#!/bin/sh
. ~/.bash_profile
echo "Report run on $(date)" > /tmp/report.txt
/opt/carpool/backend/db/show_submission_counts.sh 2>&1 1>> /tmp/report.txt
/opt/carpool/backend/db/show_last_matches.sh 2>&1 1>> /tmp/report.txt
/opt/carpool/backend/db/show_last_matching_activity.sh 2>&1 1>> /tmp/report.txt
python /opt/carpool/backend/db/reportsEmailer.py $1 "$1 status report" < /tmp/report.txt
#rm /tmp/report.txt

