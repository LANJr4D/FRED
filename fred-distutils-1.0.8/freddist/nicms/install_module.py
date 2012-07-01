#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
This module supports installation process of the nicms modules.
"""
import sys
import os
import re
from freddist import file_util
from freddist.command.install import install, set_file_executable



class NicmsModuleInstall(install):
    """Install class for Fred NICMS modules. Provides all necessary options,
    check dependencies, update cron scripts, show individual help and
    run install process with necessary functions.
    """

    # must be set in descendant
    PROJECT_NAME = None # e.g. 'fred-nicms-payments'
    PACKAGE_NAME = None # e.g. 'fred-nicms-payments'
    PACKAGE_VERSION = None # '1.5.1'
    MODULE_NAME = None # 'payments'
    SCRIPT_CREATE_DB = None # 'fred-nicms-MODULENAME-create-tables'
    # subfolder where is script SCRIPT_CREATE_DB
    SCRIPTS_DIR = 'scripts'
    
    # name of folder for settigns of the dynamic modules
    BASE_CONFIG_MODULE_NAME = 'modules'
    # name of base package
    BASE_CMS_NAME = 'fred-nicms'

    # os.path.join(BASE_CMS_NAME, 'apps', MODULE_NAME)
    BASE_APPS_MODULE_DIR = None
    log = None
    
    
    user_options = install.user_options
    user_options.append(('fredappdir=', None, 'fred-nicms path '\
                                            '[PURELIBDIR/%s]' % BASE_CMS_NAME))


    def initialize_options(self):
        "Define class variables"
        install.initialize_options(self)
        self.fredconfdir = None
        self.fredconfmoduledir = None
        self.fredappdir  = None


    def finalize_options(self):
        "Set default values"
        install.finalize_options(self)

        # path to fred-nicms base folder (/usr/share/fred-nicms)
        if self.fredappdir is None:
            self.fredappdir = os.path.join(os.path.split(self.purepyappdir)[0], 
                                           self.BASE_CMS_NAME)
        
        # path to path to fred-nicms settings modules folder 
        # (/etc/fred/)
        if self.fredconfdir is None:
            # prepare conf_path
            base, folder_name = os.path.split(self.appconfdir)
            if folder_name == self.PACKAGE_NAME:
                self.fredconfdir = os.path.join(base, self.BASE_CMS_NAME)
            else:
                self.fredconfdir = self.appconfdir

        # path to path to fred-nicms settings modules folder 
        # (/etc/fred/nicms_cfg_modules)
        if self.fredconfmoduledir is None:
            self.fredconfmoduledir = os.path.join(self.fredconfdir, 
                                                 self.BASE_CONFIG_MODULE_NAME)
        
        # can be same as fred_nicms or different:
        # share_dir:  '/usr/share/fred-nicms'
        # fred_nicms: '/usr/share/fred-nicms' or 
        #             '/usr/local/lib/python2.5/site-packages/fred-nicms/'
        self.share_dir = os.path.join(self.getDir('DATADIR'),
                                      self.BASE_CMS_NAME)
        self.rootappconfdir = self.appconfdir
        
        # join root if is required
        if self.root and not self.preservepath:
            self.rootappconfdir = os.path.join(self.root, 
                                        self.appconfdir.lstrip(os.path.sep))


    def with_root(self, path):
        "Path with root if is required"
        return path if self.root is None \
                        or self.preservepath \
                        or self.is_bdist_mode \
                    else \
                        os.path.join(self.root, path.lstrip(os.path.sep))


    def check_dependencies(self):
        'Check some dependencies'
        # check base files
        for filepath in (os.path.join(self.with_root(self.fredappdir), 
                        'manage.py'), ):
            if not os.path.isfile(filepath):
                raise SystemExit, "Error: File %s missing.\nIf you want " \
                "override this error use --no-check-deps parameter." % filepath
        
        install.check_dependencies(self)


    def update_data(self, src, dest):
        "Update file by values"
        values = (('MODULE_ROOT', self.with_root(self.fredappdir)), 
                  ('BASE_SHARE_DIR', self.share_dir), 
                  ('DIR_ETC_FRED', self.with_root(self.fredconfdir)))
        # it is necessary to join self.srcdir for situation when current dir
        # is not equal with setup.py dir
#        self.replace_pattern(os.path.join(self.srcdir, src), dest, values)
        self.replace_pattern(src, dest, values)
        if self.log:
            self.log.info('File %s was updated.' % dest)


    def update_scripts(self, src, dest):
        "Update file by values"
        values = (('MODULE_ROOT', self.with_root(self.fredappdir)), 
                  ('BASE_SHARE_DIR', self.share_dir))
        # here is not self.srcdir by casue src is path from build/scripts-#.#
        self.replace_pattern(src, dest, values)
        if self.log:
            self.log.info('File %s was updated.' % dest)


    def update_settings(self, src, dest):
        """Modify settings and copy it into final position
        This is second step of the installation of settings.
        """
        values = (('BASE_SHARE_DIR\s*=\s*(.+)', 
                   'BASE_SHARE_DIR = "%s"' % self.share_dir), 
                  ('DIR_ETC_FRED\s*=\s*(.+)', 
                   'DIR_ETC_FRED = "%s"' % self.with_root(self.fredconfdir)), 
                 )
        self.replace_pattern(src, dest, values)
        if self.log:
            self.log.info('File %s was updated.' % dest)
        
        # Remove modified settings file (named along by appname)
        # This file is created by function copy_settings() and it is necessary
        # to remove it, otherwise the file stay as an orphan after command 
        # clean
        os.unlink(src)
        if self.log:
            self.log.info('Remove tmp file %s' % src)


    def copy_settings(self, src, dest):
        """Create module settings MODULE_NAME from settings.py
        This is first step of the installation of settings.
        """
        # This is exception - the copy goes into SOURCE folder instead of DEST.
        # The copy is modified and placed into final position by function
        # update_settings() on the next step of the installation process.
        self.copy_file(src, os.path.join(os.path.dirname(src), 
                        "%s.py" % self.MODULE_NAME))


    def update_createdb(self, src, dest):
        "Update file by values"
        values = (("MANAGEPATH=\${1:-'..'}", 
                   "MANAGEPATH=${1:-'%s'}" % self.getDir('FREDAPPDIR')), 
                 )
        self.replace_pattern(src, dest, values)
        if self.log:
            self.log.info('File %s was updated.' % dest)
        if os.name == 'posix' and not self.dry_run:
            set_file_executable(dest)


    @staticmethod
    def show_after_help(commands):
        "Print individual text after default help"
        if not len(commands):
            return
        import inspect
        if inspect.isclass(commands[0]) and issubclass(commands[0], install) \
                                                    or commands[0] == "install":
            print '   or: python setup.py install --localstatedir=/var '\
               '--prefix=/usr --purelibdir=/usr/share --sysconfdir=/etc '\
               '--prepare-debian-package --root=/tmp/package'



    def run(self):
        "Run install process"
        
        # copy files
        install.run(self)

        # remove subsidiary file
        filepath = os.path.join(self.getDir_nop('DOCDIR'), 
                                    'cron.d', 'run.install')
        if os.path.isfile(filepath):
            os.unlink(filepath)

        if self.prepare_debian_package:
            self.make_preparation_for_debian_package(self.log, (
                ('MODULE_ROOT', self.fredappdir),
                ('MODULES_CONF_DIR', self.fredconfmoduledir), 
                ('APPCONFDIR', self.appconfdir), 
                ('BINDIR', self.getDir('BINDIR')), 
                ('INSTALLED_SIZE', file_util.get_folder_kb_size(self.get_root())), 
                )
            )
            return
        
        if self.SCRIPT_CREATE_DB:
            # prepare command for create database
            command = os.path.join(self.getDir('FREDAPPDIR'), self.SCRIPTS_DIR, 
                               self.SCRIPT_CREATE_DB)

            # create database
            if self.after_install:
                # copy settings into destination file
                print "Run command", command
                os.system(command) # run create-database
            else:
                print "The remaining steps to complete the installation:"
                print "(Use --after-install for make all these "\
                      "command in one step)"
                print
                print command
                
        if hasattr(self, "help_message"):
            print self.help_message

