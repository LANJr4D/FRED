#!/usr/bin/python
# -*- coding: utf-8 -*-

# TODO:
# - cleanup of code, exception handling, you name it...
# - REWRITE IT ALL

#
# Version: (see PACKAGE_VERSION in setup.py)
#

# path to config file will be change by setup.py
import os
config = os.environ.get('WHOIS_CONFIG_FILE' , '/usr/local/etc/fred/whois.conf')

# dobradomena folder path (e.g. '/home/glin/1/dobradomena/files/')
DOBRADOMENA_DIR = "/" #None

debug = False

import sys
import cgi
import time
import types
import urllib
import urllib2
import urlparse
import random
import gettext
import ConfigParser
import re
import os.path
import datetime

try:
    import cStringIO as StringIO
except ImportError:
    import StringIO

# support of dobradomena.cz
from dobradomena import get_good_domain_list

from simpletal import simpleTAL, simpleTALES

# turn off debug for simpletal
import logging
simpletal_logger = logging.getLogger('simpleTAL')
simpletal_logger.setLevel(logging.WARNING)

try:
    from mod_python import apache, util, Session
except ImportError:
    apache = None
    if debug: print "No apache support, assuming console operations"

from captcha import NicGimpy, PersistentFactory

class WhoisException(Exception):
    pass
class WhoisRequestBlocked(WhoisException):
    pass
class WhoisInvalidIdentifier(WhoisException):
    pass

conf = ConfigParser.ConfigParser()
conf.read(config)

import ccregproxy

# service codes dependent on the database table service:
LC_WEB_WHOIS = 1
LC_PUBLIC_REQUEST = 2

# action type code from database table request_type: 
WhoisRequestType = {'Info':1104}

#map between internal action names and logger DB table
PubReqRequestType = { 'authinfo' : 1600,
                      'block_transfer' : 1601,
                      'block_changes' : 1602,
                      'unblock_transfer' : 1603,
                      'unblock_changes' : 1604}

UnknownAction = 1000


langs = {'cs': 'cs_CZ', 'cz': 'cs_CZ', 'en': 'en_US'}
lang_keys = {'cs_CZ':'CS', 'en_US':'EN'}
DEFAULT_LANG = 'en'
ENCODING = 'utf-8'
CAPTCHA_SIZE = (300, 96)

common = {'private': 'Private entry',
    'who_is_disclaimer': {'url':'#', 'text':'Disclaimer'},
    # How to become a registrar
    'become_registrar': {'url':'/en/page/66/jak-se-stat-registratorem.html', 'text':'here'},
          }
title = "CZ.NIC"


def get_extra_content_processor():
    "Load python code directly from config"
    section, option = 'extra_content_processor', 'line'
    if not conf.has_section(section):
        return None
    code, pos = [], 1
    is_indented = re.compile('\.+')
    while conf.has_option(section, '%s%d' % (option, pos)):
        line = conf.get(section, '%s%d' % (option, pos))
        match = is_indented.match(line)
        if match:
            # replace leading dots by space
            indent = len(match.group(0))
            line = ' ' * indent + line[indent:]
        code.append(line)
        pos += 1
    return "\n".join(code)

EXTRA_CONTENT_PROCESSOR = get_extra_content_processor()


# for debugign only
LOG_FILE = None # '/tmp/whois.log'
def log_message(*msg):
    'Log messages during mod_apache session'
    if LOG_FILE is None:
        return
    try:
        open(LOG_FILE, 'a').write('%s\n' % ' '.join(map(str, msg)))
    except IOError, e:
        pass


def localtime(t, short=False):
    # tries to reconstruct time string from one of possible CORBA backend returns 
    try:
        if len(t) == 10:
            ret = time.strftime('%d.%m.%Y', time.strptime(t, '%Y-%m-%d'))
        elif len(t) == 23:
            ret = time.strftime('%d.%m.%Y', time.strptime(t[:19], '%Y-%m-%dT%H:%M:%S'))
        elif len(t) == 25:
            ret = time.strftime('%d.%m.%Y', time.strptime(t[:19], '%Y-%m-%dT%H:%M:%S'))
        else:
            ret = t
    except ValueError:
        ret = t
    except:
        ret = ""
    if short:
        return ret[:10]
    else:
        return ret

def currentDate():
    return time.strftime('%d.%m.%Y')

def date2iso(date):
    """Convert date from local format (e.g. '28. 9. 2011')
    into ISO 8601 ('2011-09-28').
    """
    match = re.match("(\d{1,2}).\s*(\d{1,2}).\s*(\d{4})", date)
    if match:
        return "%s-%#02d-%#02d" % (match.group(3), int(match.group(2)), int(match.group(1)))
    return date # let others unchanged


def rehashHandles(handles, qhandle=None):
    if handles is None:
        return []

    if qhandle and type(qhandle) in types.StringTypes:
        try:
            qhandle = qhandle.decode(ENCODING)
        except:
            pass
    handleMap = {'HT_DOMAIN': 'DOMAIN',
            'HT_ENUM_NUMBER': 'ENUM_NUMBER',
            'HT_ENUM_DOMAIN': 'ENUM_DOMAIN',
            'HT_CONTACT': 'CONTACT',
            'HT_NSSET': 'NSSET',
            'HT_KEYSET': 'KEYSET',
            'HT_REGISTRAR': 'REGISTRAR',
            'HT_OTHER': 'OTHER'}
    queryMap = {'HT_DOMAIN': 'd',
            'HT_ENUM_NUMBER': 'e',
            'HT_ENUM_DOMAIN': 'e',
            'HT_CONTACT': 'c',
            'HT_NSSET': 'n',
            'HT_KEYSET': 'k',
            'HT_REGISTRAR': 'r',
            'HT_OTHER': 'q'}
    functionMap = {'HT_DOMAIN': 'domain',
            'HT_ENUM_NUMBER': 'enum',
            'HT_ENUM_DOMAIN': 'enum',
            'HT_CONTACT': 'contact',
            'HT_NSSET': 'nsset',
            'HT_KEYSET': 'keyset',
            'HT_REGISTRAR': 'registrar',
            'HT_OTHER': 'invalid'}
    classMap = {'CH_UNREGISTRABLE': 'UNREGISTRABLE',
            'CH_UNREGISTRABLE_LONG': 'UNREGISTRABLE_LONG',
            'CH_REGISTRED': 'REGISTRED',
            'CH_REGISTRED_PARENT': 'REGISTRED_PARENT',
            'CH_REGISTRED_CHILD': 'REGISTRED_CHILD',
            'CH_PROTECTED': 'PROTECTED',
            'CH_FREE': 'FREE'}
    handles = [ {'resultHandleClass': classMap.get(handle['handleClass']),
                 'resultHandleAttribute': queryMap.get(handle['hType']),
                 'resultHandleFunction': functionMap.get(handle['hType']),
                 'queryHandleType': None,
                 'resultHandleType': handleMap.get(handle['hType']),
                 'resultConflictHandle': handle['conflictHandle'],
                 'queryTranslatedHandle': handle['newHandle'],
                 'queryHandle': qhandle,
                 'resultHandle': handle['newHandle']} for handle in handles ]
    # set resultHandle to resultConflictHandle if conflict exists
    [ handle.__setitem__('resultHandle', handle['resultConflictHandle']) for handle in handles \
        if handle['resultConflictHandle'] ]
    # set unregistrable handles to show "invalid" in resultHandleFunction
    [ handle.__setitem__('resultHandleFunction', 'invalid') for handle in handles \
        if handle['resultHandleClass'] in ['UNREGISTRABLE', 'UNREGISTRABLE_LONG'] ]
    # set 'free' and 'child' enum handles to show "registrars" in resultHandleFunction
    [ handle.__setitem__('resultHandleFunction', 'registrars') for handle in handles \
        if (handle['resultHandleClass'] in ['FREE', 'REGISTRED_CHILD'] \
            and handle['resultHandleFunction'] == 'enum') ]
    return handles


