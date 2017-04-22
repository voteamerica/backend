#
# create docker machine for jekyll
#

## docker build -t gc-jekyll --build-arg CACHEBUST=$(date +%s) --build-arg REPO=https://github.com/voteamerica/voteamerica.github.io --build-arg BRANCH_NAME=master .

## FOLDER
# IMPORTANT, jekyll can WIPE folders !!!! 
# cd VM_share/Jon/Documents/GitHub/voteUSfrontend/

## create MACHINE
# https://hub.docker.com/r/grahamc/jekyll/
# docker run --rm -it  --name gc-jekyll-svr -v $(pwd):/usr/src/app/frontend -p 4000:4000 gc-jekyll jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml

# docker run --rm -it --name gc-jekyll-svr -p 4000:4000 gc-jekyll jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml
# docker run --rm -it --name gc-jekyll-svr -p 4000:4000 gc-jekyll /bin/bash

# docker run --rm -it  --name gc-jekyll-svr -v $(pwd):/src -p 4000:4000 grahamc/jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml

# docker run --rm -v $(pwd):/src -p 4000:4000 grahamc/jekyll serve -H 0.0.0.0 --watch --config _config-dev.yml
# docker run --rm -v $(pwd):/src -p 4000:4000 grahamc/jekyll serve -H 0.0.0.0
#
# docker run --name jekyll -v $(pwd):/usr/src/app -p 4000:4000 grahamc/jekyll build 

# https://samneirinck.com/2016/08/01/easy-jekyll-blogging-on-windows-using-docker/
# docker run --name jekyll -v $(pwd):/usr/src/app -p 4000:4000 jekyll/jekyll:pages

