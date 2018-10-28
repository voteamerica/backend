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
const csvParseBase = require("csv-parse");
const transform = require("stream-transform");
const rp = require("request-promise");
// const riderUrl = 'http://localhost:8000/rider';
// const driverUrl = 'http://localhost:8000/driver';
const riderUrl = 'https://api.carpoolvote.com/live/rider';
const driverUrl = 'https://api.carpoolvote.com/live/driver';
const createItem = (row, isRider, orgUuid) => {
    let adjustedItem = Object.assign({}, row);
    const fieldExists = (key, rowData) => {
        const _a = key, field = rowData[_a], allOtherFields = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
        if (field) {
            return true;
        }
        return false;
    };
    const getPropValue = (key, rowData) => {
        const _a = key, field = rowData[_a], allOtherFields = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
        if (field) {
            return field;
        }
        return '';
    };
    const removeProp = (key, rowData) => {
        const _a = key, field = rowData[_a], allOtherFields = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
        return allOtherFields;
    };
    // NOTE: node app is based around the form coming from html (rather than a
    // js function) to support the widest range of clients. So it expects a false
    // value to be signified by a property not being present, otherwise the value
    // is true. So any boolean property that is not true is removed.
    const removeFalseProp = (key, rowData) => {
        let newRow = {};
        const _a = key, field = rowData[_a], allOtherFields = __rest(rowData, [typeof _a === "symbol" ? _a : _a + ""]);
        console.log('key', field);
        if (field && field.toUpperCase() !== 'TRUE') {
            console.log('true');
            newRow = allOtherFields;
        }
        else {
            console.log('false');
            newRow = rowData;
        }
        return newRow;
    };
    const handleAlternativeAvailableDateTimeFormat = (availableTimesFieldName, dateFieldName, startTimeFieldName, endTimeFieldName, rowData) => {
        debugger;
        if (fieldExists(dateFieldName, rowData) &&
            fieldExists(startTimeFieldName, rowData) &&
            fieldExists(endTimeFieldName, rowData)) {
            rowData = removeProp(availableTimesFieldName, rowData);
            const rideDate = getPropValue(dateFieldName, rowData);
            const rideStartTime = getPropValue(startTimeFieldName, rowData);
            const rideEndTime = getPropValue(endTimeFieldName, rowData);
            debugger;
            const availableDate = dateToYYYYMMDD(new Date(rideDate));
            const JSONdate = formatAvailabilityPeriod(availableDate, rideStartTime, rideEndTime);
            console.log('fmtd date', JSONdate);
            rowData = Object.assign({}, rowData, { [availableTimesFieldName]: JSONdate });
            rowData = removeProp(dateFieldName, rowData);
            rowData = removeProp(startTimeFieldName, rowData);
            rowData = removeProp(endTimeFieldName, rowData);
        }
        return rowData;
    };
    if (isRider === true) {
        adjustedItem = removeFalseProp('TwoWayTripNeeded', adjustedItem);
        adjustedItem = removeFalseProp('RiderIsVulnrable', adjustedItem);
        adjustedItem = removeFalseProp('RiderWillNotTalkPolitics', adjustedItem);
        adjustedItem = removeFalseProp('PleaseStayInTouch', adjustedItem);
        adjustedItem = removeFalseProp('NeedWheelchair', adjustedItem);
        adjustedItem = removeFalseProp('RiderLegalConsent', adjustedItem);
        adjustedItem = removeFalseProp('RiderWillBeSafe', adjustedItem);
        adjustedItem = handleAlternativeAvailableDateTimeFormat('AvailableRideTimesJSON', 'RideRequestDate', 'RideRequestStartTime', 'RideRequestEndTime', adjustedItem);
        adjustedItem.RidingOnBehalfOfOrganization = true;
        adjustedItem.RidingOBOOrganizationName = orgUuid;
        // console.log('rider', adjustedItem);
    }
    else {
        adjustedItem = removeFalseProp('DriverWillTakeCare', adjustedItem);
        adjustedItem = removeFalseProp('DriverCanLoadRiderWithWheelchair', adjustedItem);
        adjustedItem = removeFalseProp('DriverWillNotTalkPolitics', adjustedItem);
        adjustedItem = removeFalseProp('PleaseStayInTouch', adjustedItem);
        adjustedItem = removeFalseProp('RidersCanSeeDriverDetails', adjustedItem);
        adjustedItem = removeFalseProp('DriverWillTakeCare', adjustedItem);
        adjustedItem = removeFalseProp('RiderWillBeSafe', adjustedItem);
        adjustedItem = handleAlternativeAvailableDateTimeFormat('AvailableDriveTimesJSON', 'DriveOfferDate', 'DriveOfferStartTime', 'DriveOfferEndTime', adjustedItem);
        adjustedItem.DrivingOnBehalfOfOrganization = true;
        adjustedItem.DrivingOBOOrganizationName = orgUuid;
        // console.log('driver', adjustedItem);
    }
    return adjustedItem;
};
function uploadCsv(itemsStream, orgUuid, callback) {
    const options = {
        columns: true,
        trim: true,
        skip_lines_with_error: false
    };
    const uploadParseErrorType = 'parse error';
    const uploadDbInputErrorType = 'db input error';
    const items = [];
    const adjustedItems = [];
    let ridersCsv = false; // if false after parsingStarted === true, this is a drivers csv
    let parsingStarted = false;
    let postUrl = '';
    debugger;
    const csvParse = csvParseBase(options);
    const transformer = transform(record => {
        // console.log('rec:', record);
        items.push(record);
        if (parsingStarted === false) {
            if (record.RiderFirstName !== undefined) {
                ridersCsv = true;
                parsingStarted = true;
                postUrl = riderUrl;
            }
            else if (record.DriverFirstName !== undefined) {
                parsingStarted = true;
                postUrl = driverUrl;
            }
        }
        const newRecord = createItem(record, ridersCsv, orgUuid);
        adjustedItems.push(newRecord);
        return newRecord;
    });
    itemsStream.pipe(csvParse).pipe(transformer);
    csvParse.on('error', function (err) {
        debugger;
        return callback({ error: err.message, type: uploadParseErrorType });
    });
    csvParse.on('end', async function () {
        // console.log('new items:', adjustedItems);
        const rows = adjustedItems;
        const rowsAddedToDb = [];
        const inputErrors = [];
        const storeInputError = (error, row) => {
            console.log('error', error);
            const message = error.message || error;
            const data = error.options ? error.options.form : row;
            const inputErr = {
                error: message,
                type: uploadDbInputErrorType,
                data
            };
            inputErrors.push(inputErr);
            return inputErr;
        };
        const addRowToDb = async (postUrl, row, callback) => {
            // console.log(row);
            const postOptions = {
                method: 'POST',
                url: postUrl,
                rejectUnauthorized: false,
                form: row
            };
            try {
                const response = await rp.post(postOptions);
                debugger;
                const resp = JSON.parse(response);
                if (resp.out_error_code && resp.out_error_code > 0) {
                    return storeInputError('data rejected', row);
                }
                return resp;
            }
            catch (error) {
                debugger;
                return storeInputError(error, row);
            }
        };
        for (const row of rows) {
            const resp = await addRowToDb(postUrl, row, callback);
            debugger;
            const inputtedItem = resp;
            // console.log(inputtedItem);
            if (inputtedItem.error === undefined) {
                debugger;
                rowsAddedToDb.push(inputtedItem);
            }
        }
        debugger;
        // console.log('rows done:', rowsAddedToDb);
        console.log('rows added count :', rowsAddedToDb.length);
        const replyDetailsLength = {
            recordsReceived: rows.length,
            uploadCount: rowsAddedToDb.length
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
        }
        else {
            debugger;
            return callback(null, replyDetailsFull);
        }
    });
}
function uploadRidersOrDrivers(fileData, orgUuid, callback) {
    uploadCsv(fileData, orgUuid, function (err, httpResponse) {
        if (err) {
            return callback(err);
        }
        debugger;
        callback(null, httpResponse);
    });
}
exports.uploadRidersOrDrivers = uploadRidersOrDrivers;
/**
 *
 * Functions below are copied from the excellent front-end date/time input handling features.
 *
 */
