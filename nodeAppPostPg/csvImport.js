"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) if (e.indexOf(p[i]) < 0)
            t[p[i]] = s[p[i]];
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
const csvParsex = require("csv-parse");
const transform = require("stream-transform");
const rp = require("request-promise");
const p_iteration_1 = require("p-iteration");
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
function uploadCsv(postUrl, itemsStream, orgUuid, isRider, callback) {
    const options = {
        columns: true,
        trim: true,
        skip_lines_with_error: false
    };
    const items = [];
    const newItems = [];
    debugger;
    const csvParse = csvParsex(options);
    const transformer = transform(record => {
        console.log("rec:", record);
        debugger;
        newItems.push(record);
        return record;
    });
    // transformer.on("readable", () => {
    //   let row = {};
    //   debugger;
    //   while ((row = transformer.read())) {
    //     console.log("t row", row);
    //     newItems.push(row);
    //   }
    // });
    itemsStream.pipe(csvParse).pipe(transformer);
    // csvParse.on("readable", function() {
    //   let record = {};
    //   debugger;
    //   while ((record = csvParse.read())) {
    //     items.push(record);
    //   }
    // });
    csvParse.on("error", function (err) {
        debugger;
        return callback(err);
    });
    csvParse.on("end", function () {
        debugger;
        console.log("new items:", newItems);
        return callback(null, items);
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
    //   const addRow = async row => {
    //     console.log(row);
    //     let copy = { ...row };
    //     // debugger;
    //     // const rs = [];
    //     // NOTE: node app is based around the form coming from html (rather than a
    //     // js function) to support the widest range of clients. So it expects a false
    //     // value to be signified by a property not being present, otherwise the value
    //     // is true. So any boolean property that is not true is removed.
    //     const removeFalseProp = (key, rowData) => {
    //       let newRow = {};
    //       const { [key]: tw, ...oneTrip } = rowData;
    //       console.log('key', tw);
    //       if (tw && tw.toUpperCase() !== 'TRUE') {
    //         console.log('true');
    //         newRow = oneTrip;
    //       } else {
    //         console.log('false');
    //         newRow = rowData;
    //       }
    //       return newRow;
    //     };
    //     if (isRider === true) {
    //       copy = removeFalseProp('TwoWayTripNeeded', copy);
    //       copy = removeFalseProp('RiderIsVulnrable', copy);
    //       copy = removeFalseProp('RiderWillNotTalkPolitics', copy);
    //       copy = removeFalseProp('PleaseStayInTouch', copy);
    //       copy = removeFalseProp('NeedWheelchair', copy);
    //       copy = removeFalseProp('RiderLegalConsent', copy);
    //       copy = removeFalseProp('RiderWillBeSafe', copy);
    //       copy.RidingOnBehalfOfOrganization = true;
    //       copy.RidingOBOOrganizationName = orgUuid;
    //       console.log('rider', copy);
    //     } else {
    //       copy = removeFalseProp('DriverWillTakeCare', copy);
    //       copy = removeFalseProp('DriverCanLoadRiderWithWheelchair', copy);
    //       copy = removeFalseProp('DriverWillNotTalkPolitics', copy);
    //       copy = removeFalseProp('PleaseStayInTouch', copy);
    //       copy = removeFalseProp('RidersCanSeeDriverDetails', copy);
    //       copy = removeFalseProp('DriverWillTakeCare', copy);
    //       copy = removeFalseProp('RiderWillBeSafe', copy);
    //       copy.DrivingOnBehalfOfOrganization = true;
    //       copy.DrivingOBOOrganizationName = orgUuid;
    //       console.log('driver', copy);
    //     }
    //     const postOptions = {
    //       method: 'POST',
    //       url: postUrl,
    //       rejectUnauthorized: false,
    //       form: copy
    //     };
    //     // request.post(postOptions, function(err, httpResponse, body) {
    //     //   callback(err, httpResponse);
    //     // });
    //     // rp.post(postOptions)
    //     //   .then(httpResponse => {
    //     //     debugger;
    //     //     callback(null, httpResponse);
    //     //   })
    //     //   .catch(err => {
    //     //     debugger;
    //     //     callback(err);
    //     //   });
    //     try {
    //       // debugger;
    //       // const httpResponse = await rp(postOptions);
    //       // const xxx = rp(postOptions);
    //       // debugger;
    //       // return xxx;
    //       const response = await rp.post(postOptions);
    //       debugger;
    //       // const r = JSON.parse(response);
    //       // rs.push(r);
    //       // return Promise.resolve(r.out_uuid);
    //       // callback(null, httpResponse);
    //       return response;
    //     } catch (error) {
    //       debugger;
    //       console.log('error', error);
    //       // callback(err);
    //       // return Promise.reject(error);
    //     }
    //   };
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
    //   const xs = pMap(rows, addRow);
    //   debugger;
    //   console.log('x rows done:', xs);
    //   console.log('rows done:', rs);
    // });
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
        const addRow = async (row) => {
            console.log(row);
            let copy = Object.assign({}, row);
            // debugger;
            // const rs = [];
            // NOTE: node app is based around the form coming from html (rather than a
            // js function) to support the widest range of clients. So it expects a false
            // value to be signified by a property not being present, otherwise the value
            // is true. So any boolean property that is not true is removed.
            const removeFalseProp = (key, rowData) => {
                let newRow = {};
                const _a = key, tw = rowData[_a], oneTrip = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
                console.log("key", tw);
                if (tw && tw.toUpperCase() !== "TRUE") {
                    console.log("true");
                    newRow = oneTrip;
                }
                else {
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
            }
            else {
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
            }
            catch (error) {
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
        const xs = p_iteration_1.map(rows, addRow);
        debugger;
        console.log("x rows done:", xs);
        console.log("rows done:", rs);
    });
}
const consoleLogResultMessage = entryId => {
    const message = entryId && entryId.length > 0
        ? "upload successful: " + entryId
        : "upload failed";
    return message;
};
function uploadRiders(fileData, orgUuid, callback) {
    uploadCsv(riderUrl, fileData, orgUuid, true, function (err, httpResponse, body) {
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
exports.uploadRiders = uploadRiders;
//# sourceMappingURL=csvImport.js.map