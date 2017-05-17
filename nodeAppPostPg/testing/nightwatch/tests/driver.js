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
      // .assert.cssClassPresent('#RiderAvailableTimes', 'available-times')
      // .setValue('input[name="DriverCollectionZIP"]', '10037')
      .setValue('input[name="DriverCollectionZIP"]', '10036')
      .setValue('input[name="DriverCollectionRadius"]', '1')
      .setValue('input[name="SeatCount"]', '1')
      .click('input[name="DriverHasInsurance"]')
      // .setValue('input[name="DriverDate"]', '2017-05-12')
      // .setValue('input[id="DriverDate0"]', '2017-05-12')
      // .setValue('input[id="DriverDate0"]', '16')
      // .setValue('input[id="DriverDate0"]', '05')
      // .setValue('input[id="DriverDate0"]', '2017')

      // .setValue('input[id="DriverDate0"]', '03')
      // .setValue('input[id="DriverDate0"]', '12')
      // .setValue('input[id="DriverDate0"]', '4567')

      // .setValue('input[id="DriverDate0"]', '31/04/2017')
      // .setValue('input[id="DriverDate0"]', '31042017')
      // .setValue('input[id="DriverDate0"]', '31')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '1')
      // .saveScreenshot('./reports/driver-entries1m1.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '2')
      // .saveScreenshot('./reports/driver-entries1m2.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '3')
      // .saveScreenshot('./reports/driver-entries1m3.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '1')
      // .saveScreenshot('./reports/driver-entries1m4.png')

      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '2017')
      // .saveScreenshot('./reports/driver-entries1m5.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '20')
      // .saveScreenshot('./reports/driver-entries1m6.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '18')
      // .saveScreenshot('./reports/driver-entries1m7.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '201')

      // .saveScreenshot('./reports/driver-entries1m7a.png')
      // .clearValue('input[id="DriverDate0"]')

      // .setValue('input[id="DriverDate0"]', '2019')
      // .setValue('input[id="DriverDate0"]', '20194')
      // .setValue('input[id="DriverDate0"]', '201941')
      // .setValue('input[id="DriverDate0"]', '123')
      // .setValue('input[id="DriverDate0"]', '1234')

      // .setValue('input[id="DriverDate0"]', '01/01/1970')
      // .setValue('input[id="DriverDate0"]', '01/01/1990')
      // .setValue('input[id="DriverDate0"]', '01011992')
      // .setValue('input[id="DriverDate0"]', '01/01/2019')

          // document.getElementById("DriverDate0").value =  "2018-03-04"

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
      .saveScreenshot('./reports/driver-entries1m8.png')
      // .clearValue('input[id="DriverDate0"]')
      // .setValue('input[id="DriverDate0"]', '2')
      // .setValue('input[id="DriverDate0"]', '0')
      // .setValue('input[id="DriverDate0"]', '1')

      // .setValue('input[id="DriverDate0"]', '31')
      // .setValue('input[id="DriverDate0"]', '04')
      // .setValue('input[id="DriverDate0"]', '8657')
      // .setValue('id="DriverMonth0"', '05')

      // .saveScreenshot('./reports/driver-entries1m9.png')

      .setValue('input[name="DriverLicenceNumber"]', '123')
      .setValue('input[name="DriverFirstName"]', 'jim')
      .setValue('input[name="DriverLastName"]', 'test')
      .setValue('input[name="DriverEmail"]', 'j@test.com')
      .setValue('input[name="DriverPhone"]', '07755000111')
      .click('input[name="DriverPreferredContact"]')
      .click('input[name="DriverAgreeTnC"]')
      .saveScreenshot('./reports/driver-entries2.png')
      .click('button[id="offerRideSubmit"]')
      // .waitForElementNotVisible('body', 5000)
      .saveScreenshot('./reports/driver-submitted.png')
      // .waitForElementVisible('body', 5000)
      .pause(5000)
      .saveScreenshot('./reports/driver-thanks.png')

      .waitForElementVisible('h1#thanks-header', 5000)
      .assert.containsText('h1#thanks-header', 'Thank you')

      // .setValue('input[name="RiderDate"]', '2017-05-12')
      // .setValue('input[id="riderCollectionAddress"]', '1 high st')
      // .assert.containsText('input[id="riderCollectionAddress"]', '1 high st')
      // .assert.valueContains('input[id="riderCollectionAddress"]', '1')
      // .click('button[id="needRideSubmit"]')
      // .assert.containsText('div.with-errors ul li', 'Please fill in')
      // .assert.valueContains('div.with-errors ul li', 'Please')
      .end();
  }
};
