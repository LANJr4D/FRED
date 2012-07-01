#!/usr/bin/env python
# vim: set ts=4 sw=4:
#
# All changes in classes against standart distutils is marked with `DIST'
# string in comments above each change.

import sys, os, string, commands, stat, types
from distutils import log
from distutils import util
from distutils import errors
from distutils.command import config
from distutils import version
from freddist.core import setup
from freddist.command import install
from freddist.command.install_scripts import install_scripts
from freddist.command.install_data import install_data
from freddist import file_util
from freddist.command.sdist import sdist
if not '..' in sys.path:
    sys.path.append('..')
from freddist.filelist import FileList

PROJECT_NAME = 'pyfred_server'
PACKAGE_NAME = 'pyfred_server'
PACKAGE_VERSION = '2.3.0'
DEFAULT_DBUSER = 'fred'
DEFAULT_DBNAME = 'fred'
DEFAULT_DBHOST = 'localhost'
DEFAULT_DBPORT = '5432'
DEFAULT_DBPASS = ''
DEFAULT_MODULES = 'genzone mailer filemanager techcheck'
DEFAULT_NSCONTEXT = 'fred'
DEFAULT_NSHOST = 'localhost'
DEFAULT_NSPORT = '2809'
DEFAULT_PYFREDPORT = '2225'
DEFAULT_SENDMAIL = '' #'/usr/sbin/sendmail'
DEFAULT_DRILL = ''


#$localstatedir/lib/pyfred/filemanager
DEFAULT_FILEMANAGERFILES = 'lib/pyfred/filemanager/'
#whole path is by default $libexecdir/pyfred
DEFAULT_TECHCHECKSCRIPTDIR = 'pyfred' 
#whole is $localstatedir/run/pyfred.pid
DEFAULT_PIDFILE = 'run/pyfred.pid'
#$prefix/bin/pyfred_server
DEFAULT_PYFREDSERVER = 'bin/fred-pyfred'
#$prefix/etc/fred/pyfred.conf
DEFAULT_PYFREDSERVERCONF = 'fred/pyfred.conf'
#whole is $localstatedir/zonebackup
DEFAULT_ZONEBACKUPDIR = 'zonebackup'
#whole is $localstatedir/log/fred-pyfred.log
DEFAULT_LOGFILENAME = 'log/fred-pyfred.log'

#list of all default pyfred modules
g_modules = ["FileManager", "Mailer", "TechCheck", "ZoneGenerator"]
#list of parameters for omniidl executable
g_omniidl_params = ["-Cbuild/stubs", "-bpython", "-Wbinline"]

#whether install unittests scripts
g_install_unittests = None