/**
 * Convert a single Availability Time row into a joined datetime string.
 * @param  {string} date - A date in YYYY-MM-DD format
 * @param  {string} startTime - A time in either 12 or 24-hour format
 * @param  {string} endTime - A time in either 12 or 24-hour format
 * @return {string} The datetime for a single row
 */
function formatAvailabilityPeriod(date, startTime, endTime) {
    return [startTime, endTime]
        .map(function (time) {
        return toISO8601(date || '', time);
    })
        .join('/');
}
/**
 * Convert a date and time to ISO 8601 format
 * (See https://www.w3.org/TR/NOTE-datetime)
 * Uses complete date plus hours and minutes but no time-zone
 * @param  {string} date - In YYYY-MM-DD format
 * @param  {string} time - In either 12 or 24-hour format
 * @return {string} A date in YYYY-MM-DDThh-mm format
 */
function toISO8601(date, time) {
    return [date, to24Hour(time)].join('T');
}
/**
 * Convert a 12-hour time to 24-hour time
 * @param  {string} time - A time in either 12 or 24-hour format
 * @return {string} A time in 24-hour format
 */
function to24Hour(time) {
    if (!time) {
        return '';
    }
    var period = time.match(/[AP]M/);
    if (!period) {
        return time; // is 24 hour time already
    }
    var divisions = time.split(':'), hours = divisions[0], minutes = divisions[1];
    if (period.toString() === 'PM' && +hours !== 12) {
        hours = +hours + 12;
    }
    return [hours, minutes].join(':');
}
/**
 * Convert a date object to 'YYYY-MM-DD' format
 * @param  {object} date - A date object.
 * @return {string} An ISO-compliant YYYY-MM-DD date string
 */
function dateToYYYYMMDD(date) {
    var mm = date.getMonth() + 1;
    var dd = date.getDate();
    return [
        date.getFullYear(),
        mm < 10 ? '0' + mm : mm,
        dd < 10 ? '0' + dd : dd
    ].join('-');
}
//# sourceMappingURL=csvImport.js.map