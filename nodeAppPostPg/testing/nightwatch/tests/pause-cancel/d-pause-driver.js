var common = require('../../common/common.js');

module.exports = {
  'rider-self_svc': function (client) {

    common
      .addDriver(client)
      .viewDriverSelfService()
      .pauseDriverSelfService()
      .cancelDriverSelfService()
      .finish();
  }
};
