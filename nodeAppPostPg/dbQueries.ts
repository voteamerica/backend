// generate string for db query statements etc 

module.exports = {
  dbRejectRideFunctionString:   dbRejectRideFunctionString,

  dbCancelRideRequestFunctionString:  dbCancelRideRequestFunctionString,
  dbCancelRiderMatchFunctionString:   dbCancelRiderMatchFunctionString,
  dbCancelDriveOfferFunctionString:   dbCancelDriveOfferFunctionString,
  dbCancelDriverMatchFunctionString:  dbCancelDriverMatchFunctionString,

  dbAcceptDriverMatchFunctionString:  dbAcceptDriverMatchFunctionString,
  dbPauseDriverMatchFunctionString:   dbPauseDriverMatchFunctionString,

  dbDriverExistsFunctionString: dbDriverExistsFunctionString,
  dbDriverInfoFunctionString: dbDriverInfoFunctionString,

  dbDriverProposedMatchesFunctionString: dbDriverProposedMatchesFunctionString,
  dbDriverConfirmedMatchesFunctionString: dbDriverConfirmedMatchesFunctionString,

  dbRiderExistsFunctionString: dbRiderExistsFunctionString,
  dbRiderInfoFunctionString: dbRiderInfoFunctionString,
  
  dbRiderConfirmedMatchFunctionString: dbRiderConfirmedMatchFunctionString,

  dbGetMatchRiderQueryString:   dbGetMatchRiderQueryString,
  dbGetMatchDriverQueryString:  dbGetMatchDriverQueryString,
  dbGetMatchesQueryString:      dbGetMatchesQueryString,
  dbGetQueryString:             dbGetQueryString,
  dbGetUnmatchedDriversQueryString: dbGetUnmatchedDriversQueryString,
  dbGetUnmatchedRidersQueryString:  dbGetUnmatchedRidersQueryString,
  dbGetInsertClause:            dbGetInsertClause,
  dbGetSubmitDriverString:      dbGetSubmitDriverString,
  dbGetSubmitRiderString:       dbGetSubmitRiderString,
  dbGetSubmitHelperString:      dbGetSubmitHelperString
}

const dbDefs = require('./dbDefs.js');

function dbExecuteFunctionString(schema: string, functionName: string) {
  return 'SELECT ' + schema + '.' + functionName;
}

function dbSelectFromString(schema: string, tableOrView: string) {
  return 'SELECT * FROM ' + schema + '.' + tableOrView;
}

function dbGetInsertClause (tableName) {
  return 'INSERT INTO ' + dbDefs.SCHEMA_NAME + '.' + tableName;
}

// exec fns
function dbCancelRideRequestFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CANCEL_RIDE_REQUEST_FUNCTION);
}

function dbCancelRiderMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CANCEL_RIDER_MATCH_FUNCTION);
}

function dbCancelDriveOfferFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CANCEL_DRIVE_OFFER_FUNCTION);
}

function dbCancelDriverMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CANCEL_DRIVER_MATCH_FUNCTION);
}

function dbAcceptDriverMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.ACCEPT_DRIVER_MATCH_FUNCTION);
}

function dbPauseDriverMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.PAUSE_DRIVER_MATCH_FUNCTION);
}

function dbDriverExistsFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_EXISTS_FUNCTION);
}

function dbDriverInfoFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_INFO_FUNCTION);
}

function dbDriverProposedMatchesFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_PROPOSED_MATCHES_FUNCTION);
}

function dbDriverConfirmedMatchesFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_CONFIRMED_MATCHES_FUNCTION);
}

function dbRiderExistsFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.RIDER_EXISTS_FUNCTION);
}

function dbRiderInfoFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.RIDER_INFO_FUNCTION);
}

function dbRiderConfirmedMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.RIDER_CONFIRMED_MATCH_FUNCTION);
}

function dbRejectRideFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.REJECT_RIDE_FUNCTION);
}

function dbConfirmRideFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CONFIRM_RIDE_FUNCTION);
}

function dbCancelRideOfferFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NAME, dbDefs.CANCEL_RIDE_OFFER_FUNCTION); 
}

// select from table/views
function dbGetMatchesQueryString () {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.MATCH_TABLE);
}

function dbGetQueryString () {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_TABLE);
}

function dbGetUnmatchedDriversQueryString () {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.UNMATCHED_DRIVERS_VIEW);
}

function dbGetUnmatchedRidersQueryString() {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.UNMATCHED_RIDERS_VIEW);
}

// inserts
function dbGetSubmitDriverString() {
    return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.SUBMIT_DRIVER_FN)
        + ' ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, '
        + '        $13, $14, $15, $16, $17, $18 )';
	
	/*	
	a_IPAddress character varying,
	a_DriverCollectionZIP character varying,
	a_DriverCollectionRadius integer,
	a_AvailableDriveTimesLocal character varying,
	a_DriverCanLoadRiderWithWheelchair boolean,
	a_SeatCount integer,
	a_DriverLicenseNumber character varying,
	a_DriverFirstName character varying,
	a_DriverLastName character varying,
	a_DriverEmail character varying,
	a_DriverPhone character varying,
	a_DrivingOnBehalfOfOrganization boolean,
	a_DrivingOBOOrganizationName character varying,
	a_RidersCanSeeDriverDetails boolean,
	a_DriverWillNotTalkPolitics boolean,
	a_PleaseStayInTouch boolean,
	a_DriverPreferredContact character varying,
	a_DriverWillTakeCare boolean,
	*/
}
function dbGetSubmitRiderString() {
    return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.SUBMIT_RIDER_FN)
        + ' ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, '
        + '        $13, $14, $15, $16, $17, $18, $19, $20 )';
	/* 
	a_IPAddress character varying,
    a_RiderFirstName character varying,
    a_RiderLastName character varying,
    a_RiderEmail character varying,
    a_RiderPhone character varying,
    a_RiderCollectionZIP character varying,
    a_RiderDropOffZIP character varying,
    a_AvailableRideTimesLocal character varying,
    a_TotalPartySize integer,
    a_TwoWayTripNeeded boolean,
    a_RiderIsVulnerable boolean,
    a_RiderWillNotTalkPolitics boolean,
    a_PleaseStayInTouch boolean,
    a_NeedWheelchair boolean,
    a_RiderPreferredContact character varying,
    a_RiderAccommodationNotes character varying,
    a_RiderLegalConsent boolean,
    a_RiderWillBeSafe boolean,
    a_RiderCollectionAddress character varying,
    a_RiderDestinationAddress character varying,
	*/
		
}
function dbGetSubmitHelperString() {
    return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.SUBMIT_HELPER_FN)
        + ' ($1, $2, $3) ';
	
	/*
	a_helpername character varying,
    a_helperemail character varying,
    a_helpercapability character varying[],
	*/
		
}

// custom items, due to be revised
function dbGetMatchRiderQueryString (rider_uuid) {
  return 'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
    'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
    'inner join carpoolvote.driver ' + 
    'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
    'where nov2016.match.uuid_rider = ' + " '" + rider_uuid + "' ";
}

function dbGetMatchDriverQueryString (driver_uuid) {
  return 'SELECT * FROM nov2016.match inner join carpoolvote.rider ' +
    'on (nov2016.match.uuid_rider = carpoolvote.rider."UUID") ' +
    'inner join carpoolvote.driver ' + 
    'on (nov2016.match.uuid_driver = carpoolvote.driver."UUID") ' +
    'where nov2016.match.uuid_driver = ' + " '" + driver_uuid + "' ";
}
