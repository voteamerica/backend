-- View: carpoolvote.vw_drive_offer

-- DROP VIEW carpoolvote.vw_drive_offer;
-- used by show_driver_by_uuid.sh, show_last_drivers.sh
-- not used by nodeApp
CREATE OR REPLACE VIEW carpoolvote.vw_drive_offer AS 
 SELECT driver."UUID",
    driver."DriverLastName",
    driver."DriverPhone",
    driver."DriverEmail",
    driver.status,
    driver.status_info,
    driver.created_ts,
    driver.last_updated_ts,
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DrivingOnBehalfOfOrganization",
    carpoolvote.convert_datetime_to_local_format(driver."AvailableDriveTimesLocal")
   FROM carpoolvote.driver;

ALTER TABLE carpoolvote.vw_drive_offer
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_drive_offer TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_drive_offer TO carpool_role;



-- View: carpoolvote.vw_driver_matches
-- DROP VIEW carpoolvote.vw_driver_matches;
-- used in fct_user_actions.sql, driver_confirmed_matches, driver_proposed_matches
CREATE OR REPLACE VIEW carpoolvote.vw_driver_matches AS 
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
	match.driver_notes,
    rider."UUID",
    rider."IPAddress",
    rider."RiderFirstName",
    rider."RiderLastName",
    rider."RiderEmail",
    rider."RiderPhone",
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    carpoolvote.convert_datetime_to_local_format(rider."AvailableRideTimesLocal"),
    rider."TotalPartySize",
    rider."TwoWayTripNeeded",
    rider."RiderIsVulnerable",
    rider."RiderWillNotTalkPolitics",
    rider."PleaseStayInTouch",
    rider."NeedWheelchair",
    rider."RiderPreferredContact",
    rider."RiderAccommodationNotes",
    rider."RiderLegalConsent",
    rider."ReadyToMatch",
    rider.status,
    rider.status_info,
    rider."RiderWillBeSafe",
    rider."RiderCollectionAddress",
    rider."RiderDestinationAddress"
   FROM carpoolvote.match
     JOIN carpoolvote.rider ON rider."UUID"::text = match.uuid_rider::text;

ALTER TABLE carpoolvote.vw_driver_matches
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_driver_matches TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_driver_matches TO carpool_web_role;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE carpoolvote.vw_driver_matches TO carpool_role;


-- View: carpoolvote.vw_ride_request

-- DROP VIEW carpoolvote.vw_ride_request;
-- used by show_last_riders.sh, show_rider_by_uuid.sh
CREATE OR REPLACE VIEW carpoolvote.vw_ride_request AS 
 SELECT rider."UUID" AS uuid,
    rider."RiderLastName",
    rider."RiderPhone",
    rider."RiderEmail",
    rider.status,
    rider.status_info,
    rider.created_ts,
    rider.last_updated_ts,
    rider."RiderCollectionZIP",
    rider."RiderDropOffZIP",
    rider."TotalPartySize",
    rider."RiderIsVulnerable",
    rider."NeedWheelchair",
    carpoolvote.convert_datetime_to_local_format(rider."AvailableRideTimesLocal")
   FROM carpoolvote.rider;

ALTER TABLE carpoolvote.vw_ride_request
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_ride_request TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_ride_request TO carpool_role;



-- View: carpoolvote.vw_rider_matches

