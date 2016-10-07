'use strict';

const Hapi        = require('hapi');
const moment      = require('moment');
const Pool        = require('pg').Pool;
const Good        = require('good');
const GoodFile    = require('good-file');

const config      = require('./dbInfo.js');
const logOptions  = require('./logInfo.js');

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

// for db carpool
const SCHEMA_NAME   = 'stage';
const DRIVER_TABLE  = 'websubmission_driver';
const RIDER_TABLE   = 'websubmission_rider';
const HELPER_TABLE  = 'websubmission_helper';

const DRIVER_ROUTE  = 'driver';
const RIDER_ROUTE   = 'rider';
const HELPER_ROUTE  = 'helper';

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

    dbGetData(pool, dbGetQueryString, reply, results);
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

server.route({
  method: 'POST',
  path: '/' + DRIVER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(DRIVER_ROUTE);

    req.log();

    console.log("driver payload: " + JSON.stringify(payload, null, 4));
    console.log("driver zip: " + payload.DriverCollectionZIP);

    dbInsertData(payload, pool, dbGetInsertDriverString, 
                  getDriverPayloadAsArray,
                  req, reply, results);
  }
});

server.route({
  method: 'POST',
  path: '/' + RIDER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(RIDER_ROUTE);

    req.log();

    console.log("rider payload: " + JSON.stringify(payload, null, 4));
    console.log("rider zip: " + payload.RiderCollectionZIP);

    dbInsertData(payload, pool, dbGetInsertRiderString, 
                  getRiderPayloadAsArray,
                  req, reply, results);
  }
});

server.route({
  method: 'POST',
  path: '/' + HELPER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(HELPER_ROUTE);

    req.log();

    console.log("helper payload: " + JSON.stringify(payload, null, 4));
    console.log("helper zip: " + payload.helpername);

    dbInsertData(payload, pool, dbGetInsertHelperString, 
                  getHelperPayloadAsArray,
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

      console.log("driver ins: " + dbGetInsertDriverString());
      console.log("rider ins: " + dbGetInsertRiderString());
      console.log("ops interval:" + logOptions.ops.interval);
    });
  }
);

server.on('request', (request, event, tags) => {

  // Include the Requestor's IP Address on every log
  if( !event.remoteAddress ) {
    event.remoteAddress = request.headers['x-forwarded-for'] || request.info.remoteAddress;
  }

  // Put the first part of the URL into the tags
  if(request && request.url && event && event.tags) {
    event.tags.push(request.url.path.split('/')[1]);
  }

  console.log('server req: %j', event) ;
});

server.on('response', (request) => {  
  console.log(
      "server resp: " 
    + request.info.remoteAddress 
    + ': ' + request.method.toUpperCase() 
    + ' ' + request.url.path 
    + ' --> ' + request.response.statusCode);
});

pool.on('error', (err, client) => {
  if (err) {
    console.error("db err: " + err);
  } 
});

function dbGetData(pool, fnGetString, reply, results) {
    var queryString =  fnGetString();

    pool.query( queryString )
    .then(result => {
      var firstRowAsString = "";

      if (result !== undefined && result.rows !== undefined) {

        // result.rows.forEach( val => console.log(val));
        firstRowAsString = JSON.stringify(result.rows[0]);
      }

      reply(results.success + firstRowAsString);
    })
    .catch(e => {
      var message = e.message || '';
      var stack   = e.stack   || '';

      console.error(results.failure, message, stack);

      reply(results.failure + message).code(500);
    });
}

function dbInsertData(payload, pool, fnInsertString, fnPayloadArray,
                        req, reply, results) {
  var insertString = fnInsertString();

  pool.query(
    insertString,
    fnPayloadArray(req, payload)
  )
  .then(result => {
    var displayResult = result || '';

    console.log('insert: ', displayResult);

    reply(results.success);
  })
  .catch(e => {
    var message = e.message || '';
    var stack   = e.stack   || '';

    console.error('query error: ', message, stack);

    reply(results.failure + ': ' + message).code(500);
  });
}

