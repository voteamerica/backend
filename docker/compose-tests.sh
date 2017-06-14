#!/bin/bash

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

# https://docs.travis-ci.com/user/environment-variables/
# https://blog.travis-ci.com/2014-08-22-environment-variables/
# https://docs.travis-ci.com/user/ci-environment/
# https://docs.travis-ci.com/user/encryption-keys/

# https://docs.travis-ci.com/user/customizing-the-build#The-Build-Lifecycle

# https://docs.travis-ci.com/user/pull-requests/

# https://docs.travis-ci.com/user/status-images/

# https://docs.travis-ci.com/user/notifications/

echo start compose tests - travis ci

# pwd

# ls ./s*.sh

echo sct-travis sleep 60

sleep 60

echo sct-travis test runner status
# https://stackoverflow.com/questions/34724980/finding-a-string-in-docker-logs-of-container
docker logs fullstacktest_cp-test_1 > stdout.log 2>stderr.log
cat stdout.log | grep Selenium

echo sct-travis db status
docker logs fullstacktest_cp-pg-server_1 > cp-pg-server-stdout.log 2>cp-pg-server-stderr.log
cat cp-pg-server-stdout.log | grep 'autovacuum launcher started'

echo sct-travis node app status
docker logs fullstacktest_cp-nodejs_1 > cp-nodejs-stdout.log 2>cp-nodejs-stderr.log
cat cp-nodejs-stdout.log | grep 'Server running'


docker exec -it $(docker ps | grep nigh | cut -c 1-4) /run-tests.sh $TEST_GROUP
EXIT_CODE=$?

docker logs fullstacktest_cp-test-runner_1

echo exit code: $EXIT_CODE

if [[ $EXIT_CODE -eq 0 ]]
then
    echo "tests succeeded"
    exit 0
else 
    echo "tests failed"
    exit $EXIT_CODE
fi

