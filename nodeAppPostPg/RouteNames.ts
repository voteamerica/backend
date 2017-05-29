export { RouteNamesAddDriverRider, 
          RouteNamesCancel,
          RouteNamesUnmatched, 
          // RouteNamesChange,
          RouteNamesSelfService, 
          RouteNamesSelfServiceInfoExists, 
          RouteNamesMatch };

class RouteNamesSelfService {
  readonly DRIVER_PROPOSED_MATCHES_ROUTE: string = 'driver-proposed-matches';
  readonly DRIVER_CONFIRMED_MATCHES_ROUTE: string = 'driver-confirmed-matches';
  readonly RIDER_CONFIRMED_MATCH_ROUTE: string = 'rider-confirmed-match';
}

class RouteNamesSelfServiceInfoExists {
  readonly DRIVER_EXISTS_ROUTE: string = 'driver-exists';
  readonly DRIVER_INFO_ROUTE: string ='driver-info';

  readonly RIDER_EXISTS_ROUTE: string = 'rider-exists';
  readonly RIDER_INFO_ROUTE: string = 'rider-info';
}

class RouteNamesAddDriverRider {
  readonly DRIVER_ROUTE:string  = 'driver';
  readonly RIDER_ROUTE:string   = 'rider';
  readonly HELPER_ROUTE:string  = 'helper';
}

class RouteNamesMatch {
  readonly CANCEL_RIDER_MATCH_ROUTE: string  = 'cancel-rider-match';
  readonly CANCEL_DRIVER_MATCH_ROUTE: string = 'cancel-driver-match';
  readonly ACCEPT_DRIVER_MATCH_ROUTE: string = 'accept-driver-match';
  readonly PAUSE_DRIVER_MATCH_ROUTE: string  = 'pause-driver-match';
}

class RouteNamesCancel {
  readonly CANCEL_RIDE_REQUEST_ROUTE: string = 'cancel-ride-request';
  readonly CANCEL_DRIVE_OFFER_ROUTE: string  = 'cancel-drive-offer';
}

class RouteNamesUnmatched {
  readonly UNMATCHED_DRIVERS_ROUTE: string = 'unmatched-drivers';
  readonly UNMATCHED_RIDERS_ROUTE: string = 'unmatched-riders';
}

// class RouteNamesChange {
//   readonly DELETE_DRIVER_ROUTE: string           = 'driver';
//   readonly PUT_RIDER_ROUTE: string               = 'rider';
//   readonly PUT_DRIVER_ROUTE: string              = 'driver';
// }

