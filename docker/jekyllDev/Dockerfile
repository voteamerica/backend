# FROM jekyll/jekyll:pages
FROM grahamc/jekyll

RUN apt-get update

# for editing 
RUN apt-get install -y vim-tiny

RUN apt-get install -y git

# RUN apk --update add git vim

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

RUN npm install -g webpack
RUN npm install -g webpack-cli
RUN npm install -g webpack-merge

RUN echo "install yarn"

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install yarn

# test
# RUN yarn global add bs-platform

ARG CACHEBUST=1
ARG FE_PATH=/usr/src/app/frontend/
ARG BRANCH_NAME=master
ARG REPO=https://github.com/voteamerica/voteamerica.github.io

WORKDIR /usr/src/app/

RUN git clone --single-branch --branch $BRANCH_NAME $REPO frontend \
&& cd $FE_PATH \
&& git checkout $BRANCH_NAME

WORKDIR $FE_PATH

RUN pwd
RUN ls

RUN git fetch origin
RUN git merge origin/$BRANCH_NAME

# RUN npm install --only=dev

# This works, so will stick with npm for now. However, the yarn install sends a lot 
# less info to the console when it builds the bs-platform. It would be handy to get 
# npm to do the same.
RUN npm install 
# RUN yarn install --production=false
# RUN yarn

# WIP - maybe try these steps re global bsb on linux.
# https://github.com/BuckleScript/bucklescript/issues/2051#issuecomment-331387417
# For now, copy across the two reasonreact*.js files in the start script below.
# RUN bsb -make-world
RUN npx bsb -make-world

# run webpack as background task
# RUN webpack --watch --progress --info-verbosity verbose &

COPY ./_config-local-host.yml /
COPY ./_config-local-ip.yml /

COPY ./expo-start.sh /
RUN chmod +x /expo-start.sh

COPY ./expo-start-ip.sh /
RUN chmod +x /expo-start-ip.sh

RUN echo "expo-start.sh"
RUN more /expo-start.sh

RUN echo "expo-start-ip.sh"
RUN more /expo-start-ip.sh

# ENTRYPOINT ["jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml"]
# ENTRYPOINT [""]
# ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/expo-start.sh"]

# CMD ["/bin/bash"]
