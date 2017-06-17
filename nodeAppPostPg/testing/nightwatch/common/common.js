// NOTE: module.exports at end of file

// IMPORTANT: test functions created here are used in a chain. See any files under the tests folder
//            or just think of jQuery functions.

//            There are two ways to write chainable test functions, both are pretty easy. Choice
//            is a matter of personal taste.

//            NOTE: either type of test function is created as part of the testObject below 
//            (in other words, NOT as a global module function).

//            1) create a function in the same pattern as templateTest() below. The initial "var client..."
//               and "return this" must be in place. Your code replaces "client.end()".

//               This pattern has a little boiler-plate but it's short and the pattern is readable.

//            2) create a function using createChainableTest(), e.g. addRider(). This removes boiler-plate
//               except for passing your function to createChainableTest(). Instead of "this", use "testObject".
//               Remember to pass client as a param to your function (as with all nightwatch functions).

function createChainableTest (testFunction) {
  var testFn = function (client) {
      var client = this.setClient(client);
      
      // testFunction(this, client);
      testFunction(client);

      return this;
    };

  return testFn;
}

var testObject = {
  'currentClient' : undefined,

  'dates' : ['2017-08-09'],

  'riderSelfServicePageUrl' : "",

  'setClient' : function (client) {
      if (client !== undefined && client !== null) {
        this.currentClient = client;
      }

      return this.currentClient;
    },

  'templateTest' : 
    function (client) {
      var client = this.setClient(client);
      
      client.end();

      return this;
    },

  'finish' : 
    createChainableTest (
      function (client) {
        client.end();
      }),

  'finishOrig' : 
    function (client) {
      var client = this.setClient(client);
            
      client.end();

      return this;
    },

  'addDriver' : 
    createChainableTest (
    function (client) {
      // var client = this.setClient(client);
      var dates = testObject.dates;

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
        .assert.containsText('h1#thanks-header', 'Thank you');

      // return this;
    }),

  'addRider' : 
    createChainableTest (
      // function (self, client) {
      function (client) {
      var dates = testObject.dates;
      
      // var self = thisx;

      console.log("addRider");
      console.log("dates: ", dates);

      client
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

          // self.riderSelfServicePageUrl = result.value;
          testObject.riderSelfServicePageUrl = result.value;

          // console.log("rider url: ", self.riderSelfServicePageUrl);
          console.log("rider url: ", testObject.riderSelfServicePageUrl);
        });

        // .assert.containsText('div.with-errors ul li', 'Please fill in')
        // .assert.valueContains('div.with-errors ul li', 'Please')

      }),

  'addRiderOrig' : 
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      console.log("addRiderOrig");

      client
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
    createChainableTest (
    function (client) {      
      var dates = testObject.dates;

      client
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
        .assert.containsText('#driverProposedMatches > h3.self-service-heading', 'Driver Proposed Matches');
    }),

  // this test is called after first rider, then driver have been added - it's assumed 
  // app is at driver self service page, with a proposed match visible
  'viewProposedMatch' : 
    createChainableTest (
    function (client) {      
      var dates = testObject.dates;

      client
        // should check for first list item
        .assert.containsText('#driverProposedMatches > ul li', 'UUID_driver')
        .assert.containsText('#driverProposedMatches > ul li.list_button button', 'Accept')

        .waitForElementVisible('#driverProposedMatches > ul li.list_button button', 1000);
    }),

  // this test is called after first rider, then driver have been added - it's assumed 
  // app is at driver self service page, with a proposed match visible
  'acceptMatch' : 
    function (client) {      
      var client = this.setClient(client);
      var dates = this.dates;

      client
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
    function (client) {      
    var client = this.setClient(client);
      var dates = this.dates;

      client
        .click('#driverConfirmedMatches > ul li.list_button button')

        // alert button appears
        // https://stackoverflow.com/questions/35287273/how-to-click-on-alert-box-ok-button-using-nightwatch-js
        .pause(2000)
        .acceptAlert()

        .saveScreenshot('./reports/match-self-service-cancel-match.png')
        
        .waitForElementNotPresent('#driverConfirmedMatches > ul li.list_button button', 3000)

      return this;
    },

  // this test is called after a rider has been added - it's assumed 
  // app is at rider self service page
  'viewRiderSelfService' : 
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      console.log("rider info url 1: ", this.riderSelfServicePageUrl);
      // console.log("rider info url: ", riderUrl);

      client
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
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      client
        .waitForElementVisible('#btnPauseDriverMatch', 3000)

        .click('#btnPauseDriverMatch')

        .pause(3000)

        .waitForElementNotPresent('', 3000)
        .assert.containsText('#driverInfo > ul', 'PAUSED')

        .saveScreenshot('./reports/driver-pause-notifications.png')

      return this;
    },

  // this test is called after a driver has been added - it's assumed 
  // app is at driver self service page
  'cancelDriverSelfService' : 
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      client
        .waitForElementVisible('#btnCancelDriveOffer', 3000)

        .click('#btnCancelDriveOffer')

        .pause(2000)
        .acceptAlert()
        .pause(3000)

        .assert.containsText('#driverInfo > ul', 'CANCEL')

        .saveScreenshot('./reports/driver-cancel-offer.png')

      return this;
    },

  // this test is called after a rider has been added - it's assumed 
  // app is at rider self service page
  'cancelRiderSelfService' : 
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      client
        .waitForElementVisible('#btnCancelRideRequest', 3000)

        .click('#btnCancelRideRequest')

        .pause(2000)
        .acceptAlert()
        .pause(3000)

        .assert.containsText('#riderInfo > ul', 'CANCEL')

        .saveScreenshot('./reports/rider-cancel-request.png')

      return this;
    },

  // this test is run at the start
  'matchRiderDriver': 
    function (client) {
      var client = this.setClient(client);
      var dates = this.dates;
      
      var self = this;

      this
        .addRider(client)
        .addDriver()
        .viewDriverSelfService()
        .viewProposedMatch().acceptMatch().driverCancelMatch();

      return this;
  }
};

module.exports = testObject;
