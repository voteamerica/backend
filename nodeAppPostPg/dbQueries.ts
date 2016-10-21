module.exports = {
  dbRejectRideFunctionString:   dbRejectRideFunctionString,

  dbCancelRideRequestFunctionString:  dbCancelRideRequestFunctionString,
  dbCancelRiderMatchFunctionString:   dbCancelRiderMatchFunctionString,
  dbCancelDriveOfferFunctionString:   dbCancelDriveOfferFunctionString,
  dbCancelDriverMatchFunctionString:  dbCancelDriverMatchFunctionString,

  dbGetMatchRiderQueryString:   dbGetMatchRiderQueryString,
  dbGetMatchDriverQueryString:  dbGetMatchDriverQueryString,
  dbGetMatchesQueryString:      dbGetMatchesQueryString,
  dbGetQueryString:             dbGetQueryString,
  dbGetUnmatchedDriversQueryString: dbGetUnmatchedDriversQueryString,
  dbGetInsertClause:            dbGetInsertClause,
  dbGetInsertDriverString:      dbGetInsertDriverString,
  dbGetInsertRiderString:       dbGetInsertRiderString,
  dbGetInsertHelperString:      dbGetInsertHelperString
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
  return dbExecuteFunctionString(dbDefs.SCHEMA_NOV2016_NAME, dbDefs.CANCEL_RIDE_REQUEST_FUNCTION);
}

function dbCancelRiderMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NOV2016_NAME, dbDefs.CANCEL_RIDER_MATCH_FUNCTION);
}

function dbCancelDriveOfferFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NOV2016_NAME, dbDefs.CANCEL_DRIVE_OFFER_FUNCTION);
}

function dbCancelDriverMatchFunctionString() {
  return dbExecuteFunctionString(dbDefs.SCHEMA_NOV2016_NAME, dbDefs.CANCEL_DRIVER_MATCH_FUNCTION);
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
  return dbSelectFromString(dbDefs.SCHEMA_NOV2016_NAME, dbDefs.MATCH_TABLE);
}

function dbGetQueryString () {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.DRIVER_TABLE);
}

function dbGetUnmatchedDriversQueryString () {
  return dbSelectFromString(dbDefs.SCHEMA_NAME, dbDefs.UNMATCHED_DRIVERS_VIEW);
}

// inserts
function dbGetInsertDriverString() {
  return dbGetInsertClause(dbDefs.DRIVER_TABLE)
    + ' ('   
    + '  "IPAddress", "DriverCollectionZIP", "DriverCollectionRadius", "AvailableDriveTimesJSON"' 
    + ', "DriverCanLoadRiderWithWheelchair", "SeatCount", "DriverHasInsurance"'
    + ', "DriverFirstName", "DriverLastName"'
    + ', "DriverEmail", "DriverPhone"'
    + ', "DrivingOnBehalfOfOrganization", "DrivingOBOOrganizationName", "RidersCanSeeDriverDetails", "DriverWillNotTalkPolitics"'
    + ', "PleaseStayInTouch", "DriverLicenseNumber" '
    + ')'

    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17 )' 
    + ' returning "UUID" ' 
}

function dbGetInsertRiderString() {
  return dbGetInsertClause(dbDefs.RIDER_TABLE)
    + ' ('     
    + '  "IPAddress", "RiderFirstName", "RiderLastName", "RiderEmail"'       
    + ', "RiderPhone", "RiderVotingState"'
    + ', "RiderCollectionZIP", "RiderDropOffZIP", "AvailableRideTimesJSON"'
    + ', "TotalPartySize", "TwoWayTripNeeded", "RiderPreferredContactMethod", "RiderIsVulnerable" '
    + ', "RiderWillNotTalkPolitics", "PleaseStayInTouch", "NeedWheelchair", "RiderAccommodationNotes"'
    + ', "RiderLegalConsent"'
    + ')'
    + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, ' 
    + '        $13, $14, $15, $16, $17, $18 )'
    + ' returning "UUID" ' 
}

function dbGetInsertHelperString() {
  return dbGetInsertClause(dbDefs.HELPER_TABLE)
    + ' ('     
    + '  "helpername", "helperemail", "helpercapability" '       
    // + '  "helpername", "helperemail", "helpercapability", "sweep_status_id", "timestamp" '       
    + ' )'
    + ' values($1, $2, $3) '  
    // + ' values($1, $2, $3, $4, $5) '  
}

// custom items, due to be revised
function dbGetMatchRiderQueryString (rider_uuid) {
  return 'SELECT * FROM nov2016.match inner join stage.websubmission_rider ' +
    'on (nov2016.match.uuid_rider = stage.websubmission_rider."UUID") ' +
    'inner join stage.websubmission_driver ' + 
    'on (nov2016.match.uuid_driver = stage.websubmission_driver."UUID") ' +
    'where nov2016.match.uuid_rider = ' + " '" + rider_uuid + "' ";
}

function dbGetMatchDriverQueryString (driver_uuid) {
  return 'SELECT * FROM nov2016.match inner join stage.websubmission_rider ' +
    'on (nov2016.match.uuid_rider = stage.websubmission_rider."UUID") ' +
    'inner join stage.websubmission_driver ' + 
    'on (nov2016.match.uuid_driver = stage.websubmission_driver."UUID") ' +
    'where nov2016.match.uuid_driver = ' + " '" + driver_uuid + "' ";
}
