#!/bin/bash

# USAGE : $0 [max-rows]


LIMIT="LIMIT 25"
if [[ "X$1" != "X" ]]; then
    LIMIT="LIMIT $1"
fi

echo $LIMIT

psql <<RPT
select * from carpoolvote.match order by created_ts desc, score desc $LIMIT
RPT
