var remoteUrl = "http://localhost:8000";

var testZipCode = 60001;
var testAreaCode = 246;
var testDriverAreaCode = 346;
var needWheelchair = true;


// will support fairly old browsers?
// 
// http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript

function getParameterByName(name, url) {
    if (!url) {
      url = window.location.href;
    }
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

var UUID_driver = getParameterByName('UUID_driver'); 
var UUID_rider = getParameterByName('UUID_rider'); 
var Score = getParameterByName('Score'); 
var DriverPhone = getParameterByName('DriverPhone'); 
var RiderPhone = getParameterByName('RiderPhone'); 

function getUnmatchedDriversTest () {
  var xhr = new XMLHttpRequest();

  xhr.open("GET", "http://localhost:8000/unmatched-drivers", true);

  xhr.onload = function (e) {
    if (xhr.readyState === 4) {

      if (xhr.status === 200) {
        var codes = JSON.parse(xhr.responseText);       
        console.log(xhr.responseText);

        codes.forEach(function (val) {
          var code = val;

          console.log(code);
        });
      } else {
        console.error(xhr.statusText);
      }
    }
  };

  xhr.onerror = function (e) {
    console.error(xhr.statusText);
  };

  xhr.send(null);
}

function cancelRideRequestTest() {
  var formData  = new FormData();
  // var url = remoteUrl + '/cancel-ride-request';
  var url = remoteUrl + '/cancel-ride-request?UUID=1e6e274d-ad33-4127-9f02-f35b48a07897&RiderPhone=123';
  var request = new XMLHttpRequest();

  // formData.append("UUID", "1e6e274d-ad33-4127-9f02-f35b48a07897");
  // formData.append("RiderPhone", '1');

  // request.open("POST", url);
  request.open("GET", url);
  request.send(formData);
}

function cancelRiderMatchTest() {
  var formData  = new FormData();
  var url = 
    remoteUrl + '/cancel-rider-match?' + 
    'UUID_driver=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&UUID_rider=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&Score=123' +
    '&RiderPhone=123';
  var request = new XMLHttpRequest();

  // formData.append("UUID", "1e6e274d-ad33-4127-9f02-f35b48a07897");
  // formData.append("RiderPhone", '1');

  // request.open("POST", url);
  request.open("GET", url);
  request.send(formData);
}

function cancelDriveOfferTest() {
  var url = 
    remoteUrl + '/cancel-drive-offer?' + 
    'UUID=' + UUID_driver +
    '&DriverPhone=' + DriverPhone;

  var request = new XMLHttpRequest();

  request.open("GET", url);
  request.send();
}

function cancelDriverMatchTest() {
  var formData  = new FormData();
  var url = 
    remoteUrl + '/cancel-driver-match?' + 
    'UUID_driver=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&UUID_rider=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&Score=123' +
    '&DriverPhone=123';
  var request = new XMLHttpRequest();

  // formData.append("UUID", "1e6e274d-ad33-4127-9f02-f35b48a07897");
  // formData.append("DriverPhone", '1');

  // request.open("POST", url);
  request.open("GET", url);
  request.send(formData);
}

function acceptDriverMatchTest() {
  var formData  = new FormData();
  var url = 
    remoteUrl + '/accept-driver-match?' + 
    'UUID_driver=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&UUID_rider=1e6e274d-ad33-4127-9f02-f35b48a07897' +
    '&Score=123' +
    '&DriverPhone=123';
  var request = new XMLHttpRequest();

  // formData.append("UUID", "1e6e274d-ad33-4127-9f02-f35b48a07897");
  // formData.append("DriverPhone", '1');

  // request.open("POST", url);
  request.open("GET", url);
  request.send(formData);
}
