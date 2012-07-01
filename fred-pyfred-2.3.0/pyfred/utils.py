#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
This module gathers various utility functions used in other pyfred's modules.
"""

import time, re
import sys, os, fcntl, select, time, popen2, signal

def strtime(timestamp = 0):
	"""
Convert timestamp to its string reprezentation if argument is not given
of has zero value. Reprezentation of current time is returned.
	"""
	if timestamp == 0:
		timestamp = time.time()
	tm = time.localtime(timestamp)
	res = time.strftime("%Y-%m-%dT%H:%M:%S", tm)
	# ignore seconds and take daylight savings into account
	tzoff = time.altzone // 60
	if tzoff == 0:
		# zulu alias gmt alias utc time
		return res + "Z"
	elif tzoff > 0:
		res += "+"
	else:
		res += "-"
		tzoff = abs(tzoff)
	# convert tz offset in seconds in HH:MM format
	return "%s%02d:%02d" % (res, tzoff // 60, tzoff % 60)

def isExpired(timestamp):
	"""
Returns True if timestamp is older than curent timestamp, otherwise False.
	"""
	if timestamp < time.time():
		return True
	return False

def ipaddrs2list(ipaddrs):
	"""
Utility function for converting a string containing ip addresses
( e.g. {ip1,ip2,ip3} ) to python list of theese ip adresses. If the
string of ip adresses contains no ip adresses ( looks like {} ) then
empty list is returned.
	"""
	list = ipaddrs.strip("{}").split(",")
	if list[0] == "": return []
	return list

class domainClass(object):
	"""
Definition of results of domain classification.
	"""
	CLASSIC = 0
	ENUM = 1
	BAD_ZONE = 2
	LONG = 3
	INVALID = 4

def classify(fqdn):
	"""
Classify domain name in following categories: classic domain, enum domain,
bad zone, too long, invalid name. The valid zones are hardcoded in routine.
	"""
	if len(fqdn) > 63:
		return domainClass.INVALID
	p = re.compile("^([a-z0-9]([-a-z0-9]*[a-z0-9])?\.)+([a-z]{2,10})$",
			re.IGNORECASE)
	if not p.match(fqdn):
		return domainClass.INVALID
	if re.compile("^.*\.cz$", re.IGNORECASE).match(fqdn):
		if fqdn.count(".") > 1:
			return domainClass.LONG
		return domainClass.CLASSIC
	if re.compile("^.*\.0\.2\.4\.(c\.)?e164\.arpa$", re.IGNORECASE).match(fqdn):
		return domainClass.ENUM
	return domainClass.BAD_ZONE

def isInfinite(datetime):
	"""
Decide if the date is invalid. If it is invalid, it is counted as infinite.
	"""
	if datetime.date.month < 1:
		return True
	if datetime.date.day < 1:
		return True
	return False

def makeNonBlocking(fd):
    """
    Set non-blocking attribute on file.
    """
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    try:
        fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NDELAY)
    except AttributeError:
        fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.FNDELAY)


def runCommand(id, cmd, stdin, logger):
    """
    Run command in non-blocking manner.
    """
    # run the command
    child = popen2.Popen3(cmd, True)
    logger.log(logger.DEBUG, "<%d> Running command '%s', pid %d." %
            (id, cmd, child.pid))
    if (stdin):
        child.tochild.write(stdin)
    child.tochild.close()
    outfile = child.fromchild 
    outfd = outfile.fileno()
    errfile = child.childerr
    errfd = errfile.fileno()
    makeNonBlocking(outfd)
    makeNonBlocking(errfd)
    outdata = errdata = ''
    outeof = erreof = 0
    for round in range(8):
        # wait for input at most 1 second
        ready = select.select([outfd,errfd], [], [], 1.0)
        if outfd in ready[0]:
            outchunk = outfile.read()
            if outchunk == '':
                outeof = 1
            else:
                outdata += outchunk
        if errfd in ready[0]:
            errchunk = errfile.read()
            if errchunk == '':
                erreof = 1
            else:
                errdata += errchunk
        if outeof and erreof: break
        logger.log(logger.WARNING, "<%d> Output of command not ready, "
                "waiting (round %d)" % (id, round))
        time.sleep(0.3) # give a little time for buffers to fill

    child.fromchild.close()
    child.childerr.close()

    status = os.waitpid(child.pid, os.WNOHANG)

    if status[0] == 0:
        time.sleep(1)
        logger.log(logger.WARNING, "<%d> Child doesn't want to exit, TERM signal sent." % (id))
        os.kill(child.pid, signal.SIGTERM)
        time.sleep(1.2) # time to exit
        status = os.waitpid(child.pid, os.WNOHANG)

        if status[0] == 0:
            logger.log(logger.WARNING, "<%d> Child doesn't want to die, KILL signal sent." % (id))
            os.kill(child.pid, signal.SIGKILL)
            time.sleep(1.2) # time to exit
            status = os.waitpid(child.pid, os.WNOHANG)

    stat = 2 # by default assume error
    if outeof and erreof and (status[0] == child.pid) and os.WIFEXITED(status[1]):
        stat = os.WEXITSTATUS(status[1])

    return stat, outdata, errdata

