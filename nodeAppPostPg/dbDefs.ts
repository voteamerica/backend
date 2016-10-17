const SCHEMA_NAME           = 'stage';
const SCHEMA_NOV2016_NAME   = 'nov2016';

const DRIVER_TABLE  = 'websubmission_driver';
const RIDER_TABLE   = 'websubmission_rider';
const HELPER_TABLE  = 'websubmission_helper';
const MATCH_TABLE   = 'match';

var CANCEL_RIDE_FUNCTION = 'cancel_ride($1)';
var REJECT_RIDE_FUNCTION = 'reject_ride($1)';

// for db carpool
module.exports = {
  SCHEMA_NAME:          SCHEMA_NAME,
  SCHEMA_NOV2016_NAME:  SCHEMA_NOV2016_NAME,

  DRIVER_TABLE: DRIVER_TABLE,
  RIDER_TABLE:  RIDER_TABLE,
  HELPER_TABLE: HELPER_TABLE,
  MATCH_TABLE:  MATCH_TABLE,

  CANCEL_RIDE_FUNCTION: CANCEL_RIDE_FUNCTION,
  REJECT_RIDE_FUNCTION: REJECT_RIDE_FUNCTION,
}

