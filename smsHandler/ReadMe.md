SMS handler app - 

Reads db and sends sms messages

#########################
STEPS TO INSTALL ON LINUX
#########################  

ENV VARS REQUIRED 

// db env vars - tcp
export PGHOST=ip
export PGUSER=username
export PGDATABASE=dbname
export PGPASSWORD=pwd
export PGPORT=5432

// db env vars - socket
export PGHOST=/tmp
export PGDATABASE=carpool
// NOTE may need new login role for carpool
export PGUSER=carpool

// 30 seconds delay between sweeps
export CP_DELAY=30000

export TWILIO_ACCOUNT_SID=
export TWILIO_AUTH_TOKEN=
export TWILIO_NUMBER=

// go to preferred temporary area for install process
cd /tmp

git clone https://github.com/voteamerica/backend

cd voteamerica/backend/smsHandler

npm install // (installs dependencies)

copy files to /opt/carpool/smsHandler
 
cd /opt/carpool/smsHandler

// start app - for basic test, ctrl-c to exit
npm start

// start app - managed, auto-restart, resource monitoring etc. 
// see these pages for more info
// https://www.npmjs.com/package/pm2
// http://pm2.keymetrics.io/

pm2 start index.js

//stop app 
pm2 stop all // only one app, so this is ok - better to use app id, though

monitor app 
pm2 list
