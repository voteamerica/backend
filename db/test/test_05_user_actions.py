import pytest
import pgdb
from test_02_submit_rider import generic_rider_insert
from test_03_submit_driver import generic_driver_insert
from test_04_matches import getMatcherActivityStats, getMatchRecord
                     
@pytest.fixture
def pgdbConnMatchEngine(dbhost, db, matchengineuser):
    return pgdb.connect(dbhost + ':' + db + ':' + matchengineuser)

@pytest.fixture
def pgdbConnAdmin(dbhost, db, adminuser):
    return pgdb.connect(dbhost + ':' + db + ':' + adminuser)

@pytest.fixture
def pgdbConnWeb(dbhost, db, frontenduser):
    return pgdb.connect(dbhost + ':' + db + ':' + frontenduser)

    
def cleanup(pgdbConnAdmin):
    cursor=pgdbConnAdmin.cursor()
    
    cursor.execute("DELETE FROM carpoolvote.match")
    cursor.execute("DELETE FROM carpoolvote.match_engine_activity_log")
    cursor.execute("DELETE FROM carpoolvote.outgoing_email")
    cursor.execute("DELETE FROM carpoolvote.outgoing_sms")
    cursor.execute("DELETE FROM carpoolvote.rider")
    cursor.execute("DELETE FROM carpoolvote.driver")
    cursor.execute("DELETE FROM carpoolvote.helper")
    pgdbConnAdmin.commit()
    
def test_user_actions_001_driver_cancels_drive_offer_input_val(pgdbConnAdmin, pgdbConnWeb):
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_drive_offer(%(uuid)s, %(confparam)s)",
    {'uuid' : '12345', 'confparam' : '12346'})
    results = cursor.fetchone()
    assert results[0] == 2
    assert len(results[1]) > 0
    
