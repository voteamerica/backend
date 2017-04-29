#!/bin/sh

# USAGE : $0 [dbname] [max-rows]

PGDATABASE=${PGDATABASE:=carpool_live}
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

psql $PGDATABASE <<RPT
select * from carpoolvote.match_engine_activity_log order by start_ts desc $LIMIT
RPT


