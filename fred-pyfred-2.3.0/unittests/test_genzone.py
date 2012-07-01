#!/usr/bin/env python
#
# vim:ts=4 sw=4:

'''
This file tests genzone component of pyfred server.

Here is a hierarchy of test suites and test cases:

genzone_suite
	|-- SoaTest
	|
	|-- SyntaxTest
	|
	|-- DelegationTest
	|		|-- test_nameserver_rr
	|		|-- test_glue_rr
	|
	|-- FaultyGlueTest
	|		|-- test_missingGlue
	|		|-- test_extraGlue
	|
	|-- DomainFlagsTest
			|-- test_outzonemanual
			|-- test_protected
			|-- test_unprotected
			|-- test_inzonemanual

See comments in appropriate classes and methods for more information
about their operation. General description follows. For inserting, altering
and deleting test data from central register we use to interfaces:
epp_client (communicates through EPP protocol) and direct access to database.
The changes made by this unittest are not reversible! Because the EPP
operations remain in a history and may influence result of some operations in
future. So it must be run on test instance of central register. The tests
are specific for '.cz' zone and won't work with other zones.
'''

import commands, ConfigParser, sys, getopt, os, re, random
import pgdb
import unittest

pyfred_bin_dir = '/usr/local/bin/'

def usage():
	print '%s [-v LEVEL | --verbose=LEVEL]' % sys.argv[0]
	print
	print 'verbose level number is handed over to unittest function as it is.'
	print

def epp_cmd_exec(cmd):
	'''
	Execute EPP command by fred_client. XML validation is turned off.
	The EPP response must have return code 1000, otherwise exception is
	raised.
	'''
	(status, output) = commands.getstatusoutput(
            os.path.join(pyfred_bin_dir, 'fred_client -xd \'%s\'' % cmd))
	status = os.WEXITSTATUS(status) # translate status
	if status != 0:
		raise Exception('fred_client error (status=%d): %s' % (status, output))
	pattern = re.compile('^Return code:\s+(\d+)$', re.MULTILINE)
	m = pattern.search(output)
	rcode = 0
	if m:
		rcode = int(m.groups()[0])
	if rcode == 0:
		raise Exception('Return code of EPP command not matched\n%s' % output)
	if rcode != 1000:
		raise Exception('EPP command failure (code %d)\n%s' % (rcode, output))

def open_db_connection():
	'''
	Return opened db connection based on information in /etc/fred/pyfred.conf.
	'''
	# reasonable defaults
	dbhost = ''
	dbname = 'fred'
	dbport = '5432'
	dbuser = 'fred'
	dbpassword = ''
	# read config file
	config = ConfigParser.ConfigParser()
	config.read('/etc/fred/pyfred.conf')
	if config.has_option('General', 'dbhost'):
		dbhost = config.get('General', 'dbhost')
	if config.has_option('General', 'dbname'):
		dbname = config.get('General', 'dbname')
	if config.has_option('General', 'dbport'):
		dbport = config.get('General', 'dbport')
	if config.has_option('General', 'dbuser'):
		dbuser = config.get('General', 'dbuser')
	if config.has_option('General', 'dbpassword'):
		dbpassword = config.get('General', 'dbpassword')
	# create connection to database
	return pgdb.connect(host = dbhost +":"+ dbport, database = dbname,
			user = dbuser, password = dbpassword)

def get_zone_lines(greps = None):
	'''
	Generate .cz zone with help of genzone_client program in /tmp/db.cz file
	and grep strings in 'greps' list from the zone file. The result is a list
	of stripped grepped lines. If greps is None, then the zone file is
	generated and left as it is (its name is returned as a return value).
	'''
	# generate zone
	(status, output) = commands.getstatusoutput(
			'genzone_client --nobackups --zonedir=/tmp cz')
	status = os.WEXITSTATUS(status) # translate status
	if status != 0:
		raise Exception('genzone_client error (status=%d): %s' %
				(status, output))
	if greps == None:
		return '/tmp/db.cz'

	# grep interesting lines
	if len(greps) == 1:
		cmdline = 'grep "%s" /tmp/db.cz' % greps[0]
	else:
		cmdline = 'grep "\('
		for str in greps:
			cmdline = cmdline + str + '\|'
		cmdline = cmdline[:-1] + ')" /tmp/db.cz'
	(status, zonelines) = commands.getstatusoutput(cmdline)
	status = os.WEXITSTATUS(status) # translate status
	if status == 1:
		zonelines = ''
	elif status != 0:
		raise Exception('grep error (status=%d): %s' % (status, output))
	# delete generated zone file
	os.unlink('/tmp/db.cz')
	# return result
	if not zonelines:
		return []
	return [ line.strip() for line in zonelines.split('\n') ]


