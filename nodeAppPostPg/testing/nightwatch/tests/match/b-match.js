var common = require('../../common/common.js');

module.exports = {
  'rider': function (client) {

    (common.addRider(client)).addDriver().finish();
  }
};
