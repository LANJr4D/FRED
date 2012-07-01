#!/usr/bin/env python
# vim:set ts=4 sw=4:

"""
This script returns:
	0 if at least two nameservers are in autonomous systems,
	1 if the previous condition does not hold,
	2 if usage or other error occurs.

To stderr go debug and error messages, to stdout goes nothing.

Autonomous system
    is synonymum for routing domain. The purpose of this test is to ensure,
that if a routing domain including nameserver goes down, another nameserver
can still be reached.
"""

import sys, commands, re
import dns.resolver

debug = False
whoisbin = "whois"

def dbg_print(msg):
	"""
Routine which outputs msg to stdout only if global debug is True, otherwise
does nothing.
	"""
	if debug:
		sys.stderr.write(msg + '\n')

def whois_AS(ip):
	"""
Performs basic whois query on ip address and returns Autonomous system of that
ip address.
	"""
	status, output = commands.getstatusoutput("%s %s" % (whoisbin, ip))
	if status != 0:
		raise Exception("whois program failed (rc=%d)" % status)
	pattern = re.compile(r"^origin:\s*(\S+)$", re.M)
	asys = pattern.search(output)
	# if pattern was not found
	if not asys:
		return None
	return asys.groups()[0]

def get_ns_addrs(args):
	"""
	BEWARE!!! If you change something in this function, don't forget to
	change copies of it in all other tests.
	"""
	ns = args.split(',')[0]
	addrs = args.split(',')[1:]
	if not addrs:
		# get ip addresses of nameserver
		answer = dns.resolver.query(ns)
		for rr in answer:
			addrs.append(rr.__str__())
	return (ns, addrs)

def main():
	if len(sys.argv) < 2:
		sys.stderr.write("Usage error")
		return 2
	# autonomous systems of first nameserver
	as_first = None
	# process nameserver records
	for nsarg in sys.argv[1:]:
		# get ip addresses of nameserver
		(ns, addrs) = get_ns_addrs(nsarg)
		# get AS from whois
		for addr in addrs:
			dbg_print("Whois on ip address %s" % addr)
			as_curr = whois_AS(addr)
			# if it is not RIPE, we cannot say anything about autonomity,
			#    we will return success therefore
			if not as_curr:
				dbg_print("Autonomous system is not known")
				return 0
			dbg_print("IP %s is from autonomous system %s" % (addr, as_curr))
			# if it is first entry, then put it in as_base ...
			if not as_first:
				as_first = as_curr
			# ... otherwise if it is from different routing domain return passed
			elif as_curr != as_first:
				dbg_print("Two different autonomous systems found")
				return 0
	# no two different routing domains were found
	dbg_print("All nameservers are from the same autonomous system")
	return 1


if __name__ == "__main__":
	try:
		ret = main()
	# catch all clause
	except Exception, e:
		sys.stderr.write(e.__str__())
		sys.exit(2)
	sys.exit(ret)