class SoaTest(unittest.TestCase):
	'''
	This is a simple test case, which tests presence of SOA records for zones
	defined in /etc/fred/genzone.conf files. It uses genzone_test command
	for that.
	'''
	def setUp(self):
		'''
		Get list of zones from /etc/fred/genzone.conf.
		'''
		config = ConfigParser.ConfigParser()
		config.read('/etc/fred/genzone.conf')
		if config.has_option('general', 'zones'):
			self.zones = config.get('general', 'zones').split()

	def runTest(self):
		'''
		Test for presence of SOA records by genzone_test command.
		'''
		for zone in self.zones:
			(status,output) = commands.getstatusoutput('genzone_test %s' % zone)
			status = os.WEXITSTATUS(status) # translate status
			self.assertEqual(status, 0, 'Could not get SOA of %s zone' % zone)
			# status code is crucial, output test is just a safety-catch
			self.assert_((output == 'GENZONE OK'), 'genzone_test malfunction')


class SyntaxTest(unittest.TestCase):
	'''
	Checks basic syntax of zone file with help of zone-file-check script.
	'''
	def setUp(self):
		'''
		Generate zone file.
		'''
		self.zone_file = get_zone_lines()

	def tearDown(self):
		'''
		Remove generated zone file.
		'''
		os.unlink(self.zone_file)

	def runTest(self):
		'''
		The test runs zone-file-check script, which tests basic syntax of
		zone file.
		'''
		(status, errors) = commands.getstatusoutput('./zone-file-check %s' %
				self.zone_file)
		status = os.WEXITSTATUS(status) # translate status
		self.assert_(not errors.strip(), 'Following lines have invalid '
				'syntax:\n%s' % errors)


class DelegationTest(unittest.TestCase):
	'''
	This test case generates zone and tests that all resource records
	for fpug-domain.cz domain, which should be there, are really there.
	'''

	def setUp(self):
		'''
		Generate zone and grep appropriate lines from zone.
		'''
		self.zone_lines = get_zone_lines(['pfug-domain.cz',
				'ns.pfug-domain.cz', 'ns.pfug-domain.net'])
		self.rr_lines = ''
		for line in self.zone_lines:
			self.rr_lines += line + '\n'

	def test_nameserver_rr(self):
		'''
		Test domain delegation, said otherwise, presence of two NS resource
		records for pfug-domain.cz domain in zone.
		'''
		# compile resource record patterns
		patt_ns1 = re.compile('pfug-domain\.cz\.\s+IN\s+NS\s+'
				'ns\.pfug-domain\.cz\.')
		patt_ns2 = re.compile('pfug-domain\.cz\.\s+IN\s+NS\s+'
				'ns\.pfug-domain\.net\.')
		# test their presence
		found = False
		for line in self.zone_lines:
			if patt_ns1.match(line):
				found = True
				break
		self.assert_(found, 'Record for nameserver ns.pfug-domain.cz not '
				'generated.\n%s' % self.rr_lines)
		found = False
		for line in self.zone_lines:
			if patt_ns2.match(line):
				found = True
				break
		self.assert_(found, 'Record for nameserver ns.pfug-domain.net not '
				'generated.\n%s' % self.rr_lines)

	def test_glue_rr(self):
		'''
		Test presence of two GLUEs (ipv4 and ipv6), said otherwise,
		presence of A record for ns.pfug-domain.cz nameserver and
		presence of AAAA record for ns.pfug-domain.cz nameserver.
		'''
		# compile resource record patterns
		patt_glue4 = re.compile('ns\.pfug-domain\.cz\.\s+IN\s+A\s+'
				'217\.31\.206\.129')
		patt_glue6 = re.compile('ns\.pfug-domain\.cz\.\s+IN\s+AAAA\s+'
				'2001:db8::1428:57ab')
		# test GLUE record presence
		found = False
		for line in self.zone_lines:
			if patt_glue4.match(line):
				found = True
				break
		self.assert_(found, 'IPv4 GLUE record for nameserver '
				'ns.pfug-domain.cz not generated.\n%s' % self.rr_lines)
		found = False
		for line in self.zone_lines:
			if patt_glue6.match(line):
				found = True
				break
		self.assert_(found, 'IPv6 GLUE record for nameserver '
				'ns.pfu-domain.cz not generated.\n%s' % self.rr_lines)

