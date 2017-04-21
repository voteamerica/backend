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

WORKDIR /usr/src/app/

# RUN git clone https://github.com/jkbits1/backend
RUN git clone --single-branch --branch docker https://github.com/jkbits1/backend

WORKDIR /usr/src/app/backend/nodeAppPostPg

RUN git checkout docker
RUN git fetch origin
RUN git merge origin/docker

RUN cd /usr/src/app/backend/nodeAppPostPg

RUN npm install

# can't get these two lines going yet
# RUN . ./scripts/expo.sh

ENV PORT=8000 PGHOST=$CP_PG_SVR_PORT_5432_TCP_ADDR PGUSER=carpool_web
ENV PGPASSWORD=$CP_PG_SVR_ENV_POSTGRES_PASSWORD PGDATABASE=carpoolvote

# ENTRYPOINT ["/usr/src/app/backend/nodeAppPostPg/scripts/expo.sh"]

# CMD ["npm start"]

