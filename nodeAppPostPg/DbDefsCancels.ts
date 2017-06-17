export { DbDefsCancels };

class DbDefsCancels {
  readonly CANCEL_RIDE_REQUEST_FUNCTION: string  = 'rider_cancel_ride_request($1, $2)';
  readonly CANCEL_RIDER_MATCH_FUNCTION: string   = 'rider_cancel_confirmed_match($1, $2, $3)';
  readonly CANCEL_DRIVE_OFFER_FUNCTION: string   = 'driver_cancel_drive_offer($1, $2)';
}