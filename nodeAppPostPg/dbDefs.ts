// location of db names 

const SCHEMA_NAME: string           = 'carpoolvote';

const UNMATCHED_DRIVERS_VIEW: string  = 'vw_unmatched_drivers';
const UNMATCHED_RIDERS_VIEW: string   = 'vw_unmatched_riders';

const CANCEL_RIDE_REQUEST_FUNCTION: string  = 'rider_cancel_ride_request($1, $2)';
const CANCEL_RIDER_MATCH_FUNCTION: string   = 'rider_cancel_confirmed_match($1, $2, $3)';
const CANCEL_DRIVE_OFFER_FUNCTION: string   = 'driver_cancel_drive_offer($1, $2)';
const CANCEL_DRIVER_MATCH_FUNCTION: string  = 'driver_cancel_confirmed_match($1, $2, $3)';

const ACCEPT_DRIVER_MATCH_FUNCTION: string  = 'driver_confirm_match($1, $2, $3)';
const PAUSE_DRIVER_MATCH_FUNCTION: string   = 'driver_pause_match($1, $2)';

// self service 

const RIDER_CONFIRMED_MATCH_FUNCTION: string   = 'rider_confirmed_match($1, $2)';


// designed for an earlier db design
const CANCEL_RIDE_OFFER_FUNCTION: string  = 'cancel_drive_offer($1, $2)';
const REJECT_RIDE_FUNCTION: string        = 'reject_ride($1, $2)';
const CONFIRM_RIDE_FUNCTION: string       = 'confirm_ride($1, $2)';

// for db carpool
module.exports = {
  SCHEMA_NAME:          SCHEMA_NAME,

  UNMATCHED_DRIVERS_VIEW: UNMATCHED_DRIVERS_VIEW,
  UNMATCHED_RIDERS_VIEW: UNMATCHED_RIDERS_VIEW,

  CANCEL_RIDE_REQUEST_FUNCTION: CANCEL_RIDE_REQUEST_FUNCTION,
  CANCEL_RIDER_MATCH_FUNCTION:  CANCEL_RIDER_MATCH_FUNCTION,
  CANCEL_DRIVE_OFFER_FUNCTION:  CANCEL_DRIVE_OFFER_FUNCTION,
  CANCEL_DRIVER_MATCH_FUNCTION: CANCEL_DRIVER_MATCH_FUNCTION,

  ACCEPT_DRIVER_MATCH_FUNCTION: ACCEPT_DRIVER_MATCH_FUNCTION,
  PAUSE_DRIVER_MATCH_FUNCTION:  PAUSE_DRIVER_MATCH_FUNCTION,

  RIDER_CONFIRMED_MATCH_FUNCTION: RIDER_CONFIRMED_MATCH_FUNCTION,

  CANCEL_RIDE_OFFER_FUNCTION: CANCEL_RIDE_OFFER_FUNCTION,
  REJECT_RIDE_FUNCTION: REJECT_RIDE_FUNCTION,
  CONFIRM_RIDE_FUNCTION: CONFIRM_RIDE_FUNCTION
}
