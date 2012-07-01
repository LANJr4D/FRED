#!/usr/bin/env python
# vim:set ts=4 sw=4:

"""
This script returns:
	0 if the nameservers are heterogenous
	1 if the nameservers are not heterogenous
	2 if usage or other error occurs.

To stderr go debug and error messages, to stdout goes nothing.
"""

import sys, commands, re, dns.resolver

debug = False
fpdnsbin = "fpdns"

def dbg_print(msg):
	"""
Routine which outputs msg to stdout only if global debug is True, otherwise
does nothing.
	"""
	if debug:
		sys.stderr.write(msg + '\n')

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
	# process nameserver records
	nspars = ''
	for nsarg in sys.argv[1:]:
		# get ip addresses of nameserver
		(ns, addrs) = get_ns_addrs(nsarg)
		if addrs:
			nspars += ' ' + addrs[0] # XXX try first address - not exact ...
		else:
			nspars += ' ' + ns
	status, output = commands.getstatusoutput("%s %s" % (fpdnsbin, nspars))
	dbg_print("Status of fpdns: %d" % status)
	dbg_print("Output of fpdns: %s" % output)
	if status != 0:
		raise Exception("fpdns exited with failure (rc=%d)" % status)
	pattern = re.compile(r"^fingerprint \([^)]+\): (.+)$")
	software = None
	retval = 1 # default is failure
	for line in output.split('\n'):
		label = pattern.search(line)
		if not label:
			dbg_print("No match")
			# if we didn't recognize dns server, assume it is different than the
			# others
			retval = 0
			continue
		dns_soft = label.groups()[0].strip()
		dbg_print("Matched item: %s" % dns_soft)
		if not software:
			software = dns_soft
		else:
			if software != dns_soft or dns_soft == "No match found":
				# two different softwares were found! Exiting
				retval = 0
	return retval


if __name__ == "__main__":
	try:
		ret = main()
	# catch all clause
	except Exception, e:
		sys.stderr.write(e.__str__())
		sys.exit(2)
	sys.exit(ret)

