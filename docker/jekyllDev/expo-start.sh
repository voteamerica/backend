#!/bin/bash

echo 'expo-start'

# These are standard files required for the ReasonML files.
# At some point, the bs-platform bsb may be started to generate them,
# but this interim method provides all devs with an env that builds the React app.
# cp /usr/src/app/frontend/scripts/ReasonReact.js  /usr/src/app/frontend/node_modules/reason-react/src/ReasonReact.js  

# cp /usr/src/app/frontend/scripts/ReasonReactOptimizedCreateClass.js  /usr/src/app/frontend/node_modules/reason-react/src/ReasonReactOptimizedCreateClass.js  

# These files don't display when the container is built, but do when the
# docker compose env is started.
# ls /usr/src/app/frontend/node_modules/reason-react/src

# echo "copied Reason files"

jekyll serve -H 0.0.0.0 --force_polling --source /usr/src/app/frontend --destination /usr/src/app/frontend/_site --config /_config-local-host.yml &
# run webpack as background task
webpack --watch --progress --info-verbosity verbose --config development-webpack.config.js &

webpack --watch --progress --info-verbosity verbose --config production-webpack.config.js &


# echo "watch Reason files"

# Every 10 seconds, check for ReasonML file changes.
# NOTE: This works, but output options aren't great. Handy to
#       have the option, though.
# watch -n10 npx bsb -make-world &

# Hide output
# watch -n10 npx bsb -make-world & > /dev/null

# Efforts with colour, from:
# https://stackoverflow.com/a/40849490
# while sleep 10; do clear; npx bsb -make-world; done

/bin/bash
