module.exports = {
  'driver': function (client) {
    const dates = ['2017-08-09'];

    client
      .url('http://10.5.0.4:4000/#offer-ride')
      .waitForElementVisible('body', 3000)
      .assert.containsText('form#offer-ride legend', 'What can you offer?')

      .getAttribute('form#offer-ride', 'action', function (result) {
        console.log("form attribute result: ", result);
      })
      .getAttribute('form#offer-ride input', 'value', function (result) {
        console.log("form input attribute result: ", result);
      })

      // set date/time
      .execute( function (data) {
          console.log('passed args: ', arguments);
          document.getElementById("DriverDate0").value = arguments[0];  
          return arguments;
        }
        , dates 
        , function (result) {
            console.log("result", result.value);
            client.assert.deepEqual(dates, result.value, 'Result matches');
          }
      )

      .setValue('input[name="DriverCollectionZIP"]', '10036')
      .setValue('input[name="DriverCollectionRadius"]', '1')
      .setValue('input[name="SeatCount"]', '1')

      .click('input[name="DriverHasInsurance"]')

      // document.getElementById("DriverDate0").value =  "2018-03-04"

      .saveScreenshot('./reports/driver-entries1m8.png')

      .setValue('input[name="DriverLicenceNumber"]', '123')
      .setValue('input[name="DriverFirstName"]', 'jim')
      .setValue('input[name="DriverLastName"]', 'test')
      .setValue('input[name="DriverEmail"]', 'j@test.com')
      .setValue('input[name="DriverPhone"]', '07755000111')

      .click('input[name="DriverPreferredContact"]')
      .click('input[name="DriverAgreeTnC"]')
      
      .saveScreenshot('./reports/driver-entries2.png')

      .click('button[id="offerRideSubmit"]')
      
      .saveScreenshot('./reports/driver-submitted.png')
      
      // .pause(5000)
      
      .saveScreenshot('./reports/driver-thanks.png')

      .waitForElementVisible('h1#thanks-header', 5000)
      .assert.containsText('h1#thanks-header', 'Thank you')

      .end();
  }
};
