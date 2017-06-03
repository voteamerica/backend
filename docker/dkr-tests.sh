#!/bin/bash

echo start compose tests

# ./specific-machine-test.sh cp-test-runner $(date +%s) https://github.com/jkbits1/backend docker-test

# docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml up -d

# sleep 60

# docker exec -it $(docker ps | grep nigh | cut -c 1-4) /run-tests.sh match2

# # docker logs $ (docker ps | grep nigh | cut -c 1-4)

# EXIT_CODE=docker wait fullstacktest_cp-test-runner_1

# docker logs fullstacktest_cp-test-runner_1

# exit $EXIT_CODE
