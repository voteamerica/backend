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
    dbGetRidersAndOrganizationQueryString,
    dbGetDriversByUserOrganizationQueryString,
    dbGetMatchesByUserOrganizationQueryString,
    dbGetMatchesByRiderOrganizationQueryString,
    dbGetUserOrganizationQueryString,
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
// NOTE: for the riders query, there is no difference if username is 'andrea2'
function dbGetRidersAndOrganizationQueryString() {
    const dbQueryFn = () => ` SELECT carpoolvote.rider."UUID", "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail", 
       "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesLocal", 
       "TotalPartySize", "TwoWayTripNeeded", "RiderIsVulnerable", "RiderWillNotTalkPolitics", 
       "PleaseStayInTouch", "NeedWheelchair", "RiderPreferredContact", 
       "RiderAccommodationNotes", "RiderLegalConsent", "ReadyToMatch", 
       status, created_ts, last_updated_ts, status_info, "RiderWillBeSafe", 
       "RiderCollectionStreetNumber", "RiderCollectionAddress", "RiderDestinationAddress", 
       uuid_organization, carpoolvote.organization."OrganizationName", 
       city, state, full_state, timezone
  FROM carpoolvote.rider
  INNER JOIN carpoolvote.organization ON rider.uuid_organization = organization."UUID"
  INNER JOIN carpoolvote.zip_codes ON "RiderCollectionZIP" = zip`;
    return dbQueryFn;
}
function dbGetDriversByUserOrganizationQueryString(username) {
    const baseQueryString = `SELECT carpoolvote.driver."UUID", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", 
       "AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair", 
       "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", 
       "DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization", 
       "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics", 
       "ReadyToMatch", "PleaseStayInTouch", status, created_ts, last_updated_ts, 
       status_info, "DriverPreferredContact", "DriverWillTakeCare", 
       uuid_organization, city, state, full_state, timezone
  FROM carpoolvote.driver
  INNER JOIN carpoolvote.organization ON (("DrivingOnBehalfOfOrganization" is TRUE and "DrivingOBOOrganizationName" = "OrganizationName") or ("DrivingOnBehalfOfOrganization" is FALSE and 'None' = "OrganizationName"))
  INNER JOIN carpoolvote.zip_codes ON "DriverCollectionZIP" = zip `;
    const queryString = username === 'andrea2'
        ? baseQueryString
        : baseQueryString +
            ` INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
        WHERE carpoolvote.tb_user.username = '` +
            username +
            "'";
    const dbQueryFn = () => queryString;
    return dbQueryFn;
}
// matches where driver org matches user org
function dbGetMatchesByUserOrganizationQueryString(username) {
    const baseQueryString = `SELECT carpoolvote.match.status, uuid_driver, uuid_rider, score, driver_notes, rider_notes, 
       carpoolvote.match.created_ts, carpoolvote.match.last_updated_ts,
       "DriverCollectionZIP", "AvailableDriveTimesLocal", "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "DrivingOBOOrganizationName", 
       city, state, full_state, timezone,
       "RiderFirstName", "RiderLastName", "RiderEmail", 
       "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesLocal",        
       "RiderCollectionStreetNumber", "RiderCollectionAddress", "RiderDestinationAddress"
  FROM carpoolvote.match
  INNER JOIN carpoolvote.rider ON uuid_rider = carpoolvote.rider."UUID"
  INNER JOIN carpoolvote.driver ON uuid_driver = carpoolvote.driver."UUID"
  INNER JOIN carpoolvote.organization ON (("DrivingOnBehalfOfOrganization" is TRUE and "DrivingOBOOrganizationName" = "OrganizationName") or ("DrivingOnBehalfOfOrganization" is FALSE and 'None' = "OrganizationName"))
  INNER JOIN carpoolvote.zip_codes ON "DriverCollectionZIP" = zip `;
    const queryString = username === 'andrea2'
        ? baseQueryString
        : baseQueryString +
            ` INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
        WHERE carpoolvote.tb_user.username = '` +
            username +
            "'";
    const dbQueryFn = () => queryString;
    return dbQueryFn;
}
// matches where rider org matches user org and driver org is different
// NOTE: for this query, org for username 'andrea2' is applied (as need org to be other than something)
function dbGetMatchesByRiderOrganizationQueryString(username) {
    const queryString = `SELECT carpoolvote.match.status, uuid_driver, uuid_rider, score, driver_notes, rider_notes, 
       carpoolvote.match.created_ts, carpoolvote.match.last_updated_ts,
       "DriverCollectionZIP", "AvailableDriveTimesLocal", "SeatCount", "DriverLicenseNumber", "DriverFirstName", "DriverLastName", "DrivingOBOOrganizationName", 
       city, state, full_state, timezone,
       "RiderFirstName", "RiderLastName", "RiderEmail", 
       "RiderPhone", "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesLocal",        
       "RiderCollectionStreetNumber", "RiderCollectionAddress", "RiderDestinationAddress"
  FROM carpoolvote.match
  INNER JOIN carpoolvote.rider ON uuid_rider = carpoolvote.rider."UUID"
  INNER JOIN carpoolvote.driver ON uuid_driver = carpoolvote.driver."UUID"
  INNER JOIN carpoolvote.organization ON 
  not(("DrivingOnBehalfOfOrganization" is TRUE and "DrivingOBOOrganizationName" = "OrganizationName") 
  or ("DrivingOnBehalfOfOrganization" is FALSE and 'None' = "OrganizationName")) 
  and carpoolvote.rider.uuid_organization =  carpoolvote.organization."UUID"
  INNER JOIN carpoolvote.zip_codes ON "DriverCollectionZIP" = zip INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
  WHERE carpoolvote.tb_user.username = '` +
        username +
        "'";
    const dbQueryFn = () => queryString;
    return dbQueryFn;
}
// matches where rider org matches user org and driver org is different
// NOTE: for this query, org for username 'andrea2' is applied (as need org to be other than something)
function dbGetUserOrganizationQueryString(username) {
    const queryString = ` SELECT "OrganizationName", "UUID_organization"
    FROM carpoolvote.organization
    INNER JOIN carpoolvote.tb_user ON carpoolvote.tb_user."UUID_organization" = carpoolvote.organization."UUID"
    WHERE carpoolvote.tb_user.username = '` +
        username +
        "'";
    const dbQueryFn = () => queryString;
    return dbQueryFn;
}
// query for seats available
// SELECT * FROM carpoolvote.match inner join carpoolvote.rider on(carpoolvote.match.uuid_rider = carpoolvote.rider."UUID") inner join carpoolvote.driver on carpoolvote.match.uuid_driver = carpoolvote.driver."UUID"
// where rider."TotalPartySize" < driver."SeatCount"
// calculate seats remaining
// SELECT(driver."SeatCount" - rider."TotalPartySize") AS xxx FROM carpoolvote.match inner join carpoolvote.rider on(carpoolvote.match.uuid_rider = carpoolvote.rider."UUID") inner join carpoolvote.driver on carpoolvote.match.uuid_driver = carpoolvote.driver."UUID"
// where rider."TotalPartySize" < driver."SeatCount"
// create new driver with seats remaining as seatcount
// INSERT into carpoolvote.driver("SeatCount", "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius",
//   "AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair",
//   "DriverLicenseNumber", "DriverFirstName", "DriverLastName",
//   "DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization",
//   "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics",
//   "ReadyToMatch", "PleaseStayInTouch", status, created_ts, last_updated_ts,
//   status_info, "DriverPreferredContact", "DriverWillTakeCare",
//   uuid_organization)
// SELECT(driver."SeatCount" - rider."TotalPartySize") AS "SeatCount", driver."IPAddress", "DriverCollectionZIP", "DriverCollectionRadius",
//   "AvailableDriveTimesLocal", "DriverCanLoadRiderWithWheelchair",
//   "DriverLicenseNumber", "DriverFirstName", "DriverLastName",
//   "DriverEmail", "DriverPhone", "DrivingOnBehalfOfOrganization",
//   "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics",
//   driver."ReadyToMatch", driver."PleaseStayInTouch", carpoolvote.driver.status, carpoolvote.driver.created_ts, carpoolvote.driver.last_updated_ts,
//     carpoolvote.driver.status_info, "DriverPreferredContact", "DriverWillTakeCare",
//     carpoolvote.driver.uuid_organization FROM carpoolvote.match inner join carpoolvote.rider on(carpoolvote.match.uuid_rider = carpoolvote.rider."UUID") inner join carpoolvote.driver on carpoolvote.match.uuid_driver = carpoolvote.driver."UUID"
// where rider."TotalPartySize" < driver."SeatCount"
//# sourceMappingURL=dbQueries.js.map