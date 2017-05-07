#!/usr/bin/sh

# DB name is expected to be carpool_<env>
# carpool_live
# carpool_test
# carpool_purpose

if [[ "X$1" = "X" ]]
then
        echo missing DB name
        echo $0 \<DB name\> \<APIenv\> \<carpool_site_url\>
        exit 1
fi

if [[ "X$2" = "X" ]]
then
        echo missing APIenv
        echo $0 \<DB name\> \<APIenv\> \<carpool_site_url\>
        exit 1
fi

if [[ "X$3" = "X" ]]
then
        echo missing carpool_site_url
        echo $0 \<DB name\> \<APIenv\> \<carpool_site_url\>
        exit 1
fi

echo "Configuring database $1 for $2 with site $3"

psql -d $1 <<SQLINPUT
UPDATE carpoolvote.params SET value='true' WHERE name='outgoing_sms_whitelist.enabled';
UPDATE carpoolvote.params SET value='$3' WHERE name='site.base.url';
UPDATE carpoolvote.params SET value='$2' WHERE name='api_environment';
SELECT * FROM carpoolvote.params;
SQLINPUT
