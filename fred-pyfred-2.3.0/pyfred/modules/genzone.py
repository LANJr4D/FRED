#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Code of server-side of zone generator.
"""

import sys, time, random, ConfigParser, Queue
import pgdb
import base64
from pyfred import dnssec
from pyfred.idlstubs import ccReg, ccReg__POA
from pyfred.utils import ipaddrs2list

def createNs(domain, nsFqdn, addrs):
	"""
Create structure defined in idl for holding nameserver record. However it
is not so easy.  If nameserver's fqdn has suffix domain preceeded be a
dot, then list of addresses should not be empty.  If domain preceeded be
a dot is not a suffix of nameserver's fqdn, then the list of addresses
should be empty, if not, the structure is still created but with empty list
of addresses.
	"""
	if nsFqdn.endswith("." + domain):
		warning = None
		if not addrs:
			warning = "Missing GLUE for nameserver '%s' of domain '%s'." % \
					(nsFqdn, domain)
		return ccReg.DNSHost_str(nsFqdn, addrs), warning
	else:
		# we don't emit warning for GLUE which is not needed, since nsset
		# can be shared across various zones.
		return ccReg.DNSHost_str(nsFqdn, []), None

class ZoneGenerator_i (ccReg__POA.ZoneGenerator):
	"""
This class implements interface used for generation of a zone file.
	"""

	def __init__(self, logger, db, conf, joblist, corba_refs):
		"""
	Initializer saves db object (which is later used for opening database
	connection) and logger (used for logging). Transfer sequencer is
	initialized to 0 and dict of transfers is initialized to empty dict.
		"""
		# ccReg__POA.ZoneGenerator doesn't have constructor
		self.db = db  # db object
		self.l = logger # syslog functionality
		self.corba_refs = corba_refs # root poa for new servants
		self.zone_objects = Queue.Queue(-1) # list of current transfers

		self.idletreshold = 3600
		self.checkperiod = 60
		# Parse genzone-specific configuration
		if conf.has_section("Genzone"):
			# idle treshold
			try:
				self.idletreshold = conf.getint("Genzone", "idletreshold")
				self.l.log(self.l.DEBUG, "idletreshold is set to %d." %
						self.idletreshold)
			except ConfigParser.NoOptionError, e:
				pass
			# check period
			try:
				self.checkperiod = conf.getint("Genzone", "checkperiod")
				self.l.log(self.l.DEBUG, "checkperiod is set to %d." %
						self.checkperiod)
			except ConfigParser.NoOptionError, e:
				pass

		# schedule regular cleanup
		joblist.append( { "callback":self.__genzone_cleaner, "context":None,
			"period":self.checkperiod, "ticks":1 } )
		self.l.log(self.l.INFO, "Object initialized")

	def __genzone_cleaner(self, ctx):
		"""
	Method deletes closed or idle zonedata objects.
		"""
		self.l.log(self.l.DEBUG, "Regular maintance procedure.")
		remove = []
		# the queue may change and the number of items in the queue may grow
		# but we can be sure that there will be never less items than nitems
		# therefore we can use blocking call get() on queue
		nitems = self.zone_objects.qsize()
		for i in range(nitems):
			item = self.zone_objects.get()
			# test idleness of object
			if time.time() - item.lastuse > self.idletreshold:
				item.status = item.IDLE

			# schedule objects to be deleted
			if item.status == item.CLOSED:
				self.l.log(self.l.DEBUG, "Closed zone-object with id %d "
						"destroyed." % item.id)
				remove.append(item)
			elif item.status == item.IDLE:
				self.l.log(self.l.DEBUG, "Idle zone-object with id %d "
						"destroyed." % item.id)
				remove.append(item)
			# if object is active - reinsert the object in queue
			else:
				self.l.log(self.l.DEBUG, "zone-object with id %d and type %s "
							"left in queue." % (item.id, item.__class__.__name__))
				self.zone_objects.put(item)

		queue = self.zone_objects 
		self.l.log(self.l.DEBUG, '%d objects are scheduled to deletion and %d left in queue' % (len(remove), queue.qsize()))
        
		# delete objects scheduled for deletion
		rootpoa = self.corba_refs.rootpoa
		for item in remove:
			id = rootpoa.servant_to_id(item)
			rootpoa.deactivate_object(id)

	def __dbGetStaticData(self, conn, zonename, id):
		"""
	Method returns so-called static data for a zone (don't change often).
		"""
		cur = conn.cursor()
		# following data are called static since they are not expected to
		# change very often. Though they are stored in database and must
		# be sent back together with dynamic data
		cur.execute("SELECT z.id, zs.ttl, zs.hostmaster, zs.serial, zs.refresh,"
				"zs.update_retr, zs.expiry, zs.minimum, zs.ns_fqdn "
				"FROM zone z, zone_soa zs WHERE zs.zone = z.id AND z.fqdn = %s",
				[zonename])
		if cur.rowcount == 0:
			cur.close()
			self.l.log(self.l.ERR, "<%d> Zone '%s' does not exist or does not "
					"have associated SOA record." % (id, zonename))
			raise ccReg.ZoneGenerator.UnknownZone()
		(zoneid, ttl, hostmaster, serial, refresh, update_retr, expiry, minimum,
				ns_fqdn) = cur.fetchone()
		# create a list of nameservers for the zone
		cur.execute("SELECT fqdn, addrs FROM zone_ns WHERE zone = %d", [zoneid])
		nameservers = []
		for i in range(cur.rowcount):
			row = cur.fetchone()
			nsFqdn = row[0]
			nsAddrs = ipaddrs2list(row[1])
			ns, wmsg = createNs(zonename, nsFqdn, nsAddrs)
			if wmsg:
				self.l.log(self.l.WARNING, "<%d> %s" % (id, wmsg))
			nameservers.append(ns)
		cur.close()

		# if the serial is not given we will construct it on the fly
		if not serial:
			# default is unix timestamp
			serial = int(time.time()).__str__()
		else:
			serial = serial.__str__()

		return (ttl, hostmaster, serial, refresh, update_retr, expiry, minimum,
				ns_fqdn, nameservers)

	def __dbGetDynamicData(self, conn, zonename):
		"""
	Method returns so-called dynamic data for a zone (are fluctuant).
		"""
		cur = conn.cursor()
		# get id of zone and its type
		cur.execute("SELECT id, enum_zone FROM zone WHERE fqdn = %s",
				[zonename])
		if cur.rowcount == 0:
			cur.close()
			raise ccReg.ZoneGenerator.UnknownZone()
		zoneid, isenum = cur.fetchone()

		# put together domains and their nameservers
		cur.execute("SELECT oreg.name, host.fqdn, a.ipaddr, oreg.id "
			"FROM object_registry oreg, "
				"(host LEFT JOIN host_ipaddr_map a ON (host.id = a.hostid)), "
				"(domain d LEFT JOIN object_state_now osn ON (d.id = osn.object_id)) "
			"WHERE (NOT (15 = ANY (osn.states)) OR osn.states IS NULL) "
				"AND d.id = oreg.id AND d.nsset = host.nssetid AND d.zone = %d "
			"ORDER BY oreg.id, host.fqdn", [zoneid])
		
		# get ds records for generated domains, they will be fetched parallel
		# to the main list
		cur2 = conn.cursor()
		cur2.execute("SELECT d.id, ds.keyTag, ds.alg, ds.digestType,"
					 "ds.digest, ds.maxSigLife FROM domain d "
					 "LEFT JOIN object_state os ON (os.object_id=d.id AND "
					 "os.valid_to ISNULL AND os.state_id = 15) "
					 "JOIN dsrecord ds ON (ds.keysetid = d.keyset) "
					 "WHERE os.state_id IS NULL AND d.zone = %d "  
					 "ORDER BY d.id ", [zoneid])

		# get dnskeys for generated domains, they will be fetched parallel
		# to the main list
		cur3 = conn.cursor()
		cur3.execute("SELECT d.id, k.flags, k.protocol, k.alg, k.key "
					 "FROM domain d "
					 "LEFT JOIN object_state os ON (os.object_id=d.id AND "
					 "os.valid_to ISNULL AND os.state_id = 15) "
					 "JOIN dnskey k ON (k.keysetid = d.keyset) "
					 "WHERE os.state_id IS NULL AND d.zone = %d "  
					 "ORDER BY d.id ", [zoneid])

		
		return cur, cur2, cur3

	def getSOA(self, zonename):
		"""
	Method sends back data needed for SOA record construction (ttl, hostmaster,
	serial, refresh, update_retr, expiry, minimum, primary nameserver,
	secondary nameservers).
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> get-SOA request of the zone '%s' "
					"received." % (id, zonename))
			# connect to database
			conn = self.db.getConn()

			(soa_ttl, soa_hostmaster, soa_serial, soa_refresh,
					soa_update_retr, soa_expiry, soa_minimum, soa_ns_fqdn,
					nameservers) = self.__dbGetStaticData(conn, zonename, id)

			self.db.releaseConn(conn)

			# well done
			return (zonename,
				soa_ttl,
				soa_hostmaster,
				soa_serial,
				soa_refresh,
				soa_update_retr,
				soa_expiry,
				soa_minimum,
				soa_ns_fqdn,# soa nameserver
				nameservers) # zone nameservers

		except ccReg.ZoneGenerator.InternalError, e:
			raise
		except ccReg.ZoneGenerator.UnknownZone, e:
			self.l.log(self.l.ERR, "<%d> Zone '%s' does not exist." %
					(id, zonename))
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e));
			raise ccReg.ZoneGenerator.InternalError("Database error");
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caught: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.ZoneGenerator.InternalError("Unexpected error")

	def generateZone(self, zonename):
		"""
	Method sends back static data (ttl, hostmaster, serial, refresh,
	update_retr, expiry, minimum, primary nameserver, secondary nameservers).
	Dynamic data (domains and their nameservers) are left to be processed later
	by smaller peaces.
		"""
		try:
			id = random.randint(1, 9999)
			self.l.log(self.l.INFO, "<%d> Generation of the zone '%s' requested."
					% (id, zonename))
			# connect to database
			conn = self.db.getConn()

			# now comes the hard part, getting dynamic data (lot of data ;)
			(cursor, cursor2, cursor3) = self.__dbGetDynamicData(conn, zonename)
			conn.commit()
			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor: %d." %
					(id, cursor.rowcount))
			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor2: %d." %
					(id, cursor2.rowcount))
			self.l.log(self.l.DEBUG, "<%d> Number of records in cursor3: %d." %
					(id, cursor3.rowcount))
			self.db.releaseConn(conn)

			# Create an instance of ZoneData_i and an ZoneData object ref
			zone_obj = ZoneData_i(id, cursor, cursor2, cursor3, self.l)
			self.zone_objects.put(zone_obj)
			zone_ref = self.corba_refs.rootpoa.servant_to_reference(zone_obj)

			# well done
			return zone_ref # Reference to ZoneData object

		except ccReg.ZoneGenerator.InternalError, e:
			raise
		except ccReg.ZoneGenerator.UnknownZone, e:
			self.l.log(self.l.ERR, "<%d> Zone '%s' does not exist." %
					(id, zonename))
			raise
		except pgdb.DatabaseError, e:
			self.l.log(self.l.ERR, "<%d> Database error: %s" % (id, e));
			raise ccReg.ZoneGenerator.InternalError("Database error");
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caught: %s:%s" %
					(id, sys.exc_info()[0], e))
			raise ccReg.ZoneGenerator.InternalError("Unexpected error")
	
	def getZoneNameList(self):
		"""
	Method sends back list of all domains managed by registry
		"""
		conn = self.db.getConn()
		cur = conn.cursor()
		cur.execute("SELECT fqdn FROM zone")
		zonelist = [row[0] for row in cur.fetchall()]
		cur.close()
		self.db.releaseConn(conn)
		return zonelist

