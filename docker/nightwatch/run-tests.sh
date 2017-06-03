#!/bin/bash

if [[ "X$1" = "X" ]]
then
    TEST_GROUP=match
	echo TEST_GROUP default: $TEST_GROUP
else
    TEST_GROUP=$1
fi

echo TEST_GROUP $TEST_GROUP

cd /usr/src/app/backend/nodeAppPostPg/testing/nightwatch

# nightwatch 
# nightwatch --group basic

nightwatch --group $TEST_GROUP

echo tests complete

