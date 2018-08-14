'use strict';
var DELAY = process.env.CP_DELAY || 10000;
var Pool = require('pg').Pool;
var pool = new Pool({
    idleTimeoutMillis: 60000 //close idle clients after 60 seconds
});


setInterval(function () {
    pool
    .query("select to_char(now(), 'YYYY-MM-DD HH24:MI:SS')  as now, * from carpoolvote.perform_match()")
    .then(function (result) {
    if (result !== undefined && result.rows !== undefined &&
        result.rows.length > 0) {
        result.rows.forEach(function (returned_code_and_error_text) {
            console.log( 
                returned_code_and_error_text['now'] + ' ' 
              + returned_code_and_error_text['out_error_code'] + ' '
              + returned_code_and_error_text['out_error_text']);
        });
    }
})
    .catch(function (e) {
    var message = e.message || '';
    var stack = e.stack || '';
    console.error(message, stack);
});
}, DELAY);


