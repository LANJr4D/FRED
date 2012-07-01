#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Code of techcheck daemon.
"""

import sys, time, random, ConfigParser, commands, os
import Queue, pgdb
from exceptions import SystemExit
from pyfred.idlstubs import ccReg, ccReg__POA
from pyfred.utils import isInfinite
from pyfred.utils import runCommand
import CosNaming

def safeNull(str):
	"""
Substitute None value by empty string.
	"""
	if not str:
		return ""
	return str

def convFromReason(reason):
	"""
Convert IDL reason to numeric code used in database.
	"""
	if reason == ccReg.CHKR_EPP:
		return 1
	if reason == ccReg.CHKR_MANUAL:
		return 2
	if reason == ccReg.CHKR_REGULAR:
		return 3
	return 0 # code of unknown reason

def convToReason(number):
	"""
Convert IDL reason to numeric code used in database.
	"""
	if number == 1:
		return ccReg.CHKR_EPP
	if number == 2:
		return ccReg.CHKR_MANUAL
	if number == 3:
		return ccReg.CHKR_REGULAR
	return ccReg.CHKR_ANY # code of unknown reason

def convList2Array(list):
	"""
Converts python list to pg array.
	"""
	array = '{'
	for item in list:
		array += "'%s'," % pgdb.escape_string(item)
	# trim ending ','
	if len(array) > 1:
		array = array[0:-1]
	array += '}'
	return array

def convArray2List(array):
	"""
Converts pg array to python list.
	"""
	# trim {,} chars
	array = array[1:-1]
	if not array: return []
	return array.split(',')

def getDomainData(cursor, lastrow):
	"""
Assemble data about domain from db rows to logical units.
	"""
	if not lastrow:
		return None
	# init values
	objid = lastrow[0]
	histid = lastrow[1]
	domain = lastrow[2]
	level = lastrow[3]
	nslist = {}
	if lastrow[5]:
		nslist[ lastrow[4] ] = [ lastrow[5] ]
	else:
		nslist[ lastrow[4] ] = []
	# agregate nameservers and their addrs
	currow = cursor.fetchone()
	while currow and objid == currow[0]:
		if currow[5]:
			nslist[ currow[4] ] = [ currow[5] ]
		else:
			nslist[ currow[4] ] = []
		currow = cursor.fetchone()
	return currow, objid, histid, domain, nslist, level

class RegularCheck:
	"""
This class gathers data needed for regular technical check.
	"""
	def __init__(self, id, handle, objid, nsset_hid, level, nslist, fqdns):
		"""
	Initializes data representing regular technical check.
		"""
		self.id = id
		self.handle = handle
		self.objid = objid
		self.nsset_hid = nsset_hid
		self.level = level
		self.nslist = nslist
		self.fqdns = fqdns


class TechCheck_i (ccReg__POA.TechCheck):
	"""
