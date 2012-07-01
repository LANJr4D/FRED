WHOIS interface v1.5.3
======================

reference implamentation at:

http://box.office.nic.cz/whois/
http://whois.office.nic.cz/


Dependencies and technologies:
---------------------------------

Python >= 2.5
Python Imaging Library (PIL) http://www.pythonware.com/products/pil/

CORBA adapter:
- omniORB >= 4.0.x
- omniorbpy >= 2.5
- idl files


WEB interface:
- mod_python >= 3.1.3 ( http://www.modpython.org/ )
- SimpleTAL >= 4.1 ( http://www.owlfish.com/software/simpleTAL/ )

#Captcha:
#http://svn.navi.cx/misc/trunk/pycaptcha/
(Obsolete. It was included under fred_whois as CaptchaWhois)


Install:
----------

$ python setup.py install --idl=PATH/TO/IDL --ior=CORBA_NAME --config=PATH/TO/CONFIG.FILE


Reference implementation expects config file in /opt/whois
Only one full path is defined at the beginning of the file "whois.py". At mentioned
folder must be found both CORBA parts (IDL files) and templates 
for WWW output (*.pt.*).

File "whois.py" copy (or symlink) to folder defined in apache configuration
(in example "/var/www/localhost/htdocs/whois"). Make symlink of the default apache 
index to this file (in case "index.html" for example: '$ ln -s whois.py index.html')
If any different extension needed, than change AddHandler directive.



Apache configuration:

    <Directory "/var/www/localhost/htdocs/whois">
	AllowOverride all
        AddHandler mod_python .py
        PythonHandler whois
	DirectoryIndex whois.py
        #PythonDebug On  # pouze pro ladici ucely
    </Directory>


# Captcha:
# 
# $ wget -r -np -nH --cut-dirs=2 http://svn.navi.cx/misc/trunk/pycaptcha/
# or
# $ svn co http://svn.navi.cx/misc/trunk/pycaptcha/
# 
# $ cd pycaptcha/
# $ sudo python setup.py install
(Obsolete. It was included under fred_whois as CaptchaWhois)


SimpleTAL:

http://www.owlfish.com/software/simpleTAL/download.html
$ tar -xf SimpleTAL-4.1.tar.gz
$ cd SimpleTAL-4.1/
$ sudo python setup.py install

Install dependencies for Ubuntu (7.10):

$ sudo apt-get install python-imaging
$ sudo apt-get install python-omniorb2
$ sudo apt-get install omniidl4-python
$ sudo apt-get install python-simpletal