class Config (config.config):
    """
    This is config class, which checks for pyfred specific prerequisities.
    """

    description = "Check prerequisities of pyfred"

    def run(self):
        """
        The equivalent of classic configure script. The list of things tested
        here:
            *) OS
            *) Python version
            *) presence of omniORB, pygresql, dnspython, clearsilver modules
        """
        # List of tests which follow
        error = False

        # OS
        log.info(" * Operating system ... %s", sys.platform)
        if sys.platform[:5] != "linux":
            log.error("    The pyfred is not platform independent and requires "
                    "linux OS to run.")

        # python version
        python_version = version.LooseVersion(sys.version.split(' ')[0])
        log.info(" * Python version ... %s", python_version)
        # check lower bound
        if python_version < "2.4":
            log.error("    At least version 2.4 is required.")
            error = True
        # check upper bound
        if python_version >= "2.6":
            log.warn("    Pyfred was tested with version 2.4 and 2.5. Running "
                    "more recent version of \n    python might lead to a "
                    "problems. You have been warned.")

        # check module (package) dependencies
        try:
            import omniORB
            log.info(" * Package omniORB found (version cannot be verified).")
        except ImportError, e:
            log.error(" * Package omniORB with python bindings is required and "
                    "not installed!")
            log.info("    omniORB is ORB implementation in C++ "
                    "(http://omniorb.sourceforge.net/)")
            error = True

        try:
            import pgdb
            pgdb_version = version.StrictVersion(pgdb.version)
            log.info(" * package pygresql version ... %s", pgdb.version)
            if pgdb_version < "3.6":
                log.error("    At least version 3.6 of pygresql is required!")
                error = True
            if pgdb_version >= "3.9":
                log.warn("    Versions newer than 3.8 of pygresql are not "
                        "tested to work with pyfred.\n    Use at your own risk.")
        except ImportError, e:
            log.error(" * Package pygresql is required and not installed!")
            log.info("    pygresql is DB2 API compliant library for postgresql "
                    "(http://www.pygresql.org/).")
            error = True

        try:
            import dns.version
            log.info(" * Package dnspython version ... %s", dns.version.version)
            dns_version = version.StrictVersion(dns.version.version)
            if dns_version < "1.3":
                log.error("    At least version 1.3 of dnspython is required!")
                error = True
            if dns_version > "1.5":
                log.warn("    Versions newer than 1.5 of dnspython are not "
                        "tested to work with pyfred.\n    Use at your own risk.")
        except ImportError, e:
            log.error(" * Package dnspython with python bindings is required "
                    "and not installed!")
            log.info("    dnspython is DNS library (http://www.dnspython.org/)")
            error = True

        try:
            import neo_cgi
            cs_CAPI_version = neo_cgi._C_API_NUM
            log.info(" * C API version of clearsilver ... %d", cs_CAPI_version)
            if cs_CAPI_version != 4:
                log.warn("    The only tested C API version of clearsilver is 4."
                        "   Use at your own risk")
        except ImportError, e:
            log.error(" * Package clearsilver with python bindings is required "
                    "and not installed!")
            log.info("    clearsilver is template system "
                    "(http://www.clearsilver.net/).")
            error = True

        # bad test
        #error = True

        # print concluding status of test
        if error:
            log.error("One or more errors were detected. Please fix them and "
                    "then run the \nsetup script again.")
            raise SystemExit(1)
        else:
            log.info("All tests were passed successfully")
#class Config

def isDir(path):
    """return True if path is directory, otherwise False"""
    return os.path.stat.S_ISDIR(os.stat(path)[os.path.stat.ST_MODE])

def isFile(path):
    """return True if path is regular file, otherwise True"""
    return os.path.stat.S_ISREG(os.stat(path)[os.path.stat.ST_MODE])

def compile_idl(cmd, pars, files):
    """
    Put together command line for python stubs generation.
    """
    for par in pars:
        if par.strip()[:2] == '-C':
            #param `-C' (Change directory do dir) was used, so test
            #and if need create directory build/lib
            if not os.path.exists(par.strip()[2:]):
                try:
                    os.makedirs(par.strip()[2:])
                    print "Create directory", par.strip()[2:]
                except OSError, e:
                    print e
    cmdline = cmd +' '+ string.join(pars) +' '+ string.join(files)
    log.info(cmdline)
    status, output = commands.getstatusoutput(cmdline)
    log.info(output)
    if status != 0:
        raise errors.DistutilsExecError("Return status of %s is %d" %
                (cmd, status))

def gen_idl_name(dir, name):
    """
    Generate name of idl file from directory prefix and IDL module name.
    """
    return os.path.join(dir, name + ".idl")

