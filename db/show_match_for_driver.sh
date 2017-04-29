#!/bin/sh

# USAGE : $0 [id-driver] [dbname] 

if [[ "X$1" = "X" ]]
then 
echo "Usage: $0 uuid_driver [dbname]"
exit 1
fi

PGDATABASE=${PGDATABASE:=carpool_live}
if [[ "X$2" != "X" ]]
then
PGDATABASE=$2
fi

echo $PGDATABASE 

psql $PGDATABASE <<RPT
select * from carpoolvote.match where uuid_driver='$1' order by score;
RPT


