"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsSchema = /** @class */ (function () {
    function DbDefsSchema() {
        this.SCHEMA_NAME = 'carpoolvote';
    }
    return DbDefsSchema;
}());
exports.DbDefsSchema = DbDefsSchema;
var DbDefsTables = /** @class */ (function () {
    function DbDefsTables() {
        this.DRIVER_TABLE = 'driver';
        this.RIDER_TABLE = 'rider';
        this.HELPER_TABLE = 'helper';
        this.MATCH_TABLE = 'match';
    }
    return DbDefsTables;
}());
exports.DbDefsTables = DbDefsTables;
var DbDefsViews = /** @class */ (function () {
    function DbDefsViews() {
        this.UNMATCHED_DRIVERS_VIEW = 'vw_unmatched_drivers';
        this.UNMATCHED_DRIVERS_DETAILS_VIEW = 'vw_unmatched_drivers_details';
        this.UNMATCHED_RIDERS_VIEW = 'vw_unmatched_riders';
        this.UNMATCHED_RIDERS_DETAILS_VIEW = 'vw_unmatched_riders_details';
    }
    return DbDefsViews;
}());
exports.DbDefsViews = DbDefsViews;
//# sourceMappingURL=DbDefsTables.js.map