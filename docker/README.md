# carpool Dockerfiles

## The two folders, nodeApp and pg-auto, contain the Dockerfiles and info to manually setup the docker dev environment.

## Ideally, these would be revised to have no manual steps and be part of a docker compose setup.

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
