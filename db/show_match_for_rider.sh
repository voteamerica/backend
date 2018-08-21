#!/bin/bash

# USAGE : $0 [id-rider]

if [[ "X$1" = "X" ]]; then 
    echo "Usage: $0 uuid_rider"
    exit 1
fi



psql <<RPT
select * from carpoolvote.match where uuid_rider='$1' order by score desc;
RPT


