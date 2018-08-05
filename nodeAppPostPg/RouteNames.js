"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var RouteNamesSelfService = (function () {
    function RouteNamesSelfService() {
        this.DRIVER_PROPOSED_MATCHES_ROUTE = 'driver-proposed-matches';
        this.DRIVER_CONFIRMED_MATCHES_ROUTE = 'driver-confirmed-matches';
        this.RIDER_CONFIRMED_MATCH_ROUTE = 'rider-confirmed-match';
    }
    return RouteNamesSelfService;
}());
exports.RouteNamesSelfService = RouteNamesSelfService;
var RouteNamesSelfServiceInfoExists = (function () {
    function RouteNamesSelfServiceInfoExists() {
        this.DRIVER_EXISTS_ROUTE = 'driver-exists';
        this.DRIVER_INFO_ROUTE = 'driver-info';
        this.RIDER_EXISTS_ROUTE = 'rider-exists';
        this.RIDER_INFO_ROUTE = 'rider-info';
    }
    return RouteNamesSelfServiceInfoExists;
}());
exports.RouteNamesSelfServiceInfoExists = RouteNamesSelfServiceInfoExists;
var RouteNamesAddDriverRider = (function () {
    function RouteNamesAddDriverRider() {
        this.DRIVER_ROUTE = 'driver';
        this.RIDER_ROUTE = 'rider';
        this.HELPER_ROUTE = 'helper';
    }
    return RouteNamesAddDriverRider;
}());
exports.RouteNamesAddDriverRider = RouteNamesAddDriverRider;
var RouteNamesMatch = (function () {
    function RouteNamesMatch() {
        this.CANCEL_RIDER_MATCH_ROUTE = 'cancel-rider-match';
        this.CANCEL_DRIVER_MATCH_ROUTE = 'cancel-driver-match';
        this.ACCEPT_DRIVER_MATCH_ROUTE = 'accept-driver-match';
        this.PAUSE_DRIVER_MATCH_ROUTE = 'pause-driver-match';
    }
    return RouteNamesMatch;
}());
exports.RouteNamesMatch = RouteNamesMatch;
var RouteNamesCancel = (function () {
    function RouteNamesCancel() {
        this.CANCEL_RIDE_REQUEST_ROUTE = 'cancel-ride-request';
        this.CANCEL_DRIVE_OFFER_ROUTE = 'cancel-drive-offer';
    }
    return RouteNamesCancel;
}());
exports.RouteNamesCancel = RouteNamesCancel;
var RouteNamesUnmatched = (function () {
    function RouteNamesUnmatched() {
        this.UNMATCHED_DRIVERS_ROUTE = 'unmatched-drivers';
        this.UNMATCHED_RIDERS_ROUTE = 'unmatched-riders';
    }
    return RouteNamesUnmatched;
}());
exports.RouteNamesUnmatched = RouteNamesUnmatched;
var RouteNamesDetails = /** @class */ (function () {
    function RouteNamesDetails() {
        this.DRIVERS_DETAILS_ROUTE = 'drivers-details';
        this.DRIVER_MATCHES_DETAILS_ROUTE = 'driver-matches-details';
    }
    return RouteNamesDetails;
}());
exports.RouteNamesDetails = RouteNamesDetails;
// class RouteNamesChange {
//   readonly DELETE_DRIVER_ROUTE: string           = 'driver';
//   readonly PUT_RIDER_ROUTE: string               = 'rider';
//   readonly PUT_DRIVER_ROUTE: string              = 'driver';
// }
//# sourceMappingURL=RouteNames.js.map