-- DROP VIEW carpoolvote.vw_rider_matches;
-- used in fct_user_actions.sql
CREATE OR REPLACE VIEW carpoolvote.vw_rider_matches AS 
 SELECT match.status AS "matchStatus",
    match.uuid_driver,
    match.uuid_rider,
    match.score,
	match.rider_notes,
    driver."UUID",
    driver."IPAddress",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    carpoolvote.convert_datetime_to_local_format(driver."AvailableDriveTimesLocal"),
    driver."DriverCanLoadRiderWithWheelchair",
    driver."SeatCount",
    driver."DriverLicenseNumber",
    driver."DriverFirstName",
    driver."DriverLastName",
    driver."DriverEmail",
    driver."DriverPhone",
    driver."DrivingOnBehalfOfOrganization",
    driver."DrivingOBOOrganizationName",
    driver."RidersCanSeeDriverDetails",
    driver."DriverWillNotTalkPolitics",
    driver."ReadyToMatch",
    driver."PleaseStayInTouch",
    driver.status,
    driver.status_info,
    driver."DriverPreferredContact",
    driver."DriverWillTakeCare"
   FROM carpoolvote.match
     JOIN carpoolvote.driver ON driver."UUID"::text = match.uuid_driver::text;

ALTER TABLE carpoolvote.vw_rider_matches
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_rider_matches TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_rider_matches TO carpool_web_role;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE carpoolvote.vw_rider_matches TO carpool_role;


-- View: carpoolvote.vw_unmatched_drivers

-- DROP VIEW carpoolvote.vw_unmatched_drivers;

CREATE OR REPLACE VIEW carpoolvote.vw_unmatched_drivers AS 
 SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM carpoolvote.driver driver,
    carpoolvote.zip_codes zip_codes
  WHERE (driver.status::text = ANY (ARRAY['Pending'::character varying::text, 'MatchProposed'::character varying::text])) AND driver."DriverCollectionZIP"::text = zip_codes.zip::text
  GROUP BY zip_codes.zip;

ALTER TABLE carpoolvote.vw_unmatched_drivers
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_unmatched_drivers TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_drivers TO carpool_web_role;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_drivers TO carpool_role;

-- View: carpoolvote.vw_unmatched_drivers_details

-- DROP VIEW carpoolvote.vw_unmatched_drivers_details;

CREATE OR REPLACE VIEW carpoolvote.vw_unmatched_drivers_details AS 
 SELECT driver."UUID",
    driver."DriverCollectionZIP",
    driver."DriverCollectionRadius",
    driver."SeatCount",
	driver."DriverCanLoadRiderWithWheelchair",
    carpoolvote.convert_datetime_to_local_format(driver."AvailableDriveTimesLocal")
   FROM carpoolvote.driver
  WHERE (driver.status::text = ANY (ARRAY['Pending'::character varying::text, 'MatchProposed'::character varying::text, 'MatchConfirmed'::character varying::text])) AND driver."ReadyToMatch" = true;

ALTER TABLE carpoolvote.vw_unmatched_drivers_details
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_unmatched_drivers_details TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_drivers_details TO carpool_role;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_drivers_details TO carpool_web;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_drivers_details TO carpool_web_role;

-- View: carpoolvote.vw_unmatched_riders

-- DROP VIEW carpoolvote.vw_unmatched_riders;

CREATE OR REPLACE VIEW carpoolvote.vw_unmatched_riders AS 
 SELECT count(*) AS count,
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
   FROM carpoolvote.rider rider,
    carpoolvote.zip_codes zip_codes
  WHERE (rider.status::text = ANY (ARRAY['Pending'::character varying::text, 'MatchProposed'::character varying::text])) AND rider."RiderCollectionZIP"::text = zip_codes.zip::text
  GROUP BY zip_codes.zip;

ALTER TABLE carpoolvote.vw_unmatched_riders
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_unmatched_riders TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_riders TO carpool_web_role;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_riders TO carpool_role;

-- View: carpoolvote.vw_unmatched_riders_details

-- DROP VIEW carpoolvote.vw_unmatched_riders_details;

CREATE OR REPLACE VIEW carpoolvote.vw_unmatched_riders_details AS 
 SELECT rider."UUID",
    rider."RiderCollectionZIP",
    rider."TotalPartySize",
    rider."NeedWheelchair",
    carpoolvote.convert_datetime_to_local_format(rider."AvailableRideTimesLocal")
   FROM carpoolvote.rider
  WHERE rider.status::text = ANY (ARRAY['Pending'::character varying::text, 'MatchProposed'::character varying::text]);

