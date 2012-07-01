#!/usr/bin/env python
#
# vim:ts=4 sw=4:

'''
Unittests for unix whois.

Here is a hierarchy of test suites and test cases:

whois_suite
	|-- NotObjectSpecificTests
	|		|-- test_longRequest
	|		|-- test_notCRLF
	|		|-- test_invalidChar
	|		|-- test_manyArguments
	|		|-- test_flagRecursive
	|		|-- test_queryFlags
	|		|-- test_queryandother
	|		|-- test_unknowntype
	|		|-- test_unknowninverse
	|
	|-- ObjectSpecificTests
	|		|-- test_typeDomain
	|		|-- test_typeNsset
	|		|-- test_typeContact
	|		|-- test_typeRegistrar
	|		|-- test_invRegistrant
	|		|-- test_invAdmin_c
	|		|-- test_invTemp_c
	|		|-- test_invNsset
	|		|-- test_invNserver
	|		|-- test_invTech_c

See comments in appropriate classes and methods for more information
about their operation. General description follows. For inserting
and deleting test data from central register we use epp_client (EPP protocol).
The changes made by this unittest are not reversible! Because the EPP
operations remain in a history and may influence result of some operations in
future. So it must be run on test instance of central register. The tests
are specific for '.cz' zone and won't work with other zones.
'''

import commands, ConfigParser, sys, getopt, os, re, random, os, socket, time
import unittest

MAX_REQLEN = 1000
BUFFSIZE   = 4096
TESTDOMAIN = 'fred.cz'
WHOIS_HOST = 'localhost'
WHOIS_PORT = 41007
IPV4_REGEX = '(?:(?:\d+?)\.){3}\d+'
IPV6_REGEX = '\A(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z'

def usage():
	print '%s [-v LEVEL | --verbose=LEVEL]' % sys.argv[0]
	print
	print 'verbose level number is handed over to unittest function as it is.'
	print

class TestSocket(socket.socket):
    '''
    Socket wrapper using aggregation
    suitable for receiving large chunks of data
    Subclassing socket.socket was rather difficult:
    http://groups.google.com/group/comp.lang.python/browse_thread/thread/76d27388b0d286fa/c9849013e37c995b?pli=1

    Typical use of the class:
        s = TestSocket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((WHOIS_HOST, WHOIS_PORT))
		s.send('x' * MAX_REQLEN + '\r\n')
		rawans = s.recv(BUFFSIZE)
		s.close()

    '''
    def __init__(self, family, type, proto=0):
        self.sock = socket.socket(family, type, proto)


    def connect (self, addr):
        self.sock.connect(addr)


    def send (self, content):
        self.sock.send(content)


    def recv(self, size, flags=''):
        '''
        Different from originial socket.recv, size is only 
        block size to use while reading the data from socket.
        Complete answer is read by chunks of size 'size' until 
        no data is available via socket.recv
        '''
        ret=''

        while 1:
			chunk = self.sock.recv(size)
			if not chunk:
				break
            else:
                ret += chunk

        return ret


    def close(self):
        self.sock.close()


class Answer(object):
	def __init__(self, str):
		'''
		Process whois answer.
		'''
		self.comment = ''
		self.objects = []
		self.error = None
		self.error_text = ''
		obj_record = False
		obj_class = None
		obj_lines = ''
		for line in str.split('\r\n'):
			if line.startswith('% '):
				#print 'checkpoint 1'
				obj_record = False
				self.comment += line + '\n'
			elif line.startswith('%ERROR:'):
				#print 'checkpoint 2'
				obj_record = False
				self.error = int(line[7:10])
				self.error_text = line[12:]
			elif not line:
				#print 'checkpoint 3'
				if obj_record:
					break;
				obj_record = True
				if obj_class:
					if obj_class == Domain:
						self.objects.append(Domain(obj_lines))
					elif obj_class == Nsset:
						self.objects.append(Nsset(obj_lines))
					elif obj_class == Keyset:
						self.objects.append(Keyset(obj_lines))
					elif obj_class == Contact:
						self.objects.append(Contact(obj_lines))
					elif obj_class == Registrar:
						self.objects.append(Registrar(obj_lines))
				obj_class = None
				obj_lines = ''
			else:
				#print 'checkpoint 4'
				obj_record = False
				if not obj_class:
					if line.startswith('domain'):
						obj_class = Domain
					elif line.startswith('nsset'):
						obj_class = Nsset
					elif line.startswith('keyset'):
						obj_class = Keyset
					elif line.startswith('contact'):
						obj_class = Contact
					elif line.startswith('registrar'):
						obj_class = Registrar
					else:
						raise Exception('Unknown object type: %s' % line)
				obj_lines += line + '\n'

	def __str__(self):
		str = ''
		str += 'Error: %s\n' % self.error
		if self.error:
			str += 'Error text: %s\n' % self.error_text
		str += 'Count of objects: %d\n' % len(self.objects)
		return str


