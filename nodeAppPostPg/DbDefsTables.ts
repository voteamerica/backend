export { DbDefsTables, DbDefsSchema, DbDefsViews };

class DbDefsSchema {
  readonly SCHEMA_NAME: string = 'carpoolvote';
}

class DbDefsTables {
  readonly DRIVER_TABLE: string  = 'driver';
  readonly RIDER_TABLE: string   = 'rider';
  readonly HELPER_TABLE: string  = 'helper';
  readonly MATCH_TABLE: string   = 'match';
}

class DbDefsViews {
  readonly UNMATCHED_DRIVERS_VIEW: string  = 'vw_unmatched_drivers';
  readonly UNMATCHED_DRIVERS_DETAILS_VIEW: string  = 'vw_unmatched_drivers_details';
  readonly UNMATCHED_RIDERS_VIEW: string   = 'vw_unmatched_riders';
  readonly UNMATCHED_RIDERS_DETAILS_VIEW: string  = 'vw_unmatched_riders_details';
}
