# postgres Dockerfile

## run this from the host folder containing the github carpool backend

## create a docker machine
## docker run --name cp-pg-svr -p 5432:5432 -v $(pwd):/usr/src/app -e POSTGRES_PASSWORD=pwd -d postgres:9.5.4 

## log in to server as postgres (psql needs this user account)
##
## docker exec -it -u postgres container-id /bin/bash
## 

## in the shell : 
## cd /usr/src/app/db
## execute two shell script, one for db creation, one for modifying a user