class Install (install.install, object):
    user_options = []
    user_options.extend(install.install.user_options)
    user_options.append(('modules=', None, 'which pyfred modules will be loaded'
        ' [genzone mailer filemanager techcheck]'))
    user_options.append(('nscontext=', None, 
        'CORBA nameservice context name [fred]'))
    user_options.append(('nshost=', None, 
        'CORBA nameservice host [localhost]'))
    user_options.append(('nsport=', None, 
        'Port where CORBA nameservice listen [2809]'))
    user_options.append(('dbuser=', None, 
        'Name of FRED database user [fred]'))
    user_options.append(('dbname=', None, 
        'Name of FRED database [fred]'))
    user_options.append(('dbhost=', None, 'FRED database host [localhost]'))
    user_options.append(('dbport=', None, 
        'Port where PostgreSQL database listening [5432]'))
    user_options.append(('dbpass=', None, 'Password to FRED database []'))
    user_options.append(('pyfredport=', None, '  [2225]'))
    user_options.append(("omniidl=", "i", 
        "omniidl program used to build stubs [omniidl]"))
    user_options.append(("idldir=",  "d", 
        "directory where IDL files reside [PREFIX/share/idl/fred/]"))
    user_options.append(("idlforce", "o", 
        "force idl stubs to be always generated"))
    user_options.append(('install-unittests', None,
        'setup will install unittest scripts into '
        'PREFIX/lib/fred-pyfred/unittests directory'))
    user_options.append(("sendmail=", None, "sendmail path"))
    user_options.append(("drill=", None, "drill utility path"))

    boolean_options = install.install.boolean_options
    boolean_options.append('install-unittests')

    def __init__(self, *attrs):
        super(Install, self).__init__(*attrs)

        self.basedir = None
        self.interactive = None
        self.dbuser = DEFAULT_DBUSER
        self.dbname = DEFAULT_DBNAME
        self.dbhost = DEFAULT_DBHOST
        self.dbport = DEFAULT_DBPORT
        self.dbpass = DEFAULT_DBPASS
        self.nscontext = DEFAULT_NSCONTEXT
        self.nshost = DEFAULT_NSHOST
        self.nsport = DEFAULT_NSPORT
        self.modules = DEFAULT_MODULES
        self.pyfredport = DEFAULT_PYFREDPORT
        self.sendmail = DEFAULT_SENDMAIL
        self.drill = DEFAULT_DRILL

    def initialize_options(self):
        super(Install, self).initialize_options()
        self.idldir   = None
        self.idlforce = False
        self.omniidl  = None
        self.omniidl_params = g_omniidl_params #["-Cbuild/lib", "-bpython", "-Wbinline"]
        self.idlfiles = g_modules#["FileManager", "Mailer", "TechCheck", "ZoneGenerator"]
        self.install_unittests = None
        self.sendmail = None
        self.drill = None

    def finalize_options(self):
        # cmd_obj = self.distribution.get_command_obj('bdist', False)
        # if cmd_obj:
            #this will be proceeded only if install command will be
            #invoked from bdist command
            # self.idldir = cmd_obj.idldir
        super(Install, self).finalize_options()
        if not self.omniidl:
            self.omniidl = "omniidl"
        global g_install_unittests
        g_install_unittests = self.install_unittests

        if not self.idldir:
            # set idl directory to datarootdir/idl/fred/
            self.idldir=os.path.join(self.datarootdir, "idl", "fred")

        if self.install_unittests:
            self.distribution.data_files.append(
                    ('LIBDIR/%s/unittests' % self.distribution.get_name(), 
                        file_util.all_files_in_2('unittests', ['.*'])))

    def find_sendmail(self):
        self.sendmail = DEFAULT_SENDMAIL
        paths = ['/usr/bin', '/usr/sbin']
        filename = 'sendmail'
        for i in paths:
            if os.path.exists(os.path.join(i, filename)):
                self.sendmail = os.path.join(i, filename)
                log.info("sendmail found in %s" % i)
                return True
        log.error("Error: sendmail not found.")
        return False

    def find_drill(self):
        self.drill = DEFAULT_DRILL
        paths = ['/usr/bin', '/usr/sbin']
        filename = 'drill'
        for i in paths:
            if os.path.exists(os.path.join(i, filename)):
                self.drill = os.path.join(i, filename)
                log.info("drill found in %s" % i)
                return True
        log.error("Error: drill not found.")
        return False

    def update_server_config(self):
        """
        Update config items and paths in pyfred.conf file.
        """
        values = []
        values.append(('MODULES', self.modules))
        values.append(('DBUSER', self.dbuser))
        values.append(('DBNAME', self.dbname))
        values.append(('DBHOST', self.dbhost))
        values.append(('DBPORT', self.dbport))
        values.append(('DBPASS', self.dbpass))
        values.append(('NSCONTEXT', self.nscontext))
        values.append(('NSHOST', self.nshost))
        values.append(('NSPORT', self.nsport))
        values.append(('SENDMAIL', self.sendmail))
        values.append(('PYFREDPORT', self.pyfredport))
        values.append(('DRILL', self.drill))

        values.append(('FILEMANAGERFILES', os.path.join(
            self.getDir('localstatedir'), DEFAULT_FILEMANAGERFILES)))
        values.append(('TECHCHECKSCRIPTDIR', os.path.join(
            self.getDir('libexecdir'), DEFAULT_TECHCHECKSCRIPTDIR)))
        values.append(('PIDFILE', os.path.join(
            self.getDir('localstatedir'), DEFAULT_PIDFILE)))
        values.append(('LOGFILENAME', os.path.join(
            self.getDir('localstatedir'), DEFAULT_LOGFILENAME)))

        self.replace_pattern(
                os.path.join(self.srcdir, 'conf', 'pyfred.conf.install'),
                os.path.join('build', 'pyfred.conf'),
                values)
        print "Configuration file has been updated"

    def update_genzone_config(self):
        """
        Update paths in genzone.conf file.
        """
        values = []
        values.append(('ZONEBACKUPDIR', self.getDir('localstatedir')))
        values.append(('NAMESERVICE', self.nshost + ":" + self.nsport))
        values.append(('CONTEXT', self.nscontext))

        self.replace_pattern(
                os.path.join(self.srcdir, 'conf', 'genzone.conf.install'),
                os.path.join('build', 'genzone.conf'),
                values)
                #map(None, patterns, newvals))

        print "genzone configuration file has been updated"

    def check_dependencies(self):
        Config(self.distribution).run()

        error = False
        if self.sendmail:
            if not (os.path.exists(self.sendmail) or os.access(self.sendmail, os.X_OK)):
                log.error("Dependency error: not valid path to sendmail given through parameters.")
                error = True
        else:
            if not self.find_sendmail():
                error = True
        if self.drill:
            if not (os.path.exists(self.drill) or os.access(self.drill, os.X_OK)):
                log.error("Dependency error: not valid path to drill given through parameters.")
                error = True
        else:
            if not self.find_drill():
                error = True
        if error:
            raise SystemExit, "If you want to suppress these error run install with " \
                              "--no-check-deps option."

    def run(self):
        if not self.no_check_deps:
            self.check_dependencies()
        
        self.update_server_config()
        self.update_genzone_config()

        super(Install, self).run()
