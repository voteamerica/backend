#!/usr/bin/sh

if [[ "X$1" = "X" ]]
then
	echo missing DB name
	echo $0 \<DB name\>
	exit 1
fi

psql -U postgres -d postgres -h /tmp < carpool_roles.sql \
&& createdb -U postgres -h /tmp --owner postgres $1 \
&& psql -U postgres -h /tmp $1 < carpool_schema_bootstrap.sql \
&& psql -U postgres -h /tmp $1 < carpool_schema.sql \
&& psql -U postgres -h /tmp $1 < carpool_static_data.sql \
&& psql -U postgres -h /tmp $1 < carpool_params_data.sql \
&& ./load_functions.sh $1

