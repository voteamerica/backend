#!/bin/sh

# USAGE : $0 [dbname] [max-rows]

PGDATABASE=${PGDATABASE:=carpool_v2.0_live}
if [[ "X$1" != "X" ]]
then
PGDATABASE=$1
fi

LIMIT="LIMIT 25"
if [[ "X$2" != "X" ]]
then
LIMIT="LIMIT $2"
fi

echo $PGDATABASE $LIMIT

psql -h /tmp $PGDATABASE <<RPT
select * from nov2016.match order by created_ts desc, score desc $LIMIT
RPT


