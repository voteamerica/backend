import pytest
import pgdb
from test_03_submit_driver import generic_driver_insert
from test_02_submit_rider import generic_rider_insert
                     
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
    

def getMatcherActivityStats(pgdbConnMatchEngine):
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.match_engine_activity_log")
    results=cursor.fetchone()
    return {'evaluated_pairs' : results[2], 'proposed_count' : results[3], 'error_count' : results[4], 'expired_count' : results[5]}

def getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver):
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.match WHERE uuid_rider=%(uuid_rider)s and uuid_driver=%(uuid_driver)s",
    {'uuid_rider':uuid_rider,'uuid_driver':uuid_driver})
    results=cursor.fetchone()
    return {'status' : results[0], 'score' : results[3]}

    
def test_match_001_nothing_to_match(pgdbConnAdmin, pgdbConnMatchEngine):
    cleanup(pgdbConnAdmin)
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.perform_match()")
    match_stats = getMatcherActivityStats(pgdbConnMatchEngine)
    assert match_stats['evaluated_pairs']==0
    assert match_stats['proposed_count']==0
    assert match_stats['error_count']==0
    assert match_stats['expired_count']==0
    pgdbConnMatchEngine.commit()
    
def test_match_002_perfect_match(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_driver})
    results = cursor.fetchone()
    assert results[0] == 'MatchProposed'
    
    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid_rider})
    results = cursor.fetchone()
    assert results[0] == 'MatchProposed'


def test_match_003_no_match_wheelchair(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'DriverCanLoadRiderWithWheelchair' : 'False',
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
    assert match_stats['evaluated_pairs']==0   # wheelchair criteria is applied first, no pair is evaluated
    assert match_stats['proposed_count']==0
    pgdbConnMatchEngine.commit()

def test_match_004_no_match_seatcount(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'TotalPartySize' : '5',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
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
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '4',
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
    assert match_stats['evaluated_pairs']==0
    assert match_stats['proposed_count']==0
    pgdbConnMatchEngine.commit()

def test_match_005_no_match_vulnerable(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'TotalPartySize' : '5',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
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
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '5',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['proposed_count']==0  
    pgdbConnMatchEngine.commit()

def test_match_006_no_match_time(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'TotalPartySize' : '5',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
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
        'AvailableDriveTimesLocal' : '2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '5',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['proposed_count']==0  
    pgdbConnMatchEngine.commit()

def test_match_007_match_upgraded_wheelchair_same_day(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'TotalPartySize' : '5',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
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
        'AvailableDriveTimesLocal' : '2018-10-01T18:00/2018-10-01T19:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '5',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    pgdbConnMatchEngine.commit()

def test_match_007_no_match_upgraded_wheelchair_different_day(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
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
        'TotalPartySize' : '5',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
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
        'AvailableDriveTimesLocal' : '2018-10-02T18:00/2018-10-02T19:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '5',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['proposed_count']==0
    pgdbConnMatchEngine.commit()

def test_match_008_no_match_disjoint_times(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    
    rider_args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T02:00|2018-10-01T03:00/2018-10-01T04:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
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
        'AvailableDriveTimesLocal' : '2018-10-01T02:01/2018-10-01T02:59',
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['evaluated_pairs']==2
    assert match_stats['proposed_count']==0
    pgdbConnMatchEngine.commit()
 
def test_match_009_match_disjoint_times(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    
    rider_args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T02:00|2018-10-01T03:00/2018-10-01T04:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
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
        'AvailableDriveTimesLocal' : '2018-10-01T02:01/2018-10-01T03:30|2018-10-02T02:01/2018-10-02T03:30',
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['evaluated_pairs']==4
    assert match_stats['proposed_count']==1
    pgdbConnMatchEngine.commit()

def test_match_010_match_distances(pgdbConnAdmin, pgdbConnMatchEngine, pgdbConnWeb):
    cleanup(pgdbConnAdmin)
    
    
    rider_args1 = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '20111',
        'RiderDropOffZIP' : '20111',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T18:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args1)
    uuid_rider1=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider1)>0

    rider_args2 = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '20112',
        'RiderDropOffZIP' : '20112',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T18:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args2)
    uuid_rider2=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider1)>0

    rider_args3 = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '20115',
        'RiderDropOffZIP' : '20115',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T18:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args3)
    uuid_rider3=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider3)>0

    rider_args4 = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'RiderFirstName',
        'RiderLastName' : 'RiderLastName',
        'RiderEmail' : 'rider@mail.com',
        'RiderPhone' : '555-555-5555',
        'RiderCollectionZIP' : '22401',
        'RiderDropOffZIP' : '22401',
        'AvailableRideTimesLocal' : '2018-10-01T01:00/2018-10-01T18:00',
        'TotalPartySize' : '1',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'False',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'False',
        'RiderPreferredContact' : 'Email',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }
    
    results = generic_rider_insert(pgdbConnWeb, rider_args4)
    uuid_rider4=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(uuid_rider3)>0
    
    
    driver_args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '20105',
        'DriverCollectionRadius' : '15',
        'AvailableDriveTimesLocal' : '2018-10-01T01:00/2018-10-01T18:00',
        'DriverCanLoadRiderWithWheelchair' : 'False',
        'SeatCount' : '1',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'DriverFirstName',
        'DriverLastName' : 'DriverLastName',
        'DriverEmail' : 'driver@mail.com',
        'DriverPhone' : '666-666-6666',
        'DrivingOnBehalfOfOrganization' : 'False',
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
    assert match_stats['evaluated_pairs']==3
    assert match_stats['proposed_count']==3
    pgdbConnMatchEngine.commit()

