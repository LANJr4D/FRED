#!/usr/bin/python
# -*- coding: utf-8 -*-
__all__ = ["DummyLogger"]


class DummyLogger(object):
    """
        Dummy Logger. Never logs anything and never
        fails.
        Used to imitate normal logger, when you don't want to log anything (e.g.
        because you don't want to connect via Corba).
    """
    request_type_codes = {}
    result_codes = {}
    object_types = {}
    default_results = {}

    def start_session(self, *args, **kwargs):
        pass

    def create_request(self, *args, **kwargs):
        return DummyLogRequest()

    def create_dummy_request(self, *args, **kwargs):
        return DummyLogRequest()

    def close_session(self, *args, **kwargs): 
        pass


class DummyLogRequest(object):
    def __init__(self, *args, **kwargs):
        self.request_id = 0
        self.service = ''
        self.request_type = ''
        self.result = ''

    def close(self, *args, **kwargs):
        pass
