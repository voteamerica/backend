module.exports = {
  dbRejectRideFunctionString:   dbRejectRideFunctionString,
  dbCancelRideFunctionString:   dbCancelRideFunctionString,
  dbGetMatchRiderQueryString:   dbGetMatchRiderQueryString,
  dbGetMatchDriverQueryString:  dbGetMatchDriverQueryString,
  dbGetMatchesQueryString:      dbGetMatchesQueryString,
  dbGetQueryString:             dbGetQueryString,
  dbGetUnmatchedDriversQueryString: dbGetMatchDriverQueryString,
  dbGetInsertClause:            dbGetInsertClause,
  dbGetInsertDriverString:      dbGetInsertDriverString,
  dbGetInsertRiderString:       dbGetInsertRiderString,
  dbGetInsertHelperString:      dbGetInsertHelperString
}

const dbDefs = require('./dbDefs.js');

function dbRejectRideFunctionString() {
    return 'select ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.REJECT_RIDE_FUNCTION;
}

function dbConfirmRideFunctionString() {
    return 'select ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.CONFIRM_RIDE_FUNCTION;
}

function dbCancelRideFunctionString() {
    return 'select ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.CANCEL_RIDE_FUNCTION;
}

function dbCancelRideOfferFunctionString() {
    return 'select ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.CANCEL_RIDE_OFFER_FUNCTION;
}

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

function dbGetMatchesQueryString () {
  return 'SELECT * FROM ' + dbDefs.SCHEMA_NOV2016_NAME + '.' + dbDefs.MATCH_TABLE;
}

function dbGetQueryString () {
  return 'SELECT * FROM ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.DRIVER_TABLE;
}

function dbGetUnmatchedDriversQueryString () {
  return 'SELECT * FROM ' + dbDefs.SCHEMA_NAME + '.' + dbDefs.UNMATCHED_DRIVERS_VIEW;
}

function dbGetInsertClause (tableName) {
  return 'INSERT INTO ' + dbDefs.SCHEMA_NAME + '.' + tableName;
}

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
    + '  "helpername", "helperemail", "helpercapability", "sweep_status_id", "timestamp" '       
    + ' )'
    + ' values($1, $2, $3, $4, $5) '  
}

