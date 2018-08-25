#!/bin/bash

jekyll serve -H 0.0.0.0 --force_polling --source /usr/src/app/frontend --destination /usr/src/app/frontend/_site --config /_config-local-host.yml &
# run webpack as background task
webpack --watch --progress --info-verbosity verbose &

/bin/bash
