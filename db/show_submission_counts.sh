#!/bin/sh

# USAGE : $0 [dbname] 

PGDATABASE=${PGDATABASE:=carpool_live}
if [[ "X$1" != "X" ]]
then
PGDATABASE=$1
fi

echo $PGDATABASE 

echo "DRIVERS" 
psql $PGDATABASE <<RPT
select count(*) , status from carpoolvote.driver group by status;
RPT

echo "RIDERS"
psql $PGDATABASE <<RPT
select count(*) , status from carpoolvote.rider group by status;
RPT

echo "MATCHES" 
psql $PGDATABASE <<RPT
select count(*) , status from carpoolvote.match group by status;
RPT

echo "EMAILS"
psql $PGDATABASE <<RPT
select count(*) , status from carpoolvote.outgoing_email group by status;
RPT

echo "SMS"
psql $PGDATABASE <<RPT
select count(*) , status from carpoolvote.outgoing_sms group by status;
RPT


