#!/bin/bash

# USAGE : $0 [id-driver]

if [[ "X$1" = "X" ]]; then
    echo "Usage: $0 uuid_driver"
    exit 1
fi


psql <<RPT
select * from carpoolvote.match where uuid_driver='$1' order by score;
RPT


