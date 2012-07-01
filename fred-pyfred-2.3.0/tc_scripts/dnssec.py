#!/usr/bin/env python
# vim:set ts=4 sw=4:
"""
Code of techcheck daemon.
"""
import dns.resolver
import dns.message

def countKeyTag(k):
    """
    Count keytag from RRdata of DNSKEY RR according to appendix B of RFC 4034
    """
    sum = k.flags + (k.protocol << 8) + k.algorithm
    for i in range(0,len(k.key)):
        if (i & 1):
            sum += ord(k.key[i])
        else:
            sum += ord(k.key[i]) << 8
    sum += (sum >> 16) & 0xFFFF
    return sum & 0xFFFF
    
def getAllKeys(domain, ip):
    msg_q = dns.message.make_query(domain, "DNSKEY")
    msg_r = dns.query.tcp(msg_q,ip,3)
    return msg_r.answer[0]
