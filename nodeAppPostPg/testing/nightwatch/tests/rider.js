module.exports = {
  'rider': function (client) {
    client
      .url('http://10.5.0.4:4000/#need-ride')
      .waitForElementVisible('body', 3000)
      .assert.containsText('legend', 'Your trip')
      .assert.cssClassPresent('#RiderAvailableTimes', 'available-times')
      .setValue('input[name="RiderDate"]', '2017-05-12')
      .setValue('input[id="riderCollectionAddress"]', '1 high st')
      // .assert.containsText('input[id="riderCollectionAddress"]', '1 high st')
      .assert.valueContains('input[id="riderCollectionAddress"]', '1')
      // .click('button[id="needRideSubmit"]')
      // .assert.containsText('div.with-errors ul li', 'Please fill in')
      // .assert.valueContains('div.with-errors ul li', 'Please')
      .end();
  }
};
