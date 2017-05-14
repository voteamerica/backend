# Docker setup for carpool-vote 

The setup is created using docker compose. Previously this process was done with manual steps to create the individual docker machines.

Folders nodeApp and pg-auto contain the Dockerfiles (and info to manually setup the docker dev environment). A third folder contains a Dockerfile for the jekyll frontend server.

## Install docker compose (if not already installed)
#### Details at [the docker compose install page](https://docs.docker.com/compose/install)
e.g. boot2docker requires these steps
``` 
sudo -i 
curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose 
sudo chmod +x /usr/local/bin/docker-compose
```

## Go to the docker folder of your forked repo (here known as voteUSbackend)
`cd .../voteUSbackend/docker`

## There are several docker compose files to support various setups
#### http://stackoverflow.com/questions/32612650/how-to-get-docker-compose-to-always-re-create-containers-from-fresh-images
#### https://github.com/docker/compose/issues/1049
DEV `docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up`

TEST `docker-compose -f ./compose/docker-compose-dev-build-test.yml up`

MISC
```
#### docker-compose -f ./compose/docker-compose-static-ip.yml up
#### docker-compose -f ./compose/docker-compose-static-ip-dev.yml up
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --build
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --force-recreate
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up -d --force-recreate --remove-orphans
```

## Test Front-end PR
#### 1) on your local fork, create a branch pr... for the PR [(how to do this)](https://help.github.com/articles/checking-out-pull-requests-locally/)
Push this new PR to origin (not upstream)

#### 2) create specific build of front-end docker machine using --build-arg BRANCH_NAME=pr...
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=pr270 cp-front-end`

#### 3) use docker-compose to create the full local system
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up`


## Automated Testing
#### Create specific machines if appropriate
#### 1) use docker-compose to create local system
`docker-compose -f ./compose/docker-compose-dev-build-test.yml up`
#### 2) `docker ps`, then `exec` into carpool machine
#### 3) go to nightwatch folder
#### 4) run nightwatch

## Clearing up for new builds (not a one-step process)

### full clearing
```
docker-compose rm -f
docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml down
```

## Miscellaneous tidying steps (not yet prioritized)
http://stackoverflow.com/questions/36663809/how-to-remove-all-docker-volumes
https://github.com/chadoe/docker-cleanup-volumes

### effective but slowest
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --no-cache`

## Cache Bust builds - need a separate call for each service
```
docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-pg-server
docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-nodejs
docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) cp-front-end
```
Example of using specific repo branch -`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=thanks-redirect cp-front-end`


## Running individual docker machines

## 1) pg-auto
`cd .../voteUSbackend/docker/pg-auto`

check .sh files for LF

Use docker build step with REPO & BRANCH_NAME as relevant -
`docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=master .`

`cd .../voteUSbackend`
#### execute run command (with volumes if required)
default run command (no volumes) -
`docker run --rm --name cp-pg-svr -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d pgres-cp` 

## 2) nodeApp
`cd .../voteUSbackend/docker/nodeApp`

check .sh files for LF

Use docker build step with REPO & BRANCH_NAME as relevant -
`docker build -t carpool --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend  --build-arg BRANCH_NAME=patch-redirect .`

`cd .../voteUSbackend`
#### execute relevant run command, with volumes if required
default run command (no volumes) -
`docker run --rm -it --link cp-pg-svr -p 8000:8000 carpool /bin/bash`

## 3) jekyll
`cd .../voteUSbackend/docker/jekyll`

#### Use docker build step with REPO & BRANCH_NAME as relevant
`docker build -t gc-jekyll --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/voteamerica.github.io --build-arg BRANCH_NAME=jekyll-dev .`

### IMPORTANT to be careful, jekyll can WIPE folders !!!! 
`cd .../voteUSfrontend/`
#### execute relevant run command, with volumes if required
default run command (no volumes) -
`docker run --rm -it --name gc-jekyll-svr -p 4000:4000 gc-jekyll jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml`
