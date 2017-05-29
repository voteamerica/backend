"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsSchema = (function () {
    function DbDefsSchema() {
        this.SCHEMA_NAME = 'carpoolvote';
    }
    return DbDefsSchema;
}());
exports.DbDefsSchema = DbDefsSchema;
var DbDefsTables = (function () {
    function DbDefsTables() {
        this.DRIVER_TABLE = 'driver';
        this.RIDER_TABLE = 'rider';
        this.HELPER_TABLE = 'helper';
        this.MATCH_TABLE = 'match';
    }
    return DbDefsTables;
}());
exports.DbDefsTables = DbDefsTables;
var DbDefsViews = (function () {
    function DbDefsViews() {
        this.UNMATCHED_DRIVERS_VIEW = 'vw_unmatched_drivers';
        this.UNMATCHED_RIDERS_VIEW = 'vw_unmatched_riders';
    }
    return DbDefsViews;
}());
exports.DbDefsViews = DbDefsViews;
//# sourceMappingURL=DbDefsTables.js.map