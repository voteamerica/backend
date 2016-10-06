'use strict';
var DELAY = process.env.CP_DELAY || 10000;
var Pool = require('pg').Pool;
var pool = new Pool({
    idleTimeoutMillis: 2000 //close idle clients after 1 second
});
var SCHEMA_NAME = 'stage';
var SWEEPER_FUNCTION = 'create_riders()';
setInterval(function () {
    dbGetData(pool, dbGetNewItemsQueryString);
}, DELAY);
function dbGetNewItemsQueryString() {
    return 'select ' + SCHEMA_NAME + '.' + SWEEPER_FUNCTION;
}
function dbGetData(pool, fnGetString) {
    var queryString = fnGetString();
    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            // result.rows.forEach( val => console.log(val));
            result.rows.forEach(function (val) { return console.log("select: " + JSON.stringify(val)); });
            firstRowAsString = JSON.stringify(result.rows[0]);
        }
        console.error("executed query: " + firstRowAsString);
        // reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(
        // results.failure, 
        message, stack);
        // reply(results.failure + message).code(500);
    });
}
//# sourceMappingURL=index.js.map