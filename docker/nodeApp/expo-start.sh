#!/bin/bash

export PORT=8000
export PGHOST=$CP_PG_SVR_PORT_5432_TCP_ADDR
export PGUSER=postgres, export PGUSER=carpool_web
export PGPASSWORD=$CP_PG_SVR_ENV_POSTGRES_PASSWORD
export PGDATABASE=carpoolvote

cd /usr/src/app/backend/nodeAppPostPg

npm start

