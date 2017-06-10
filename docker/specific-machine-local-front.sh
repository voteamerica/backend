#!/bin/bash

if [[ "X$1" = "X" ]]
then
	echo missing machine name
	echo $0 \<DB name\>
	# exit 1
else
    M=$1
fi

if [[ "X$2" = "X" ]]
then
    C=1
	echo CACHEBUST $C
else
    C=$2
fi

if [[ "X$3" = "X" ]]; then
    R=https://github.com/jkbits1/backend
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

docker-compose -f ./compose/full-stack-local/docker-compose-local-frontend.yml build --build-arg REPO=$R --build-arg BRANCH_NAME=$B --build-arg CACHEBUST=$C $M
