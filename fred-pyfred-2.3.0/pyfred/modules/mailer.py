#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Code of mailer daemon.
"""

import os, sys, time, random, ConfigParser, Queue, tempfile, re
import base64
import pgdb
from pyfred.utils import isInfinite
from pyfred.utils import runCommand
# corba stuff
import CosNaming
from pyfred.idlstubs import ccReg, ccReg__POA
# template stuff
import neo_cgi # must be included before neo_cs and neo_util
import neo_cs, neo_util
# email stuff
import email
import email.Charset
from email import Encoders
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.Utils import formatdate, parseaddr
# IMAP stuff
import imaplib


def convList2Array(list):
	"""
Converts python list to pg array.
	"""
	array = '{'
	for item in list:
		if isinstance(item, str):
			item = pgdb.escape_string(item)
		array += "%s," % str(item)
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

def contentfilter(mail, ismultipart):
	"""
	This routine slightly modifies email in order to prevent unexpected results
	of email signing.
	"""
	# tabs might not be preserved during mail transfer
	mail = mail.replace('\t', '        ')
	# add newline at the end if email is not multipart to make outlook
	# - shitty client - happy
	if not ismultipart:
		mail += '\n'
	return mail

def qp_str(string):
	"""
	Function checks if the string contains characters, which need to be "quoted
	printable" and if there are any, it will encode the string. This function
	is used for headers of email.
	"""
	need = False
	for c in string:
		if email.quopriMIME.header_quopri_check(c):
			need = True
	if need:
		string = email.quopriMIME.header_encode(string, charset="utf-8",
				maxlinelen=None)
	return string

def filter_email_addrs(str):
	"""
	addresses are separated by comma or whitespace, delete any address which
	does not contain at-sign.
	"""
	str = str.replace(',', ' ')
	result = ""
	for addr in str.split():
		if addr.find('@') > 0 and not addr.endswith('@'):
			if result: result += ", "
			result += addr
	return result

class Mailer_i (ccReg__POA.Mailer):
	"""
	This class implements Mailer interface.
	"""

	class MailerException(Exception):
		"""
		Exception used for error signalization in periodic sendmail routine.
		"""
		def __init__(self, msg):
			Exception.__init__(self, msg)

	def __init__(self, logger, db, conf, joblist, corba_refs):
		"""
		Initializer saves db_pars (which is later used for opening database
		connection) and logger (used for logging).
		"""
		# ccReg__POA.Mailer doesn't have constructor
		self.db = db # db object for accessing database
		self.l = logger # syslog functionality
		self.search_objects = Queue.Queue(-1) # list of created search objects
		self.corba_refs = corba_refs # root poa and nameservice reference

		# this avoids base64 encoding for utf-8 messages
		email.Charset.add_charset( 'utf-8', email.Charset.SHORTEST, None, None )

		# default configuration
		self.testmode     = False
		self.tester       = ""
		self.sendmail     = "/usr/sbin/sendmail"
		self.openssl      = "/usr/bin/openssl"
		self.fm_context   = "fred"
		self.fm_object    = "FileManager"
		self.idletreshold = 3600
		self.checkperiod  = 60
		self.signing      = False
		self.keyfile      = ""
		self.certfile     = ""
		self.vcard        = ""
		self.sendperiod   = 300
		self.sendlimit    = 100
		self.archstatus   = 1
		self.maxattempts  = 3
		self.undeliveredperiod = 0
		self.IMAPuser     = "pyfred"
		self.IMAPpass     = ""
		self.IMAPserver   = "localhost"
		self.IMAPport     = 143
		self.IMAPssl      = False
		# Parse Mailer-specific configuration
		if conf.has_section("Mailer"):
			# testmode
			try:
				self.testmode = conf.getboolean("Mailer", "testmode")
				if self.testmode:
					self.l.log(self.l.DEBUG, "Test mode is turned on.")
			except ConfigParser.NoOptionError, e:
				pass
			# tester email address
			try:
				tester = conf.get("Mailer", "tester")
				if tester:
					self.l.log(self.l.DEBUG, "Tester's address is %s." % tester)
					self.tester = tester
			except ConfigParser.NoOptionError, e:
				pass
			# sendmail path
			try:
				sendmail = conf.get("Mailer", "sendmail")
				if sendmail:
					self.l.log(self.l.DEBUG, "Path to sendmail is %s." %
							sendmail)
					self.sendmail = sendmail
			except ConfigParser.NoOptionError, e:
				pass
			# openssl path
			try:
				openssl = conf.get("Mailer", "openssl")
				if openssl:
					self.l.log(self.l.DEBUG, "Path to openssl is %s." % openssl)
					self.openssl = openssl
			except ConfigParser.NoOptionError, e:
				pass
			# filemanager object's name
			try:
				fm_object = conf.get("Mailer", "filemanager_object")
				if fm_object:
					self.l.log(self.l.DEBUG, "Name under which to look for "
							"filemanager is %s." % fm_object)
					fm_object = fm_object.split(".")
					if len(fm_object) == 2:
						self.fm_context = fm_object[0]
						self.fm_object = fm_object[1]
					else:
						self.fm_object = fm_object[0]
			except ConfigParser.NoOptionError, e:
				pass
			# check period
			try:
				self.checkperiod = conf.getint("Mailer", "checkperiod")
				self.l.log(self.l.DEBUG, "checkperiod is set to %d." %
						self.checkperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# idle treshold
			try:
				self.idletreshold = conf.getint("Mailer", "idletreshold")
				self.l.log(self.l.DEBUG, "idletreshold is set to %d." %
						self.idletreshold)
			except ConfigParser.NoOptionError, e:
				pass
			# signing
			try:
				self.signing = conf.getboolean("Mailer", "signing")
				if self.signing:
					self.l.log(self.l.DEBUG, "Signing of emails is turned on.")
			except ConfigParser.NoOptionError, e:
				pass
			# certificate path
			try:
				certfile = conf.get("Mailer", "certfile")
				if certfile:
					self.l.log(self.l.DEBUG, "Path to certfile is %s." %
							certfile)
					self.certfile = certfile
			except ConfigParser.NoOptionError, e:
				pass
			# key path
			try:
				keyfile = conf.get("Mailer", "keyfile")
				if keyfile:
					self.l.log(self.l.DEBUG, "Path to keyfile is %s." % keyfile)
					self.keyfile = keyfile
			except ConfigParser.NoOptionError, e:
				pass
			# vcard switch
			try:
				vcard = conf.getboolean("Mailer", "vcard")
				if vcard:
					self.l.log(self.l.DEBUG, "Vcard attachment enabled.")
					conn = self.db.getConn()
					self.vcard = self.__dbGetVcard(conn).strip() + '\n'
					self.db.releaseConn(conn)
			except ConfigParser.NoOptionError, e:
				pass
			# sendperiod
			try:
				self.sendperiod = conf.getint("Mailer", "sendperiod")
				self.l.log(self.l.DEBUG, "Sendperiod is %d seconds." %
							self.sendperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# sendlimit
			try:
				self.sendlimit = conf.getint("Mailer", "sendlimit")
				self.l.log(self.l.DEBUG, "Sendlimit is %d emails." %
							self.sendlimit)
			except ConfigParser.NoOptionError, e:
				pass
			# archstatus alias manualconfirm
			try:
				manconfirm = conf.getboolean("Mailer", "manconfirm")
				if manconfirm:
					self.l.log(self.l.DEBUG, "Manual confirmation of email "
								"submission is enabled.")
					self.archstatus = 2
			except ConfigParser.NoOptionError, e:
				pass
			# maxattempts
			try:
				self.maxattempts = conf.getint("Mailer", "maxattempts")
				self.l.log(self.l.DEBUG, "Maxattempts is set to %d." %
						self.maxattempts)
			except ConfigParser.NoOptionError, e:
				pass
			# undeliveredperiod
			try:
				self.undeliveredperiod = conf.getint("Mailer",
						"undeliveredperiod")
				self.l.log(self.l.DEBUG, "Undeliveredperiod is set to %d." %
						self.undeliveredperiod)
			except ConfigParser.NoOptionError, e:
				pass
			# IMAPuser
			try:
				IMAPuser = conf.get("Mailer", "IMAPuser")
				if IMAPuser:
					self.l.log(self.l.DEBUG, "IMAPuser is %s" % IMAPuser)
					self.IMAPuser = IMAPuser
			except ConfigParser.NoOptionError, e:
				pass
			# IMAPpass
			try:
				IMAPpass = conf.get("Mailer", "IMAPpass")
				if IMAPpass:
					self.l.log(self.l.DEBUG, "IMAPpass is %s" % IMAPpass)
					self.IMAPpass = IMAPpass
			except ConfigParser.NoOptionError, e:
				pass
			# IMAPserver
			try:
				IMAPserver = conf.get("Mailer", "IMAPserver")
				if IMAPserver:
					temp = IMAPserver.split(':')
					if len(temp) == 1:
						self.IMAPserver = temp[0]
					else:
						self.IMAPserver = temp[0]
						self.IMAPport = int(temp[1])
						self.l.log(self.l.DEBUG, "IMAPport is %d" %
								self.IMAPport)
					self.l.log(self.l.DEBUG, "IMAPserver is %s" %
							self.IMAPserver)
			except ConfigParser.NoOptionError, e:
				pass
			# IMAPssl
			try:
				self.IMAPssl = conf.getboolean("Mailer", "IMAPssl")
				if self.IMAPssl:
					self.l.log(self.l.DEBUG, "IMAPssl is turned on.")
			except ConfigParser.NoOptionError, e:
				pass

		# check configuration consistency
		if self.tester and not self.testmode:
			self.l.log(self.l.WARNING, "Tester configuration directive will "
					"be ignored because testmode is not turned on.")
		if self.signing and not (self.certfile and self.keyfile):
			raise Exception("Certificate and key file must be set for mailer.")
		# do quick check that all files exist
		if not os.path.isfile(self.sendmail):
			raise Exception("sendmail binary (%s) does not exist." %
					self.sendmail)
		if self.signing:
			if not os.path.isfile(self.openssl):
				raise Exception("openssl binary (%s) does not exist." %
						self.openssl)
			if not os.path.isfile(self.certfile):
				raise Exception("Certificate (%s) does not exist." %
						self.certfile)
			if not os.path.isfile(self.keyfile):
				raise Exception("Key file (%s) does not exist." %
						self.keyfile)
		# schedule regular cleanup
		joblist.append( { "callback":self.__search_cleaner, "context":None,
			"period":self.checkperiod, "ticks":1 } )
		# schedule regular submission of ready emails
		self.mail_type_penalization = {}
		joblist.append( { "callback":self.__sendEmails, "context":None,
			"period":self.sendperiod, "ticks":1 } )
		# schedule checks for unsuccessfull delivery of emails
		if self.undeliveredperiod > 0:
			joblist.append( { "callback":self.__checkUndelivered,"context":None,
				"period":self.undeliveredperiod, "ticks":1 } )
		self.l.log(self.l.INFO, "Object initialized")

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

	def __sendEmails(self, ctx):
		"""
		Method sends all emails stored in database and ready to be sent.
		"""
		self.l.log(self.l.DEBUG, "Regular send-emails procedure.")
		conn = self.db.getConn()
		# iterate over all emails from database ready to be sent
		for (mailid, mail_text, attachs) in self.__dbGetReadyEmailsTypePenalization(conn):
			try:
				# run email through completion procedure
				(mail, efrom) = self.__completeEmail(mailid, mail_text, attachs)
				# sign email if signing is enabled
				if self.signing:
					mail = self.__sign_email(mailid, mail)
				# send email
				status = self.__sendEmail(mailid, mail, efrom)
				# check sendmail status
				if status == 0:
					self.l.log(self.l.DEBUG, "<%d> Email with id %d was successfully"
							" sent." % (mailid, mailid))
					# archive email and status
					self.__dbUpdateStatus(conn, mailid, 0)
				else:
					self.l.log(self.l.ERR, "<%d> Sendmail exited with failure for "
						"email with id %d (rc = %d)" % (mailid, mailid, status))
					self.__dbSendFailed(conn, mailid)
			except Mailer_i.MailerException, me:
				self.l.log(self.l.ERR, "<%d> Error when sending email with "
						"mailid %d: %s" % (mailid, mailid, me))
				self.__dbSendFailed(conn, mailid)
			conn.commit()
		self.db.releaseConn(conn)

	def __checkUndelivered(self, ctx):
		"""
		Method sends all emails stored in database and ready to be sent.
		"""
		self.l.log(self.l.DEBUG, "Regular check-undelivered procedure.")
		# get emails from mailbox
		try:
			if self.IMAPssl:
				server = imaplib.IMAP4_SSL(self.IMAPserver, self.IMAPport)
			else:
				server = imaplib.IMAP4(self.IMAPserver, self.IMAPport)
			server.login(self.IMAPuser, self.IMAPpass)
			server.select()
			# XXX potencial source of error - hardcoded return.nic.cz
			(r, data) = server.search(None, '((UNSEEN) (TO return.nic.cz))')
			mailids = data[0].split(' ')
			if not mailids[0]:
				self.l.log(self.l.DEBUG, "No new undelivered messages.")
				server.close()
				server.logout()
				return
			pattern = re.compile("^[Tt][Oo]:\s+<?(\d+)@return\.nic\.cz.*$")
			self.l.log(self.l.DEBUG, "%d new undelivered messages" %len(mailids))
			conn = None
			for mailid in mailids:
				if not conn:
					conn = self.db.getConn()
				temp = server.fetch(mailid, "(BODY[HEADER.FIELDS (TO)])")
				to_header = temp[1][0][1].strip()
				m = pattern.match(to_header)
				if m:
					msgid = int(m.groups()[0])
					msgbody = server.fetch(mailid, "(RFC822)")[1][0][1]
					self.l.log(self.l.DEBUG, "Email with ID %d undelivered." %
							msgid)
					try:
						self.__dbSetUndelivered(conn, msgid, msgbody)
						server.store(mailid, 'FLAGS', '(\Deleted)')
					except ccReg.Mailer.UnknownMailid, e:
						self.l.log(self.l.WARNING, "Mail with id %s not sent."%e)
				else:
					self.l.log(self.l.WARNING, "Invalid email identifier found.")
			if conn:
				conn.commit()
				self.db.releaseConn(conn)
			server.expunge()
			server.close()
			server.logout()
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "Database error: %s" % e)
		except imaplib.IMAP4.error, e:
			self.l.log(self.l.ERR, "IMAP protocol error: %s" % e)

	def __getFileManagerObject(self):
		"""
		Method retrieves FileManager object from nameservice.
		"""
		# Resolve the name "fred.context/FileManager.Object"
		name = [CosNaming.NameComponent(self.fm_context, "context"),
				CosNaming.NameComponent(self.fm_object, "Object")]
		obj = self.corba_refs.nsref.resolve(name)
		# Narrow the object to an ccReg::FileManager
		filemanager_obj = obj._narrow(ccReg.FileManager)
		return filemanager_obj

	def __dbGetVcard(self, conn):
		"""
		Get vcard attachment from database.
		"""
		cur = conn.cursor()
		cur.execute("SELECT vcard FROM mail_vcard")
		vcard = cur.fetchone()[0]
		cur.close()
		return vcard

	def __dbGetMailTypeData(self, conn, mailtype):
		"""
		Method returns subject template, attachment templates and their content
		types.
		"""
		cur = conn.cursor()
		# get mail type data
		cur.execute("SELECT id, subject FROM mail_type WHERE name = %s", [mailtype])
		if cur.rowcount == 0:
			cur.close()
			self.l.log(self.l.ERR, "Mail type '%s' was not found in db." %
					mailtype)
			raise ccReg.Mailer.UnknownMailType(mailtype)

		id, subject = cur.fetchone()

		# get templates belonging to mail type
		cur.execute("SELECT mte.contenttype, mte.template, mf.footer "
				"FROM mail_type_template_map mt, mail_templates mte "
				"LEFT JOIN mail_footer mf ON (mte.footer = mf.id) "
				"WHERE mt.typeid = %d AND mt.templateid = mte.id", [id])
		templates = []
		if cur.rowcount == 0:
			self.l.log(self.l.WARNING, "Request for mail type ('%s') with no "
					"associated templates." % mailtype)
		else:
			for row in cur.fetchall():
				# append footer if there is any to template
				if row[2]:
					templates.append( {"type":row[0],
						"template":row[1] +'\n'+ row[2]} )
				else:
					templates.append( {"type":row[0], "template":row[1]} )
		cur.close()
		return id, subject, templates

	def __dbSetHeaders(self, conn, mailid, subject, header, msg):
		"""
		Method initializes headers of email object. Header struct is modified
		as well, which is important for actual value of envelope sender.
		Date header is added later and Message-ID is later revisited.
		"""
		# get default values from database
		cur = conn.cursor()
		cur.execute("SELECT h_from, h_replyto, h_errorsto, h_organization, "
				"h_contentencoding, h_messageidserver FROM mail_header_defaults")
		defaults = cur.fetchone()
		cur.close()
		# headers which don't have defaults
		msg["Subject"] = qp_str(subject)
		msg["To"] = filter_email_addrs(header.h_to)
		# 'To:' is the only mandatory header
		if not msg["To"]:
			raise ccReg.Mailer.InvalidHeader("To")
		if header.h_cc: msg["Cc"] = filter_email_addrs(header.h_cc)
		if header.h_bcc: msg["Bcc"] = filter_email_addrs(header.h_bcc)
		# modify header struct in place based on default values
		if not header.h_from:
			header.h_from = defaults[0]
		if not header.h_reply_to:
			header.h_reply_to = defaults[1]
		if not header.h_errors_to:
			header.h_errors_to = defaults[2]
		if not header.h_organization:
			header.h_organization = defaults[3]
		# headers which have default values
		msg["Message-ID"] = "<%d.%d@%s>" %(mailid, int(time.time()), defaults[5])
		msg["From"] = header.h_from
		msg["Reply-to"] = header.h_reply_to
		msg["Errors-to"] = header.h_errors_to
		msg["Organization"] = qp_str(header.h_organization)

	def __dbNewEmailId(self, conn):
		"""
		Get next available ID of email. This ID is used in message-id header and
		when archiving email.
		"""
		cur = conn.cursor()
		cur.execute("SELECT nextval('mail_archive_id_seq')")
		id = cur.fetchone()[0]
		cur.close()
		return int(id)

	def __dbArchiveEmail(self, conn, mailid, mailtype_id, mail, handles,
			attachs = []):
		"""
		Method archives email in database.
		"""
		cur = conn.cursor()
		# save the generated email
		cur.execute("INSERT INTO mail_archive (id, mailtype, message, status) "
				"VALUES (%d, %d, %s, %d)",
				[mailid, mailtype_id, mail, self.archstatus] )
		for handle in handles:
			cur.execute("INSERT INTO mail_handles (mailid, associd) VALUES "
					"(%d, %s)", [mailid, handle])
		for attachid in attachs:
			cur.execute("INSERT INTO mail_attachments (mailid, attachid) VALUES"
					" (%d, %s)", [mailid, attachid])
		cur.close()

	def __dbGetReadyEmails(self, conn):
		"""
		Get all emails from database which are ready to be sent.
		"""
		cur = conn.cursor()
		cur.execute("SELECT mar.id, mar.message, mat.attachid "
				"FROM mail_archive mar LEFT JOIN mail_attachments mat "
				"ON (mar.id = mat.mailid) "
				"WHERE mar.status = 1 AND mar.attempt < %d", [self.maxattempts])
		rows = cur.fetchall()
		cur.close()
		# transform result attachids in list
		result = []
		for row in rows:
			if len(result) == 0 or result[-1][0] != row[0]:
				if row[2]:
					result.append( (row[0], row[1], [row[2]]) )
				else:
					result.append( (row[0], row[1], []) )
			else:
				result[-1][2].append(row[2])

		return result

	def __dbGetReadyEmailsTypePenalization(self, conn):
		"""
		Get all emails from database which are ready to be send fairly by mail type.
		"""
		cur = conn.cursor()

		penalized = []
		if len(self.mail_type_penalization):
			for mt in self.mail_type_penalization.keys():
				penalized.append(mt)
				if self.mail_type_penalization[mt] == 0:
					del self.mail_type_penalization[mt]
				else:
					self.mail_type_penalization[mt] -= 1

		self.l.log(self.l.DEBUG, "mail types penalized in query: %s" % str(penalized))

		cur.execute("SELECT mar.id, mar.mailtype, mar.message, "
			"array_filter_null(array_accum(mat.attachid)) "
			"FROM mail_archive mar LEFT JOIN mail_attachments mat "
			"ON mar.id = mat.mailid "
			"WHERE mar.status = 1 AND mar.attempt < %d "
			"AND NOT mar.mailtype =ANY(%s::integer[]) "
			"GROUP BY mar.id, mar.mailtype, mar.message LIMIT %d",
			[self.maxattempts, convList2Array(penalized), self.sendlimit])

		rows = cur.fetchall()
		cur.close()

		if len(rows) == 0:
			self.l.log(self.l.DEBUG, "no mails selected")
			if len(penalized) > 0:
				self.mail_type_penalization = {}
				self.l.log(self.l.DEBUG, "penalties used => now dropping and re-run")
				return self.__dbGetReadyEmailsTypePenalization(conn)
			else:
				return []

		# convert db array to list and get mail type count statistics
		type_stats = {}
		result = []
		for m_id, m_type, m_body, m_attach_ids in rows:
			result.append([m_id, m_body, [int(i) for i in convArray2List(m_attach_ids)]])
			type_stats[m_type] = type_stats.get(m_type, 0) + 1

		self.l.log(self.l.DEBUG, "mail type distribution: %s" % str(type_stats))

		# count penalties for next round
		for mt, mc in type_stats.items():
			if (float(mc) / self.sendlimit) > 0.3:
				self.mail_type_penalization[mt] = 1
				self.l.log(self.l.DEBUG, "mail type %d penalization scheduled" % int(mt))

		return result

	def __dbUpdateStatus(self, conn, mailid, status, reset_counter = False):
		"""
		Set status value in mail archive. Meaning of status values are:

		  0: Mail was successfully sent.
		  1: Mail is ready to be sent.
		  2: Mail waits for manual confirmation.
		  3: This email will not be sent or touched by mailer.
		  4: Delivery of email failed.

		If reset_counter is true, then counter of unsuccessfull sendmail
		attempts is set to 0.
		"""
		cur = conn.cursor()
		if reset_counter:
			cur.execute("UPDATE mail_archive "
					"SET status = %d, moddate = now(), attempt = 0 "
					"WHERE id = %d", [status, mailid])
		else:
			cur.execute("UPDATE mail_archive "
					"SET status = %d, moddate = now() "
					"WHERE id = %d", [status, mailid])
		if cur.rowcount != 1:
			raise ccReg.Mailer.UnknownMailid(mailid)
		cur.close()

	def __dbSetUndelivered(self, conn, mailid, mail):
		"""
		Set status value and insert text of email notification in mail archive.
		"""
		cur = conn.cursor()
		cur.execute("UPDATE mail_archive "
				"SET status = 4, moddate = now(), response = %s "
				"WHERE id = %d", [base64.b64encode(mail), mailid])
		if cur.rowcount != 1:
			raise ccReg.Mailer.UnknownMailid(mailid)
		cur.close()

	def __dbSendFailed(self, conn, mailid):
		"""
		Increment counter of failed attempts to send email.
		"""
		cur = conn.cursor()
		cur.execute("UPDATE mail_archive "
				"SET attempt = attempt + 1, moddate = now() "
				"WHERE id = %d", [mailid])
		cur.close()

	def __dbGetDefaults(self, conn):
		"""
		Retrieve defaults from database.
		"""
		cur = conn.cursor()
		cur.execute("SELECT name, value FROM mail_defaults")
		pairs = [ (line[0], line[1]) for line in cur.fetchall() ]
		cur.close()
		return pairs

	def __dbGetMailTypes(self, conn):
		"""
		Get mapping between ids and names of mailtypes.
		"""
		cur = conn.cursor()
		cur.execute("SELECT id, name FROM mail_type")
		result = cur.fetchall()
		cur.close()
		return result

	def __completeEmail(self, mailid, mail_text, attachs):
		"""
		Method attaches base64 attachments, few email headers to email message.
		"""
		# Create email object and init headers
		msg = email.message_from_string(mail_text)

		filemanager = None
		# attach not templated attachments (i.e. pdfs)
		for attachid in attachs:
			# initialize filemanager if it is first iteration
			if not filemanager:
				try:
					filemanager = self.__getFileManagerObject()
				except CosNaming.NamingContext.NotFound, e:
					raise Mailer_i.MailerException("Could not get File "
							"Manager's reference: %s" % e)
				if filemanager == None:
					raise Mailer_i.MailerException("FileManager reference is "
							"not filemanager.")
			# get attachment from file manager
			self.l.log(self.l.DEBUG, "<%d> Sending request for attachment with "
					"id %d" % (mailid, attachid))
			try:
				# get MIME type of attachment
				attachinfo = filemanager.info(attachid)
				# create attachment
				if not attachinfo.mimetype or attachinfo.mimetype.find("/") < 0:
					# provide some defaults
					maintype = "application"
					subtype = "octet-stream"
				else:
					maintype, subtype = attachinfo.mimetype.split("/")
				part = MIMEBase(maintype, subtype)
				if attachinfo.name:
					part.add_header('content-disposition', 'attachment',
							filename=attachinfo.name)
				# get raw data of attachment
				loadobj = filemanager.load(attachid)
				attachdata = ""
				chunk = loadobj.download(2**14) # download 16K chunk
				while chunk:
					attachdata += chunk
					chunk = loadobj.download(2**14) # download 16K chunk
				loadobj.finalize_download()
				# encode attachment
				part.set_payload(attachdata)
				Encoders.encode_base64(part)
				msg.attach(part)

			except ccReg.FileManager.IdNotFound, e:
				raise Mailer_i.MailerException("Non-existing id of attachment "
						"%d given." % attachid)
			except ccReg.FileManager.FileNotFound, e:
				raise Mailer_i.MailerException("For attachment with id %d is "
						"missing file." % attachid)
			except ccReg.FileDownload.InternalError, e:
				raise Mailer_i.MailerException("Internal error when "
						"downloading attachment with id %d: %s" %
						(attachid, e.message))
			except ccReg.FileDownload.NotActive, e:
				raise Mailer_i.MailerException("Download object for attachment "
						"with id %d is not active anymore: %s" %
						(attachid, e.message))

		msg["Date"] = formatdate(localtime=True)
		# Message-ID contains the domain part, which is needed in envelope From.
		domain = msg["Message-ID"][(msg["Message-ID"].find('@') + 1):-1]
		envelope_from = "%d@return.%s" % (mailid, domain)
		# parseaddr returns sender's name and sender's address
		return contentfilter(msg.as_string(), msg.is_multipart()), envelope_from

	def __sign_email(self, mailid, mail):
		"""
		Routine for signing of email.
		"""
		# before signing remove non-MIME headers
		headerend_index = mail.find("\n\n") # find empty line
		headers = mail[:headerend_index+1]
		mimeheaders = ""
		signedmail = ""
		# throw away otherwise duplicated headers
		for header in headers.splitlines():
			if header.startswith("MIME-Version:") or \
					header.startswith("Content-Type:") or \
					header.startswith("Content-Transfer-Encoding:"):
				mimeheaders += header + '\n'
			else:
				signedmail += header + '\n'
		mail = mimeheaders + mail[headerend_index+1:]
		# create temporary file for openssl which will be used as input
		tmpfile = tempfile.mkstemp(prefix="pyfred-smime")
		os.write(tmpfile[0], mail)
		os.close(tmpfile[0])
		# do the signing
		stat, outdata, errdata = runCommand(mailid, "%s smime -sign -signer %s -inkey %s -in %s" %
				   (self.openssl, self.certfile, self.keyfile, tmpfile[1]), None, self.l)
		os.remove(tmpfile[1])
		
		if stat:
			if errdata:
				err = errdata
			else:
				err = ''
			self.l.log(self.l.ERR, "<%d> Openssl exited with failure (%d): %s" % (mailid, stat, err))
			raise Mailer_i.MailerException("Signing of email failed.")
		signedmail += outdata
		return signedmail

	def __sendEmail(self, mailid, mail, envelope_from):
		"""
		This routine sends email.
		"""
		# this tranformation guaranties that each line is terminated by crlf
		mail = mail.replace('\r', '')
		mail = mail.replace('\n', '\r\n')

		# send email
		if self.testmode:
			# if tester is not set, do nothing
			if self.tester:
				status, outdata, errdata = runCommand(mailid, "%s -f %s %s" % (self.sendmail, envelope_from, self.tester), 
													mail, self.l)
			else:
				status = 0
		else:
			status, outdata, errdata = runCommand(mailid, "%s -f %s -t" % (self.sendmail, envelope_from), 
												  mail, self.l)

		if status is None: status = 0 # ok
		else: status = int(status) # sendmail failed

		return status

	def __prepareEmail(self, conn, mailid, mailtype, header, data, attlen):
		"""
		Method creates text part of email, it means without base64 encoded
		attachments. This includes following steps:

			1) Create HDF dataset (base of templating)
			2) Template subject
			3) Run templating for all wanted templates and attach them
			4) Create email headers
			5) Dump email in string form
		"""
		# init headers
		hdf = neo_util.HDF()
		# pour defaults in data set
		for pair in self.__dbGetDefaults(conn):
			hdf.setValue("defaults." + pair[0], pair[1])
		# pour user provided values in data set
		for pair in data:
			hdf.setValue(pair.key, pair.value)

		mailtype_id, subject_tpl, templates = self.__dbGetMailTypeData(conn,
				mailtype)

		# render subject
		cs = neo_cs.CS(hdf)
		cs.parseStr(subject_tpl)
		subject = cs.render()

		# Create email object multi or single part (we have to decide now)
		if attlen > 0 or len(templates) > 1 or self.vcard:
			msg = MIMEMultipart()
			# render text attachments
			for item in templates:
				cs = neo_cs.CS(hdf)
				cs.parseStr(item["template"])
				mimetext = MIMEText(cs.render().strip() + '\n', item["type"])
				mimetext.set_charset("utf-8")
				# Leave this commented out, otherwise it duplicates header
				#   Content-Transfer-Encoding
				#Encoders.encode_7or8bit(mimetext)
				msg.attach(mimetext)
			# Attach vcard attachment if configured so
			if self.vcard:
				mimetext = MIMEText(self.vcard, "x-vcard")
				mimetext.set_charset("utf-8")
				msg.attach(mimetext)
		else:
			# render text attachment
			cs = neo_cs.CS(hdf)
			cs.parseStr(templates[0]["template"])
			msg = MIMEText(cs.render().strip()+'\n', templates[0]["type"])
			msg.set_charset("utf-8")

		# init email header (BEWARE that header struct is modified in this
		# call to function, so it is filled with defaults for not provided
		# headers, which is important for obtaining envelope sender).
		self.__dbSetHeaders(conn, mailid, subject, header, msg)
		return msg.as_string(), mailtype_id

	def mailNotify(self, mailtype, header, data, handles, attachs, preview):
		"""
		Method from IDL interface. It runs data through appropriate templates
		and generates an email. The text of the email and operation status must
		be archived in database.
		"""
		conn = None
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Email-Notification request received "
					"(preview = %s)" % (id, preview))

			# connect to database
			conn = self.db.getConn()
			# get unique email id (based on primary key from database)
			mailid = self.__dbNewEmailId(conn)

			mail_text, mailtype_id = self.__prepareEmail(conn, mailid, mailtype,
					header, data, len(attachs))

			if preview:
				return (mailid, mail_text)

			# archive email (without non-templated attachments)
			self.__dbArchiveEmail(conn, mailid, mailtype_id, mail_text, handles,
					attachs)
			# commit changes in mail archive
			conn.commit()

			return (mailid, "")

		except ccReg.Mailer.InternalError, e:
			raise
		except ccReg.Mailer.UnknownMailType, e:
			raise
		except ccReg.Mailer.InvalidHeader, e:
			self.l.log(self.l.ERR, "<%d> Header 'To' is empty." % id)
			raise
		except neo_util.ParseError, e:
			self.l.log(self.l.ERR, "<%d> Error when parsing template: %s" %
					(id, e))
			raise ccReg.Mailer.InternalError("Template error")
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.Mailer.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.Mailer.InternalError("Unexpected error")
		finally:
			self.db.releaseConn(conn)

	def resend(self, mailid):
		"""
		Resend email from mail archive with given id. This includes zeroing of
		counter of unsuccessfull sendmail attempts and setting status to 1.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> resend request for email with id = "
					"%d received." % (id, mailid))

			conn = self.db.getConn()
			self.__dbUpdateStatus(conn, mailid, 1, True)
			conn.commit()
			self.db.releaseConn(conn)

		except ccReg.Mailer.UnknownMailid, e:
			self.l.log(self.l.ERR, "<%d> Unknown mailid %d." % (id, mailid))
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.Mailer.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.Mailer.InternalError("Unexpected error")

	def getMailTypes(self):
		"""
		Return mapping between ids of email types and their names.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> get-mailtypes request received." % id)

			# connect to database
			conn = self.db.getConn()
			codelist = self.__dbGetMailTypes(conn)
			self.db.releaseConn(conn)
			return [ ccReg.MailTypeCode(item[0], item[1]) for item in codelist ]

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.Mailer.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.Mailer.InternalError("Unexpected error")

	def createSearchObject(self, filter):
		"""
		This is universal mail archive lookup function. It returns object
		reference which can be used to access data.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Search create request received." % id)

			# construct SQL query coresponding to filter constraints
			conditions = []
			condvalues = []
			if filter.mailid != -1:
				conditions.append("ma.id = %d")
				condvalues.append(filter.mailid)
			if filter.mailtype != -1:
				conditions.append("ma.mailtype = %d")
				condvalues.append(filter.mailtype)
			if filter.status != -1:
				conditions.append("ma.status = %d")
				condvalues.append(filter.status)
			if filter.handle:
				conditions.append("mh.associd = %s")
				condvalues.append(filter.handle)
			if filter.attachid != -1:
				conditions.append("mt.attachid = %d")
				condvalues.append(filter.attachid)
			fromdate = filter.crdate._from
			if not isInfinite(fromdate):
				conditions.append("ma.crdate > '%d-%d-%d %d:%d:%d'" %
						(fromdate.date.year,
						fromdate.date.month,
						fromdate.date.day,
						fromdate.hour,
						fromdate.minute,
						fromdate.second))
			todate = filter.crdate.to
			if not isInfinite(todate):
				conditions.append("ma.crdate < '%d-%d-%d %d:%d:%d'" %
						(todate.date.year,
						todate.date.month,
						todate.date.day,
						todate.hour,
						todate.minute,
						todate.second))
			if filter.fulltext:
				conditions.append("ma.message LIKE '%%\%s%%'")
				condvalues.append(filter.fulltext[1:-1])
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
			# execute MEGA GIGA query :(
			cur.execute("SELECT ma.id, ma.mailtype, ma.crdate, ma.moddate, "
						"ma.status, ma.message, mt.attachid, mh.associd "
					"FROM mail_archive ma "
					"LEFT JOIN mail_handles mh ON (ma.id = mh.mailid) "
					"LEFT JOIN mail_attachments mt ON (ma.id = mt.mailid) "
					"%s ORDER BY ma.id" % cond, condvalues)
			self.db.releaseConn(conn)
			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor: %d" %
					(id, cur.rowcount))

			# Create an instance of MailSearch_i and an MailSearch object ref
			searchobj = MailSearch_i(id, cur, self.l)
			self.search_objects.put(searchobj)
			searchref = self.corba_refs.rootpoa.servant_to_reference(searchobj)
			return searchref

		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e))
			raise ccReg.Mailer.InternalError("Database error")
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.Mailer.InternalError("Unexpected error")


