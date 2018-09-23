"use strict";
// generate string for db query statements etc
Object.defineProperty(exports, "__esModule", { value: true });
const DbDefsTables_1 = require("./DbDefsTables");
const DbDefsSubmits_1 = require("./DbDefsSubmits");
const DbDefsMatches_1 = require("./DbDefsMatches");
const DbDefsExistsInfo_1 = require("./DbDefsExistsInfo");
const DbDefsMatchFunctions_1 = require("./DbDefsMatchFunctions");
const DbDefsCancels_1 = require("./DbDefsCancels");
const DbDefsLegacy_1 = require("./DbDefsLegacy");
const DbQueriesPosts_1 = require("./DbQueriesPosts");
let dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
let dbDefsTables = new DbDefsTables_1.DbDefsTables();
let dbDefsViews = new DbDefsTables_1.DbDefsViews();
let dbDefsSubmits = new DbDefsSubmits_1.DbDefsSubmits();
let dbDefsMatches = new DbDefsMatches_1.DbDefsMatches();
let dbDefsExistsInfo = new DbDefsExistsInfo_1.DbDefsExistsInfo();
let dbDefsMatchFunctions = new DbDefsMatchFunctions_1.DbDefsMatchFunctions();
let dbDefsCancels = new DbDefsCancels_1.DbDefsCancels();
let dbDefsLegacy = new DbDefsLegacy_1.DbDefsLegacy();
let dbQueriesHelpers = new DbQueriesPosts_1.DbQueriesHelpers();
module.exports = {
    dbRejectRideFunctionString: dbRejectRideFunctionString,
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
    dbGetDriversByUserOrganizationQueryString,
    dbGetMatchesByUserOrganizationQueryString,
    dbGetMatchesQueryString,
    dbGetDriversQueryString,
    dbGetRidersQueryString,
    dbGetUsersQueryString,
    dbAddUserQueryString,
    dbGetUnmatchedDriversQueryString: dbGetUnmatchedDriversQueryString,
    dbGetUnmatchedRidersQueryString: dbGetUnmatchedRidersQueryString,
    dbGetDriversDetailssQueryString: dbGetDriversDetailssQueryString,
    dbGetDriverMatchesDetailsQueryString: dbGetDriverMatchesDetailsQueryString
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
function dbGetDriversQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsTables.DRIVER_TABLE);
}
function dbGetRidersQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsTables.RIDER_TABLE);
}
function dbGetUsersQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsTables.USER_TABLE);
}
function dbAddUserQueryString() {
    return dbQueriesHelpers.dbGetInsertClause(dbDefsTables.USER_TABLE);
}
function dbGetUnmatchedDriversQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.UNMATCHED_DRIVERS_VIEW);
}
function dbGetUnmatchedRidersQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.UNMATCHED_RIDERS_VIEW);
}
function dbGetDriversDetailssQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.DRIVERS_DETAILS_VIEW);
}
function dbGetDriverMatchesDetailsQueryString() {
    return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsViews.DRIVER_MATCHES_DETAILS_VIEW);
}
// custom items, due to be revised
function dbGetMatchRiderQueryString(rider_uuid) {
    return ('SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
        'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
        'inner join carpoolvote.driver ' +
        'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
        'where nov2016.match.uuid_rider = ' +
        " '" +
        rider_uuid +
        "' ");
}
function dbGetMatchDriverQueryString(driver_uuid) {
    return ('SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
        'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
        'inner join carpoolvote.driver ' +
        'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
        'where nov2016.match.uuid_driver = ' +
        " '" +
        driver_uuid +
        "' ");
}
function dbGetDriversByUserOrganizationQueryString(username) {
    const dbQueryFn = () => ` SELECT carpoolvote.driver."UUID", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", 
       "AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair", 
       "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", 
       "DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization", 
       "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics", 
       "ReadyToMatch", "PleaseStayInTouch", status, created_ts, last_updated_ts, 
       status_info, "DriverPreferredContact", "DriverWillTakeCare", 
       uuid_organization
  FROM carpoolvote.driver
  INNER JOIN carpoolvote.organization ON "DrivingOBOOrganizationName" = "OrganizationName"
  INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
  WHERE carpoolvote.tb_user.username = '` +
        username +
        "'";
    if (username === 'andrea2') {
        return dbGetDriversQueryString;
    }
    return dbQueryFn;
}
function dbGetMatchesByUserOrganizationQueryString(username) {
    const dbQueryFn = () => ` SELECT carpoolvote.match.status, uuid_driver, uuid_rider, score, driver_notes, rider_notes, 
       carpoolvote.match.created_ts, carpoolvote.match.last_updated_ts,
       "DriverCollectionZIP", "AvailableDriveTimesLocal", "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "DrivingOBOOrganizationName" 
  FROM carpoolvote.match
  INNER JOIN carpoolvote.driver ON uuid_driver = carpoolvote.driver."UUID"
  INNER JOIN carpoolvote.organization ON "DrivingOBOOrganizationName" = "OrganizationName"
  INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
  WHERE carpoolvote.tb_user.username = '` +
        username +
        "'";
    if (username === 'andrea2') {
        return dbGetDriversQueryString;
    }
    return dbQueryFn;
}
//# sourceMappingURL=dbQueries.js.map