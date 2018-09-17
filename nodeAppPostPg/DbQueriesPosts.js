"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const DbDefsTables_1 = require("./DbDefsTables");
const DbDefsSubmits_1 = require("./DbDefsSubmits");
class DbQueriesHelpers {
    dbExecuteFunctionString(schema, functionName) {
        return 'SELECT ' + schema + '.' + functionName;
    }
    dbSelectFromString(schema, tableOrView) {
        return 'SELECT * FROM ' + schema + '.' + tableOrView;
    }
    dbGetInsertClause(tableName) {
        return 'INSERT INTO ' + dbDefsSchema.SCHEMA_NAME + '.' + tableName;
    }
}
exports.DbQueriesHelpers = DbQueriesHelpers;
let dbQueriesHelpers = new DbQueriesHelpers();
let dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
let dbDefsSubmits = new DbDefsSubmits_1.DbDefsSubmits();
class DbQueriesPosts {
    // inserts // , "DriverHasInsurance" , $17
    dbGetSubmitDriverString() {
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
    }
    dbGetSubmitRiderString() {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_RIDER_FN)
            + ' ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, '
            + '        $13, $14, $15, $16, $17, $18, $19, $20, $21, $22 )'; /* TODO add $21 for new a_RiderCollectionStreetNumber when form is ready */
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
          a_RidingOnBehalfOfOrganization boolean,
          a_RidingOBOOrganizationName character varying,
        */
    }
    dbGetSubmitHelperString() {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_HELPER_FN)
            + ' ($1, $2, $3) ';
        /*
        a_helpername character varying,
          a_helperemail character varying,
          a_helpercapability character varying[],
        */
    }
    dbGetSubmitUserString() {
        return dbQueriesHelpers.dbSelectFromString(dbDefsSchema.SCHEMA_NAME, dbDefsSubmits.SUBMIT_USER_FN)
            + ' ($1, $2, $3, $4)';
        /*
        email character varying,
        username character varying,
        password character varying,
        is_admin boolean
        */
    }
}
exports.DbQueriesPosts = DbQueriesPosts;
//# sourceMappingURL=DbQueriesPosts.js.map