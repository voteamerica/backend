#!/bin/bash

echo 'expo-start'

# creates node_modules correctly - can it affect volume files?
# review
yarn

cp /usr/src/app/frontend/scripts/ReasonReact.js  /usr/src/app/frontend/node_modules/reason-react/src/ReasonReact.js  

cp /usr/src/app/frontend/scripts/ReasonReactOptimizedCreateClass.js  /usr/src/app/frontend/node_modules/reason-react/src/ReasonReactOptimizedCreateClass.js  

echo "copied Reason files"

jekyll serve -H 0.0.0.0 --force_polling --source /usr/src/app/frontend --destination /usr/src/app/frontend/_site --config /_config-local-host.yml &
# run webpack as background task
webpack --watch --progress --info-verbosity verbose --config development-webpack.config.js &

webpack --watch --progress --info-verbosity verbose --config production-webpack.config.js &

/bin/bash
