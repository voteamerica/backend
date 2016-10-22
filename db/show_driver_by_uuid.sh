#!/bin/sh

# USAGE : $0 [id] [dbname]

if [[ "X$1" = "X" ]]
then
exit 1
fi

id=$1

PGDATABASE="carpool"
if [[ "X$2" != "X" ]]
then
PGDATABASE=$2
fi

echo $PGDATABASE 

psql -h /tmp $PGDATABASE <<RPT
select * from stage.vw_drive_offer where "UUID"='${id}'
RPT


