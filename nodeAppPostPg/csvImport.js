'use strict';
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
const csvParse = require("csv-parse");
const request = require("request");
const riderUrl = 'http://localhost:8000/rider';
const driverUrl = 'http://localhost:8000/driver';
// const riderUrl = 'https://api.carpoolvote.com/live/rider';
// const driverUrl = 'https://api.carpoolvote.com/live/driver';
// const postUrl = 'http://localhost:8000/rider';
// Callback callback{err, httpResponse}
// function uploadCsv(postUrl, file, orgUuid, isRider, callback) {
//   fs.readFile(file, function(err, fileData) {
//     if (err) {
//       return callback(err);
//     }
function uploadCsv(postUrl, fileData, orgUuid, isRider, callback) {
    const options = {
        columns: true,
        trim: true,
        skip_lines_with_error: false
    };
    csvParse(fileData, options, (err, rows) => {
        if (err) {
            console.log('parse error:', err);
            return callback(err);
        }
        rows.forEach(row => {
            console.log(row);
            let copy = Object.assign({}, row);
            debugger;
            // NOTE: node app is based around the form coming from html (rather than a
            // js function) to support the widest range of clients. So it expects a false
            // value to be signified by a property not being present, otherwise the value
            // is true. So any boolean property that is not true is removed.
            const removeFalseProp = (key, rowData) => {
                let newRow = {};
                const _a = key, tw = rowData[_a], oneTrip = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
                console.log('key', tw);
                if (tw && tw.toUpperCase() !== 'TRUE') {
                    console.log('true');
                    newRow = oneTrip;
                }
                else {
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
            }
            else {
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
            request.post(postOptions, function (err, httpResponse, body) {
                callback(err, httpResponse);
            });
        });
        // };
    });
}
const consoleLogResultMessage = entryId => {
    const message = entryId && entryId.length > 0
        ? 'upload successful: ' + entryId
        : 'upload failed';
    return message;
};
function uploadRiders(fileData, orgUuid, callback) {
    uploadCsv(riderUrl, fileData, orgUuid, true, function (err, httpResponse, body) {
        if (err) {
            return callback(err);
        }
        debugger;
        const riderInfo = JSON.parse(httpResponse.body);
        const riderId = riderInfo.out_uuid;
        console.log('Rider ' + consoleLogResultMessage(riderId));
        console.log('Rider upload code: ' + riderInfo.out_error_code);
        console.log('Rider upload text: ' + riderInfo.out_error_text);
        callback(err, riderInfo);
    });
}
exports.uploadRiders = uploadRiders;
//# sourceMappingURL=csvImport.js.map