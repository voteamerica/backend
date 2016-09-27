var remoteUrl = "http://localhost:8000";

function sendDriverForm() {
  var formData  = new FormData();
  var url = remoteUrl + '/driver';

  formData.append("IPAddress", "0.0.0.1");
  formData.append("DriverCollectionZIP", 60004); 
  formData.append("DriverCollectionRadius", 21); 
  formData.append("AvailableDriveTimesJSON", "after 11 am"); 

  formData.append("DriverCanLoadRiderWithWheelchair", false); 
  formData.append("SeatCount", 3);
  formData.append("DriverHasInsurance", true); 
  formData.append("DriverInsuranceProviderName", "ill. ins"); 
  formData.append("DriverInsurancePolicyNumber", 1234);

  formData.append("DriverLicenseState", 'MO');
  formData.append("DriverLicenseNumber", '5678');
  formData.append("DriverFirstName", 'jim');
  formData.append("DriverLastName", 'nilsen');
  formData.append("PermissionCanRunBackgroundCheck", true);

  formData.append("DriverEmail", 'jn@t.com');
  formData.append("DriverPhone", '246');
  formData.append("DriverAreaCode", 123);
  formData.append("DriverEmailValidated", false);              
  formData.append("DriverPhoneValidated", true);

  formData.append("DrivingOnBehalfOfOrganization", false); 
  formData.append("DrivingOBOOrganizationName", 'none');
  formData.append("RidersCanSeeDriverDetails", false);
  formData.append("DriverWillNotTalkPolitics", true);
  formData.append("ReadyToMatch", false);

  formData.append("PleaseStayInTouch", true);

  var request = new XMLHttpRequest();

  request.open("POST", url);
  request.send(formData);
}

function sendRiderForm() {
  var formData  = new FormData();
  var url = remoteUrl + '/rider';

  formData.append("IPAddress", "0.0.0.3");
  formData.append("RiderFirstName", 'jim');
  formData.append("RiderLastName", 'nilsen');
  formData.append("RiderEmail", 'jn@t.com');

  formData.append("RiderPhone", '246');
  formData.append("RiderAreaCode", 123);
  formData.append("RiderEmailValidated", false);
  formData.append("RiderPhoneValidated", true);
  formData.append("RiderVotingState", 'MO');

  formData.append("RiderCollectionZIP", 60004); 
  formData.append("RiderDropOffZIP", 60004); 
  formData.append("AvailableRideTimesJSON", "after 11 am");
  formData.append("WheelchairCount", 2);
  formData.append("NonWheelchairCount", 1);

  formData.append("TotalPartySize", 4);
  formData.append("TwoWayTripNeeded", false);
  formData.append("RiderPreferredContactMethod", 1);
  formData.append("RiderIsVulnerable", false);
  formData.append("DriverCanContactRider", true);

  formData.append("RiderWillNotTalkPolitics", true);
  formData.append("ReadyToMatch", false);
  formData.append("PleaseStayInTouch", true);

  var request = new XMLHttpRequest();

  request.open("POST", url);
  request.send(formData);
}
