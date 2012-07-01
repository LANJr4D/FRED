#!/usr/bin/env python
#
# vim:ts=4 sw=4:

'''
This file tests filemanager component of pyfred server.

Here is a hierarchy of test suites and test cases:

filemanager_suite
    |-- TypeEnumTest
    |
    |-- UploadTest
    |       |-- test_uploadFromFile
    |       |-- test_uploadFromStdin
    |
    |-- DownloadTest
    |
    |-- SearchTest

See comments in appropriate classes and methods for more information about
their operation. General description follows. For inserting test data from
central register we use filemanager_client.  The changes made by this unittest
are not reversible! The files uploaded to server by client are not deleted
afterwards. So it must be run on test instance of central register.
'''

import commands, ConfigParser, sys, getopt, os, re, random, os
import pgdb
import unittest

# bin dir will be added during setup
pyfred_bin_dir = '/usr/local/bin/'

def usage():
    print '%s [-v LEVEL | --verbose=LEVEL]' % sys.argv[0]
    print
    print 'verbose level number is handed over to unittest function as it is.'
    print

def create_test_file():
    '''
    Create test file.
    '''
    filename = '/tmp/uploadtest'
    fd = open(filename, 'w')
    fd.write('This is content of a file, which is used to test\n')
    fd.write('filemanager. The test is part of pyfred\'s unittests.\n')
    fd.close()
    return filename


class TypeEnumTest(unittest.TestCase):
    '''
    Try to download list of file types with help of filemanager_admin_client.
    '''

    def runTest(self):
        '''
        Download list of file types with help of filemanager_admin_client.
        '''
        (status, output) = commands.getstatusoutput(
                os.path.join(pyfred_bin_dir, 'filemanager_admin_client -e'))
        status = os.WEXITSTATUS(status) # translate status
        self.assertEqual(status, 0, 'Could not obtain file type enumeration\n'
                '%s\n' % output)
        pattern = re.compile('^\d+\s+\w.+$')
        for line in output.split('\n'):
            self.assert_(pattern.match(line), 'Line with invalid syntax: %s' %
                    line)


class UploadTest(unittest.TestCase):
    '''
    We try to upload a file in two ways (as a file and via stdin).
    '''

    def setUp(self):
        '''
        Create test file which will be uploaded.
        '''
        self.filename = create_test_file()

    def tearDown(self):
        '''
        Remove test file.
        '''
        os.unlink(self.filename)

    def test_uploadFromFile(self):
        '''
        Upload a file specified by filename.
        '''
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_client --input=%s --mime="text/plain" --type=0' %\
                self.filename)
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        self.assertEqual(status, 0, 'Could not upload file %s\n%s' %
                (self.filename, output))

    def test_uploadFromStdin(self):
        '''
        Upload a content on stdin.
        '''
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_client --mime="text/plain" --type=0 <%s' %\
                self.filename)
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        self.assertEqual(status, 0, 'Could not upload content of %s\n%s' %
                (self.filename, output))


class DownloadTest(unittest.TestCase):
    '''
    We try to upload a file in two ways (as a file and via stdin).
    '''

    def setUp(self):
        '''
        Create test file and uploaded it.
        '''
        filename = create_test_file()
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_client --input=%s --mime="text/plain" --type=0 '\
                '--silent' % filename)
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        if status != 0:
            raise Exception('Could not upload file %s\n%s' % (filename, output))
        self.fileid = int(output)
        fd = open(filename, 'r')
        self.content = fd.read()
        fd.close()
        os.unlink(filename)

    def runTest(self):
        '''
        Download a file uploaded in setUp.
        '''
        filename = '/tmp/downloadtest'
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_client --output="%s" --id=%d' %\
                (filename, self.fileid))
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        self.assertEqual(status, 0, 'Could not download file\n%s' % output)
        fd = open(filename, 'r')
        content = fd.read()
        fd.close()
        os.unlink(filename)
        self.assertEqual(content, self.content,
                'Content of downloaded file seems wrong')


class SearchTest(unittest.TestCase):
    '''
    Search uploaded file with help of filemanager_admin_client.
    '''

    def setUp(self):
        '''
        Create test file which will be uploaded.
        '''
        self.filename = create_test_file()
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_client --input=%s --mime="text/plain" --type=0 '\
                '--silent' % self.filename)
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        if status != 0:
            raise Exception('Could not upload file %s\n%s' %
                    (self.filename, output))
        self.fileid = int(output)
        os.unlink(self.filename)

    def runTest(self):
        '''
        Find uploaded file.
        '''
        cmd = os.path.join(pyfred_bin_dir, 'filemanager_admin_client --chunk=1 --label="%s" '\
                '--mime="text/plain" --type=0 --id=%d' %\
                (self.filename[self.filename.rfind('/')+1:], self.fileid))
        (status, output) = commands.getstatusoutput(cmd)
        status = os.WEXITSTATUS(status) # translate status
        self.assertEqual(status, 0, 'Error when searching for file\n%s'% output)
        count = 0
        for line in output.split('\n'):
            if line.startswith('*' * 10):
                count += 1
        self.assertEqual(count, 2, 'Different # of found mails than expected '
                '(%d)\n%s\n%s' % (count, cmd, output))


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
    fm_upload_suite = unittest.TestLoader().loadTestsFromTestCase(UploadTest)
    fm_suite = unittest.TestSuite()
    fm_suite.addTest(TypeEnumTest())
    fm_suite.addTest(fm_upload_suite)
    fm_suite.addTest(DownloadTest())
    fm_suite.addTest(SearchTest())

    # Run unittests
    unittest.TextTestRunner(verbosity = level).run(fm_suite)
