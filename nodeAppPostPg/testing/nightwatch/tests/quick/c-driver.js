var common = require('../../common/common.js');

module.exports = {
  'driver': function (client) {

    common.addDriver(client).finish();
  }
};
