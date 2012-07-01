#!/usr/bin/python
# -*- coding: utf-8 -*-
"Support of dobradomena.cz"
import os


def get_good_domain_list(files_root, langcode):
    "Join dictionnatry with good domains links"
    goodomain = {}
    language = langcode[:2]
    
    # must correspond with _get_fs_path_and_mime() 
    # at nicms/apps/cms/views/dobradomena.py
    docname = 'manual.pdf'
    hostname = 'dobradomena.cz' # TEST: 'dobradomena.cz:8001'
    
    for registrar_name in os.listdir(files_root):
        if registrar_name == 'www':
            continue # skip default
        
        fs_path = os.path.join(files_root, registrar_name, language, docname)
        if os.access(fs_path, os.R_OK):
            # http://REGHANDLE.dobradomena.cz:8001/dobradomena/manual.pdf
            goodomain[registrar_name] = {'href': "http://%s.%s/dobradomena/%s" 
                                         % (registrar_name, hostname, docname)}
    
#    # TEST ONLY:
#    for registrar_name in ('fred_a', 'fred_b', 'ignum'):
#        goodomain[registrar_name] = {'href': "http://%s.%s/dobradomena/%s" 
#                                     % (registrar_name, hostname, docname)}
    
    return goodomain
