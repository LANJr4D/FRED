#!/usr/bin/env python
# vim:set ts=4 sw=4:

"""
This script returns:
	0 if all nameservers contain record for the domain.
	1 if any of nameservers does not contain record for the domain.
	2 if usage or other error occurs.

To stderr go error messages and to stdout go nameservers separated by space
which don't contain appropriate records. The list of domains, which are not
present in nameserver, are glued to nameserver's fqdn separated by commas.
From stdin is read a list of domains for which a record must be present at
nameserver.
"""

import sys
import dns.resolver
import dns.message
import dns.query

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
	domains = sys.stdin.read().strip().split(' ')
	# dictionary of renegades
	renegades = {}
	error = False
	# process nameserver records
	for nsarg in sys.argv[1:]:
		# get ip addresses of nameserver
		(ns, addrs) = get_ns_addrs(nsarg)
		for domain in domains:
			# create common query for all nameservers
			query = dns.message.make_query(domain, "SOA")
			message = None
			for addr in addrs:
				try:
					message = dns.query.udp(query, addr, 3)
					break
				except dns.exception.Timeout, e:
					pass
			# did we got response for any of ip addresses of nameserver ?
			if not message:
				error = True
			elif len(message.answer) == 0:
				if not renegades.has_key(ns):
					renegades[ns] = []
				renegades[ns].append(domain)
	if renegades:
		for ns in renegades:
			domain_list = renegades[ns]
			sys.stdout.write(ns)
			for fqdn in domain_list:
				sys.stdout.write(",%s" % fqdn)
			sys.stdout.write(" ")
		return 1
	if error:
		return 2
	return 0

if __name__ == "__main__":
	try:
		ret = main()
	# catch all clause
	except Exception, e:
		sys.stderr.write(e.__str__())
		sys.exit(2)
	sys.exit(ret)
