#!/usr/bin/python

"""
Usage:
    sudo python setup.py install
"""

import sys, os, re

from freddist.core import setup
from freddist.command.install import install
from freddist.command.install_scripts import install_scripts
from freddist.file_util import *
from distutils.sysconfig import get_python_lib

PROJECT_NAME = 'fred-doc2pdf'
PACKAGE_NAME = 'fred-doc2pdf'

CONFIG_FILENAME = 'fred-doc2pdf.conf'
CONFIG_SECTION = 'main'
CONFIG_OPTIONS = ('trml_module_name', 'true_type_path', 'default_font_ttf', 'module_path')

# ----------------------------------------
# Here you can configure config variables:
# ----------------------------------------

# Name of the reportlab module
MODULE_REPORTLAB = 'reportlab'

# Names of the TRML modules
MODULES_TINYRML = ('trml2pdf', 'rml2pdf')
TINYERP_PATH = 'tinyerp-server/report/render'

# Folder where setup looks for font
FONT_ROOT = '/usr/share/fonts'

# Folder names where process looking for fonts
PREFERRED_FONT_FOLDERS = ('freefont', 'truetype', 'freefont-ttf', "dejavu")

# Font names which process looking for
PREFERRED_FONT_NAMES = ('FreeSans', 'FreeSerif', 'FreeMono', 
        'DejaVuSans', 'DejaVuSerif',
        'Helvetica', 'Arial', 'Times', 'Times-Roman', 'Times-New-Roman')

# ----------------------------------------


def try_import(modulename):
    """Check if exists module named `modulename'"""
    try:
        exec('import %s' % modulename)
    except ImportError, msg:
        sys.stderr.write('ImportError: %s\n' % msg)
        return False
    else:
        sys.stdout.write('Module %s was found.\n' % modulename)
    return True

def check_reportlab():
    """Check if `reportlab' module exists"""
    if not try_import(MODULE_REPORTLAB):
        sys.stderr.write('Module `python-reportlab\' not found, you will need to install it.\n')
        return False, MODULE_REPORTLAB

    exec('import %s' % MODULE_REPORTLAB)
    try:
        version = eval('%s.Version' % MODULE_REPORTLAB)
        fVersion = float(version)
    except AttributeError, msg:
        sys.stderr.write('AttributeError: %s\n' % msg)
    except ValueError, msg:
        sys.stderr.write('ValueError: %s\n' % msg)
    else:
        if fVersion < 2.0:
            sys.stderr.write('Error: Module %s version %s is lower than minimum 2.0.\n' % (MODULE_REPORTLAB, version))
            return False, MODULE_REPORTLAB
        else:
            sys.stdout.write('Checked %s version: %s\n' % (MODULE_REPORTLAB, version))
    return True, MODULE_REPORTLAB

def check_trml2pdf():
    """Check Tiny RML templating module"""

    #try to find it in standard module path
    for modulename in MODULES_TINYRML:
        if try_import(modulename):
            return True, modulename, ''

    path = os.path.join(get_python_lib(), TINYERP_PATH)
    sys.path.insert(0, path)

    #try again with explicit path
    for modulename in MODULES_TINYRML:
        if try_import(modulename):
            return True, modulename, path
    sys.path.pop(0)

    path = os.path.join('/usr/lib', TINYERP_PATH)
    sys.path.insert(0, path)

    #try again with another explicit path
    for modulename in MODULES_TINYRML:
        if try_import(modulename):
            return True, modulename, path
    sys.path.pop(0)

    sys.stderr.write('Module `TinyERP\' not found, you will need to install it.\n')
    return False, '', ''

def get_popen_result(command):
    """Returns result from shell command find"""
    status = True
    data = ''
    try:
        pipes = os.popen3(command)
    except IOError, msg:
        sys.stderr.write('IOError: %s\n'%msg)
        status = False
    else:
        data = pipes[1].read()
        errors = pipes[2].read()
        map(lambda f: f.close(), pipes)
        if errors:
            sys.stderr.write('PipeError: %s\n'%errors)
            status = False
    return status, data

def find_font_folders():
    """Returs list of folders"""

    sys.stdout.write("Looking for folders '%s'...\n"%"', '".join(PREFERRED_FONT_FOLDERS))
    cmd = 'find %s -type d%s'%(FONT_ROOT, ' -or'.join(map(lambda s: ' -iname %s'%s, PREFERRED_FONT_FOLDERS)))
    # sys.stdout.write('$ %s\n'%cmd) info about shell command
    status, data = get_popen_result(cmd)
    data = data.strip()

    # list of path with font folders:
    font_folders = re.split('\s+', data)
    print 'Found %d folder(s).'%len(font_folders)
    return status, font_folders

def join_font_types(plain, fontnames):
    """
    Chceck if name has all types: plain, obligue, bold, bold-obligue.
    If is it true, returns string with this names.
    """
    font_family = ''
    font_name, ext = plain.split('.')
    
    obligue, bold, bold_obligue = ['']*3
    
    for name in fontnames:
        if re.match('%s-?(Oblique|Italics?).ttf'%font_name, name, re.I):
            obligue = name
        if re.match('%s-?Bold.ttf'%font_name, name,  re.I):
            bold = name
        if re.match('%s-?Bold-?(Oblique|Italics?).ttf'%font_name, name, re.I):
            bold_obligue = name
    
    if obligue and bold and bold_obligue:
        font_family = ' '.join((plain,  obligue,  bold,  bold_obligue))
        sys.stdout.write("Found font family '%s'\n"%plain)
    
    return font_family

