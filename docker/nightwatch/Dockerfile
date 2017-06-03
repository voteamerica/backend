FROM node:6.6.0

EXPOSE 8000
EXPOSE 5858
EXPOSE 8080

RUN apt-get update

# for network testing 
RUN apt-get install -y netcat

# for editing 
RUN apt-get install -y vim-tiny

RUN apt-get install -y git

#
# It would be excellent to have this file run the
# following commands, where the contents
# of the nodeAppPostPg folder are files on the host as in:
# docker run -v $(pwd):/usr/src/app ...
#

ARG CACHEBUST=1
ARG BRANCH_NAME=docker-1
ARG REPO=https://github.com/jkbits1/backend

WORKDIR /usr/src/app/

RUN git clone --single-branch --branch $BRANCH_NAME $REPO \
&& cd /usr/src/app/backend/db \
&& git checkout $BRANCH_NAME

WORKDIR /usr/src/app/backend/nodeAppPostPg

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

RUN cd /usr/src/app/backend/nodeAppPostPg

RUN npm install -g nightwatch

COPY ./run-tests.sh /

# ENTRYPOINT ["/bin/bash"]

CMD ["/run-tests.sh match2"]

