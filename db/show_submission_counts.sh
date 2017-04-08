#!/bin/sh

# USAGE : $0 [dbname] 

PGDATABASE=${PGDATABASE:=carpool_v2.0_live}
if [[ "X$1" != "X" ]]
then
PGDATABASE=$1
fi

echo $PGDATABASE 

echo "DRIVERS" 
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from carpoolvote.driver group by state;
RPT

echo "RIDERS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from carpoolvote.rider group by state;
RPT

echo "MATCHES" 
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from carpoolvote.match group by state;
RPT

echo "EMAILS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from carpoolvote.outgoing_email group by state;
RPT

echo "SMS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from carpoolvote.outgoing_sms group by state;
RPT


