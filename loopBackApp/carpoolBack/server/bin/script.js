var loopback = require('loopback');

var config  = path.resolve(__dirname, '../dbInfo.js');

var ds = loopback.createDataSource('PostgreSQL', config);
  
// Discover and build models from DRIVER table
ds.discoverAndBuildModels('DRIVER', {visited: {}, associations: true},
function (err, models) {
  // Now we have a list of models keyed by the model name
  // Find the first record from the inventory
  models.Inventory.findOne({}, function (err, inv) {
    if(err) {
      console.error(err);
      return;
    }
    console.log("\nDriver: ", inv);
    
    // Navigate to the product model
    inv.product(function (err, prod) {
      console.log("\nProduct: ", prod);
      console.log("\n ------------- ");
    });
  });
});
