#!/bin/bash

# useful info here
# https://hharnisc.github.io/2016/06/19/integration-testing-with-docker-compose.html

echo start compose tests

# pwd

# ls ./s*.sh

# build specific machines
docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml build --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=docker-test --build-arg CACHEBUST=$(date +%s) cp-test-runner

docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml up -d

sleep 60

docker exec -it $(docker ps | grep nigh | cut -c 1-4) /run-tests.sh match2

# docker logs $ (docker ps | grep nigh | cut -c 1-4)

docker wait fullstacktest_cp-test-runner_1
EXIT_CODE=$?

docker logs fullstacktest_cp-test-runner_1

docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml down

echo exit code: $EXIT_CODE

# exit $EXIT_CODE
