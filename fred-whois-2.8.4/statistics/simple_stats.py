#!/usr/bin/python
import omniORB
import CosNaming
import ConfigParser
import sys

# setup.py change this line to respect correct path
config = '/etc/fred/whois.conf'



def get_statistic(idl, ior, context, argv=[]):
    'Returns connection True/False and (str)answer'
    # connect corba service
    try:
        omniORB.importIDL(idl, [""])
    except ImportError, msg:
        sys.stderr.write('CORBA ImportError: %s\n'%msg)
        return False, ''
        
    orb = omniORB.CORBA.ORB_init(argv, omniORB.CORBA.ORB_ID)
    try:
        ns = orb.string_to_object(ior)._narrow(CosNaming.NamingContext)
    except (omniORB.CORBA.TRANSIENT, omniORB.CORBA.BAD_PARAM), msg:
        sys.stderr.write('CORBA._narrow error: %s\n'%msg)
        return False, ''
    
    # call service
    try:
        admin = ns.resolve([CosNaming.NameComponent(context, "context"),
                            CosNaming.NameComponent("WebWhois", "Object")])
    except:
        sys.stderr.write('CosNaming error: %s\n'%sys.exc_info()[0])
        return False, ''
    
    ccReg = sys.modules.get("ccReg")
    if ccReg:
        admin._narrow(ccReg.Admin)
        try:
            body = str(admin.getDomainCount('0.2.4.e164.arpa'))\
                    +'|'+str(admin.getEnumNumberCount())\
                    +'|'+str(admin.getDomainCount('cz'))\
                    +'|'+str(admin.getSignedDomainCount('cz'))
        except (omniORB.CORBA.TRANSIENT, omniORB.CORBA.BAD_PARAM), msg:
            sys.stderr.write('CORBA.(getDomainCount | getEnumNumberCount) '
                    'error: %s\n'%msg)
            return False, ''
    else:
        sys.stderr.write('Module error: Module ccReg missing.\n')
        return False, ''
    
    return True, body


    
def main(argv):
    # load configuration
    conf = ConfigParser.ConfigParser()
    if not conf.read(config):
        print "Configuration file (%s) not found - using default values."\
                % config

    # set default values
    ior = 'corbaname::localhost'
    idl = '/usr/local/share/idl/fred/ccReg.idl'
    context = 'fred'
    stat_file = '/tmp/statictic.log'

    try:
        if conf.has_option('corba', 'host'):
            ior = 'corbaname::' + conf.get('corba', 'host')
        if conf.has_option('corba', 'idl'):
            idl = conf.get('corba', 'idl')
        if conf.has_option('corba', 'context'):
            context = conf.get('corba', 'context')
        if conf.has_option('corba', 'statistic_path'):
            stat_file = conf.get('corba', 'statistic_path')
    except ConfigParser.NoOptionError, msg:
        sys.stderr.write('ConfigParser error: %s\n'%msg)
        return

    is_ok, answer = get_statistic(idl, ior, context, argv)
    # print answer
    if is_ok:
        open(stat_file, 'w').write(answer)

if __name__ == '__main__':
    main(sys.argv)
