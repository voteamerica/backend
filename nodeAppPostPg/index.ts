'use strict';

const Hapi        = require('hapi');
const moment      = require('moment');
const Pool        = require('pg').Pool;
const Good        = require('good');
const GoodFile    = require('good-file');

const config      = require('./dbInfo.js');
const logOptions  = require('./logInfo.js');

const dbQueries   = require('./dbQueries.js');
const logging     = require('./logging.js');
const postgresQueries = require('./postgresQueries.js');

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
  handler: (req, reply) => {
    var results = {
      success: 'GET carpool: ',
      failure: 'GET error: ' 
    };

    req.log();

    postgresQueries.dbGetData(pool, dbQueries.dbGetQueryString, reply, results);
  }
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

function getExecResultStrings(tableName) {
    var resultStrings = {
      success: ' fn called: ',
      failure: ' fn call failed: ' 
    }

    resultStrings.success = tableName + resultStrings.success; 
    resultStrings.failure = tableName + resultStrings.failure; 

    return resultStrings;
}

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
  method: 'DELETE',
  path: '/' + routeFns.DELETE_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getExecResultStrings('cancel ride: ');

    req.log();

    console.log("delete payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbCancelRideFunctionString, 
                      getCancelRidePayloadAsArray,
                      req, reply, results);
  }
});

server.route({
  method: 'PUT',
  path: '/' + routeFns.PUT_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getExecResultStrings('reject ride: ');

    req.log();

    console.log("reject payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbRejectRideFunctionString, 
                      getRejectRidePayloadAsArray,
                      req, reply, results);
  }
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
      console.log("cancel ride fn: " + dbQueries.dbCancelRideFunctionString());
      console.log("reject ride fn: " + dbQueries.dbRejectRideFunctionString());
      console.log("ops interval:" + logOptions.ops.interval);
    });
  }
);

logging.logReqResp(server, pool);

function getRejectRidePayloadAsArray(req, payload) {
  return [
        payload.UUID
    ]
}

function getCancelRidePayloadAsArray(req, payload) {
  return [      
        payload.UUID
    ]
}

