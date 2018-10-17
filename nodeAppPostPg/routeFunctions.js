"use strict";
// route names, handlers and support functions
Object.defineProperty(exports, "__esModule", { value: true });
// const moment          = require('moment');
// const postgresQueries = require('./postgresQueries.js');
const DbDefsCancels_1 = require("./DbDefsCancels");
const postgresQueries_1 = require("./postgresQueries");
const PostFunctions_1 = require("./PostFunctions");
let dbQueriesCancels = new DbDefsCancels_1.DbQueriesCancels();
let postgresQueries = new postgresQueries_1.PostgresQueries();
let postFunctions = new PostFunctions_1.PostFunctions();
const dbQueries = require('./dbQueries.js');
var rfPool = undefined;
// NOTE: module.exports at bottom of file
function setPool(pool) {
    rfPool = pool;
}
function getAnon(req, reply) {
    var results = {
        success: 'GET carpool: ',
        failure: 'GET error: '
    };
    req.log();
    postgresQueries.dbGetData(rfPool, dbQueries.dbGetDriversQueryString, reply, results);
}
function getUsers(req, reply) {
    var results = {
        success: 'GET users: ',
        failure: 'GET users error: '
    };
    req.log();
    postgresQueries.dbGetData(rfPool, dbQueries.dbGetUsersQueryString, reply, results);
}
const mapDbUserToNodeAppUser = dbData => {
    let userInfo = {};
    try {
        userInfo = JSON.parse(dbData);
    }
    catch (error) {
        console.log('invalid user returned from db');
        return undefined;
    }
    const userInfoAdmin = Object.assign({}, userInfo, { admin: userInfo.is_admin });
    return userInfoAdmin;
};
async function getUsersInternal(req, reply, payload) {
    var results = {
        success: 'GET users internal: ',
        failure: 'GET users internal error: '
    };
    req.log();
    const [userName, email, ...info] = userPayloadAsArray(req, payload);
    const queryPlusWhere = queryFn => () => queryFn() + ` WHERE username = '${userName}' OR email = '${email}' `;
    const dbData = await postgresQueries.dbGetDataInternal(rfPool, queryPlusWhere(dbQueries.dbGetUsersQueryString), reply, results);
    if (dbData === undefined) {
        return undefined;
    }
    const nodeAppUser = mapDbUserToNodeAppUser(dbData);
    return JSON.stringify(nodeAppUser);
}
async function getUsersListInternal(req, reply, payload) {
    var results = {
        success: 'GET users list internal: ',
        failure: 'GET users list internal error: '
    };
    req.log();
    const dbData = await postgresQueries.dbGetDataListInternal(rfPool, dbQueries.dbGetUsersQueryString, reply, results);
    return dbData;
}
async function getDriversListInternal(req, reply, payload) {
    var results = {
        success: 'GET drivers list internal: ',
        failure: 'GET drivers list internal error: '
    };
    // debugger;
    // console.log('drivers list int');
    req.log();
    const dbData = await postgresQueries.dbGetDataListInternal(rfPool, 
    // dbQueries.dbGetDriversQueryString,
    dbQueries.dbGetDriversByUserOrganizationQueryString(req.auth.credentials.username), reply, results);
    return dbData;
}
async function getRidersListInternal(req, reply, payload) {
    var results = {
        success: 'GET riders list internal: ',
        failure: 'GET riders list internal error: '
    };
    req.log();
    const dbData = await postgresQueries.dbGetDataListInternal(rfPool, dbQueries.dbGetRidersAndOrganizationQueryString(), reply, results);
    return dbData;
}
async function getMatchesListInternal(req, reply, payload) {
    var results = {
        success: 'GET matches list internal: ',
        failure: 'GET matches list internal error: '
    };
    req.log();
    const dbData = await postgresQueries.dbGetDataListInternal(rfPool, 
    // dbQueries.dbGetMatchesQueryString,
    dbQueries.dbGetMatchesByUserOrganizationQueryString(req.auth.credentials.username), reply, results);
    return dbData;
}
async function getMatchesOtherDriverListInternal(req, reply, payload) {
    var results = {
        success: 'GET matches other list internal: ',
        failure: 'GET matches other list internal error: '
    };
    req.log();
    const dbData = await postgresQueries.dbGetDataListInternal(rfPool, dbQueries.dbGetMatchesByRiderOrganizationQueryString(req.auth.credentials.username), reply, results);
    return dbData;
}
async function addUserInternal(req, reply, payload) {
    var results = {
        success: 'POST user internal: ',
        failure: 'POST user internal error: '
    };
    req.log();
    const insertPlusValues = queryFn => () => queryFn() +
        ' ("username", "email", "password", "is_admin") ' +
        ' values ($1, $2, $3, $4) returning ' +
        '"UUID", email, username, is_admin';
    const newUserUUID = await postgresQueries.dbInsertDataInternal(payload, rfPool, insertPlusValues(dbQueries.dbAddUserQueryString), userPayloadAsArray, req, reply, results);
    return newUserUUID;
}
function getUnmatchedDrivers(req, reply) {
    var results = {
        success: 'GET unmatched drivers: ',
        failure: 'GET unmatched drivers error: '
    };
    req.log();
    postgresQueries.dbGetUnmatchedDrivers(rfPool, dbQueries.dbGetUnmatchedDriversQueryString, reply, results);
}
function getDriversDetails(req, reply) {
    var results = {
        success: 'GET drivers details: ',
        failure: 'GET drivers details error: '
    };
    req.log();
    postgresQueries.dbGetDriversDetails(rfPool, dbQueries.dbGetDriversDetailssQueryString, reply, results);
}
function getDriverMatchesDetails(req, reply) {
    var results = {
        success: 'GET driver matches details: ',
        failure: 'GET driver matches details error: '
    };
    req.log();
    postgresQueries.dbGetDriverMatchesDetails(rfPool, dbQueries.dbGetDriverMatchesDetailsQueryString, reply, results);
}
function getUnmatchedRiders(req, reply) {
    var results = {
        success: 'GET unmatched riders: ',
        failure: 'GET unmatched riders error: '
    };
    req.log();
    postgresQueries.dbGetUnmatchedRiders(rfPool, dbQueries.dbGetUnmatchedRidersQueryString, reply, results);
}
var cancelRideRequest = createConfirmCancelFn('cancel ride request: ', 'get payload: ', dbQueriesCancels.dbCancelRideRequestFunctionString, getTwoRiderCancelConfirmPayloadAsArray
// getCancelConfirmQueryAsArray
);
var cancelRiderMatch = createConfirmCancelFn('cancel rider match: ', 'get payload: ', dbQueriesCancels.dbCancelRiderMatchFunctionString, getFourRiderCancelConfirmPayloadAsArray);
var cancelDriveOffer = createConfirmCancelFn('cancel drive offer: ', 'get payload: ', dbQueriesCancels.dbCancelDriveOfferFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var cancelDriverMatch = createConfirmCancelFn('cancel driver match: ', 'get payload: ', dbQueriesCancels.dbCancelDriverMatchFunctionString, 
// getThreeDriverCancelConfirmPayloadAsArray
getFourDriverCancelConfirmPayloadAsArray);
var acceptDriverMatch = createConfirmCancelFn('accept driver match: ', 'get payload: ', dbQueries.dbAcceptDriverMatchFunctionString, getFourDriverCancelConfirmPayloadAsArray);
var pauseDriverMatch = createConfirmCancelFn('pause driver match: ', 'get payload: ', dbQueries.dbPauseDriverMatchFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var driverExists = createConfirmCancelFn('driver exists: ', 'get payload: ', dbQueries.dbDriverExistsFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var driverInfo = createConfirmCancelFn('driver info: ', 'get payload: ', dbQueries.dbDriverInfoFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var driverProposedMatches = createMultipleResultsFn('driver proposed matches: ', 'get payload: ', dbQueries.dbDriverProposedMatchesFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var driverConfirmedMatches = createMultipleResultsFn('driver confirmed matches: ', 'get payload: ', dbQueries.dbDriverConfirmedMatchesFunctionString, getTwoDriverCancelConfirmPayloadAsArray);
var riderExists = createConfirmCancelFn('rider exists: ', 'get payload: ', dbQueries.dbRiderExistsFunctionString, getTwoRiderCancelConfirmPayloadAsArray);
var riderInfo = createConfirmCancelFn('rider info: ', 'get payload: ', dbQueries.dbRiderInfoFunctionString, getTwoRiderCancelConfirmPayloadAsArray);
var riderConfirmedMatch = createConfirmCancelFn('rider confirmed match: ', 'get payload: ', dbQueries.dbRiderConfirmedMatchFunctionString, getTwoRiderCancelConfirmPayloadAsArray);
// var cancelRideOffer = createConfirmCancelFn
//   ('cancel ride offer: ', "delete payload: ", dbQueries.dbCancelRideOfferFunctionString, getCancelRideOfferPayloadAsArray);
// var rejectRide = createConfirmCancelFn
//   ('reject ride: ', "reject payload: ", dbQueries.dbRejectRideFunctionString, getRejectRidePayloadAsArray);
// var confirmRide = createConfirmCancelFn
//   ('confirm ride: ', "confirm payload: ", dbQueries.dbConfirmRideFunctionString, getConfirmRidePayloadAsArray);
function createConfirmCancelFn(resultStringText, consoleText, dbQueryFn, payloadFn) {
    function execFn(req, reply) {
        // var payload = req.payload;
        var payload = req.query;
        var results = postFunctions.getExecResultStrings(resultStringText);
        console.log('createConfirmCancelFn-payload: ', payload);
        req.log();
        console.log(consoleText + JSON.stringify(payload, null, 4));
        postgresQueries.dbExecuteFunction(payload, rfPool, dbQueryFn, payloadFn, req, reply, results);
    }
    return execFn;
}
function createMultipleResultsFn(resultStringText, consoleText, dbQueryFn, payloadFn) {
    function execFn(req, reply) {
        // var payload = req.payload;
        var payload = req.query;
        var results = postFunctions.getExecResultStrings(resultStringText);
        console.log('createMultipleResultsFn-payload: ', payload);
        req.log();
        console.log(consoleText + JSON.stringify(payload, null, 4));
        postgresQueries.dbExecuteFunctionMultipleResults(payload, rfPool, dbQueryFn, payloadFn, req, reply, results);
    }
    return execFn;
}
// for all two param Rider fns
function getTwoRiderCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload UUID');
    }
    if (payload.RiderPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload RiderPhone');
    }
    return [payload.UUID, payload.RiderPhone];
}
// for all two param Driver fns
function getTwoDriverCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload UUID');
    }
    if (payload.DriverPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload DriverPhone');
    }
    return [payload.UUID, payload.DriverPhone];
}
// for all three param Rider fns
function getThreeRiderCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID_driver === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload driver UUID');
    }
    if (payload.UUID_rider === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload rider UUID');
    }
    if (payload.RiderPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload RiderPhone');
    }
    return [payload.UUID_driver, payload.UUID_rider, payload.RiderPhone];
}
// for all four param Rider fns
function getFourRiderCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID_driver === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload driver UUID');
    }
    if (payload.UUID_rider === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload rider UUID');
    }
    if (payload.RiderPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload RiderPhone');
    }
    return [payload.UUID_driver, payload.UUID_rider, payload.RiderPhone];
}
// for all three param Driver fns
function getThreeDriverCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID_driver === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload driver UUID');
    }
    if (payload.UUID_rider === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload rider UUID');
    }
    if (payload.DriverPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload DriverPhone');
    }
    return [payload.UUID_driver, payload.UUID_rider, payload.DriverPhone];
}
// for all four param Driver fns
function getFourDriverCancelConfirmPayloadAsArray(req, payload) {
    if (req === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no req');
    }
    if (payload === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload');
    }
    if (payload.UUID_driver === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload driver UUID');
    }
    if (payload.UUID_rider === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload rider UUID');
    }
    if (payload.DriverPhone === undefined) {
        console.log('getCancelConfirmPayloadAsArray: no payload DriverPhone');
    }
    return [payload.UUID_driver, payload.UUID_rider, payload.DriverPhone];
}
function getRejectRidePayloadAsArray(req, payload) {
    return [payload.UUID, payload.RiderPhone];
}
function getConfirmRidePayloadAsArray(req, payload) {
    return [payload.UUID, payload.RiderPhone];
}
function getCancelRidePayloadAsArray(req, payload) {
    return [payload.UUID, payload.RiderPhone];
}
function userPayloadAsArray(req, payload) {
    return [payload.username, payload.email, payload.password, payload.admin];
}
function getCancelRideOfferPayloadAsArray(req, payload) {
    return [payload.UUID, payload.DriverPhone];
}
module.exports = {
    getAnon: getAnon,
    getUsers: getUsers,
    getUsersInternal,
    getUsersListInternal,
    getDriversListInternal,
    getRidersListInternal,
    getMatchesListInternal,
    getMatchesOtherDriverListInternal,
    addUserInternal,
    getUnmatchedDrivers: getUnmatchedDrivers,
    getDriversDetails: getDriversDetails,
    getDriverMatchesDetails: getDriverMatchesDetails,
    getUnmatchedRiders: getUnmatchedRiders,
    cancelRideRequest: cancelRideRequest,
    cancelRiderMatch: cancelRiderMatch,
    cancelDriveOffer: cancelDriveOffer,
    cancelDriverMatch: cancelDriverMatch,
    acceptDriverMatch: acceptDriverMatch,
    pauseDriverMatch: pauseDriverMatch,
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
};
//# sourceMappingURL=routeFunctions.js.map