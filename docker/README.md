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
exit
```

## Development enviroments

Carpool-vote is spread across two repos, one for front-end the other for backend. Although some setups below use only one, mostly it is necessary to have both installed on your development machine.

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

#### Create specific machines (if required)
This can be necessary for testing against a version of code that is under development or in a non-default branch and/or repo.

Example params to these scripts 

`cp-nodejs` the service name in the relevant docker-compose .yml file

`R` force rebuild

`https://github.com/voteamerica/backend` repo name

`master` branch name

More details below.

### 1) Front-end Development

#### Go to the docker folder ... 
... of your backend repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Create specific machines (if required)
This might be necessary if you are testing against a version of either the node app or db that is under development. 

```
sh ./specific-machine-local-frontend.sh cp-nodejs R https://github.com/voteamerica/backend master
sh ./specific-machine-local-frontend.sh cp-pg-server R https://github.com/voteamerica/backend master
 ```

#### Start the environment

```
sh ./start-compose-local-frontend.sh
```

Awesome, you are up and running! Head to http://localhost:4000 in your browser to see the running app.

##### Stopping & cleaning up the environment
Ctrl-C to finish, then tidy up with this command
```
docker-compose -f ./compose/full-stack-local/docker-compose-local-frontend.yml down
```

### 2) Full-stack Development
This works directly from the files in the folders for your front and back-end repos.

If you don't have a local clone of the front-end repo, create one as described above.

#### Create specific machines (if required)
This is not usually necessary for this setup. However, if you change package.json for the node app for a specific branch/repo pair, create a specific machine for that pair, otherwise the node_modules folder will not be installed correctly before the node app starts. For example,
```
sh ./specific-machine-local.sh cp-nodejs R https://github.com/jkbits1/backend auth-users
```

#### Go to the docker folder ... 
##### ... of your forked repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Start the environment

```
sh ./start-compose-local-fullstack.sh
```

Ctrl-C to finish, then tidy up with this command
```
docker-compose -f ./compose/full-stack-local/docker-compose-local-fullstack.yml down
```

## Automated Testing 

There are three types of tests, depending on whether it is required to override the code in github repos with code on the local machine.

#### Optional - use VNC viewer to watch tests excecute
The app, under the test setups, does not execute correctly in the standard browser. Instead, use a VNC viewer (e.g. [RealVNC](https://www.realvnc.com/download/viewer/)) to watch the test being executed on vnc://localhost:5900 (don't type vnc:// for RealVNC viewer)

### 1) Github repos only - ignores any local code

#### Go to the docker folder ... 
... of your backend repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Create specific machines (if required)
E.g. for specific front-end, node app, db or test-runner repo branches.
 ```
sh ./specific-machine-test.sh cp-front-end R https://github.com/jkbits1/voteamerica.github.io self-service-changes
sh ./specific-machine-test.sh cp-nodejs R
sh ./specific-machine-test.sh cp-test-runner R https://github.com/jkbits1/backend docker-test
 ```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests.sh
sh ./start-compose-tests.sh match
```

### 2) Local development environment - frontend 

#### This overrides the frontend github repo with local code.

#### Go to the docker folder ... 
... of your backend repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Create specific machines (if required)
##### e.g. to test a against a specific branch
 ```
sh ./specific-machine-test-frontend.sh cp-nodejs R
sh ./specific-machine-test-frontend.sh cp-test-runner R https://github.com/jkbits1/backend docker-test
 ```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests-frontend.sh
sh ./start-compose-tests-frontend.sh match
```

### 3) Local development environment - fullstack 

#### Local code overrides github repos for frontend, backend & test runner.

#### Go to the docker folder ... 
... of your backend repo (here named voteUSbackend)
`cd .../voteUSbackend/docker`

#### Create specific machines (if required)
This may be necessary when making changes to the run-tests.sh script in the nightwatch docker folder. The same applies to changes to scripts in the other docker folders.
```
sh ./specific-machine-test-fullstack.sh cp-test-runner R https://github.com/jkbits1/backend docker-test
```

#### Run the tests
Parameter is nightwatch test group. If not specified, a default is used.
```
sh ./start-compose-tests-fullstack.sh
sh ./start-compose-tests-fullstack.sh match
```

docker-compose -f ./compose/full-stack-test/docker-compose-test-fullstack.yml

## Common development tasks

### 1) Create a front-end PR that requires changes to tests
NOTE: this assumes that your front-end repo has travis CI enabled.

Some front-end code changes will require matching changes or extensions to the tests.
Once the front-end changes are ready (or at least under way), use the `Local development environment - fullstack` environment described above to confirm if tests now fail.

If so, follow these steps:

1) create a new branch in your back-end repo. In the front-end branch under development, change the `./travis.yml` file to refer to this repo and branch.

2) In the back-end branch, make the necessary changes to the test files. 