class ZoneData_i (ccReg__POA.ZoneData):
	"""
Class encapsulating zone data.
	"""

	# statuses of zone object
	ACTIVE = 1
	CLOSED = 2
	IDLE = 3

	def __init__(self, id, cursor, cursor2, cursor3, log):
		"""
	Initializes zonedata object.
		"""
		self.l = log
		self.id = id
		self.cursor = cursor
		self.cursor2 = cursor2
		self.cursor3 = cursor3
		self.status = self.ACTIVE
		self.crdate = time.time()
		self.lastuse = self.crdate
		self.lastrow = cursor.fetchone()
		self.lastds = cursor2.fetchone()
		self.lastkey = cursor3.fetchone()

	def __get_one_domain(self):
		"""
	This function gets on input rows with columns (domain, host name, host
	address) sorted in this order. The task is to return one domain, list
	of its nameservers and list of ip addresses of its nameservers of
	the domain.
		"""
		if not self.lastrow:
			return None, None, None, None, None
		prev = self.lastrow
		curr = self.cursor.fetchone()
		domainname = prev[0]
		domain = prev[3]
		nameservers = [ prev[1] ]
		ipaddrs = {}
		if prev[2]:
			ipaddrs[prev[1]] = [ prev[2] ]
		else:
			ipaddrs[prev[1]] = []

		# process all rows with the same domain name
		while curr and domain == curr[3]: # while the domain names are same
			if curr[1] not in nameservers:
				nameservers.append(curr[1])
				if curr[2]:
					ipaddrs[ curr[1] ] = [ curr[2] ]
				else:
					ipaddrs[ curr[1] ] = []
			else:
				if curr[2] and curr[2] not in ipaddrs[ curr[1] ]:
					ipaddrs[ curr[1] ].append(curr[2])
			curr = self.cursor.fetchone() # move to next row

		# first while cycle solves problem when cursor2 has some new domains
		# not catched by cursor. it will iterate through them without stop
		while self.lastds and self.lastds[0] < domain:
			self.lastds = self.cursor2.fetchone() 
		dslist = []
		while self.lastds and self.lastds[0] == domain:
			dslist.append(self.lastds)
			self.lastds = self.cursor2.fetchone()
		# the same for dnskeys
		while self.lastkey and self.lastkey[0] < domain:
			self.lastkey = self.cursor3.fetchone() 
		keylist = []
		while self.lastkey and self.lastkey[0] == domain:
			keylist.append(self.lastkey)
			self.lastkey = self.cursor3.fetchone()
            
		# save leftover
		self.lastrow = curr
		return domainname, nameservers, ipaddrs, dslist, keylist

	def getNext(self, count):
		"""
	Method sends back dynamic data associated with particular zone transfer.
	Dynamic data are a list of domain names and their nameservers. Number of
	domains which will be sent is given by count parameter. If end of data is
	encountered, empty list is returned.
		"""
		try:
			self.l.log(self.l.INFO, "<%d> Get zone data request received." %
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
				raise ccReg.ZoneData.NotActive()

			# update last use timestamp
			self.lastuse = time.time()

			# transform data from db cursor into a structure which will be sent
			# back to client. These data are called dynamic since they keep
			# changing
			dyndata = []
			for i in range(count):
				domain, nameservers, ipaddrs, dslist, keylist = self.__get_one_domain()
				if not domain: # test end of data
					break

				# transform result in corba structures
				corba_nameservers = []
				for ns in nameservers:
					corba_ns, wmsg = createNs(domain, ns, ipaddrs[ns])
					if wmsg:
						self.l.log(self.l.WARNING, "<%d> %s" % (self.id, wmsg))
					corba_nameservers.append(corba_ns)
				corba_dslist = []
				for ds in dslist:
					corba_dslist.append(ccReg.DSRecord_str(
						ds[1], ds[2], ds[3], ds[4], ds[5]
					))
				for key in keylist:
					keydata = base64.decodestring(key[4])
					corba_dslist.append(ccReg.DSRecord_str(
						dnssec.countKeyTag(key[1], key[2], key[3], keydata),
						key[3], 1,						
						dnssec.countDSRecordDigest(
							domain, key[1], key[2], key[3], keydata
						), 0
					))
				dyndata.append( ccReg.ZoneItem(
					domain, corba_nameservers, corba_dslist
				) )

			self.l.log(self.l.DEBUG, "<%d> Number of records returned: %d." %
					(self.id, len(dyndata)) )
			return dyndata

		except ccReg.ZoneData.NotActive, e:
			raise
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception caught: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.ZoneData.InternalError("Unexpected error")

	def destroy(self):
		"""
	Mark zonedata object as ready to be destroyed.
		"""
		try:
			if self.status != self.ACTIVE:
				self.l.log(self.l.WARNING, "<%d> An attempt to close non-active "
						"zonedata object." % self.id)
				return

			self.status = self.CLOSED
			self.cursor.close()
			self.l.log(self.l.INFO, "<%d> Zone transfer closed." % self.id)
			# close db cursor
			self.cursor.close()
		except Exception, e:
			self.l.log(self.l.ERR, "<%d> Unexpected exception: %s:%s" %
					(self.id, sys.exc_info()[0], e))
			raise ccReg.MailSearch.InternalError("Unexpected error")


def init(logger, db, conf, joblist, corba_refs):
	"""
Function which creates, initializes and returns object ZoneGenerator.
	"""
	# Create an instance of ZoneGenerator_i and an ZoneGenerator object ref
	servant = ZoneGenerator_i(logger, db, conf, joblist, corba_refs)
	return servant, "ZoneGenerator"
