FROM postgres:latest
ENV CARPOOL_DATABASE_NAME=LIVE
ENV CARPOOL_SOURCE_FILES=/db
RUN mkdir ${CARPOOL_SOURCE_FILES}
ADD . ${CARPOOL_SOURCE_FILES}
ADD ./create_fresh_carpool_db_docker.sh /docker-entrypoint-initdb.d
VOLUME /var/lib/postgresql/data