def getval(key, pattern, input, mustbe = True, list = False):
	pattern = '^' + key + ':' + '\s+(' + pattern + ')$'
	result = re.compile(pattern, re.MULTILINE).search(input)
	if not result or len(result.groups()) == 0:
		if mustbe:
			raise Exception('Mandatory argument missing\n%s\n%s' %
					(pattern, input))
		if list: return []
		else: return None
	elif len(result.groups()) == 1:
		if list: return [ result.groups()[0] ]
		else: return result.groups()[0]
	else:
		if list: return [ item for item in result.groups() ]
		else: raise Exception('Expected 1 value and got %d values\n%s\n%s' %
				(len(result.groups()), pattern, input))

def gettimeval(key, input, mustbe = True):
	datpat = '\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:\d\d'
	date = getval(key, datpat, input, mustbe, False)
	if not date:
		return date
	return time.strptime(date, '%d.%m.%Y %H:%M:%S')

def getdateval(key, input, mustbe = True):
	datpat = '\d\d\.\d\d\.\d\d\d\d'
	date = getval(key, datpat, input, mustbe, False)
	if not date:
		return date
	return time.strptime(date, '%d.%m.%Y')

class Domain(object):
	def __init__(self, str):
		self.domain = getval('domain', '[a-zA-Z0-9][a-zA-Z0-9\-]+\.cz', str)
		self.registrant = getval('registrant', '\S+', str, mustbe=False)
		self.admin_c = getval('admin-c', '\S+', str, mustbe=False, list=True)
		self.temp_c = getval('temp-c', '\S+', str, mustbe=False, list=True)
		self.nsset = getval('nsset', '\S+', str, mustbe=False)
		self.keyset = getval('keyset', '\S+', str, mustbe=False)
		self.registrar = getval('registrar', '\S+', str)
		self.status = getval('status', '.+', str, mustbe=False, list=True)
		self.registered = gettimeval('registered', str)
		self.changed = gettimeval('changed', str, mustbe=False)
		self.expire = getdateval('expire', str)
		self.validated_to = gettimeval('validated-to', str, mustbe=False)

class Nsset(object):
	def __init__(self, str):
		self.nsset = getval('nsset', '\S+', str)
		# complete:
		# self.nserver = getval('nserver', '((?:[a-zA-Z0-9]+\.?)+)\s+\(((' + IPV4_REGEX + ')|(' + IPV6_REGEX + '),?\s*)+\)', str, list=True)
		# simple solution:
		self.nserver = getval('nserver', '((?:[a-zA-Z0-9]+\.?)+)\s+\(.+\)?', str, list=True)
		self.tech_c = getval('tech-c', '\S+', str, list=True)
		self.registrar = getval('registrar', '\S+', str)
		self.created = gettimeval('created', str)
		self.changed = gettimeval('changed', str, mustbe=False)

class Keyset(object):
	def __init__(self, str):
		self.keyset = getval('keyset', '\S+', str)
		self.dnskey = getval('dnskey', '.+', str, list=True)
		self.tech_c = getval('tech-c', '\S+', str, list=True)
		self.registrar = getval('registrar', '\S+', str)
		self.created = gettimeval('created', str)
		self.changed = gettimeval('changed', str, mustbe=False)


class Contact(object):
	def __init__(self, str):
		self.contact = getval('contact', '\S+', str)
		self.org = getval('org', '.+', str, mustbe=False)
		self.name = getval('name', '.+', str)
		self.address = getval('address', '.+', str, list=True)
		self.phone = getval('phone', '.+', str, mustbe=False)
		self.fax_no = getval('fax-no', '.+', str, mustbe=False)
		self.e_mail = getval('e-mail', '.+', str, mustbe=False)
		self.registrar = getval('registrar', '\S+', str)
		self.created = gettimeval('created', str)
		self.changed = gettimeval('changed', str, mustbe=False)

