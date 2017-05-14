module.exports = {
  'basic': function (client) {
    client
      .url('http://10.5.0.4:4000')
      // .url(client.launch_url)
      .waitForElementVisible('body', 3000)
      .assert.containsText('.support-banner', 'Carpool Vote')
      .assert.cssClassNotPresent('#fb-root', 'xxx')
      .end();
  }
};