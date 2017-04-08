#!/bin/sh

# USAGE : $0 [id] [dbname]

if [[ "X$1" = "X" ]]
then
exit 1
fi

id=$1

PGDATABASE=${PGDATABASE:=carpool_v2.0_live}
if [[ "X$2" != "X" ]]
then
PGDATABASE=$2
fi

echo $PGDATABASE 

echo "Rider Details"
psql -h $PGHOST $PGDATABASE <<RPT
select * from carpoolvote.vw_ride_request where uuid='${id}'
RPT

echo "Rider Matches"
psql -h $PGHOST $PGDATABASE <<RPT
select * from carpoolvote.match where uuid_rider='${id}'
RPT

echo "Rider emails"
psql -h $PGHOST $PGDATABASE <<RPT
select status, subject, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_email where uuid='${id}'
RPT

echo "Rider sms"
psql -h $PGHOST $PGDATABASE <<RPT
select status, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_sms where uuid='${id}'
RPT
