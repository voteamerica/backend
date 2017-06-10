#!/bin/bash

if [[ "X$1" = "X" ]]
then
    TEST_GROUP=match
	echo TEST_GROUP default: $TEST_GROUP
else
    TEST_GROUP=$1
fi

echo run-tests TEST_GROUP $TEST_GROUP

cd /usr/src/app/backend/nodeAppPostPg/testing/nightwatch

echo sleep 60

sleep 60

echo start tests

# nightwatch 
# nightwatch --group basic

nightwatch --group $TEST_GROUP

# get exit code of last action
# https://stackoverflow.com/questions/90418/exit-shell-script-based-on-process-exit-code
EXIT_CODE=$?

echo tests complete $EXIT_CODE

exit $EXIT_CODE

