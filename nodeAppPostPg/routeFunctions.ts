const postgresQueries = require('./postgresQueries.js');
const dbQueries   = require('./dbQueries.js');

const DRIVER_ROUTE  = 'driver';
const RIDER_ROUTE   = 'rider';
const HELPER_ROUTE  = 'helper';
const DELETE_ROUTE  = 'rider';
const PUT_ROUTE     = 'rider';

var rfPool = undefined;

module.exports = {
  postDriver: postDriver,
  postRider: postRider,
  postHelper: postHelper,
  cancelRider: cancelRider,
  rejectRide: rejectRide,
  DRIVER_ROUTE: DRIVER_ROUTE,
  RIDER_ROUTE: RIDER_ROUTE,
  HELPER_ROUTE: HELPER_ROUTE,
  DELETE_ROUTE: DELETE_ROUTE,
  PUT_ROUTE: PUT_ROUTE,
  setPool: setPool
}

function setPool(pool) {
  rfPool = pool;
}

function postDriver (req, reply) {
    var payload = req.payload;
    var results = getResultStrings(DRIVER_ROUTE);

    console.log("driver radius1 : " + payload.DriverCollectionRadius);
    sanitiseDriver(payload);
    console.log("driver radius2 : " + payload.DriverCollectionRadius);

    req.log();

    console.log("driver payload: " + JSON.stringify(payload, null, 4));
    console.log("driver zip: " + payload.DriverCollectionZIP);

    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertDriverString, 
                  getDriverPayloadAsArray,
                  req, reply, results);
}

function postRider (req, reply) {
    var payload = req.payload;
    var results = getResultStrings(RIDER_ROUTE);

    console.log("rider state1 : " + payload.RiderVotingState);
    sanitiseRider(payload);
    console.log("rider state2 : " + payload.RiderVotingState);

    req.log();

    console.log("rider payload: " + JSON.stringify(payload, null, 4));
    console.log("rider zip: " + payload.RiderCollectionZIP);

    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertRiderString, 
                  getRiderPayloadAsArray,
                  req, reply, results);
}

function postHelper (req, reply) {
    var payload = req.payload;
    var results = getResultStrings(HELPER_ROUTE);

    req.log();

    console.log("helper payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertHelperString, 
                  getHelperPayloadAsArray,
                  req, reply, results);
}

function cancelRider (req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('cancel ride: ');

    req.log();

    console.log("delete payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbCancelRideFunctionString, 
                      getCancelRidePayloadAsArray,
                      req, reply, results);
}

function rejectRide (req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('reject ride: ');

    req.log();

    console.log("reject payload: " + JSON.stringify(payload, null, 4));

    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbRejectRideFunctionString, 
                      getRejectRidePayloadAsArray,
                      req, reply, results);
}

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

function getHelperPayloadAsArray(req, payload) {
  return [      
        payload.Name, payload.Email, payload.Capability,
        1, moment().toISOString()
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

function sanitiseDriver(payload) {
  if (payload.DriverCollectionRadius === undefined ||
      payload.DriverCollectionRadius === "") {
    // console.log("santising...");
    payload.DriverCollectionRadius = 0;
  }    
}

function sanitiseRider(payload) {

  if (payload.RiderVotingState === undefined) {
    payload.RiderVotingState = "MO";
  }
}