This class implements TechCheck interface.
	"""
	# Test seriosity levels
	CHK_ERROR = 0
	CHK_WARNING = 1
	CHK_NOTICE = 2

	def __init__(self, logger, db, conf, joblist, corba_refs):
		"""
	Initializer saves db (which is later used for opening database
	connection) and logger (used for logging).
		"""
		# ccReg__POA.TechCheck doesn't have constructor
		self.db = db # db connection string
		self.l = logger # syslog functionality
		self.corba_refs = corba_refs
		self.search_objects = Queue.Queue(-1)
		self.idle_rounds = 0 # counter of so far idle rounds (see missrounds)

		# default configuration
		self.testmode       = False
		self.periodic_checks= True
		self.scriptdir      = "/usr/libexec/pyfred/"
		self.exMsg          = 7
		self.mailer_object  = "Mailer"
		self.mailer_context = "fred"
		self.mailtype       = "techcheck"
		self.idletreshold   = 3600
		self.checkperiod    = 60
		self.queueperiod    = 5
		self.oldperiod      = 30
		self.missrounds     = 10
		self.drill          = "/usr/bin/drill"
		self.trusted_key    = ""
		# Parse TechCheck-specific configuration
		if conf.has_section("TechCheck"):
			try:
				scriptdir = conf.get("TechCheck", "scriptdir")
				if scriptdir:
					self.l.log(self.l.DEBUG, "scriptdir is set to '%s'." %
							scriptdir)
					self.scriptdir = scriptdir.strip()
			except ConfigParser.NoOptionError, e:
				pass
			try:
				self.exMsg = conf.getint("TechCheck", "msgLifetime")
				self.l.log(self.l.DEBUG, "Poll message lifetime is set to %d "
						"days." % self.exMsg)
			except ConfigParser.NoOptionError, e:
				pass
			try:
				self.testmode = conf.getboolean("TechCheck", "testmode")
				if self.testmode:
					self.l.log(self.l.DEBUG, "Test mode is turned on.")
			except ConfigParser.NoOptionError, e:
				pass
			try:
				self.periodic_checks = conf.getboolean("TechCheck", "periodic_checks")
				if not self.periodic_checks:
					self.l.log(self.l.DEBUG, "Periodic checks are turned off.")
			except ConfigParser.NoOptionError, e:
				pass
			try:
				mailer = conf.get("TechCheck", "mailer_object")
				if mailer:
					self.l.log(self.l.DEBUG, "mailer object name is set to "
							"'%s'." % mailer)
					mailer = mailer.split(".")
					if len(mailer) == 2:
						self.mailer_context = mailer[0]
						self.mailer_object = mailer[1]
					else:
						self.mailer_object = mailer[0]
			except ConfigParser.NoOptionError, e:
				pass
			try:
				mailtype = conf.get("TechCheck", "mailtype")
				if mailtype:
					self.l.log(self.l.DEBUG, "mailtype is set to '%s'." %
							mailtype)
					self.mailtype = mailtype
			except ConfigParser.NoOptionError, e:
				pass
			# check period
			try:
				self.checkperiod = conf.getint("TechCheck", "checkperiod")
				self.l.log(self.l.DEBUG, "checkperiod is set to %d." %
							self.checkperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# queues inspect period
			try:
				self.queueperiod = conf.getint("TechCheck", "queueperiod")
				self.l.log(self.l.DEBUG, "queueperiod is set to %d." %
							self.queueperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# idle treshold
			try:
				self.idletreshold = conf.getint("TechCheck", "idletreshold")
				self.l.log(self.l.DEBUG, "idletreshold is set to %d." %
							self.idletreshold)
			except ConfigParser.NoOptionError, e:
				pass
			# oldperiod
			try:
				self.oldperiod = conf.getint("TechCheck", "oldperiod")
				self.l.log(self.l.DEBUG, "oldperiod is set to %d." %
							self.oldperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# missrounds
			try:
				self.missrounds = conf.getint("TechCheck", "missrounds")
				self.l.log(self.l.DEBUG, "missrounds is set to %d." %
							self.missrounds)
			except ConfigParser.NoOptionError, e:
				pass
			# drill
			try:
				drill = conf.get("TechCheck", "drill")
				if drill:
					self.l.log(self.l.DEBUG, "drill is set to %s" %
								drill)
					self.drill = drill
			except ConfigParser.NoOptionError, e:
				pass
			# trusted_key
			try:
				trusted_key = conf.get("TechCheck", "trusted_key")
				if trusted_key:
					self.l.log(self.l.DEBUG, "trusted_key is set to %s" %
								trusted_key)
					self.trusted_key = trusted_key
			except ConfigParser.NoOptionError, e:
				pass

		if not os.path.isdir(self.scriptdir):
			raise Exception("Scriptdir '%s' does not exist." % self.scriptdir)
		if not os.access(self.scriptdir, os.R_OK):
			raise Exception("Scriptdir '%s' is not readable." % self.scriptdir)
		if not os.path.exists(self.drill):
			raise Exception("Drill utility '%s' does not exist." % self.drill)
		if not os.access(self.drill, os.X_OK):
			raise Exception("Drill utility '%s' is not executable." % self.drill)
		if not os.path.exists(self.trusted_key):
			self.l.log(self.l.WARNING, "File with trusted key was not found/set, "
					"dnssec key trust chain test will not work properly.")

		# add trailing '/' to scriptdir if not given
		if self.scriptdir[-1] != '/':
			self.scriptdir += '/'
		# build test suite based on values from database
		conn = self.db.getConn()
		self.testsuite = self.__dbBuildTestSuite(conn)
		self.db.releaseConn(conn)
		# create four queues for requests
		# queue for regularly scheduled checks
		self.queue_regular = Queue.Queue(-1)
		# queue for prioritized out-of-order checks
		self.queue_ooo = Queue.Queue(-1)
		# queue for regular checks which failed one time
		self.queue_failed = Queue.Queue(-1)
		# queue for regular checks which failed two times
		self.queue_last = Queue.Queue(-1)
		# schedule regular queues inspection job
		joblist.append( { "callback":self.__inspect_queues, "context":None,
			"period":self.queueperiod, "ticks":1 } )
		# schedule regular cleanup of search objects
		joblist.append( { "callback":self.__search_cleaner, "context":None,
			"period":self.checkperiod, "ticks":1 } )
		self.l.log(self.l.INFO, "Object initialized")

	def __inspect_queues(self, ctx):
		"""
	Process records in queues. This method processes one request from
	a queue and exits. It is important to do things quickly and exit,
	otherwise other regular jobs get blocked.
		"""
		# at first check out-of-order requests (i.e. comming from epp)
		if not self.queue_ooo.empty():
			(id, nsset, nsset_hid, level, nslist, fqdns_extra, fqdns_all,
					dig, regid, reason, cltestid) = self.queue_ooo.get()
			self.l.log(self.l.DEBUG, "<%d> Found scheduled ooo tech check." % id)
			(status, results) = self.__runTests(id, fqdns_all, nslist, level)
			try:
				conn = self.db.getConn()
				# archive results of check
				chkid = self.__dbArchiveCheck(conn, nsset_hid, fqdns_extra,
						status, results, reason, dig, 1)
				self.__dbQueuePollMsg(conn, regid, chkid)
				# commit changes in archive and message queue
				conn.commit()
				self.db.releaseConn(conn)
			except pgdb.DatabaseError, e:
				self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			return
		# when there are not ooo requests, there is time for regular checks
		# recruit new regular check
		if not self.periodic_checks:
			return
		if self.idle_rounds > 0:
			self.idle_rounds -= 1
			if self.idle_rounds == 0:
				self.idle_rounds = -1 # signal that we have just changed status
		else:
			check_obj = None
			try:
				id = random.randint(1, 9999) # generate random id of check
				conn = self.db.getConn()
				handle, objid, nsset_hid, nslist, level = self.__dbGetNsset(conn)
				self.idle_rounds = 0
				self.l.log(self.l.DEBUG, "<%d> Regular check created "
						"(nsset = %s [hid=%d])." % (id, handle, nsset_hid))
				fqdns = self.__dbGetAssocDomains(conn, objid)
				check_obj = RegularCheck(id, handle, objid, nsset_hid, level,
						nslist, fqdns)
				# run the tests
				status, results = self.__runTests(id, check_obj.fqdns,
						check_obj.nslist, check_obj.level)
				# archive results of tests
				checkid = self.__dbArchiveCheck(conn, check_obj.nsset_hid, [],
						status, results, ccReg.CHKR_REGULAR, True, 1)
				conn.commit()
				# reschedule failed tests
				if status == 1:
					self.queue_failed.put(check_obj)
					self.l.log(self.l.DEBUG, "<%d> Regular check failed - "
							"repetition scheduled." % id)
				self.db.releaseConn(conn)
				return
			except pgdb.DatabaseError, e:
				self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
				return
			except ccReg.TechCheck.NssetNotFound, e:
				if self.idle_rounds == 0:
					self.l.log(self.l.DEBUG, "<%d> Activating low-cost working"%
							id)
				self.idle_rounds = self.missrounds

		# when all regular checks are done, try again the failed checks
		try:
			conn = self.db.getConn()
			if not self.queue_failed.empty():
				check_obj = self.queue_failed.get()
				self.l.log(self.l.DEBUG, "<%d> Failed check revisited. "
						"(nsset = %s [hid=%d])" % (check_obj.id, check_obj.handle,
							check_obj.nsset_hid))
				# run the tests
				status, results = self.__runTests(check_obj.id, check_obj.fqdns,
						check_obj.nslist, check_obj.level)
				# archive results of tests
				checkid = self.__dbArchiveCheck(conn, check_obj.nsset_hid, [],
						status, results, ccReg.CHKR_REGULAR, True, 2)
				conn.commit()
				if status == 1:
					self.queue_last.put(check_obj)
					self.l.log(self.l.DEBUG, "<%d> Repeated check failed - "
							"repetition scheduled." % check_obj.id)
			# finally last chance to get better if two previous attempts failed
			elif not self.queue_last.empty():
				check_obj = self.queue_last.get()
				self.l.log(self.l.DEBUG, "<%d> Failed check revisited. "
						"(nsset = %s [%d])" % (check_obj.id, check_obj.handle, 
							check_obj.nsset_hid))
				# run the tests
				status, results = self.__runTests(check_obj.id, check_obj.fqdns,
						check_obj.nslist, check_obj.level)
				# archive results of tests
				checkid = self.__dbArchiveCheck(conn, check_obj.nsset_hid, [],
						status, results, ccReg.CHKR_REGULAR, True, 3)
				conn.commit()
				# send email notification if nsset failed three times
				if status == 1:
					emails = self.__dbGetEmail(conn, check_obj.objid)
					history = self.__dbGetNssetHistory(conn, check_obj.objid)
					self.l.log(self.l.DEBUG, "<%d> Last chance waisted - check "
							"failed." % check_obj.id)
					# it is possible that nsset does not exist any more
					if not emails:
						self.l.log(self.l.DEBUG, "<%d> No contacts to be "
								"notified about bad nsset." % check_obj.id)
					# check if we have newer version of nsset to not send
					# notification which can be confusing
					elif len([hid for hid in history if hid > check_obj.nsset_hid]):
						self.l.log(self.l.DEBUG, "<%d> Nsset was updated "
								"recently - we don't notify oldsters." % check_obj.id)
					# notify it
					else:
						self.__notify(check_obj.id, checkid, emails,
								check_obj.handle, results)

			self.db.releaseConn(conn)
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<0> Database error: %s" % e)
		return

	def __search_cleaner(self, ctx):
		"""
	Method deletes closed or idle search objects.
		"""
		self.l.log(self.l.DEBUG, "Regular maintance procedure.")
		remove = []
		# the queue may change and the number of items in the queue may grow
		# but we can be sure that there will be never less items than nitems
		# therefore we can use blocking call get() on queue
		nitems = self.search_objects.qsize()
		for i in range(nitems):
			item = self.search_objects.get()
			# test idleness of object
			if time.time() - item.lastuse > self.idletreshold:
				item.status = item.IDLE

			# schedule objects to be deleted
			if item.status == item.CLOSED:
				self.l.log(self.l.DEBUG, "Closed search-object with id %d "
						"destroyed." % item.id)
				remove.append(item)
			elif item.status == item.IDLE:
				self.l.log(self.l.DEBUG, "Idle search-object with id %d "
						"destroyed." % item.id)
				remove.append(item)
			# if object is active - reinsert the object in queue
			else:
				self.l.log(self.l.DEBUG, "search-object with id %d and type %s "
							"left in queue." % (item.id, item.__class__.__name__))
				self.search_objects.put(item)
		
		queue = self.search_objects 
		self.l.log(self.l.DEBUG, '%d objects are scheduled to deletion and %d left in queue' % (len(remove), queue.qsize()))
		
		# delete objects scheduled for deletion
		rootpoa = self.corba_refs.rootpoa
		for item in remove:
			id = rootpoa.servant_to_id(item)
			rootpoa.deactivate_object(id)

	def __dbBuildTestSuite(self, conn):
		"""
	This routine pulls information about tests from database and puts together
	a test suite.
		"""
		# init list of checks
		testsuite = {}
		# Get all enabled tests
		cur = conn.cursor()
		cur.execute("SELECT id, name, severity, script, need_domain "
				" FROM check_test WHERE disabled = False")
		tests = cur.fetchall()
		# Get dependencies of tests
		for test in tests:
			cur.execute("SELECT testid FROM check_dependance WHERE addictid = %d",
					[test[0]])
			testsuite[ test[0] ] = {
				"id" : test[0],
				"name" : test[1],
				"level" : test[2],
				"script" : test[3],
				"need_domain" : test[4],
				"requires" : [ item[0] for item in cur.fetchall() ]
				}
		cur.close()
		return testsuite

	def __dbGetEmail(self, conn, objid):
		"""
	Get email addresses of all technical contacts for given nsset.
	We prefer notifyEmail if it is not empty, otherwise we have to use
	normal email addresse.
		"""
		cur = conn.cursor()
		cur.execute("SELECT c.notifyemail, c.email, oreg.name "
				"FROM object_registry oreg, contact c, nsset_contact_map ncm "
				"WHERE oreg.id = c.id AND c.id = ncm.contactid AND "
					"ncm.nssetid = %d", [objid])
		emails = []
		for row in cur.fetchall():
			if row[0]:
				emails.append((row[0], row[2]))
			elif row[1]:
				emails.append((row[1], row[2]))
		cur.close()
		return emails

	def __dbGetAssocDomains(self, conn, objid):
		"""
	Dig all associated domains with nsset from database.
		"""
		cur = conn.cursor()
		cur.execute("SELECT oreg.name, (d.keyset IS NOT NULL) as signed "
				"FROM domain d, object_registry oreg "
				"WHERE oreg.type = 3 AND d.id = oreg.id AND d.nsset = %d",
				[objid])
		# fqdns = [ item[0] for item in cur.fetchall() ]
		# dictionary of domains (key=fqdn, value=is signed flag)
		fqdns = dict( (item[0], item[1]) for item in cur.fetchall() )
		cur.close()
		return fqdns

	def __dbGetNsset(self, conn, nsset = ''):
		"""
	Get all data about nsset from database needed for technical checks.
		"""
		cur = conn.cursor()
		# get nsset data (id, history id and checklevel)
		if nsset:
			cur.execute("SELECT oreg.name, oreg.id, oreg.historyid, oreg.name, "
						"ns.checklevel "
					"FROM object_registry oreg, nsset ns "
					"WHERE oreg.id = ns.id AND oreg.type = 2 AND "
						"upper(oreg.name) = upper(%s)", [nsset])
		else:
			cur.execute("SELECT oreg.name, oreg.id, oreg.historyid, oreg.name, "
						"ns.checklevel "
					"FROM object_registry oreg LEFT JOIN check_nsset cn "
						"ON (cn.nsset_hid=oreg.historyid), nsset ns "
					"WHERE (oreg.id = ns.id) AND (oreg.type = 2) AND "
						"(cn.nsset_hid NOT IN "
							"(SELECT nsset_hid FROM check_nsset "
							 "WHERE (age(now(),checkdate)) <interval '%d days')"
						"OR cn.id IS NULL) LIMIT 1", [self.oldperiod])

		if cur.rowcount == 0:
			cur.close()
			raise ccReg.TechCheck.NssetNotFound()
		handle, objid, histid, handle, level = cur.fetchone()
		# get nameservers (fqdns and ip addresses) of hosts belonging to nsset
		cur.execute("SELECT h.fqdn, ip.ipaddr FROM host h "
				"LEFT JOIN host_ipaddr_map ip ON (h.id = ip.hostid) "
				"WHERE h.nssetid = %d ORDER BY h.fqdn", [objid])
		row = cur.fetchone()
		nameservers = {}
		while row:
			fqdn, addr = row
			if (fqdn in nameservers) and addr:
				nameservers[fqdn].append(addr)
			elif addr:
				nameservers[fqdn] = [ addr ]
			else:
				nameservers[fqdn] = []
			row = cur.fetchone()
		cur.close()
		return handle, objid, histid, nameservers, level

	def __dbGetNssetHistory(self, conn, nsset_id):
		"""
	Get all history ids of nsset.
		"""
		hid_list = []
		cur = conn.cursor()
		cur.execute("SELECT historyid FROM nsset_history WHERE id = %d",
							[nsset_id])
		hid_list = [row[0] for row in cur.fetchall()]
		cur.close()
		return hid_list

	def __dbArchiveCheck(self, conn, histid, fqdns, status, results, reason,
			dig, attempt):
		"""
	Archive result of technical test on domain in database.
		"""
		# convert IDL code of check-reason to database code
		reason_enum = convFromReason(reason)
		cur = conn.cursor()

		# get next ID of archive record from database
		cur.execute("SELECT nextval('check_nsset_id_seq')")
		archid = cur.fetchone()[0]
		# insert main archive record
		cur.execute("INSERT INTO check_nsset (id, nsset_hid, reason, "
					"overallstatus, extra_fqdns, dig, attempt) "
				"VALUES (%d, %d, %d, %d, %s, %s, %d)",
				[archid, histid, reason_enum, status, convList2Array(fqdns),
					dig, attempt])
		# archive results of individual tests
		for resid in results:
			result = results[resid]
			# escape note and data strings if there are any
			if result["note"]:
				raw_note = result["note"]
			else:
				raw_note = None
			if result["data"]:
				raw_data = result["data"]
			else:
				raw_data = None
			cur.execute("INSERT INTO check_result (checkid, testid, status, "
						"note, data) "
					"VALUES (%d, %d, %d, %s, %s)", 
					[archid, resid, result["result"], raw_note, raw_data])
		cur.close()
		return archid

	def __dbGetRegistrar(self, conn, reghandle):
		"""
		Get numeric ID of registrar.
		"""
		cur = conn.cursor()
		cur.execute("SELECT id FROM registrar WHERE handle = %s", [reghandle])
		if cur.rowcount == 0:
			raise ccReg.TechCheck.RegistrarNotFound()
		regid = cur.fetchone()[0]
		cur.close()
		return regid

	def __dbQueuePollMsg(self, conn, regid, chkid):
		"""
		Insert poll message in database.
		"""
		cur = conn.cursor()
		cur.execute("SELECT nextval('message_id_seq')")
		msgid = cur.fetchone()[0]
		cur.execute("INSERT INTO message (id, clid, exdate, msgtype) "
				"VALUES (%d, %d, now() + interval '%d days', 2)", 
				[msgid, regid, self.exMsg])
		cur.execute("INSERT INTO poll_techcheck (msgid, cnid) "
				"VALUES (%d, %d)", [msgid, chkid])
		cur.close()

	def __runTests(self, id, fqdns, nslist, level):
		"""
		Run all enabled tests bellow given level.
		"""
		# fool the system if testmode is turned on
		if self.testmode:
			level = 0
		results = {}
		overallstatus = 0 # by default we assume that all tests were passed
		# perform all enabled tests (the ids must be sorted!)
		testkeys = self.testsuite.keys()
		testkeys.sort()
		for testid in testkeys:
			test = self.testsuite[testid]
			# check level
			if test["level"] > level:
				self.l.log(self.l.DEBUG, "<%d> Omitting test '%s' becauseof its "
						"level." % (id, test["name"]))
				continue
			# check prerequisities
			req_ok = True
			for req in test["requires"]:
				# the test might not be done if it was disabled
				try:
					deptest = results[req]
				except KeyError, e:
					self.l.log(self.l.WARNING, "<%d> Test '%s' depends on a "
							"test which is disabled." % (id, test["name"]))
					continue
				# check the result of test on which we depend
				# (unknown status is considered as if the test failed)
				if results[req]["result"] != 0:
					self.l.log(self.l.DEBUG, "<%d> Omitting test '%s' becauseof "
							"not fulfilled prerequisity." % (id, test["name"]))
					req_ok = False
					break
			if not req_ok:
				# prerequisities were not satisfied
				continue
			if (test["need_domain"] == 1 or test["need_domain"] == 3) and not fqdns:
				# list of domains is required for the test but is not given
				self.l.log(self.l.DEBUG, "<%d> Omitting test '%s' because "
						"no domains are provided." % (id, test["name"]))
				continue
			#
			# command scheduled for execution has following format:
			#    /scriptdir/script nsFqdn,ipaddr1,ipaddr2,...
			# last part is repeated as many times as many there are nameservers.
			# If test requires a domain name(s), they are supplied on stdin.
			#
			# ip addresses are provided only if the GLUE record is needed,
			# the test whether the ip addresses are needed is done here, not in
			# external test script, and all subsequent external tests use the
			# result of this pre-test. From users point of it is just another
			# ussual test.
			#
			# We recognize the GLUE test by empty string in script field
			if not test["script"]:
				stat = 0
				for ns in nslist:
					addrs = nslist[ns]
					data = ''
					glue_needed = False
					for fqdn in fqdns:
						if ns.endswith(fqdn):
							glue_needed = True
							if not addrs:
								data += " %s" % fqdn
					# errors (missing glue) goes to 'data'
					if data:
						self.l.log(self.l.DEBUG, "<%d> Missing glue for ns '%s'"
								% (id, ns))
						data = ns + data
						stat = 1
					# cancel not needed glue
					if not glue_needed and addrs:
						self.l.log(self.l.DEBUG, "<%d> Extra glue by ns '%s' "
								"cancelled" % (id, ns))
						nslist[ns] = []
				note = ''
			else:
				cmd = "%s%s" % (self.scriptdir, test["script"])
				for ns in nslist:
					addrs = nslist[ns]
					cmd += " %s" % ns
					for addr in addrs:
						cmd += ",%s" % addr
				# decide if list of domains is needed
				stdin = ''
				if test["need_domain"] != 0:
					# decide if test need only signed domains
					if test["need_domain"] == 3:
						# append configuration parameters to command string
						cmd += " %s %s" % (self.drill, self.trusted_key)
						# select only signed domains
						list = [ item for item in fqdns if fqdns[item] ]
					else:
						list = fqdns
					# send space separated list of domain fqdns to stdin
					for fqdn in list:
						stdin += fqdn + ' '

				stat, data, note = runCommand(id, cmd, stdin, self.l)

			# Status values:
			#     0 ... test OK
			#     1 ... test failed
			#     2 ... unknown result
			if stat == 1 and overallstatus != 1:
				overallstatus = 1
			elif stat == 2 and overallstatus == 0:
				overallstatus = 2
			# save the result
			results[testid] = { "result" : stat, "note" : note, "data" : data }
			# end of one technical test
		return overallstatus, results

	def __transfmResult(self, results):
		"""
	Transform results to IDL result structure.
		"""
		checkresult = []
		for testid in results:
			test = self.testsuite[testid]
			result = results[testid]
			checkresult.append( ccReg.CheckResult(testid, result["result"],
				result["note"], result["data"]) )
		return checkresult

	def __getMailerObject(self):
		"""
	Method retrieves Mailer object from nameservice.
		"""
		# Resolve the name "fred.context/FileManager.Object"
		name = [CosNaming.NameComponent(self.mailer_context, "context"),
				CosNaming.NameComponent(self.mailer_object, "Object")]
		obj = self.corba_refs.nsref.resolve(name)
		# Narrow the object to an ccReg::FileManager
		mailer_obj = obj._narrow(ccReg.Mailer)
		return mailer_obj

	def __notify(self, id, checkid, emails, handle, results):
		"""
	Send email notification to addresses in emails list.
		"""
		# obtain mailer object's reference
		try:
			mailer = self.__getMailerObject()
		except CosNaming.NamingContext.NotFound, e:
			self.l.log(self.l.ERR, "<%d> Could not get Mailer's reference: %s" %
					(id, e))
			raise ccReg.TechCheck.InternalError("Mailer object not accessible")
		if mailer == None:
			self.l.log(self.l.ERR, "<%d> Mailer reference is not mailer." % id)
			raise ccReg.TechCheck.InternalError("Mailer object not accessible")

		header = ccReg.MailHeader('','','','','','','')
		tpldata = [ ccReg.KeyValue("handle", handle),
				ccReg.KeyValue("ticket", checkid.__str__()),
				ccReg.KeyValue("checkdate",time.strftime("%H:%M:%S %d-%m-%Y %Z"))
				]
		# construct HDF dataset (tree of data)
		i = 0
		for key in results:
			i += 1
			test = self.testsuite[key]
			result = results[key]
			if result["result"] == 1:
				tpldata.append(ccReg.KeyValue("tests.%d.name"%i, test["name"]))
				# define the level of test (error, warning or notice)
				if test["level"] <= 3:
					tpldata.append(ccReg.KeyValue("tests.%d.type"%i, "error"))
				elif test["level"] <= 5:
					tpldata.append(ccReg.KeyValue("tests.%d.type"%i, "warning"))
				else:
					tpldata.append(ccReg.KeyValue("tests.%d.type"%i, "notice"))
				j = 0
				for ns in result["data"].split():
					j += 1
					if test["need_domain"] == 1:
						ns_and_fqdns = ns.split(',')
						tpldata.append(ccReg.KeyValue("tests.%d.ns.%d" % (i,j),
									ns_and_fqdns[0]) )
						k = 0
						for fqdn in ns_and_fqdns[1:]:
							k += 1
							if k > 20:
								tpldata.append(ccReg.KeyValue(
									"tests.%d.ns.%d.overfull" % (i,j), '1') )
								break
							tpldata.append(ccReg.KeyValue(
								"tests.%d.ns.%d.fqdn.%d" % (i,j,k), fqdn) )
					else:
						tpldata.append(
								ccReg.KeyValue("tests.%d.ns.%d" % (i,j), ns) )

		try:
			for email in emails:
				header.h_to = email[0]
				mailer.mailNotify(self.mailtype, header, tpldata, [ email[1] ],
						[], False)
		except ccReg.Mailer.UnknownMailType, e:
			self.l.log(self.l.ERR, "<%d> Mailer doesn't know the email type "
					"'%s'." % (id, self.mailtype))
			raise ccReg.TechCheck.InternalError("Error when sending email "
					"notification.")
		except ccReg.Mailer.SendMailError, e:
			self.l.log(self.l.ERR, "<%d> Error when sending email." % id)
			raise ccReg.TechCheck.InternalError("Error when sending email "
					"notification.")
		except ccReg.Mailer.InternalError, e:
			self.l.log(self.l.ERR, "<%d> Internal error in Mailer " % id)
			raise ccReg.TechCheck.InternalError("Error when sending email "
					"notification.")

	def __checkNsset(self, nsset, level, dig, archive, reason, fqdns, asynch,
			registrarid=None, clienttestid=None):
		"""
	Run tests for a nsset. Flag asynch decides whether the mode of operation
	is asynchronous or synchronous.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Request for technical test of nsset "
					"'%s' received (asynchronous=%s)." % (id, nsset, asynch))
			# convert dig from int to boolean (CORBA maps booleans to ints)
			if dig:
				dig = True
			else:
				dig = False

			# connect to database
			conn = self.db.getConn()

			# get all nsset data (including nameservers)
			nsset, objid, histid, nslist, dblevel =self.__dbGetNsset(conn, nsset)
			# override level if it is not zero
			if level <= 0:
				level = dblevel
			# dig associated domain fqdns if told to do so
			all_fqdns = dict( (item, True) for item in fqdns )
			if dig:
				# get all fqdns of domains associated with nsset and join
				# them with provided fqdns
				all_fqdns.update(self.__dbGetAssocDomains(conn, objid))

			self.l.log(self.l.DEBUG, "<%d> List of first 5 domain fqdns "
					"from total %d: %s" % (id, len(all_fqdns), all_fqdns.keys()[0:5]))
			# perform tests on the nsset
			if asynch:
				registrarid = self.__dbGetRegistrar(conn, registrarid)
				self.db.releaseConn(conn)
				self.queue_ooo.put( (id, nsset, histid, level, nslist, fqdns,
					all_fqdns, dig, registrarid, reason, clienttestid) )
				return

			# if we are here it means that we do synchronous test
			(status, results) = self.__runTests(id, all_fqdns, nslist, level)
			# archive results of check if told to do so
			if archive:
				checkid = self.__dbArchiveCheck(conn, histid, fqdns, status,
						results, reason, dig, 1)
				# commit changes in archive
				conn.commit()
			else:
				checkid = 0

			self.db.releaseConn(conn)
			return (self.__transfmResult(results), checkid, status)

		except ccReg.TechCheck.NssetNotFound, e:
			self.l.log(self.l.ERR, "<%d> Nsset '%s' does not exist." %
					(id, nsset))
			raise
		except ccReg.TechCheck.RegistrarNotFound, e:
			self.l.log(self.l.ERR, "<%d> Registrar '%s' does not exist." %
					(id, registrarid))
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.TechCheck.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caught: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.TechCheck.InternalError("Unexpected error")

	def checkNsset(self, nsset, level, dig, archive, reason, fqdns):
		"""
	Method from IDL interface. Run synchronously tests for a nsset.
		"""
		return self.__checkNsset(nsset, level, dig, archive, reason, fqdns,
				False)

	def checkNssetAsynch(self, regid, nsset, level, dig, archive, reason, fqdns,
			cltestid):
		"""
	Method from IDL interface. Run asynchronously tests for a nsset.
		"""
		self.__checkNsset(nsset, level, dig, archive, reason, fqdns, True,
				registrarid=regid, clienttestid=cltestid)

	def checkGetTests(self):
		"""
	Method from IDL interface. It returns a list of active technical tests.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Get list-of-tests is being called." %
					id)
			# connect to database
			conn = self.db.getConn()
			self.db.releaseConn(conn)
			# transform testsuite in list of CheckTest IDL structures
			tests = []
			for testid in self.testsuite:
				test = self.testsuite[testid]
				tests.append( ccReg.CheckTest(testid, test["name"],
					test["level"], test["need_domain"] == 1) )
			return tests

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.TechCheck.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caught: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.TechCheck.InternalError("Unexpected error")

	def createSearchObject(self, filter):
		"""
	This is universal techcheck archive lookup function. It returns object
	reference which can be used to access data.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Search create request received." % id)

			# construct SQL query coresponding to filter constraints
			conditions = []
			condvalues = []
			if filter.checkid != -1:
				conditions.append("chn.id = %d")
				condvalues.append(filter.checkid)
			if filter.nsset_hid != -1:
				conditions.append("chn.nsset_hid = %d")
				condvalues.append(filter.nsset_hid)
			if filter.reason != ccReg.CHKR_ANY:
				conditions.append("chn.reason = %d")
				condvalues.append(convFromReason(filter.reason))
			if filter.status != -1:
				conditions.append("chn.overallstatus = %d")
				condvalues.append(filter.status)
			fromdate = filter.checkdate._from
			if not isInfinite(fromdate):
				conditions.append("chn.checkdate > '%d-%d-%d %d:%d:%d'" %
						(fromdate.date.year,
						fromdate.date.month,
						fromdate.date.day,
						fromdate.hour,
						fromdate.minute,
						fromdate.second))
			todate = filter.checkdate.to
			if not isInfinite(todate):
				conditions.append("chn.checkdate < '%d-%d-%d %d:%d:%d'" %
						(todate.date.year,
						todate.date.month,
						todate.date.day,
						todate.hour,
						todate.minute,
						todate.second))
			if len(conditions) == 0:
				cond = ""
			else:
				cond = "WHERE (%s)" % conditions[0]
				for condition in conditions[1:]:
					cond += " AND (%s)" % condition

			# connect to database
			conn = self.db.getConn()
			cur = conn.cursor()

			self.l.log(self.l.DEBUG, "<%d> Search WHERE clause is: %s" %
					(id, cond))
			# execute the query
			cur.execute("SELECT chn.id, chn.nsset_hid, chn.checkdate, "
						"chn.reason, chn.overallstatus, chn.extra_fqdns, "
						"chn.dig, chr.testid, chr.status, chr.note, chr.data "
					"FROM check_nsset chn "
					"LEFT JOIN check_result chr ON (chn.id = chr.checkid) "
					"%s ORDER BY chn.id" % cond, condvalues)
			self.db.releaseConn(conn)
			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor: %d" %
					(id, cur.rowcount))

			# Create an instance of MailSearch_i and an MailSearch object ref
			searchobj = TechCheckSearch_i(id, cur, self.l)
			self.search_objects.put(searchobj)
			searchref = self.corba_refs.rootpoa.servant_to_reference(searchobj)
			return searchref

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "Database error: %s" % e)
			raise ccReg.TechCheck.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "Unexpected exception: %s:%s" %
					(sys.exc_info()[0], e))
			raise ccReg.TechCheck.InternalError("Unexpected error")

