'use strict';

import * as Hapi        from 'hapi';
const Pool        = require('pg').Pool;
const Good        = require('good');
const GoodFile    = require('good-file');

const config      = require('./dbInfo.js');
const logOptions  = require('./logInfo.js');

const dbQueries   = require('./dbQueries.js');

const routeFns    = require('./routeFunctions.js');

import { PostgresQueries }  from "./postgresQueries";
import { PostFunctions } from "./PostFunctions";
import { RouteNamesAddDriverRider } from "./RouteNames";
import { RouteNamesSelfService, RouteNamesMatch } from "./RouteNames";
import { RouteNamesSelfServiceInfoExists } from "./RouteNames";
import { RouteNamesCancel, RouteNamesUnmatched, RouteNamesChange } from "./RouteNames";
import { logging }          from "./logging";

let postgresQueries = new PostgresQueries();
let postFunctions = new PostFunctions();
let routeNamesAddDriverRider = new RouteNamesAddDriverRider();
let routeNamesSelfService = new RouteNamesSelfService();
let routeNamesMatch = new RouteNamesMatch();
let routeNamesSelfServiceInfoExists = new RouteNamesSelfServiceInfoExists();
let routeNamesCancel = new RouteNamesCancel();
let routeNamesUnmatched = new RouteNamesUnmatched();
let routeNamesChange = new RouteNamesChange();
let loggingItem        = new logging();

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
postFunctions.setPool(pool);

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
  path: '/' + routeNamesAddDriverRider.DRIVER_ROUTE,
  handler: postFunctions.postDriver
});

server.route({
  method: 'POST',
  path: '/' + routeNamesAddDriverRider.RIDER_ROUTE,
  handler: postFunctions.postRider
});

server.route({
  method: 'POST',
  path: '/' + routeNamesAddDriverRider.HELPER_ROUTE,
  handler: postFunctions.postHelper
});

server.route({
  method: 'GET',
  path: '/' + routeNamesUnmatched.UNMATCHED_DRIVERS_ROUTE,
  handler: routeFns.getUnmatchedDrivers
});

server.route({
  method: 'GET',
  path: '/' + routeNamesUnmatched.UNMATCHED_RIDERS_ROUTE,
  handler: routeFns.getUnmatchedRiders
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfServiceInfoExists.DRIVER_EXISTS_ROUTE,
  handler: routeFns.driverExists
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfServiceInfoExists.DRIVER_INFO_ROUTE,
  handler: routeFns.driverInfo
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfService.DRIVER_PROPOSED_MATCHES_ROUTE,
  handler: routeFns.driverProposedMatches
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfService.DRIVER_CONFIRMED_MATCHES_ROUTE,
  handler: routeFns.driverConfirmedMatches
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfServiceInfoExists.RIDER_EXISTS_ROUTE,
  handler: routeFns.riderExists
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfServiceInfoExists.RIDER_INFO_ROUTE,
  handler: routeFns.riderInfo
});

server.route({
  method: 'GET',
  path: '/' + routeNamesSelfService.RIDER_CONFIRMED_MATCH_ROUTE,
  handler: routeFns.riderConfirmedMatch
});

server.route({
  method: 'GET',
  path: '/matches',
  handler: (req, reply) => {
    var results = {
      success: 'GET matches: ',
      failure: 'GET matches: ' 
    };

    req.log(['request']);

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

    req.log(['request']);

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

    req.log(['request']);

    postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchDriverQueryString, 
                            req.params.uuid, reply, results);
  }
});

server.route({
  method: 'GET',
  // method: 'POST',
  path: '/' + routeNamesCancel.CANCEL_RIDE_REQUEST_ROUTE,
  handler: routeFns.cancelRideRequest
});

server.route({
  method: 'GET',
  path: '/' + routeNamesMatch.CANCEL_RIDER_MATCH_ROUTE,
  handler: routeFns.cancelRiderMatch
});

server.route({
  method: 'GET',
  path: '/' + routeNamesCancel.CANCEL_DRIVE_OFFER_ROUTE,
  handler: routeFns.cancelDriveOffer
});

server.route({
  method: 'GET',
  path: '/' + routeNamesMatch.CANCEL_DRIVER_MATCH_ROUTE,
  handler: routeFns.cancelDriverMatch
});

server.route({
  method: 'GET',
  path: '/' + routeNamesMatch.ACCEPT_DRIVER_MATCH_ROUTE,
  handler: routeFns.acceptDriverMatch
});

server.route({
  method: 'GET',
  path: '/' + routeNamesMatch.PAUSE_DRIVER_MATCH_ROUTE,
  handler: routeFns.pauseDriverMatch
});

server.route({
  method: 'DELETE',
  path: '/' + routeNamesChange.DELETE_DRIVER_ROUTE,
  handler: routeFns.cancelRideOffer
});

server.route({
  method: 'PUT',
  path: '/' + routeNamesChange.PUT_RIDER_ROUTE,
  handler: routeFns.rejectRide
});

server.route({
  method: 'PUT',
  path: '/' + routeNamesChange.PUT_DRIVER_ROUTE,
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

      console.log("driver ins: " + dbQueries.dbGetSubmitDriverString());
      console.log("rider ins: " + dbQueries.dbGetSubmitRiderString());
      console.log("cancel ride fn: " + dbQueries.dbCancelRideRequestFunctionString());
      console.log("reject ride fn: " + dbQueries.dbRejectRideFunctionString());
      console.log("ops interval:" + logOptions.ops.interval);
    });
  }
);

loggingItem.logReqResp(server, pool);
