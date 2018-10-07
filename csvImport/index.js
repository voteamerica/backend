'use strict';
const csvParse = require('csv-parse');
const fs = require('fs');
const request = require('request');
const minimist = require('minimist');
const riderUrl = 'https://api.carpoolvote.com/live/rider';
function parseRidersFile(file, orgUuid, callback) {
    fs.readFile(file, function (err, fileData) {
        if (err)
            callback(err);
        const options = {
            columns: true,
            trim: true,
            skip_lines_with_error: false
        };
        csvParse(fileData, options, function (err, rows) {
            if (err)
                callback(err);
            rows.forEach(function (row) {
                const copy = Object.assign({}, row);
                copy.uuid_organization = orgUuid;
                const postOptions = {
                    url: riderUrl,
                    rejectUnauthorized: false,
                    form: copy
                };
                request.post(postOptions, function (err, httpResponse, body) {
                    if (err)
                        callback(err);
                    const riderId = JSON.parse(httpResponse.body).out_uuid;
                    console.log("Rider upload successful: " + riderId);
                });
            });
        });
    });
}
var argv = minimist(process.argv.slice(2));
if (!argv.file || !argv.org_uuid) {
    console.error("Usage: --file=[csv file] --org_uuid=[organization identifier]");
}
else {
    parseRidersFile(argv.file, argv.org_uuid, function (err, data) {
        if (err)
            console.log(err);
    });
}
//# sourceMappingURL=index.js.map