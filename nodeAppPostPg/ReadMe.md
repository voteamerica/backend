Node app - 

  accepts POSTs to ip-address/driver and ip-address/rider
  Form data is inserted into relevant postGres STAGE table
    (WEBSUBMISSION_DRIVER/RIDER) 

  a GET to ip-address returns test data. This allows for a quick check that 
  service is running and connected to db.

Use testPage.html (and linked testPageScript.js) to test app
  testPageScript.js contains a line that refers to app location and route
      http://ip-address/driver
      http://ip-address/rider

      (change ip-address depending on app location)

#########################
STEPS TO INSTALL ON LINUX
#########################  

ENV VARS REQUIRED (will change for carpool_web account, using for now)

// db env vars
export PGHOST=ip
export PGUSER=username
export PGDATABASE=dbname
export PGPASSWORD=pwd
export PGPORT=5432

// node env var
export PORT=3000

cd /usr/local (or wherever we put our apps)

git clone https://github.com/voteamerica/backend

cd /voteamerica/backend/nodeAppPostPg

npm install // (installs dependencies)

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
