#!/usr/bin/env python
# vim:set ts=4 sw=4:

"""
This script returns:
	0 if all nameservers answer.
	1 if any of nameservers does not answer.
	2 if usage or other error occurs.

To stderr go error messages and to stdout go nameservers separated by space
which don't answer.  From stdin is read a list of domains for which a record
must be present at nameserver.

The test consists of 4 smaller tests, each of which tries to provoke the
DNS server to send an answer. It is legal, when DNS server doesn't answer
to any of these tests and still can exist, but we are trying to do our best.
"""

import sys
import dns.resolver
import dns.message
import dns.query

DEBUG = False

def debug(msg):
	global DEBUG
	if DEBUG:
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
	domain = sys.stdin.read().strip().split(' ')[0] # try first domain only
	# list of renegades
	renegades = []
	# process nameserver records
	for nsarg in sys.argv[1:]:
		# get ip addresses of nameserver
		try:
			(ns, addrs) = get_ns_addrs(nsarg)
		except dns.resolver.NXDOMAIN, e:
			renegades.append(nsarg)
			continue
		# First try domain query if there is one
		if domain:
			debug('Bound domain exists, trying query for that domain')
			query = dns.message.make_query(domain, "SOA")
			resp = None
			for addr in addrs:
				try:
					resp = dns.query.udp(query, addr, 2)
					break
				except dns.exception.Timeout, e:
					pass
			# did we got response for any of ip addresses of nameserver ?
			if resp:
				continue
		# Second try root nameservers
		debug('Trying query for root nameservers')
		query = dns.message.make_query(".", "ANY")
		resp = None
		for addr in addrs:
			try:
				resp = dns.query.udp(query, addr, 1)
				break
			except dns.exception.Timeout, e:
				pass
		if resp:
			continue
		# Third try weird class query
		debug('Trying weird query CH .')
		query = dns.message.make_query(".", "ANY", "CH")
		resp = None
		for addr in addrs:
			try:
				resp = dns.query.udp(query, addr, 1)
				break
			except dns.exception.Timeout, e:
				pass
		if resp:
			continue
		# Fourth try id of server query
		debug('Trying query for id of server')
		query = dns.message.make_query("id.server.", "ANY", "CH")
		resp = None
		for addr in addrs:
			try:
				resp = dns.query.udp(query, addr, 1)
				break
			except dns.exception.Timeout, e:
				pass
		if resp:
			continue
		# if nothing helped, mark nserver as non-existent
		debug('DNS Server doesn\'t seem to exist')
		renegades.append(ns)
	if renegades:
		for ns in renegades:
			sys.stdout.write("%s " % ns)
		return 1
	return 0

if __name__ == "__main__":
	try:
		ret = main()
	# catch all clause
	except Exception, e:
		sys.stderr.write(e.__str__())
		sys.exit(2)
	sys.exit(ret)
