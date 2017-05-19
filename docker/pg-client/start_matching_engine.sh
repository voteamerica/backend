#!/bin/sh

# . ~/.bash_profile

# if [[ "X$1" = "X" ]]
# then
# 	echo missing DB name
# 	echo $0 \<DB name\>
# 	exit 1
# fi

DB=carpoolvote

echo "client $DB"

sleep 60

echo "matching $DB"

while true
do
# date  >> matching_engine_$1.log
psql $DB < matching_engine.sql 
# 2>&1 >> matching_engine_$1.log
# python ../emailHandler/emailSender.py $1 >> emailSender_$1.log
sleep 30
done
