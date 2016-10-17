'use strict';

const Hapi        = require('hapi');
const moment      = require('moment');
const Pool        = require('pg').Pool;
const Good        = require('good');
const GoodFile    = require('good-file');

const config      = require('./dbInfo.js');
const logOptions  = require('./logInfo.js');

const dbDefs      = require('./dbDefs.js');
const dbQueries   = require('./dbQueries.js')
const logging     = require('./logging.js');
const postgresQueries = require('./postgresQueries.js');

config.user       = process.env.PGUSER;
config.database   = process.env.PGDATABASE;
config.password   = process.env.PGPASSWORD;
config.host       = process.env.PGHOST;
config.port       = process.env.PGPORT;

// const pool = new Pool(config);
// not passing config causes Client() to search for env vars
const pool = new Pool();
const server = new Hapi.Server();

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

function getResultStrings(tableName) {
    var resultStrings = {
      success: ' row inserted',
      failure: ' row insert failed' 
    }

    resultStrings.success = tableName + resultStrings.success; 
    resultStrings.failure = tableName + resultStrings.failure; 

    return resultStrings;
}

function getExecResultStrings(tableName) {
    var resultStrings = {
      success: ' fn called: ',
      failure: ' fn call failed: ' 
    }

    resultStrings.success = tableName + resultStrings.success; 
    resultStrings.failure = tableName + resultStrings.failure; 

    return resultStrings;
}

function sanitiseDriver(payload) {
  if (payload.DriverCollectionRadius === undefined ||
      payload.DriverCollectionRadius === "") {
    // console.log("santising...");
    payload.DriverCollectionRadius = 0;
  }    
}

server.route({
  method: 'POST',
  path: '/' + dbDefs.DRIVER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(dbDefs.DRIVER_ROUTE);

    console.log("driver radius1 : " + payload.DriverCollectionRadius);
    sanitiseDriver(payload);
    console.log("driver radius2 : " + payload.DriverCollectionRadius);

    req.log();

    console.log("driver payload: " + JSON.stringify(payload, null, 4));
    console.log("driver zip: " + payload.DriverCollectionZIP);

    postgresQueries.dbInsertData(payload, pool, dbQueries.dbGetInsertDriverString, 
                  getDriverPayloadAsArray,
                  req, reply, results);
  }
});

function sanitiseRider(payload) {

  if (payload.RiderVotingState === undefined) {
    payload.RiderVotingState = "MO";
  }
}

server.route({
  method: 'POST',
  path: '/' + dbDefs.RIDER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(dbDefs.RIDER_ROUTE);

    console.log("rider state1 : " + payload.RiderVotingState);
    sanitiseRider(payload);
    console.log("rider state2 : " + payload.RiderVotingState);

    req.log();

    console.log("rider payload: " + JSON.stringify(payload, null, 4));
    console.log("rider zip: " + payload.RiderCollectionZIP);

    postgresQueries.dbInsertData(payload, pool, dbQueries.dbGetInsertRiderString, 
                  getRiderPayloadAsArray,
                  req, reply, results);
  }
});

server.route({
  method: 'POST',
  path: '/' + dbDefs.HELPER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(dbDefs.HELPER_ROUTE);

    req.log();

    console.log("helper payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbInsertData(payload, pool, dbQueries.dbGetInsertHelperString, 
                  getHelperPayloadAsArray,
                  req, reply, results);
  }
});

server.route({
  method: 'DELETE',
  path: '/' + dbDefs.DELETE_ROUTE,
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
  path: '/' + dbDefs.PUT_ROUTE,
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

function getHelperPayloadAsArray(req, payload) {
  return [      
        payload.Name, payload.Email, payload.Capability,
        1, moment().toISOString()
    ]
}

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

function getRiderPayloadAsArray(req, payload) {
  return [      
        req.info.remoteAddress, payload.RiderFirstName, payload.RiderLastName, payload.RiderEmail
      , payload.RiderPhone, payload.RiderVotingState
      , payload.RiderCollectionZIP, payload.RiderDropOffZIP, payload.AvailableRideTimesJSON
      , payload.TotalPartySize
      , (payload.TwoWayTripNeeded ? 'true' : 'false')
      , payload.RiderPreferredContactMethod
      , (payload.RiderIsVulnerable ? 'true' : 'false')
      , (payload.RiderWillNotTalkPolitics ? 'true' : 'false')
      , (payload.PleaseStayInTouch ? 'true' : 'false')
      , (payload.NeedWheelchair ? 'true' : 'false')
      , payload.RiderAccommodationNotes
      , (payload.RiderLegalConsent ? 'true' : 'false')
    ]
}

function getDriverPayloadAsArray(req, payload) {
  return [
        req.info.remoteAddress, payload.DriverCollectionZIP, payload.DriverCollectionRadius, payload.AvailableDriveTimesJSON
      , (payload.DriverCanLoadRiderWithWheelchair ? 'true'  : 'false')
      , payload.SeatCount
      , (payload.DriverHasInsurance ? 'true' : 'false')
      , payload.DriverFirstName, payload.DriverLastName
      , payload.DriverEmail, payload.DriverPhone
      , (payload.DrivingOnBehalfOfOrganization ? 'true' : 'false')
      , payload.DrivingOBOOrganizationName 
      , (payload.RidersCanSeeDriverDetails ? 'true' : 'false')
      , (payload.DriverWillNotTalkPolitics ? 'true' : 'false')
      , (payload.PleaseStayInTouch ? 'true' : 'false')
      , payload.DriverLicenceNumber 
    ]
}
