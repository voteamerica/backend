"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class RouteNamesSelfService {
    constructor() {
        this.DRIVER_PROPOSED_MATCHES_ROUTE = 'driver-proposed-matches';
        this.DRIVER_CONFIRMED_MATCHES_ROUTE = 'driver-confirmed-matches';
        this.RIDER_CONFIRMED_MATCH_ROUTE = 'rider-confirmed-match';
    }
}
exports.RouteNamesSelfService = RouteNamesSelfService;
class RouteNamesSelfServiceInfoExists {
    constructor() {
        this.DRIVER_EXISTS_ROUTE = 'driver-exists';
        this.DRIVER_INFO_ROUTE = 'driver-info';
        this.RIDER_EXISTS_ROUTE = 'rider-exists';
        this.RIDER_INFO_ROUTE = 'rider-info';
    }
}
exports.RouteNamesSelfServiceInfoExists = RouteNamesSelfServiceInfoExists;
class RouteNamesAddDriverRider {
    constructor() {
        this.DRIVER_ROUTE = 'driver';
        this.RIDER_ROUTE = 'rider';
        this.HELPER_ROUTE = 'helper';
        this.USER_ROUTE = 'user';
    }
}
exports.RouteNamesAddDriverRider = RouteNamesAddDriverRider;
class RouteNamesMatch {
    constructor() {
        this.CANCEL_RIDER_MATCH_ROUTE = 'cancel-rider-match';
        this.CANCEL_DRIVER_MATCH_ROUTE = 'cancel-driver-match';
        this.ACCEPT_DRIVER_MATCH_ROUTE = 'accept-driver-match';
        this.PAUSE_DRIVER_MATCH_ROUTE = 'pause-driver-match';
    }
}
exports.RouteNamesMatch = RouteNamesMatch;
class RouteNamesCancel {
    constructor() {
        this.CANCEL_RIDE_REQUEST_ROUTE = 'cancel-ride-request';
        this.CANCEL_DRIVE_OFFER_ROUTE = 'cancel-drive-offer';
    }
}
exports.RouteNamesCancel = RouteNamesCancel;
class RouteNamesUnmatched {
    constructor() {
        this.UNMATCHED_DRIVERS_ROUTE = 'unmatched-drivers';
        this.UNMATCHED_RIDERS_ROUTE = 'unmatched-riders';
    }
}
exports.RouteNamesUnmatched = RouteNamesUnmatched;
class RouteNamesDetails {
    constructor() {
        this.DRIVERS_DETAILS_ROUTE = 'drivers-details';
        this.DRIVER_MATCHES_DETAILS_ROUTE = 'driver-matches-details';
    }
}
exports.RouteNamesDetails = RouteNamesDetails;
// class RouteNamesChange {
//   readonly DELETE_DRIVER_ROUTE: string           = 'driver';
//   readonly PUT_RIDER_ROUTE: string               = 'rider';
//   readonly PUT_DRIVER_ROUTE: string              = 'driver';
// }
//# sourceMappingURL=RouteNames.js.map