class FaultyGlueTest(unittest.TestCase):
	'''
	This test case moves ip addresses of nameserver, where they are needed,
	to nameserver where they are not needed. Zone generator should react to
	this unussual situation like this. The nameserver with missing GLUE
	should not appear in zone and nameserver with extra GLUE should be in zone
	but without a GLUE record.
	'''

	def setUp(self):
		'''
		Move ip addresses from nameserver which needs them to nameserver which
		doesn't need them. Generate zone and grep appropriate lines from zone.
		'''
		self.dbconn = open_db_connection()
		# change information in db
		cur = self.dbconn.cursor()
		cur.execute("SELECT id FROM host WHERE fqdn = 'ns.pfug-domain.cz'")
		self.ns_cz_id = cur.fetchone()[0]
		cur.execute("SELECT id FROM host WHERE fqdn = 'ns.pfug-domain.net'")
		self.ns_net_id = cur.fetchone()[0]
		cur.execute("UPDATE host_ipaddr_map SET hostid = %d WHERE hostid = %d" %
				(self.ns_net_id, self.ns_cz_id))
		cur.close()
		self.dbconn.commit()
		# generate zone and grep lines
		self.zone_lines = get_zone_lines(['ns.pfug-domain.cz',
				'ns.pfug-domain.net'])
		self.rr_lines = ''
		for line in self.zone_lines:
			self.rr_lines += line + '\n'

	def tearDown(self):
		'''
		Revert changes in database (exchange of ip addresses between
		nameservers).
		'''
		cur = self.dbconn.cursor()
		cur.execute("UPDATE host_ipaddr_map SET hostid = %d WHERE hostid = %d"
				% (self.ns_cz_id, self.ns_net_id))
		cur.close()
		self.dbconn.commit()
		self.dbconn.close()

	def test_missingGlue(self):
		'''
		In case when GLUE for a nameserver is missing, the nameserver should
		not be generated in zone.
		'''
		# compile delegation pattern
		patt_ns1 = re.compile('pfug-domain\.cz\.\s+IN\s+NS\s+'
				'ns\.pfug-domain\.cz\.')
		# assure that nameserver is not in zone
		for line in self.zone_lines:
			self.assert_(not patt_ns1.match(line),
					'Nameserver ns.pfu-domain.cz with missing GLUE was '
					'generated.\n%s' % self.rr_lines)

	def test_extraGlue(self):
		'''
		In case when nameserver has unnecessary ip address (in context of given
		zone), the address should be ignored, which means the GLUE should not
		be generated.
		'''
		# compile GLUE patterns
		patt_glue4 = re.compile('ns\.pfu-domain\.net\.\s+IN\s+A\s+'
				'217\.31\.206\.129')
		patt_glue6 = re.compile('ns\.pfu-domain\.net\.\s+IN\s+AAAA\s+'
				'2001:db8::1428:57ab')
		# assure that GLUEs are not in zone
		for line in self.zone_lines:
			self.assert_(not patt_glue4.match(line),
					'Not needed glue for nameserver ns.pfug-domain.net was '
					'generated.\n%s' % self.rr_lines)
		for line in self.zone_lines:
			self.assert_(not patt_glue6.match(line),
					'Not needed glue for nameserver ns.pfug-domain.net was '
					'generated.\n%s' % self.rr_lines)

