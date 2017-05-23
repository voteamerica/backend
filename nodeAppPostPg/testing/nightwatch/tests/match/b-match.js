var common = require('../../common/common.js');

module.exports = {
  'rider-driver': function (client) {

    common.addRider(client).addDriver().finish();
  }
};