def get_valid_app_type(apptype):
    'Get only valid app type.'
    if not apptype in ('enum', 'whois'):
        apptype = 'whois' # default
    return apptype


class Contact:
    ssnType = {
        'EMPTY':    ' ',
        'RC':       'Birth date',
        'OP':       'Personal ID',
        'PASSPORT': 'Passport number',
        'ICO':      'ID number',
        'MPSV':     'MPSV ID',
        'BIRTHDAY': 'Birth day',
        'UNKNOWN':  'Unspecified type',
        }


class Domain:
    status_ok = 'Paid and in zone'


class KeySet:

    # http://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers.xml
    keyset_alg = {
        0: 'Reserved',
        1: 'RSA/MD5',
        2: 'Diffie-Hellman',
        3: 'DSA/SHA-1',
        4: 'Elliptic Curve',
        5: 'RSA/SHA-1',
        6: 'DSA-NSEC3-SHA1',
        7: 'RSASHA1-NSEC3-SHA1',
        8: 'RSA/SHA-256',
        9: 'Unassigned',
       10: 'RSA/SHA-512',
       11: 'Unassigned',
       12: 'GOST R 34.10-2001',
    }

    keyset_digest_type = {
        1: 'SHA-1',
    }

    keyset_dnskey_alg = keyset_alg.copy()
    keyset_dnskey_alg.update({
        252: 'Indirect',
        253: 'Private-DNS',
        254: 'Private-OID',
    })

    break_char = '<br />\n'
    n_break_chars = 40



class Whois(object):

    SERVER_NAME, INTERPRETER, UNPARSED_URI, PARSED_URI, URI = range(5)
    #(mp_request)PARSED_URI: (scheme, host:port, None, None, host, port, path, query, fragment)

    def __init__(self, req=None, session=None, group_id=None):
        """
        req is tuple: (SERVER_NAME, INTERPRETER, UNPARSED_URI, PARSED_URI(9), URI)
        session can be type:
        mod_python.Session.DbmSession / django.contrib.sessions.middleware.SessionWrapper
        """
        object.__init__(self)
        self.request = req
        self.apptype = get_valid_app_type(conf.get('app', 'type'))
        self.needcaptcha = conf.get('app', 'captcha') in ('True', 'true', '1') and True or None
        self.templatetype = conf.get('templates', 'location')
        self.hideContentMenu = 0
        self.factory = None
        self.DOBRADOMENA_DIR = DOBRADOMENA_DIR
        self.group_id = group_id
        self.dbId = None

        # set language version
        if session:
            _lang = session.get('lang', DEFAULT_LANG)
        else:
            _lang = DEFAULT_LANG
        if not _lang in langs:
            _lang = _lang.split('-')[0]
            if not _lang in langs:
                _lang = DEFAULT_LANG
        self.lang = langs[_lang]

        self.session = session
        self.langswitch = "/whois/?lang=%s"
        gt = gettext.translation(conf.get('gettext', 'domain'), conf.get('gettext', 'localedir'), languages=[self.lang])
        self.translate = gt.gettext
        self.u_translate = gt.ugettext
        self.common = {}
        # translating common strings
        for key, value in common.items():
            self.common.__setitem__(key, type(value) is str and self.translate(value).decode(ENCODING) or value)
        self.admin = ccregproxy.Admin(
                ior='corbaname::' + conf.get('corba', 'host'),
                idl=conf.get('corba', 'idl'),
                context=conf.get('corba', 'context'))

    def disable_captcha_for_remote_addr(self, remote_addr, blacklist_dir=None, always_captcha_paths=None, current_path=None):
        'Disable captcha for IP address defined in the config file.'

        if conf.has_option('app', 'omit_ip') and remote_addr:
            for pattern in re.split('\s+', conf.get('app', 'omit_ip')):
                if re.match(pattern, remote_addr):
                    self.needcaptcha = False
                    break

        # Not disabling captcha for urls, that statrs with one of always_captcha_paths
        if always_captcha_paths is not None and current_path is not None:
            for always_captcha_path in always_captcha_paths:
                if current_path.startswith(always_captcha_path):
                    return
        if blacklist_dir is not None and not os.path.exists(os.path.join(blacklist_dir, remote_addr)):
            self.needcaptcha = False
            return


    def set_template_to_inset(self, apptype, pages={}):
        """Init defaults for display as inset.
        apptype is type of the application (enum,whois)
        pages are list of page links: { page_key: {url:url, text: text}, ... }
        """
        # render only a part of the values (no whole page)
        self.templatetype = 'inset'
        # django generate its own content menu
        self.hideContentMenu = 1
        self.apptype = get_valid_app_type(apptype)
        # register pages ID from django settings
        for key, value in pages.items():
            self.common[key] = value



