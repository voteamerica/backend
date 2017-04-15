'use strict';

interface TwilioConfig {
  accountSid: String;
  authToken: String;
  sendingNumber: String; 
}

interface SMSMessage {
  id: Number,
  status: String;
  body: String;
  phoneNumber: String; 
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

var DELAY = process.env.CP_DELAY || 10000;

var Pool = require('pg').Pool;
var pool = new Pool({
  idleTimeoutMillis: 2000 //close idle clients after 2 seconds
});

var SCHEMA_NAME = 'carpoolvote';

const OUTGOING_EMAIL_TABLE    = 'outgoing_email';
const OUTGOING_SMS_TABLE      = 'outgoing_sms';

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
          + ' WHERE status=' + " '" + 'Pending' + "' ";
      ;
}

function dbGetOutgoingSmsString() {
  return 'SELECT * FROM '
          + SCHEMA_NAME + '.' 
          + OUTGOING_SMS_TABLE
          + ' WHERE status=' + " '" + 'Pending' + "' ";
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
  .then( result => {
    var firstRowAsString = "";

    if (result !== undefined && result.rows !== undefined &&
        result.rows.length > 0) {

      result.rows.forEach( smsMessage => { 
        var smsMessageOutput = JSON.stringify(smsMessage);

        console.log("message: " + smsMessageOutput); 

        var message: SMSMessage = {
          id:           smsMessage.id,
          status:        smsMessage.state,
          body:         smsMessage.body,
          phoneNumber:  smsMessage.recipient
        };

        makeCalls(message);

        console.error("executed sms query: " + firstRowAsString);
      });
    }
  })
  .catch(function (e) {
    var message = e.message || '';
    var stack = e.stack || '';

    console.error(
      message, stack);
  });
}

function formatMessage (msg) {
  return msg;
};

function makeCalls (message: SMSMessage) {
  var messageToSend = formatMessage(message.body);

  sendSms(message.id, message.phoneNumber, messageToSend);
};

function sendSms (id: Number, to: String, message: String) {
  client.messages.create({
      body: message,
      to: to,
      from: cfg.sendingNumber
    }, 
    (err, data) => {
      
      if (err) {
        console.error('Could not notify user');

        // update table status
        dbUpdateMessageItemStatus(id, pool, dbUpdateFailedString);
      
        return console.error(err);
      } 
      
      // update table status
      dbUpdateMessageItemStatus(id, pool, dbUpdateSentString);
      
      console.log('User notified');
    }
  );
};

function dbUpdateSentString (tableName) {
  return 'UPDATE ' + SCHEMA_NAME + '.' + OUTGOING_SMS_TABLE +
          ' SET status=' + " '" + 'Sent' + "' WHERE id=$1";
}

function dbUpdateFailedString (tableName) {
  return 'UPDATE ' + SCHEMA_NAME + '.' + OUTGOING_SMS_TABLE +
          ' SET status=' + " '" + 'Failed' + "' WHERE id=$1";
}

function dbUpdateMessageItemStatus(id, pool, fnUpdateString) {
  var updateString = fnUpdateString();

  pool.query(
    updateString,
    [id]
  )
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
    var stack   = e.stack   || '';

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

