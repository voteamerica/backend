psql -U postgres

export PORT=8000
# export PGUSER=postgres
export PGUSER=carpool_web
export PGHOST=
# export PGPASSWORD=$CP_PG_SVR_ENV_POSTGRES_PASSWORD
export PGDATABASE=carpoolvote

. ../docker/pg-auto/start_matching_engine.sh
