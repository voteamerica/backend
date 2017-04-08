-- select * from carpoolvote.driver where "DriverLastName" LIKE 'Test%';
select body from carpoolvote.outgoing_sms where "created_ts" > '30 Oct 2016';

driver_cancel_confirmed_match

driver_cancel_drive_offer

driver_confirm_match

perform_match

queue_email_notif

!!
rider_cancel_confirmed_match

rider_cancel_ride_request

select carpoolvote.driver_exists('ccc4a38f-f6a8-47c1-a123-0be89dc3e960', 'Test');
select carpoolvote.rider_exists('c1e2cdb2-a8b7-4270-9d5c-f6e63ff9a856', 'Test');
select carpoolvote.rider_info('c1e2cdb2-a8b7-4270-9d5c-f6e63ff9a856', 'Test');
select carpoolvote.driver_info('ccc4a38f-f6a8-47c1-a123-0be89dc3e960', 'Test');

select * from carpoolvote.match
inner join 
carpoolvote.rider on carpoolvote.rider."UUID" = carpoolvote.match.uuid_rider
 where uuid_driver = 'b57afc47-d97c-4c36-a078-6e68a0e9ef21' 
and carpoolvote.match.state = 'MatchProposed'

select * from carpoolvote.match
inner join 
carpoolvote.rider on carpoolvote.rider."UUID" = carpoolvote.match.uuid_rider
 where uuid_driver = 'b57afc47-d97c-4c36-a078-6e68a0e9ef21' 
and carpoolvote.match.state = 'MatchConfirmed'

select * from carpoolvote.vw_driver_matches;
select * from carpoolvote.vw_rider_matches;

select carpoolvote.driver_proposed_matches('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');
select carpoolvote.driver_confirmed_matches('99b36528-9043-4a19-aa62-0d446a4dd925', 'Test');

select carpoolvote.driver_confirmed_matches('2fcd0822-5fe7-4658-b92f-7056fa06feea', 'Test');
select carpoolvote.driver_proposed_matches('2fcd0822-5fe7-4658-b92f-7056fa06feea', 'Test');

select carpoolvote.rider_confirmed_match('8aa91abb-b7ee-4eb0-b901-0af3903b868e', 'Test');

select carpoolvote.driver_exists('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');
select carpoolvote.driver_info('32e5cbd4-1342-4e1e-9076-0147e779a796', 'Test');

-- http://localhost:8000/driver-exists?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test
-- http://localhost:8000/driver-info?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test

-- http://localhost:8000/driver-proposed-matches?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test
-- http://localhost:8000/driver-proposed-matches?UUID=b3c4dba0-8e71-4960-92fa-8aab43ed2275&DriverPhone=+447958110786

-- http://localhost:8000/driver-confirmed-matches?UUID=32e5cbd4-1342-4e1e-9076-0147e779a796&DriverPhone=Test

-- http://localhost:8000/driver-confirmed-matches?UUID=99b36528-9043-4a19-aa62-0d446a4dd925&DriverPhone=Test


http://localhost:8000/rider-exists?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test
http://localhost:8000/rider-info?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test

http://localhost:8000/rider-confirmed-match?UUID=8aa91abb-b7ee-4eb0-b901-0af3903b868e&RiderPhone=Test

http://192.168.99.1:8080/self-service/?type=driver&uuid=99b36528-9043-4a19-aa62-0d446a4dd925

http://192.168.99.1:8080/self-service/?type=rider&uuid=8aa91abb-b7ee-4eb0-b901-0af3903b868e

