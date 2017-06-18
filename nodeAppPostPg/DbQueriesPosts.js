"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsTables_1 = require("./DbDefsTables");
var DbDefsSubmits_1 = require("./DbDefsSubmits");
var DbQueriesHelpers = (function () {
    function DbQueriesHelpers() {
    }
    DbQueriesHelpers.prototype.dbExecuteFunctionString = function (schema, functionName) {
        return 'SELECT ' + schema + '.' + functionName;
    };
    DbQueriesHelpers.prototype.dbSelectFromString = function (schema, tableOrView) {
        return 'SELECT * FROM ' + schema + '.' + tableOrView;
    };
    DbQueriesHelpers.prototype.dbGetInsertClause = function (tableName) {
        return 'INSERT INTO ' + dbDefsSchema.SCHEMA_NAME + '.' + tableName;
    };
    return DbQueriesHelpers;
}());
exports.DbQueriesHelpers = DbQueriesHelpers;
var dbQueriesHelpers = new DbQueriesHelpers();
var dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
var dbDefsSubmits = new DbDefsSubmits_1.DbDefsSubmits();
var DbQueriesPosts = (function () {
    function DbQueriesPosts() {
    }
    // inserts // , "DriverHasInsurance" , $17
    DbQueriesPosts.prototype.dbGetSubmitDriverString = function () {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_DRIVER_FN)
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
    };
    DbQueriesPosts.prototype.dbGetSubmitRiderString = function () {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_RIDER_FN)
            + ' ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, '
            + '        $13, $14, $15, $16, $17, $18, $19, $20 )'; /* TODO add $21 for new a_RiderCollectionStreetNumber when form is ready */
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
          a_RiderCollectionStreetNumber character varying,  --- 4/30: this is new field on the API, see backend issue #105
          a_RiderCollectionAddress character varying,
          a_RiderDestinationAddress character varying,
        */
    };
    DbQueriesPosts.prototype.dbGetSubmitHelperString = function () {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_HELPER_FN)
            + ' ($1, $2, $3) ';
        /*
        a_helpername character varying,
          a_helperemail character varying,
          a_helpercapability character varying[],
        */
    };
    return DbQueriesPosts;
}());
exports.DbQueriesPosts = DbQueriesPosts;
//# sourceMappingURL=DbQueriesPosts.js.map