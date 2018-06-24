// route names, handlers and support functions

// const moment          = require('moment');
// const postgresQueries = require('./postgresQueries.js');

import { DbQueriesCancels } from "./DbDefsCancels"

import { PostgresQueries }  from "./postgresQueries";
import { PostFunctions, PayloadFunc2 }  from "./PostFunctions";

let dbQueriesCancels = new DbQueriesCancels();

let postgresQueries = new PostgresQueries();
let postFunctions = new PostFunctions();

const dbQueries       = require('./dbQueries.js');

var rfPool: any = undefined;

// NOTE: module.exports at bottom of file

function setPool(pool: any) {
  rfPool = pool;
}

function getAnon (req: any, reply: any) {
  var results = {
    success: 'GET carpool: ',
    failure: 'GET error: ' 
  };

  req.log();

  postgresQueries.dbGetData(rfPool, dbQueries.dbGetQueryString, reply, results);
}

function getUnmatchedDrivers (req: any, reply: any) {
  var results = {
    success: 'GET unmatched drivers: ',
    failure: 'GET unmatched drivers error: ' 
  };

  req.log();

  postgresQueries.dbGetUnmatchedDrivers(rfPool, dbQueries.dbGetUnmatchedDriversQueryString, reply, results);
}

function getDriversDetails (req: any, reply: any) {
  var results = {
    success: 'GET drivers details: ',
    failure: 'GET drivers details error: ' 
  };

  req.log();

  postgresQueries.dbGetDriversDetails(rfPool, dbQueries.dbGetDriversDetailssQueryString, reply, results);
}

function getDriverMatchesDetails (req: any, reply: any) {
  var results = {
    success: 'GET driver matches details: ',
    failure: 'GET driver matches details error: ' 
  };

  req.log();

  postgresQueries.dbGetDriverMatchesDetails(rfPool, dbQueries.dbGetDriverMatchesDetailsQueryString, reply, results);
}

function getUnmatchedRiders(req: any, reply: any) {
    var results = {
        success: 'GET unmatched riders: ',
        failure: 'GET unmatched riders error: '
    };
    req.log();
    postgresQueries.dbGetUnmatchedRiders(rfPool, dbQueries.dbGetUnmatchedRidersQueryString, reply, results);
}

var cancelRideRequest = createConfirmCancelFn 
  ('cancel ride request: ', "get payload: ", 
    dbQueriesCancels.dbCancelRideRequestFunctionString, 
    getTwoRiderCancelConfirmPayloadAsArray
    // getCancelConfirmQueryAsArray
    );

var cancelRiderMatch = createConfirmCancelFn 
  ('cancel rider match: ', "get payload: ", 
    dbQueriesCancels.dbCancelRiderMatchFunctionString, 
    getFourRiderCancelConfirmPayloadAsArray
  );

var cancelDriveOffer = createConfirmCancelFn 
  ('cancel drive offer: ', "get payload: ", 
    dbQueriesCancels.dbCancelDriveOfferFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var cancelDriverMatch = createConfirmCancelFn 
  ('cancel driver match: ', "get payload: ", 
    dbQueriesCancels.dbCancelDriverMatchFunctionString, 
    // getThreeDriverCancelConfirmPayloadAsArray
    getFourDriverCancelConfirmPayloadAsArray
  );

var acceptDriverMatch = createConfirmCancelFn 
  ('accept driver match: ', "get payload: ", 
    dbQueries.dbAcceptDriverMatchFunctionString, 
    getFourDriverCancelConfirmPayloadAsArray
  );

var pauseDriverMatch = createConfirmCancelFn 
  ('pause driver match: ', "get payload: ", 
    dbQueries.dbPauseDriverMatchFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var driverExists = createConfirmCancelFn 
  ('driver exists: ', "get payload: ", 
    dbQueries.dbDriverExistsFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var driverInfo = createConfirmCancelFn 
  ('driver info: ', "get payload: ", 
    dbQueries.dbDriverInfoFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var driverProposedMatches = createMultipleResultsFn 
  ('driver proposed matches: ', "get payload: ", 
    dbQueries.dbDriverProposedMatchesFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var driverConfirmedMatches = createMultipleResultsFn 
  ('driver confirmed matches: ', "get payload: ", 
    dbQueries.dbDriverConfirmedMatchesFunctionString, 
    getTwoDriverCancelConfirmPayloadAsArray
  );

var riderExists = createConfirmCancelFn 
  ('rider exists: ', "get payload: ", 
    dbQueries.dbRiderExistsFunctionString, 
    getTwoRiderCancelConfirmPayloadAsArray
  );

var riderInfo = createConfirmCancelFn 
  ('rider info: ', "get payload: ", 
    dbQueries.dbRiderInfoFunctionString, 
    getTwoRiderCancelConfirmPayloadAsArray
  );

var riderConfirmedMatch = createConfirmCancelFn 
  ('rider confirmed match: ', "get payload: ", 
    dbQueries.dbRiderConfirmedMatchFunctionString, 
    getTwoRiderCancelConfirmPayloadAsArray
  );

// var cancelRideOffer = createConfirmCancelFn 
//   ('cancel ride offer: ', "delete payload: ", dbQueries.dbCancelRideOfferFunctionString, getCancelRideOfferPayloadAsArray);

// var rejectRide = createConfirmCancelFn 
//   ('reject ride: ', "reject payload: ", dbQueries.dbRejectRideFunctionString, getRejectRidePayloadAsArray);

// var confirmRide = createConfirmCancelFn 
//   ('confirm ride: ', "confirm payload: ", dbQueries.dbConfirmRideFunctionString, getConfirmRidePayloadAsArray);

function createConfirmCancelFn 
  (resultStringText: string, consoleText: string, dbQueryFn: any, payloadFn: PayloadFunc2) {
  
  function execFn (req: any, reply: any) {
      // var payload = req.payload;
      var payload = req.query;
      
      var results = postFunctions.getExecResultStrings(resultStringText);

      console.log("createConfirmCancelFn-payload: ", payload);

      req.log();

      console.log(consoleText + JSON.stringify(payload, null, 4));

      postgresQueries.dbExecuteFunction
        (payload, rfPool, dbQueryFn, payloadFn, req, reply, results);
  }

  return execFn;
}

function createMultipleResultsFn 
  (resultStringText: string, consoleText: string, dbQueryFn: any, payloadFn: any) {
  
  function execFn (req: any, reply: any) {
      // var payload = req.payload;
      var payload = req.query;
      
      var results = postFunctions.getExecResultStrings(resultStringText);

      console.log("createMultipleResultsFn-payload: ", payload);

      req.log();

      console.log(consoleText + JSON.stringify(payload, null, 4));

      postgresQueries.dbExecuteFunctionMultipleResults
        (payload, rfPool, dbQueryFn, payloadFn, req, reply, results);
  }

  return execFn;
}

// for all two param Rider fns
function getTwoRiderCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload UUID");
  }

  if (payload.RiderPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload RiderPhone");
  }

  return [      
        payload.UUID, payload.RiderPhone
    ]
}

// for all two param Driver fns
function getTwoDriverCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload UUID");
  }

  if (payload.DriverPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload DriverPhone");
  }

  return [      
        payload.UUID, payload.DriverPhone
    ]
}

// for all three param Rider fns
function getThreeRiderCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID_driver === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload driver UUID");
  }

  if (payload.UUID_rider === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload rider UUID");
  }

  if (payload.RiderPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload RiderPhone");
  }

  return [      
        payload.UUID_driver, payload.UUID_rider, payload.RiderPhone
    ]
}

