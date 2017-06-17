#!/bin/bash

if [[ "X$1" = "X" ]]
then
    TEST_GROUP=match
	echo TEST_GROUP default: $TEST_GROUP
else
    TEST_GROUP=$1
fi

echo run-tests - TEST_GROUP $TEST_GROUP

cd /usr/src/app/backend/nodeAppPostPg/testing/nightwatch --verbose

# echo run-tests - sleep 60
# sleep 60

echo run-tests - sleep 30
sleep 30

echo run-tests - start tests

nightwatch --group $TEST_GROUP

# get exit code of last action
# https://stackoverflow.com/questions/90418/exit-shell-script-based-on-process-exit-code
EXIT_CODE=$?

echo run-tests - tests complete $EXIT_CODE

exit $EXIT_CODE

