"use strict";

import fs = require("fs");
import request = require("request");
import csvParsex = require("csv-parse");
import transform = require("stream-transform");
import rp = require("request-promise");
import minimist = require("minimist");
import { map as pMap } from "p-iteration";

const riderUrl = "http://localhost:8000/rider";
const driverUrl = "http://localhost:8000/driver";
// const riderUrl = 'https://api.carpoolvote.com/live/rider';
// const driverUrl = 'https://api.carpoolvote.com/live/driver';

// const postUrl = 'http://localhost:8000/rider';

// Callback callback{err, httpResponse}
// function uploadCsv(postUrl, file, orgUuid, isRider, callback) {
//   fs.readFile(file, function(err, fileData) {
//     if (err) {
//       return callback(err);
//     }

const inputErrors = [];

const addRow = async (postUrl, row, callback) => {
  console.log(row);
  const postOptions = {
    method: "POST",
    url: postUrl,
    rejectUnauthorized: false,
    form: row
  };
  // request.post(postOptions, function(err, httpResponse, body) {
  //   callback(err, httpResponse);
  // });
  // rp.post(postOptions)
  //   .then(httpResponse => {
  //     debugger;
  //     callback(null, httpResponse);
  //   })
  //   .catch(err => {
  //     debugger;
  //     callback(err);
  //   });

  try {
    debugger;
    // const httpResponse = await rp(postOptions);

    // const xxx = rp(postOptions);
    // debugger;
    // return xxx;

    const response = await rp.post(postOptions);

    debugger;

    // const r = JSON.parse(response);
    // rs.push(r);

    // return Promise.resolve(r.out_uuid);

    // callback(null, httpResponse);
    return response;
  } catch (error) {
    debugger;
    console.log("error", error);

    const inputErr = {
      error: error.message,
      type: "db input error",
      data: error.options.form
    };

    inputErrors.push(inputErr);

    return JSON.stringify(inputErr);
    // return Promise.reject(error);
  }
};

const createItem = (row, isRider, orgUuid) => {
  let copy = { ...row };

  debugger;

  // NOTE: node app is based around the form coming from html (rather than a
  // js function) to support the widest range of clients. So it expects a false
  // value to be signified by a property not being present, otherwise the value
  // is true. So any boolean property that is not true is removed.
  const removeFalseProp = (key, rowData) => {
    let newRow = {};

    const { [key]: field, ...oneTrip } = rowData;

    console.log("key", field);

    if (field && field.toUpperCase() !== "TRUE") {
      console.log("true");
      newRow = oneTrip;
    } else {
      console.log("false");
      newRow = rowData;
    }

    return newRow;
  };

  if (isRider === true) {
    copy = removeFalseProp("TwoWayTripNeeded", copy);
    copy = removeFalseProp("RiderIsVulnrable", copy);
    copy = removeFalseProp("RiderWillNotTalkPolitics", copy);
    copy = removeFalseProp("PleaseStayInTouch", copy);
    copy = removeFalseProp("NeedWheelchair", copy);
    copy = removeFalseProp("RiderLegalConsent", copy);
    copy = removeFalseProp("RiderWillBeSafe", copy);

    copy.RidingOnBehalfOfOrganization = true;
    copy.RidingOBOOrganizationName = orgUuid;

    console.log("rider", copy);
  } else {
    copy = removeFalseProp("DriverWillTakeCare", copy);
    copy = removeFalseProp("DriverCanLoadRiderWithWheelchair", copy);
    copy = removeFalseProp("DriverWillNotTalkPolitics", copy);
    copy = removeFalseProp("PleaseStayInTouch", copy);
    copy = removeFalseProp("RidersCanSeeDriverDetails", copy);
    copy = removeFalseProp("DriverWillTakeCare", copy);
    copy = removeFalseProp("RiderWillBeSafe", copy);

    copy.DrivingOnBehalfOfOrganization = true;
    copy.DrivingOBOOrganizationName = orgUuid;

    console.log("driver", copy);
  }

  return copy;
};

