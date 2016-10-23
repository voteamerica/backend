'use strict';
var cfg = {
    // get info from env vars
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    sendingNumber: process.env.TWILIO_NUMBER
};
var requiredConfig = [cfg.accountSid, cfg.authToken, cfg.sendingNumber];
var isConfigured = requiredConfig.every(function (configValue) {
    return configValue || false;
});
if (!isConfigured) {
    var errorMessage = 'TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_NUMBER must be set.';
    throw new Error(errorMessage);
}
var client = require('twilio')(cfg.accountSid, cfg.authToken);
var DELAY = process.env.CP_DELAY || 10000;
var Pool = require('pg').Pool;
var pool = new Pool({
    idleTimeoutMillis: 2000 //close idle clients after 2 seconds
});
// var SCHEMA_NAME = 'stage';
var SCHEMA_NAME = 'nov2016';
var OUTGOING_EMAIL_TABLE = 'outgoing_email';
var OUTGOING_SMS_TABLE = 'outgoing_sms';
var currentFunction = 0;
setInterval(function () {
    dbGetItemsToSend(pool, [
        // dbGetOutgoingEmailString
        dbGetOutgoingSmsString
    ]);
}, DELAY);
function dbGetOutgoingEmailString() {
    return 'SELECT * FROM '
        + SCHEMA_NAME + '.'
        + OUTGOING_EMAIL_TABLE
        + ' WHERE state=' + " '" + 'Pending' + "' ";
    ;
}
function dbGetOutgoingSmsString() {
    return 'SELECT * FROM '
        + SCHEMA_NAME + '.'
        + OUTGOING_SMS_TABLE
        + ' WHERE state=' + " '" + 'Pending' + "' ";
    ;
}
function dbGetItemsToSend(pool, executeFunctionArray) {
    var fnExecuteFunction = executeFunctionArray[currentFunction++];
    if (currentFunction >= executeFunctionArray.length) {
        currentFunction = 0;
    }
    console.log("array len : " + executeFunctionArray.length);
    console.log("fn index: " + currentFunction);
    var queryString = fnExecuteFunction();
    console.log("queryString: " + queryString);
    pool
        .query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined &&
            result.rows.length > 0) {
            result.rows.forEach(function (smsMessage) {
                var smsMessageOutput = JSON.stringify(smsMessage);
                console.log("message: " + smsMessageOutput);
                var message = {
                    id: smsMessage.id,
                    state: smsMessage.state,
                    body: smsMessage.body,
                    phoneNumber: smsMessage.recipient
                };
                makeCalls(message);
                console.error("executed sms query: " + firstRowAsString);
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
;
function makeCalls(message) {
    var messageToSend = formatMessage(message.body);
    sendSms(message.id, message.phoneNumber, messageToSend);
}
;
function sendSms(id, to, message) {
    client.messages.create({
        body: message,
        to: to,
        from: cfg.sendingNumber
    }, function (err, data) {
        if (err) {
            console.error('Could not notify user');
            return console.error(err);
        }
        // update table status
        dbUpdateMessageItemStatus(id, pool, dbGetUpdateString);
        console.log('User notified');
    });
}
;
function dbGetUpdateString(tableName) {
    return 'UPDATE ' + SCHEMA_NAME + '.' + OUTGOING_SMS_TABLE +
        ' SET state=' + " '" + 'Sent' + "' WHERE id=$1";
}
function dbUpdateMessageItemStatus(id, pool, fnUpdateString) {
    var updateString = fnUpdateString();
    pool.query(updateString, [id])
        .then(function (result) {
        var displayResult = result || '';
        try {
            displayResult = JSON.stringify(result);
        }
        catch (err) {
            console.error('no update result returned');
        }
        console.log('update: ', id + ' ' + displayResult);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error('update error: ', message, stack);
    });
}
//  curl -X POST 'https://api.twilio.com/2010-04-01/Accounts/<AccountSid>/Messages.json' \
//         --data-urlencode 'To=<ToNumber>' \
//         --data-urlencode 'From=<FromNumber>' \
//         --data-urlencode 'Body=<BodyText>' \
//         -u <AccountSid>:<AuthToken>
// // Twilio Credentials
//     var accountSid = '<AccountSid>';
//     var authToken = '<AuthToken>';
//     //require the Twilio module and create a REST client
//     var client = require('twilio')(accountSid, authToken);
//     client.messages.create({
//         to: '<ToNumber>',
//         from: '<FromNumber>',
//         body: '<BodyText>',
//     }, function (err, message) {
//         console.log(message.sid);
//     });        
// <Response>
//    <Message>Hello from Twilio!</Message>
// </Response>
//# sourceMappingURL=index.js.map