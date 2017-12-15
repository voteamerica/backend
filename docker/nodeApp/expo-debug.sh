#!/bin/bash

export PORT=8000
export PGUSER=postgres, export PGUSER=carpool_web
# export PGHOST=$CP_PG_SVR_PORT_5432_TCP_ADDR
# export PGPASSWORD=$CP_PG_SVR_ENV_POSTGRES_PASSWORD
export PGDATABASE=carpoolvote

cd /usr/src/app/backend/nodeAppPostPg

# npm start

# node debug index.js

echo "debug"

# https://github.com/Microsoft/vscode/issues/23257
# https://github.com/Microsoft/vscode/issues/13005
# https://alexanderzeitler.com/articles/debugging-a-nodejs-es6-application-in-a-docker-container-using-visual-studio-code/
# node --debug=0.0.0.0:5858 index.js
node --inspect=0.0.0.0:5858 index.js
