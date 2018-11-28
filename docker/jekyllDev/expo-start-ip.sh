#!/bin/bash

echo 'expo-start'

jekyll serve -H 0.0.0.0 --force_polling --source /usr/src/app/frontend --destination /usr/src/app/frontend/_site --config /_config-local-ip.yml &

# run webpack as background task
webpack --watch --progress --info-verbosity verbose --config development-webpack.config.js &

webpack --watch --progress --info-verbosity verbose --config production-webpack.config.js &

/bin/bash
