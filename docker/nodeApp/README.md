#
# create docker machine for node app
#

## FOLDER 
# cd VM_share/Jon/Documents/GitHub/voteUSbackend/docker/pg-auto

## build IMAGE
## docker build -t carpool --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=docker-1 .

## FOLDER 
# cd VM_share/Jon/Documents/GitHub/voteUSbackend

## create MACHINE
## (links to postgres docker machine)
## docker run --rm -it --link cp-pg-svr -p 8000:8000 carpool /bin/bash
#
## docker run --rm --entrypoint /usr/src/app/backend/docker/nodeApp/expo-start.sh -it --link cp-pg-svr -p 8000:8000 carpool /bin/bash
## docker run --rm -it --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 carpool /bin/bash
## docker run --rm --entrypoint="" -it --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 carpool /bin/bash

# dev versions
## docker run --rm -it --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash
# expo-start.sh is current dockerfile entrypoint, so the above is equivalent to this command
## docker run --rm -it --entrypoint /usr/src/app/backend/docker/nodeApp/expo-start.sh --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash
#
## docker run -it --entrypoint /usr/src/app/backend/docker/nodeApp/expo-bash.sh --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash
## docker run -it --entrypoint="" --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash

## docker run -it --link cp-pg-svr -p 8000:8000 -p 5858:5858 -p 8080:8080 -v $(pwd):/usr/src/app/backend -v node_app_node_modules:/usr/src/app/backend/nodeAppPostPg/node_modules/ carpool /bin/bash

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
