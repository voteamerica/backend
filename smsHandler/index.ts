'use strict';

var cfg = {};

// get info from env vars
cfg.accountSid = process.env.TWILIO_ACCOUNT_SID;
cfg.authToken = process.env.TWILIO_AUTH_TOKEN;
cfg.sendingNumber = process.env.TWILIO_NUMBER;

var requiredConfig = [cfg.accountSid, cfg.authToken, cfg.sendingNumber];
var isConfigured = requiredConfig.every(function(configValue) {
  return configValue || false;
});

if (!isConfigured) {
  var errorMessage =
    'TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_NUMBER must be set.';

  throw new Error(errorMessage);
}

var client = require('twilio')(cfg.accountSid, cfg.authToken);


var admins = require('./nums.json');

var DELAY = process.env.CP_DELAY || 10000;

var Pool = require('pg').Pool;
var pool = new Pool({
    idleTimeoutMillis: 2000 //close idle clients after 1 second
});

// var SCHEMA_NAME = 'stage';
var SCHEMA_NAME = 'nov2016';
// var SWEEPER_RIDERS_FUNCTION = 'create_riders()';
// var SWEEPER_DRIVERS_FUNCTION = 'create_drivers()';
// random thing to call
const UNMATCHED_DRIVERS_VIEW    = 'vw_unmatched_riders';
const MATCH_TABLE    = 'match';


var currentFunction = 0;

setInterval(function () {
    dbGetData(pool, [dbExecuteRidersFunctionString
        // ,
        // dbExecuteDriversFunctionString
    ]);
}, DELAY);

function dbExecuteRidersFunctionString() {
    // return 'SELECT * FROM ' + SCHEMA_NAME + '.' + UNMATCHED_DRIVERS_VIEW
    // return 'SELECT * FROM '
    return 'SELECT uuid_driver FROM '
     + SCHEMA_NAME + '.' + 
    // UNMATCHED_DRIVERS_VIEW
    MATCH_TABLE 
        //SWEEPER_RIDERS_FUNCTION
        ;
}

// function dbExecuteDriversFunctionString() {
//     return 'select ' + SCHEMA_NAME + '.' + SWEEPER_DRIVERS_FUNCTION;
// }

function dbGetData(pool, executeFunctionArray) {
    var fnExecuteFunction = executeFunctionArray[currentFunction++];
    if (currentFunction >= executeFunctionArray.length) {
        currentFunction = 0;
    }
    
    console.log("array len : " + executeFunctionArray.length);
    console.log("fn index: " + currentFunction);
    
    var queryString = fnExecuteFunction();
    
    console.log("queryString: " + queryString);

    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            // result.rows.forEach( val => console.log(val));
            result.rows.forEach(function (val) { return console.log("select: " + JSON.stringify(val)); });
            firstRowAsString = JSON.stringify(result.rows[0]);

var uuid_driver = result.rows[0].uuid_driver.toString();
console.log("uuid: ", uuid_driver);
makeCalls(uuid_driver);

        }
        console.error("executed query: " + firstRowAsString);
        // reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(
        // results.failure, 
        message, stack);
        // reply(results.failure + message).code(500);
    });
}



// makeCalls();

function formatMessage (msg) {
  return '[This is a test] ' +
    ' Driver: ' + msg +
    '. Go to: http://carpoolvote.com ' +
    'for more details.';
};

function makeCalls (message) {

  admins.forEach( admin => {
    var messageToSend = formatMessage(message);

    sendSms(admin.phoneNumber, messageToSend);
  });

};

function sendSms (to, message) {
  client.messages.create({
      body: message,
      to: to,
      from: cfg.sendingNumber
      // mediaUrl: 'http://www.yourserver.com/someimage.png'
    }, 
    (err, data) => {
      if (err) {
        console.error('Could not notify administrator');
        return console.error(err);
      } 
      
      console.log('Administrator notified');
    }
  );
};

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


