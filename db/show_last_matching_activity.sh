#!/bin/bash

# USAGE : $0 [max-rows]

LIMIT="LIMIT 25"
if [[ "X$1" != "X" ]]; then
    LIMIT="LIMIT $1"
fi

echo $LIMIT

psql <<RPT
select * from carpoolvote.match_engine_activity_log order by start_ts desc $LIMIT
RPT
