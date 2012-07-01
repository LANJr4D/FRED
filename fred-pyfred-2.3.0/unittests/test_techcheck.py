#!/usr/bin/env python
#
# vim:ts=4 sw=4:

'''
This file tests techcheck component of pyfred server.

Here is a hierarchy of test suites and test cases:

techcheck_suite
	|-- DigFlag
	|-- TestAll
	|-- Existence
	|-- Presence
	|-- RecursiveNs
	|		|-- test_authoritative
	|		|-- test_recursive
	|		|-- test_recursive4all
	|
	|-- Autonomous
	|-- Heterogenous
	|		|-- test_heterogenous
	|		|-- test_autonomous


See comments in appropriate classes and methods for more information
about their operation. General description follows. For inserting, altering
and deleting test data from central register we use to interfaces:
epp_client (communicates through EPP protocol) and techcheck_client program.
The changes made by this unittest are not reversible! Because the EPP
operations remain in a history and may influence result of some operations in
future. So it must be run on test instance of central register.

The tests are based on configuration and current state of nameserver for
cz zone as of 17.10.2007. Any change on these nameservers may break the tests.

fingerprint (a.ns.nic.cz, 217.31.205.180): ISC BIND 9.2.3rc1 -- 9.4.0a0  
fingerprint (b.ns.nic.cz, 217.31.205.188): ISC BIND 9.2.3rc1 -- 9.4.0a0  
fingerprint (c.ns.nic.cz, 195.66.241.202): Unknown
fingerprint (d.ns.nic.cz, 193.29.206.1):   ISC BIND 9.2.3rc1 -- 9.4.0a0  

As an example of recursive DNS was taken wren.office.nic.cz.

Domain nic.cz must exist in database. Nsset with nameservers is created
on the fly.
'''

import commands, ConfigParser, sys, getopt, os, re, random
import pgdb
import unittest

BIND1_NS     = 'a.ns.nic.cz'
BIND2_NS     = 'b.ns.nic.cz'
BIND2_NS_IP  = '217.31.205.188'
OTHER1_NS    = 'c.ns.nic.cz'
OTHER1_NS_IP = '195.66.241.202'
OTHER2_NS    = 'f.ns.nic.cz'
REC_NS       = 'nsd.csas.cz'
NONS_HOST    = 'nic.cz'
NONS_HOST_IP = '217.31.205.50'
NOHOSTED_DOMAIN = 'blabla-long-coffeee-domain.cz'

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
	(status, output) = commands.getstatusoutput('fred_client -xd \'%s\'' % cmd)
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

class TechCheck(object):
	def __init__(self, str):
		self.tests = {}
		self.output = str
		p_name = re.compile('^Test\'s name:\s+(\w+)$', re.MULTILINE)
		p_status = re.compile('^\s+Status:\s+(\w+)$', re.MULTILINE)
		names = p_name.findall(str)
		statuses = p_status.findall(str)
		if not names or not statuses:
			return
		for i in range(len(names)):
			self.tests[names[i]] = statuses[i]

	def __str__(self):
		return self.output

def techcheck_exec(nsset, level=0, dig=True, extra=None):
	'''
	Execute technical check by techcheck_client and return object representing
	results of the test.
	'''
	options = ''
	if dig:
		options += ' --dig'
	options += ' --level=%d' % level
	if extra:
		options += ' --fqdn="%s"' % extra
	(status, output) = commands.getstatusoutput('techcheck_client %s %s' %
			(options, nsset))
	status = os.WEXITSTATUS(status) # translate status
	if status != 0:
		raise Exception('techcheck_client error (status=%d): %s' %
				(status, output))
	return TechCheck(output)


class DigFlag(unittest.TestCase):
	'''
	This is a simple test case, which tests functionality of dig flag.
	If dig flag is turned on, the domains bound to nsset are tested as well
	as possible extra domain names. If dig flag is turned off, the domains
	bound to nameserver are not taken into account.
	'''

	def runTest(self):
		res = techcheck_exec('NSSID:PFUT-NSSET', 2, True)
		self.assertEqual(len(res.tests), 3, 'Flag "dig" turned on and number '
				'of executed tests is %d (should be 3)\n%s' %
				(len(res.tests), res))
		res = techcheck_exec('NSSID:PFUT-NSSET', 2, False)
		self.assertEqual(len(res.tests), 2, 'Flag "dig" turned off and number '
				'of executed tests is %d (should be 2)\n%s' %
				(len(res.tests), res))


