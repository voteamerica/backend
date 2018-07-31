#!/bin/bash

. ./common-sudo-fix.sh

if [[ "X$1" = "X" ]]
then
	echo missing machine name
	echo $0 \<DB name\>
	# exit 1
else
    M=$1
fi

if [[ "X$2" = "XR" ]]
then
    # R is flag for rebuild, so force a cache bust
    C=$(date +%s)
else
    # 1 matches the arg in the dockerfile, this will not bust the cache
    C=1
	echo CACHEBUST $C
fi

if [[ "X$3" = "X" ]]; then
    R=https://github.com/voteamerica/backend.git
    echo REPO $R
else 
    R=$3
fi

if [[ "X$4" = "X" ]]
then
    B=ts-route
	echo BRANCH_NAME $B
else
    B=$4
fi

echo MACHINE $M
echo CACHEBUST $C
echo REPO $R
echo BRANCH_NAME $B

$DOCKERCOMPOSE -f ./compose/full-stack-test/docker-compose-test-fullstack.yml build --build-arg REPO=$R --build-arg BRANCH_NAME=$B --build-arg CACHEBUST=$C $M
