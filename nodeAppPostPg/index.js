'use strict';

const Hapi    = require('hapi');
const moment  = require('moment');
var   Pool    = require('pg').Pool;

const config  = require('./dbInfo.js');

config.user       = process.env.PGUSER;
config.database   = process.env.PGDATABASE;
config.password   = process.env.PGPASSWORD;
config.host       = process.env.PGHOST;
config.port       = process.env.PGPORT;

const pool = new Pool(config);
const server = new Hapi.Server();

const DEFAULT_PORT  = process.env.PORT || 8000;

const SCHEMA_NAME   = '"STAGE"';
const DRIVER_TABLE  = '"WEBSUBMISSION_DRIVER"';
const RIDER_TABLE   = '"WEBSUBMISSION_RIDER"';

const DRIVER_ROUTE  = 'driver';
const RIDER_ROUTE  = 'rider';

var appPort = DEFAULT_PORT;

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

    pool.query(dbGetQueryString(), (err, result) => {
      var firstRowAsString = "";

      if (err) {
        return reply("error: " + err);
      }

      if (result !== undefined && result.rows !== undefined) {

        // result.rows.forEach( val => console.log(val));
        firstRowAsString = JSON.stringify(result.rows[0]);
      }

      reply('get received at carpool' + firstRowAsString);
    });
  }
});

server.route({
  method: 'POST',
  path: '/' + DRIVER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;

    console.log("payload: " + payload);
    console.log("driver zip: " + payload.DriverCollectionZIP);

    dbInsertData(payload, pool, dbGetInsertDriverString, getDriverPayloadAsArray);

    reply('driver row inserted');
  }
});

server.route({
  method: 'POST',
  path: '/' + RIDER_ROUTE,
  handler: (req, reply) => {
    var payload = req.payload;

    console.log("payload: " + payload);
    console.log("rider zip: " + payload.RiderCollectionZIP);

    dbInsertData(payload, pool, dbGetInsertRiderString, getRiderPayloadAsArray);

    reply('rider row inserted');
  }
});

server.start(err => {
  if (err) {
      throw err;
  }

  console.log(`Server running at: ${server.info.uri}`);
});

pool.on('error', (err, client) => {
  if (err) {
    console.error("db err" + err);
  } 
});

function dbInsertData(payload, pool, fnInsertString, fnPayloadArray) {
    pool.query(
      fnInsertString(),
      fnPayloadArray(payload)
    )
    .then(result => {
      if (result !== undefined) {
        console.log('insert: ', result)
      }
      else {
        console.error('insert made')
      }
    })
    .catch(e => {
      if (e !== undefined && e.message !== undefined && e.stack !== undefined) {
        console.error('query error', e.message, e.stack)
      }
      else {
        console.error('query error.')
      }
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
    + ' (' // "TimeStamp",  
    + '  "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesJSON"' 
    + ', "DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverHasInsurance", "DriverInsuranceProviderName", "DriverInsurancePolicyNumber"'
    + ', "DriverLicenseState", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "PermissionCanRunBackgroundCheck"'
    + ', "DriverEmail", "DriverPhone", "DriverAreaCode", "DriverEmailValidated", "DriverPhoneValidated"'
    + ', "DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics", "ReadyToMatch"'
    + ', "PleaseStayInTouch"'  
    + ')'

    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25)' //-- $26
}

function dbGetInsertRiderString() {
  return dbGetInsertClause(RIDER_TABLE)
    + ' (' // "CreatedTimeStamp",    
    + '  "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail"'       
    + ', "RiderPhone", "RiderAreaCode", "RiderEmailValidated", "RiderPhoneValidated", "RiderVotingState"'
    + ', "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesJSON", "WheelchairCount", "NonWheelchairCount"'
    + ', "TotalPartySize", "TwoWayTripNeeded", "RiderPreferredContactMethod", "RiderIsVulnerable", "DriverCanContactRider"'
    + ', "RiderWillNotTalkPolitics", "ReadyToMatch", "PleaseStayInTouch"' 
    + ')'
    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18, $19, $20, $21, $22)' // , $23 
}

