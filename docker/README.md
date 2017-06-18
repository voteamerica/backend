# Docker environments for carpool-vote 

#### There are two main types of environments - development and automated tests

Each environment is created using docker compose. Previously this process was done with manual steps to create the individual docker machines.

For the development environment, folders nodeApp and pg-auto contain the Dockerfiles (and details to manually setup the docker dev environment). A third folder contains a Dockerfile for the jekyll frontend server. Finally, the pg-client folder contains the environment to run the matching engine.

The testing environment has two further folders, one for a selenium standalone server, and another for the app that runs the tests.

## Install docker compose (if not already installed)
#### Details at [the docker compose install page](https://docs.docker.com/compose/install)
e.g. boot2docker requires these steps
``` 
sudo -i
curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Development enviroments

#### Create the necessary local setup
**IMPORTANT:**
1) It is best to clone from a fork of the carpoolvote repo's rather than directly. Use the commands below with your own forked repo in place of the carpoolvote repo's.

2) Folders for the frontend and backend repo's must be at the same level, e.g. both directly beneath the GitHub folder

**Front-end code folder**

The default value for the front-end folder is `voteUSfrontend`. This can be changed by either editing the `COMPOSE_DEV_FE_DIR` variable in the `.env` file (in the docker folder) or by setting this as an environment variable.

```export COMPOSE_DEV_FE_DIR=...``` See the [docker documentation](https://docs.docker.com/compose/compose-file/compose-file-v2/#variable-substitution) for details.

It is assumed that you already have a a local clone of the frontend repo, but if not, create one:

`git clone https://github.com/voteamerica/voteamerica.github.io voteUSfrontend`

**Back-end code folder**

If it does not already exist, clone the backend git repo. It can be named however you wish. Here it is called `voteUSbackend`.

`git clone https://github.com/voteamerica/backend voteUSbackend`

### 1) Front-end Development

#### Go to the docker folder ... 
... of your backend repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Create specific machines (if required)
This might be necessary if you are testing against a version of either the node app or db that is under development. 

```
sh ./specific-machine-local-front.sh cp-nodejs $(date +%s) https://github.com/voteamerica/backend master
sh ./specific-machine-local-front.sh cp-pg-server $(date +%s) https://github.com/voteamerica/backend master
 ```

#### create local system
```
sh ./start-compose-local-frontend.sh

docker-compose -f ./compose/full-stack-local/docker-compose-local-frontend.yml up
```

### 2) Full-stack Development
This works directly from the files in the folders for your front and back-end repos.

#### Go to the docker folder ... 
##### ... of your forked repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### 2) use docker-compose to create local system
```
sh ./start-compose-local-fullstack.sh

docker-compose -f ./compose/full-stack-local/docker-compose-local-fullstack.yml up
```

## Automated Testing 
NOTE: app will not execute correctly in the standard browser, see the VNC steps below

There are three types, depending on whether it is required to override the code in github repos with code on the local machine.

### 1) Github repos only - ignores any local code

#### Create specific machines (if required)
E.g. for specific front-end, node app, db or test-runner repo branches.
 ```
sh ./specific-machine-test.sh cp-front-end $(date +%s) https://github.com/jkbits1/voteamerica.github.io self-service-changes
sh ./specific-machine-test.sh cp-nodejs $(date +%s)
sh ./specific-machine-test.sh cp-test-runner $(date +%s) https://github.com/jkbits1/backend docker-test
 ```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests.sh
sh ./start-compose-tests.sh match
```

### 2) Local development environment - frontend 

#### This overrides the frontend github repo with local code.

#### Create specific machines (if required)
 ```
sh ./specific-machine-test-frontend.sh cp-nodejs $(date +%s)
sh ./specific-machine-test-frontend.sh cp-test-runner $(date +%s) https://github.com/jkbits1/backend docker-test
 ```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests-frontend.sh
sh ./start-compose-tests-frontend.sh match
```

### 3) Local development environment - fullstack 

#### Local code overrides github repos for frontend, backend & test runner.

#### Create specific machines (if required)
Possibly needed if change change the run-tests.sh script in the nightwatch docker folder. The same applies to changes to scripts in the other docker folders.
```
sh ./specific-machine-test-fullstack.sh cp-test-runner $(date +%s) https://github.com/jkbits1/backend docker-test
```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests-fullstack.sh
sh ./start-compose-tests-fullstack.sh match
```


### review c) d)

### c) Test Front-end PR
#### 1) on your local fork, create a branch pr... for the PR [(how to do this)](https://help.github.com/articles/checking-out-pull-requests-locally/)
Push this new PR to origin (not upstream)

#### 2) create specific build of front-end docker machine using --build-arg BRANCH_NAME=pr...
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=pr270 cp-front-end`

