var common = require('../../common/common.js');

module.exports = {
  'match-rider-driver': function (client) {

    common.matchRiderDriver(client)
      .driverCancelMatch()
      .finish();
  }
};
