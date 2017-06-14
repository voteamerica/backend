var common = require('../../common/common.js');

module.exports = {
  'rider-self_svc': function (client) {

    common
      .testAddRider(client)
      .viewRiderSelfService()
      // .finish();
      .testFinish();
  }
};
