#
# create docker machine for postgres db
#

# cd /var
# mkdir VM_share 
# sudo mount -t vboxsf c/users VM_share

## FOLDER 
# cd VM_share/Jon/Documents/GitHub/voteUSbackend/docker/pg-auto

## build IMAGE
## docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=master .

## FOLDER 
# cd VM_share/Jon/Documents/GitHub/voteUSbackend

## create MACHINE
## docker run --rm --name cp-pg-svr -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp 
# 
# with shared volume
## docker run --name cp-pg-svr -p 5432:5432 -v $(pwd):/usr/src/app/backend -e POSTGRES_PASSWORD=pwd -d pgres-cp 


## interactive for testing
# docker run -it --name cp-pg-svr-test -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp /bin/bash

## log in to server as postgres (psql needs this user account)
##
## docker exec -it -u postgres container-id /bin/bash
## 


