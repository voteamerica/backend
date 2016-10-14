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
const SCHEMA_NAME           = 'stage';
const SCHEMA_NOV2016_NAME   = 'nov2016';

const DRIVER_TABLE  = 'websubmission_driver';
const RIDER_TABLE   = 'websubmission_rider';
const HELPER_TABLE  = 'websubmission_helper';
const MATCH_TABLE   = 'match';

var CANCEL_RIDE_FUNCTION = 'cancel_ride($1)';
var REJECT_RIDE_FUNCTION = 'reject_ride($1)';

// app routes (api paths)
const DRIVER_ROUTE  = 'driver';
const RIDER_ROUTE   = 'rider';
const HELPER_ROUTE  = 'helper';
const DELETE_ROUTE  = 'rider';
const PUT_ROUTE     = 'rider';

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

server.route({
  method: 'GET',
  path: '/matches',
  handler: (req, reply) => {
    var results = {
      success: 'GET matches: ',
      failure: 'GET matches: ' 
    };

    req.log();

    dbGetMatchesData(pool, dbGetMatchesQueryString, reply, results);
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

    dbGetMatchSpecificData(pool, dbGetMatchRiderQueryString, 
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

    dbGetMatchSpecificData(pool, dbGetMatchDriverQueryString, 
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
  path: '/' + DRIVER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(DRIVER_ROUTE);

    console.log("driver radius1 : " + payload.DriverCollectionRadius);
    sanitiseDriver(payload);
    console.log("driver radius2 : " + payload.DriverCollectionRadius);

    req.log();

    console.log("driver payload: " + JSON.stringify(payload, null, 4));
    console.log("driver zip: " + payload.DriverCollectionZIP);

    dbInsertData(payload, pool, dbGetInsertDriverString, 
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
  path: '/' + RIDER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getResultStrings(RIDER_ROUTE);

    console.log("rider state1 : " + payload.RiderVotingState);
    sanitiseRider(payload);
    console.log("rider state2 : " + payload.RiderVotingState);

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

    dbInsertData(payload, pool, dbGetInsertHelperString, 
                  getHelperPayloadAsArray,
                  req, reply, results);
  }
});

server.route({
  method: 'DELETE',
  path: '/' + DELETE_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getExecResultStrings('cancel ride: ');

    req.log();

    console.log("delete payload: " + JSON.stringify(payload, null, 4));

    dbExecuteFunction(payload, pool, dbCancelRideFunctionString, 
                      getCancelRidePayloadAsArray,
                      req, reply, results);
  }
});

server.route({
  method: 'PUT',
  path: '/' + PUT_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;
    var results = getExecResultStrings('reject ride: ');

    req.log();

    console.log("reject payload: " + JSON.stringify(payload, null, 4));

    dbExecuteFunction(payload, pool, dbRejectRideFunctionString, 
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

      console.log("driver ins: " + dbGetInsertDriverString());
      console.log("rider ins: " + dbGetInsertRiderString());
      console.log("cancel ride fn: " + dbCancelRideFunctionString());
      console.log("reject ride fn: " + dbRejectRideFunctionString());
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

function dbGetMatchesData(pool, fnGetString, reply, results) {
    var queryString =  fnGetString();

    pool.query( queryString )
    .then(result => {
      var firstRowAsString = "";

      if (result !== undefined && result.rows !== undefined) {

        result.rows.forEach( val => {
          
          firstRowAsString += JSON.stringify(val);
        });

        console.log(JSON.stringify(result.rows[0]));        
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

function dbGetMatchSpecificData(pool, fnGetString, uuid, reply, results) {
    var queryString =  fnGetString(uuid);

    console.log('match rider query: ' + queryString);

    pool.query( queryString )
    .then(result => {
      var firstRowAsString = "";

      if (result !== undefined && result.rows !== undefined) {

        result.rows.forEach( val => {
          
          firstRowAsString += JSON.stringify(val);
        });

        console.log(JSON.stringify(result.rows[0]));        
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
    var uuid = "";

    try {
      displayResult = JSON.stringify(result);
      uuid = result.rows[0].UUID;
      console.error('row: ' + JSON.stringify(result.rows[0]) );
    }
    catch (err) {
      console.error('no uuid returned');
    }

    console.log('insert: ', uuid + ' ' + displayResult);

    if (payload._redirect) {

      reply.redirect(payload._redirect + '?uuid=' + uuid.toString());
    } 
    else {
      reply(results.success + ': ' + uuid);
    }
  })
  .catch(e => {
    var message = e.message || '';
    var stack   = e.stack   || '';

    console.error('query error: ', message, stack);

    reply(results.failure + ': ' + message).code(500);
  });
}

function dbExecuteFunction(payload, pool, fnExecuteFunctionString, fnPayloadArray,
                        req, reply, results) {
  var queryString = fnExecuteFunctionString();

  console.log("executeFunctionString: " + queryString);
  pool.query(
    queryString, 
    fnPayloadArray(req, payload)
    )
    .then(function (result) {
    var firstRowAsString = "";

    if (result !== undefined && result.rows !== undefined) {
        // result.rows.forEach( val => console.log(val));
        result.rows.forEach(function (val) { return console.log("exec fn: " + JSON.stringify(val)); });
        firstRowAsString = JSON.stringify(result.rows[0]);
    }
    console.error("executed fn: " + firstRowAsString);

    reply(results.success + firstRowAsString);
  })
  .catch(function (e) {
    var message = e.message || '';
    var stack = e.stack || '';

    console.error(
    // results.failure, 
    message, stack);

    reply(results.failure + message).code(500);
  });
}

function dbRejectRideFunctionString() {
    return 'select ' + SCHEMA_NAME + '.' + REJECT_RIDE_FUNCTION;
}

function dbCancelRideFunctionString() {
    return 'select ' + SCHEMA_NAME + '.' + CANCEL_RIDE_FUNCTION;
}

function dbGetMatchRiderQueryString (rider_uuid) {
  return 'SELECT * FROM nov2016.match inner join stage.websubmission_rider ' +
    'on (nov2016.match.uuid_rider = stage.websubmission_rider."UUID") ' +
    'inner join stage.websubmission_driver ' + 
    'on (nov2016.match.uuid_driver = stage.websubmission_driver."UUID") ' +
    'where nov2016.match.uuid_rider = ' + " '" + rider_uuid + "' ";
}

function dbGetMatchDriverQueryString (driver_uuid) {
  return 'SELECT * FROM nov2016.match inner join stage.websubmission_rider ' +
    'on (nov2016.match.uuid_rider = stage.websubmission_rider."UUID") ' +
    'inner join stage.websubmission_driver ' + 
    'on (nov2016.match.uuid_driver = stage.websubmission_driver."UUID") ' +
    'where nov2016.match.uuid_driver = ' + " '" + driver_uuid + "' ";
}

function dbGetMatchesQueryString () {
  return 'SELECT * FROM ' + SCHEMA_NOV2016_NAME + '.' + MATCH_TABLE;
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
    + ', "DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverHasInsurance"'
    + ', "DriverFirstName", "DriverLastName"'
    + ', "DriverEmail", "DriverPhone"'
    + ', "DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics"'
    + ', "PleaseStayInTouch", "VehicleRegistrationNumber", "DriverLicenseNumber" '
    + ')'

    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18 )' 
    + ' returning "UUID" ' 
}

function dbGetInsertRiderString() {
  return dbGetInsertClause(RIDER_TABLE)
    + ' ('     
    + '  "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail"'       
    + ', "RiderPhone", "RiderVotingState"'
    + ', "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesJSON"'
    + ', "TotalPartySize", "TwoWayTripNeeded", "RiderPreferredContactMethod", "RiderIsVulnerable" '
    + ', "RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderAccommodationNotes"'
    + ', "RiderLegalConsent"'
    + ')'
    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18 )'
    + ' returning "UUID" ' 
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
      , payload.VehicleRegistrationNumber
      , payload.DriverLicenceNumber 
    ]
}
