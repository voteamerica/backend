#!/usr/bin/sh

if [[ "X$1" = "X" ]]
then
        echo missing DB name
        echo $0 \<DB name\>
        exit 1
fi

psql -U carpool_admin  -h /tmp $1 < fct_utilities.sql \
&& psql -U carpool_admin -h /tmp $1 < fct_outbound_notifications.sql \
&& psql -U carpool_admin -h /tmp $1 < fct_user_actions.sql \
&& psql -U carpool_admin -h /tmp $1 < fct_matching_engine.sql