#class Install


class Install_data(install_data):
    user_options = install_data.user_options
    user_options.append(("omniidl=", "i", 
        "omniidl program used to build stubs [omniidl]"))
    user_options.append(("idldir=",  "d", 
        "directory where IDL files reside [PREFIX/share/idl/fred/]"))
    user_options.append(("idlforce", "o", 
        "force idl stubs to be always generated"))
    
    boolean_options = install_data.boolean_options
    boolean_options.append('idlforce')

    def initialize_options(self):
        install_data.initialize_options(self)
        self.install_unittests = None
        self.omniidl = None
        self.idldir = None
        self.idlforce = None

    def finalize_options(self):
        install_data.finalize_options(self)
        self.install_unittests = g_install_unittests
        self.set_undefined_options('install',
                ('omniidl', 'omniidl'),
                ('idldir', 'idldir'),
                ('idlforce', 'idlforce'))

    def update_test_filemanager(self):
        values = []
        values.append((r'(pyfred_bin_dir\ =\ )\'\/usr\/local\/bin\/\'',
            r"\1'%s'" % os.path.join(self.getDir('prefix'), 'bin')))

        self.replace_pattern(
                os.path.join(self.getDir('libdir'), self.distribution.get_name(),
                    'unittests', 'test_filemanager.py'),
                None, values)
        print "test_filemanager file has been updated"

    def update_test_genzone(self):
        values = []
        values.append((r'(pyfred_bin_dir\ =\ )\'\/usr\/local\/bin\/\'',
            r"\1'%s'" % os.path.join(self.getDir('prefix'), 'bin')))
        values.append((r'(config\.read)\(\'\/etc\/fred\/pyfred.conf\'\)',
            r"\1('%s')" %
            os.path.join(self.getDir('sysconfdir'), 'fred', 'pyfred.conf')))
        values.append((r'(config\.read)\(\'\/etc\/fred\/genzone.conf\'\)',
            r"\1('%s')" %
            os.path.join(self.getDir('sysconfdir'), 'fred', 'genzone.conf')))

        self.replace_pattern(
                os.path.join(self.getDir('libdir'), self.distribution.get_name(),
                    'unittests', 'test_genzone.py'),
                None, values)
        print "test_genzone file has been updated"

    def run(self):
        self.omniidl_params = g_omniidl_params
        self.modules = g_modules
        if not os.path.isdir(os.path.join(self.rundir, 'build', 'stubs', 'pyfred', 'idlstubs')):
            os.makedirs(os.path.join(self.rundir, 'build', 'stubs', 'pyfred', 'idlstubs'))
        #create (if need) idl files
        self.omniidl_params.append("-Wbpackage=pyfred.idlstubs")
        if not self.idlforce and os.access(
                os.path.join(self.rundir, "build/stubs/pyfred/idlstubs/ccReg"),
                    os.F_OK):
            log.info("IDL stubs found, skipping building IDL stubs. Use idlforce "
                    "option to compile idl stubs anyway or run clean target.")
        else:
            util.execute(compile_idl,
                (self.omniidl, self.omniidl_params,
                    [ gen_idl_name(self.idldir, module) for module in self.modules ]),
                    "Generating python stubs from IDL files")

        self.data_files = self.data_files +\
                file_util.all_files_in('PURELIBDIR',
                        os.path.join('build', 'stubs', 'pyfred', 'idlstubs'),
                        recursive=True, cutSlashes_dst=1)
        install_data.run(self)

        # TODO so far is impossible to create rpm package with unittests \ 
        # scripts in it, because of update_* methods have wrong paths \
        # to files which should be changed.
        if self.install_unittests or self.is_bdist_mode:
            self.update_test_filemanager()
            self.update_test_genzone()

