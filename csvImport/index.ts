'use strict';

const csvParse = require('csv-parse');
const fs = require('fs');
const request = require('request');
const minimist = require('minimist');

const riderUrl = 'https://api.carpoolvote.com/live/rider';
const driverUrl = 'https://api.carpoolvote.com/live/driver';

// Callback callback{err, httpResponse}
function uploadCsv(postUrl, file, orgUuid, callback) {
  fs.readFile(file, function (err, fileData) {
    if (err) callback(err);

    const options = {
      columns: true,
      trim: true,
      skip_lines_with_error: false
    };

    csvParse(fileData, options, function (err, rows) {
      if (err) callback(err);

      rows.forEach(function (row) {
        console.log(row);
        const copy = Object.assign({}, row);
        copy.uuid_organization = orgUuid;

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

function uploadRiders(file, orgUuid, callback) {
  uploadCsv(riderUrl, file, orgUuid, function(err, httpResponse, body) {
    if (err) callback(err);

    const riderId = JSON.parse(httpResponse.body).out_uuid;
    console.log("Rider upload successful: " + riderId);
  });
}

function uploadDrivers(file, orgUuid, callback) {
  uploadCsv(driverUrl, file, orgUuid, function(err, httpResponse, body) {
    if (err) callback(err);

    const riderId = JSON.parse(httpResponse.body);
    console.log("Driver upload successful: " + JSON.stringify(httpResponse));
  });
}

var argv = minimist(process.argv.slice(2));
if (!argv.org_uuid || !(argv.ridersFile || argv.driversFile)) {
  console.error("Usage: --ridersFile=[csv file] --driversFile=[csv file] --org_uuid=[organization identifier]")
} else {
  if (argv.ridersFile) {
    uploadRiders(argv.ridersFile, argv.org_uuid, function(err, data) {
      if (err) console.log(err);
    });
  }

  if (argv.driversFile) {
    uploadDrivers(argv.driversFile, argv.org_uuid, function(err, data) {
      if (err) console.log(err);
    });
  }
}
