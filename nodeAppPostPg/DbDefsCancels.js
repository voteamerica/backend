"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const DbDefsTables_1 = require("./DbDefsTables");
const DbQueriesPosts_1 = require("./DbQueriesPosts");
const DbDefsMatchFunctions_1 = require("./DbDefsMatchFunctions");
class DbDefsCancels {
    constructor() {
        this.CANCEL_RIDE_REQUEST_FUNCTION = 'rider_cancel_ride_request($1, $2)';
        this.CANCEL_RIDER_MATCH_FUNCTION = 'rider_cancel_confirmed_match($1, $2, $3)';
        this.CANCEL_DRIVE_OFFER_FUNCTION = 'driver_cancel_drive_offer($1, $2)';
    }
}
exports.DbDefsCancels = DbDefsCancels;
let dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
let dbQueriesHelpers = new DbQueriesPosts_1.DbQueriesHelpers();
let dbDefsCancels = new DbDefsCancels();
let dbDefsMatchFunctions = new DbDefsMatchFunctions_1.DbDefsMatchFunctions();
class DbQueriesCancels {
    dbCancelRideRequestFunctionString() {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDE_REQUEST_FUNCTION);
    }
    dbCancelRiderMatchFunctionString() {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDER_MATCH_FUNCTION);
    }
    dbCancelDriveOfferFunctionString() {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_DRIVE_OFFER_FUNCTION);
    }
    dbCancelDriverMatchFunctionString() {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.CANCEL_DRIVER_MATCH_FUNCTION);
    }
}
exports.DbQueriesCancels = DbQueriesCancels;
//# sourceMappingURL=DbDefsCancels.js.map