class Install_scripts(install_scripts):
    """
    Copy of standart distutils install_scripts with some small
    addons (new options derived from install class)
    """

    # def get_actual_root(self):
        # return self.actualRoot
    def __init__(self, *attrs):
        install_scripts.__init__(self, *attrs)
        self.pythonLibPath = os.path.join('lib', 'python' +
                str(sys.version_info[0]) + '.' + 
                str(sys.version_info[1]), 'site-packages')

    def update_pyfredctl(self):
        """
        Update paths in pyfredctl file (location of pid file and
        fred-pyfred file)
        """
        values = []
        values.append((r'(pidfile = )\'[\w/_ \-\.]*\'',
            r"\1'%s'" % os.path.join(self.getDir('localstatedir'),
                DEFAULT_PIDFILE)))
        values.append((r'(pyfred_server = )\'[\w/_ \-\.]*\'',
            r"\1'%s'" % os.path.join(self.getDir('prefix'),
                DEFAULT_PYFREDSERVER)))
        self.replace_pattern(
                os.path.join(self.build_dir, 'pyfredctl'),
                None, values)
        print "pyfredctl file has been updated"

    def update_pyfred_server(self):
        """
        Update paths in fred-pyfred file (path to config file and search
        path for modules).
        """
        values = []
        values.append((r'(configs = )\["[\w/_\- \.]*",',
            r"\1['%s'," % os.path.join(self.getDir('sysconfdir'),
                DEFAULT_PYFREDSERVERCONF)))
        values.append((r'(sys\.path\.insert\(0, )\'\'\)',
            r"\1'%s')" % self.getDir('purelibdir')))
            # r"\1('%s')" % os.path.join(self.getDir('prefix'),
                # self.pythonLibPath)))
        self.replace_pattern(
                os.path.join(self.build_dir, 'fred-pyfred'),
                None, values)
        print "fred-pyfred file has been updated"

    def update_filemanager_admin_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred', 
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'filemanager_admin_client'),
                None, values)
        print "filemanager_admin_client file has been updated"

    def update_filemanager_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'filemanager_client'),
                None, values)
        print "filemanager_client file has been updated"

    def update_genzone_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/genzone.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred', 
                'genzone.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'genzone_client'),
                None, values)
        print "genzone_client file has been updated"

    def update_genzone_test(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/genzone.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred', 
                'genzone.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'check_pyfred_genzone'),
                None, values)
        print "check_pyfred_genzone file has been updated"

    def update_mailer_admin_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'mailer_admin_client'),
                None, values)
        print "mailer_admin_client file has been updated"

    def update_mailer_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'mailer_client'),
                None, values)
        print "mailer_client file has been updated"

    def update_techcheck_admin_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'),
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'techcheck_admin_client'),
                None, values)
        print "techcheck_admin_client file has been updated"

    def update_techcheck_client(self):
        values = []
        values.append((r"(sys\.path\.insert\(0,\ )''\)",
            r"\1 '%s')" % os.path.join(self.getDir('prefix'), 
                self.pythonLibPath)))
        values.append((r"(configfile\ =\ )'\/etc\/fred\/pyfred.conf'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred', 
                'pyfred.conf')))

        self.replace_pattern(
                os.path.join(self.build_dir, 'techcheck_client'),
                None, values)
        print "techcheck_client file has been updated"

    def run(self):
        self.update_pyfredctl()
        self.update_pyfred_server()
        self.update_filemanager_admin_client()
        self.update_filemanager_client()
        self.update_genzone_client()
        self.update_genzone_test()
        self.update_mailer_admin_client()
        self.update_mailer_client()
        self.update_techcheck_admin_client()
        self.update_techcheck_client()
        return install_scripts.run(self)
