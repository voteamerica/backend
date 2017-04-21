# cd /var
# mkdir VM_share 
# sudo mount -t vboxsf c/users VM_share
# cd VM_share/Jon/Documents/GitHub/voteUSbackend/db/

## build IMAGE
### not ready yet, just thinking through
# cd VM_share/Jon/Documents/GitHub/voteUSbackend/docker/postgres/
## auto test
## build image
## docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) .

## FOLDER - run this from the host folder containing the github carpool backend

## create MACHINE
## create a docker machine
## docker run --name cp-pg-svr -p 5432:5432 -v $(pwd):/usr/src/app/backend -e POSTGRES_PASSWORD=pwd -d pgres-cp 
## docker run --name cp-pg-svr -p 5432:5432 -v $(pwd):/usr/src/app -e POSTGRES_PASSWORD=pwd -d pgres-cp 

## docker run --name cp-pg-svr -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp 

## interactive for testing
# docker run -it --name cp-pg-svr-test -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp /bin/bash

## log in to server as postgres (psql needs this user account)
##
## docker exec -it -u postgres container-id /bin/bash
## 

## in the shell : 
## cd /usr/src/app/db
## execute two shell script, one for db creation, one for modifying a user

