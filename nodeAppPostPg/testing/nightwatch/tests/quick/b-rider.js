module.exports = {
  'rider': function (client) {
    const dates = ['2017-08-09'];

    client
      .url('http://10.5.0.4:4000/#need-ride')
      .waitForElementVisible('body', 3000)
      .assert.containsText('legend', 'Your trip')
      .assert.cssClassPresent('#RiderAvailableTimes', 'available-times')

      // set date/time
      .execute( function (data) {
          console.log('passed args: ', arguments);
          document.getElementById("RiderDate0").value = arguments[0];  
          return arguments;
        }
        , dates 
        , function (result) {
            console.log("result", result.value);
            client.assert.deepEqual(dates, result.value, 'Result matches');
          }
      )
      // .setValue('input[name="RiderDate"]', '2017-05-12')

      .setValue('input[id="riderCollectionAddress"]', '1 high st')
      // .assert.containsText('input[id="riderCollectionAddress"]', '1 high st')
      .assert.valueContains('input[id="riderCollectionAddress"]', '1')

// new
      .setValue('input[name="RiderCollectionZIP"]', '10036')
      .setValue('input[id="riderDestinationAddress"]', '1 main st')
      .setValue('input[id="rideDestinationZIP"]', '10036')

      .setValue('input[id="rideSeats"]', '1')
      .setValue('#RiderAccommodationNotes', 'comfy chair')

      .setValue('input[name="RiderFirstName"]', 'anne')
      .setValue('input[name="RiderLastName"]', 'test')
      .setValue('input[name="RiderEmail"]', 'a@test.com')
      .setValue('input[name="RiderPhone"]', '07755000111')

      .click('input[name="RiderPreferredContact"]')
      .click('input[name="RiderAgreeTnC"]')
      
      .saveScreenshot('./reports/rider-entries2.png')

      .click('button[id="needRideSubmit"]')

      .saveScreenshot('./reports/rider-submitted.png')

      .waitForElementVisible('h1#thanks-header', 5000)
      .assert.containsText('h1#thanks-header', 'Congratulations')


      // .assert.containsText('div.with-errors ul li', 'Please fill in')
      // .assert.valueContains('div.with-errors ul li', 'Please')
      .end();
  }
};
