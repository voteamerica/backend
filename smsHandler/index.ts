'use strict';

interface TwilioConfig {
  accountSid: String;
  authToken: String;
  sendingNumber: String; 
}

var cfg: TwilioConfig = {

// get info from env vars
  accountSid: process.env.TWILIO_ACCOUNT_SID,
  authToken: process.env.TWILIO_AUTH_TOKEN,
  sendingNumber: process.env.TWILIO_NUMBER
};


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

interface SMSMessage {
  id: Number,
  state: String;
  body: String;
  phoneNumber: String; 
}

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
// const UNMATCHED_DRIVERS_VIEW  = 'vw_unmatched_riders';
// const MATCH_TABLE             = 'match';

const OUTGOING_EMAIL_TABLE    = 'outgoing_email';
const OUTGOING_SMS_TABLE      = 'outgoing_sms';

var currentFunction = 0;

setInterval(function () {
  dbGetData(pool, [
    // dbGetOutgoingEmailString
    dbGetOutgoingSmsString
      // ,
      // dbExecuteDriversFunctionString
  ]);
}, DELAY);

function dbGetOutgoingEmailString() {
  // return 'SELECT * FROM ' + SCHEMA_NAME + '.' + UNMATCHED_DRIVERS_VIEW
  return 'SELECT * FROM '
  // return 'SELECT uuid_driver FROM '
          + SCHEMA_NAME + '.' 
          + OUTGOING_EMAIL_TABLE
  // UNMATCHED_DRIVERS_VIEW
  // MATCH_TABLE 
      //SWEEPER_RIDERS_FUNCTION
      ;
}

function dbGetOutgoingSmsString() {
  return 'SELECT * FROM '
          + SCHEMA_NAME + '.' 
          + OUTGOING_SMS_TABLE
      ;
}

function dbGetData(pool, executeFunctionArray) {
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
      // result.rows.forEach( val => console.log(val));
      result.rows.forEach(function (smsMessage) { 
        var smsMessageOutput = JSON.stringify(smsMessage);

        console.log("select: " + smsMessageOutput); 

      // firstRowAsString = JSON.stringify(result.rows[0]);

      // var uuid_driver = result.rows[0].uuid_driver.toString();

      var message: SMSMessage = {
        id:           smsMessage.id,
        state:        smsMessage.state,
        body:         smsMessage.body,
        phoneNumber:  smsMessage.recipient
      };

      // console.log("uuid: ", uuid_driver);
      makeCalls(message);

  //      id serial NOT NULL,
  // created_ts timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  // last_updated_ts timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  // state character varying(30) NOT NULL DEFAULT 'Pending'::character varying,
  // recipient character varying(255) NOT NULL,
  // subject character varying(255) NOT NULL,
  // body text NOT NULL,
  // emission_info text,

    console.error("executed sms query: " + firstRowAsString);

      });

    }

  })
  .catch(function (e) {
    var message = e.message || '';
    var stack = e.stack || '';

    console.error(
      // results.failure, 
      message, stack);
  });
}

function formatMessage (msg) {
  return msg
    // '[This is a test] ' +
    // ' Driver: ' + 
    // msg
    //  +
    // '. Go to: http://carpoolvote.com ' +
    // 'for more details.'
    ;
};

function makeCalls (message: SMSMessage) {
// interface SMSMessage {
//   state: String;
//   body: String;
//   phoneNumber: String; 
// }

  // admins.forEach( admin => {
    var messageToSend = formatMessage(message.body);

    sendSms(message.id, message.phoneNumber, messageToSend);
  // });

};

function sendSms (id: Number, to: String, message: String) {
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
      
      dbUpdateData(id, pool, dbGetUpdateString);
      
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

function dbGetUpdateString (tableName) {
  return 'UPDATE ' + SCHEMA_NAME + '.' + OUTGOING_SMS_TABLE +
          ' SET state=' + " '" + 'Sent' + "' WHERE id=$1";
}

function dbUpdateData(id, pool, fnUpdateString) {
  var updateString = fnUpdateString();

  pool.query(
    updateString,
    // fnPayloadArray(req, payload)
    [id]
  )
  .then(result => {
    var displayResult = result || '';
    var uuid = "";

    try {
      displayResult = JSON.stringify(result);
      uuid = result.rows[0].UUID;
      console.error('row: ' + JSON.stringify(result.rows[0]) );
    }
    catch (err) {
      console.error('no uuid returned');
    }

    console.log('update: ', uuid + ' ' + displayResult);

  })
  .catch(e => {
    var message = e.message || '';
    var stack   = e.stack   || '';

    console.error('query error: ', message, stack);
  });
}
