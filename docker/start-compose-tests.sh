#!/bin/bash

. ./common-sudo-fix.sh

if [[ "X$1" = "X" ]]
then
    TEST_GROUP=match2
	echo TEST_GROUP default: $TEST_GROUP
else
    TEST_GROUP=$1
fi

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

echo start compose tests

# pwd

# ls ./s*.sh

# build specific machines
# docker-compose -f ./compose/full-stack-test/docker-compose-test.yml build --build-arg REPO=https://github.com/voteamerica/backend.git --build-arg BRANCH_NAME=docker-test --build-arg CACHEBUST=$(date +%s) cp-test-runner

$DOCKERCOMPOSE -f ./compose/full-stack-test/docker-compose-test.yml up -d

sleep 60

echo sct test runner status
# https://stackoverflow.com/questions/34724980/finding-a-string-in-docker-logs-of-container
$DOCKER logs fullstacktest_cp-test_1 > stdout.log 2>stderr.log
cat stdout.log | grep Selenium
cat stdout.log | grep ServerConnector

echo sct db status
$DOCKER logs fullstacktest_cp-pg-server_1 > cp-pg-server-stdout.log 2>cp-pg-server-stderr.log
cat cp-pg-server-stdout.log | grep 'ALTER ROLE'
cat cp-pg-server-stdout.log | grep 'autovacuum launcher started'

echo sct node app status
$DOCKER logs fullstacktest_cp-nodejs_1 > cp-nodejs-stdout.log 2>cp-nodejs-stderr.log
cat cp-nodejs-stdout.log | grep 'Server running'

echo sct fe status
$DOCKER logs fullstacktest_cp-front-end_1 > cp-front-end-stdout.log 2>cp-pg-front-end-stderr.log
cat cp-front-end-stdout.log | grep 'Server running'
cat cp-front-end-stdout.log | grep 'Configuration file'
cat cp-front-end-stdout.log | grep 'Source'
cat cp-front-end-stdout.log | grep 'Destination'

echo sct pg-client status
$DOCKER logs fullstacktest_cp-client_1 > cp-client-stdout.log 2>cp-pg-client-stderr.log
cat cp-client-stdout.log | grep 'DO'

# curl 10.5.0.6:5432
curl 10.5.0.5:8000
curl 10.5.0.4:4000 | grep "Every American"
curl 10.5.0.3:4444 | grep "Selenium"

curl http://10.5.0.3:4444/selenium-server/driver?cmd=getLogMessages

curl localhost:8000
curl localhost:4000 | grep "Every American"
# curl localhost:4444 | grep "Selenium"


$DOCKER exec -it $($DOCKER ps | grep nigh | cut -c 1-4) /run-tests.sh $TEST_GROUP
# $DOCKER logs $ ($DOCKER ps | grep nigh | cut -c 1-4)
# $DOCKER wait fullstacktest_cp-test-runner_1
EXIT_CODE=$?

$DOCKER logs fullstacktest_cp-test-runner_1

$DOCKERCOMPOSE -f ./compose/full-stack-test/docker-compose-test.yml down

echo exit code: $EXIT_CODE

if [[ $EXIT_CODE -eq 0 ]]
then
    echo "tests succeeded"
    exit 0
else 
    echo "tests failed"
    exit $EXIT_CODE
fi

