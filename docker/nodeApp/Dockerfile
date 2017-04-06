FROM node:6.6.0

EXPOSE 8000

RUN apt-get update

# for network testing 
RUN apt-get install -y netcat

# for editing 
RUN apt-get install -y vim-tiny

#
# It would be excellent to have this file run the
# following commands, where the contents
# of the nodeAppPostPg folder are files on the host as in:
# docker run -v $(pwd):/usr/src/app ...
#

# WORKDIR /usr/src/app/nodeAppPostPg

# RUN npm install

# RUN . ./scripts/expo

# RUN npm start

