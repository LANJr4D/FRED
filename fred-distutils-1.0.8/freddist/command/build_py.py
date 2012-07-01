import sys
import string, os, re
#from types import StringType
from distutils.command.build_py import build_py as _build_py


class build_py(_build_py):
    def finalize_options(self):
        self.srcdir = self.distribution.srcdir
        _build_py.finalize_options(self)

    def get_package_dir(self, package):
        """
        Return the directory, relative to the top of the source
        distribution, where package 'package' should be found
        (at least according to the 'package_dir' option, if any).
        Standart distutils build_py does not support scrdir option.
        So Build_py class implements this funkcionality. This code
        is from http://lists.mysql.com/ndb-connectors/617 
        """
        path = string.split(package, '.')

        if not self.package_dir:
            if path:
                #FREDDIST line changed
                return os.path.join(self.srcdir, apply(os.path.join, path))
            else:
                #FREDDIST line changed
                return self.srcdir
        else:
            tail = []
            while path:
                try:
                    pdir = self.package_dir[string.join(path, '.')]
                except KeyError:
                    tail.insert(0, path[-1])
                    del path[-1]
                else:
                    tail.insert(0, pdir)
                    #FREDIST line changed
                    return os.path.join(self.srcdir, apply(os.path.join, tail))
            else:
                # Oops, got all the way through 'path' without finding a
                # match in package_dir.  If package_dir defines a directory
                # for the root (nameless) package, then fallback on it;
                # otherwise, we might as well have not consulted
                # package_dir at all, as we just use the directory implied
                # by 'tail' (which should be the same as the original value
                # of 'path' at this point).
                pdir = self.package_dir.get('')
                if pdir is not None:
                    tail.insert(0, pdir)

                if tail:
                    #FREDDIST line changed
                    return os.path.join(self.srcdir, apply(os.path.join, tail))
                else:
                    #FREDDIST line changed
                    return self.srcdir
    #get_package_dir()


    def modify_file(self, command, filename, targetpath):
        "Modify file if any function is defined."
        if not hasattr(self.distribution, "modify_files"):
            return
        
        # modify_files: {"command": 
        #                 (("module.function", ("filename", ...)), ...), ...}
        for mfncname, files in self.distribution.modify_files.get(command, []):
            modulename, fncname = mfncname.split(".")
            moduleobj = self.distribution.command_obj.get(modulename)
            if not moduleobj:
                continue
            fnc = getattr(moduleobj, fncname)
            for name in files:
                if re.search("%s$" % name, filename):
                    # modify file by fnc(SRC, DEST) from SRC to DEST
                    fnc(filename, os.path.join(targetpath, name))


    def build_module (self, module, module_file, package):
        "Extend build_module by modification files"
        # do original function
        retval = _build_py.build_module(self, module, module_file, package)
        #if type(package) is StringType:
        if isinstance(package, str):
            package = string.split(package, '.')
        outfile = self.get_module_outfile(self.build_lib, package, module)
        # extend by modify file if is defined
        self.modify_file("build_py", module_file, os.path.dirname(outfile))
        return retval


    def build_package_data (self):
        """Copy data files into build directory"""
        lastdir = None
        for package, src_dir, build_dir, filenames in self.data_files:
            for filename in filenames:
                source = os.path.join(src_dir, filename)
                target = os.path.join(build_dir, filename)
                self.mkpath(os.path.dirname(target))
                self.copy_file(source, target, preserve_mode=False)
                self.modify_file("build_py", source, os.path.dirname(target))

    def byte_compile (self, files):
        "Compile files *.py and *.po"
        if hasattr(sys, "dont_write_bytecode") and sys.dont_write_bytecode:
            self.warn('byte-compiling is disabled, skipping.')
            return

        _build_py.byte_compile(self, files)

        if 'no_mo' not in self.distribution.get_option_dict('install'):
            from freddist.util import pomo_compile
            pomo_compile(files)


    def run(self):
        _build_py.run(self)

