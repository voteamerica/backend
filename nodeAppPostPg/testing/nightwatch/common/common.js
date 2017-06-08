module.exports = {
  'currentClient' : undefined,

  'dates' : ['2017-08-09'],

  'riderSelfServicePageUrl' : "",

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

      console.log("addRider");

      var self = this;

      var client = this.currentClient;
      var dates = this.dates;
      var newState = client
        .url('http://10.5.0.4:4000/#need-ride')
        // .waitForElementVisible('body', 3000)
        .waitForElementVisible('form#need-ride', 3000)
        // .assert.containsText('legend', 'Your trip')
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

        .waitForElementVisible('.self-service-url', 1000)
        .assert.containsText('.self-service-url', 'self-service portal')

        .getAttribute(".self-service-url", "href", function(result) {
          console.log("rider self service url: ", result);
          // this.assert.equal(typeof result, "object");
          // this.assert.equal(result.status, 0);
          // this.assert.equal(result.value, "#home");
          self.riderSelfServicePageUrl = result.value;

          console.log("rider url: ", self.riderSelfServicePageUrl);
        });

        // .assert.containsText('div.with-errors ul li', 'Please fill in')
        // .assert.valueContains('div.with-errors ul li', 'Please')

      return this;
    },

  // this test is called after a driver has been added - it's assumed 
  // app is at thanks driver page
  'viewDriverSelfService' : 
    function viewDriverSelfService (client) {      
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

      return this;
    },

  // this test is called after first rider, then driver have been added - it's assumed 
  // app is at driver self service page, with a proposed match visible
  'viewProposedMatch' : 
    function viewProposedMatch (client) {      
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      var client = this.currentClient;
      var dates = this.dates;

      var newState = client
        // should check for first list item
        .assert.containsText('#driverProposedMatches > ul li', 'UUID_driver')
        .assert.containsText('#driverProposedMatches > ul li.list_button button', 'Accept')

        .waitForElementVisible('#driverProposedMatches > ul li.list_button button', 1000)

      return this;
    },

    // this test is called after first rider, then driver have been added - it's assumed 
    // app is at driver self service page, with a proposed match visible
    'acceptMatch' : 
      function acceptMatch (client) {      
        if (client !== undefined && client !== null) {
          this.currentClient = client;
        }

        var client = this.currentClient;
        var dates = this.dates;

        var newState = client
          .click('#driverProposedMatches > ul li.list_button button')

          .waitForElementNotPresent('#driverProposedMatches > ul li.list_button button', 3000)
          .waitForElementVisible('#driverConfirmedMatches > ul li.list_button button', 3000)

          .saveScreenshot('./reports/match-self-service-accept-match.png')

          .assert.containsText('#driverConfirmedMatches > ul li', 'UUID_driver')
          .assert.containsText('#driverConfirmedMatches > ul li.list_button button', 'Cancel')

        return this;
      },

    // this test is called after first rider, then driver have been added - it's assumed 
    // app is at driver self service page, with an accepted match visible
    'driverCancelMatch' : 
      function driverCancelMatch (client) {      
        if (client !== undefined && client !== null) {
          this.currentClient = client;
        }

        var client = this.currentClient;
        var dates = this.dates;

        var newState = client
          .click('#driverConfirmedMatches > ul li.list_button button')

          // alert button appears
          // https://stackoverflow.com/questions/35287273/how-to-click-on-alert-box-ok-button-using-nightwatch-js
          .pause(2000)
          .acceptAlert()

          .saveScreenshot('./reports/match-self-service-cancel-match.png')
          
          .waitForElementNotPresent('#driverConfirmedMatches > ul li.list_button button', 3000)

        return this;
      },

    // this test is called after first rider, then driver have been added - it's assumed 
    // app is at rider self service page
    'viewRiderSelfService' : 
      function viewRiderSelfService (client) {
        if (client !== undefined && client !== null) {
          this.currentClient = client;
        }

        var self = this;

        var client = this.currentClient;
        var dates = this.dates;
        
        console.log("rider info url 1: ", this.riderSelfServicePageUrl);
        // console.log("rider info url: ", riderUrl);

        var newState = client
          .perform(function (client, done) {

            console.log("rider info url 2: ", self.riderSelfServicePageUrl);

            client
              .url(self.riderSelfServicePageUrl)
              // .url(riderUrl)

              .pause(3000) // page takes a while to settle and hide id field

              .saveScreenshot('./reports/rider-self-service.png')

              .waitForElementVisible('#inputPhoneNumber', 3000)
              .setValue('input[id="inputPhoneNumber"]', 'test')

              .click('.button')

              .waitForElementVisible('#riderInfo > h3.self-service-heading', 3000)

              .saveScreenshot('./reports/rider-self-service-logged-in.png')

              .assert.containsText('#riderInfo > h3.self-service-heading', 'Rider Info');

            done();
          })

        return this;
      },

    // this test is called a driver has been added - it's assumed 
    // app is at driver self service page
    'pauseDriverSelfService' : 
      function pauseDriverSelfService (client) {
        if (client !== undefined && client !== null) {
          this.currentClient = client;
        }

        var self = this;

        var client = this.currentClient;
        var dates = this.dates;
        
        var client = this.currentClient;
        var dates = this.dates;

        var newState = client
          .waitForElementVisible('#btnPauseDriverMatch', 3000)

          .click('#btnPauseDriverMatch')

          .pause(3000)

          .waitForElementNotPresent('', 3000)
          .assert.containsText('#driverInfo > ul', 'PAUSED')

          .saveScreenshot('./reports/driver-pause-notifications.png')

        return this;
      },

    // this test is called a driver has been added - it's assumed 
    // app is at driver self service page
    'cancelDriverSelfService' : 
      function cancelDriverSelfService (client) {
        if (client !== undefined && client !== null) {
          this.currentClient = client;
        }

        var self = this;

        var client = this.currentClient;
        var dates = this.dates;
        
        var client = this.currentClient;
        var dates = this.dates;

        var newState = client
          .waitForElementVisible('#btnCancelDriveOffer', 3000)

          .click('#btnCancelDriveOffer')

          .pause(3000)

          .waitForElementNotPresent('', 3000)
          .assert.containsText('#driverInfo > ul', 'CANCEL')

          .saveScreenshot('./reports/driver-cancel-notifications.png')

        return this;
      }
};
