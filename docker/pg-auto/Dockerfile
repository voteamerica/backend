FROM postgres:9.6.2

EXPOSE 5432

# duplicate these steps from postgres dockerfile - may be able to remove later
# COPY docker-entrypoint.sh /usr/local/bin/
# RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
# 

RUN apt-get update
RUN apt-get install -y git

ARG CACHEBUST=1
ARG BRANCH_NAME=docker-1
ARG REPO=https://github.com/jkbits1/backend

WORKDIR /usr/src/app/

RUN git clone --single-branch --branch $BRANCH_NAME $REPO backend \
&& cd /usr/src/app/backend/db \
&& git checkout $BRANCH_NAME

WORKDIR /usr/src/app/backend/db

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

# USER postgres

RUN su -l postgres

RUN cd /usr/src/app/backend/db

COPY create_fresh_carpool_db2.sh /docker-entrypoint-initdb.d/

# ENTRYPOINT ["docker-entrypoint.sh"]

# CMD ["postgres"]
