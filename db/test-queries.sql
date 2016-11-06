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

select * from nov2016.match
inner join 
stage.websubmission_rider on stage.websubmission_rider."UUID" = nov2016.match.uuid_rider
 where uuid_driver = 'b57afc47-d97c-4c36-a078-6e68a0e9ef21' 
and nov2016.match.state = 'MatchProposed'

select * from nov2016.match
inner join 
stage.websubmission_rider on stage.websubmission_rider."UUID" = nov2016.match.uuid_rider
 where uuid_driver = 'b57afc47-d97c-4c36-a078-6e68a0e9ef21' 
and nov2016.match.state = 'MatchConfirmed'

select * from nov2016.vw_driver_matches;
select * from nov2016.vw_rider_matches;

select nov2016.driver_proposed_matches('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');
select nov2016.driver_confirmed_matches('99b36528-9043-4a19-aa62-0d446a4dd925', 'Test');

select nov2016.driver_confirmed_matches('2fcd0822-5fe7-4658-b92f-7056fa06feea', 'Test');
select nov2016.driver_proposed_matches('2fcd0822-5fe7-4658-b92f-7056fa06feea', 'Test');

select nov2016.rider_confirmed_match('8aa91abb-b7ee-4eb0-b901-0af3903b868e', 'Test');

select nov2016.driver_exists('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');
select nov2016.driver_info('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');

-- http://localhost:8000/driver-exists?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test
-- http://localhost:8000/driver-info?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test

-- http://localhost:8000/driver-proposed-matches?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test
-- http://localhost:8000/driver-confirmed-matches?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test

-- http://localhost:8000/driver-confirmed-matches?UUID=99b36528-9043-4a19-aa62-0d446a4dd925&DriverPhone=Test


http://localhost:8000/rider-exists?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test
http://localhost:8000/rider-info?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test

http://localhost:8000/rider-confirmed-match?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test