// for all four param Rider fns
function getFourRiderCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID_driver === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload driver UUID");
  }

  if (payload.UUID_rider === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload rider UUID");
  }

  if (payload.RiderPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload RiderPhone");
  }

  return [      
        payload.UUID_driver, payload.UUID_rider, payload.RiderPhone
    ]
}

// for all three param Driver fns
function getThreeDriverCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID_driver === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload driver UUID");
  }

  if (payload.UUID_rider === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload rider UUID");
  }

  if (payload.DriverPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload DriverPhone");
  }

  return [      
        payload.UUID_driver, payload.UUID_rider, payload.DriverPhone
    ]
}

// for all four param Driver fns
function getFourDriverCancelConfirmPayloadAsArray (req: any, payload: any) {

  if (req === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no req");
  }

  if (payload === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload");
  }

  if (payload.UUID_driver === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload driver UUID");
  }

  if (payload.UUID_rider === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload rider UUID");
  }


  if (payload.DriverPhone === undefined) {
    console.log("getCancelConfirmPayloadAsArray: no payload DriverPhone");
  }

  return [      
        payload.UUID_driver, payload.UUID_rider, payload.DriverPhone
    ]
}

function getRejectRidePayloadAsArray (req: any, payload: any) {
  return [
        payload.UUID, payload.RiderPhone
    ]
}

function getConfirmRidePayloadAsArray (req: any, payload: any) {
  return [
        payload.UUID, payload.RiderPhone
    ]
}

function getCancelRidePayloadAsArray (req: any, payload: any) {
  return [      
        payload.UUID, payload.RiderPhone
    ]
}

function getCancelRideOfferPayloadAsArray (req: any, payload: any) {
  return [
        payload.UUID, payload.DriverPhone
    ]
}

module.exports = {
  getAnon: getAnon,

  getUnmatchedDrivers:  getUnmatchedDrivers,
  getDriversDetails: getDriversDetails,
  getDriverMatchesDetails: getDriverMatchesDetails,
  getUnmatchedRiders:   getUnmatchedRiders,
  cancelRideRequest:  cancelRideRequest,
  cancelRiderMatch:   cancelRiderMatch,
  cancelDriveOffer:   cancelDriveOffer,
  cancelDriverMatch:  cancelDriverMatch,

  acceptDriverMatch:  acceptDriverMatch,
  pauseDriverMatch:   pauseDriverMatch,

  driverExists: driverExists,
  driverInfo: driverInfo,

  driverProposedMatches: driverProposedMatches,
  driverConfirmedMatches: driverConfirmedMatches,

  riderExists: riderExists,
  riderInfo: riderInfo,

  riderConfirmedMatch: riderConfirmedMatch,

  // cancelRideOffer: cancelRideOffer,
  // rejectRide: rejectRide,
  // confirmRide: confirmRide,
  
  setPool: setPool
}