class TestAll(unittest.TestCase):
	'''
	This test tests default configuration of nsset. All tests should be ok,
	therefore the overall status should be ok.
	'''
	def runTest(self):
		res = techcheck_exec('NSSID:PFUT-NSSET', 10)
		self.assertEqual(len(res.tests), 8, 'Number of executed tests is less '
				'than expected\n%s' % res)
		for test in res.tests:
			self.assertEqual(res.tests[test], 'Passed',
					'Test %s failed and should have been ok\n%s' % (test, res))


class Existence(unittest.TestCase):
	'''
	Insert nonexisting nameserver and see if it's detected.
	'''
	def setUp(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET (((%s (%s))))' %
				(NONS_HOST, NONS_HOST_IP))

	def runTest(self):
		res = techcheck_exec('NSSID:PFUT-NSSET', 1, False)
		self.assertEqual(res.tests['existence'], 'Failed',
				'Nonexisting nameserver %s not detected\n%s' % (NONS_HOST, res))

	def tearDown(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET () (((%s)))' % NONS_HOST)


class Presence(unittest.TestCase):
	'''
	Specify by "fqdn switch" domain which is not hosted on DNS servers and see
	if it is reported as not present.
	'''
	def runTest(self):
		res = techcheck_exec('NSSID:PFUT-NSSET', 2, False, NOHOSTED_DOMAIN)
		self.assertEqual(res.tests['presence'], 'Failed',
				'Not present domain %s not detected\n%s' %
				(NOHOSTED_DOMAIN, res))


class RecursiveNs(unittest.TestCase):
	'''
	Insert recursive nameserver among nameservers and test that answer from
	this ns is reported as not authoritative and recursive.
	'''
	def setUp(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET (((%s)))' % REC_NS)
		self.res = techcheck_exec('NSSID:PFUT-NSSET', 4)
		#print self.res

	def test_authoritative(self):
		self.assertEqual(self.res.tests['authoritative'], 'Failed',
				'Not authoritative answer from %s not detected\n%s' %
				(REC_NS, self.res))

	def test_recursive(self):
		self.assertEqual(self.res.tests['notrecursive'], 'Failed',
				'Recursive nameserver %s not detected\n%s' % (REC_NS, self.res))

	def test_recursive4all(self):
		self.assertEqual(self.res.tests['notrecursive4all'], 'Failed',
				'Recursive nameserver %s not detected\n%s' % (REC_NS, self.res))

	def tearDown(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET () (((%s)))' % REC_NS)


class Heterogenous(unittest.TestCase):
	'''
	Insert second BIND nameserver and remove the unknown nameserver and
	test if heterogenous software is detected and autonomous test fails.
	'''
	def setUp(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET (((%s (%s)))) (((%s)))' %
				(BIND2_NS, BIND2_NS_IP, OTHER1_NS))
		self.res = techcheck_exec('NSSID:PFUT-NSSET', 6, False)

	def test_heterogenous(self):
		self.assertEqual(self.res.tests['heterogenous'], 'Failed',
				'Heterogenous software not detected\n%s' % self.res)

	def test_autonomous(self):
		self.assertEqual(self.res.tests['autonomous'], 'Failed',
				'Servers from same autonomous system not detected\n%s' %
				self.res)

	def tearDown(self):
		epp_cmd_exec('update_nsset NSSID:PFUT-NSSET (((%s (%s)))) (((%s)))' %
				(OTHER1_NS, OTHER1_NS_IP, BIND2_NS))


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
	tc_suite = unittest.TestSuite()
	tc_suite.addTest(DigFlag())
	tc_suite.addTest(TestAll())
	tc_suite.addTest(Existence())
	tc_suite.addTest(Presence())
	tc_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(RecursiveNs))
	tc_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(Heterogenous))

	# Run unittests
	unittest.TextTestRunner(verbosity = level).run(tc_suite)

