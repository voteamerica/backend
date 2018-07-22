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

#
# Start the instance for debugging
#
# https://github.com/Microsoft/vscode/issues/23257
# https://github.com/Microsoft/vscode/issues/13005
# https://alexanderzeitler.com/articles/debugging-a-nodejs-es6-application-in-a-docker-container-using-visual-studio-code/
# node --debug=0.0.0.0:5858 index.js
node --inspect=0.0.0.0:5858 index.js

#
# Debugging
#
# run `docker-machine ip` at the level `docker-machine ssh` is run to get the ip
# in the browser use this ip to visit this url
# http://192.168.99.100:5858/json
# The url gives the various info (as in the MS issues above) to connect.
# chrome-devtools://devtools/bundled/inspector.html?experiments=true&v8only=true&ws=192.168.99.100:5858/8f950707-e131-429a-8bdd-139ee5f86da4
# In this line of the info, probably need to change ws=... to the ip
# Also, each time the node debug is re-run on the server, the guid will change, so change 
# that in the browser when it's re-run

