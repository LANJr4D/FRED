#!/usr/bin/env python2.4

# fallback constants
IDL_FILE = "ccReg.idl"

# system imports
import os
os.putenv('ORBnativeCharCodeSet', 'UTF-8') # should work, but it doesn't
os.environ['ORBnativeCharCodeSet'] = 'UTF-8' # should work, but it doesn't
argv = ["-ORBnativeCharCodeSet", "UTF-8"] # even this doesn't work.. omniORB sucks
# set UTF-8 variable in config file (usually /etc/omniorb/omniORB.cfg)
# ie: nativeCharCodeSet = UTF-8

import sys
import time
import types
import urlparse
from exceptions import Exception
import datetime

# extension imports
import omniORB
import CosNaming
from omniORB import CORBA, importIDL

# local imports
import corbaparser
import whois

# own exceptions
class IorNotFoundError(Exception):
    pass
class AlreadyLoggedInError(Exception):
    pass
class NotLoggedInError(Exception):
    pass
class LanguageNotSupportedError(Exception):
    pass
class SetLangAfterLoginError(Exception):
    pass
class ParameterIsNotListOrTupleError(Exception):
    pass


# CORBA global failure handling
def transientFailure(cookie, retries, exc):
    if retries > 20:
        return False
    else:
        return True

def commFailure(cookie, retries, exc):
    if retries > 40:
        return False
    else:
        return True

def systemFailure(cookie, retries, exc):
    if retries > 5:
        return False
    else:
        return True

ENCODING = 'utf-8'

cookie = None

omniORB.installTransientExceptionHandler(cookie, transientFailure)
omniORB.installCommFailureExceptionHandler(cookie, commFailure)
omniORB.installSystemExceptionHandler(cookie, systemFailure)

importIDL(whois.conf.get('corba', 'idl'))
ccReg = sys.modules['ccReg']
registry = sys.modules['Registry']
# CORBA end

def convertProperties(props, output):
    cproperties = []
    
    if not props:
        return cproperties

    for key, value in props.iteritems():
        if type(value) is unicode:
            value = value.encode(ENCODING)
        elif type(value) is not str:
            value = str(value)            
        
        cproperties.append(
            ccReg.RequestProperty(key, value, output, False))

    return cproperties



