#!/usr/bin/python
#
import os
import re
import sys
from distutils import log

from freddist.core import setup
from freddist.command.install import install
from freddist.command.install_scripts import install_scripts
from freddist.command.install_lib import install_lib
from freddist.file_util import all_files_in_2

# from statistics import simple_stats

PROJECT_NAME = 'fred-whois'
PACKAGE_NAME = 'fred_whois'
DEFAULT_APACHE_CONFIG = 'apache.conf'

PACKAGE_CAPTCHA = PACKAGE_NAME + '.CaptchaWhois'

# install files into folders according to filesystem standard FHS
SHARE_DOC = os.path.join('share', 'doc', PROJECT_NAME)

SHARE_TEMPLATES = os.path.join(PROJECT_NAME, 'templates')
SHARE_LOCALE = os.path.join(PROJECT_NAME, 'locale')
SHARE_WWW = os.path.join(PROJECT_NAME, 'www')

SHARE_WWW_CLIP = os.path.join(SHARE_WWW, '_clip')
SHARE_WWW_IMG = os.path.join(SHARE_WWW, '_img')
SHARE_WWW_CSS = os.path.join(SHARE_WWW, '_css')
SHARE_WWW_JS = os.path.join(SHARE_WWW, '_js')

INSTALL_DOC = """Copy this file into apache configuration folder (or make symlink). 
# For examle:
#$ ln -s /usr/share/doc/fred-whois/%s /etc/apache2/sites-available/
""" % DEFAULT_APACHE_CONFIG

class FredWhoisInstall(install):
    user_options = install.user_options
    user_options.append(('context=', None,
        'CORBA nameservice context name [fred]'))
    user_options.append(('host=', None,
        'CORBA nameservice host [localhost:2809]'))
    user_options.append(("idldir=", "d",
        "directory where IDL files reside [PREFIX/share/idl/fred/]"))

    def initialize_options(self):
        install.initialize_options(self)
        self.context = None
        self.host = None
        self.idldir = None

    def finalize_options(self):
        install.finalize_options(self)
        if not self.context:
            self.context = 'fred'
        if not self.host:
            self.host = 'localhost:2809'
        if not self.idldir:
            self.idldir = os.path.join(self.datarootdir, 'idl', 'fred')

    def check_TAL(self):
        try:
            import simpletal
        except ImportError, msg:
            sys.stderr.write('ImportError: %s\nWhois needs simpletal module. For more see README.\n' % msg)
            sys.exit(1)

    def check_CORBA(self):
        try:
            from omniORB import CORBA
            import omniidl
        except ImportError, msg:
            sys.stderr.write('ImportError: %s\nWhois needs omniORB and omniidl module. For more see README.\n' % msg)
            sys.exit(1)

    def check_PIL(self):
        'Check if exists python image'
        try:
            import Image
        except ImportError, msg:
            sys.stderr.write('ImportError: %s\nWhois needs Image module (python image library). For more see README.\n' % msg)
            sys.exit(1)

    def check_dependencies(self):
        'Check all dependencies needed for runnig whois'
        print "Checking dependencies needed for running whois"
        self.check_PIL()
        self.check_TAL()
        self.check_CORBA()

    def update_whois_config(self):
        '''Update whois config'''
        values = []
        values.append(('ROOT_BASEDIR',
            os.path.join(self.getDir('datarootdir'), PROJECT_NAME)))
        values.append(('LOCALSTATEDIR', self.getDir('localstatedir')))
        values.append(('TEMPLATES_BASEDIR',
            os.path.join(self.getDir('datarootdir'), PROJECT_NAME, 'templates')))
        values.append(('SHARE_PACKAGE',
            os.path.join(self.getDir('datarootdir'), PROJECT_NAME)))
        values.append(('CORBA_IDL', os.path.join(self.idldir, 'ccReg.idl')))
        values.append(('CORBA_HOST', self.host))
        values.append(('CORBA_CONTEXT', self.context))

        self.replace_pattern(
                os.path.join(self.srcdir, 'conf', 'whois.conf.install'),
                os.path.join('build', 'whois.conf'),
                values)
        print 'Whois configuration file has been updated.'

    def update_apache_config(self):
        '''Update apache config'''

        values = []
        values.append(('PYTHON_ROOT', self.getDir('purelibdir')))
        values.append(('INSTALL_PURELIB',
            os.path.join(self.getDir('purelibdir'), PACKAGE_NAME)))
        values.append(('SHARE_WWW',
            os.path.join(self.getDir('datarootdir'), PROJECT_NAME, 'www')))

        self.replace_pattern(
                os.path.join(self.srcdir, 'conf', 'apache.conf.install'),
                os.path.join('build', 'apache.conf'),
                values)
        print 'Whois Apache configuration file has been updated.'


    def run(self):
        if not self.no_check_deps:
            self.check_dependencies()

        self.update_whois_config()
        self.update_apache_config()
        install.run(self)


