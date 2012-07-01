#!/usr/bin/python
# -*- coding: utf-8 -*-
""" Captcha.Base

Base class for all types of CAPTCHA tests. All tests have one or
more solution, determined when the test is generated. Solutions
can be any python object,

All tests can be solved by presenting at least some preset number
of correct solutions. Some tests may only have one solution and require
one solution, but other tests may require N correct solutions of M
possible solutions.
"""
#
# PyCAPTCHA Package
# Copyright (C) 2004 Micah Dowty <micah@navi.cx>
#
import logging, traceback
import random, string, time, os, os.path, sys, cPickle as pickle

__all__ = ["BaseCaptcha", "Factory", "PersistentFactory"]

# fix the promblem of overwriting captcha tmp files between users
random.seed()


def randomIdentifier(alphabet = string.ascii_letters + string.digits,
                     length = 24):
    return "".join([random.choice(alphabet) for i in xrange(length)])


class BaseCaptcha(object):
    """Base class for all CAPTCHA tests"""
    # Subclasses can override these to set the solution criteria
    minCorrectSolutions = 1
    maxIncorrectSolutions = 0

    def __init__(self):
        self.solutions = []
        self.valid = True

        # Each test has a unique identifier, used to refer to that test
        # later, and a creation time so it can expire later.
        self.id = randomIdentifier()
        self.creationTime = time.time()

    def addSolution(self, solution):
        self.solutions.append(solution)

    def testSolutions(self, solutions):
        """Test whether the given solutions are sufficient for this CAPTCHA.
           A given CAPTCHA can only be tested once, after that it is invalid
           and always returns False. This makes random guessing much less effective.
           """
        if not self.valid:
            return False
        self.valid = False

        numCorrect = 0
        numIncorrect = 0

        for solution in solutions:
            if solution in self.solutions:
                numCorrect += 1
            else:
                numIncorrect += 1

        return numCorrect >= self.minCorrectSolutions and \
               numIncorrect <= self.maxIncorrectSolutions


class Factory(object):
    """Creates BaseCaptcha instances on demand, and tests solutions.
       CAPTCHAs expire after a given amount of time, given in seconds.
       The default is 15 minutes.
       """
    def __init__(self, lifetime=60*15):
        self.lifetime = lifetime
        self.storedInstances = None

    def new(self, cls, *args, **kwargs):
        """Create a new instance of our assigned BaseCaptcha subclass, passing
           it any extra arguments we're given. This stores the result for
           later testing.
           """
        self.clean()
        inst = cls(*args, **kwargs)
        try:
            o = file(os.path.join(self.storedInstances, inst.id), "w")
            pickle.dump(inst, o)
            o.close()
        except IOError, msg:
            logging.error('CaptchaWhois/Base.py:Factory.new() IOError: %s' % msg)
        return inst

    def get(self, id):
        """Retrieve the CAPTCHA with the given ID. If it's expired already,
           this will return None. A typical web application will need to
           new() a CAPTCHA when generating an html page, then get() it later
           when its images or sounds must be rendered.
           """
        if id is None or os.path.basename(id) != id:
            logging.info("CaptchaWhois/Base.py:Factory.get() invalid id: '%s'" % id)
            return None

        try:
            i = file(os.path.join(self.storedInstances, id), "r")
            inst = pickle.load(i)
            i.close()
        except:
            logging.info("CaptchaWhois/Base.py:Factory.get() %s" % traceback.format_exc(0))
            return None
        return inst

    def remove(self, id):
        """Remove the CAPTCHA with the given ID."""
        # protection against injection
        if id is None or os.path.basename(id) != id:
            return
        
        fn = os.path.join(self.storedInstances, id)
        try:
            os.unlink(fn)
        except OSError, e:
            sys.stderr.write('OSError: %s\n'%e)
            

    def clean(self):
        """Removed expired tests"""
        # delete all files older than # minuts
        ## os.system('find %s -type f -mmin +%d | xargs rm'%(self.storedInstances, self.lifetime/60))


    def test(self, id, solutions):
        """Test the given list of solutions against the BaseCaptcha instance
           created earlier with the given id. Returns True if the test passed,
           False on failure. In either case, the test is invalidated. Returns
           False in the case of an invalid id.
           """
        inst = self.get(id)
        if not inst:
            return False
        result = inst.testSolutions(solutions)
        return result


class PersistentFactory(Factory):
    """A simple persistent factory, for use in CGI or multi-process environments
       where the state must remain across python interpreter sessions.
       This implementation uses the 'shelve' module.
       """
    def __init__(self, filename, lifetime=60*15):
        Factory.__init__(self, lifetime)
        self.storedInstances = filename
        if not os.path.isdir(filename):
            try:
                os.unlink(filename)
            except OSError:
                pass
            os.mkdir(filename)
                                   
### The End ###
