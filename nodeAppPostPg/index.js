'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const Hapi = require("hapi");
const Pool = require('pg').Pool;
const Good = require('good');
const GoodFile = require('good-file');
const es = require('event-stream');
// const {
//   Readable
// ,
// Writable,
// Transform,
// Duplex,
// pipeline,
// finished
// } = require('readable-stream');
console.log('start requires');
// const hapiAuthJwt = require('hapi-auth-jwt');
const Boom = require('boom');
// const Joi         = require('joi');
console.log('end requires');
const hapiAuthJwt = require('./hapi-auth-jwt-local.js');
const config = require('./dbInfo.js');
const logOptions = require('./logInfo.js');
const dbQueries = require('./dbQueries.js');
const routeFns = require('./routeFunctions.js');
const csvImport_1 = require("./csvImport");
const DbQueriesPosts_1 = require("./DbQueriesPosts");
const DbDefsCancels_1 = require("./DbDefsCancels");
const postgresQueries_1 = require("./postgresQueries");
const PostFunctions_1 = require("./PostFunctions");
const RouteNames_1 = require("./RouteNames");
const RouteNames_2 = require("./RouteNames");
const RouteNames_3 = require("./RouteNames");
const RouteNames_4 = require("./RouteNames");
const logging_1 = require("./logging");
const login_1 = require("./login");
let dbQueriesPosts = new DbQueriesPosts_1.DbQueriesPosts();
let dbQueriesCancels = new DbDefsCancels_1.DbQueriesCancels();
let postgresQueries = new postgresQueries_1.PostgresQueries();
let postFunctions = new PostFunctions_1.PostFunctions();
let routeNamesAddDriverRider = new RouteNames_1.RouteNamesAddDriverRider();
let routeNamesSelfService = new RouteNames_2.RouteNamesSelfService();
let routeNamesMatch = new RouteNames_2.RouteNamesMatch();
let routeNamesSelfServiceInfoExists = new RouteNames_3.RouteNamesSelfServiceInfoExists();
let routeNamesCancel = new RouteNames_4.RouteNamesCancel();
let routeNamesUnmatched = new RouteNames_4.RouteNamesUnmatched();
let routeNamesDetails = new RouteNames_4.RouteNamesDetails();
let loggingItem = new logging_1.logging();
config.user = process.env.PGUSER;
config.database = process.env.PGDATABASE;
config.password = process.env.PGPASSWORD;
config.host = process.env.PGHOST;
config.port = process.env.PGPORT;
const jwt_secret = login_1.getJWTSecretFromEnv();
// const pool = new Pool(config);
// not passing config causes Client() to search for env vars
const pool = new Pool();
const server = new Hapi.Server();
routeFns.setPool(pool);
postFunctions.setPool(pool);
const OPS_INTERVAL = 300000; // 5 mins
const DEFAULT_PORT = process.env.PORT || 3000;
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
    method: 'POST',
    path: '/' + routeNamesAddDriverRider.USER_ROUTE,
    handler: postFunctions.postUser
});
server.route({
    method: 'GET',
    path: '/' + routeNamesUnmatched.UNMATCHED_DRIVERS_ROUTE,
    handler: routeFns.getUnmatchedDrivers
});
server.route({
    method: 'GET',
    path: '/' + routeNamesDetails.DRIVERS_DETAILS_ROUTE,
    handler: routeFns.getDriversDetails
});
server.route({
    method: 'GET',
    path: '/' + routeNamesDetails.DRIVER_MATCHES_DETAILS_ROUTE,
    handler: routeFns.getDriverMatchesDetails
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
    handler: (req, reply) => {
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
    handler: (req, reply) => {
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
    handler: (req, reply) => {
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
server.route({
    method: 'GET',
    path: '/users/authenticate',
    config: {
        pre: [
            {
                method: login_1.verifyCredentials,
                assign: 'user'
            }
        ],
        handler: (req, res) => {
            const user = req.pre.user;
            return login_1.createTokenAndRespond(res, user, 200);
        }
        // ,
        // validate: {
        //   payload: authenticateUserSchema
        // }
    }
});
const getUsersListHandler = async (req, res) => {
    const payload = req.query;
    const userInfo = await routeFns.getUsersListInternal(req, res, payload);
    if (!userInfo) {
        return res(Boom.badRequest('get users list error'));
    }
    const userInfoJSON = JSON.stringify(userInfo);
    res({ data: userInfoJSON });
};
const getDriversListHandler = async (req, res) => {
    const payload = req.query;
    const driverInfo = await routeFns.getDriversListInternal(req, res, payload);
    if (!driverInfo) {
        return res(Boom.badRequest('get drivers list error'));
    }
    const driverInfoJSON = JSON.stringify(driverInfo);
    res({ data: driverInfoJSON });
};
const getRidersListHandler = async (req, res) => {
    const payload = req.query;
    const riderInfo = await routeFns.getRidersListInternal(req, res, payload);
    if (!riderInfo) {
        return res(Boom.badRequest('get riders list error'));
    }
    const riderInfoJSON = JSON.stringify(riderInfo);
    res({ data: riderInfoJSON });
};
const getMatchesListHandler = async (req, res) => {
    const payload = req.query;
    const matchInfo = await routeFns.getMatchesListInternal(req, res, payload);
    if (!matchInfo) {
        return res(Boom.badRequest('get matches list error'));
    }
    const matchInfoJSON = JSON.stringify(matchInfo);
    res({ data: matchInfoJSON });
};
const getMatchesOtherDriverListHandler = async (req, res) => {
    const payload = req.query;
    const matchInfo = await routeFns.getMatchesOtherDriverListInternal(req, res, payload);
    if (!matchInfo) {
        return res(Boom.badRequest('get matches other list error'));
    }
    const matchInfoJSON = JSON.stringify(matchInfo);
    res({ data: matchInfoJSON });
};
// const bulkUploadHandler = async (req, res) => {
const bulkUploadHandler = (request, reply) => {
    // const payload = req.query;
    // const matchInfo = await routeFns.getMatchesOtherDriverListInternal(
    //   req,
    //   res,
    //   payload
    // );
    // if (!matchInfo) {
    //   return res(Boom.badRequest('get matches other list error'));
    // }
    // const matchInfoJSON = JSON.stringify(matchInfo);
    // function (request, reply) {
    try {
        const data = request.payload;
        debugger;
        // console.log('data', data);
        console.log('file', data.file);
        // const file = data['avatar']; // accept a field call avatar
        // save the file
        // const fileDetails = await uploader(file, fileOptions);
        // save data to database
        // const col = await loadCollection(COLLECTION_NAME, db);
        // const result = col.insert(fileDetails);
        // db.saveDatabase();
        let string = '';
        let lineNr = 0;
        let ridersCsv = false;
        let driversCsv = false;
        let headerLine = '';
        let parsingStarted = false;
        const s = 
        // fs.createReadStream('very-large-file.csv')
        data.file.pipe(es.split()).pipe(es
            .mapSync(function (line) {
            // pause the readstream
            s.pause();
            debugger;
            lineNr += 1;
            console.log(line);
            if (parsingStarted === false) {
                if (line.indexOf('RiderFirstName') >= 0) {
                    parsingStarted = true;
                    ridersCsv = true;
                    headerLine = line;
                }
                else if (line.indexOf('DriverFirstName') >= 0) {
                    parsingStarted = true;
                    driversCsv = true;
                    headerLine = line;
                }
            }
            else {
                if (ridersCsv) {
                    const data = headerLine + '\n' + line;
                    csvImport_1.uploadRiders(data, 'NAACP', function (err, data) {
                        if (err)
                            console.log(err);
                        console.log('successful upload:', data);
                    });
                }
            }
            // process line here and call s.resume() when rdy
            // function below was for logging memory usage
            // logMemoryUsage(lineNr);
            // resume the readstream, possibly from a callback
            s.resume();
        })
            .on('error', function (err) {
            console.log('Error while reading file.', err);
        })
            .on('end', function () {
            console.log('Read entire file.');
            reply({
            // id: result.$loki,
            // fileName: result.filename,
            // originalName: result.originalname
            });
        }));
        // data.file.on('readable', function(buffer) {
        //   debugger;
        //   if (!buffer) {
        //     return;
        //   }
        //   var part = buffer.read().toString();
        //   string += part;
        //   console.log('stream data ' + part);
        // });
        // data.file.on('data', function(buffer) {
        //   debugger;
        //   if (!buffer) {
        //     return;
        //   }
        //   // var part = buffer.read().toString();
        //   var part = buffer.toString();
        //   string += part;
        //   console.log('stream data ' + part);
        // });
        // data.file.on('end', function() {
        //   debugger;
        //   console.log('final output ' + string);
        //   // return result
        //   reply({
        //     // id: result.$loki,
        //     // fileName: result.filename,
        //     // originalName: result.originalname
        //   });
        //   // }
        // });
    }
    catch (err) {
        // error handling
        reply(Boom.badRequest(err.message, err));
    }
    // res({ data: matchInfoJSON });
};
const usersHandler = getUsersListHandler;
const driversHandler = getDriversListHandler;
const ridersHandler = getRidersListHandler;
const matchesHandler = getMatchesListHandler;
const matchesOtherDriverHandler = getMatchesOtherDriverListHandler;
server.register([
    {
        register: hapiAuthJwt,
        options: {
            state: {
                strictHeader: false,
                ignoreErrors: true
            }
        }
    },
    {
        register: Good,
        options: logOptions
    }
], err => {
    if (err) {
        return console.error(err);
    }
    // only allow use of jwt strategy is valid key was defined
    if (login_1.validJWTSecret()) {
        server.auth.strategy('jwt', 'jwt', {
            key: jwt_secret,
            verifyOptions: { algorithms: ['HS256'] }
        });
        server.route({
            method: 'POST',
            path: '/createuser',
            config: {
                pre: [{ method: login_1.verifyUniqueUser }],
                handler: login_1.createUser,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'GET',
            path: '/users/list',
            config: {
                handler: usersHandler,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'GET',
            path: '/drivers/list',
            config: {
                handler: driversHandler,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'GET',
            path: '/riders/list',
            config: {
                handler: ridersHandler,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'GET',
            path: '/matches/list',
            config: {
                handler: matchesHandler,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'GET',
            path: '/matches-other/list',
            config: {
                handler: matchesOtherDriverHandler,
                auth: {
                    strategy: 'jwt',
                    scope: ['admin']
                }
            }
        });
        server.route({
            method: 'POST',
            path: '/bulk-upload',
            config: {
                payload: {
                    output: 'stream',
                    allow: 'multipart/form-data'
                },
                handler: bulkUploadHandler
                // auth: {
                //   strategy: 'jwt',
                //   scope: ['admin']
                // }
            }
        });
    }
    server.start(err => {
        if (err) {
            throw err;
        }
        console.log(`Server running at: ${server.info.uri} \n`);
        console.log('driver ins: ' + dbQueriesPosts.dbGetSubmitDriverString());
        console.log('rider ins: ' + dbQueriesPosts.dbGetSubmitRiderString());
        console.log('user ins: ' + dbQueriesPosts.dbGetSubmitUserString());
        console.log('cancel ride fn: ' +
            dbQueriesCancels.dbCancelRideRequestFunctionString());
        console.log('reject ride fn: ' + dbQueries.dbRejectRideFunctionString());
        console.log('ops interval:' + logOptions.ops.interval);
    });
});
loggingItem.logReqResp(server, pool);
//# sourceMappingURL=index.js.map