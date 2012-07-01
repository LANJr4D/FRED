#!/usr/bin/python
# -*- coding: utf-8 -*-
import os, sys
import subprocess
from distutils.core import Command
# freddist
from freddist.command.install_parent import install_parent


# name of package release
UBUNTU_NAME = 'jaunty'


class bdist_deb (Command):

    description = "create a Debian distribution"

    user_options = [
        ('bdist-base=', None, "base directory for creating build"),
        ('epoch=', None, "Program epoch [0]"),
        ('package-version=', None, "Package version [1]"),
        ('release=', None, "Debian release [%s]" % UBUNTU_NAME),
        ('build-int=', None, "Package build int [1]"),
        ('platform=', None, "OS platform [all]"),
        ('install-extra-opts=', 'i', 'extra option(s) passed to install command'), 
    ]
    
    
    def initialize_options (self):
        self.bdist_base = None
        self.epoch = None
        self.package_version = None
        self.release = None
        self.build_int = None
        self.platform = None
        self.fred_distutils_dir = None
        self.install_extra_opts = None


    def finalize_options (self):
        if not self.bdist_base:
            self.bdist_base = 'deb'
        elif self.bdist_base == "build":
            raise SystemExit("Error --bdist-base: Folder name 'build' is " \
                             "reserved for building process.")
        
        # epoch zero is shown empty string "" otherwice "NUMBER:"
        if not self.epoch:
            self.epoch = ''
        else:
            self.epoch = '%s:' % self.epoch
        if not self.package_version:
            self.package_version = '1'
        if not self.release:
            self.release = UBUNTU_NAME
        if not self.build_int:
            self.build_int = '1'
        if not self.platform:
            self.platform = 'all' # architecture
        
        # it is necessary overwrite extra-opts if the command 'bdist' is set
        if self.distribution.command_options.has_key('bdist'):
            bdist_val = self.distribution.command_options['bdist']
            if bdist_val.has_key('install_extra_opts'):
                self.install_extra_opts = bdist_val['install_extra_opts'][1]   


    def run (self):
        # check if exists tool for create deb package
        if os.popen("which dpkg-deb").read() == "":
            raise SystemExit, "Error: dpkg-deb missing. "\
                              "It is required for create deb."
        
        # check debian/control
        controlpath = os.path.join(self.distribution.srcdir, 
                                   "doc", "debian", "control")
        if not os.path.isfile(controlpath):
            raise SystemExit, "Error: %s missing." % controlpath
        
        # options --no-compile --no-pycpyo --preservepath --no-check-deps are
        # set automaticly by --prepare-debian-package
        # other options must be set in setup.cfg
        ex = "" if self.install_extra_opts is None else self.install_extra_opts
        command = "python %s/setup.py install %s --prepare-debian-package "\
                  "--root=%s" % (self.distribution.srcdir, ex, self.bdist_base)
        print "running command:", command
        if not do_command(command):
            return

        # prepare package name and find paths
        version = "%s%s-%s~%s+%s" % (self.epoch, 
                self.distribution.get_version(), self.package_version, 
                self.release, self.build_int)
        deb_name = "%s_%s_%s" % (self.distribution.get_name(), version, 
                                 self.platform)
        build_dir = os.path.abspath(self.bdist_base)
        current_dir = os.getcwd()

        # modify control file
        path = os.path.join(build_dir, "DEBIAN", "control")
        command_obj = install_parent()
        command_obj.replace_pattern(path, path, 
                (("PACKAGE_VERSION", version), ("PLATFORM", self.platform)))
        
        for command in (
            'cd %s; find * -type f | grep -v "^DEBIAN/" | while read x;'\
                        'do md5sum "${x}";done > DEBIAN/md5sums' % build_dir, 
            'cd %s' % current_dir, 
            'dpkg-deb -b %s %s.deb' % (build_dir, deb_name), 
            ):
            print "running command:", command
            if not do_command(command):
                break


def do_command(command):
    "Run any command in subprocess"
    p = subprocess.Popen(command, shell=True, stderr=subprocess.PIPE)
    error = p.stderr.read()
    if error:
        print >> sys.stderr, error
        return False
    return True