function dbGetQueryString () {
  return 'SELECT * FROM ' + SCHEMA_NAME + '.' + DRIVER_TABLE;
}

function dbGetInsertClause (tableName) {
  return 'INSERT INTO ' + SCHEMA_NAME + '.' + tableName;
}

function dbGetInsertDriverString() {
  return dbGetInsertClause(DRIVER_TABLE)
    + ' ('   
    + '  "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesJSON"' 
    + ', "DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverHasInsurance", "DriverInsuranceProviderName", "DriverInsurancePolicyNumber"'
    + ', "DriverLicenseState", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "PermissionCanRunBackgroundCheck"'
    + ', "DriverEmail", "DriverPhone", "DriverAreaCode", "DriverEmailValidated", "DriverPhoneValidated"'
    + ', "DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics", "ReadyToMatch"'
    + ', "PleaseStayInTouch"'  
    + ')'

    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25)' 
}

function dbGetInsertRiderString() {
  return dbGetInsertClause(RIDER_TABLE)
    + ' ('     
    + '  "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail"'       
    + ', "RiderPhone", "RiderAreaCode", "RiderEmailValidated", "RiderPhoneValidated", "RiderVotingState"'
    + ', "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesJSON"'
    + ', "TotalPartySize", "TwoWayTripNeeded", "RiderPreferredContactMethod", "RiderIsVulnerable", "DriverCanContactRider"'
    + ', "RiderWillNotTalkPolitics", "ReadyToMatch", "PleaseStayInTouch", "NeedWheelchair"' 
    + ')'
    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18, $19, $20, $21)' // , $22 
}

function dbGetInsertHelperString() {
  return dbGetInsertClause(HELPER_TABLE)
    + ' ('     
    + '  "helpername", "helperemail", "helpercapability", "sweep_status_id", "timestamp" '       
    + ' )'
    + ' values($1, $2, $3, $4, $5) '  
}

function getHelperPayloadAsArray(req, payload) {
  return [      
        payload.helpername, payload.helperemail, payload.helpercapability,
        1, moment().toISOString()
    ]
}

function getRiderPayloadAsArray(req, payload) {
  return [      
        req.info.remoteAddress, payload.RiderFirstName, payload.RiderLastName, payload.RiderEmail
      , payload.RiderPhone, payload.RiderAreaCode, payload.RiderEmailValidated, payload.RiderPhoneValidated, payload.RiderVotingState
      , payload.RiderCollectionZIP, payload.RiderDropOffZIP, payload.AvailableRideTimesJSON
      , payload.TotalPartySize, payload.TwoWayTripNeeded, payload.RiderPreferredContactMethod, payload.RiderIsVulnerable, payload.DriverCanContactRider
      , payload.RiderWillNotTalkPolitics, payload.ReadyToMatch, payload.PleaseStayInTouch, payload.NeedWheelchair
    ]
}

function getDriverPayloadAsArray(req, payload) {
  return [
        req.info.remoteAddress, payload.DriverCollectionZIP, payload.DriverCollectionRadius, payload.AvailableDriveTimesJSON
      , payload.DriverCanLoadRiderWithWheelchair, payload.SeatCount, payload.DriverHasInsurance, payload.DriverInsuranceProviderName, payload.DriverInsurancePolicyNumber
      , payload.DriverLicenseState, payload.DriverLicenseNumber, payload.DriverFirstName, payload.DriverLastName, payload.PermissionCanRunBackgroundCheck
      , payload.DriverEmail, payload.DriverPhone, payload.DriverAreaCode, payload.DriverEmailValidated, payload.DriverPhoneValidated
      , payload.DrivingOnBehalfOfOrganization, payload.DrivingOBOOrganizationName, payload.RidersCanSeeDriverDetails, payload.DriverWillNotTalkPolitics, payload.ReadyToMatch
      , payload.PleaseStayInTouch
    ]
}
