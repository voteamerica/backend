'use strict';
var Hapi = require('hapi');
var moment = require('moment');
var Pool = require('pg').Pool;
var Good = require('good');
var GoodFile = require('good-file');
var config = require('./dbInfo.js');
var logOptions = require('./logInfo.js');
var dbQueries = require('./dbQueries.js');
var logging = require('./logging.js');
var postgresQueries = require('./postgresQueries.js');
var routeFns = require('./routeFunctions.js');
config.user = process.env.PGUSER;
config.database = process.env.PGDATABASE;
config.password = process.env.PGPASSWORD;
config.host = process.env.PGHOST;
config.port = process.env.PGPORT;
// const pool = new Pool(config);
// not passing config causes Client() to search for env vars
var pool = new Pool();
var server = new Hapi.Server();
routeFns.setPool(pool);
var OPS_INTERVAL = 300000; // 5 mins
var DEFAULT_PORT = process.env.PORT || 3000;
var appPort = DEFAULT_PORT;
logOptions.ops.interval = OPS_INTERVAL;
server.connection({
    port: appPort,
    routes: {
        cors: true
    }
});
server.route({
    method: 'GET',
    path: '/',
    handler: function (req, reply) {
        var results = {
            success: 'GET carpool: ',
            failure: 'GET error: '
        };
        req.log();
        postgresQueries.dbGetData(pool, dbQueries.dbGetQueryString, reply, results);
    }
});
server.route({
    method: 'GET',
    path: '/matches',
    handler: function (req, reply) {
        var results = {
            success: 'GET matches: ',
            failure: 'GET matches: '
        };
        req.log();
        postgresQueries.dbGetMatchesData(pool, dbQueries.dbGetMatchesQueryString, reply, results);
    }
});
server.route({
    method: 'GET',
    path: '/match-rider/{uuid}',
    handler: function (req, reply) {
        var results = {
            success: 'GET match-rider: ',
            failure: 'GET match-rider: '
        };
        req.log();
        postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchRiderQueryString, req.params.uuid, reply, results);
    }
});
server.route({
    method: 'GET',
    path: '/match-driver/{uuid}',
    handler: function (req, reply) {
        var results = {
            success: 'GET match-driver: ',
            failure: 'GET match-driver: '
        };
        req.log();
        postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchDriverQueryString, req.params.uuid, reply, results);
    }
});
server.route({
    method: 'POST',
    path: '/' + routeFns.DRIVER_ROUTE,
    handler: routeFns.postDriver
});
server.route({
    method: 'POST',
    path: '/' + routeFns.RIDER_ROUTE,
    handler: routeFns.postRider
});
server.route({
    method: 'POST',
    path: '/' + routeFns.HELPER_ROUTE,
    handler: routeFns.postHelper
});
server.route({
    method: 'DELETE',
    path: '/' + routeFns.DELETE_RIDER_ROUTE,
    handler: routeFns.cancelRider
});
server.route({
    method: 'DELETE',
    path: '/' + routeFns.DELETE_DRIVER_ROUTE,
    handler: routeFns.cancelRideOffer
});
server.route({
    method: 'PUT',
    path: '/' + routeFns.PUT_RIDER_ROUTE,
    handler: routeFns.rejectRide
});
server.route({
    method: 'PUT',
    path: '/' + routeFns.PUT_DRIVER_ROUTE,
    handler: routeFns.confirmRide
});
server.register({
    register: Good,
    options: logOptions
}, function (err) {
    if (err) {
        return console.error(err);
    }
    server.start(function (err) {
        if (err) {
            throw err;
        }
        console.log("Server running at: " + server.info.uri + " \n");
        console.log("driver ins: " + dbQueries.dbGetInsertDriverString());
        console.log("rider ins: " + dbQueries.dbGetInsertRiderString());
        console.log("cancel ride fn: " + dbQueries.dbCancelRideFunctionString());
        console.log("reject ride fn: " + dbQueries.dbRejectRideFunctionString());
        console.log("ops interval:" + logOptions.ops.interval);
    });
});
logging.logReqResp(server, pool);
//# sourceMappingURL=index.js.map