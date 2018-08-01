#!/bin/bash

# pre-requisite : /etc/sudoers.d/docker
#username        ALL=(ALL)       NOPASSWD: /usr/bin/docker
#username        ALL=(ALL)       NOPASSWD: /usr/bin/docker-compose

# https://www.projectatomic.io/blog/2015/08/why-we-dont-let-non-root-users-run-docker-in-centos-fedora-or-rhel/

export DOCKER=/usr/bin/docker
export DOCKERCOMPOSE=/usr/bin/docker-compose

# check if docker commands need sudo or not
docker ps >/dev/null 2>&1
[[ $? != 0 ]] && {
    export DOCKER="sudo /usr/bin/docker"
    export DOCKERCOMPOSE="sudo /usr/bin/docker-compose"
}

