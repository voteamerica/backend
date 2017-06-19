var common = require('../../common/common.js');

module.exports = {
  'match-rider-cancel': function (client) {

    common.nextDate(client)
      .matchRiderDriver()
      .viewRiderSelfService()
      .finish();
  }
};
