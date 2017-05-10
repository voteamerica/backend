# carpool Dockerfiles

## The two folders, nodeApp and pg-auto, contain the Dockerfiles and info to manually setup the docker dev environment.
## A third folder contains a dockerfile for the jekyll frontend server

## Work is under way to revise this process remove manual steps and become a docker compose setup.

# cd .../voteUSbackend/docker

# install compose if necessary
# https://docs.docker.com/compose/install/
# sudo -i 
# curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose 
# sudo chmod +x /usr/local/bin/docker-compose

# http://stackoverflow.com/questions/32612650/how-to-get-docker-compose-to-always-re-create-containers-from-fresh-images
# https://github.com/docker/compose/issues/1049
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up
# docker-compose -f ./compose/docker-compose-dev-build-test.yml up

# docker-compose -f ./compose/docker-compose-static-ip.yml up
# docker-compose -f ./compose/docker-compose-static-ip-dev.yml up
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --build
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --force-recreate
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up -d --force-recreate --remove-orphans

## clearing up for new builds (not a one-step process)

# clear
# docker-compose rm -f
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml down

# misc tidy
# http://stackoverflow.com/questions/36663809/how-to-remove-all-docker-volumes
# https://github.com/chadoe/docker-cleanup-volumes

# effective but slowest
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --no-cache

# cache bust works, but needs a separate call for each service
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-pg-server
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-nodejs
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-front-end
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=thanks-redirect cp-front-end


## Test fe PR
#
# 1) on your local fork, create a branch pr... for the PR (https://help.github.com/articles/checking-out-pull-requests-locally/)
# push this to origin (not upstream)
#
# 2) create specific build of front machine using --build-arg BRANCH_NAME=pr...
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=pr270 cp-front-end
#
# 3) use docker-compose to create local system
# docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up



# 1) pg-auto
# cd .../voteUSbackend/docker/pg-auto
## check .sh files for LF

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=master .

# cd .../voteUSbackend
# execute run command (with volumes if required)
# default run command (no volumes)
# docker run --rm --name cp-pg-svr -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp 


# 2) nodeApp
## cd .../voteUSbackend/docker/nodeApp
## check .sh files for LF

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t carpool --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend  --build-arg BRANCH_NAME=patch-redirect .

# cd .../voteUSbackend
# execute relevant run command, with volumes if required
# default run command (no volumes)
# docker run --rm -it --link cp-pg-svr -p 8000:8000 carpool /bin/bash

# 3) jekyll
# cd .../voteUSbackend/docker/jekyll

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t gc-jekyll --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/voteamerica.github.io --build-arg BRANCH_NAME=jekyll-dev .

# IMPORTANT to be careful, jekyll can WIPE folders !!!! 
# cd .../voteUSfrontend/
# execute relevant run command, with volumes if required
# default run command (no volumes)
# docker run --rm -it --name gc-jekyll-svr -p 4000:4000 gc-jekyll jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml
