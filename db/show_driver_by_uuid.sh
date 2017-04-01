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

psql -h /tmp $PGDATABASE <<RPT
select * from carpoolvote.vw_drive_offer where "UUID"='${id}'
RPT