class DomainFlagsTest(unittest.TestCase):
	'''
	These tests set various flags on domain and test the implication of these
	operations. Some flags are not set directly, but via change of expiration
	date.
	'''
	def setUp(self):
		'''
		Save current expiration date of a domain. It will be restored in
		tearDown method.
		'''
		self.dbconn = open_db_connection()
		# change information in db
		cur = self.dbconn.cursor()
		cur.execute("SELECT id FROM object_registry "
				"WHERE name = 'pfug-domain.cz'")
		self.domainid = cur.fetchone()[0]
		cur.execute("SELECT exdate FROM domain WHERE id = %d" % self.domainid)
		self.exdate = cur.fetchone()[0]
		cur.close()
		self.dbconn.commit()

	def tearDown(self):
		'''
		Restore expiration date to original value remove manual flags and
		run update_flags procedure.
		'''
		cur = self.dbconn.cursor()
		cur.execute("UPDATE domain SET exdate = '%s' WHERE id = %d" %
				(self.exdate, self.domainid))
		cur.execute("DELETE FROM object_state_request WHERE object_id = %d" %
				self.domainid)
		cur.execute("SELECT update_object_states()")
		cur.close()
		self.dbconn.commit()
		# delete generated zone file (doesn't have to exist)
		if os.access('/tmp/db.cz', os.F_OK):
			os.unlink('/tmp/db.cz')

	def test_outzonemanual(self):
		'''
		Set outzonemanual flag, run update_object_states() and check that
		domain is not in zone.
		'''
		cur = self.dbconn.cursor()
		cur.execute("INSERT INTO object_state_request "
				"(object_id, state_id, valid_from, valid_to, crdate)"
				"VALUES (%d, 5, now(), now() + INTERVAL '1 day', now())" %
				self.domainid)
		cur.execute("SELECT update_object_states()")
		cur.close()
		self.dbconn.commit()
		# generate zone and grep lines
		self.assert_(not get_zone_lines(['pfug-domain.cz']),
				'Domain with status outzonemanual is in zone')

	def test_protected(self):
		'''
		Get domain in protection period (recently expired). Domain should
		stay in zone.
		'''
		cur = self.dbconn.cursor()
		cur.execute("UPDATE domain SET exdate = now() - INTERVAL '15 days' "
				"WHERE id = %d" % self.domainid)
		cur.execute("SELECT update_object_states()")
		cur.close()
		self.dbconn.commit()
		# generate zone and grep lines
		self.assert_(get_zone_lines(['pfug-domain.cz']),
				'Domain which is in protected period is not in zone')

	def test_unprotected(self):
		'''
		Get domain past the protection period. Domain should get out of zone.
		'''
		cur = self.dbconn.cursor()
		cur.execute("UPDATE domain SET exdate = now() - INTERVAL '31 days' "
				"WHERE id = %d" % self.domainid)
		cur.execute("SELECT update_object_states()")
		cur.close()
		self.dbconn.commit()
		# generate zone and grep lines
		self.assert_(not get_zone_lines(['pfug-domain.cz']),
				'Domain which is past the protected period is in zone')

	def test_inzonemanual(self):
		'''
		Get domain past the protection period, set inzonemanual flag, run
		update_object_states() and check that domain is in zone.
		'''
		cur = self.dbconn.cursor()
		cur.execute("UPDATE domain SET exdate = now() - INTERVAL '31 days' "
				"WHERE id = %d" % self.domainid)
		cur.execute("INSERT INTO object_state_request "
				"(object_id, state_id, valid_from, valid_to, crdate)"
				"VALUES (%d, 5, now(), now() + INTERVAL '1 day', now())" %
				self.domainid)
		cur.execute("SELECT update_object_states()")
		cur.close()
		self.dbconn.commit()
		# generate zone and grep lines
		self.assert_(not get_zone_lines(['pfug-domain.cz']),
				'Domain with status inzonemanual is not in zone')



if __name__ == '__main__':
	# parse command line parameters
	try:
		(opts, args) = getopt.getopt(sys.argv[1:], 'v:', ['verbose='])
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	level = 2 # default verbose level
	for o,a in opts:
		if o in ('-v', '--verbose'):
			level = int(a)
	# put together test suite
	genzone_suite = unittest.TestSuite()
	genzone_suite.addTest(SoaTest())
	genzone_suite.addTest(SyntaxTest())
	genzone_suite.addTest(
			unittest.TestLoader().loadTestsFromTestCase(DelegationTest))
	genzone_suite.addTest(
			unittest.TestLoader().loadTestsFromTestCase(FaultyGlueTest))
	genzone_suite.addTest(
			unittest.TestLoader().loadTestsFromTestCase(DomainFlagsTest))

	# Run unittests
	unittest.TextTestRunner(verbosity = level).run(genzone_suite)

