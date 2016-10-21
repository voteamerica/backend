const SCHEMA_NAME           = 'stage';
const SCHEMA_NOV2016_NAME   = 'nov2016';

const DRIVER_TABLE  = 'websubmission_driver';
const RIDER_TABLE   = 'websubmission_rider';
const HELPER_TABLE  = 'websubmission_helper';
const MATCH_TABLE   = 'match';

const UNMATCHED_DRIVERS_VIEW    = 'vw_unmatched_riders';

const CANCEL_RIDE_REQUEST_FUNCTION  = 'cancel_ride_request($1, $2)';
const CANCEL_RIDE_OFFER_FUNCTION  = 'cancel_drive_offer($1, $2)';
const REJECT_RIDE_FUNCTION        = 'reject_ride($1, $2)';
const CONFIRM_RIDE_FUNCTION       = 'confirm_ride($1, $2)';

// new
const CANCEL_RIDER_MATCH_FUNCTION   = 'rider_cancel_confirmed_match($1, $2)';
const CANCEL_DRIVER_MATCH_FUNCTION  = 'driver_cancel_confirmed_match($1, $2)';


// for db carpool
module.exports = {
  SCHEMA_NAME:          SCHEMA_NAME,
  SCHEMA_NOV2016_NAME:  SCHEMA_NOV2016_NAME,

  UNMATCHED_DRIVERS_VIEW: UNMATCHED_DRIVERS_VIEW,

  DRIVER_TABLE: DRIVER_TABLE,
  RIDER_TABLE:  RIDER_TABLE,
  HELPER_TABLE: HELPER_TABLE,
  MATCH_TABLE:  MATCH_TABLE,

  CANCEL_RIDE_REQUEST_FUNCTION: CANCEL_RIDE_REQUEST_FUNCTION,
  CANCEL_RIDE_OFFER_FUNCTION: CANCEL_RIDE_OFFER_FUNCTION,
  REJECT_RIDE_FUNCTION: REJECT_RIDE_FUNCTION,
  CONFIRM_RIDE_FUNCTION: CONFIRM_RIDE_FUNCTION
}
