[![Build Status](https://travis-ci.org/voteamerica/backend.svg?branch=master)](https://travis-ci.org/voteamerica/backend)

# Carpool Vote - Backend repo

Carpool Vote connects volunteer drivers with anybody who needs a ride to claim their vote. We are a nonpartisan organisation: Our goal is to increase voter turnout and improve representation.

We successfully deployed the site for the US 2016 election and now we are working hard on improvements for the various US elections in 2017 and beyond. We're a team of volunteers from around the world, working pro bono in our free time alongside our day jobs. As a result, we need all the help we can get, and any contributions would be gratefully appreciated.

## Slack

We have a [Slack team](https://carpool-vote.slack.com/). Please [email us](mailto:slack@carpoolvote.com) if you would like to join.

## Overview

Everything related to the back-end of Carpool Vote exists in this repo. The main components are a Nodejs app that provides services to the front-end and a Postgres database. Other components, written in both Python and Nodejs, send emails, SMS messages, and provide other functions to support the Nodejs app and the database.

### Travis CI
[Travis CI](https://travis-ci.org/voteamerica/backend) tests are run automatically against all PRs. 

### Development environment and automated tests
Docker and docker-compose are used to provide contributors with a variety of development environments and automated tests.

Details can be found [here](https://github.com/voteamerica/backend/tree/master/docker)

### Nodejs App

This is [here](https://github.com/voteamerica/backend/tree/master/nodeAppPostPg).

### Database

The database is Postgres. 
This is [here](https://github.com/voteamerica/backend/tree/master/db)

### Working on the front-end
The front-end repo is [here](https://github.com/voteamerica/voteamerica.github.io). The main site is available at http://carpoolvote.com/

## Contributing

If you're interested in contributing to this project, read our guidelines for [how to contribute](docs/contributing.md) first, and also please be aware of our [code of conduct](https://github.com/voteamerica/voteamerica.github.io/blob/master/docs/code-of-conduct.md).


# Alternate Docker configuration for backend
- make sure you have docker and docker-compose installed
- Clone your fork of the backend repo
- In your /etc/hosts file, define
	127.0.0.1 api.carpoolvote.com
- Build the docker images
	- docker-compose -f docker-compose-build.yml build
- Run the containers
	- docker-compose up -d
- You can now run the front end (jekyll), it will reach the backend on https://api.carpoolvote.com/live
	- Note: In this test environment, a self-signed certificate is used by the backend instead of the real official certificate from LetsEncrypt. That will cause some errors in your browser. You will likely have to add an exception to allow it.
