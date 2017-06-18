"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsTables_1 = require("./DbDefsTables");
var DbQueriesPosts_1 = require("./DbQueriesPosts");
var DbDefsMatchFunctions_1 = require("./DbDefsMatchFunctions");
var DbDefsCancels = (function () {
    function DbDefsCancels() {
        this.CANCEL_RIDE_REQUEST_FUNCTION = 'rider_cancel_ride_request($1, $2)';
        this.CANCEL_RIDER_MATCH_FUNCTION = 'rider_cancel_confirmed_match($1, $2, $3)';
        this.CANCEL_DRIVE_OFFER_FUNCTION = 'driver_cancel_drive_offer($1, $2)';
    }
    return DbDefsCancels;
}());
exports.DbDefsCancels = DbDefsCancels;
var dbDefsSchema = new DbDefsTables_1.DbDefsSchema();
var dbQueriesHelpers = new DbQueriesPosts_1.DbQueriesHelpers();
var dbDefsCancels = new DbDefsCancels();
var dbDefsMatchFunctions = new DbDefsMatchFunctions_1.DbDefsMatchFunctions();
var DbQueriesCancels = (function () {
    function DbQueriesCancels() {
    }
    DbQueriesCancels.prototype.dbCancelRideRequestFunctionString = function () {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDE_REQUEST_FUNCTION);
    };
    DbQueriesCancels.prototype.dbCancelRiderMatchFunctionString = function () {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDER_MATCH_FUNCTION);
    };
    DbQueriesCancels.prototype.dbCancelDriveOfferFunctionString = function () {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_DRIVE_OFFER_FUNCTION);
    };
    DbQueriesCancels.prototype.dbCancelDriverMatchFunctionString = function () {
        return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.CANCEL_DRIVER_MATCH_FUNCTION);
    };
    return DbQueriesCancels;
}());
exports.DbQueriesCancels = DbQueriesCancels;
//# sourceMappingURL=DbDefsCancels.js.map