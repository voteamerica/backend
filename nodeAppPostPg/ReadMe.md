# Nodejs App

This app handles all requests and submissions from the front-end. Together with the Postgres database, this app provides the bulk of the services of the Carpool Vote system.

## Development

The app is built with [TypeScript](https://www.typescriptlang.org/index.html). Install Typescript on your development machine from [here](https://www.typescriptlang.org/#download-links). The mainstream editors support Typescript, and it is also possible to compile the files manually as below.

```
cd NodeAppPostPg
```

Work on the .ts files, and compile them, as show below, to create the .js files

```
tsc -p .

tsc  --target es2017 -w -p .
```

## Operator page - (instructions are a work in progress)

NOTE: Looking to expand the operator page? That's great, thank you! It's most effective to get in touch with the organisers and we'll provide help and guidance.

Here are the steps to adding a new area to the operator page.

1. Find table mentioned in `DbDefsTables`

Add the table if it doesn't exist.

2. Add a query to `dbQueries.ts` as follows:

NOTE: this instructions deal with Select queries only. If there is a Where clause for the query, that's added in a later step.

Add a function for the query and export this function in `module.exports`. We recommend using the helper functions that you can see used for other queries. The property from Step 1 is used for the query function.

3. Add a route handler support function to `routeFunctions.ts`

It's most likely that your query will return a list of items. So follow the pattern of `getUsersListInternal()`. Adjust `results` for logging and later checks.

NOTES:

a. If you want to add a Where clause, look at `getUsersInternal` to see how that is done. IMPORTANT: Do follow the existing pattern as it is, as it creates a function to be called later. So don't just add the clause as text.

b. Do put `Internal` as part of your new function name, this helps other volunteers be aware this function returns data and does not respond directly to a http request.

4. Add the route handler to `index.ts`

Create a function that follows the pattern of `getUsersListHandler`.

Make the bad request error specific to this route.

5. Add the secure route within `server.register()`

Follow the pattern of `server.route()` for path `/users/list`.

## Installation on linux - notes for deployment

DATABASE
Run matches.sql

ENV VARS REQUIRED

// db env vars - tcp
export PGHOST=ip
export PGUSER=username
export PGDATABASE=dbname
export PGPASSWORD=pwd
export PGPORT=5432

// db env vars - socket
// export PGHOST=/tmp
// export PGDATABASE=carpool
// export PGUSER=carpool_web

// node env var
export PORT=3000

// go to preferred temporary area for install process
cd /tmp

git clone https://github.com/voteamerica/backend

cd voteamerica/backend/nodeAppPostPg

npm install // (installs dependencies)

copy files to /opt/carpool/web
 
cd /opt/carpool/web 

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

### typescript notes

https://stackoverflow.com/questions/31173738/typescript-getting-error-ts2304-cannot-find-name-require

https://blogs.msdn.microsoft.com/typescript/2016/06/15/the-future-of-declaration-files/

### Legacy notes
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
