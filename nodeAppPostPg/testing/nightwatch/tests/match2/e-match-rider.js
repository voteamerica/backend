var common = require('../../common/common.js');

module.exports = {
  'rider-self_svc': function (client) {

    common
      .addRider(client)
      .viewRiderSelfService()
      .finish();
  }
};
