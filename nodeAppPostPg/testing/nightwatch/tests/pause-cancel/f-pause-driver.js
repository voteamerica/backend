var common = require('../../common/common.js');

module.exports = {
  'driver-pause-cancel': function (client) {

    common
      .addDriver(client)
      .viewDriverSelfService()
      .pauseDriverSelfService()
      .cancelDriverSelfService()
      .addRider()
      .viewRiderSelfService()
      .cancelRiderSelfService()      
      .finish();
  }
};
