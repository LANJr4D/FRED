#!/bin/sh
#
# The script accepts arguments: destroy and create. Destroy target will remove
# objects needed for testing from database. Do not do that because you cannot
# simply create them again because of protection period.
# Create target is called in all cases when target is not destroy and will
# create all objects needed for unittests in database.
#

if [ $# -eq 1 ]
then
  if [ $1 = "destroy" ]
  then
    echo "Are you sure, you want to remove all test objects from database? [y/n]"
    read INPUT
    if [ $INPUT = "y" -o $INPUT = "Y" ]
    then
      # test_genzone
      fred_client -xd 'delete_domain  pfug-domain.cz'
      fred_client -xd 'delete_nsset   NSSID:PFUG-NSSET'
      fred_client -xd 'delete_contact CID:PFUG-CONTACT'
      # test_techcheck
      fred_client -xd 'delete_domain  nic.cz'
      fred_client -xd 'delete_nsset   NSSID:PFUT-NSSET'
      fred_client -xd 'delete_contact CID:PFUT-CONTACT'
    fi
    exit 0
  elif [ $1 = "create" ]
  then
    # this is for test_genzone
    fred_client -xd 'create_contact CID:PFUG-CONTACT "Jan Ban" info@mail.com Street Brno 123000 CZ'
    fred_client -xd 'create_nsset NSSID:PFUG-NSSET ((ns.pfug-domain.cz (217.31.206.129, 2001:db8::1428:57ab)), (ns.pfug-domain.net)) CID:PFUG-CONTACT'
    fred_client -xd 'create_domain pfug-domain.cz CID:PFUG-CONTACT nsset=NSSID:PFUG-NSSET'
    # this is for test_techcheck
    fred_client -xd 'create_contact CID:PFUT-CONTACT "Jan Ban" info@mail.com Street Brno 123000 CZ'
    fred_client -xd 'create_nsset NSSID:PFUT-NSSET ((a.ns.nic.cz (217.31.205.180)), (c.ns.nic.cz (193.29.206.1))) CID:PFUT-CONTACT'
    fred_client -xd 'create_domain nic.cz CID:PFUT-CONTACT NSSID:PFUT-NSSET'
    exit 0
  fi
fi

echo "Usage: create_environment.sh [create|destroy]"
exit 1

