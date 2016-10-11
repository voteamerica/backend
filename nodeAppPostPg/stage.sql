CREATE FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) 
  RETURNS integer AS $$
DECLARE
    retVal integer := -1;
BEGIN
    RAISE NOTICE 'tstamp here is %', tstamp; 

    -- get timestamp of unprocessed riders 
    IF EXISTS (
      SELECT stage.websubmission_rider."UUID" 
      FROM stage.status_rider  
        INNER JOIN 
          stage.websubmission_rider 
        ON 
          (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
         
      WHERE 
        stage.websubmission_rider."UUID" = "rider_UUID"
    )
    THEN
      -- select MAX("CreatedTimeStamp") into tstamp from stage.status_rider;
      retVal := 1;      
    ELSE 
      RETURN retVal;
      -- tstamp := '2010-01-01';
    END IF;

    -- create intermediate table of timestamps, processed flag and riderId
    -- INSERT INTO 
    --   stage.status_rider ("CreatedTimeStamp")     
    -- SELECT 
    --   "CreatedTimeStamp" FROM stage.websubmission_rider 
    -- WHERE 
    --   "CreatedTimeStamp" > tstamp;

    -- create riders in nov2016 db
    -- only insert riders in intermediate tables, and with status == 1
    -- ?? timestamp to be creation of nov2016 row, or original submission ??
    -- INSERT INTO 
    --   nov2016.rider 
    --     (
    --     "RiderID", "Name", "Phone", "Email", "EmailValidated",
    --     "State", "City", "Notes", "DataEntryPoint", "VulnerablePopulation",
    --     "NeedsWheelChair", "Active"
    --     )     
    -- SELECT
    --   stage.status_rider."RiderID",
    --   concat_ws(' ', 
    --             stage.websubmission_rider."RiderFirstName"::text, 
    --             stage.websubmission_rider."RiderLastName"::text) 
    --   ,
    --   stage.websubmission_rider."RiderPhone",
    --   stage.websubmission_rider."RiderEmail",
    --   stage.websubmission_rider."RiderEmailValidated"::int::bit,

    --   stage.websubmission_rider."RiderVotingState",
    --   'city?',
    --   'notes?',
    --   'entry?',
    --   stage.websubmission_rider."RiderIsVulnerable"::int::bit,

    --   stage.websubmission_rider."NeedWheelchair"::int::bit,
    --   true::int::bit
    -- FROM 
    --   stage.websubmission_rider
    -- INNER JOIN 
    --   stage.status_rider 
    -- ON 
    --   (stage.websubmission_rider."CreatedTimeStamp" = stage.status_rider."CreatedTimeStamp") 
    -- WHERE 
    --       stage.websubmission_rider."CreatedTimeStamp" > tstamp 
    --   AND stage.status_rider.status = 1;
    
    -- UPDATE 
    --   stage.status_rider
    -- SET
    --   status = 100
    -- WHERE
    --       stage.status_rider."CreatedTimeStamp" > tstamp 
    --   AND stage.status_rider.status = 1;

    -- RAISE EXCEPTION 'Nonexistent ID --> %', user_id
    --   USING HINT = 'Please check your user ID';

    RETURN retVal;
END;
$$ LANGUAGE plpgsql;

GRANT ALL ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_admins;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_web_role;
GRANT EXECUTE ON FUNCTION stage.cancel_ride("rider_UUID" character varying(50)) TO carpool_role;

