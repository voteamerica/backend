'use strict';

const csvParse = require('csv-parse');
const fs = require('fs');
const request = require('request');
const minimist = require('minimist');

// const riderUrl = 'http://localhost:8000/rider';
// const driverUrl = 'http://localhost:8000/driver';
const riderUrl = 'https://api.carpoolvote.com/live/rider';
const driverUrl = 'https://api.carpoolvote.com/live/driver';

// Callback callback{err, httpResponse}
function uploadCsv(postUrl, file, orgUuid, isRider, callback) {
  fs.readFile(file, function(err, fileData) {
    if (err) {
      return callback(err);
    }

    const options = {
      columns: true,
      trim: true,
      skip_lines_with_error: false
    };

    csvParse(fileData, options, function(err, rows) {
      if (err) {
        return callback(err);
      }

      rows.forEach(function(row) {
        console.log(row);
        let copy = { ...row };

        // NOTE: node app is based around the form coming from html (rather than a
        // js function) to support the widest range of clients. So it expects a false
        // value to be signified by a property not being present, otherwise the value
        // is true. So any boolean property that is not true is removed.
        const removeFalseProp = (key, rowData) => {
          let newRow = {};

          const { [key]: tw, ...oneTrip } = rowData;

          console.log('key', tw);

          if (tw && tw.toUpperCase() !== 'TRUE') {
            console.log('true');
            newRow = oneTrip;
          } else {
            console.log('false');
            newRow = rowData;
          }

          return newRow;
        };

        if (isRider === true) {
          copy = removeFalseProp('TwoWayTripNeeded', copy);
          copy = removeFalseProp('RiderIsVulnrable', copy);
          copy = removeFalseProp('RiderWillNotTalkPolitics', copy);
          copy = removeFalseProp('PleaseStayInTouch', copy);
          copy = removeFalseProp('NeedWheelchair', copy);
          copy = removeFalseProp('RiderLegalConsent', copy);
          copy = removeFalseProp('RiderWillBeSafe', copy);

          copy.RidingOnBehalfOfOrganization = true;
          copy.RidingOBOOrganizationName = orgUuid;

          console.log('rider', copy);
        } else {
          copy = removeFalseProp('DriverWillTakeCare', copy);
          copy = removeFalseProp('DriverCanLoadRiderWithWheelchair', copy);
          copy = removeFalseProp('DriverWillNotTalkPolitics', copy);
          copy = removeFalseProp('PleaseStayInTouch', copy);
          copy = removeFalseProp('RidersCanSeeDriverDetails', copy);
          copy = removeFalseProp('DriverWillTakeCare', copy);
          copy = removeFalseProp('RiderWillBeSafe', copy);

          copy.DrivingOnBehalfOfOrganization = true;
          copy.DrivingOBOOrganizationName = orgUuid;

          console.log('driver', copy);
        }

        const postOptions = {
          url: postUrl,
          rejectUnauthorized: false,
          form: copy
        };
        request.post(postOptions, function(err, httpResponse, body) {
          callback(err, httpResponse);
        });
      });
    });
  });
}

function consoleLogResultMessage(entryId) {
  const message =
    entryId && entryId.length > 0
      ? 'upload successful: ' + entryId
      : 'upload failed';

  return message;
}

function uploadRiders(file, orgUuid, callback) {
  uploadCsv(riderUrl, file, orgUuid, true, function(err, httpResponse, body) {
    if (err) {
      return callback(err);
    }

    const riderInfo = JSON.parse(httpResponse.body);

    const riderId = riderInfo.out_uuid;
    console.log('Rider ' + consoleLogResultMessage(riderId));
    console.log('Rider upload code: ' + riderInfo.out_error_code);
    console.log('Rider upload text: ' + riderInfo.out_error_text);
  });
}

function uploadDrivers(file, orgUuid, callback) {
  uploadCsv(driverUrl, file, orgUuid, false, function(err, httpResponse, body) {
    if (err) {
      return callback(err);
    }

    const driverInfo = JSON.parse(httpResponse.body);

    const driverId = driverInfo.out_uuid;
    // console.log('Driver upload successful: ' + JSON.stringify(httpResponse));
    console.log('Driver ' + consoleLogResultMessage(driverId));
    console.log('Driver upload code: ' + driverInfo.out_error_code);
    console.log('Driver upload text: ' + driverInfo.out_error_text);
  });
}

var argv = minimist(process.argv.slice(2));
if (!argv.org_name || !(argv.ridersFile || argv.driversFile)) {
  console.error(
    'Usage: --ridersFile=[csv file] --driversFile=[csv file] --org_name=[organization name]'
  );
} else {
  if (argv.ridersFile) {
    uploadRiders(argv.ridersFile, argv.org_name, function(err, data) {
      if (err) console.log(err);
    });
  }

  if (argv.driversFile) {
    uploadDrivers(argv.driversFile, argv.org_name, function(err, data) {
      if (err) console.log(err);
    });
  }
}

// node ./index.js --driversFile=./testing/drivers.csv --org_name=NAACP

// node ./index.js --ridersFile=./testing/riders.csv --org_name=NAACP

// DELETE FROM carpoolvote.rider
// WHERE rider."RiderLastName" = 'SAMPLE';

// DELETE FROM carpoolvote.driver
// WHERE driver."DriverLastName" = 'SAMPLE';
