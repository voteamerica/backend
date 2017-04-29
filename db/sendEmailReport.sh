#!/bin/sh



if [[ "X$1" != "X" ]]
then
PGDATABASE=$1
else
PGDATABASE=carpool_live
fi

echo "Report run on $(date)" > /tmp/report.txt
/opt/carpool/backend/db/show_submission_counts.sh 2>&1 1>> /tmp/report.txt
/opt/carpool/backend/db/show_last_matches.sh 2>&1 1>> /tmp/report.txt
/opt/carpool/backend/db/show_last_matching_activity.sh 2>&1 1>> /tmp/report.txt
python /opt/carpool/backend/db/reportsEmailer.py $PGDATABASE "$1 status report" < /tmp/report.txt
#rm /tmp/report.txt

