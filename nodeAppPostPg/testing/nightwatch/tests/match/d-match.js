var common = require('../../common/common.js');

module.exports = {
  'match-rider-driver': function (client) {

    common.addRider(client).addDriver()
      .viewDriverSelfService()
      .viewProposedMatch().acceptMatch().driverCancelMatch().finish();
  }
};