#### 3) use docker-compose to create the full local system
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up`

### d) Test Backend-end PR
#### 1) on your local fork, create a branch pr... for the PR [(how to do this)](https://help.github.com/articles/checking-out-pull-requests-locally/)

Checkout this new pr branch.

Now, if your repo is set up for travis, simply:

i) merge with master if PR is behind master. If not merged automatically, stop at this step and mention this on the PR issue page. Otherwise, continue.

ii) add .travis.yml if necessary (e.g. https://github.com/jkbits1/backend/blob/docker-test/.travis.yml)

iii) push this new PR to origin (not upstream)

iv) watch travis test the PR (e.g. https://travis-ci.org/jkbits1/backend/builds/240592981)


#### 2) create specific build of front-end docker machine using --build-arg BRANCH_NAME=pr...
```
. ./specific-machine-test.sh cp-nodejs $(date +%s) https://github.com/jkbits1/backend pr162
. ./specific-machine-test.sh cp-pg-server $(date +%s) https://github.com/jkbits1/backend pr162
```

#### 3) Run the tests
This script uses docker-compose to create the full local system. The parameter specifies a nightwatch test group.

```
sh ./start-compose-tests-pr.sh
sh ./start-compose-tests-pr.sh match
```

#### 4) Optional: use VNC viewer to watch the tests execute





### Manual test steps 

#### 3) test environment
In a new terminal, run
`docker exec -it $(docker ps | grep nigh | cut -c 1-4) /bin/bash`

Or step by step -
`docker ps | grep nigh | cut -c 1-4`
This provides 4 characters of the docker machine's alphanumeric id. Type `docker exec -it ctr-id /bin/bash`, replacing ctr-id with the numbers/letters of the id, to use the testing machine

For full line of info, type `docker ps | grep nigh` 


#### 5) run nightwatch with script
Use this script with no parameter for default tests, or with a parameter for specific test group
`. ./run-tests.sh`
`. ./run-tests.sh match2`

#### ) close tidily when done
ctrl-c twice to exit, then
`docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml down`


All tests

`nightwatch`

Specific group of tests

`nightwatch --group quick`
#### 6) optional - use a vnc viewer (e.g. [RealVNC](https://www.realvnc.com/download/viewer/)) to watch the test being executed on vnc://localhost:5900 (don't type vnc:// for RealVNC viewer)

#### 7) optional - create specific pg client
```
. ./specific-machine-local.sh cp-nodejs
. ./specific-machine-test.sh cp-nodejs $(date +%s)
. ./specific-machine-local.sh cp-nodejs $(date +%s) https://github.com/jkbits1/backend ts-route 
```

 
#### useful suggestions for managing tests structure
https://github.com/nightwatchjs/nightwatch/pull/37


## There are several docker compose files to support various setups
#### http://stackoverflow.com/questions/32612650/how-to-get-docker-compose-to-always-re-create-containers-from-fresh-images
#### https://github.com/docker/compose/issues/1049

As above

DEV `docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up`

TEST `docker-compose -f ./compose/docker-compose-dev-build-test.yml up`


MISC OTHERS
```
#### docker-compose -f ./compose/docker-compose-static-ip.yml up
#### docker-compose -f ./compose/docker-compose-static-ip-dev.yml up
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --build
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up --force-recreate
#### docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up -d --force-recreate --remove-orphans
```

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

Example of using specific repo branch -`docker-compose -f ./compose/full-stack-test/docker-compose-dev-build-test.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=thanks-redirect cp-front-end`

## network 
https://stackoverflow.com/questions/42373954/create-network-failed-to-allocate-gateway-x-x-x-x-address-already-in-use-i

docker network ls, docker network inspect ...



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

### debugging node with vs code
#### very useful
https://blog.docker.com/2016/07/live-debugging-docker/

https://code.visualstudio.com/docs/nodejs/nodejs-debugging
https://alexanderzeitler.com/articles/debugging-a-nodejs-es6-application-in-a-docker-container-using-visual-studio-code/

### virtualbox portforward list, update
```
./vboxmanage showvminfo default | grep 'host port'
.\VBoxManage modifyvm "default" --natpf1 "NodeApp,tcp,127.0.0.1,8000,,8000"
.\VBoxManage modifyvm "default" --natpf1 "NodeDebug,tcp,127.0.0.1,5858,,5858"
.\VBoxManage modifyvm "default" --natpf1 "NodeDebug2,tcp,127.0.0.1,8080,,8080"
.\VBoxManage modifyvm "default" --natpf1 "Postgres,tcp,127.0.0.1,5432,,5432"
.\VBoxManage modifyvm "default" --natpf1 "jekyll,tcp,127.0.0.1,4000,,4000"
.\VBoxManage modifyvm "default" --natpf1 "pulp,tcp,127.0.0.1,1337,,1337"



```
