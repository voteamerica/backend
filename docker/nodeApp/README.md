# node app Docker file

## build image
## docker build -t carpool .

## run this from the host folder containing the github carpool backend

## docker run -it --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash

## using postgres docker machine
## (uses files, inc. node_modules from npm install that exist in build image)
## docker run -it --link cp-pg-svr -p 8000:8000 carpool /bin/bash

## (uses files from host, so may need to do npm install again)
## docker run -it --link cp-pg-svr -p 8000:8000 -v $(pwd):/usr/src/app/backend carpool /bin/bash
# named folder works
## docker run -it --link cp-pg-svr -p 8000:8000 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash
# unnamed folder works
## docker run -it --link cp-pg-svr -p 8000:8000 -v $(pwd):/usr/src/app/backend -v /usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash


## docker exec -it container-id /bin/bash

## in the shell :     
## cd /usr/src/app/nodeAppPostPg

## execute the script to setup env vars
## 
## npm install, then npm start
