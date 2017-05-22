var common = require('../../common/common.js');

module.exports = {
  'rider': function (client) {
    const dates = ['2017-08-09'];

    common.finish(common.addDriver(common.addRider(client, dates), dates));
  }
};
