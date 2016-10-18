var postgresQueries = require('./postgresQueries.js');
var dbQueries = require('./dbQueries.js');
var DRIVER_ROUTE = 'driver';
var RIDER_ROUTE = 'rider';
var HELPER_ROUTE = 'helper';
var DELETE_RIDER_ROUTE = 'rider';
var DELETE_DRIVER_ROUTE = 'driver';
var PUT_RIDER_ROUTE = 'rider';
var PUT_DRIVER_ROUTE = 'driver';
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
    DELETE_RIDER_ROUTE: DELETE_RIDER_ROUTE,
    DELETE_DRIVER_ROUTE: DELETE_DRIVER_ROUTE,
    PUT_RIDER_ROUTE: PUT_RIDER_ROUTE,
    PUT_DRIVER_ROUTE: PUT_DRIVER_ROUTE,
    setPool: setPool
};
function setPool(pool) {
    rfPool = pool;
}
function postDriver(req, reply) {
    var payload = req.payload;
    var results = getResultStrings(DRIVER_ROUTE);
    console.log("driver radius1 : " + payload.DriverCollectionRadius);
    sanitiseDriver(payload);
    console.log("driver radius2 : " + payload.DriverCollectionRadius);
    req.log();
    console.log("driver payload: " + JSON.stringify(payload, null, 4));
    console.log("driver zip: " + payload.DriverCollectionZIP);
    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertDriverString, getDriverPayloadAsArray, req, reply, results);
}
function postRider(req, reply) {
    var payload = req.payload;
    var results = getResultStrings(RIDER_ROUTE);
    console.log("rider state1 : " + payload.RiderVotingState);
    sanitiseRider(payload);
    console.log("rider state2 : " + payload.RiderVotingState);
    req.log();
    console.log("rider payload: " + JSON.stringify(payload, null, 4));
    console.log("rider zip: " + payload.RiderCollectionZIP);
    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertRiderString, getRiderPayloadAsArray, req, reply, results);
}
function postHelper(req, reply) {
    var payload = req.payload;
    var results = getResultStrings(HELPER_ROUTE);
    req.log();
    console.log("helper payload: " + JSON.stringify(payload, null, 4));
    postgresQueries.dbInsertData(payload, rfPool, dbQueries.dbGetInsertHelperString, getHelperPayloadAsArray, req, reply, results);
}
function cancelRider(req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('cancel ride: ');
    req.log();
    console.log("delete payload: " + JSON.stringify(payload, null, 4));
    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbCancelRideFunctionString, getCancelRidePayloadAsArray, req, reply, results);
}
function cancelRideOffer(req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('cancel ride offer: ');
    req.log();
    console.log("delete payload: " + JSON.stringify(payload, null, 4));
    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbCancelRideOfferFunctionString, getCancelRideOfferPayloadAsArray, req, reply, results);
}
function rejectRide(req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('reject ride: ');
    req.log();
    console.log("reject payload: " + JSON.stringify(payload, null, 4));
    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbRejectRideFunctionString, getRejectRidePayloadAsArray, req, reply, results);
}
function confirmRide(req, reply) {
    var payload = req.payload;
    var results = getExecResultStrings('confirm ride: ');
    req.log();
    console.log("confirm payload: " + JSON.stringify(payload, null, 4));
    postgresQueries.dbExecuteFunction(payload, pool, dbQueries.dbConfirmRideFunctionString, getConfirmRidePayloadAsArray, req, reply, results);
}
function getResultStrings(tableName) {
    var resultStrings = {
        success: ' row inserted',
        failure: ' row insert failed'
    };
    resultStrings.success = tableName + resultStrings.success;
    resultStrings.failure = tableName + resultStrings.failure;
    return resultStrings;
}
function getExecResultStrings(tableName) {
    var resultStrings = {
        success: ' fn called: ',
        failure: ' fn call failed: '
    };
    resultStrings.success = tableName + resultStrings.success;
    resultStrings.failure = tableName + resultStrings.failure;
    return resultStrings;
}
function getHelperPayloadAsArray(req, payload) {
    return [
        payload.Name, payload.Email, payload.Capability,
        1, moment().toISOString()
    ];
}
function getRiderPayloadAsArray(req, payload) {
    return [
        req.info.remoteAddress, payload.RiderFirstName, payload.RiderLastName, payload.RiderEmail,
        payload.RiderPhone, payload.RiderVotingState,
        payload.RiderCollectionZIP, payload.RiderDropOffZIP, payload.AvailableRideTimesJSON,
        payload.TotalPartySize,
        (payload.TwoWayTripNeeded ? 'true' : 'false'),
        payload.RiderPreferredContactMethod,
        (payload.RiderIsVulnerable ? 'true' : 'false'),
        (payload.RiderWillNotTalkPolitics ? 'true' : 'false'),
        (payload.PleaseStayInTouch ? 'true' : 'false'),
        (payload.NeedWheelchair ? 'true' : 'false'),
        payload.RiderAccommodationNotes,
        (payload.RiderLegalConsent ? 'true' : 'false')
    ];
}
function getDriverPayloadAsArray(req, payload) {
    return [
        req.info.remoteAddress, payload.DriverCollectionZIP, payload.DriverCollectionRadius, payload.AvailableDriveTimesJSON,
        (payload.DriverCanLoadRiderWithWheelchair ? 'true' : 'false'),
        payload.SeatCount,
        (payload.DriverHasInsurance ? 'true' : 'false'),
        payload.DriverFirstName, payload.DriverLastName,
        payload.DriverEmail, payload.DriverPhone,
        (payload.DrivingOnBehalfOfOrganization ? 'true' : 'false'),
        payload.DrivingOBOOrganizationName,
        (payload.RidersCanSeeDriverDetails ? 'true' : 'false'),
        (payload.DriverWillNotTalkPolitics ? 'true' : 'false'),
        (payload.PleaseStayInTouch ? 'true' : 'false'),
        payload.DriverLicenceNumber
    ];
}
function getRejectRidePayloadAsArray(req, payload) {
    return [
        payload.UUID, payload.RiderPhone
    ];
}
function getConfirmRidePayloadAsArray(req, payload) {
    return [
        payload.UUID, payload.RiderPhone
    ];
}
function getCancelRidePayloadAsArray(req, payload) {
    return [
        payload.UUID, payload.RiderPhone
    ];
}
function getCancelRideOfferPayloadAsArray(req, payload) {
    return [
        payload.UUID, payload.DriverPhone
    ];
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
//# sourceMappingURL=routeFunctions.js.map