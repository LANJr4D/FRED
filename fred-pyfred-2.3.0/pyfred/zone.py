#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Module representing zone file for given zone name.

The module defines object Zone, which encapsulates complexity of CORBA
communication with genzone server, and exports simple methods to be used
for zone file generation.

It connects through CORBA interface to the server which acts directly
on database. All data needed for zone generation are retrieved from server.
"""

import sys
from omniORB import CORBA
import CosNaming
from pyfred.idlstubs import ccReg


class ZoneException (Exception):
	"""
	ZoneException is used for all exceptions thrown by Zone object. To find
	out what actualy happened stringify exception.
	"""
	def __init__(self, msg = ""):
		Exception.__init__(self, msg)


class ZoneFilter (object):
	"""
	ZoneFilter is generic output filter, which transforms raw data (stored
	in python variables) into a zone file. This class is abstract. Composers
	specific for a given format should be defined by inheritance.
	"""

	def __init__(self, output):
		"""
		Initialize variable holding output descriptor. If output is a string,
		it is interpreted as name of output file. Otherwise it is assumed
		to be file descriptor.
		"""
		if type(output) == type(''):
			self.output_fd = open(output, "w")
		else:
			self.output_fd = output

	def write_soa(self, ttl, hostmaster, serial, refresh, update_retr, expiry,
			minimum, ns_fqdn, nameservers):
		"""
		Output SOA record.
		"""
		pass

	def write_records(self, domains):
		"""
		Write delegation records. Input is a list of domain objects as defined
		in IDL. Domain object has attributes: its fqdn and list of nameservers.
		"""
		pass

class BindFilter (ZoneFilter):
	"""
	Descendant of ZoneFilter class, which generates output understandable by
	BIND DNS server.
	"""
	def __init__(self, output):
		"""
		Just call parent's initializer.
		"""
		ZoneFilter.__init__(self, output)

	def get_iptype(self, addr):
		"""
		Get IP address type (IPv4 or IPv6) for DNS record.
		"""
		if addr.find(".") != -1:
			return "A"
		else:
			return "AAAA"

	def write_soa(self,
			zonename,
			ttl,
			hostmaster,
			serial,
			refresh,
			update_retr,
			expiry,
			minimum,
			ns_fqdn,
			nameservers):
		"""
		Output SOA record.
		"""
		self.output_fd.write("$TTL %d ;default TTL for all records in zone\n" %
				ttl)
		# SOA record (spans multiple lines)
		self.output_fd.write( "%s.\t\tIN\tSOA\t%s.\t%s. (" %
				(zonename, ns_fqdn, hostmaster.replace("@",".")) )
		self.output_fd.write("%s " % serial)
		self.output_fd.write("%d " % refresh)
		self.output_fd.write("%d " % update_retr)
		self.output_fd.write("%d " % expiry)
		self.output_fd.write("%d)\n" % minimum)
		# list of nameservers for the zone
		for ns in nameservers:
			self.output_fd.write("\t\tIN\tNS\t%s.\n" % ns.fqdn)
		# addresses of nameservers (only if there are any)
		for ns in nameservers:
			for addr in ns.inet:
				self.output_fd.write("%s.\tIN\t%s\t%s\n" %
						(ns.fqdn, self.get_iptype(addr), addr))
		# domains, their nameservers and addresses
		self.output_fd.write(";\n")
		self.output_fd.write(";--- domain records ---\n")
		self.output_fd.write(";\n")

	def write_records(self, domains):
		"""
		Write delegation records. Input is a list of domain objects as defined
		in IDL. Domain object has attributes: its fqdn and list of nameservers.
		"""
		for domain in domains:
			for ns in domain.nameservers:
				self.output_fd.write("%s.\tIN\tNS\t%s" % (domain.name, ns.fqdn))
				# if the nameserver's fqdn is already terminated by a dot
				# we don't add another one - ugly check which is necessary
				# becauseof error in CR (may be removed in future)
				if not ns.fqdn.endswith("."):
					self.output_fd.write(".\n")
				else:
					self.output_fd.write("\n")
				# distinguish ipv4 and ipv6 address
				for addr in ns.inet:
					self.output_fd.write("%s.\tIN\t%s\t%s\n" %
							(ns.fqdn, self.get_iptype(addr), addr))
			for ds in domain.dsrecords:
				if ds.maxSigLife > 0:
					ttl = ds.maxSigLife
				else:
					ttl = ""
				self.output_fd.write("%s. %s\tIN\tDS\t%s %s %s %s\n" % 
						(domain.name, ttl, ds.keyTag, ds.alg, 
						 ds.digestType, ds.digest))

class ZoneGeneratorObject (object):
	"""
	Object ZoneGenerator encapsulates corba communication
	"""
	
	def getObject(self,  ns = "localhost", context = "fred",
			object = "ZoneGenerator"):
		try:
			# Initialise the ORB
			orb = CORBA.ORB_init(["-ORBnativeCharCodeSet", "UTF-8",
					"-ORBInitRef", "NameService=corbaname::" + ns],
					CORBA.ORB_ID)
			# Obtain a reference to the root naming context
			obj = orb.resolve_initial_references("NameService")
			rootContext = obj._narrow(CosNaming.NamingContext)
			if rootContext is None:
				raise ZoneException("Failed to narrow the root naming context")
			# Resolve the name "fred.context/ZoneGenerator.Object"
			name = [CosNaming.NameComponent(context, "context"),
					CosNaming.NameComponent(object, "Object")]
			obj = rootContext.resolve(name)
			# Narrow the object to an fred::ZoneGenerator
			zone_orb_object = obj._narrow(ccReg.ZoneGenerator)
			if (zone_orb_object is None):
				raise ZoneException("Obtained object reference is not "
						"ccReg::ZoneGenerator")
			return zone_orb_object
		except CORBA.TRANSIENT, e:
			raise ZoneException("Is nameservice running? (%s)" % e)
		except CORBA.Exception, e:
			raise ZoneException("CORBA failure, original exception is: %s" % e)
	
class Zone (object):
	"""
	Object Zone is responsible for downloading zone data from server and
	formating obtained data when dump() method is called.
	"""
	BIND = 0 # currently the only supported output format (constant)

	def __init__(self, filter, zonename, ns = "localhost", context = "fred",
			object = "ZoneGenerator", chunk = 100, progress_callback = None):
		"""
		TODO
		"""
		self.output_filter = filter
		self.zonename = zonename
		self.chunk = chunk
		self.progress_cb = progress_callback
		self.soa = {}
		self.zone_orb_object = ZoneGeneratorObject().getObject(
			ns,context,object
		)
		self.zonedata = None

		try:
			# Download SOA data
			(zonename, self.soa["ttl"], self.soa["hostmaster"],
					self.soa["serial"], self.soa["refresh"],
					self.soa["update_retr"], self.soa["expiry"],
					self.soa["minimum"], self.soa["ns_fqdn"],
					self.soa["nameservers"]) = \
							self.zone_orb_object.getSOA(self.zonename)
		except ccReg.ZoneGenerator.UnknownZone, e:
			raise ZoneException("Unknown zone requested")
		except ccReg.ZoneGenerator.InternalError, e:
			raise ZoneException("Internal error on server: %s" % e.message)
		except CosNaming.NamingContext.NotFound, ex:
			raise ZoneException("CORBA object named '%s' not found "
					"(check that the server is running)" % name)
		except CORBA.TRANSIENT, e:
			raise ZoneException("Is nameservice running? (%s)" % e)
		except CORBA.Exception, e:
			raise ZoneException("CORBA failure, original exception is: %s" % e)

	def dump(self):
		"""
		Dump zone content in given format in a file.
		"""
		self.output_filter.write_soa(
				self.zonename,
				self.soa["ttl"],
				self.soa["hostmaster"],
				self.soa["serial"],
				self.soa["refresh"],
				self.soa["update_retr"],
				self.soa["expiry"],
				self.soa["minimum"],
				self.soa["ns_fqdn"],
				self.soa["nameservers"]
				)
		try:
			self.zonedata = self.zone_orb_object.generateZone(self.zonename)
		except ccReg.ZoneGenerator.UnknownZone, e:
			raise ZoneException("Unknown zone requested")
		except ccReg.ZoneGenerator.InternalError, e:
			raise ZoneException("Internal error on server: %s" % e.message)
		except CORBA.Exception, e:
			raise ZoneException("CORBA failure, original exception is: %s" % e)

		domains = True
		while domains:
			# Invoke the getZoneData operation
			try:
				domains = self.zonedata.getNext(self.chunk)
			except ccReg.ZoneData.NotActive, e:
				raise ZoneException("ZoneData object is not active any more.")
			except ccReg.ZoneData.InternalError, e:
				raise ZoneException("Internal error on server: %s" % e.message)
			except CORBA.TRANSIENT, e:
				raise ZoneException("Is corba server running? (%s)" % e)
			except CORBA.Exception, e:
				raise ZoneException("CORBA failure, original exception is: %s" % e)
			self.output_filter.write_records(domains)
			if self.progress_cb:
				self.progress_cb()

	def cleanup(self):
		"""
	Clean up resources allocated for transfer on server's side.
		"""
		if self.zonedata:
			try:
					self.zonedata.destroy()
			except ccReg.ZoneData.NotActive, e:
				raise ZoneException("ZoneData object is not active anymore")
			except ccReg.ZoneData.InternalError, e:
				raise ZoneException("Error message from server: %s" % e)
			except CORBA.TRANSIENT, e:
				raise ZoneException("Is corba server running? (%s)" % e)
			except CORBA.Exception, e:
				raise ZoneException("CORBA failure, original exception is: %s"%e)
			self.zonedata = None

	def __del__(self):
		"""
	Call cleanup method, which releases resources on server-side. Destructor
	comes in handy if a user of Zone object forgot to call cleanup method.
		"""
		self.cleanup()

