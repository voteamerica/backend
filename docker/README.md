# carpool Dockerfiles

## The two folders, nodeApp and pg-auto, contain the Dockerfiles and info to manually setup the docker dev environment.

## Ideally, these would be revised to have no manual steps and be part of a docker compose setup.

# 1) pg-auto
# cd .../voteUSbackend/docker/pg-auto
## check .sh files for LF

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=master .

# cd .../voteUSbackend
# execute run command, with volumes if required


# 2) nodeApp
## cd .../voteUSbackend/docker/nodeApp
## check .sh files for LF

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t pgres-cp --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/backend --build-arg BRANCH_NAME=master .

# cd .../voteUSbackend
# execute relevant run command, with volumes if required


# 3) jekyll
# cd .../voteUSbackend/docker/jekyll

## Use docker build step with REPO & BRANCH_NAME as relevant
## docker build -t gc-jekyll --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/jkbits1/voteamerica.github.io --build-arg BRANCH_NAME=master .

# IMPORTANT to be careful, jekyll can WIPE folders !!!! 
# cd .../voteUSfrontend/
# execute relevant run command, with volumes if required
