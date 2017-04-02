import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbname, username):
    return pgdb.connect(':' + dbname + ':' + username)

def test_insert_rider(pgdbConn):
    cursor=pgdbConn.cursor()

    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '12345',
        'RiderCollectionZIP' : '12345',
        'RiderDropOffZIP' : '',
        'AvailableRideTimesLocal' : '',
        'TotalPartySize' : '10',
        'TwoWayTripNeeded' : 'True',
        'RiderIsVulnerable' : 'True',
        'RiderWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'NeedWheelchair' : 'True',
        'RiderPreferredContact' : 'True',
        'RiderAccommodationNotes' : '',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'st the polls'
        }
    
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
    uuid=results[0]
    error_code=results[1]
    error_text=results[2]
    
    assert error_text=='', "error_text is not empty"
    assert uuid!='', "uuid is empty"
    assert error_code==0, "error_code is not 0"
    
    