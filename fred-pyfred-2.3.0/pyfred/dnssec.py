"""
This module gathers various utility functions used in other pyfred's modules.
"""

def countKeyTag(flags, protocol, alg, key):
    """
    Count keytag from RRDATA od DNSKEY RR according to appendix B of RFC 4034
    """
    if alg == 1:
        if (len(key) < 4):
            return 0;
        else:
            return (ord(key[len(key)-4]) << 8) + ord(key[len(key)-3])
    else :
        sum = flags + (protocol<< 8) + alg
        for i in range(0,len(key)):
            if (i & 1):
                sum += ord(key[i])
            else:
                sum += ord(key[i]) << 8
        sum += (sum >> 16) & 0xFFFF
        return sum & 0xFFFF

def countDSRecordDigest(fqdn, flags, protocol, alg, key):
    """
    Count SHA1 digest from fqdn and RRDATA of DNSKEY RR according to RFC 4034
    """
    try:
        import hashlib
        hash = hashlib.sha1()
    except:
        import sha
        hash = sha.sha()
    labels = fqdn.split(".")
    buffer = ""
    for l in labels:
        buffer += chr(len(l)) + l
    buffer += chr(0) + chr(flags >> 8) + chr(flags & 255) + chr(protocol)
    buffer += chr(alg) + key
    hash.update(buffer)
    return hash.hexdigest().upper()