class Registrar(object):
	def __init__(self, str):
		self.registrar = getval('registrar', '\S+', str)
		self.org = getval('org', '.+', str)
		#self.url = getval('url', 'http://\S+', str)
		self.url = getval('url', '\S+', str)
		self.phone = getval('phone', '.+', str, mustbe=False)
		self.address = getval('address', '.+', str, list=True)


class NotObjectSpecificTests(unittest.TestCase):
	'''
	The class gathers tests which are not object specific.
	'''

	def setUp(self):
		'''
		Connect to whois server.
		'''
		self.s = TestSocket(socket.AF_INET, socket.SOCK_STREAM)
		self.s.connect((WHOIS_HOST, WHOIS_PORT))

	def tearDown(self):
		self.s.close()

	def test_longRequest(self):
		'''
		Send long request.
		'''
		self.s.send('x' * MAX_REQLEN + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 108, 'Too long request not detected\n%s' %
				ans)

	def test_notCRLF(self):
		'''
		Send request not terminated by CR LF.
		'''
		self.s.send('domena.cz' + '\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 108, 'Not properly terminated request '
				'not detected\n%s' % ans)

	def test_invalidChar(self):
		'''
		Send invalid char in domain name.
		'''
		self.s.send('domena.cz' + '\\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 108, 'Invalid char in request not '
				'detected\n%s' % ans)

	def test_manyArguments(self):
		'''
		Send too many arguments.
		'''
		self.s.send('domena.cz arg1 arg3' + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 107, 'Too many arguments not detected\n%s'%
				ans)

	def test_flagRecursive(self):
		'''
		Turn off recursion and check that one object only is returned.
		'''
		self.s.send('-r ' + TESTDOMAIN + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1, 'Recursive flag not working\n%s'%
				ans)

	def test_queryflags(self):
		'''
		Test version switch.
		Test index switch.
		Test templates switch.
		'''
		for flag in ['version', 'indexes', 'templates']:
			self.s.send('-q %s\r\n' % flag)
			rawans = self.s.recv(BUFFSIZE)
			ans = Answer(rawans)
			self.assert_(len(ans.objects) == 0 and not ans.error,
					'Query flag mulfunction\n%s' % ans)

	def test_queryandother(self):
		'''
		Test query flag combined with another one.
		'''
		self.s.send('-q version domain.cz\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 107, 'Invalid combination of flags not '
				'detected\n%s' % ans)

	def test_unknowntype(self):
		'''
		Test unknown type.
		'''
		self.s.send('unknowntype domain.cz\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 107, 'Unknown type not detected\n%s' % ans)

	def test_unknowninverse(self):
		'''
		Test unknown inverse key.
		'''
		self.s.send('-i unknownkey domain.cz\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 107, 'Unknown inverse key not detected\n%s'%
				ans)


class ObjectSpecificTests(unittest.TestCase):
	'''
	The class gathers tests which are object specific.
	'''

	def setUp(self):
		'''
		Connect to whois server.
		'''
        self.s = TestSocket(socket.AF_INET, socket.SOCK_STREAM)
		# self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.s.connect((WHOIS_HOST, WHOIS_PORT))
		self.s.send(TESTDOMAIN + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.domain = ans.objects[0]
		# find nsset
		for obj in ans.objects:
			if isinstance(obj, Nsset):
				self.nsset = obj
		# find keyset
		for obj in ans.objects:
			if isinstance(obj, Keyset):
				self.keyset = obj

		self.s.close()
		self.s = TestSocket(socket.AF_INET, socket.SOCK_STREAM)
		self.s.connect((WHOIS_HOST, WHOIS_PORT))

	def tearDown(self):
		self.s.close()

	def test_typeDomainPos(self):
		# positive case
		self.s.send('-r domain ' + self.domain.domain + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1, 'type domain not working\n%s\n%s'%
				(rawans, ans))

	def test_typeDomainNeg(self):
		# negative case
		self.s.send('-r domain ' + self.domain.registrant + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 101, 'type domain not working\n%s\n%s' %
				(rawans, ans))

	def test_typeNssetPos(self):
		# positive case
		self.s.send('-r nsset ' + self.domain.nsset + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1,'type nsset not working\n%s\n%s'%
				(rawans, ans))

	def test_typeNssetNeg(self):
		# negative case
		self.s.send('-r nsset ' + self.domain.domain + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 101, 'type nsset not working\n%s\n%s' %
				(rawans, ans))
	def test_typeKeysetPos(self):
		# positive case
		self.s.send('-r keyset ' + self.domain.keyset + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1,'type keyset not working\n%s\n%s'%
				(rawans, ans))

	def test_typeKeysetNeg(self):
		# negative case
		self.s.send('-r keyset ' + self.domain.domain + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 101, 'type keyset not working\n%s\n%s' %
				(rawans, ans))

	def test_typeContactPos(self):
		# positive case
		self.s.send('-r contact ' + self.domain.registrant + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1, 'type contact not working\n%s\n%s'%
				(rawans, ans))

	def test_typeContactNeg(self):
		# negative case
		self.s.send('-r contact ' + self.domain.nsset + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 101, 'type contact not working\n%s\n%s' %
				(rawans, ans))

	def test_typeRegistrarPos(self):
		# positive case
		self.s.send('-r registrar ' + self.domain.registrar + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(len(ans.objects), 1, 'type registrar not working\n%s\n%s' %
				(rawans, ans))

	def test_typeRegistrarNeg(self):
		# negative case
		self.s.send('-r registrar ' + self.domain.registrant + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		self.assertEqual(ans.error, 101, 'type registrar not working\n%s\n%s' %
				(rawans, ans))

	def test_invRegistrant(self):
		self.s.send('-r -i registrant ' + self.domain.registrant + '\r\n')

        rawans = self.s.recv(BUFFSIZE);

		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.domain == self.domain.domain:
				found = True
				break
		self.assertEqual(found, True, 'inverse registrar not working\n%s\n%s' %
				(rawans, ans))

	def test_invAdmin_c(self):
		self.s.send('-r -i admin-c ' + self.domain.admin_c[0] + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.domain == self.domain.domain:
				found = True
				break
		self.assertEqual(found, True, 'inverse admin-c not working\n%s\n%s' %
				(rawans, ans))

	def test_invNsset(self):
		self.s.send('-r -i nsset ' + self.domain.nsset + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.domain == self.domain.domain:
				found = True
				break
		self.assertEqual(found, True, 'inverse nsset not working\n%s\n%s' %
				(rawans, ans))

	def test_invKeyset(self):
		self.s.send('-r -i keyset ' + self.domain.keyset + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.domain == self.domain.domain:
				found = True
				break
		self.assertEqual(found, True, 'inverse keyset not working\n%s\n%s' %
				(rawans, ans))

	def test_invNserver(self):
		self.s.send('-r -i nserver ' + self.nsset.nserver[1] + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.nsset == self.nsset.nsset:
				found = True
				break
		self.assertEqual(found, True, 'inverse nserver not working\n%s\n%s' %
				(rawans, ans))

	def test_invTech_c(self):
		self.s.send('-r -T nsset -i tech-c ' + self.nsset.tech_c[0] + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.nsset == self.nsset.nsset:
				found = True
				break
		self.assertEqual(found, True, 'inverse tech-c for nsset not working\n%s\n%s' %
				(rawans, ans))

	def test_invTech_c_Keyset(self):
		self.s.send('-r -T keyset -i tech-c ' + self.keyset.tech_c[0] + '\r\n')
		rawans = self.s.recv(BUFFSIZE)
		ans = Answer(rawans)
		found = False
		for obj in ans.objects:
			if obj.keyset == self.keyset.keyset:
				found = True
				break
		self.assertEqual(found, True, 'inverse tech-c for keyset not working\n%s\n%s' %
				(rawans, ans))



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
	whois_suite = unittest.TestLoader().loadTestsFromTestCase(NotObjectSpecificTests)
	whois_suite2 = unittest.TestLoader().loadTestsFromTestCase(ObjectSpecificTests)
	whois_suite.addTest(whois_suite2)
	#fm_suite.addTest(SearchTest())

	# Run unittests
	unittest.TextTestRunner(verbosity = level).run(whois_suite)

