#!/usr/bin/sh

# DB name is expected to be carpool_<env>
# carpool_live
# carpool_test
# carpool_purpose

if [[ "X$1" = "X" ]]
then
        echo missing DB name
        echo $0 \<DB name\>
        exit 1
fi

IFS='_' read -ra ARRELEMS <<< $1

APIENV=${ARRELEMS[1]}

echo "Configuring database for environment : " $APIENV

psql -d $1 <<SQLINPUT
UPDATE carpoolvote.params SET value='true' WHERE name='outgoing_sms_whitelist.enabled';
UPDATE carpoolvote.params SET value='http://richardwestenra.com/voteamerica.github.io' WHERE name='site.base.url';
UPDATE carpoolvote.params SET value='$APIENV' WHERE name='api_environment';
SELECT * FROM carpoolvote.params;
SQLINPUT