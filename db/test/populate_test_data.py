from urllib.parse import urlencode
from urllib.request import Request, urlopen
import csv

# This will HTTP POST to the node.js app

# PORT 3000 is used by node.js app connected to carpool DB.
# For testing purposes, setup your own node.js in your home directory and use a different port
BASE_URL = 'http://127.0.0.1:2000'

driverValues = {'IPAddress' : '0.0.0.0',
      'DriverCollectionZIP' : 0,
      'DriverCollectionRadius' : 0,
      'AvailableDriveTimesJSON' : [],
      'DriverCanLoadRiderWithWheelchair' : False,
      'SeatCount' : 0,
      'DriverHasInsurance' : True,
      'DriverInsuranceProviderName' : 'AllInsurance',
      'DriverInsurancePolicyNumber' : '1234567890',
      'DriverLicenseState' : 'MO',
      'DriverLicenseNumber' : '5678',
      'DriverFirstName' : 'FIRST',
      'DriverLastName' : 'DRIVER',
      'PermissionCanRunBackgroundCheck' : True,
      'DriverEmail' : 'driver@email.com',
      'DriverPhone' : '555-555-5555',
      'DriverAreaCode' : 555,
      'DriverEmailValidated' : False,
      'DriverPhoneValidated' : True,
      'DrivingOnBehalfOfOrganization' : False,
      'DrivingOBOOrganizationName' : 'none',
      'RidersCanSeeDriverDetails' : False,
      'DriverWillNotTalkPolitics' : True,
      'ReadyToMatch' : False,
      'PleaseStayInTouch' : True
      }

url = BASE_URL + '/driver'
with open('carpool_test_databank_driver.csv', newline='\n') as csvfile:
    driver_reader = csv.reader(csvfile, delimiter=',')
    row_idx = 0
    for row in driver_reader:
        if row_idx > 0:
            driverValues['DriverLastName']=row[0]
            driverValues['DriverCollectionZIP']=row[1]
            driverValues['DriverCollectionRadius']=row[2]
            driverValues['SeatCount']=row[3]
            if row[4] == 'T':
                driverValues['DriverCanLoadRiderWithWheelchair']=True
            else:
                driverValues['DriverCanLoadRiderWithWheelchair']=False
            ride_times = row[5].split('|')
            driverValues['AvailableDriveTimesJSON'] = []
            for a_time in ride_times:
                driverValues['AvailableDriveTimesJSON'].append(a_time)

            data = urlencode(driverValues).encode("utf-8")
            req = Request(url, data)
            response = urlopen(req)
            the_page = response.read().decode("utf-8")
            print (the_page)
        row_idx += 1


riderValues = {'IPAddress' : '0.0.0.0',
      'RiderFirstName' : 'FIRST',
      'RiderLastName' : 'RIDER',
      'RiderEmail' : 'rider@email.com',
      'RiderPhone' : '555-555-5555',
      'RiderAreaCode' : 555,
      'RiderEmailValidated' : False,
      'RiderPhoneValidated' : True,
      'RiderVotingState' : 'DC',
      'RiderCollectionZIP' : 0,
      'RiderDropOffZIP' : 0,
      'AvailableRideTimesJSON' : [],
      'NeedWheelchair' : False,
      'TotalPartySize' : 0,
      'TwoWayTripNeeded' : False,
      'RiderPreferredContactMethod' : 0,
      'RiderIsVulnerable' : False,
      'DriverCanContactRider' : False,
      'RiderWillNotTalkPolitics' : True,      
      'ReadyToMatch' : False,
      'PleaseStayInTouch' : True
      }


url = BASE_URL + '/rider'
with open('carpool_test_databank_rider.csv', newline='\n') as csvfile:
    rider_reader = csv.reader(csvfile, delimiter=',')
    row_idx = 0
    for row in rider_reader:
        if row_idx > 0:
            riderValues['RiderLastName']=row[0]
            riderValues['RiderCollectionZIP']=row[1]
            riderValues['RiderDropOffZIP']=row[2]
            riderValues['TotalPartySize']=row[3]
            if row[4] == 'T':
                riderValues['NeedWheelchair']=True
            else:
                riderValues['NeedWheelchair']=False
            ride_times = row[5].split('|')
            riderValues['AvailableRideTimesJSON'] = []
            for a_time in ride_times:
                riderValues['AvailableRideTimesJSON'].append(a_time)

            data = urlencode(riderValues).encode("utf-8")
            req = Request(url, data)
            response = urlopen(req)
            the_page = response.read().decode("utf-8")
            print (the_page)
        row_idx += 1


