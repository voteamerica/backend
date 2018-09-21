// generate string for db query statements etc

import { DbDefsTables, DbDefsViews, DbDefsSchema } from './DbDefsTables';
import { DbDefsSubmits } from './DbDefsSubmits';
import { DbDefsMatches } from './DbDefsMatches';
import { DbDefsExistsInfo } from './DbDefsExistsInfo';
import { DbDefsMatchFunctions } from './DbDefsMatchFunctions';
import { DbDefsCancels } from './DbDefsCancels';
import { DbDefsLegacy } from './DbDefsLegacy';

import { DbQueriesHelpers } from './DbQueriesPosts';

let dbDefsSchema = new DbDefsSchema();
let dbDefsTables = new DbDefsTables();
let dbDefsViews = new DbDefsViews();
let dbDefsSubmits = new DbDefsSubmits();
let dbDefsMatches = new DbDefsMatches();
let dbDefsExistsInfo = new DbDefsExistsInfo();
let dbDefsMatchFunctions = new DbDefsMatchFunctions();
let dbDefsCancels = new DbDefsCancels();
let dbDefsLegacy = new DbDefsLegacy();

let dbQueriesHelpers = new DbQueriesHelpers();

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
function dbAcceptDriverMatchFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsMatchFunctions.ACCEPT_DRIVER_MATCH_FUNCTION
  );
}

function dbPauseDriverMatchFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsMatchFunctions.PAUSE_DRIVER_MATCH_FUNCTION
  );
}

function dbDriverExistsFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsExistsInfo.DRIVER_EXISTS_FUNCTION
  );
}

function dbDriverInfoFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsExistsInfo.DRIVER_INFO_FUNCTION
  );
}

function dbDriverProposedMatchesFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsMatches.DRIVER_PROPOSED_MATCHES_FUNCTION
  );
}

function dbDriverConfirmedMatchesFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsMatches.DRIVER_CONFIRMED_MATCHES_FUNCTION
  );
}

function dbRiderExistsFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsExistsInfo.RIDER_EXISTS_FUNCTION
  );
}

function dbRiderInfoFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsExistsInfo.RIDER_INFO_FUNCTION
  );
}

function dbRiderConfirmedMatchFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsMatchFunctions.RIDER_CONFIRMED_MATCH_FUNCTION
  );
}

function dbRejectRideFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsLegacy.REJECT_RIDE_FUNCTION
  );
}

function dbConfirmRideFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsLegacy.CONFIRM_RIDE_FUNCTION
  );
}

function dbCancelRideOfferFunctionString(): string {
  return dbQueriesHelpers.dbExecuteFunctionString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsLegacy.CANCEL_RIDE_OFFER_FUNCTION
  );
}

// select from table/views
function dbGetMatchesQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsTables.MATCH_TABLE
  );
}

function dbGetDriversQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsTables.DRIVER_TABLE
  );
}

function dbGetRidersQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsTables.RIDER_TABLE
  );
}

function dbGetUsersQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsTables.USER_TABLE
  );
}

function dbAddUserQueryString(): string {
  return dbQueriesHelpers.dbGetInsertClause(dbDefsTables.USER_TABLE);
}

function dbGetUnmatchedDriversQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsViews.UNMATCHED_DRIVERS_VIEW
  );
}

function dbGetUnmatchedRidersQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsViews.UNMATCHED_RIDERS_VIEW
  );
}

function dbGetDriversDetailssQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsViews.DRIVERS_DETAILS_VIEW
  );
}

function dbGetDriverMatchesDetailsQueryString(): string {
  return dbQueriesHelpers.dbSelectFromString(
    dbDefsSchema.SCHEMA_NAME,
    dbDefsViews.DRIVER_MATCHES_DETAILS_VIEW
  );
}

// custom items, due to be revised
function dbGetMatchRiderQueryString(rider_uuid: string): string {
  return (
    'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
    'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
    'inner join carpoolvote.driver ' +
    'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
    'where nov2016.match.uuid_rider = ' +
    " '" +
    rider_uuid +
    "' "
  );
}

function dbGetMatchDriverQueryString(driver_uuid: string): string {
  return (
    'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
    'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
    'inner join carpoolvote.driver ' +
    'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
    'where nov2016.match.uuid_driver = ' +
    " '" +
    driver_uuid +
    "' "
  );
}
