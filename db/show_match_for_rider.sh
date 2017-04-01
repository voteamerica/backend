#!/bin/sh

# USAGE : $0 [id-rider] [dbname] 

if [[ "X$1" = "X" ]]
then 
echo "Usage: $0 uuid_rider [dbname]"
exit 1
fi

PGDATABASE=${PGDATABASE:=carpool_v2.0_live}
if [[ "X$2" != "X" ]]
then
PGDATABASE=$2
fi

echo $PGDATABASE 

psql -h /tmp $PGDATABASE <<RPT
select * from carpoolvote.match where uuid_rider='$1' order by score desc;
RPT


