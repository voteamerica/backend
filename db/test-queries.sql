-- select * from stage.websubmission_driver where "DriverLastName" LIKE 'Test%';
select body from nov2016.outgoing_sms where "created_ts" > '30 Oct 2016';

driver_cancel_confirmed_match

driver_cancel_drive_offer

driver_confirm_match

perform_match

queue_email_notif

!!
rider_cancel_confirmed_match

rider_cancel_ride_request

select nov2016.driver_exists('ccc4a38f-f6a8-47c1-a123-0be89dc3e960', 'Test');
select nov2016.rider_exists('c1e2cdb2-a8b7-4270-9d5c-f6e63ff9a856', 'Test');
select nov2016.rider_info('c1e2cdb2-a8b7-4270-9d5c-f6e63ff9a856', 'Test');
select nov2016.driver_info('ccc4a38f-f6a8-47c1-a123-0be89dc3e960', 'Test');
