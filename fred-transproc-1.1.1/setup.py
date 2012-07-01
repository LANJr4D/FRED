#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Installation fred transproc.
"""
# Start block --fred-distutils-dir
# add path for freddist if is required and set as argument
import re
import os
import sys

setup = None
try:
    from freddist.core import setup
except ImportError:
    # path to freddist module (use if freddist is not installed)
    explicit_dir_name = None
    pythonpath = os.environ.get("PYTHONPATH", "")
    for argv in sys.argv:
        match = re.match("--fred-distutils-dir=(\S+)", argv)
        if match:
            explicit_dir_name = True
            distpath = match.group(1)
            if distpath not in pythonpath:
                os.environ["PYTHONPATH"] = os.path.pathsep.join(
                                                        (pythonpath, distpath))
            if distpath not in sys.path:
                sys.path.insert(0, distpath)
            break
    if not explicit_dir_name:
        distpath = os.path.dirname(__file__)
        if distpath:
            if distpath not in pythonpath:
                os.environ["PYTHONPATH"] = os.path.pathsep.join(
                                                        (pythonpath, distpath))
            if distpath not in sys.path:
                sys.path.insert(0, distpath)
# End of block --fred-distutils-dir

if setup is None:
    try:
        from freddist.core import setup
    except ImportError, msg:
        print >> sys.stderr, 'ImportError:', msg
        raise SystemExit, 'You required fred-distutils package or define path '\
        'with option --fred-distutils-dir=PATH'

from freddist.command.install import install
from freddist import file_util

PACKAGE_VERSION = '1.1.1'
PROJECT_NAME = 'fred-transproc'
PACKAGE_NAME = 'fred_transproc'

class TransprocInstall(install):
    user_options = []
    user_options.extend(install.user_options)
    user_options.extend([
        ('backendcmd=', None, 'Command for backend CLI admin tool.'),
    ])
    def initialize_options(self):
        install.initialize_options(self)
        self.backendcmd = ''
        
    def update_config(self, src, dest):
        'Update config path variable.'
        # filepath always with root (if is defined)
        body = open(src).read()
        if self.backendcmd:
            body = re.sub("backendcmd\s*=\s*(.*)", 
                          "backendcmd=%s" % self.backendcmd, body)


        body = re.sub("procdir\s*=\s*(.*)", 
                      "procdir=%s" % os.path.join(self.getDir('LIBEXECDIR'), PROJECT_NAME), body)
        body = re.sub("logfile\s*=\s*(.*)",
                      "logfile=%s" % os.path.join(self.getDir('localstatedir'), "log", PROJECT_NAME + ".log"), body)
        open(dest, 'w').write(body)

    def update_transproc_path_to_config(self, src, dest):
        'Update transproc script path variable.'
        # filepath always with root (if is defined)
        body = open(src).read()
        body = re.sub("configfile\s*=\s*(.*)", 
                      "configfile = '%s'" % os.path.join(self.getDir('SYSCONFDIR'), 'fred', 'transproc.conf'), 
                      body, count=1)
        open(dest, 'w').write(body)
    
    
    
        
def main():
    "Run freddist setup"
    setup(
        # Distribution meta-data
        name = PROJECT_NAME,
        author = 'Jan Kryl',
        author_email = 'developers@nic.cz',
        url = 'http://fred.nic.cz/',
        version = PACKAGE_VERSION,
        license = 'GNU GPL',
        platforms = ['posix'],
        description = 'FRED TransProc',
        long_description = 'Component of FRED (Fast Registry for Enum and '
                           'Domains)',
    
        #scripts = ['transproc'], 
        packages = [PACKAGE_NAME], 
        
        data_files = (
            (os.path.join('SYSCONFDIR', 'fred'), ['transproc.conf']), 
            ('DOCDIR', ['backend.xml', 'ChangeLog', 'README']),
            ('BINDIR', ['transproc']),
            (os.path.join('LIBEXECDIR', PROJECT_NAME), ['proc_csob_xml.py', 'proc_ebanka_csv.py', 'proc_ebanka.py']),
        ),
        
        modify_files = {
            'install_data': (('install.update_config', ['transproc.conf']), 
                             ('install.update_transproc_path_to_config', ['transproc']), 
                            ),
            
        },
        
        cmdclass = {
            'install': TransprocInstall, 
        },
    )

if __name__ == '__main__':
    main()