class Admin(object):

    def __init__(self, ior='corbaname::localhost', idl=None, context='fred', 
            orb=None):
        object.__init__(self)
              
        # Action types taken from log_action_type database table
        self.LogActionType = {'Info': 1104}
        
        techs_str = whois.conf.get('registrars', 'technologies')
        techs = techs_str.split(',') if techs_str else []
        self.technologies = techs
        
        self.context = context
                    
        self.errors = [] # keep error messages for display later
        self.ccReg = ccReg
        self.Registry = registry
        self.__logger = None
        if orb is None:
            orb = CORBA.ORB_init(
                ["-ORBInitRef", "NameService=%s" % ior], CORBA.ORB_ID)
        try:
            obj = orb.string_to_object(ior)
            self.rootContext = obj._narrow(CosNaming.NamingContext)
            self.__admin = self.getCorbaObject(
                self.rootContext, 'WebWhois', 'Admin')
            try:
                self.__logger = self.getCorbaObject(
                    self.rootContext, 'Logger',  'Logger')
            except CosNaming.NamingContext.NotFound, e:
                write_debug_log(
                    "Logger not found, loggin of actions is turned off, "
                    "exception: %s" % e)
            try:
                self.__whois = self.getCorbaObject(
                    self.rootContext, 'Whois',  'Whois')
            except CosNaming.NamingContext.NotFound, e:
                write_debug_log(
                    "Whois not found, "
                    "exception: %s" % e)
            self.__corbaparser = corbaparser.CorbaParser('utf-8')
            self.__langs = {}
            self.invalid_input_type = False # checkHandle()
            [ self.__langs.__setitem__(x._n, x) for x in self.ccReg.Languages._items ]
        except:
            self.errors.append(get_exception())

    def getErrors(self):
        'Returns errors and reset error list.'
        retval = self.errors
        self.errors = [] # reset
        return retval

    def getCorbaObject(self, context, name, idltype):
        cosname = [
            CosNaming.NameComponent(self.context, "context"), 
            CosNaming.NameComponent(name, "Object")]
        obj = context.resolve(cosname)
        return obj._narrow(getattr(self.ccReg, idltype))

    def parse(self, answer):
        """
        This is generic parser for CORBA answers
        """
        parsed = self.__corbaparser.parse(answer)
        return parsed

    def _rewriteUrl(self, url):
        if url and not urlparse.urlsplit(url)[0]:
            url = "http://%s" % (url,)
        return url
    
    def domainInfo(self, domain, handles = {}):
        try:
            if isinstance(domain, types.UnicodeType):
                domain = domain.encode('utf-8')
            ret = self.parse(self.__whois.getDomainByFQDN(domain))
            if 'domain' not in handles.keys():
                handles['domain'] = [domain]
            if domain not in handles['domain']:
                handles['domain'].append(domain)
        except self.ccReg.Whois.ObjectNotFound:
            ret = None
        except self.ccReg.Whois.InternalServerError:
            self.errors.append(get_exception())
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def logRequest(self, content, ipaddr, props, service_type, action_type):
        if self.__logger:
            if action_type is None:
                return None;

            try:
                if isinstance(content, types.UnicodeType):
                    content = content.encode(ENCODING)

                if not content:
                    content = ''
                if not ipaddr:
                    ipaddr = '' 

                cproperties = convertProperties(props, False)
        
                ret = self.__logger.createRequest(
                    ipaddr, service_type, content, cproperties, [], action_type, 0)
                if ret == 0:
                    ret = None
                     
            except self.ccReg.Admin.ObjectNotFound:
                write_debug_log('exception: ObjectNotFound')
                ret = None            
            except:
                # Following line is commented, because Error while Logging should not affect functionality of whois:
                # self.errors.append(get_exception()) 
                write_debug_log('other exception: ', get_exception())
                ret = None
        else:
            write_debug_log('Reference to logger object not found')
            ret = None
        return ret      
    
    
    def logResponse(self, dbId, props = {}, result_code=0, object_id = None):
        """ end record about request in fred-logd
            default is no properties and successful result code
        """ 
        if self.__logger:
            try:
                cprops = convertProperties(props, True)

                objrefs = []
                if object_id:
                    objrefs.append(ccReg.ObjectReference("publicrequest", object_id))

                self.__logger.closeRequest(dbId, '', cprops, objrefs, result_code, 0)   
            except self.ccReg.Admin.ObjectNotFound:
                write_debug_log('exception: ObjectNotFound')
            except:
                # Following line is commented, because Error while Logging should not affect functionality of whois:
                # self.errors.append(get_exception())
                write_debug_log('other exception: ', get_exception())
        else:
            write_debug_log('No reference to logger')
            
    def contactInfo(self, contact, handles = {}):
        try:
            if isinstance(contact, types.UnicodeType):
                contact = contact.encode('utf-8')
            ret = self.parse(self.__whois.getContactByHandle(contact))
            if 'contact' not in handles.keys():
                handles['contact'] = [contact]
            if contact not in handles['contact']:
                handles['contact'].append(contact)
        except omniORB.CORBA.MARSHAL:
            ret = None
        except self.ccReg.Whois.ObjectNotFound:
            ret = None
        except self.ccReg.Whois.InternalServerError:
            self.errors.append(get_exception())
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def nssetInfo(self, nsset, handles = {}):
        try:
            if isinstance(nsset, types.UnicodeType):
                nsset = nsset.encode('utf-8')
            ret = self.parse(self.__whois.getNSSetByHandle(nsset))
            if 'nsset' not in handles.keys():
                handles['nsset'] = [nsset]
            if nsset not in handles['nsset']:
                handles['nsset'].append(nsset)
        except omniORB.CORBA.MARSHAL:
            ret = None
        except self.ccReg.Whois.ObjectNotFound:
            ret = None
        except self.ccReg.Whois.InternalServerError:
            self.errors.append(get_exception())
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
                        
        return ret

    def keysetInfo(self, keyset, handles = {}):
        try:
            if isinstance(keyset, types.UnicodeType):
                keyset = keyset.encode('utf-8')
            ret = self.parse(self.__whois.getKeySetByHandle(keyset))
            if 'keyset' not in handles.keys():
                handles['keyset'] = [keyset]
            if keyset not in handles['keyset']:
                handles['keyset'].append(keyset)
        except omniORB.CORBA.MARSHAL:
            ret = None
        except self.ccReg.Whois.ObjectNotFound:
            ret = None
        except self.ccReg.Whois.InternalServerError:
            self.errors.append(get_exception())
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def registrarInfo(self, registrar, handles = {}):
        try:
            if isinstance(registrar, types.UnicodeType):
                registrar = registrar.encode('utf-8')
            ret = self.parse(self.__whois.getRegistrarByHandle(registrar))
            if 'registrar' not in handles.keys():
                handles['registrar'] = [registrar]
            if registrar not in handles['registrar']:
                handles['registrar'].append(registrar)
            newaccess = []
            for acc in ret['access']:
                try:
                    newaccess.append(acc.__dict__)
                except AttributeError:
                    newaccess.append(acc)
            ret['access'] = newaccess
            ret['url'] = self._rewriteUrl(ret['url'])
        except self.ccReg.Whois.ObjectNotFound:
            ret = None
        except self.ccReg.Whois.InternalServerError:
            self.errors.append(get_exception())
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def registrarsList(self, zone, sort = False):
        try:
            if isinstance(zone, types.UnicodeType):
                zone = zone.encode('utf-8')
            ret = [x for x in self.parse(
                self.__whois.getRegistrarsByZone(zone)) if not x['hidden']]
            [ x.__setitem__('url', self._rewriteUrl(x['url'])) for x in ret ]
            if sort:
                ret = sorted(ret, None, lambda x: x['handle'])
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def getCertificationsForRegistrar(self, reg_id):
        cert_mgr = self.__admin.getCertificationManager()
        certs = cert_mgr.getCertificationsByRegistrar(reg_id)
        return certs

    def getGroups(self):
        group_mgr = self.__admin.getGroupManager()
        groups = group_mgr.getGroups()
        return groups
    
    def getTechnologyGroups(self):
        if not self.technologies:
            return []
        groups = self.getGroups()
        return [group for group in groups if group.name in whois.conf.get('registrars', 'technologies')]

    def getRegistrarIdsForGroup(self, group_id):
        group_mgr = self.__admin.getGroupManager()
        memberships = group_mgr.getMembershipsByGroup(group_id)
        # Only return active registrars in the group (with no toDate).
        return [mem.registrar_id for mem in memberships if mem.toDate.year == 0]

    def getCertificationEvalFileForRegistrar(self, reg_id):
        """ Obtains a certification evaluation file of a certification with the
            biggest "fromDate" for a registrar.

            Args:
                reg_id: Long. Identifier of the registrar we are interested in.
            Returns:
                A tuple of (ccReg.FileInfo, file contents).
        """
        cert_mgr = self.__admin.getCertificationManager()
        try:
            certs = cert_mgr.getCertificationsByRegistrar(reg_id)
        except self.Registry.Registrar.InvalidValue:
            raise whois.WhoisInvalidIdentifier("Invalid registrar id provided!")
        try:
            today = datetime.date.today()
            active_certs = [cert for cert in certs if
                _corba_date_to_python_date(cert.fromDate) <= today and 
                _corba_date_to_python_date(cert.toDate) >= today]
            newest_cert = max(active_certs, key=lambda x: x.fromDate)
        except ValueError:
            raise whois.WhoisInvalidIdentifier(
                "Registrar with id %i does not have a certification!" % reg_id)
        file_mgr = self.getCorbaObject(
            self.rootContext, 'FileManager', 'FileManager')
        try:
            info = file_mgr.info(newest_cert.evaluation_file_id)
        except ccReg.FileManager.IdNotFound:
            raise whois.WhoisInvalidIdentifier(
                "Requested file not found!")
        f = file_mgr.load(newest_cert.evaluation_file_id)
        body = ""
        while 1:
            part = f.download(102400) # 100kBytes
            if part:
                body = "".join((body, part))
            else:
                break
        return (info, body)

    # def getRegistrar(self, reg_id):
    #     try:
    #         reg = self.__admin.getRegistrarById(reg_id)
    #     except Registry.Registrar.Certification.InvalidValue:
    #         raise whois.WhoisInvalidIdentifier("Invalid registrar id provided!")
    #     return reg

    def deepDomainInfo(self, domain, handles = {}):
        d = self.domainInfo(domain, handles) or {}
        if d:
            contact = self.deepContactInfo(d['registrantHandle'], handles) or {} # owner contact
            del(d['registrantHandle'])
            d['registrant'] = contact

            registrar = self.registrarInfo(d['registrarHandle'], handles) or {} # registrar
            del(d['registrarHandle'])
            d['registrar'] = registrar

            updateRegistrar = self.registrarInfo(d['updateRegistrarHandle'], handles) or {} # update registrar
            del(d['updateRegistrarHandle'])
            d['updateRegistrar'] = updateRegistrar

            createRegistrar = self.registrarInfo(d['createRegistrarHandle'],  handles) or {} # create registrar
            del(d['createRegistrarHandle'])
            d['createRegistrar'] = createRegistrar

            nsset = self.deepNSSetInfo(d['nssetHandle'], handles) or {} # nsset
            del(d['nssetHandle'])
            d['nsset'] = nsset

            keyset = self.deepKeySetInfo(d['keysetHandle'], handles) or {} # keyset
            del(d['keysetHandle'])
            d['keyset'] = keyset

            a = [] # admins
            for admin in d['admins']:
                ax = self.deepContactInfo(admin, handles)
                if ax:
                    a.append(ax)
            del(d['admins'])
            d['admins'] = a

            t = [] # temporary contacts
            for temp in d['temps']:
                tx = self.deepContactInfo(temp, handles)
                if tx:
                    t.append(tx)
            del(d['temps'])
            d['temps'] = t

        return d

    def deepContactInfo(self, contact, handles = {}):
        c = self.contactInfo(contact, handles) or {}
        if c:
            registrar = self.registrarInfo(c['registrarHandle'], handles) or {} # registrar
            del(c['registrarHandle'])
            c['registrar'] = registrar

            updateRegistrar = self.registrarInfo(c['updateRegistrarHandle'], handles) or {} # update registrar
            del(c['updateRegistrarHandle'])
            c['updateRegistrar'] = updateRegistrar

            createRegistrar = self.registrarInfo(c['createRegistrarHandle'], handles) or {} # create registrar
            del(c['createRegistrarHandle'])
            c['createRegistrar'] = createRegistrar
        return c

    def deepNSSetInfo(self, nsset, handles = {}):
        n = self.nssetInfo(nsset, handles) or {}
        if n:
            registrar = self.registrarInfo(n['registrarHandle'], handles) or {} # registrar
            del(n['registrarHandle'])
            n['registrar'] = registrar

            updateRegistrar = self.registrarInfo(n['updateRegistrarHandle'], handles) or {} # update registrar
            del(n['updateRegistrarHandle'])
            n['updateRegistrar'] = updateRegistrar

            createRegistrar = self.registrarInfo(n['createRegistrarHandle'], handles) or {} # create registrar
            del(n['createRegistrarHandle'])
            n['createRegistrar'] = createRegistrar

            a = [] # admins
            for admin in n['admins']:
                ax = self.deepContactInfo(admin, handles)
                if ax:
                    a.append(ax)
            del(n['admins'])
            n['admins'] = a
        return n

    def deepKeySetInfo(self, keyset, handles = {}):
        k = self.keysetInfo(keyset, handles) or {}
        if k:
            registrar = self.registrarInfo(k['registrarHandle'], handles) or {} # registrar
            del(k['registrarHandle'])
            k['registrar'] = registrar

            updateRegistrar = self.registrarInfo(k['updateRegistrarHandle'], handles) or {} # update registrar
            del(k['updateRegistrarHandle'])
            k['updateRegistrar'] = updateRegistrar

            createRegistrar = self.registrarInfo(k['createRegistrarHandle'], handles) or {} # create registrar
            del(k['createRegistrarHandle'])
            k['createRegistrar'] = createRegistrar

            a = [] # admins
            for admin in k['admins']:
                ax = self.deepContactInfo(admin, handles)
                if ax:
                    a.append(ax)
            del(k['admins'])
            k['admins'] = a
            
            
        return k

    def checkHandle(self, handle, handles = {}):
        'Check if hande is valid type.'
        try:
            if isinstance(handle, types.UnicodeType):
                handle = handle.encode('utf-8')
            ret = self.parse(self.__admin.checkHandle(handle))
        except:
            #BAD_PARAM: CORBA.BAD_PARAM(omniORB.BAD_PARAM_WrongPythonType, CORBA.COMPLETED_NO)
            #ex = sys.exc_info()
            #sys.exc_clear()
            #self.invalid_input_type = '%s: %s'%(ex[0], ex[1])
            self.invalid_input_type = True
            self.errors.append(get_exception())
            ret = None
        return ret

    def PublicRequestType(self, action_type, method): 
