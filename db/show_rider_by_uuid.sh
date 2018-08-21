#!/bin/bash

# USAGE : $0 [id]

if [[ "X$1" = "X" ]]; then
    echo "Usage: $0 id-rider"
    exit 1
fi

id=$1

echo "Rider Details"
psql <<RPT
select * from carpoolvote.vw_ride_request where uuid='${id}'
RPT

echo "Rider Matches"
psql <<RPT
select * from carpoolvote.match where uuid_rider='${id}'
RPT

echo "Rider emails"
psql <<RPT
select status, subject, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_email where uuid='${id}'
RPT

echo "Rider sms"
psql <<RPT
select status, created_ts, last_updated_ts, recipient, emission_info from carpoolvote.outgoing_sms where uuid='${id}'
RPT
