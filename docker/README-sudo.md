# pre-requisite : /etc/sudoers.d/docker
#username        ALL=(ALL)       NOPASSWD: /usr/bin/docker
#username        ALL=(ALL)       NOPASSWD: /usr/bin/docker-compose

# https://www.projectatomic.io/blog/2015/08/why-we-dont-let-non-root-users-run-docker-in-centos-fedora-or-rhel/

Also, define aliases to simplify command line operations
alias docker="sudo /usr/bin/docker"
alias docker-compose="sudo /usr/bin/docker-compose"
