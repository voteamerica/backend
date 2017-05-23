module.exports = {
  'currentClient' : undefined,

  'dates' : ['2017-08-09'],

  'finish' : 
    function finish (client) {
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      var client = this.currentClient;
      
      client.end();

      return this;
    },

  'addDriver' : 
    function addDriver (client) {
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      var client = this.currentClient;
      var dates = this.dates;

      var newState = client
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
        .assert.containsText('h1#thanks-header', 'Thank you');

      // return newState;
      return this;
    },

  'addRider' : 
    function addRider (client) {
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      var client = this.currentClient;
      var dates = this.dates;
      var newState = client
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
        .assert.containsText('h1#thanks-header', 'Congratulations');


        // .assert.containsText('div.with-errors ul li', 'Please fill in')
        // .assert.valueContains('div.with-errors ul li', 'Please')

      // return newState;
      return this;
    },

  // this test is called after first rider, then driver have been added - it's assumed 
  // app is at thanks driver page
  'match' : 
    function match (client) {      
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      var client = this.currentClient;
      var dates = this.dates;

      var newState = client
        // .url('http://10.5.0.4:4000/#need-ride')
        .waitForElementVisible('.self-service-url', 3000)
        .assert.containsText('.self-service-url', 'self-service portal')
        .pause(15000) // wait for matching engine to create the proposed match
        .click('.self-service-url')
        .pause(3000) // page takes a while to settle and hide id field

        .saveScreenshot('./reports/match-self-service.png')

        .waitForElementVisible('#inputPhoneNumber', 3000)
        .setValue('input[id="inputPhoneNumber"]', 'test')

        .click('.button')

        .waitForElementVisible('#driverInfo > h3.self-service-heading', 3000)

        .saveScreenshot('./reports/match-self-service-logged-in.png')

        .assert.containsText('#driverInfo > h3.self-service-heading', 'Driver Info')
        .waitForElementVisible('#driverProposedMatches > h3.self-service-heading', 3000)
        .assert.containsText('#driverProposedMatches > h3.self-service-heading', 'Driver Proposed Matches')

        // should check for first list item
        .assert.containsText('#driverProposedMatches > ul li', 'UUID_driver')
        .assert.containsText('#driverProposedMatches > ul li.list_button button', 'Accept')

        .waitForElementVisible('#driverProposedMatches > ul li.list_button button', 1000)
        // accept match
        .click('#driverProposedMatches > ul li.list_button button')

        .waitForElementNotPresent('#driverProposedMatches > ul li.list_button button', 3000)
        .waitForElementVisible('#driverConfirmedMatches > ul li.list_button button', 3000)

        .saveScreenshot('./reports/match-self-service-accept-match.png')

        .assert.containsText('#driverConfirmedMatches > ul li', 'UUID_driver')
        .assert.containsText('#driverConfirmedMatches > ul li.list_button button', 'Cancel')

        // cancel match
        .click('#driverConfirmedMatches > ul li.list_button button')

        // alert button appears
        // https://stackoverflow.com/questions/35287273/how-to-click-on-alert-box-ok-button-using-nightwatch-js
        .pause(2000)
        .acceptAlert()

        .saveScreenshot('./reports/match-self-service-cancel-match.png')
        
        .waitForElementNotPresent('#driverConfirmedMatches > ul li.list_button button', 3000)

      return this;
    }
};
