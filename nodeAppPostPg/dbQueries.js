"use strict";
// generate string for db query statements etc 
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsTables_1 = require("./DbDefsTables");
var DbDefsSubmits_1 = require("./DbDefsSubmits");
var DbDefsMatches_1 = require("./DbDefsMatches");
var DbDefsExistsInfo_1 = require("./DbDefsExistsInfo");
var DbDefsMatchFunctions_1 = require("./DbDefsMatchFunctions");
var DbDefsCancels_1 = require("./DbDefsCancels");
var DbDefsLegacy_1 = require("./DbDefsLegacy");
var DbQueriesPosts_1 = require("./DbQueriesPosts");
var dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
var dbDefsTables = new DbDefsTables_1.DbDefsTables();
var dbDefsViews = new DbDefsTables_1.DbDefsViews();
var dbDefsSubmits = new DbDefsSubmits_1.DbDefsSubmits();
var dbDefsMatches = new DbDefsMatches_1.DbDefsMatches();
var dbDefsExistsInfo = new DbDefsExistsInfo_1.DbDefsExistsInfo();
var dbDefsMatchFunctions = new DbDefsMatchFunctions_1.DbDefsMatchFunctions();
var dbDefsCancels = new DbDefsCancels_1.DbDefsCancels();
var dbDefsLegacy = new DbDefsLegacy_1.DbDefsLegacy();
var dbQueriesHelpers = new DbQueriesPosts_1.DbQueriesHelpers();
module.exports = {
    dbRejectRideFunctionString: dbRejectRideFunctionString,
    // dbCancelRideRequestFunctionString:  dbCancelRideRequestFunctionString,
    // dbCancelRiderMatchFunctionString:   dbCancelRiderMatchFunctionString,
    // dbCancelDriveOfferFunctionString:   dbCancelDriveOfferFunctionString,
    // dbCancelDriverMatchFunctionString:  dbCancelDriverMatchFunctionString,
    dbAcceptDriverMatchFunctionString: dbAcceptDriverMatchFunctionString,
    dbPauseDriverMatchFunctionString: dbPauseDriverMatchFunctionString,
    dbDriverExistsFunctionString: dbDriverExistsFunctionString,
    dbDriverInfoFunctionString: dbDriverInfoFunctionString,
    dbDriverProposedMatchesFunctionString: dbDriverProposedMatchesFunctionString,
    dbDriverConfirmedMatchesFunctionString: dbDriverConfirmedMatchesFunctionString,
    dbRiderExistsFunctionString: dbRiderExistsFunctionString,
    dbRiderInfoFunctionString: dbRiderInfoFunctionString,
    dbRiderConfirmedMatchFunctionString: dbRiderConfirmedMatchFunctionString,
    dbGetMatchRiderQueryString: dbGetMatchRiderQueryString,
    dbGetMatchDriverQueryString: dbGetMatchDriverQueryString,
    dbGetMatchesQueryString: dbGetMatchesQueryString,
    dbGetQueryString: dbGetQueryString,
    dbGetUnmatchedDriversQueryString: dbGetUnmatchedDriversQueryString,
    dbGetUnmatchedRidersQueryString: dbGetUnmatchedRidersQueryString,
};
// const dbDefs = require('./dbDefs.js');
// exec fns
function dbAcceptDriverMatchFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.ACCEPT_DRIVER_MATCH_FUNCTION);
}
function dbPauseDriverMatchFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.PAUSE_DRIVER_MATCH_FUNCTION);
}
function dbDriverExistsFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsExistsInfo.DRIVER_EXISTS_FUNCTION);
}
function dbDriverInfoFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsExistsInfo.DRIVER_INFO_FUNCTION);
}
function dbDriverProposedMatchesFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatches.DRIVER_PROPOSED_MATCHES_FUNCTION);
}
function dbDriverConfirmedMatchesFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatches.DRIVER_CONFIRMED_MATCHES_FUNCTION);
}
function dbRiderExistsFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsExistsInfo.RIDER_EXISTS_FUNCTION);
}
function dbRiderInfoFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsExistsInfo.RIDER_INFO_FUNCTION);
}
function dbRiderConfirmedMatchFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.RIDER_CONFIRMED_MATCH_FUNCTION);
}
function dbRejectRideFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsLegacy.REJECT_RIDE_FUNCTION);
}
function dbConfirmRideFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsLegacy.CONFIRM_RIDE_FUNCTION);
}
function dbCancelRideOfferFunctionString() {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsLegacy.CANCEL_RIDE_OFFER_FUNCTION);
}
// select from table/views
function dbGetMatchesQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsTables.MATCH_TABLE);
}
function dbGetQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsTables.DRIVER_TABLE);
}
function dbGetUnmatchedDriversQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.UNMATCHED_DRIVERS_VIEW);
}
function dbGetUnmatchedRidersQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.UNMATCHED_RIDERS_VIEW);
}
// custom items, due to be revised
function dbGetMatchRiderQueryString(rider_uuid) {
    return 'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
        'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
        'inner join carpoolvote.driver ' +
        'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
        'where nov2016.match.uuid_rider = ' + " '" + rider_uuid + "' ";
}
function dbGetMatchDriverQueryString(driver_uuid) {
    return 'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
        'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
        'inner join carpoolvote.driver ' +
        'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
        'where nov2016.match.uuid_driver = ' + " '" + driver_uuid + "' ";
}
//# sourceMappingURL=dbQueries.js.map