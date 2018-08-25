# optional environment variables
# For docker, use :
# CARPOOL_DATABASE_NAME=LIVE
# CARPOOL_SOURCE_FILES=/db

CARPOOL_DATABASE_NAME=${CARPOOL_DATABASE_NAME:-LIVE}
CARPOOL_SOURCE_FILES=${CARPOOL_SOURCE_FILES:-.}

unset PGDATABASE
unset PGUSER

cd $CARPOOL_SOURCE_FILES

psql -d postgres -U postgres < carpool_roles.sql  \
&& su - postgres -c "createdb --owner carpool_admin $CARPOOL_DATABASE_NAME" \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < carpool_schema_bootstrap.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < carpool_schema.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < carpool_static_data.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < carpool_params_data.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < fct_utilities.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < carpool_views.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < fct_outbound_notifications.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < fct_user_actions.sql \
&& psql -U postgres -d $CARPOOL_DATABASE_NAME < fct_matching_engine.sql
