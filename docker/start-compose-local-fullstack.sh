#!/bin/bash

. ./common-sudo-fix.sh

# useful info here
# https://hharnisc.github.io/2016/06/19/integration-testing-with-docker-compose.html
# 
# good error checks and colour use here
# 

# http://bencane.com/2016/01/11/using-travis-ci-to-test-docker-builds/
# https://mike42.me/blog/how-to-set-up-docker-containers-in-travis-ci
# https://blog.codeship.com/orchestrate-containers-for-development-with-docker-compose/

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html
# http://www.tldp.org/LDP/abs/html/exit-status.html
# http://bencane.com/2014/09/02/understanding-exit-codes-and-how-to-use-them-in-bash-scripts/

echo start compose local

# pwd

# ls ./s*.sh

# build specific machines
# $DOCKERCOMPOSE -f ./compose/full-stack-local/docker-compose-local-fullstack.yml build --build-arg REPO=https://github.com/voteamerica/backend.git --build-arg BRANCH_NAME=docker-test --build-arg CACHEBUST=$(date +%s) cp-test-runner

$DOCKERCOMPOSE -f ./compose/full-stack-local/docker-compose-local-fullstack.yml up

