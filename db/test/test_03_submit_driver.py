import pytest
import pgdb
                     
@pytest.fixture
def pgdbConn(dbhost, db, frontenduser):
    return pgdb.connect(dbhost + ':' + db + ':' + frontenduser)

      
def generic_driver_insert(conn, args):
    cursor=conn.cursor()
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
    conn.commit()
    return {'uuid' : results[0], 'error_code' : results[1], 'error_text' : results[2]}
    
def test_insert_driver_000_all_valid(pgdbConn):
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()
    
    cursor = pgdbConn.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.driver WHERE "UUID"=%(uuid)s """, {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 'Pending'

def test_insert_driver_001_IPAddress_invalid(pgdbConn):
    args = {
        'IPAddress' : 'abcd',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_002_DriverCollectionZIP_invalid_empty(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_driver_003_DriverCollectionZIP_invalid_not_exists(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '000000',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_004_DriverCollectionZIP_invalid_not_number(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : 'abcdefgh',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_005_DriverCollectionRadius_invalid_zero(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '0',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_006_DriverCollectionRadius_invalid_negative(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '-10',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()
    
def test_insert_driver_007_AvailableDriveTimesLocal_invalid_empty(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()
    
def test_insert_driver_008_AvailableDriveTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_009_AvailableDriveTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_010_AvailableDriveTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()
 
def test_insert_driver_011_AvailableDriveTimesLocal_invalid_chronology(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T03:00/2018-10-01T02:00',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_012_AvailableDriveTimesLocal_invalid_past(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2000-10-01T02:00/2000-10-01T03:00',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()


    

def test_insert_driver_013_SeatCount_invalid_zero(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '0',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()
    

def test_insert_driver_014_SeatCount_invalid_zero(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '0',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()

def test_insert_driver_015_DriverLicenseNumber_invalid_huge(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : 'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==-1
    assert len(uuid)==0
        
    pgdbConn.commit()
 
def test_insert_driver_016_DriverPreferredContact_valid_SMS(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : '',
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
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()
 
def test_insert_driver_017_DriverPreferredContact_valid_Email(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : '',
        'DriverLastName' : 'Doe',
        'DriverEmail' : 'john.doe@mail.com',
        'DriverPhone' : '555-555-5555',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'False',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Email',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()

def test_insert_driver_018_DriverPreferredContact_valid_Phone(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : '',
        'DriverLastName' : 'Doe',
        'DriverEmail' : 'john.doe@mail.com',
        'DriverPhone' : '555-555-5555',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'False',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Phone',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
        
    pgdbConn.commit()

def test_insert_driver_019_DriverPreferredContact_invalid(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'DriverCollectionZIP' : '90210',
        'DriverCollectionRadius' : '10',
        'AvailableDriveTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'DriverCanLoadRiderWithWheelchair' : 'True',
        'SeatCount' : '10',
        'DriverLicenseNumber' : '',
        'DriverFirstName' : '',
        'DriverLastName' : 'Doe',
        'DriverEmail' : 'john.doe@mail.com',
        'DriverPhone' : '555-555-5555',
        'DrivingOnBehalfOfOrganization' : 'True',
        'DrivingOBOOrganizationName' : 'Good Org',
        'RidersCanSeeDriverDetails' : 'False',
        'DriverWillNotTalkPolitics' : 'True',
        'PleaseStayInTouch' : 'True',
        'DriverPreferredContact' : 'Junk',
        'DriverWillTakeCare' : 'True'
        }
    
    results = generic_driver_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']
    
    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0
        
    pgdbConn.commit()
