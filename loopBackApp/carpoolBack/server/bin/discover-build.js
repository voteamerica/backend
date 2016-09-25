var path = require('path');
var fs = require('fs');
var app = require(path.resolve(__dirname, '../server'));
var outputPath = path.resolve(__dirname, '../../common/models');

var config  = path.resolve(__dirname, '../dbInfo.js');

var loopback = require('loopback');
var dataSource = loopback.createDataSource('PostgreSQL', config);

console.log("ds - " + dataSource.toString());

// var dataSource = app.dataSources.accountDs;

function schemaCB(err, schema) {
  console.log("here");

  if(schema) {
    console.log("Auto discovery success: " + schema.name);
    var outputName = outputPath + '/' +schema.name + '.json';
    fs.writeFile(outputName, JSON.stringify(schema, null, 2), function(err) {
      if(err) {
        console.log(err);
      } else {
        console.log("JSON saved to " + outputName);
      }
    });
  }
  if(err) {
    console.error(err);
    return;
  }
  return;
};

// var tableName = 'RIDER';
var tableName = 'DRIVER';
var schemaName = 'NOV2016';

dataSource.discoverSchema(tableName, {schema: schemaName},schemaCB);