#class Install_scripts

def main():
    try:
        if not os.path.isdir('build/stubs/pyfred/idlstubs'):
            os.makedirs('build/stubs/pyfred/idlstubs')
        setup(name="fred-pyfred", version=PACKAGE_VERSION,
                description="Component of FRED (Fast Registry for Enum and Domains)",
                author   = "Jan Kryl",
                author_email="jan.kryl@nic.cz",
                url      = "http://fred.nic.cz/",
                license  = "GNU GPL",
                cmdclass = { "config":Config,
                             "install":Install,
                             "install_scripts":Install_scripts,
                             "install_data":Install_data,
                             },
                packages = ["pyfred", "pyfred.modules"],
                py_modules = ['pyfred.idlstubs',
                    'pyfred.idlstubs.ccReg',
                    'pyfred.idlstubs.ccReg__POA'],
                #XXX 'requires' option does not work allthough it is described in
                #official documentation.
                #requires = ["omniORB", "pgdb(>=3.6)", "dns(>=1.3)", "neo_cgi"],
                scripts  = [
                    "scripts/fred-pyfred",
                    "scripts/pyfredctl",
                    "scripts/filemanager_admin_client",
                    "scripts/filemanager_client",
                    "scripts/genzone_client",
                    "scripts/check_pyfred_genzone",
                    "scripts/mailer_admin_client",
                    "scripts/mailer_client",
                    "scripts/techcheck_admin_client",
                    "scripts/techcheck_client",
                    ],
                data_files = [
                    # create empty directories
                    ('LOCALSTATEDIR/run',),
                    ('LOCALSTATEDIR/lib/pyfred/filemanager',),
                    ('LIBEXECDIR/pyfred',
                        [
                            "tc_scripts/authoritative.py",
                            "tc_scripts/autonomous.py",
                            "tc_scripts/existance.py",
                            "tc_scripts/heterogenous.py",
                            "tc_scripts/presence.py",
                            "tc_scripts/recursive4all.py",
                            "tc_scripts/recursive.py",
                            "tc_scripts/dnsseckeychase.py"
                        ]
                    ),
                    ('SYSCONFDIR/fred',
                        [
                            os.path.join("build", "pyfred.conf"),
                            os.path.join("build", "genzone.conf")
                        ]
                    ),
                ],
                )
        return True
    except Exception, e:
        log.error("Error: %s", e)
        return False

if __name__ == '__main__':
    if main():
        print "All done!"