##############################################

    def getStatusList(self, result, function_type, status_name_type='name'):
        'Get status if object needs'
        if status_name_type not in ['name', 'shortName']:
            status_name_type = 'name'
        # join status, if necessary
        retval = []
        try:
            size = len(result['statusList'])
        except (KeyError, TypeError):
            size = 0 # no list 'statusList' in answer

        if size == 0:
            if function_type == 'Domain':
                retval.append(self.u_translate(Domain.status_ok))
            return retval # no status

        data = getattr(self.admin, 'get%sStatusDescList' % function_type)(lang_keys[self.lang])
        if data:
            for item in data:
                if item['id'] in result['statusList']:
                    retval.append(item[status_name_type])
        return retval

    def get_keyset_alg_label(self, alg):
        return self.u_translate(KeySet.keyset_alg.get(alg, 'unknown'))

    def get_keyset_digest_type_label(self, type):
        return self.u_translate(KeySet.keyset_digest_type.get(type, 'unknown'))

    def get_keyset_dnskey_alg_label(self, alg):
        return self.u_translate(KeySet.keyset_dnskey_alg.get(alg, 'unknown'))

    def get_keyset_dnskey_formated(self, key, separator=KeySet.break_char):
        splitted = [key[KeySet.n_break_chars * i:KeySet.n_break_chars * (i + 1)] for i in range(len(key) / KeySet.n_break_chars + 1)]
        return separator.join(splitted)

    def query_domain(self, *params, **kw):
        handle = kw.get('handle')
        handles = kw.get('handles', {})
        d = self.admin.deepDomainInfo(handle, handles)
        result = {'qtype': 'notfound', 'apptype': self.apptype,
                  'query': {'queryHandle':handle} }
        if d:
            result['qtype'] = 'domain'
            replace_contacts_names_by_org(d)
            result['domain'] = d
            if d['nsset']:
                result['nsset'] = d['nsset'] # XXX hack for nsset macro
                result['nsset']['status_names'] = self.getStatusList(d['nsset'], 'NSSet')
            if d['keyset']:
                result['keyset'] = d['keyset'] # XXX hack for keyset macro
                result['keyset']['status_names'] = self.getStatusList(d['keyset'], 'KeySet')
                for dsrecord in result['keyset']['dsrecords']:
                    dsrecord['alg_label'] = self.get_keyset_alg_label(dsrecord['alg'])
                    dsrecord['digest_type_label'] = self.get_keyset_digest_type_label(dsrecord['digestType'])
                for dnskey in result['keyset']['dnskeys']:
                    dnskey['alg_label'] = self.get_keyset_dnskey_alg_label(dnskey['alg'])
                    dnskey['key'] = self.get_keyset_dnskey_formated(dnskey['key'], '\n')
            # omit fields while rendering domain detail (they are empty for status deleteCandidate anyway)
            result['omit_domain_data'] = 'deleteCandidate' in self.getStatusList(d, 'Domain', 'shortName')
            # join status, if necessary
            result['status_names'] = self.getStatusList(d, 'Domain')
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result


    def query_enum(self, *params, **kw):
        handle = kw.get('handle')
        handles = kw.get('handles', {})
        query = kw.get('query')
        d = self.admin.deepDomainInfo(handle, handles)
        result = { 'qtype': 'notfound', 'apptype': self.apptype, 'handle': handle,
            #'query': {'queryHandle':handle} }
            'query': query}
        if d:
            result['qtype'] = 'enum'
            handles['enum'] = handles['domain']
            del(handles['domain'])
            replace_contacts_names_by_org(d)
            result['domain'] = d
            if d['nsset']:
                result['nsset'] = d['nsset'] # XXX hack for nsset macro
                result['nsset']['status_names'] = self.getStatusList(d['nsset'], 'NSSet')
            if d['keyset']:
                result['keyset'] = d['keyset'] # XXX hack for keyset macro
                result['keyset']['status_names'] = self.getStatusList(d['keyset'], 'KeySet')
                for dsrecord in result['keyset']['dsrecords']:
                    dsrecord['alg_label'] = self.get_keyset_alg_label(dsrecord['alg'])
                    dsrecord['digest_type_label'] = self.get_keyset_digest_type_label(dsrecord['digestType'])
                for dnskey in result['keyset']['dnskeys']:
                    dnskey['alg_label'] = self.get_keyset_dnskey_alg_label(dnskey['alg'])
                    dnskey['key'] = self.get_keyset_dnskey_formated(dnskey['key'])
            result['status_names'] = self.getStatusList(d, 'Domain')
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result


    def query_contact(self, *params, **kw):
        handle = kw.get('handle')
        handles = kw.get('handles', {})
        c = self.admin.deepContactInfo(handle, handles)
        result = { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':handle} }
        if c:
            result['qtype'] = 'contact'
            # HACK for EMPTY, RC, OP, ...
            t = c.get('ssnType')
            if t:
                c['ssnTypeKey'] = t
                c['ssnType'] = self.u_translate(Contact.ssnType.get(t, t))

            if c['registrar']['handle'] == conf.get('whois', 'mojeid_registrar_handle'):
                c['mojeID'] = True
                if 16 not in c['statusList']: # 16 = "linked"
                    result['mojeID'] = True

            # previous registry allows list of emails
            c['emails'] = parse_emails(c['email'])
            c['notifyEmails'] = parse_emails(c['notifyEmail'])

            result['contact'] = c
            result['status_names'] = self.getStatusList(c, 'Contact')
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result


    def query_nsset(self, *params, **kw):
        handle = kw.get('handle')
        handles = kw.get('handles', {})
        n = self.admin.deepNSSetInfo(handle, handles)
        result = { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':handle} }
        if n:
            result['qtype'] = 'nsset'
            result['nsset'] = n
            result['status_names'] = self.getStatusList(n, 'NSSet')
            result['nsset']['status_names'] = result['status_names']
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result

    def query_keyset(self, *params, **kw):
        handle = kw.get('handle')
        handles = kw.get('handles', {})
        k = self.admin.deepKeySetInfo(handle, handles)
        result = { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':handle} }
        if k:
            result['qtype'] = 'keyset'
            result['keyset'] = k
            result['status_names'] = self.getStatusList(k, 'KeySet')
            result['keyset']['status_names'] = result['status_names']
            for dsrecord in result['keyset']['dsrecords']:
                dsrecord['alg_label'] = self.get_keyset_alg_label(dsrecord['alg'])
                dsrecord['digest_type_label'] = self.get_keyset_digest_type_label(dsrecord['digestType'])
            for dnskey in result['keyset']['dnskeys']:
                dnskey['alg_label'] = self.get_keyset_dnskey_alg_label(dnskey['alg'])
                dnskey['key'] = self.get_keyset_dnskey_formated(dnskey['key'])
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result


    def query_registrar(self, *params, **kw):
        handle = kw.get('handle')
        r = self.admin.registrarInfo(handle.upper())
        result = { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':handle} }
        if r:
            result['qtype'] = 'registrar'
            result['registrar'] = r
        else:
            result['proxy_errors'] = self.admin.getErrors()
        return result


    def query_registrars(self, group_id=None, *params, **kw):
        """ Returns a list of registrars.
            Arguments:
                group_id: If not None, only returns registrars belonging to
                          group with id == group_id.
        """
        query = kw.get('query')
        if self.apptype == 'enum':
            zone = '0.2.4.e164.arpa'
        else:
            zone = 'cz'
        r = self.admin.registrarsList(zone) or []
        result = { 'apptype': self.apptype, 'query': query, 'qtype': 'registrars',
                   'goodomain': {}, 'technology': self.admin.technologies}
        # append good domain links
        if self.DOBRADOMENA_DIR:
            result['goodomain'] = get_good_domain_list(
                self.DOBRADOMENA_DIR, self.lang)

        cert_group_on = not (conf.has_option('registrars', 'certified_group_ids') and
                conf.get('registrars', 'certified_group_ids').strip() == '')

        if cert_group_on and group_id:
            # Only select registrars that belong to the group.
            reg_ids_for_group = self.admin.getRegistrarIdsForGroup(group_id)
            r = [reg for reg in r if reg["id"] in reg_ids_for_group]

        def _corba_date_to_python(corba_date):
            res = datetime.date(
                year=corba_date.year,
                month=corba_date.month,
                day=corba_date.day)
            return res

        def _cmp_registrars_by_cert_from_date_desc(crt1, crt2):
            corba_date1 = crt1.fromDate
            corba_date2 = crt2.fromDate
            from1 = _corba_date_to_python(corba_date1)
            from2 = _corba_date_to_python(corba_date2)
            if from1 < from2:
                return 1
            elif from1 == from2:
                return 0
            else:
                return -1

        if cert_group_on:
            for reg in r:
                certs = self.admin.getCertificationsForRegistrar(reg['id'])
                now = datetime.datetime.now()
                # Filter out expired certifications.
                certs = [crt for crt in certs if
                    _corba_date_to_python(crt.toDate) >= datetime.date.today() and
                    _corba_date_to_python(crt.fromDate) <= datetime.date.today()]
                # Sort the certifications (so that the most current one 
                # gets index 0).
                if certs:
                    certs.sort(_cmp_registrars_by_cert_from_date_desc)
                    reg["certification"] = certs[0].__dict__

        if self.admin.technologies:
            regs_by_id = dict((reg["id"], reg) for reg in r)
            for group in self.admin.getTechnologyGroups():
                reg_ids = self.admin.getRegistrarIdsForGroup(group.id)
                for reg_id in reg_ids:
                    if reg_id in regs_by_id.keys():
                        if regs_by_id[reg_id].has_key("technology"):
                            regs_by_id[reg_id]["technology"].append(group.name)
                        else:
                            regs_by_id[reg_id]["technology"] = [group.name]

        if not query:
            result['qtype'] = 'registrars-list'
        if r:
            if result['goodomain']:
                # convert registrar handle to good domain name:
                # REG-COMPANY-NAME --> company-name
                for reg in r:
                    reg['goodomain'] = re.sub('^reg[-_]', '', reg.get('handle', '').lower())
            random.shuffle(r)
            result['registrars'] = r
        else:
            result['proxy_errors'] = self.admin.getErrors()
            result['registrars'] = []
        return result

    def _cmp_registrars_by_score_descending(self, reg1, reg2):
        if not reg1.get("certification"):
            score1 = 0
        else:
            score1 = int(reg1.get("certification").get("score"))
        if not reg2.get("certification"):
            score2 = 0
        else:
            score2 = int(reg2.get("certification").get("score"))
        if score1 < score2:
            return 1
        elif score1 == score2:
            return 0
        else:
            return -1

    def multiple_choice(self, *params, **kw):
        links = kw.get('links')
        query = kw.get('query')
        return { 'qtype': 'multiple', 'apptype': self.apptype, 'links': links,
                'query': {'queryHandle':query} }

    def notfound(self, *params, **kw):
        query = kw.get('query')
        return { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':query} }

    def query_invalid(self, *params, **kw):
        query = kw.get('query')
        ## invalid
        return { 'qtype': 'notfound', 'apptype': self.apptype, 'query': {'queryHandle':query} }

    def invalid_gid(self, *params, **kw):
        query = kw.get('query')
        return {
            'qtype': 'invalid_gid', 'apptype': self.apptype,
            'query': {'queryHandle': query} }

    def inputform(self, kw):
        errors = []
        retval = { 'qtype': 'query', 'apptype': self.apptype, 'query': kw.get('query'),
            'errors':errors
            }

        query = kw.get('query')
        if query:
            # display domain name like not editable text and put value in hidden input
            retval['hidehandle'] = 1 # python:('text', 'hidden')[result.get('hidehandle',0)]

        if kw.get('error'):
            errors.append(kw['error'])

        if kw.get('whois_request'):
            if not query:
                errors.append('missing_handle')
        if kw.get('captchakey'):
            # form was submited
            if not query:
                errors.append('missing_handle')
            if self.needcaptcha and kw.get('captcha') is None:
                errors.append('missing_captcha')

        if self.needcaptcha:
            retval['captchakey'] = self.newCaptchaId(kw['captcha_size'])

        return retval


#########################################

    def query_public_request(self, form):
        'Create public_request page'

        log_props = {}

        log_req_type = None

        write_debug_log('function query_public_request')
        if form.get('requestType'):
            log_req_type = PubReqRequestType[form.get('requestType')]

        errors = []
        handle = form.get('handle', None)
        retval = {'qtype': 'publicrequest', 'apptype': self.apptype, 'handle': handle,
                'errors': errors, 'form': form}

        log_props['handle'] = handle

        if log_req_type:
            self._log_public_request(log_req_type, form['remote_ip'], log_props)

        # set defaults for SELECT options:

        if form.get('requestType'):
            # form was submited
            if not handle:
                errors.append('missing_handle')

            if self.needcaptcha and form.get('captcha') is None:
                errors.append('missing_captcha')

            # required mail
            if form.get('requestType') == 'authinfo' \
                    and form.get('sendingMethod') in ('signedemail', 'snailmail') \
                    and not form.get('replyMail'):
                errors.append('mail_missing')

            # required reason
            if form.get('reason') == '3' and form.get('txtreason') is None:
                errors.append('reason_missing')

        if form.get('requestType') is None:
            form['requestType'] = 'authinfo'
        if form.get('sendingMethod') is None:
            form['sendingMethod'] = 'auto'
        if form.get('reason') is None:
            form['reason'] = '1'

        objtype = form.get('objectType', 'empty')
        typefunc = {'domain': 'domainInfo', 'contact': 'contactInfo', 'nsset': 'nssetInfo', 'keyset': 'keysetInfo',
            'empty': None}.get(objtype)
        if handle and typefunc and len(errors) == 0:
            # captcha test
            if self.needcaptcha:
                factory = self.getFactory()
                if factory:
                    captchakey = form.get('captchakey', '')
                    captcha = factory.get(captchakey)
                    userinput = form.get('captcha', '')
                    if (not captcha) or \
                      (not captcha.valid) or \
                      (not captcha.testSolutions([userinput])):
                        errors.append('captcha')
                        retval['captchakey'] = self.newCaptchaId(form['captcha_size'])
                        # Important! Handle must be taken away for display input form:
                        retval.pop('handle')
                        return retval

                    if getattr(factory, 'remove', None):
                        factory.remove(captchakey)
                    else:
                        del factory.storedInstances[captchakey]
            # end captcha



            func = getattr(self.admin, typefunc)
            reply = form.get('requestType', '')

            obj = func(handle)

            status_func = {'domain': 'Domain', 'contact': 'Contact', 'nsset': 'NSSet', 'keyset': 'KeySet', 'empty': None}.get(objtype)
            if 'deleteCandidate' in self.getStatusList(obj, status_func, 'shortName'):
                obj = None

            if obj:
                if reply == 'authinfo':
                    method = form.get('sendingMethod', '')
                    reason = form.get('txtreason', '')
                    if not reason:
                        reason = form.get('reason', '')
                    replymail = form.get('replyMail', '')
                    if not replymail:
                        replymail = ''
                    if not reason:
                        reason = ''
                    if reason == '3':
                        reason = '' # value 3 means '' (no reason)
                else: # block/unblock
                    method = form.get('confirmMethod', '')
                    reason = ''
                    replymail = ''


                result = 0
                error_type = None
                try:
                    result = self.admin.createPublicRequest(obj['id'], reply, method, reason, replymail, self.dbId)
                except WhoisRequestBlocked:
                    if reply.startswith('unblock'):
                        error_type = 'error_request_not_blocked'
                    else:
                        error_type = 'error_request_blocked'
                    reply = 'error'
                except:
                    reply = 'error'

                if result and (method == 'snailmail'):
                    self.session['pdf_id'] = result
                    ## self.session.save()
                retval['reply'] = reply
                retval['error_type'] = error_type
                retval['found'] = True
                retval['id'] = result
                retval['url'] = "http://%s%s" % (self.request[Whois.SERVER_NAME], self.request[Whois.UNPARSED_URI])
                retval['currentTime'] = currentDate()

            return retval

        # open publicrequest form page 
        retval = { 'qtype': 'publicrequest', 'apptype': self.apptype, 'errors': errors, 'form': form }
        if self.needcaptcha:
            retval['captchakey'] = self.newCaptchaId(form['captcha_size'])
        return retval

    def newCaptchaId(self, size):
        factory = self.getFactory()
        if factory:
            return factory.new(NicGimpy, size=size).id
        else:
            return None

    def is_group_certified(self, group_id):
        cert_reg_groups_ids = conf.get(
            'registrars', 'certified_group_ids').split(",")
        return str(group_id) in cert_reg_groups_ids

    def _get_certified_registrars_group_id(self):
        groups = self.admin.getGroups()
        cert_reg_group_name = conf.get('registrars', 'certified_group_name')
        try:
            certified_group_id = [
                g.id for g in groups if g.name == cert_reg_group_name][0]
        except IndexError:
            raise RuntimeError("Could not find certified registrars group!")
        return certified_group_id

    def _get_uncertified_registrars_group_id(self):
        groups = self.admin.getGroups()
        uncert_reg_group_name = conf.get('registrars', 'uncertified_group_name')
        try:
            uncertified_group_id = [
                g.id for g in groups if g.name == uncert_reg_group_name][0]
        except IndexError:
            raise RuntimeError("Could not find uncertified registrars group!")
        return uncertified_group_id

    def _check_gid_validity(self, gid):
        cert_reg_gids = conf.get(
            'registrars', 'certified_group_ids').split(",")
        uncert_reg_gids = conf.get(
            'registrars', 'uncertified_group_ids').split(",")
        return (str(gid) in cert_reg_gids) or (str(gid) in uncert_reg_gids)

    def render(self, form, links={}):
        'Render html page along to queries. Returns (rendered-body, url-to-redirect)'
        # pure registrars list
        url_part = self.request[Whois.PARSED_URI][6]
        render_immediately = False

        # Checking the links to match the URL is kinda stupid, but that's the
        # way it was written (for an unknown reason) and rewritting it would be
        # a major pain in the ass. So we leave it and we leave a warning here. 
        # :-)
        ##### registrar list 
        if url_part.startswith(links.get('registrars_list')):
            answer = self.query_registrars(group_id=self.group_id)
            any_non_zero_score = any(
                [r['certification']['score'] > 0 for \
                    r in answer['registrars'] if r.get('certification')])
            is_gid_valid = (
                self.group_id is None or
                self._check_gid_validity(self.group_id))
            if not is_gid_valid:
                return (self._render(
                    self.invalid_gid(query=self.group_id)), None)
            should_display_certs_for_this_group = self.is_group_certified(
                self.group_id)
            if any_non_zero_score and should_display_certs_for_this_group:
                # We only display score and detail file if there is a registrar
                # with score > 0.
                answer['show_certifications'] = True
                # Sort registrars according to score (registrars with same
                # score are ordered randomly, because the field has already
                # been randomized before and sorting preserves natural
                # ordering).
                answer['registrars'].sort(
                    self._cmp_registrars_by_score_descending)
            else:
                answer['show_certifications'] = False
            render_immediately = True
        if url_part == conf.get('registrars', 'location'):
            answer = self.query_registrars()
            render_immediately = True

        if render_immediately:
            self.langswitch = "%s?lang=%%s" % conf.get('registrars', 'location')
            return (self._render(answer), None)

        ##### public request page + result
        location = conf.get('publicrequest', 'location')
        write_debug_log(" Location: " + location)
        write_debug_log(" request [Whois.PARSED_URI][6]: " + self.request[Whois.PARSED_URI][6])
        if self.request[Whois.PARSED_URI][6] == location \
            or self.request[Whois.PARSED_URI][6] == links.get('publicrequest'):

            self.session['captcha_size'] = form['captcha_size'] = 10

            answer = self.query_public_request(form)

            self.langswitch = "%s?lang=%%s" % location


            # link to main page changed to 'publicrequest'
            return (self._render(answer, 0, {}), None) #Ok

        # Whois captcha size 5 and for autInfo 10.
        self.session['captcha_size'] = form['captcha_size'] = 5

        if self.apptype == 'whois':
            d = form.get('d') # domain
        else:
            d = None
        if self.apptype == 'enum':
            e = form.get('e') # enum
        else:
            e = None
        c = form.get('c') # contact
        n = form.get('n') # nsset
        k = form.get('k') # keyset
        r = form.get('r') # registrar
        q = form.get('q') # generic types (domain, enum, contact, nsset, keyset, registrar)
        answer = None
        mojeid_endpoint = None
        status = 'OK'


        if q:

            q = re.sub('\s+', '', q) # remove spaces from query

            # captcha test
            if self.needcaptcha:
                factory = self.getFactory()
                if factory:
                    captchakey = form.get('captchakey', '')
                    captcha = factory.get(captchakey)
                    userinput = form.get('captcha', '')
                    if (not captcha) or \
                       (not captcha.valid) or \
                       (not captcha.testSolutions([userinput])):
                        form['query'] = q
                        if userinput:
                            form['error'] = 'captcha'
                        return (self._render(self.inputform(form)), None)

                    if getattr(factory, 'remove', None):
                        factory.remove(captchakey)
                    else:
                        del factory.storedInstances[captchakey]
            # end captcha

            # new query, clear previous list of "safe" ids
            if self.session.get('handles'):
                del(self.session['handles'])
            # firsthandles is list (mostly with single element) of possible
            # type specific queries, which should follow next.
            # if only one item is returned, user is automaticaly redirected to
            # that specific entry, otherwise list of links is provided
            firsthandles = rehashHandles(self.admin.checkHandle(q), q)

            if self.admin.invalid_input_type:
                return (self._render(self.query_invalid(query=q)), None)

            # reset types on conflicting types
            if self.apptype == 'whois':
                [ firsthandles.__delitem__(firsthandles.index(x)) for x in firsthandles if x['resultHandleType'] in ['ENUM_DOMAIN', 'ENUM_NUMBER'] ]
            if self.apptype == 'enum':
                [ firsthandles.__delitem__(firsthandles.index(x)) for x in firsthandles if x['resultHandleType'] == 'DOMAIN' ]
            self.session['firsthandles'] = firsthandles
            ## self.session.save()
            if len(firsthandles) > 1:
                # draw list of links
                links = {'enum': None, 'contact': None, 'domain': None, 'nsset': None, 'registrar': None}
                new_fh = [] # new list of the firsthandles
                for x in firsthandles:
                    if x['resultHandleFunction'] is not 'invalid':
                        links[x['resultHandleFunction']] = x['queryHandle']
                        new_fh.append(x)
                firsthandles = new_fh

            if len(firsthandles) > 1:
                answer = self.multiple_choice(links=links, query=q)

            elif len(firsthandles) == 1:
                queryHandle = firsthandles[0].get('queryHandle')
                # redirect to specific query
                if firsthandles[0]['resultHandleFunction'] == 'invalid':
                    status = 'invalid'
                    answer = self.query_invalid(query=queryHandle)
                elif firsthandles[0]['resultHandleFunction'] == 'registrars':
                    answer = self.query_registrars(query=queryHandle)
                else:
                    base_url = urlparse.urlsplit(self.request[Whois.URI])[2].replace('/%s' % os.path.basename(__file__), '')

                    return (None, "%s/?%s=%s" % (base_url, firsthandles[0]['resultHandleAttribute'], urllib.quote(firsthandles[0]['queryHandle'].encode(ENCODING))))
            else:
                # error (shouldn't be < 1)
                status = 'invalid'
                answer = self.query_invalid(query=q)

            log_content = q

        # request to one of specific types
        elif (d or e or c or n or k or r):
            if d:
                # domain
                handle = d.decode(ENCODING)
                handleFunction = 'domain'
            elif e:
                # enum
                handle = e.decode(ENCODING)
                handleFunction = 'enum'
            elif c:
                # contact
                handle = c.decode(ENCODING)
                handleFunction = 'contact'
            elif n:
                # nsset
                handle = n.decode(ENCODING)
                handleFunction = 'nsset'
            elif k:
                # keyset
                handle = k.decode(ENCODING)
                handleFunction = 'keyset'
            elif r:
                # registrar
                handle = r.decode(ENCODING)
                handleFunction = 'registrar'

            # test if handle and handleFunction are together in any item within firsthandles
            firstvalid = self.session.get('firsthandles', None) and \
                [ x for x in self.session['firsthandles'] if (x['resultHandleFunction'] == handleFunction) and (x['queryHandle'] == handle) ]
            # test if "handles" dict contains handle and handleFunction pair
            secondvalid = self.session.get('handles', None) and \
                (handle in self.session['handles'].get(handleFunction, []))
            # at least one have to succeed
            if firstvalid or secondvalid:
                objtype = rehashHandles(self.admin.checkHandle(handle.encode(ENCODING)), handle)
                if self.admin.invalid_input_type:
                    return (self._render(self.query_invalid(query=handle)), None)

                qtype = [ x for x in objtype if x['resultHandleFunction'] == handleFunction and x['queryHandle'] == handle]
                if len(qtype):
                    query = qtype[0]
                else:
                    query = ''
                if qtype:
                    query['queryHandle'] = handle
                    query['queryHandleFunction'] = handleFunction
                    # get reference to function handling this specific query
                    func = getattr(self, "query_%s" % query['resultHandleFunction'])
                    # prepare empty dict for storing lists of handles, which can be
                    # queried next in this session
                    handles = {}
                    # if query has translated handle, use it (most probably for enum)
                    h = query['resultHandle'] or query['queryHandle']
                    answer = func(handle=h, handles=handles, query=query)
                    # store valid handles in session if it doesn't exist yet
                    if not self.session.get('handles', None):
                        self.session['handles'] = handles
                        ## self.session.save()
                    if answer:
                        if handleFunction == 'contact':
                            # check if contact handler is valid mojeID identifier
                            try:
                                from django.conf import settings
                                answer['is_site_nic'] = settings.SITE_DIR_NAME == "nic"
                            except ImportError, msg:
                                logging.debug('ImportError: %s' % msg)
                            handle = answer.get('contact', {}).get('handle')
                            if handle and re.match('^[A-Za-z0-9](-?[A-Za-z0-9])*$', handle) and not answer.get('contact', {}).get('mojeID'):
                                is_valid = True
                                # create context for post formular of mojeID
                                mojeid_endpoint = build_mojeid_endpoint(answer['contact'])
                            else:
                                is_valid = False
                            answer['contact']['is_valid_mojeid_handler'] = is_valid
                    else:
                        answer = self.notfound(query=query)
                        status = 'not found'
                else:
                    answer = self.query_invalid(query=query)
                    status = 'invalid'
            else:
                # test why none of tests passed. for now it's set to 'cookie' (catched in 
                # templates) as it ends here only if user set direct URL to one [c,d,e,n,r]
                # query strings without filling in captcha code
                form['query'] = handle
                if self.needcaptcha:
                    form['error'] = 'missing_captcha'
                answer = self.inputform(form)
                status = 'error'

            log_content = handle

        else:
            # no request, supply inputform                        
            answer = self.inputform(form)
            status = 'no request'
            log_content = None

        if answer and mojeid_endpoint and conf.has_section("mojeid"):
            answer['mojeid_registry_endpoint'] = mojeid_endpoint
            answer['mojeid_transfer_endpoint'] = conf.get('mojeid', 'transfer_endpoint')

        # if answer and log_content:
        if answer and status != 'no request':
            self._log_whois(form['remote_ip'], log_content, status, answer)
            result_code = 2 #error
            if answer == None and status == 'OK':
                result_code = 1 #no response
            if answer and status == 'OK':
                result_code = 0 #ok
            return (self._render(answer, result_code, {}), None)

        return (self._render(answer), None)

    def _log_public_request(self, log_request_type, remote_ip, props):
        "Logs a public request, doesn't close the logging record"

        self.dbId = self.admin.logRequest(None, remote_ip, props, LC_PUBLIC_REQUEST, log_request_type)
        if not self.dbId:
            write_debug_log('Failed to log public request')

    def _log_whois(self, remote_ip, content, status, ans):
        "Logs a whois request using fred-logd service. "

        properties = {}
        #properties = [ self.admin.ccReg.RequestProperty('qtype', ans['qtype'], False, False),
        #          self.admin.ccReg.RequestProperty('apptype', ans['apptype'], False, False)  ]

        if 'qtype' in ans and ans['qtype']:
        # don't log registrar list query
            if ans['qtype'] == 'registrars-list':
                return

            properties['queryType'] = ans['qtype']

        if status:
            properties['status'] = status;

        if 'query' in ans and ans['query'] and 'queryHandle' in ans['query']:
            properties['handle'] = ans['query']['queryHandle']

        #if 'apptype' in ans and ans['apptype']:
        #    properties.append(self.admin.ccReg.RequestProperty('apptype', str(ans['apptype']), False, False))

        #if 'form' in ans and ans['form']:
        #    form = ans['form']
        #    if 'requestType' in form and form['requestType']:                
        #        properties.append( self.admin.ccReg.RequestProperty('form', str(ans['form']), True, False))

        self.dbId = self.admin.logRequest(content, remote_ip, properties, LC_WEB_WHOIS, WhoisRequestType["Info"])
        if not self.dbId:
            write_debug_log('Failed to log whois request')


    def _render(self, content, log_result=None, request_out_props={}):
        'Render content into TAL'
        # text for template must be in unicode, decode text inputs only
        for key in ('query', 'queryHandle', 'handle', 'replyMail', 'txtreason'):
            if type(content.get(key)) is str:
                content[key] = content[key].decode(ENCODING)
        if content.has_key('form'):
            for key in ('handle', 'replyMail', 'txtreason'):
                if type(content['form'].get(key)) is str:
                    content['form'][key] = content['form'][key].decode(ENCODING)

        if not content.has_key('form'):
            content['form'] = {}
        content['form']['captcha_img'] = {'width': CAPTCHA_SIZE[0], 'height':CAPTCHA_SIZE[1]}

        # join proxy errors, if any occurs after call query functions.
        if len(self.admin.errors):
            messages = self.admin.getErrors()
            if content.has_key('proxy_errors'):
                content['proxy_errors'].extend(messages)
            else:
                content['proxy_errors'] = messages

        if len(content.get('proxy_errors', [])):
            # if any corba errors occurs
            section, option = 'corba', 'redirect_errors'
            if conf.has_option(section, option):
                # relesase mode: don't display corba errors on the page
                open(conf.get(section, option), 'a').write('\n'.join(content['proxy_errors']))
                content['redirected_error'] = 'yes'
                content.pop('proxy_errors') # remove internal proxy errors
                content['qtype'] = 'error_proxy'
            else:
                # debug mode: display errors on the page
                content['proxy_errors'].insert(0, 'Internal ccregproxy errors:') # Label

        # template content menu taken from config [templates] inset:
        try:
            content_menu = simpleTAL.compileHTMLTemplate(open("%s.%s" % (conf.get('templates', 'content_menu'), self.lang)), inputEncoding=ENCODING)
        except IOError, e:
            log_message('IOError: %s' % e)
            content_menu = simpleTAL.compileHTMLTemplate('IOError: %s' % e)

        # create content (inset) from current values
        try:
            inset = simpleTAL.compileHTMLTemplate(open("%s.%s" % (conf.get('templates', 'inset'), self.lang)), inputEncoding=ENCODING)
        except IOError, e:
            log_message('IOError: %s' % e)
            inset = simpleTAL.compileHTMLTemplate('IOError: %s' % e)
        # natazeni maker
        try:
            macros = simpleTAL.compileHTMLTemplate(open("%s.%s" % (conf.get('templates', 'macros'), self.lang)), inputEncoding=ENCODING)
        except IOError, e:
            log_message('IOError: %s' % e)
            macros = simpleTAL.compileHTMLTemplate('IOError: %s' % e)

        # create context from current values
        context = simpleTALES.Context(allowPythonPath=1)
        context.addGlobal("localtime", localtime)
        context.addGlobal("title", title)
        context.addGlobal("common", self.common)
        context.addGlobal("uri", self.request[Whois.URI] and urlparse.urlsplit(self.request[Whois.URI])[2] or "/")
        context.addGlobal("result", content)
        context.addGlobal("macropage", macros)

        # extra content processor
        if EXTRA_CONTENT_PROCESSOR:
            exec(EXTRA_CONTENT_PROCESSOR)

        # extra content; related with templates
        section, option = 'extra_content', 'keys'
        if conf.has_section(section) and conf.has_option(section, option):
            for key in conf.get(section, option).split(' '):
                name = '%s.%s' % (key, self.lang)
                if not conf.has_option(section, name):
                    continue
                extal = simpleTAL.compileHTMLTemplate(conf.get(section, name), inputEncoding=ENCODING)
                exbody = StringIO.StringIO()
                extal.expand(context, exbody, outputEncoding=ENCODING)
                exbody.seek(0)
                content['extra_content_%s' % key] = exbody.read().decode(ENCODING)
                exbody.close()

        # fill inset template by data
        output = StringIO.StringIO()
        output.write('<div id="main-content">\n')
        if not self.hideContentMenu:
            # append content menu
            content_menu.expand(context, output, outputEncoding=ENCODING)
        inset.expand(context, output, outputEncoding=ENCODING)
        output.write('</div>\n')

        output.seek(0)
        result = output.read()
        output.close()
        if self.templatetype == 'external': # pretty naive parser :-/
            # load page at http://enum.nic.cz/ 
            error = None
            url = conf.get('whois', 'url.%s' % (self.lang))
            if url[:4] == 'http':
                # file from web
                try:
                    livepage = urllib2.urlopen(url).read()
                except ValueError, e:
                    error = 'ValueError: %s. %s' % (e, url)
                except urllib2.URLError, e:
                    error = 'URLError: %s. %s' % (e, url)
                except urllib2.HTTPError, e:
                    error = 'HTTPError: %s. %s' % (e, url)
            else:
                # local file
                try:
                    livepage = open(url).read()
                except IOError, e:
                    error = 'IOError: %s. %s' % (e, url)

            if error:
                log_message(error)
                livepage = ''

            parts = livepage.split('<div id="main-content">')
            prefix = parts[0]

            # The link enum.nic.cz is deprecated by cause of new website running at the django engine.
            #prefix = prefix.replace('http://enum.nic.cz/css/global.css', "/whois/_css/global.css")
            # Previous template nad styles are temporarly (!!!) put at /enumday
            prefix = re.sub('[^\'"\s]+/css/global.css', '/whois/_css/global.css', prefix, 1)

            prefix = prefix.replace('/en/template/28/', self.langswitch % "en")
            prefix = prefix.replace('/cz/template/28/', self.langswitch % "cz")
            anchor = '<div id="main-menu">'
            if len(parts) > 1:
                part1 = parts[1].split(anchor) # [1]
                if len(part1) > 1:
                    postfix = part1[1]
                else:
                    postfix = ''
            else:
                postfix = ''
            result = "%s%s%s%s" % (prefix, result, anchor, postfix)
        elif self.templatetype == 'internal':
            # get local surroundings and set result into it
            # regenerates 'result' too
            output = StringIO.StringIO()
            context.addGlobal("inset", result.decode(ENCODING))
            try:
                template = simpleTAL.compileHTMLTemplate(open("%s.%s" % (conf.get('templates', 'index'), self.lang)), inputEncoding=ENCODING)
            except IOError, e:
                log_message('IOError: %s' % e)
                template = simpleTAL.compileHTMLTemplate('IOError: %s' % e)
            template.expand(context, output, outputEncoding=ENCODING)
            output.seek(0)
            result = output.read()
            output.close()

        if self.templatetype != 'inset' and self.request[Whois.PARSED_URI][6] == conf.get('publicrequest', 'location'):
            # join javascripts for publicrequest
            tag = '<script type="text/javascript" src="/media/_js/%s.js"></script>'
            links_js = [tag % 'MochiKit/MochiKit', tag % 'ajax', tag % 'main', tag % 'publicrequest']
            if not self.needcaptcha:
                links_js.append(tag % 'captcha_status')
            if self.lang == 'cs_CZ':
                links_js.append(tag % 'messages_cs')
            result = re.sub('</head>', '%s\n</head>' % '\n'.join(links_js), result, 1)

        #if we don't want to call logging
        if log_result == None:
            return result
        elif self.dbId:
            pubreq_id = None
            if content and 'id' in content:
                pubreq_id = content['id']

            write_debug_log('Object ID: ' + str(pubreq_id))
            self.admin.logResponse(self.dbId, request_out_props, log_result, pubreq_id)

        return result

    def getFactory(self):
        'Access to the captcha persistent values. In case not permitions returns None'
        if self.factory:
            return self.factory

        path = "/tmp/pycaptcha_%s" % self.request[Whois.INTERPRETER]
        self.factory = PersistentFactory(path)
        return self.factory


class FileDownloader(object):
    def __init__(self):
        super(FileDownloader, self).__init__()
        self.admin = ccregproxy.Admin(
                ior='corbaname::' + conf.get('corba', 'host'),
                idl=conf.get('corba', 'idl'),
                context=conf.get('corba', 'context'))

    def get_file_info(self, file_id):
        info = self.admin.getFileInfo(file_id)
        return info

    def download_file(self, file_id):
        f = self.admin.loadFile(file_id)
        return f


def handler(req):
    form = util.FieldStorage(req)
    session = Session.Session(req)

    lang = DEFAULT_LANG
    try:
        lang = session['lang']
    except KeyError:
        pass
    try:
        qlang = util.parse_qs(req.args)['lang'][0]
        if qlang in ['cz', 'en']:
            lang = qlang
    except:
        pass
    session['lang'] = lang

    # request goes to captcha image
    # match expresion captcha.py and possible paramters:
    # req.parsed_uri[6]='/whois/captcha.py'
    # req.parsed_uri[7]='id=LIjJKkhntjXw2L6ewVhTFwLx'
    if re.search('captcha.py[^/]*$', req.parsed_uri[6]):

        req.content_type = "image/jpeg"

        id = form.getfirst('id')
        w = Whois(get_request(req), session)
        factory = w.getFactory()
        if not factory:
            req.write(jpeg_captcha_no_access())
            return apache.OK

        test = factory.get(id)
        if not test:
            req.write(jpeg_captcha_invalid_user())
            return apache.OK
            # raise apache.SERVER_RETURN, apache.HTTP_NOT_FOUND

        test.render(size=CAPTCHA_SIZE).save(req, "JPEG")
        return apache.OK

    try:
        w = Whois(get_request(req), session)

        # request goes to PDF request, we need Whois instance
        if req.parsed_uri[6] == conf.get('pdf', 'location'):
            sid = session.get('pdf_id', None)
            if not sid:
                raise apache.SERVER_RETURN, apache.HTTP_FORBIDDEN
            pdf = None
            try:
                if lang == 'cz': # 'cz' is used in whole enum website, 'cs' in corba
                    pdflang = 'cs'
                else:
                    pdflang = lang
                pdf = w.admin.getPublicRequestPDF(sid, pdflang)
            except:
                raise apache.SERVER_RETURN, apache.HTTP_NOT_FOUND
            req.content_type = "application/pdf"
            session.save()
            req.headers_out["Content-Disposition"] = "attachment; filename=CZ-NIC_PasswordRequest.pdf"
            req.write(pdf)
            return apache.OK

        req.content_type = 'text/html'
        body, redirect_url = w.render(get_form_data(req, form), links={'registrars_list': '/whois/registrars'})
        session.save()
        if redirect_url:
            util.redirect(req, redirect_url)
        else:
            req.write(body)
        return apache.OK
    except:
        raise


def get_request(req):
    'Get data from apache mp_request'
    return  (
            req.server.server_hostname,
            req.interpreter, # used for db captcha
            req.unparsed_uri, # '/whois/?' or '/captcha.py?id=d3sDVO6awBmOVKJZ7KWxOPgc'
            req.parsed_uri,
            req.uri,
            )


def get_form_data(req, form):
    'Get data from mod_python.util.FieldStorage'
    # Warning! This function is used only in mod_python.
    #        For django exists similar function in apps/cms/view/meny.py
    # form: get, getfirst, getlist, has_key, keys, list, make_field, 
    #       make_file, read_to_boundary
    # d - domain, e - enum
    # c - contact
    # n - nsset
    # k - keyset
    # r - registrar
    # q - generic types (domain, enum, contact, nsset, keyset, registrar)
    # shared:
    #   captchakey, captcha
    # query_public_request:
    #   handle, objectType,requestType, txtreason, reason, replyMail
    f = {}
    for key in ('d', 'e', 'c', 'n', 'k', 'r', 'q',
        'captchakey', 'captcha', 'whois_request',
        'handle', 'objectType', 'requestType', 'txtreason', 'reason',
        'replyMail', 'confirmMethod', 'sendingMethod'):
        f[key] = form.getfirst(key)

        if type(f[key]) is unicode:
            f[key] = f[key].encode('utf-8')

        if type(f[key]) is str and f[key].strip() == '':
            f[key] = None
    f['remote_ip'] = req.connection.remote_ip
    return f


def replace_name_by_org(d):
    'Replace name by organisation'
    if len(d.get('organization', '')):
        d['name'] = d['organization']

def replace_contacts_names_by_org(d):
    replace_name_by_org(d.get('registrant', {}))
    for admin in d.get('admins', []):
        replace_name_by_org(admin)
    for admin in d.get('temps', []):
        replace_name_by_org(admin)
    for admin in d.get('nsset', {}).get('admins', []):
        replace_name_by_org(admin)
    for admin in d.get('keyset', {}).get('admins', []):
        replace_name_by_org(admin)

def parse_emails(emails):
    return re.split('[,\s]+', emails.strip())

def make_jpeg(message):
    """Display error messages in jpeg file.
    Used to problems with captcha creation.
    Returned raw JPEG stream.
    """
    try:
        import Image, ImageDraw
    except ImportError:
        # if PIL missing use static jpeg
        path = os.path.join(os.path.dirname(__file__), 'captcha/pil_missing.jpg')
        return open(path).read()

    img = Image.new('L', CAPTCHA_SIZE, 0xffffff)
    draw = ImageDraw.Draw(img)
    # draw border
    x, y = CAPTCHA_SIZE[0] - 1, CAPTCHA_SIZE[1] - 1
    draw.rectangle(((0, 0), (x, y)))
    # draw message text
    x, y = 10, 10
    for line in message.split('\n'):
        draw.text((x, y), line)
        y += 15
    # write to output
    output = StringIO.StringIO()
    img.save(output, 'jpeg')
    output.seek(0)
    data_jpeg = output.read()
    output.close()
    return data_jpeg

def jpeg_captcha_no_access():
    return make_jpeg("""Error:
Chaptcha is not accessible.
Check captcha file privileges.
Path is defined in whois.py _getFactory()""")


def jpeg_captcha_invalid_user():
    return make_jpeg('Chaptcha Error:\nInvalid user ID.')


def write_debug_log(*messages):
    f = open(conf.get('log', 'log_path'), 'a')
    if f:
        for msg in messages:
            f.write(str(msg) + '\n')
        f.close()

def debug_object(name, obj):
    body = ['DEBUG: %s' % name]
    for key in dir(obj):
        body.append('%s = %s' % (key, repr(getattr(obj, key))))
    return '\n'.join(body)


def build_mojeid_endpoint(contact):
    """
    Prepare data for registration protocol for transfer with update.
    """
    if not conf.has_section("mojeid"):
        return {}

    retval = {'action': conf.get('mojeid', 'registry_endpoint')}
    params = []

    params.append(('username', contact['handle'].lower()))

    if contact['discloseOrganization']:
        if contact['organization']:
            params.append(('organization', contact['organization']))

    if contact['discloseName']:
        if contact['name']:
            params.append(('full_name', contact['name']))

    if contact['discloseVat']:
        if contact['vat']:
            params.append(('vat_reg_num', contact['vat']))

    # SSN type
    if contact['discloseIdent'] and contact['ssn']:
        if contact['ssnTypeKey'] == 'ICO':
            params.append(('vat_ident_num', contact['ssn']))
        elif contact['ssnTypeKey'] == 'BIRTHDAY':
            params.append(('birth_date', date2iso(contact['ssn'])))

    if contact['discloseNotifyEmail']:
        if contact['notifyEmail']:
            params.append(('email__notify__email', contact['notifyEmail']))

    if contact['discloseFax']:
        if contact['fax']:
            params.append(('phone__fax__number', contact['fax']))

    if contact['discloseEmail']:
        if contact['email']:
            params.append(('email__default__email', contact['email']))

    if contact['discloseTelephone']:
        if contact['telephone']:
            params.append(('phone__default__number', contact['telephone']))

    if contact['discloseAddress']:
        for key in ('street1', 'street2', 'street3'):
            if contact[key]:
                params.append(('address__default__%s' % key, contact[key]))
        if contact['postalcode']:
            params.append(('address__default__postal_code', contact['postalcode']))
        if contact['city']:
            params.append(('address__default__city', contact['city']))
        if contact['province']:
            params.append(('address__default__state', contact['province']))
        if contact['country']:
            params.append(('address__default__country', contact['country']))

    retval['post_params'] = params
    return retval
