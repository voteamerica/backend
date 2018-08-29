var common = require('../../common/common.js');

module.exports = {
  'full-match-pause': function (client) {

    common.matchRiderDriver(client)
      .driverCancelMatch()
      
      .nextDate()
      .addDriver()
      .viewDriverSelfService()
      .pauseDriverSelfService()
      .cancelDriverSelfService()
      .addRider()
      .viewRiderSelfService()
      .cancelRiderSelfService()      

      .nextDate()
      .matchRiderDriver()
      .viewRiderSelfService()
      .viewRiderMatch()
      .riderCancelMatch()
      
      .viewOperatorPage()
      .finish();
  }
};