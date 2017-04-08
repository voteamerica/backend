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

echo "Driver Details"
psql -h $PGHOST $PGDATABASE <<RPT
select * from carpoolvote.vw_drive_offer where "UUID"='${id}'
RPT

echo "Driver Matches"
psql -h $PGHOST $PGDATABASE <<RPT
select * from carpoolvote.match where uuid_driver='${id}'
RPT

echo "Driver emails"
psql -h $PGHOST $PGDATABASE <<RPT
select status, subject, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_email where uuid='${id}'
RPT

echo "Driver sms"
psql -h $PGHOST $PGDATABASE <<RPT
select status, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_sms where uuid='${id}'
RPT

