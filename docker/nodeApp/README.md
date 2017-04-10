# node app Docker file

## build image
## docker build -t carpool .

## run this from the host folder containing the github carpool backend

## using postgres docker machine
## docker run -it --link cp-pg-svr -p 8000:8000 -v $(pwd):/usr/src/app carpool /bin/bash

## docker exec -it container-id /bin/bash

## in the shell :     
## cd /usr/src/app/nodeAppPostPg

## execute the script to setup env vars
## 
## npm install, then npm run