function uploadCsv(postUrl, itemsStream, orgUuid, isRider, callback) {
  const options = {
    columns: true,
    trim: true,
    skip_lines_with_error: false
  };

  const items = [];
  const newItems = [];

  let ridersCsv = false;
  let driversCsv = false;

  let headerLine = "";
  let parsingStarted = false;

  debugger;

  const csvParse = csvParsex(options);

  const transformer = transform(record => {
    console.log("rec:", record);
    items.push(record);

    if (parsingStarted === false) {
      if (record.RiderFirstName !== undefined) {
        parsingStarted = true;
        ridersCsv = true;
      } else if (record.DriverFirstName !== undefined) {
        parsingStarted = true;
        driversCsv = true;
      }
    }

    const newRecord = createItem(record, ridersCsv, orgUuid);

    debugger;
    newItems.push(newRecord);
    return newRecord;
  });

  itemsStream.pipe(csvParse).pipe(transformer);

  csvParse.on("error", function(err) {
    debugger;
    return callback({ error: err.message, type: "parse error" });
  });

  csvParse.on("end", async function() {
    debugger;
    console.log("new items:", newItems);

    const rows = newItems;
    const rs = [];

    // rows.forEach(async row => {
    // for await (const x of addRow(row)) {
    for (const row of rows) {
      const r = await addRow(postUrl, row, callback);

      debugger;
      const inputtedItem = JSON.parse(r);
      console.log(inputtedItem);

      if (inputtedItem.error === undefined) {
        debugger;
        rs.push(inputtedItem);
      }
    }
    // rows.forEach(
    // await Promise.all(rows.map(async row => addRow(row)));

    // const xs = pMap(rows, addRow);

    debugger;
    // console.log('x rows done:', xs);
    console.log("rows done:", rs);
    console.log("rows done:", rs.length);
    // });

    const replyDetailsLength = {
      recordsReceived: rows.length,
      uploadCount: rs.length
    };

    const errorOccurred = inputErrors.length > 0;
    const replyDetailsFull = errorOccurred
      ? {
          replyDetailsLength,
          inputErrorsCount: inputErrors.length,
          inputErrors
        }
      : replyDetailsLength;

    if (errorOccurred) {
      return callback(replyDetailsFull);
    } else {
      return callback(null, replyDetailsFull);
    }
    //         console.log('Read entire file.');

    //         debugger;

    //         reply({
    //           // id: result.$loki,
    //           // fileName: result.filename,
    //           // originalName: result.originalname
    //         });
  });

  // csvParse(fileData, options, async (err, rows) => {
  //   if (err) {
  //     console.log('parse error:', err);

  //     return callback(err);
  //   }

  //   const rs = [];

  //   // rows.forEach(async row => {
  //   //   for await
  //   // rows.forEach(
  // );
  // };
}

