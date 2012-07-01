"""distutils.util

Miscellaneous utility functions -- anything that doesn't fit into
one of the other *util.py modules.
"""
import sys
import os
import codecs

from distutils import log
try:
    # distutils version 2.6.5
    from distutils.errors import DistutilsByteCompileError
except ImportError:
    # distutils version 2.5.1
    from distutils.errors import CompileError as DistutilsByteCompileError



def pomo_compile(files):
    "Compile .po files with gettext translations into .mo"
    # nothing is done if sys.dont_write_bytecode is True
    if hasattr(sys, "dont_write_bytecode") and sys.dont_write_bytecode:
        raise DistutilsByteCompileError('byte-compiling is disabled.')

    for filename in files:
        if not filename.endswith('.po'):
            continue

        log.info("processing file '%s'", filename)
        if has_bom(filename):
            raise DistutilsByteCompileError("The %s file has a BOM (Byte Order Mark). "
                    "Freddistutils only supports .po files encoded in UTF-8 and without any BOM." % filename)

        pathfile = os.path.splitext(filename)[0]
        os.environ['freddistmo'] = pathfile + '.mo'
        os.environ['freddistpo'] = pathfile + '.po'
        if sys.platform == 'win32': # Different shell-variable syntax
            cmd = 'msgfmt --check-format -o "%freddistmo%" "%freddistpo%"'
        else:
            cmd = 'msgfmt --check-format -o "$freddistmo" "$freddistpo"'
        os.system(cmd)


def has_bom(filepath):
    "Check if file has BOM (Byte Order Mark) at the beginning."
    fph = open(filepath, 'r')
    sample = fph.read(4)
    return sample[:3] == '\xef\xbb\xbf' or \
            sample.startswith(codecs.BOM_UTF16_LE) or \
            sample.startswith(codecs.BOM_UTF16_BE)
