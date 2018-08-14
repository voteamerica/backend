#!/bin/bash

# USAGE : $0


echo "DRIVERS" 
psql <<RPT
select count(*) , status from carpoolvote.driver group by status;
RPT

echo "RIDERS"
psql <<RPT
select count(*) , status from carpoolvote.rider group by status;
RPT

echo "MATCHES" 
psql <<RPT
select count(*) , status from carpoolvote.match group by status;
RPT

echo "EMAILS"
psql <<RPT
select count(*) , status from carpoolvote.outgoing_email group by status;
RPT

echo "SMS"
psql <<RPT
select count(*) , status from carpoolvote.outgoing_sms group by status;
RPT