function uploadCsvX(postUrl, fileData, orgUuid, isRider, callback) {
  const options = {
    columns: true,
    trim: true,
    skip_lines_with_error: false
  };

  csvParse(fileData, options, async (err, rows) => {
    if (err) {
      console.log("parse error:", err);

      return callback(err);
    }

    const rs = [];

    // rows.forEach(async row => {
    //   for await
    // rows.forEach(
    const addRow = async row => {
      console.log(row);
      let copy = { ...row };

      // debugger;
      // const rs = [];

      // NOTE: node app is based around the form coming from html (rather than a
      // js function) to support the widest range of clients. So it expects a false
      // value to be signified by a property not being present, otherwise the value
      // is true. So any boolean property that is not true is removed.
      const removeFalseProp = (key, rowData) => {
        let newRow = {};

        const { [key]: tw, ...oneTrip } = rowData;

        console.log("key", tw);

        if (tw && tw.toUpperCase() !== "TRUE") {
          console.log("true");
          newRow = oneTrip;
        } else {
          console.log("false");
          newRow = rowData;
        }

        return newRow;
      };

      if (isRider === true) {
        copy = removeFalseProp("TwoWayTripNeeded", copy);
        copy = removeFalseProp("RiderIsVulnrable", copy);
        copy = removeFalseProp("RiderWillNotTalkPolitics", copy);
        copy = removeFalseProp("PleaseStayInTouch", copy);
        copy = removeFalseProp("NeedWheelchair", copy);
        copy = removeFalseProp("RiderLegalConsent", copy);
        copy = removeFalseProp("RiderWillBeSafe", copy);

        copy.RidingOnBehalfOfOrganization = true;
        copy.RidingOBOOrganizationName = orgUuid;

        console.log("rider", copy);
      } else {
        copy = removeFalseProp("DriverWillTakeCare", copy);
        copy = removeFalseProp("DriverCanLoadRiderWithWheelchair", copy);
        copy = removeFalseProp("DriverWillNotTalkPolitics", copy);
        copy = removeFalseProp("PleaseStayInTouch", copy);
        copy = removeFalseProp("RidersCanSeeDriverDetails", copy);
        copy = removeFalseProp("DriverWillTakeCare", copy);
        copy = removeFalseProp("RiderWillBeSafe", copy);

        copy.DrivingOnBehalfOfOrganization = true;
        copy.DrivingOBOOrganizationName = orgUuid;

        console.log("driver", copy);
      }

      const postOptions = {
        method: "POST",
        url: postUrl,
        rejectUnauthorized: false,
        form: copy
      };
      // request.post(postOptions, function(err, httpResponse, body) {
      //   callback(err, httpResponse);
      // });
      // rp.post(postOptions)
      //   .then(httpResponse => {
      //     debugger;
      //     callback(null, httpResponse);
      //   })
      //   .catch(err => {
      //     debugger;
      //     callback(err);
      //   });

      try {
        // debugger;
        // const httpResponse = await rp(postOptions);

        // const xxx = rp(postOptions);
        // debugger;
        // return xxx;

        const response = await rp.post(postOptions);

        debugger;

        // const r = JSON.parse(response);
        // rs.push(r);

        // return Promise.resolve(r.out_uuid);

        // callback(null, httpResponse);
        return response;
      } catch (error) {
        debugger;
        console.log("error", error);
        // callback(err);

        // return Promise.reject(error);
      }
    };
    // );
    // };

    // const rs = [];

    // rows.forEach(async row => {
    // for await (const x of addRow(row)) {
    // for (const row of rows) {
    //   const r = await addRow(row);

    //   debugger;
    //   console.log(r);

    //   rs.push(r);
    // }
    // rows.forEach(

    // await Promise.all(rows.map(async row => addRow(row)));

    const xs = pMap(rows, addRow);

    debugger;
    console.log("x rows done:", xs);
    console.log("rows done:", rs);
  });
}

const consoleLogResultMessage = entryId => {
  const message =
    entryId && entryId.length > 0
      ? "upload successful: " + entryId
      : "upload failed";

  return message;
};

function uploadRiders(fileData, orgUuid, callback) {
  uploadCsv(riderUrl, fileData, orgUuid, true, function(
    err,
    httpResponse,
    body
  ) {
    if (err) {
      return callback(err);
    }

    debugger;

    const riderInfo = JSON.parse(httpResponse);

    const riderId = riderInfo.out_uuid;
    console.log("Rider " + consoleLogResultMessage(riderId));
    console.log("Rider upload code: " + riderInfo.out_error_code);
    console.log("Rider upload text: " + riderInfo.out_error_text);

    callback(err, riderInfo);
  });
}

// function uploadDrivers(file, orgUuid, callback) {
//   uploadCsv(driverUrl, file, orgUuid, false, function(err, httpResponse, body) {
//     if (err) {
//       return callback(err);
//     }

//     const driverInfo = JSON.parse(httpResponse.body);

//     const driverId = driverInfo.out_uuid;
//     // console.log('Driver upload successful: ' + JSON.stringify(httpResponse));
//     console.log('Driver ' + consoleLogResultMessage(driverId));
//     console.log('Driver upload code: ' + driverInfo.out_error_code);
//     console.log('Driver upload text: ' + driverInfo.out_error_text);
//   });
// }

export { uploadRiders };

// node ./index.js --driversFile=./testing/drivers.csv --org_name=NAACP

// node ./index.js --ridersFile=./testing/riders.csv --org_name=NAACP

// DELETE FROM carpoolvote.rider
// WHERE rider."RiderLastName" = 'SAMPLE';

// DELETE FROM carpoolvote.driver
// WHERE driver."DriverLastName" = 'SAMPLE';
