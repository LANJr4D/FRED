#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
    Logging framework.
"""

import corbarecoder as recoder
import dummylogger
import omniORB
import traceback
import datetime
import logging

__all__ = ["Logger", "LogRequest", 
            "LoggingException", "service_type_webadmin"]

# Constant representing web admin service type (hardcoded in db).
service_type_webadmin = 4

"""
*** Module initialization section. ***
"""



"""
*** Class definitions ***
"""


class Logger(object):
    """ 
    Logger for a session.

    Example usage (in nicms):
from apps.nicommon.utils import get_logger
logger = get_logger()
props = [['a', 3], ['b', 'Example'], ['c', 1, True], ['d', 4, True]]
req = logger.create_request("127.0.0.1", "MojeID", "UserChange", props)
req.result = 'Success'
req.close()
---
from apps.nicommon.utils import get_logger
logger = get_logger()
session_id = logger.start_session(1, "username")
props = [['a', 3], ['b', 'Example'], ['c', 1, True], ['d', 4, True]]
req = logger.create_request("127.0.0.1", "MojeID", "UserChange", props, session_id=session_id)
req.result = 'Success'
out_props = [['e', 3], ['f', 'Example'], ['g', 1], ['h', 4, True]]
req.close(properties = out_props)
logger.close_session(session_id)

    Usually, when logging some action, it should look like:

from apps.nicommon.utils import get_logger
logger = get_logger()
props = [['a', 3], ['b', 'Example'], ['c', 1, True], ['d', 4, True, True]]
req = logger.create_request("127.0.0.1", "EPP", "NSsetUpdate", props)
try:
    PERFORM_ACTION()
    req.result = 'Success'
ecxept KnownException, e:
    req.result = 'Fail'