#        RT_EPP, ///< Request was created by registrar through EPP
#        RT_AUTO_PIF, ///< Request for automatic answer created through PIF
#        RT_EMAIL_PIF, ///< Request waiting for autorization by signed email
#        RT_POST_PIF ///< Request waiting for autorization by checked letter
        action_names = {
            'authinfo': 'AUTHINFO',
            'block_transfer': 'BLOCK_TRANSFER',
            'block_changes': 'BLOCK_CHANGES',
            'unblock_transfer': 'UNBLOCK_TRANSFER',
            'unblock_changes': 'UNBLOCK_CHANGES',
        }
        method_names = {
            'auto': 'AUTO',
            'signedemail': 'EMAIL',
            'snailmail': 'POST',
        }
        enum_name = 'PRT_' +  action_names[action_type] + '_' + method_names[method] + '_PIF'
        try:
            # fake RT_NONEXISTANT to make it raise exception if key is not in list
            request = getattr(self.Registry.PublicRequest, enum_name)
        except AttributeError:
            request = getattr(self.Registry.PublicRequest, 'PRT_AUTHINFO_AUTO_PIF')
        return request

    def createPublicRequest(self, objectId, type, method, requestReason, email, requestId):
        try:
            if isinstance(email, types.UnicodeType):
                email = email.encode('utf-8')
            if isinstance(requestReason, types.UnicodeType):
                requestReason = requestReason.encode('utf-8')
            return self.__admin.createPublicRequest(
                self.PublicRequestType(type, method), requestReason, email, 
                [objectId], requestId)
        except self.ccReg.Admin.REQUEST_BLOCKED:
            raise whois.WhoisRequestBlocked

    def getPublicRequestPDF(self, requestId, lang):
        return self.__admin.getPublicRequestPDF(requestId, lang)

    def __getStatusList__(self, admin_fnc, lang):
        if not self.__langs.has_key(lang):
            self.errors.append("Unsupported language version '%s'."%lang)
            self.errors.append("Available languages are: %s."%', '.join(self.__langs.keys()))
            return None
        try:
            ret = self.parse(admin_fnc(lang))
        except self.ccReg.Admin.ObjectNotFound:
            ret = None
        except:
            self.errors.append(get_exception())
            ret = None
        return ret

    def getDomainStatusDescList(self, lang):
        return self.__getStatusList__(self.__whois.getDomainStatusDescList, lang)
    def getContactStatusDescList(self, lang):
        return self.__getStatusList__(self.__whois.getContactStatusDescList, lang)
    def getNSSetStatusDescList(self, lang):
        return self.__getStatusList__(self.__whois.getNSSetStatusDescList, lang)
    def getKeySetStatusDescList(self, lang):
        return self.__getStatusList__(self.__whois.getKeySetStatusDescList, lang)

def _corba_date_to_python_date(corba_date):
    res = datetime.date(corba_date.year, corba_date.month, corba_date.day);
    return res


def get_exception():
    'Fetch exception for debugging.'

    import traceback
    
    msg = ['Traceback (most recent call last):']
    ex = sys.exc_info()
    sys.exc_clear()
    for trace in traceback.extract_tb(ex[2]):
        msg.append(' File "%s", line %d, in %s'%(trace[0], trace[1], trace[2]))
        msg.append('    %s'%trace[3])
    msg.append('%s: %s'%(ex[0], ex[1]))
    return '\n'.join(msg)


def write_debug_log(*messages):
    f = open('/tmp/debug_ccregproxy.log', 'a')
    if f:
        f.write(time.strftime('%Y-%m-%d %H:%M:%S\n', time.localtime()))
        for msg in messages:
            f.write(str(msg)+'; ')
        f.write('%s\n'%('-'*30,))
        f.close()
