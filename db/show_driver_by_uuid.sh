#!/bin/bash

# USAGE : $0 [id]

if [[ "X$1" = "X" ]]; then
    echo "Usage: $0 id-driver"
    exit 1
fi

id=$1

echo "Driver Details"
psql <<RPT
select * from carpoolvote.vw_drive_offer where "UUID"='${id}'
RPT

echo "Driver Matches"
psql <<RPT
select * from carpoolvote.match where uuid_driver='${id}'
RPT

echo "Driver emails"
psql <<RPT
select status, subject, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_email where uuid='${id}'
RPT

echo "Driver sms"
psql  <<RPT
select status, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_sms where uuid='${id}'
RPT