finally:
    req.close()

    Attributes:
        request_types: Dictionary containing ((service string name, request type string name) -> 
            (service id int, request type id int) mapping.
        dao: Data Access Object. That's where we get our data from / send them 
            to.
    """

    def __init__(self, dao, corba_module):
        """Inits Logger.

            Arguments:
                dao: Data Access Object for the logger. 
                    That's where we get our data from / send them to.
                    Generally it's a Corba Logger object for normal use and 
                    mock object for unit tests.

        """
        self.dao = dao
        self.corba_module = corba_module
        
        self.request_type_codes = {}
        self.result_codes = {}
        self.object_types = {}
        #self.service_codes = {}
        self._load_all_type_codes()
        
        # Default result code for each service (aka unexpected error) - for each service, there will
        # be some default result code, which will be set in constructor of request, so when
        # there will be unexpecded error, in try: finally: will be req.close() which will close it
        # with this default result.
        # Note: If useful, this should go to backend and not be specified here
        self.default_results = {
            'MojeID': 'Error',
            'EPP': 'CommandFailed',
            'WebAdmin': 'Error',
        } 

    def start_session(self, user_id, username):
        """Starts a new logging session.

            Arguments:
                userid: Int. Registrar id for EPP session or user id for other apps.
                username: String. Registrar Handle for EPP session or username for other apps.
        """
        if not isinstance(username, basestring):
            username = str(username)
        else:
            username = recoder.u2c(username)

        logging.debug("<Logger %s> createSession %s %s" % (id(self), user_id, username))
        session_id = self.dao.createSession(user_id, username)
        if session_id == 0:
            raise LoggingException(
                """Logging session failed to start with args: (%s).""" % username)
        return session_id

    def create_request(self, source_ip, service_name, request_type_name, 
                       properties=None, references = None, session_id=None, 
                       default_result=None, content=''):
        """
            Creates a request object on the server.
            Returns a new LogRequest object or None on error.
        """
        if default_result is None:
            default_result = self.default_results.get(service_name)
            if default_result is None:
                raise LoggingException('Service "%s" doesn\'t have specified default result code!' % service_name)
        request_id = self._server_create_request(
            source_ip, content, service_name, request_type_name, properties, references, session_id)
        log_request = LogRequest(self, request_id, service_name, request_type_name, default_result)
        return log_request

    def create_dummy_request(self, *args, **kwargs):
        return dummylogger.DummyLogRequest(*args, **kwargs)

    def close_session(self, session_id):
        """ 
            Tells the server to close this logging session.
            Returns True iff session closed successfully.
        """
        if session_id is None:
            raise LoggingException("Error in close_session: session_id cannot be None.")
        logging.debug("<Logger %s> closeSession %s" % (id(self), session_id))
        self.dao.closeSession(session_id)

    def _load_all_type_codes(self):
        """
            Loads all service types and request types to attributes 
            request_type_codes and service_codes.
        """
        logging.debug("<Logger %s> getServices" % id(self))
        service_type_list = self.dao.getServices()
        for service_type in service_type_list:
            self._load_request_type_codes(service_type)
            self._load_result_codes(service_type)
        self._load_object_types()

    def _load_request_type_codes(self, service_type):
        """
            Request ([service name][request type name] -> (service int code, request type int code) mapping from
            the server. 
        """
        logging.debug("<Logger %s> getRequestTypesByService %s" % (id(self), service_type.id))
        request_type_list = self.dao.getRequestTypesByService(service_type.id)
        for request_type in request_type_list:
            if self.request_type_codes.get(service_type.name) is None:
                self.request_type_codes[service_type.name] = {}
            self.request_type_codes[service_type.name][request_type.name] = (service_type.id, request_type.id)

    def _load_result_codes(self, service_type):
        """
            Request ([service name][result name] -> (service int code, result int code) mapping from
            the server. 
        """
        logging.debug("<Logger %s> getResultCodesByService %s" % (id(self), service_type.id))
        result_codes_list = self.dao.getResultCodesByService(service_type.id)
        for result_code in result_codes_list:
            if self.result_codes.get(service_type.name) is None:
                self.result_codes[service_type.name] = {}
            self.result_codes[service_type.name][result_code.name] = result_code.result_code

    def _load_object_types(self):
        #logging.debug("<Logger %s> getObjectTypes" % id(self))
        object_type_list = []#self.dao.getObjectTypes()
        for object_type in object_type_list:
            self.object_types[object_type.name] = object_type.id

    def _convert_nested_to_str(self, value):
        """ Converts nested lists (or tuples) of objects to nested lists of
            strings. """
        if isinstance(value, (datetime.date, datetime.datetime)):
            return value.isoformat()
        if not isinstance(value, list) and not isinstance(value, tuple):
            return str(value)
        return [self._convert_nested_to_str(item) for item in value]

    def _convert_property(self, name, value, child):
        """
            Converts input pareametrs to RequestProperty
        """
        if not isinstance(name, basestring):
            name = str(name)
        if not isinstance(value, basestring):
            value = str(self._convert_nested_to_str(value))
        name = recoder.u2c(name)
        value = recoder.u2c(value)
        prop = self.corba_module.RequestProperty(name, value, False, child)
        return prop

    def convert_properties(self, properties):
        """
            Convert python list of [name, value, output, child] to list of RequestProperties.
            (Output and child are optional)
        """
        converted_properties = []
        if properties:
            for prop in properties:
                name = prop[0]
                value = prop[1]
                child = prop[2] if len(prop) > 2 else False
                converted_property = self._convert_property(name, value, child)
                converted_properties.append(converted_property)
        return converted_properties    

    def convert_references(self, references):
        converted_references = []
        if references:
            for ref in references:
                #object_type = self.object_types[ref[0]]
                object_type = ref[0] # TODO: change to previous line when
                converted_references.append(self.corba_module.ObjectReference(object_type, ref[1]))
        return converted_references

    def _server_create_request(self, source_ip, content, service_name, request_type_name, 
                                properties, references, session_id):
        """
            Ask the server to create a new logging request.
            Returns request id iff request has been created successfully.
        """
        if content is None:
            content = ""
        if session_id is None:
            session_id = 0

        converted_properties = self.convert_properties(properties)
        converted_references = self.convert_references(references)
        try:
            service_code, request_type_code = self.request_type_codes[service_name][request_type_name]
        except KeyError:
            raise ValueError(
                "Invalid service and/or request type '%s'-'%s'. Original exception: %s." %
                (service_name, request_type_name, traceback.format_exc()))
        logging.debug("<Logger %s> createRequest %s %s %s %s %s %s %s" % (
            id(self), source_ip, service_code, content,
            converted_properties, converted_references, request_type_code, session_id
        ))
        request_id = self.dao.createRequest(
            source_ip, service_code, content, converted_properties, converted_references, request_type_code, session_id)
        if request_id == 0:
            raise LoggingException(
                "Failed to create a request with args: (%s, %s, %s, %s, %s, %s)." %
                (source_ip, content, service_name, request_type_name, properties, session_id))
        return request_id


class LogRequest(object):
    """ 
        A request for logging. Use one LogRequest object for one request to be 
        logged and use the update method to log the necessary information for 
        this request.

        Should NOT be instantiated directly; use Logger.create_request.

        Example usage: 
            req = session_logger.create_request(...)
            req.update("example_property", 132)
            ...
            req.close("")

        Arguments:
            dao: Data Access Object for logging. Usually Corba Logger object.
            request_id: Integer identifier of the request.
            throws_exceptions: Boolean. True iff Logger throws 
                exceptions.
            log: When we encounter an error, this function is called with 
                a string description of what happened.
    """

    def __init__(self, logger, request_id, service, request_type, default_result):
        self.logger = logger
        self.dao = logger.dao
        self.request_id = request_id
        self.service = service
        self.request_type = request_type
        self.result = default_result

    def close(self, result=None, content="", properties=None, references=None, session_id=None):
        """ Close this logging request. Warning: the request cannot be changed
            anymore after closing. """
        if result is not None:
            self.result = result
        result_code = self.logger.result_codes[self.service][self.result]
        converted_properties = self.logger.convert_properties(properties)
        converted_references = self.logger.convert_references(references)
        if not session_id:
            session_id = 0
        logging.debug("<Logger %s> closeRequest %s %s %s %s %s %s" % (
            id(self), self.request_id, content, converted_properties, converted_references, result_code, session_id
        ))
        self.dao.closeRequest(self.request_id, content, 
                              converted_properties, converted_references, result_code, session_id)


class LoggerFailSilent(Logger):
    """ Logger that does not raise exceptions on failure. 
    """
    def __init__(self, *args, **kwargs):
        Logger.__init__(self, *args, **kwargs)

    def start_session(self, *args, **kwargs):
        try:
            return Logger.start_session(self, *args, **kwargs)
        except LoggingException:
            pass
        except omniORB.CORBA.SystemException:
            #TODO: Re-think somehow?
            # I have to reraise it, so that I know in ADIF.login that I should
            # hide away the logger...
            raise
        except Exception, e:
            logging.error('Logger failed to error during start_session: %s.', e)

    def create_request(self, source_ip, service_name, request_type_name, 
                       properties=None, references = None, session_id=None, 
                       default_result=None, content=''):
        try:
            if default_result is None:
                default_result = self.default_results.get(service_name)
                if default_result is None:
                    raise LoggingException('Service "%s" doesn\'t have specified default result code!' % service_name)
            
            properties = properties or []
            request_id = self._server_create_request(
                source_ip, content, service_name, request_type_name, properties, references, session_id)
            log_request = LogRequestFailSilent(self, request_id, service_name, request_type_name, default_result)
            return log_request
        except Exception, e:
            logging.error('Logger failed to error during create_request: %s.', e)
            return dummylogger.DummyLogRequest()

    def close_session(self, *args, **kwargs): 
        try:
            Logger.close_session(self, *args, **kwargs)
        except Exception:
            logging.error('Logger failed to error during close_session: %s.', e)


class LogRequestFailSilent(LogRequest):
    """ LogRequest that does not raise exceptions on failure (to be used with
        LoggerFailSilent). """
    def __init__(self, *args, **kwargs):
        LogRequest.__init__(self, *args, **kwargs)

    def close(self, *args, **kwargs):
        try:
            LogRequest.close(self, *args, **kwargs)
        except Exception, e:
            logging.error('Logger failed to error during request.close: %s.', e)


class LoggingException(Exception):
    """ Generic exception thrown by this logging framework. """
    def __init__(self, value):
        Exception.__init__(self, value)
        self.value = value

    def __str__(self):
        return repr(self.value)
