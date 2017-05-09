#!/usr/bin/sh

# if [ "X$1" = "X" ]
# then
# 	echo missing DB name test
# 	echo $0 \<DB name\>
# 	exit 1
# fi

# this script is run from the dockerfile init folder using the postgres user
# https://github.com/docker-library/docs/pull/848/files

DB=carpoolvote

echo "createdb $DB"

psql < carpool_roles.sql \
&& createdb  --owner carpool_admin $DB \
&& psql $DB < carpool_schema_bootstrap.sql \
&& psql $DB < carpool_schema.sql \
&& psql $DB < carpool_static_data.sql \
&& psql $DB < carpool_params_data.sql \
&& psql $DB < fct_utilities.sql \
&& psql $DB < carpool_views.sql \
&& psql $DB < fct_outbound_notifications.sql \
&& psql $DB < fct_user_actions.sql \
&& psql $DB < fct_matching_engine.sql \
&& psql $DB < /usr/src/app/backend/docker/pg-auto/alter.sql \
