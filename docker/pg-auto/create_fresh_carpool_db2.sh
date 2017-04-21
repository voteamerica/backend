#!/usr/bin/sh

# if [ "X$1" = "X" ]
# then
# 	echo missing DB name test
# 	echo $0 \<DB name\>
# 	exit 1
# fi

echo createdb ...

createdb carpoolvote \
&& psql carpoolvote < carpool_roles.sql \
&& psql carpoolvote < carpool_schema_bootstrap.sql \
&& psql carpoolvote < carpool_schema.sql \
&& psql carpoolvote < carpool_static_data.sql \
&& psql carpoolvote < carpool_params_data.sql \
&& psql carpoolvote < fct_utilities.sql \
&& psql carpoolvote < fct_outbound_notifications.sql \
&& psql carpoolvote < fct_user_actions.sql \
&& psql carpoolvote < fct_matching_engine.sql \
&& psql carpoolvote < /usr/src/app/backend/docker/pg-auto/alter.sql \
