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
select count(*) , state from stage.websubmission_driver group by state;
RPT

echo "RIDERS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from stage.websubmission_rider group by state;
RPT

echo "MATCHES" 
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from nov2016.match group by state;
RPT

echo "EMAILS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from nov2016.outgoing_email group by state;
RPT

echo "SMS"
psql -h /tmp $PGDATABASE <<RPT
select count(*) , state from nov2016.outgoing_sms group by state;
RPT


