'use strict';

const Hapi        = require('hapi');
const Pool        = require('pg').Pool;
const Good        = require('good');
const GoodFile    = require('good-file');

const config      = require('./dbInfo.js');
const logOptions  = require('./logInfo.js');

const dbQueries   = require('./dbQueries.js');
const postgresQueries = require('./postgresQueries.js');
const logging     = require('./logging.js');

const routeFns = require('./routeFunctions.js');

config.user       = process.env.PGUSER;
config.database   = process.env.PGDATABASE;
config.password   = process.env.PGPASSWORD;
config.host       = process.env.PGHOST;
config.port       = process.env.PGPORT;

// const pool = new Pool(config);
// not passing config causes Client() to search for env vars
const pool = new Pool();
const server = new Hapi.Server();

routeFns.setPool(pool);

const OPS_INTERVAL  = 300000; // 5 mins
const DEFAULT_PORT  = process.env.PORT || 3000;

var appPort = DEFAULT_PORT;

logOptions.ops.interval = OPS_INTERVAL;

server.connection({ 
  port: appPort, 
  routes: { 
    cors: true 
  } 
});

server.route({
  method: 'GET',
  path: '/',
  handler: routeFns.getAnon
});

server.route({
  method: 'POST',
  path: '/' + routeFns.DRIVER_ROUTE,
  handler: routeFns.postDriver
});

server.route({
  method: 'POST',
  path: '/' + routeFns.RIDER_ROUTE,
  handler: routeFns.postRider
});

server.route({
  method: 'POST',
  path: '/' + routeFns.HELPER_ROUTE,
  handler: routeFns.postHelper
});

server.route({
  method: 'GET',
  path: '/' + routeFns.UNMATCHED_DRIVERS_ROUTE,
  handler: routeFns.getUnmatchedDrivers
});

server.route({
  method: 'GET',
  path: '/matches',
  handler: (req, reply) => {
    var results = {
      success: 'GET matches: ',
      failure: 'GET matches: ' 
    };

    req.log();

    postgresQueries.dbGetMatchesData(pool, dbQueries.dbGetMatchesQueryString, reply, results);
  }
});

server.route({
  method: 'GET',
  path: '/match-rider/{uuid}',
  handler: (req, reply) => {
    var results = {
      success: 'GET match-rider: ',
      failure: 'GET match-rider: ' 
    };

    req.log();

    postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchRiderQueryString, 
                            req.params.uuid, reply, results);
  }
});

server.route({
  method: 'GET',
  path: '/match-driver/{uuid}',
  handler: (req, reply) => {
    var results = {
      success: 'GET match-driver: ',
      failure: 'GET match-driver: ' 
    };

    req.log();

    postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchDriverQueryString, 
                            req.params.uuid, reply, results);
  }
});

server.route({
  method: 'GET',
  // method: 'POST',
  path: '/' + routeFns.CANCEL_RIDE_REQUEST_ROUTE,
  handler: routeFns.cancelRideRequest
});

server.route({
  method: 'GET',
  path: '/' + routeFns.CANCEL_RIDER_MATCH_ROUTE,
  handler: routeFns.cancelRiderMatch
});

server.route({
  method: 'GET',
  path: '/' + routeFns.CANCEL_DRIVE_OFFER_ROUTE,
  handler: routeFns.cancelDriveOffer
});


server.route({
  method: 'DELETE',
  path: '/' + routeFns.DELETE_DRIVER_ROUTE,
  handler: routeFns.cancelRideOffer
});

server.route({
  method: 'PUT',
  path: '/' + routeFns.PUT_RIDER_ROUTE,
  handler: routeFns.rejectRide
});

server.route({
  method: 'PUT',
  path: '/' + routeFns.PUT_DRIVER_ROUTE,
  handler: routeFns.confirmRide
});

server.register({
    register: Good,
    options:  logOptions
  }
  ,
  err => {
    if (err) {
      return console.error(err);
    }

    server.start(err => {
      if (err) {
          throw err;
      }

      console.log(`Server running at: ${server.info.uri} \n`);

      console.log("driver ins: " + dbQueries.dbGetInsertDriverString());
      console.log("rider ins: " + dbQueries.dbGetInsertRiderString());
      console.log("cancel ride fn: " + dbQueries.dbCancelRideRequestFunctionString());
      console.log("reject ride fn: " + dbQueries.dbRejectRideFunctionString());
      console.log("ops interval:" + logOptions.ops.interval);
    });
  }
);

logging.logReqResp(server, pool);
