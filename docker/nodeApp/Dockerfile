FROM node:8.11.4

EXPOSE 8000
EXPOSE 5858
EXPOSE 8080

RUN apt-get update

# for network testing 
RUN apt-get install -y netcat

# for editing 
RUN apt-get install -y vim-tiny

RUN apt-get install -y git

# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
# echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

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

RUN git clone --single-branch --branch $BRANCH_NAME $REPO backend \
    && cd /usr/src/app/backend/db \
    && git checkout $BRANCH_NAME

WORKDIR /usr/src/app/backend/nodeAppPostPg

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

RUN cd /usr/src/app/backend/nodeAppPostPg

RUN npm -v 
RUN npm install 
RUN npm install -g typescript

# # reasons for yarn params
# # https://github.com/yarnpkg/yarn/issues/2240#issuecomment-300762981
# # https://github.com/yarnpkg/yarn/issues/3223#issuecomment-296373273
# RUN cat package.json
# # RUN npm install
# RUN yarn
# # RUN yarn install --check-files
# # RUN yarn install --force

ENV PORT=8000 PGUSER=carpool_web PGDATABASE=carpoolvote

COPY ./expo-start.sh /
COPY ./expo-debug.sh /
COPY ./expo-bash.sh /

# these steps may be needed
# https://github.com/moby/moby/issues/27182
RUN chmod +x /expo-start.sh
RUN chmod +x /expo-debug.sh
RUN chmod +x /expo-bash.sh

CMD ["/expo-start.sh"]

# NOTES for dev support
# CMD ["/expo-debug.sh"]
# CMD ["/expo-bash.sh"]

# RUN tsc  --target es2017 -w -p . &
# node --inspect=0.0.0.0:5858 --inspect-brk index.js
