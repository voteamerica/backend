#!/usr/bin/sh

if [[ "X$1" = "X" ]]
then
	echo missing DB name
	echo $0 \<DB name\>
	exit 1
fi

su postgres -c "cd /opt/carpool/backend/db && psql < carpool_roles.sql" \ 
&& su postgres -c "createdb --owner carpool_admin $1" \
&& su carpool_app -c "cd /opt/carpool/backend/db && psql $1 < carpool_schema_bootstrap.sql" \
&& su carpool_app -c "cd /opt/carpool/backend/db && psql $1 < carpool_schema.sql" \
&& su carpool_app -c "cd /opt/carpool/backend/db && psql $1 < carpool_static_data.sql" \
&& su carpool_app -c "cd /opt/carpool/backend/db && psql $1 < carpool_params_data.sql" \
&& su carpool_app -c "cd /opt/carpool/backend/db && ./load_functions.sh $1"

