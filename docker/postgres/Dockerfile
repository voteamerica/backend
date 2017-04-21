FROM postgres:9.5.4

COPY ./init-user-db-cp.sh /docker-entrypoint-initdb.d/

EXPOSE 5432

#
# This dockerfile is not used currently.
# However, it would be excellent to have this 
# file run the following commands, where the contents
# of the db folder are files on the host as in:
# docker run -v $(pwd):/usr/src/app ...
#

RUN apt-get update
RUN apt-get install -y git

WORKDIR /usr/src/app/

# RUN git clone https://github.com/jkbits1/backend
RUN git clone --single-branch --branch docker https://github.com/jkbits1/backend

WORKDIR /usr/src/app/backend/db

RUN git checkout docker
RUN git fetch origin
RUN git merge origin/docker

# USER postgres

RUN su -l postgres

RUN cd /usr/src/app/backend/db

# COPY create_fresh_carpool_db2.sh /docker-entrypoint-initdb.d/
COPY init-user-db.sh /docker-entrypoint-initdb.d/

RUN ls /docker-entrypoint-initdb.d/

# COPY /usr/src/app/backend/db/scripts/create_fresh_carpool_db2.sh /docker-entrypoint-initdb.d/
# COPY /usr/local/bin/ /test/

# RUN . /usr/src/app/backend/db/scripts/create_fresh_carpool_db2.sh carpool

# RUN /bin/bash -c "source ./scripts/create_fresh_carpool_db2.sh"

# these two lines execute manually, but not from the dockerfile
# RUN . ./scripts/create_fresh_carpool_db2.sh
# RUN . ./scripts/load_functions.sh carpool

# RUN . ./scripts/init_cp_web_role.sh carpool

