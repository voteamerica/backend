import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbhost, dbname, username):
    return pgdb.connect(dbhost + ':' + dbname + ':' + username)

    
def generic_insert(conn, args):
    cursor=conn.cursor()
    cursor.execute("""
SELECT * from carpoolvote.submit_new_rider (
	%(IPAddress)s,
    %(RiderFirstName)s,
    %(RiderLastName)s,
    %(RiderEmail)s,
    %(RiderPhone)s,
    %(RiderCollectionZIP)s,
    %(RiderDropOffZIP)s,
    %(AvailableRideTimesLocal)s,
    %(TotalPartySize)s,
    %(TwoWayTripNeeded)s,
    %(RiderIsVulnerable)s,
    %(RiderWillNotTalkPolitics)s,
    %(PleaseStayInTouch)s,
    %(NeedWheelchair)s,
    %(RiderPreferredContact)s,
    %(RiderAccommodationNotes)s,
    %(RiderLegalConsent)s,
    %(RiderWillBeSafe)s,
    %(RiderCollectionAddress)s,
    %(RiderDestinationAddress)s
)
""", args)
    results=cursor.fetchone()
    conn.commit()
    return {'uuid' : results[0], 'error_code' : results[1], 'error_text' : results[2]}
   

def test_insert_rider_000_all_valid(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
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
    
    results = generic_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()

