var admins = require('./nums.json');

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

makeCalls();

function formatMessage (msg) {
  return '[This is a test] ' +
    ' Driver: ' + msg +
    '. Go to: http://carpoolvote.com ' +
    'for more details.';
};

function makeCalls () {

  admins.forEach( admin => {
    var messageToSend = formatMessage('test sms');

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