ALTER TABLE carpoolvote.vw_unmatched_riders_details
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_unmatched_riders_details TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_riders_details TO carpool_role;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_riders_details TO carpool_web;
GRANT SELECT ON TABLE carpoolvote.vw_unmatched_riders_details TO carpool_web_role;


-- View: carpoolvote.vw_drivers_details

-- DROP VIEW carpoolvote.vw_drivers_details;

CREATE OR REPLACE VIEW carpoolvote.vw_drivers_details AS 
  SELECT 1 AS count, 
    "DriverCollectionZIP", 
    "DriverCollectionRadius", 
    "AvailableDriveTimesLocal", 
    "DriverCanLoadRiderWithWheelchair", 
    "SeatCount", 
    "DrivingOnBehalfOfOrganization", 
    "DrivingOBOOrganizationName", 
    "ReadyToMatch",  
    status, 
    created_ts, 
    last_updated_ts, 
    status_info,
    carpoolvote.convert_datetime_to_local_format(driver."AvailableDriveTimesLocal"),
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric
  FROM carpoolvote.driver,
    carpoolvote.zip_codes zip_codes
  where status != 'Canceled'AND 
    driver."DriverCollectionZIP"::text = zip_codes.zip::text;

ALTER TABLE carpoolvote.vw_drivers_details
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_drivers_details TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_drivers_details TO carpool_role;
GRANT SELECT ON TABLE carpoolvote.vw_drivers_details TO carpool_web;
GRANT SELECT ON TABLE carpoolvote.vw_drivers_details TO carpool_web_role;


-- View: carpoolvote.vw_driver_matches_details

-- DROP VIEW carpoolvote.vw_driver_matches_details;

CREATE OR REPLACE VIEW carpoolvote.vw_driver_matches_details AS 
  SELECT 1 AS count, 
    "DriverCollectionZIP", 
    "DriverCollectionRadius", 
    "DriverCanLoadRiderWithWheelchair", 
    "SeatCount", 
    "DrivingOnBehalfOfOrganization", 
    "DrivingOBOOrganizationName", 
    driver."ReadyToMatch",  
    driver.status, 
    driver.created_ts, 
    driver.last_updated_ts, 
    driver.status_info,
    carpoolvote.convert_datetime_to_local_format(driver."AvailableDriveTimesLocal"),
    zip_codes.zip,
    zip_codes.state,
    zip_codes.city,
    zip_codes.full_state,
    zip_codes.latitude_numeric,
    zip_codes.longitude_numeric,
    "matchStatus", 
    score, 
    convert_datetime_to_local_format AS "Matches_convert_datetime_to_local_format", 
    "TotalPartySize", 
    "TwoWayTripNeeded", 
    vw_driver_matches."ReadyToMatch" AS "Matches_ReadyToMatch", 
    vw_driver_matches.status AS "Matches_Status", 
    vw_driver_matches.status_info AS "Matches_StatusInfo"
  FROM carpoolvote.driver,
    carpoolvote.zip_codes zip_codes,carpoolvote.vw_driver_matches
  where driver.status != 'Canceled'AND 
    driver."DriverCollectionZIP"::text = zip_codes.zip::text AND
    carpoolvote.vw_driver_matches.uuid_driver = carpoolvote.driver."UUID";

ALTER TABLE carpoolvote.vw_driver_matches_details
  OWNER TO carpool_admins;
GRANT ALL ON TABLE carpoolvote.vw_driver_matches_details TO carpool_admins;
GRANT SELECT ON TABLE carpoolvote.vw_driver_matches_details TO carpool_role;
GRANT SELECT ON TABLE carpoolvote.vw_driver_matches_details TO carpool_web;
GRANT SELECT ON TABLE carpoolvote.vw_driver_matches_details TO carpool_web_role;
