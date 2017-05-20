#!/bin/bash


DB=carpoolvote

# echo "client $DB"

sleep 60

# echo "matching $DB"

while true
do
# # date  >> matching_engine_$1.log
    psql $DB < matching_engine.sql 
# # 2>&1 >> matching_engine_$1.log
# # python ../emailHandler/emailSender.py $1 >> emailSender_$1.log
    sleep 30
done
