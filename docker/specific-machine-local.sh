#!/bin/bash

if [[ "X$1" = "X" ]]
then
	echo missing machine name
	echo $0 \<DB name\>
	# exit 1
else
    M=$1
fi

if [[ "X$2" = "X" ]]; then
    R=https://github.com/jkbits1/backend
else 
    R=$2
fi

if [[ "X$3" = "X" ]]
then
    B=ts-route
	echo BRANCH_NAME $B
else
    B=$3
fi

echo MACHINE $M
echo REPO $R
echo BRANCH_NAME $3

docker-compose -f ./compose/full-stack-local/docker-compose-dev-build-test.yml build --build-arg REPO=$R --build-arg BRANCH_NAME=$B $M
