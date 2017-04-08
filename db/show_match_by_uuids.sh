#!/bin/sh

# USAGE : $0 [id-driver] [id-rider] [dbname] 

if [[ "X$1" = "X" ]]
then 
echo "Usage: $0 id-driver id-rider [dbname]"
exit 1
fi

if [[ "X$2" = "X" ]]
then
echo "Usage: $0 id-driver id-rider [dbname]"
exit 1
fi

PGDATABASE=${PGDATABASE:=carpool_v2.0_live}
if [[ "X$3" != "X" ]]
then
PGDATABASE=$3
fi

echo $PGDATABASE 

psql -h /tmp $PGDATABASE <<RPT
select * from carpoolvote.match where uuid_rider='$2' and uuid_driver='$1';
RPT


