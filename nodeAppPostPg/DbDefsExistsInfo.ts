export { DbDefsExistsInfo };

class DbDefsExistsInfo {
    readonly DRIVER_EXISTS_FUNCTION: string   = 'driver_exists($1, $2)';
    readonly DRIVER_INFO_FUNCTION: string   = 'driver_info($1, $2)';

    readonly RIDER_EXISTS_FUNCTION: string   = 'rider_exists($1, $2)';
    readonly RIDER_INFO_FUNCTION: string   = 'rider_info($1, $2)';
}