import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbhost, dbname, username):
    return pgdb.connect(dbhost + ':' + dbname + ':' + username)

def test_insert_rider(pgdbConn):
    cursor=pgdbConn.cursor()

    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : 'John',
        'DriverLastName' : 'Doe',
        'DriverEmail' : 'john.doe@mail.com',
        'DriverPhone' : '555-555-5555',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'False',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'SMS',
        'DriverWillTakeCare' : 'True'
        }
    
    cursor.execute("""
SELECT * from carpoolvote.submit_new_driver (
	%(IPAddress)s,
	%(DriverCollectionZIP)s,
	%(DriverCollectionRadius)s,
	%(AvailableDriveTimesLocal)s,
	%(DriverCanLoadRiderWithWheelchair)s,
	%(SeatCount)s,
	%(DriverLicenseNumber)s,
	%(DriverFirstName)s,
	%(DriverLastName)s,
	%(DriverEmail)s,
	%(DriverPhone)s,
	%(DrivingOnBehalfOfOrganization)s,
	%(DrivingOBOOrganizationName)s,
	%(RidersCanSeeDriverDetails)s,
	%(DriverWillNotTalkPolitics)s,
	%(PleaseStayInTouch)s,
	%(DriverPreferredContact)s,
	%(DriverWillTakeCare)s
)
""", args)
    results=cursor.fetchone()
    uuid=results[0]
    error_code=results[1]
    error_text=results[2]
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()
