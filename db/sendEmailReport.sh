#!/bin/sh
echo "Report run on $(date)" > /tmp/report.$$
/opt/carpool/v2.0/show_submission_counts.sh >> /tmp/report.$$
/opt/carpool/v2.0/show_last_matches.sh >> /tmp/report.$$
/opt/carpool/v2.0/show_last_matching_activity.sh >> /tmp/report.$$
python3.5  /opt/carpool/v2.0/reportsEmailer.py $1 "$1 status report" < /tmp/report.$$
rm /tmp/report.$$

