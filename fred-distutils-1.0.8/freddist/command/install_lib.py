import re, os, sys
from distutils.command.install_lib import install_lib as _install_lib
from install_parent import install_parent

class install_lib(_install_lib, install_parent):

    user_options = _install_lib.user_options + install_parent.user_options
    boolean_options = _install_lib.boolean_options + install_parent.boolean_options

    user_options.append(('root=', None,
        'install everything relative to this alternate root directory'))
    user_options.append(('prefix=', None,
        'installation prefix'))

    def __init__(self, *attrs):
        _install_lib.__init__(self, *attrs)
        install_parent.__init__(self, *attrs)

    def initialize_options(self):
        self.root = None
        self.prefix = None
        self.record = None
        _install_lib.initialize_options(self)
        install_parent.initialize_options(self)

    def finalize_options(self):
        _install_lib.finalize_options(self)
        if 'install' in sys.argv:
            self.set_undefined_options('install', *[(k, k) for k in self.UNDEFINED_OPTIONS])
        else:
            install_parent.finalize_options(self)
        self.set_directories(self.prefix)
        if not self.record and not self.no_record:
            self.record = 'install.log'
        self.srcdir = self.distribution.srcdir
        self.rundir = self.distribution.rundir

    def run(self):
        self.install_dir = self.getDir_nop('purelibdir')
        _install_lib.run(self)
