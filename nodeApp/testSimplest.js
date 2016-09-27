var config = require('./dbInfo.js');

var Pool = require('pg').Pool;
var pool = new Pool(config);

pool.query('SELECT * from "NOV2016"."DRIVER"', (err, res) => {
  res.rows.forEach( val => console.log(val));
});
