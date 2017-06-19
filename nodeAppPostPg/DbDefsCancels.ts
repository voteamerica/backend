export { DbDefsCancels, DbQueriesCancels };

import { DbDefsSchema } from "./DbDefsTables"
import { DbQueriesHelpers } from "./DbQueriesPosts"
import { DbDefsMatchFunctions } from "./DbDefsMatchFunctions"

class DbDefsCancels {
  readonly CANCEL_RIDE_REQUEST_FUNCTION: string  = 'rider_cancel_ride_request($1, $2)';
  readonly CANCEL_RIDER_MATCH_FUNCTION: string   = 'rider_cancel_confirmed_match($1, $2, $3)';
  readonly CANCEL_DRIVE_OFFER_FUNCTION: string   = 'driver_cancel_drive_offer($1, $2)';
}

let dbDefsSchema = new DbDefsSchema();
let dbQueriesHelpers = new DbQueriesHelpers();
let dbDefsCancels = new DbDefsCancels();
let dbDefsMatchFunctions = new DbDefsMatchFunctions();

class DbQueriesCancels {
  dbCancelRideRequestFunctionString(): string {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDE_REQUEST_FUNCTION);
  }

  dbCancelRiderMatchFunctionString(): string {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_RIDER_MATCH_FUNCTION);
  }

  dbCancelDriveOfferFunctionString(): string {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsCancels.CANCEL_DRIVE_OFFER_FUNCTION);
  }

  dbCancelDriverMatchFunctionString(): string {
    return dbQueriesHelpers.dbExecuteFunctionString(dbDefsSchema.SCHEMA_NAME, dbDefsMatchFunctions.CANCEL_DRIVER_MATCH_FUNCTION);
  }
}