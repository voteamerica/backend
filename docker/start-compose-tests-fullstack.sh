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

echo start compose tests - fullstack

docker-compose -f ./compose/full-stack-test/docker-compose-test-fullstack.yml up -d

# echo sct-full sleep 60
# sleep 60

echo sct-full sleep 45
sleep 45


# docker logs fullstacktest_cp-test_1 | grep Selenium
# --line-buffered not supported everywhere
# docker logs fullstacktest_cp-test_1 | grep --line-buffered Selenium
# docker logs fullstacktest_cp-test_1 | sed -n '/Selenium/p'


echo sct-full test runner status
# https://stackoverflow.com/questions/34724980/finding-a-string-in-docker-logs-of-container
docker logs fullstacktest_cp-test_1 > stdout.log 2>stderr.log
cat stdout.log | grep Selenium

echo sct-full db status
docker logs fullstacktest_cp-pg-server_1 > cp-pg-server-stdout.log 2>cp-pg-server-stderr.log
cat cp-pg-server-stdout.log | grep 'autovacuum launcher started'

echo sct-full node app status
docker logs fullstacktest_cp-nodejs_1 > cp-nodejs-stdout.log 2>cp-nodejs-stderr.log
cat cp-nodejs-stdout.log | grep 'Server running'


docker exec -it $(docker ps | grep nigh | cut -c 1-4) /run-tests.sh $TEST_GROUP
EXIT_CODE=$?

docker logs fullstacktest_cp-test-runner_1

docker-compose -f ./compose/full-stack-test/docker-compose-test-fullstack.yml down

echo exit code: $EXIT_CODE

if [[ $EXIT_CODE -eq 0 ]]
then
    echo "tests succeeded"
    exit 0
else 
    echo "tests failed"
    exit $EXIT_CODE
fi

