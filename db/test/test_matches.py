import pytest
import pgdb
from test_submit_driver import generic_driver_insert
from test_submit_rider import generic_rider_insert
                     
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
    pgdbConnMatchEngine.rollback()
    
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
    
    
    cursor = pgdbConnMatchEngine.cursor()
    cursor.execute("SELECT * FROM carpoolvote.perform_match()")
    match_stats = getMatcherActivityStats(pgdbConnMatchEngine)
    assert match_stats['error_count']==0
    assert match_stats['expired_count']==0
    assert match_stats['evaluated_pairs']==1
    assert match_stats['proposed_count']==1

    
    match_record = getMatchRecord(pgdbConnMatchEngine, uuid_rider, uuid_driver)
    assert match_record['status'] == 'MatchProposed'
    
    pgdbConnMatchEngine.rollback()
    
