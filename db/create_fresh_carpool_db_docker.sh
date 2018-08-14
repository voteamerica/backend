# needs to be executed as postgres user

# optional environment variables
# For docker, use :
# CARPOOL_DATABASE_NAME=LIVE
# CARPOOL_SOURCE_FILES=/db

CARPOOL_DATABASE_NAME=${CARPOOL_DATABASE_NAME:-LIVE}
CARPOOL_SOURCE_FILES=${CARPOOL_SOURCE_FILES:-.}

cd $CARPOOL_SOURCE_FILES

psql < carpool_roles.sql \
&& createdb --owner carpool_admin $CARPOOL_DATABASE_NAME \
&& psql $CARPOOL_DATABASE_NAME < carpool_schema_bootstrap.sql \
&& psql $CARPOOL_DATABASE_NAME < carpool_schema.sql \
&& psql $CARPOOL_DATABASE_NAME < carpool_static_data.sql \
&& psql $CARPOOL_DATABASE_NAME < carpool_params_data.sql \
&& psql $CARPOOL_DATABASE_NAME < fct_utilities.sql \
&& psql $CARPOOL_DATABASE_NAME < carpool_views.sql \
&& psql $CARPOOL_DATABASE_NAME < fct_outbound_notifications.sql \
&& psql $CARPOOL_DATABASE_NAME < fct_user_actions.sql \
&& psql $CARPOOL_DATABASE_NAME < fct_matching_engine.sql