In the backend `travis.yml`, add a line to match up the backend branch with the frontend branch in the 
`before_script:` section, e.g. for the `slfsvc-ui-adjust` branch of the `jkbits1` repo:

```
  - ./docker/specific-machine-test-travis.sh cp-front-end R jkbits1/voteamerica.github.io slfsvc-ui-adjust 
```

Commit the changes and push this branch to your own repo origin. The back-end repo branch will fail the travis tests, this is expected.

3) Work on the front-end code and make the required test changes (in the backend repo) until tests for the revised front-end code pass. If you need assistance, ask on #backend channel of the Slack team and we will be happy to help you. **Do not** remove any tests without discussion with a senior repo member. If creating a PR that changes the tests, **clearly** mention this in the PR description.

4) Once the front-end code is ready, commit the changes and push this branch to your own repo origin. Do the same for any back-end test changes, as before. 

NOTE: the backend tests should pass now. On the travis page for your backend repo, find the failing backend branch and click Rebuild

5) The front-end repo should pass the travis tests once pushed to your origin. If not, there is a problem in either front-end code or the tests. Presuming the tests have passed, create a PR for the front-end.

6) The final steps below re-align the `travis.yml` files to the main branches. 

When the front-end branch is accepted, a PR can be created for the back-end branch with the revised tests. 

NOTE:  the backend PR should adjust the backend `travis.yml` file to refer to the main frontend repo and branch; this is to undo the change in step 2) above. Once the back-end PR is accepted, the final step is to adjust the front-end `./travis.yml` to once again refer to the main backend repo and branch. These final steps should be done **promptly** after the front-end PR is accepted.




### The following instructions are being reviewed

### 2) Test Front-end PR
#### 1) on your local fork, create a branch pr... for the PR [(how to do this)](https://help.github.com/articles/checking-out-pull-requests-locally/)
Push this new PR to origin (not upstream)

#### 2) create specific build of front-end docker machine using --build-arg BRANCH_NAME=pr...
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml build --build-arg CACHEBUST=$(date +%s) --build-arg BRANCH_NAME=pr270 cp-front-end`

#### 3) use docker-compose to create the full local system
`docker-compose -f ./compose/docker-compose-static-ip-dev-build.yml up`

### 3) Test Backend-end PR
#### 1) on your local fork, create a branch pr... for the PR [(how to do this)](https://help.github.com/articles/checking-out-pull-requests-locally/)

Checkout this new pr branch.

Now, if your repo is set up for travis, simply:

i) merge with master if PR is behind master. If not merged automatically, stop at this step and mention this on the PR issue page. Otherwise, continue.

ii) add .travis.yml if necessary (e.g. https://github.com/jkbits1/backend/blob/docker-test/.travis.yml)

iii) push this new PR to origin (not upstream)

iv) watch travis test the PR (e.g. https://travis-ci.org/jkbits1/backend/builds/240592981)


#### 2) create specific build of front-end docker machine using --build-arg BRANCH_NAME=pr...
```
. ./specific-machine-test.sh cp-nodejs R https://github.com/jkbits1/backend pr162
. ./specific-machine-test.sh cp-pg-server R https://github.com/jkbits1/backend pr162
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

#### 7) optional - create specific pg client
```
. ./specific-machine-local.sh cp-nodejs
. ./specific-machine-test.sh cp-nodejs R
. ./specific-machine-local.sh cp-nodejs R https://github.com/jkbits1/backend ts-route 
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
.\VBoxManage modifyvm "default" --natpf1 "vnc,tcp,127.0.0.1,5900,,5900"
.\VBoxManage modifyvm "default" --natpf1 "pulp,tcp,127.0.0.1,1337,,1337"
```

