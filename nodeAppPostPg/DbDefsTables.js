"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class DbDefsSchema {
    constructor() {
        this.SCHEMA_NAME = 'carpoolvote';
    }
}
exports.DbDefsSchema = DbDefsSchema;
class DbDefsTables {
    constructor() {
        this.DRIVER_TABLE = 'driver';
        this.RIDER_TABLE = 'rider';
        this.HELPER_TABLE = 'helper';
        this.MATCH_TABLE = 'match';
        this.USER_TABLE = 'operator';
    }
}
exports.DbDefsTables = DbDefsTables;
class DbDefsViews {
    constructor() {
        this.UNMATCHED_DRIVERS_VIEW = 'vw_unmatched_drivers';
        this.UNMATCHED_DRIVERS_DETAILS_VIEW = 'vw_unmatched_drivers_details';
        this.UNMATCHED_RIDERS_VIEW = 'vw_unmatched_riders';
        this.UNMATCHED_RIDERS_DETAILS_VIEW = 'vw_unmatched_riders_details';
        this.DRIVERS_DETAILS_VIEW = 'vw_drivers_details';
        this.DRIVER_MATCHES_DETAILS_VIEW = 'vw_driver_matches_details';
    }
}
exports.DbDefsViews = DbDefsViews;
//# sourceMappingURL=DbDefsTables.js.map