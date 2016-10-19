module.exports = {
    dbGetData: dbGetData,
    dbGetUnmatchedDrivers: dbGetUnmatchedDrivers,
    dbGetMatchesData: dbGetMatchesData,
    dbGetMatchSpecificData: dbGetMatchSpecificData,
    dbInsertData: dbInsertData,
    dbExecuteFunction: dbExecuteFunction
};
function dbGetData(pool, fnGetString, reply, results) {
    var queryString = fnGetString();
    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            // result.rows.forEach( val => console.log(val));
            firstRowAsString = JSON.stringify(result.rows[0]);
        }
        reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(results.failure, message, stack);
        reply(results.failure + message).code(500);
    });
}
function dbGetUnmatchedDrivers(pool, fnGetString, reply, results) {
    var queryString = fnGetString();
    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        var rowsToSend = [];
        if (result !== undefined && result.rows !== undefined) {
            result.rows.forEach(function (val) {
                rowsToSend.push(val);
            });
        }
        console.log("unmatched drivers: ", rowsToSend);
        reply(rowsToSend);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(results.failure, message, stack);
        reply(results.failure + message).code(500);
    });
}
function dbGetMatchesData(pool, fnGetString, reply, results) {
    var queryString = fnGetString();
    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            result.rows.forEach(function (val) {
                firstRowAsString += JSON.stringify(val);
            });
            console.log(JSON.stringify(result.rows[0]));
        }
        reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(results.failure, message, stack);
        reply(results.failure + message).code(500);
    });
}
function dbGetMatchSpecificData(pool, fnGetString, uuid, reply, results) {
    var queryString = fnGetString(uuid);
    console.log('match rider query: ' + queryString);
    pool.query(queryString)
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            result.rows.forEach(function (val) {
                firstRowAsString += JSON.stringify(val);
            });
            console.log(JSON.stringify(result.rows[0]));
        }
        reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(results.failure, message, stack);
        reply(results.failure + message).code(500);
    });
}
function dbInsertData(payload, pool, fnInsertString, fnPayloadArray, req, reply, results) {
    var insertString = fnInsertString();
    pool.query(insertString, fnPayloadArray(req, payload))
        .then(function (result) {
        var displayResult = result || '';
        var uuid = "";
        try {
            displayResult = JSON.stringify(result);
            uuid = result.rows[0].UUID;
            console.error('row: ' + JSON.stringify(result.rows[0]));
        }
        catch (err) {
            console.error('no uuid returned');
        }
        console.log('insert: ', uuid + ' ' + displayResult);
        if (payload._redirect) {
            reply.redirect(payload._redirect + '?uuid=' + uuid.toString());
        }
        else {
            reply(results.success + ': ' + uuid);
        }
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error('query error: ', message, stack);
        reply(results.failure + ': ' + message).code(500);
    });
}
function dbExecuteFunction(payload, pool, fnExecuteFunctionString, fnPayloadArray, req, reply, results) {
    var queryString = fnExecuteFunctionString();
    console.log("executeFunctionString: " + queryString);
    pool.query(queryString, fnPayloadArray(req, payload))
        .then(function (result) {
        var firstRowAsString = "";
        if (result !== undefined && result.rows !== undefined) {
            // result.rows.forEach( val => console.log(val));
            result.rows.forEach(function (val) { return console.log("exec fn: " + JSON.stringify(val)); });
            firstRowAsString = JSON.stringify(result.rows[0]);
        }
        console.error("executed fn: " + firstRowAsString);
        reply(results.success + firstRowAsString);
    })
        .catch(function (e) {
        var message = e.message || '';
        var stack = e.stack || '';
        console.error(
        // results.failure, 
        message, stack);
        reply(results.failure + message).code(500);
    });
}
//# sourceMappingURL=postgresQueries.js.map