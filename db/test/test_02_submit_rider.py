import pytest
import pgdb

@pytest.fixture
def pgdbConn(dbhost, db, frontenduser):
    return pgdb.connect(dbhost + ':' + db + ':' + frontenduser)


def generic_rider_insert(conn, args):
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0
    pgdbConn.commit()

    cursor = pgdbConn.cursor()
    cursor.execute("""SELECT status FROM carpoolvote.rider WHERE "UUID"=%(uuid)s """, {'uuid' : uuid})
    results = cursor.fetchone()
    assert results[0] == 'Pending'


def test_insert_rider_001_IPAddress_invalid(pgdbConn):
    args = {
        'IPAddress' : 'abcd',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_002_RiderCollectionZIP_invalid_empty(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_003_RiderCollectionZIP_invalid_not_exists(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '00000',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()


def test_insert_rider_004_RiderCollectionZIP_invalid_not_number(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : 'abcd',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_005_RiderDropOffZIP_invalid_empty(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_006_RiderDropOffZIP_invalid_not_found(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '00000',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_007_RiderDropOffZIP_invalid_not_number(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : 'abcd',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_008_AvailableRideTimesLocal_empty(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()


def test_insert_rider_009_AvailableRideTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()


def test_insert_rider_010_AvailableRideTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_011_AvailableRideTimesLocal_invalid_incomplete(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_012_AvailableRideTimesLocal_invalid_chronology(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T03:00/2018-10-01T02:00',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()


def test_insert_rider_013_AvailableRideTimesLocal_invalid_past(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2000-10-01T02:00/2000-10-01T03:00',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()




def test_insert_rider_014_TotalPartySize_invalid_zero(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'TotalPartySize' : '0',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()


def test_insert_rider_015_TotalPartySize_invalid_negative(pgdbConn):
    args = {
        'IPAddress' : '127.0.0.1',
        'RiderFirstName' : 'John',
        'RiderLastName' : 'Doe',
        'RiderEmail' : 'john.doe@gmail.com',
        'RiderPhone' : '555-555-555',
        'RiderCollectionZIP' : '90210',
        'RiderDropOffZIP' : '90210',
        'AvailableRideTimesLocal' : '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00',
        'TotalPartySize' : '-10',
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)>0
    assert error_code==2
    assert len(uuid)==0

    pgdbConn.commit()

def test_insert_rider_016_RiderPreferredContact_valid_SMS(pgdbConn):
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
        'RiderPreferredContact' : 'SMS',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0

    pgdbConn.commit()

def test_insert_rider_017_RiderPreferredContact_valid_Email(pgdbConn):
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

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0

    pgdbConn.commit()

def test_insert_rider_018_RiderPreferredContact_valid_Phone(pgdbConn):
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
        'RiderPreferredContact' : 'Phone',
        'RiderAccommodationNotes' : 'I am picky',
        'RiderLegalConsent' : 'True',
        'RiderWillBeSafe' : 'True',
        'RiderCollectionAddress' : 'at home',
        'RiderDestinationAddress' : 'at the polls'
        }

    results = generic_rider_insert(pgdbConn, args)
    uuid=results['uuid']
    error_code=results['error_code']
    error_text=results['error_text']

    assert len(error_text)==0
    assert error_code==0
    assert len(uuid)>0

    pgdbConn.commit()