class MailSearch_i (ccReg__POA.MailSearch):
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

	def __get_one_search_result(self):
		"""
		Fetch one mail from archive. The problem is that attachments and handles
		must be transformed from cursor rows to lists.
		"""
		if not self.lastrow:
			return None
		prev = self.lastrow
		curr = self.cursor.fetchone()
		id = prev[0]
		mtid = prev[1]
		crdate = prev[2]
		if prev[3]: # moddate may be NULL
			moddate = prev[3]
		else:
			moddate = ""
		if prev[4] == None: # status may be NULL
			status = -1
		else:
			status = prev[4]
		message = prev[5]
		if prev[6]: # attachment may be NULL
			attachs = [prev[6]]
		else:
			attachs = []
		if prev[7]: # handle may be NULL
			handles = [prev[7]]
		else:
			handles = []
		# process all rows with the same id
		while curr and id == curr[0]: # while the ids are same
			if curr[6]:
				if curr[6] not in attachs:
					attachs.append(curr[6])
			if curr[7]:
				if curr[7] not in handles:
					handles.append(curr[7])
			curr = self.cursor.fetchone() # move to next row
		# save leftover
		self.lastrow = curr
		return id, mtid, crdate, moddate, status, message, handles, attachs

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
			maillist = []
			for i in range(count):
				if not self.lastrow:
					break
				(id, mailtypeid, crdate, moddate, status, message, handles,
						attachs) = self.__get_one_search_result()
				# create email structure
				maillist.append( ccReg.Mail(id, mailtypeid, crdate, moddate,
					status, handles, message, attachs) )

			self.l.log(self.l.DEBUG, "<%d> Number of records returned: %d." %
					(self.id, len(maillist)))
			return maillist

		except ccReg.MailSearch.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.MailSearch.InternalError("Unexpected error")

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
			raise ccReg.MailSearch.InternalError("Unexpected error")


def init(logger, db, conf, joblist, corba_refs):
	"""
	Function which creates, initializes and returns servant Mailer.
	"""
	# Create an instance of Mailer_i and an Mailer object ref
	servant = Mailer_i(logger, db, conf, joblist, corba_refs)
	return servant, "Mailer"
