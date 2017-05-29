'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
var Hapi = require("hapi");
var Pool = require('pg').Pool;
var Good = require('good');
var GoodFile = require('good-file');
var config = require('./dbInfo.js');
var logOptions = require('./logInfo.js');
var dbQueries = require('./dbQueries.js');
var routeFns = require('./routeFunctions.js');
var postgresQueries_1 = require("./postgresQueries");
var PostFunctions_1 = require("./PostFunctions");
var RouteNames_1 = require("./RouteNames");
var RouteNames_2 = require("./RouteNames");
var RouteNames_3 = require("./RouteNames");
var RouteNames_4 = require("./RouteNames");
var logging_1 = require("./logging");
var postgresQueries = new postgresQueries_1.PostgresQueries();
var postFunctions = new PostFunctions_1.PostFunctions();
var routeNamesAddDriverRider = new RouteNames_1.RouteNamesAddDriverRider();
var routeNamesSelfService = new RouteNames_2.RouteNamesSelfService();
var routeNamesMatch = new RouteNames_2.RouteNamesMatch();
var routeNamesSelfServiceInfoExists = new RouteNames_3.RouteNamesSelfServiceInfoExists();
var routeNamesCancel = new RouteNames_4.RouteNamesCancel();
var routeNamesUnmatched = new RouteNames_4.RouteNamesUnmatched();
var loggingItem = new logging_1.logging();
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
postFunctions.setPool(pool);
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
    handler: routeFns.getAnon
});
server.route({
    method: 'POST',
    path: '/' + routeNamesAddDriverRider.DRIVER_ROUTE,
    handler: postFunctions.postDriver
});
server.route({
    method: 'POST',
    path: '/' + routeNamesAddDriverRider.RIDER_ROUTE,
    handler: postFunctions.postRider
});
server.route({
    method: 'POST',
    path: '/' + routeNamesAddDriverRider.HELPER_ROUTE,
    handler: postFunctions.postHelper
});
server.route({
    method: 'GET',
    path: '/' + routeNamesUnmatched.UNMATCHED_DRIVERS_ROUTE,
    handler: routeFns.getUnmatchedDrivers
});
server.route({
    method: 'GET',
    path: '/' + routeNamesUnmatched.UNMATCHED_RIDERS_ROUTE,
    handler: routeFns.getUnmatchedRiders
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfServiceInfoExists.DRIVER_EXISTS_ROUTE,
    handler: routeFns.driverExists
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfServiceInfoExists.DRIVER_INFO_ROUTE,
    handler: routeFns.driverInfo
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfService.DRIVER_PROPOSED_MATCHES_ROUTE,
    handler: routeFns.driverProposedMatches
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfService.DRIVER_CONFIRMED_MATCHES_ROUTE,
    handler: routeFns.driverConfirmedMatches
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfServiceInfoExists.RIDER_EXISTS_ROUTE,
    handler: routeFns.riderExists
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfServiceInfoExists.RIDER_INFO_ROUTE,
    handler: routeFns.riderInfo
});
server.route({
    method: 'GET',
    path: '/' + routeNamesSelfService.RIDER_CONFIRMED_MATCH_ROUTE,
    handler: routeFns.riderConfirmedMatch
});
server.route({
    method: 'GET',
    path: '/matches',
    handler: function (req, reply) {
        var results = {
            success: 'GET matches: ',
            failure: 'GET matches: '
        };
        req.log(['request']);
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
        req.log(['request']);
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
        req.log(['request']);
        postgresQueries.dbGetMatchSpecificData(pool, dbQueries.dbGetMatchDriverQueryString, req.params.uuid, reply, results);
    }
});
server.route({
    method: 'GET',
    // method: 'POST',
    path: '/' + routeNamesCancel.CANCEL_RIDE_REQUEST_ROUTE,
    handler: routeFns.cancelRideRequest
});
server.route({
    method: 'GET',
    path: '/' + routeNamesMatch.CANCEL_RIDER_MATCH_ROUTE,
    handler: routeFns.cancelRiderMatch
});
server.route({
    method: 'GET',
    path: '/' + routeNamesCancel.CANCEL_DRIVE_OFFER_ROUTE,
    handler: routeFns.cancelDriveOffer
});
server.route({
    method: 'GET',
    path: '/' + routeNamesMatch.CANCEL_DRIVER_MATCH_ROUTE,
    handler: routeFns.cancelDriverMatch
});
server.route({
    method: 'GET',
    path: '/' + routeNamesMatch.ACCEPT_DRIVER_MATCH_ROUTE,
    handler: routeFns.acceptDriverMatch
});
server.route({
    method: 'GET',
    path: '/' + routeNamesMatch.PAUSE_DRIVER_MATCH_ROUTE,
    handler: routeFns.pauseDriverMatch
});
// server.route({
//   method: 'DELETE',
//   path: '/' + routeNamesChange.DELETE_DRIVER_ROUTE,
//   handler: routeFns.cancelRideOffer
// });
// server.route({
//   method: 'PUT',
//   path: '/' + routeNamesChange.PUT_RIDER_ROUTE,
//   handler: routeFns.rejectRide
// });
// server.route({
//   method: 'PUT',
//   path: '/' + routeNamesChange.PUT_DRIVER_ROUTE,
//   handler: routeFns.confirmRide
// });
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
        console.log("driver ins: " + dbQueries.dbGetSubmitDriverString());
        console.log("rider ins: " + dbQueries.dbGetSubmitRiderString());
        console.log("cancel ride fn: " + dbQueries.dbCancelRideRequestFunctionString());
        console.log("reject ride fn: " + dbQueries.dbRejectRideFunctionString());
        console.log("ops interval:" + logOptions.ops.interval);
    });
});
loggingItem.logReqResp(server, pool);
//# sourceMappingURL=index.js.map