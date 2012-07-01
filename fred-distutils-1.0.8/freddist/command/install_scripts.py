import re, os, sys
from distutils.command.install_scripts import install_scripts as _install_scripts
from install_parent import install_parent
from stat import ST_MODE
from distutils.core import Command
from distutils import log

class install_scripts(_install_scripts, install_parent):

    user_options = _install_scripts.user_options + install_parent.user_options
    boolean_options = _install_scripts.boolean_options + install_parent.boolean_options

    user_options.append(('root=', None,
        'install everything relative to this alternate root directory'))
    user_options.append(('prefix=', None,
        'installation prefix'))

    def __init__(self, *attrs):
        self.compile = 0
        self.optimize = 0
        _install_scripts.__init__(self, *attrs)
        install_parent.__init__(self, *attrs)

    def initialize_options(self):
        self.prefix = None
        self.root = None
        self.record = None
        _install_scripts.initialize_options(self)
        install_parent.initialize_options(self)

    def finalize_options(self):
        _install_scripts.finalize_options(self)
        if 'install' in sys.argv:
            self.set_undefined_options('install', *[(k, k) for k in self.UNDEFINED_OPTIONS])
        else:
            install_parent.finalize_options(self)
        if not self.record and not self.no_record:
            self.record = 'install.log'
        self.srcdir = self.distribution.srcdir
        self.rundir = self.distribution.rundir
        # necessary for function get_outputs()
        self.outfiles = []


    def run(self):
        self.install_dir = self.getDir_nop('bindir')

        if not self.no_pycpyo:
            files = os.listdir(self.build_dir)
            for file in files:
                #file = os.path.join(self.build_dir, file)
                if file.endswith('.py') and self.compile == 1:
                    os.system('python -c "import py_compile; \
                            py_compile.compile(\'%s\')"' % os.path.join(self.build_dir, file))
                    print "creating compiled %s" % file + 'c'
                if file.endswith('.py') and self.optimize == 1:
                    os.system('python -O -c "import py_compile; \
                            py_compile.compile(\'%s\')"' % os.path.join(self.build_dir, file))
                    print "creating optimized %s" % file + 'o'
        if not self.skip_build:
            self.run_command('build_scripts')

        if not self.include_scripts:
            log.info("Skip install scripts. For install scripts set option: " \
                     "--include-scripts")
            return

        _install_scripts.run(self)
        
        # modify scripts if it is necessary
        for filepath in self.outfiles:
            self.modify_file("install_scripts", os.path.join(self.build_dir, 
                        os.path.basename(filepath)), os.path.dirname(filepath))