class TechCheckSearch_i (ccReg__POA.TechCheckSearch):
	"""
Class encapsulating results of search.
	"""
	# statuses of search object
	ACTIVE = 1
	CLOSED = 2
	IDLE = 3

	def __init__(self, id, cursor, log):
		"""
	Initializes search object.
		"""
		self.l = log
		self.id = id
		self.cursor = cursor
		self.status = self.ACTIVE
		self.crdate = time.time()
		self.lastuse = self.crdate
		self.lastrow = cursor.fetchone()

	def getNext(self, count):
		"""
	Get result of search.
		"""
		try:
			self.l.log(self.l.INFO, "<%d> Get search results request received." %
					self.id)

			# check count
			if count < 1:
				self.l.log(self.l.WARNING, "Invalid count of domains requested "
						"(%d). Default value (1) is used." % count)
				count = 1

			# check status
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> Search object is not active "
						"anymore." % self.id)
				raise ccReg.MailSearch.NotActive()

			# update last use timestamp
			self.lastuse = time.time()

			# get 'count' results
			checklist = []
			for i in range(count):
				if not self.lastrow: break
				resultlist = []
				currow = self.lastrow
				checkid = self.lastrow[0]
				while currow[0] == checkid:
					self.lastrow = currow
					# create CheckResult structure
					resultlist.append( ccReg.CheckResult(currow[7], currow[8],
						safeNull(currow[9]), safeNull(currow[10])) )
					currow = self.cursor.fetchone()
					if not currow: break
				# create CheckItem structure
				checklist.append( ccReg.CheckItem(self.lastrow[0],
					self.lastrow[1], self.lastrow[6],
					convArray2List(self.lastrow[5]),
					self.lastrow[4],
					self.lastrow[2],
					convToReason(self.lastrow[3]),
					resultlist) )
				self.lastrow = currow

			self.l.log(self.l.DEBUG, "<%d> Number of records returned: %d." %
					(self.id, len(checklist)))
			return checklist

		except ccReg.TechCheckSearch.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.TechCheckSearch.InternalError("Unexpected error")

	def destroy(self):
		"""
	Mark object as ready to be destroyed.
		"""
		try:
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> An attempt to close non-active "
						"search." % self.id)
				return

			self.status = self.CLOSED
			self.l.log(self.l.INFO, "<%d> Search closed." % self.id)
			# close db cursor
			self.cursor.close()
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.TechCheckSearch.InternalError("Unexpected error")


def init(logger, db, conf, joblist, corba_refs):
	"""
Function which creates, initializes and returns servant TechCheck.
	"""
	# Create an instance of TechCheck_i and an TechCheck object ref
	servant = TechCheck_i(logger, db, conf, joblist, corba_refs)
	return servant, "TechCheck"