def find_font_family(font_folders):
    'Returns status,  path to the font,  font family names (4 names)'
    status = False
    font_folder_name, font_family = '', ''
    font_filenames = map(lambda s: '%s.ttf'%s, PREFERRED_FONT_NAMES)
    
    for folder_name in font_folders:
        command = "find %s -name '*.ttf'"%folder_name
        stat, data = get_popen_result(command)
        if not stat:
            continue
        
        # keep paths and names of fonts separately:
        font_paths = []
        font_names = []
        for p in re.split('\s+', data.strip()):
            font_paths.append(os.path.dirname(p))
            font_names.append(os.path.basename(p))
        
        print "Found %d fonts in folder '%s'."%(len(font_names), folder_name)
        # find font family
        # looking for fonty types (4 types = one family)
        for font_type in font_filenames:
            if font_type in font_names:
                font_family = join_font_types(font_type, font_names)
                if font_family:
                    status = True
                    font_folder_name = font_paths[font_names.index(font_type)]
                    break
    if not status:
        sys.stderr.write('Error: Suitable font was not found.\n')
        sys.stderr.write('Try install: sudo apt-get intall ttf-freefont\n')
    return status, font_folder_name, font_family

def find_font_path_and_family():
    """Find truetype fonts"""
    status, font_path, font_names = False, '', ''
    font_names = []
    status, font_folders = find_font_folders()
    if status and len(font_folders):
        status, font_path, font_names = find_font_family(font_folders)
    else:
        status = False
    return status, font_path, font_names

class Install(install):
    description = "Install fred2pdf"

    user_options = install.user_options
    user_options.append(('trml-name=', None,
        'name of trml module'))
    user_options.append(('trml-path=', None,
        'path to trml module'))
    user_options.append(('font-names=', None,
        'default names for true-type fonts'))
    user_options.append(('font-path=', None,
        'path to true-type fonts'))

    def initialize_options(self):
        install.initialize_options(self)
        self.trml_name = None
        self.trml_path = None
        self.font_names = None
        self.font_path  = None

    def finalize_options(self):
        install.finalize_options(self)
# 
    def update_fred2pdf_config(self):
        values = []
        status = True

        if self.no_check_deps:
            if not self.trml_name:
                self.trml_name = 'rml2pdf'
            if not self.trml_path:
                self.trml_path = '/usr/lib/tinyerp-server/report/render'
            if not self.font_names:
                self.font_names = 'FreeSans.ttf FreeSansOblique.ttf FreeSansBold.ttf FreeSansBoldOblique.ttf'
            if not self.font_path:
                self.font_path = '/usr/share/fonts/truetype/freefont'

            trml_name = self.trml_name
            trml_path = self.trml_path
            font_path = self.font_path
            font_family = self.font_names
        else:
            stat1, trml_name, trml_path = check_trml2pdf()
            stat2, font_path, font_family = find_font_path_and_family()
            if not stat1 or not stat2:
                sys.stdout.write('Some problems occured.\nClear them out and try again.\n')
                return False

        values.append(('TRML_MODULE_NAME', trml_name))
        values.append(('MODULE_PATH', trml_path))
        values.append(('TRUE_TYPE_PATH', font_path))
        values.append(('DEFAULT_FONT_TTF', font_family))

        if not os.path.isdir('build'):
            # create `build' directory if needed
            os.makedirs('build')

        self.replace_pattern(
                os.path.join(self.srcdir, 'conf', CONFIG_FILENAME + '.install'),
                os.path.join('build', CONFIG_FILENAME),
                values)
        print "Configuration file %s has been updated" % CONFIG_FILENAME
        return True

    def run(self):
        self.update_fred2pdf_config()
        return install.run(self)
# class Install

class Install_scripts(install_scripts):
    def update_fred_doc2pdf_script(self):
        values = []
        values.append((r'(CONFIG_FILENAME = )\'[\w/_ \-\.]*\'',
            r"\1'%s'" % os.path.join(self.getDir('sysconfdir'), 'fred', CONFIG_FILENAME)))

        self.replace_pattern(
                os.path.join(self.build_dir, PACKAGE_NAME), None, values)
        print "Script file %s has been updated" % PACKAGE_NAME

    def run(self):
        self.update_fred_doc2pdf_script()
        return install_scripts.run(self)

def main(directory):
    try:
        setup(name=PROJECT_NAME,
                description='PDF creator module',
                author='Zdenek Bohm, CZ.NIC',
                author_email='zdenek.bohm@nic.cz',
                url='http://fred.nic.cz',
                license='GNU GPL',
                long_description='The module of the FRED system',
                cmdclass={
                    'install':Install,
                    'install_scripts':Install_scripts},
                scripts=[
                    PACKAGE_NAME],
                data_files=[
                    ('SYSCONFDIR/fred/', [
                        os.path.join('build', CONFIG_FILENAME)]),
                ]
                + all_files_in_4(
                    os.path.join('DATAROOTDIR', PACKAGE_NAME, 'templates'),
                    os.path.join(directory, 'templates'))
                ,
        )
        return True
    except Exception, e:
        sys.stderr.write("Error: %s\n" % e)
        return False

if __name__=='__main__':
    dir = ''
    if 'bdist' in sys.argv:
        dir = ''
    else:
        dir = os.path.dirname(sys.argv[0])
    if main(dir):
        print "All done!"
