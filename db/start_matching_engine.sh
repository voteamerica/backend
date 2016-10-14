#!/bin/sh

if [[ "X$1" = "X" ]]
then
	echo missing DB name
	echo $0 \<DB name\>
	exit 1
fi

while true
do
date  >> matching_engine_$1.log
psql -h /tmp $1 < matching_engine.sql 2>&1 >> matching_engine_$1.log
sleep 30
done
