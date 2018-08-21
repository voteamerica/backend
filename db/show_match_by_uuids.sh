#!/bin/bash

# USAGE : $0 [id-driver] [id-rider]

if [[ "X$1" = "X" ]]; then
    echo "Usage: $0 id-driver id-rider"
    exit 1
fi

if [[ "X$2" = "X" ]]; then
    echo "Usage: $0 id-driver id-rider"
    exit 1
fi

psql <<RPT
select * from carpoolvote.match where uuid_rider='$2' and uuid_driver='$1';
RPT


