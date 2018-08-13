#!/bin/bash

# pre-requisite : /etc/sudoers.d/docker
#username        ALL=(ALL)       NOPASSWD: /usr/bin/docker
#username        ALL=(ALL)       NOPASSWD: /usr/local/bin/docker-compose

# https://www.projectatomic.io/blog/2015/08/why-we-dont-let-non-root-users-run-docker-in-centos-fedora-or-rhel/


if [[ -x /usr/local/bin/docker ]]; then
    export DOCKER=/usr/local/bin/docker
else 
    export DOCKER=/usr/bin/docker
fi

export DOCKERCOMPOSE=/usr/local/bin/docker-compose

# check if docker commands need sudo or not
$DOCKER ps >/dev/null 2>&1
[[ $? != 0 ]] && {
    export DOCKER="sudo $DOCKER"
    export DOCKERCOMPOSE="sudo $DOCKERCOMPOSE"
}

