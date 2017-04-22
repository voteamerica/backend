FROM grahamc/jekyll

RUN apt-get update

RUN apt-get install -y git

ARG CACHEBUST=1
ARG FE_PATH=/usr/src/app/frontend/
ARG BRANCH_NAME=master
ARG REPO=https://github.com/voteamerica/voteamerica.github.io

WORKDIR /usr/src/app/

RUN git clone --single-branch --branch $BRANCH_NAME $REPO frontend \
&& cd $FE_PATH \
&& git checkout $BRANCH_NAME

WORKDIR $FE_PATH

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

RUN cd $FE_PATH

# ENTRYPOINT ["jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml"]

ENTRYPOINT [""]