class FredWhoisLib(install_lib):
    def update_whois(self):
        values = []
        values.append((r"(config = os.environ.get\('WHOIS_CONFIG_FILE' , )'[a-zA-Z/\.-_]*'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'whois.conf')))
        self.replace_pattern(
                os.path.join(self.build_dir, PACKAGE_NAME, 'whois.py'),
                None, values)
        print 'whois.py file has been updated.'

    def update_simple_stats(self):
        values = []
        values.append((r"(config = )'[a-zA-Z/\.-_]*'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'whois.conf')))
        self.replace_pattern(
                os.path.join(self.build_dir, PACKAGE_NAME,
                    'statistics', 'simple_stats.py'),
                None, values)
        print 'simple_stats.py file has been updated.'

    def run(self):
        self.update_whois()
        self.update_simple_stats()
        install_lib.run(self)


class FredWhoisScripts(install_scripts):
    def update_simple_stats(self):
        values = []
        values.append((r"(config = )'[a-zA-Z/\.-_]*'",
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred',
                'whois.conf')))
        self.replace_pattern(
                os.path.join(self.build_dir, 'simple_stats.py'),
                None, values)
        print "simple_stats.py file has been updated"

    def run(self):
        self.update_simple_stats()
        return install_scripts.run(self)


def main(directory):
    try:
        setup(
            # Distribution meta-data
            name=PROJECT_NAME,
            description='Fred Whois',
            author='David Pospisilik, Zdenek Bohm, CZ.NIC',
            author_email='zdenek.bohm@nic.cz',
            url='http://www.nic.cz/',
            license='GNU GPL',
            platforms=['posix'],
            long_description='The part of the CZ.NIC CMS web framework.',

            scripts=[os.path.join('statistics', 'simple_stats.py')],
            packages=[PACKAGE_NAME,
                PACKAGE_NAME + '.captcha',
                PACKAGE_CAPTCHA,
                PACKAGE_CAPTCHA + '.Visual',
                PACKAGE_NAME + '.statistics'],
            package_dir={PACKAGE_NAME: '.'},
            package_data={PACKAGE_NAME: ['captcha/pil_missing.jpg'],
                PACKAGE_CAPTCHA: ['data/fonts/vera/*.*']},
            # Value of the option --config will be join into data_files inside
            # class FredWhoisData
            data_files=[
                ('DOCDIR',
                    ['README.txt', os.path.join('build', 'apache.conf')]),
                ('SYSCONFDIR/fred',
                    [os.path.join('build', 'whois.conf')]),
                (os.path.join('DATAROOTDIR', SHARE_TEMPLATES),
                    all_files_in_2(os.path.join(directory, 'templates'))),
                (os.path.join('DATAROOTDIR', SHARE_LOCALE),
                    ['locale/messages.pot', 'locale/cs_CZ.po',
                        'locale/localegen.sh', 'locale/C.po']),
                (os.path.join('DATAROOTDIR', SHARE_LOCALE, 'C', 'LC_MESSAGES'),
                    ['locale/C/LC_MESSAGES/whois.mo']),
                (os.path.join('DATAROOTDIR', SHARE_LOCALE, 'en_US',
                    'LC_MESSAGES'), ['locale/en_US/LC_MESSAGES/whois.mo']),
                (os.path.join('DATAROOTDIR', SHARE_LOCALE, 'cs_CZ',
                    'LC_MESSAGES'), ['locale/cs_CZ/LC_MESSAGES/whois.mo']),
                (os.path.join('DATAROOTDIR', SHARE_WWW_CLIP),
                    all_files_in_2(os.path.join(directory, '_clip'))),
                (os.path.join('DATAROOTDIR', SHARE_WWW_IMG),
                    all_files_in_2(os.path.join(directory, '_img'))),
                (os.path.join('DATAROOTDIR', SHARE_WWW_CSS),
                    all_files_in_2(os.path.join(directory, '_css'))),
                (os.path.join('DATAROOTDIR', SHARE_WWW_JS),
                    all_files_in_2(os.path.join(directory, '_js'))),
                (os.path.join('DATAROOTDIR', SHARE_WWW_JS, 'MochiKit'),
                    all_files_in_2(os.path.join(directory, '_js/MochiKit')))
                ],
            cmdclass={
                'install': FredWhoisInstall,
                'install_scripts': FredWhoisScripts,
                'install_lib': FredWhoisLib,
                },
            )
        return True
    except Exception, e:
        log.error("Error: %s" % e)
        return False



if __name__ == '__main__':
    dir = ''
    if 'bdist' in sys.argv:
        dir = ''
    else:
        dir = os.path.dirname(sys.argv[0])
    print dir
    if main(dir):
        print "All done!"
