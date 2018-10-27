'use strict';
const dateFormat = require('dateformat');
const cfg = {
    // get info from env vars
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    sendingNumber: process.env.TWILIO_NUMBER
};
const requiredConfig = [cfg.accountSid, cfg.authToken, cfg.sendingNumber];
const isConfigured = requiredConfig.every(function (configValue) {
    return configValue || false;
});
if (!isConfigured) {
    const errorMessage = 'TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_NUMBER must be set.';
    throw new Error(errorMessage);
}
var client = require('twilio')(cfg.accountSid, cfg.authToken);
const DELAY = process.env.CP_DELAY || 10000;
const Pool = require('pg').Pool;
const pool = new Pool({
    idleTimeoutMillis: 2000 //close idle clients after 2 seconds
});
const SCHEMA_NAME = 'carpoolvote';
const OUTGOING_EMAIL_TABLE = 'outgoing_email';
const OUTGOING_SMS_TABLE = 'outgoing_sms';
let currentFunction = 0;
setInterval(function () {
    dbGetItemsToSend(pool, [
        // dbGetOutgoingEmailString
        dbGetOutgoingSmsString
    ]);
}, DELAY);
function dbGetOutgoingEmailString() {
    return ('SELECT * FROM ' +
        SCHEMA_NAME +
        '.' +
        OUTGOING_EMAIL_TABLE +
        ' WHERE status=' +
        " '" +
        'Pending' +
        "' ");
}
function dbGetOutgoingSmsString() {
    return ('SELECT * FROM ' +
        SCHEMA_NAME +
        '.' +
        OUTGOING_SMS_TABLE +
        ' WHERE status=' +
        " '" +
        'Pending' +
        "' ");
}
function dbGetItemsToSend(pool, executeFunctionArray) {
    const fnExecuteFunction = executeFunctionArray[currentFunction++];
    if (currentFunction >= executeFunctionArray.length) {
        currentFunction = 0;
    }
    console.log('array len : ' + executeFunctionArray.length);
    console.log('fn index: ' + currentFunction);
    const queryString = fnExecuteFunction();
    console.log('queryString: ' + queryString);
    pool
        .query(queryString)
        .then(result => {
        const firstRowAsString = '';
        if (result !== undefined &&
            result.rows !== undefined &&
            result.rows.length > 0) {
            result.rows.forEach(smsMessage => {
                const smsMessageOutput = JSON.stringify(smsMessage);
                console.log(dateFormat(new Date(), 'yyyy-mm-dd HH:MM:ss') +
                    ': SMS: ' +
                    smsMessageOutput);
                const message = {
                    id: smsMessage.id,
                    status: smsMessage.state,
                    body: smsMessage.body,
                    phoneNumber: smsMessage.recipient
                };
                makeCalls(message);
                console.error('executed sms query: ' + firstRowAsString);
            });
        }
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(message, stack);
    });
}
function formatMessage(msg) {
    return msg;
}
function makeCalls(message) {
    const messageToSend = formatMessage(message.body);
    sendSms(message.id, message.phoneNumber, messageToSend);
}
function sendSms(id, to, message) {
    client.messages
        .create({
        body: message,
        to: to,
        from: cfg.sendingNumber
    })
        .then(message => {
        // update table status
        dbUpdateMessageItemStatus(id, pool, dbUpdateSentString);
        console.log('User notified');
    })
        .catch(err => {
        console.error('Could not notify user');
        // update table status
        dbUpdateMessageItemStatus(id, pool, dbUpdateFailedString);
        return console.error(err);
    });
}
function dbUpdateSentString(tableName) {
    return ('UPDATE ' +
        SCHEMA_NAME +
        '.' +
        OUTGOING_SMS_TABLE +
        ' SET status=' +
        " '" +
        'Sent' +
        "' WHERE id=$1");
}
function dbUpdateFailedString(tableName) {
    return ('UPDATE ' +
        SCHEMA_NAME +
        '.' +
        OUTGOING_SMS_TABLE +
        ' SET status=' +
        " '" +
        'Failed' +
        "' WHERE id=$1");
}
function dbUpdateMessageItemStatus(id, pool, fnUpdateString) {
    var updateString = fnUpdateString();
    pool
        .query(updateString, [id])
        .then(result => {
        var displayResult = result || '';
        try {
            displayResult = JSON.stringify(result);
        }
        catch (err) {
            console.error('no update result returned');
        }
        console.log('update: ', id + ' ' + displayResult);
    })
        .catch(e => {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error('update error: ', message, stack);
    });
}
