FROM debian:jessie
# FROM alpine:3.1

# RUN apk --update add postgresql-client && rm -rf /var/cache/apk/*
RUN apt-get update && \
    apt-get install -y postgresql-client 
# && rm -rf /var/cache/apk/*

RUN apt-get update && \
    apt-get install -y git

ARG CACHEBUST=1
ARG BRANCH_NAME=docker-1
ARG REPO=https://github.com/jkbits1/backend

WORKDIR /usr/src/app/

RUN git clone --single-branch --branch $BRANCH_NAME $REPO \
&& cd /usr/src/app/backend/db \
&& git checkout $BRANCH_NAME

WORKDIR /usr/src/app/backend/db

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

# USER postgres

# RUN su -l postgres

RUN cd /usr/src/app/backend/db

COPY ./start_matching_engine.sh /usr/src/app/backend/docker/pg-client/start_matching_engine_dkr.sh

# ENTRYPOINT [ "../docker/pg-client/start_matching_engine_dkr.sh" ]
# ENTRYPOINT [ "../docker/pg-client/start_matching_engine.sh" ]
