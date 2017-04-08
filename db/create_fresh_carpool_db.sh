#!/usr/bin/sh

if [[ "X$1" = "X" ]]
then
	echo missing DB name
	echo $0 \<DB name\>
	exit 1
fi

createdb $1 \
&& psql -h /tmp $1 < carpool_roles.sql \
&& psql -h /tmp $1 < carpool_schema_bootstrap.sql \
&& psql -h /tmp $1 < carpool_schema.sql \
&& psql -h /tmp $1 < carpool_static_data.sql \
&& psql -h /tmp $1 < carpool_params_data.sql \
&& ./load_functions.sh $1