function getRiderPayloadAsArray(payload) {
  return [      
        payload.IPAddress, payload.RiderFirstName, payload.RiderLastName, payload.RiderEmail
      , payload.RiderPhone, payload.RiderAreaCode, payload.RiderEmailValidated, payload.RiderPhoneValidated, payload.RiderVotingState
      , payload.RiderCollectionZIP, payload.RiderDropOffZIP, payload.AvailableRideTimesJSON, payload.WheelchairCount, payload.NonWheelchairCount
      , payload.TotalPartySize, payload.TwoWayTripNeeded, payload.RiderPreferredContactMethod, payload.RiderIsVulnerable, payload.DriverCanContactRider
      , payload.RiderWillNotTalkPolitics, payload.ReadyToMatch, payload.PleaseStayInTouch 
    ]
}

function getDriverPayloadAsArray(payload) {
  return [
      payload.IPAddress, payload.DriverCollectionZIP, payload.DriverCollectionRadius, payload.AvailableDriveTimesJSON
      , 
      //   "TimeStamp" timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
      //   "IPAddress" character varying(20),
      //   "DriverCollectionZIP" character varying(5) NOT NULL,
      //   "DriverCollectionRadius" integer NOT NULL,
      //   "AvailableDriveTimesJSON" character varying(2000),
      // false, 2, false, 'ill. ins', '1234'
      payload.DriverCanLoadRiderWithWheelchair, payload.SeatCount, payload.DriverHasInsurance, payload.DriverInsuranceProviderName, payload.DriverInsurancePolicyNumber
      , 
      //   "DriverCanLoadRiderWithWheelchair" boolean NOT NULL DEFAULT false,
      //   "SeatCount" integer DEFAULT 1,
      //   "DriverHasInsurance" boolean NOT NULL DEFAULT false,
      //   "DriverInsuranceProviderName" character varying(255),
      //   "DriverInsurancePolicyNumber" character varying(50),
      // 'IL', '1234', 'fred', 'smith', false
      payload.DriverLicenseState, payload.DriverLicenseNumber, payload.DriverFirstName, payload.DriverLastName, payload.PermissionCanRunBackgroundCheck
      ,
      //   "DriverLicenseState" character(2),
      //   "DriverLicenseNumber" character varying(50),
      //   "DriverFirstName" character varying(255) NOT NULL,
      //   "DriverLastName" character varying(255) NOT NULL,
      //   "PermissionCanRunBackgroundCheck" boolean NOT NULL DEFAULT false,
      // 'f@gmail.xxx', '555-123-4567', 555, false, false
      payload.DriverEmail, payload.DriverPhone, payload.DriverAreaCode, payload.DriverEmailValidated, payload.DriverPhoneValidated
      , 
      //   "DriverEmail" character varying(255),
      //   "DriverPhone" character varying(20),
      //   "DriverAreaCode" integer,
      //   "DriverEmailValidated" boolean NOT NULL DEFAULT false,
      //   "DriverPhoneValidated" boolean NOT NULL DEFAULT false,
      // false, 'misc', false, false, false
      payload.DrivingOnBehalfOfOrganization, payload.DrivingOBOOrganizationName, payload.RidersCanSeeDriverDetails, payload.DriverWillNotTalkPolitics, payload.ReadyToMatch
      , 
      //   "DrivingOnBehalfOfOrganization" boolean NOT NULL DEFAULT false,
      //   "DrivingOBOOrganizationName" character varying(255),
      //   "RidersCanSeeDriverDetails" boolean NOT NULL DEFAULT false,
      //   "DriverWillNotTalkPolitics" boolean NOT NULL DEFAULT false,
      //   "ReadyToMatch" boolean NOT NULL DEFAULT false,
      // false
      payload.PleaseStayInTouch
      //   "PleaseStayInTouch" boolean NOT NULL DEFAULT false
    ]
}
