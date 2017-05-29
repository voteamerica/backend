export { DbDefsMatchFunctions };

class DbDefsMatchFunctions {
  readonly CANCEL_DRIVER_MATCH_FUNCTION: string  = 'driver_cancel_confirmed_match($1, $2, $3)';
  readonly ACCEPT_DRIVER_MATCH_FUNCTION: string  = 'driver_confirm_match($1, $2, $3)';
  readonly PAUSE_DRIVER_MATCH_FUNCTION: string   = 'driver_pause_match($1, $2)';
}

