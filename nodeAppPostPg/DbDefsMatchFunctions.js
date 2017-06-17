"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsMatchFunctions = (function () {
    function DbDefsMatchFunctions() {
        this.CANCEL_DRIVER_MATCH_FUNCTION = 'driver_cancel_confirmed_match($1, $2, $3)';
        this.ACCEPT_DRIVER_MATCH_FUNCTION = 'driver_confirm_match($1, $2, $3)';
        this.PAUSE_DRIVER_MATCH_FUNCTION = 'driver_pause_match($1, $2)';
        // not currently used
        this.RIDER_CONFIRMED_MATCH_FUNCTION = 'rider_confirmed_match($1, $2)';
    }
    return DbDefsMatchFunctions;
}());
exports.DbDefsMatchFunctions = DbDefsMatchFunctions;
//# sourceMappingURL=DbDefsMatchFunctions.js.map