def test_user_actions_002_driver_cancels_drive_offer_email_only(pgdbConnAdmin, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    # 1. insert drive offer
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConnWeb, driver_args)
    uuid_driver=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver)>0
    
    pgdbConnWeb.commit()

    # 2. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 1
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 0
    
    
    # 3. Cancel it
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_drive_offer(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid_driver, 'confparam' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
    
    # 4. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.driver where "UUID"=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
    
    # 5. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 2
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 0
    
    # 6. Cancel it again
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_drive_offer(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid_driver, 'confparam' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    
    # 7. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.driver where "UUID"=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'    
    
def test_user_actions_003_driver_cancels_drive_offer_email_sms(pgdbConnAdmin, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    # 1. insert drive offer
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'SMS',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConnWeb, driver_args)
    uuid_driver=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver)>0
    
    pgdbConnWeb.commit()

    # 2. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 1
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 1
    
    
    # 3. Cancel it
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_drive_offer(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid_driver, 'confparam' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    # 4. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.driver where "UUID"=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
    
    # 5. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 2
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 2
    
    
def test_user_actions_004_rider_cancels_ride_request_input_val(pgdbConnAdmin, pgdbConnWeb):    
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.rider_cancel_ride_request(%(uuid)s, %(confparam)s)",
    {'uuid' : '12345', 'confparam' : '12346'})
    results = cursor.fetchone()
    assert results[0] == 2
    assert len(results[1]) > 0

    
def test_user_actions_005_rider_cancels_ride_request_email_only(pgdbConnAdmin, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    # 1. insert ride request
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'TotalPartySize' : '10',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConnWeb.commit()

    # 2. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 1
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 0
    
    
    # 3. Cancel it
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.rider_cancel_ride_request(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid, 'confparam' : args['RiderLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    
    # 4. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.rider where "UUID"=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
    
    # 5. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 2
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 0
    
    # 6. Cancel it again
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.rider_cancel_ride_request(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid, 'confparam' : args['RiderLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    
    # 7. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.rider where "UUID"=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
    
    
def test_user_actions_006_rider_cancels_ride_request_email_sms(pgdbConnAdmin, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    # 1. insert ride request
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'TotalPartySize' : '10',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'SMS',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConnWeb.commit()

    # 2. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 1
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 1
    
    
    # 3. Cancel it
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.rider_cancel_ride_request(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid, 'confparam' : args['RiderLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    
    # 4. check the status
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.rider where "UUID"=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
    
    # 5. Check the number of email and sms notification
    cursor = pgdbConnAdmin.cursor()
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_email WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 2
    
    cursor.execute("""SELECT COUNT(*) FROM carpoolvote.outgoing_sms WHERE uuid=%(uuid)s """,
    {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 2
    
def test_user_actions_007_driver_confirm_match(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    rider_args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args)
    uuid_rider=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider)>0
        
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConnWeb, driver_args)
    uuid_driver=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver)>0
    
    pgdbConnWeb.commit()
    
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.perform_match()")
    match_stats = getMatcherActivityStats(pgdbConnMatchEngine)
    assert match_stats['error_count']==0
    assert match_stats['expired_count']==0
    assert match_stats['evaluated_pairs']==1
    assert match_stats['proposed_count']==1

    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchProposed'   
    pgdbConnMatchEngine.commit()
    
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
 
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'   
    pgdbConnMatchEngine.commit()
    
    cursor = pgdbConnWeb.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'
    
    # Cannot match an already matched record
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1])> 0
    assert results[0] == 2
    
    
    
def test_user_actions_008_driver_cancels_confirmed_match(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    rider_args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    rider_args2 = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName2',
        'RiderLastName' : 'RiderLastName2',
        'RiderEmail' : 'rider2@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    
    results = generic_rider_insert(pgdbConnWeb, rider_args)
    uuid_rider=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider)>0
        
    results = generic_rider_insert(pgdbConnWeb, rider_args2)
    uuid_rider2=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider2)>0
    
        
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }

    driver_args2 = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName2',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }
        
    results = generic_driver_insert(pgdbConnWeb, driver_args)
    uuid_driver=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver)>0

    results = generic_driver_insert(pgdbConnWeb, driver_args2)
    uuid_driver2=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver2)>0
    
    pgdbConnWeb.commit()
    
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.perform_match()")
    match_stats = getMatcherActivityStats(pgdbConnMatchEngine)
    assert match_stats['error_count']==0
    assert match_stats['expired_count']==0
    assert match_stats['evaluated_pairs']==4
    assert match_stats['proposed_count']==4
    pgdbConnMatchEngine.commit()
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchProposed'   
        
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()

    # Match is confirmed.    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'  
        
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
   
    # Cannot confirm and already confirmed match
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1])> 0
    assert results[0] == 2
    pgdbConnWeb.commit()
    
    # A 2nd Driver is not able to confirm an already confirmed ride request
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver2, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args2['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) > 0
    assert results[0] == 2
    pgdbConnWeb.commit()

    # Same driver confirms 2nd rider
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider2, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
    
    # Match is confirmed (driver has 2 confirmed matches)  
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'  
        
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver2})
    results = cursor.fetchone()
    assert results[0] == 'MatchProposed'
      
    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider2})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'
    
    
    # Now driver cancels one match
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_confirmed_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider2, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver)
    assert match_record['status'] == 'Canceled'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver2)
    assert match_record['status'] == 'MatchProposed'   
    
  
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver2})
    results = cursor.fetchone()
    assert results[0] == 'MatchProposed'
      
    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider2})
    results = cursor.fetchone()
    assert results[0] == 'MatchProposed'
    
    
    # Driver2 cancels 
    cursor.execute("SELECT * FROM carpoolvote.driver_cancel_drive_offer(%(uuid)s, %(confparam)s)",
    {'uuid' : uuid_driver2, 'confparam' : driver_args2['DriverPhone']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
    
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver2)
    assert match_record['status'] == 'Canceled'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver)
    assert match_record['status'] == 'Canceled'   
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider2, uuid_driver2)
    assert match_record['status'] == 'Canceled'   
    
    
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver2})
    results = cursor.fetchone()
    assert results[0] == 'Canceled'
      
    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider})
    results = cursor.fetchone()
    assert results[0] == 'MatchConfirmed'

    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider2})
    results = cursor.fetchone()
    assert results[0] == 'Pending'
    
    
    
def test_user_actions_009_rider_cancels_confirmed_match(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    rider_args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args)
    uuid_rider=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider)>0
        
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'True',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConnWeb, driver_args)
    uuid_driver=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_driver)>0
    
    pgdbConnWeb.commit()
    
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.perform_match()")
    match_stats = getMatcherActivityStats(pgdbConnMatchEngine)
    assert match_stats['error_count']==0
    assert match_stats['expired_count']==0
    assert match_stats['evaluated_pairs']==1
    assert match_stats['proposed_count']==1

    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchProposed'   
    pgdbConnMatchEngine.commit()
    
    cursor = pgdbConnWeb.cursor()
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
 
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchConfirmed'   
    pgdbConnMatchEngine.commit()
    
    # Cannot match an already matched record
    cursor.execute("SELECT * FROM carpoolvote.driver_confirm_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : driver_args['DriverLastName']})
    results = cursor.fetchone()
    assert len(results[1])> 0
    assert results[0] == 2
    pgdbConnWeb.commit()
    
    # Match is confirmed.
    
    # Now driver cancels the match
    cursor.execute("SELECT * FROM carpoolvote.rider_cancel_confirmed_match(%(uuid_driver)s, %(uuid_rider)s, %(score)s::smallint, %(confirm)s)", 
    {'uuid_driver' : uuid_driver, 'uuid_rider' : uuid_rider, 'score' : match_record['score'], 'confirm' : rider_args['RiderLastName']})
    results = cursor.fetchone()
    assert len(results[1]) == 0
    assert results[0] == 0
    pgdbConnWeb.commit()
    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'Canceled'   
    pgdbConnMatchEngine.commit()