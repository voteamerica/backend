"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var DbDefsCancels = (function () {
    function DbDefsCancels() {
        this.CANCEL_RIDE_REQUEST_FUNCTION = 'rider_cancel_ride_request($1, $2)';
        this.CANCEL_RIDER_MATCH_FUNCTION = 'rider_cancel_confirmed_match($1, $2, $3)';
        this.CANCEL_DRIVE_OFFER_FUNCTION = 'driver_cancel_drive_offer($1, $2)';
    }
    return DbDefsCancels;
}());
exports.DbDefsCancels = DbDefsCancels;
//# sourceMappingURL=DbDefsCancels.js.map