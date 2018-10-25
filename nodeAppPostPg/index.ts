'use strict';

import * as Hapi from 'hapi';
const Pool = require('pg').Pool;
import Good = require('good');
import GoodFile = require('good-file');

import es = require('event-stream');

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

import { uploadRidersOrDrivers } from './csvImport';

import { DbQueriesPosts } from './DbQueriesPosts';
import { DbQueriesCancels } from './DbDefsCancels';

import { PostgresQueries } from './postgresQueries';
import { PostFunctions } from './PostFunctions';
import { RouteNamesAddDriverRider } from './RouteNames';
import {
  RouteNamesSelfService,
  RouteNamesMatch
  // , RouteNamesChange
} from './RouteNames';
import { RouteNamesSelfServiceInfoExists } from './RouteNames';
import {
  RouteNamesCancel,
  RouteNamesUnmatched,
  RouteNamesDetails
} from './RouteNames';
import { logging } from './logging';

import {
  verifyUniqueUser,
  verifyCredentials,
  createUser,
  createTokenAndRespond,
  validJWTSecret,
  getJWTSecretFromEnv
} from './login';

let dbQueriesPosts = new DbQueriesPosts();
let dbQueriesCancels = new DbQueriesCancels();

let postgresQueries = new PostgresQueries();
let postFunctions = new PostFunctions();
let routeNamesAddDriverRider = new RouteNamesAddDriverRider();
let routeNamesSelfService = new RouteNamesSelfService();
let routeNamesMatch = new RouteNamesMatch();
let routeNamesSelfServiceInfoExists = new RouteNamesSelfServiceInfoExists();
let routeNamesCancel = new RouteNamesCancel();
let routeNamesUnmatched = new RouteNamesUnmatched();
let routeNamesDetails = new RouteNamesDetails();
let loggingItem = new logging();

config.user = process.env.PGUSER;
config.database = process.env.PGDATABASE;
config.password = process.env.PGPASSWORD;
config.host = process.env.PGHOST;
config.port = process.env.PGPORT;

const jwt_secret = getJWTSecretFromEnv();

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

    postgresQueries.dbGetMatchesData(
      pool,
      dbQueries.dbGetMatchesQueryString,
      reply,
      results
    );
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

    postgresQueries.dbGetMatchSpecificData(
      pool,
      dbQueries.dbGetMatchRiderQueryString,
      req.params.uuid,
      reply,
      results
    );
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

    postgresQueries.dbGetMatchSpecificData(
      pool,
      dbQueries.dbGetMatchDriverQueryString,
      req.params.uuid,
      reply,
      results
    );
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
        method: verifyCredentials,
        assign: 'user'
      }
    ],
    handler: (req, reply) => {
      const user = req.pre.user;

      return createTokenAndRespond(reply, user, 200);
    }

    // ,
    // validate: {
    //   payload: authenticateUserSchema
    // }
  }
});

const getUsersListHandler = async (req, reply) => {
  const payload = req.query;

  const userInfo = await routeFns.getUsersListInternal(req, reply, payload);

  if (!userInfo) {
    return reply(Boom.badRequest('get users list error'));
  }

  const userInfoJSON = JSON.stringify(userInfo);

  reply({ data: userInfoJSON });
};

const getDriversListHandler = async (req, reply) => {
  const payload = req.query;

  const driverInfo = await routeFns.getDriversListInternal(req, reply, payload);

  if (!driverInfo) {
    return reply(Boom.badRequest('get drivers list error'));
  }

  const driverInfoJSON = JSON.stringify(driverInfo);

  reply({ data: driverInfoJSON });
};

const getRidersListHandler = async (req, reply) => {
  const payload = req.query;

  const riderInfo = await routeFns.getRidersListInternal(req, reply, payload);

  if (!riderInfo) {
    return reply(Boom.badRequest('get riders list error'));
  }

  const riderInfoJSON = JSON.stringify(riderInfo);

  reply({ data: riderInfoJSON });
};

const getMatchesListHandler = async (req, reply) => {
  const payload = req.query;

  const matchInfo = await routeFns.getMatchesListInternal(req, reply, payload);

  if (!matchInfo) {
    return reply(Boom.badRequest('get matches list error'));
  }

  const matchInfoJSON = JSON.stringify(matchInfo);

  reply({ data: matchInfoJSON });
};

const getMatchesOtherDriverListHandler = async (req, reply) => {
  const payload = req.query;

  const matchInfo = await routeFns.getMatchesOtherDriverListInternal(
    req,
    reply,
    payload
  );

  if (!matchInfo) {
    return reply(Boom.badRequest('get matches other list error'));
  }

  const matchInfoJSON = JSON.stringify(matchInfo);

  reply({ data: matchInfoJSON });
};

const bulkUploadHandler = async (request, reply) => {
  try {
    const data = request.payload;
    const payload = request.query;

    debugger;

    console.log('file', data.file);

    const userInfo = await routeFns.getUserOrganizationInternal(
      request,
      reply,
      payload
    );

    if (!userInfo) {
      return reply(Boom.badRequest('bulk upload error'));
    }

    uploadRidersOrDrivers(data.file, 'NAACP', function(err, data) {
      if (err) {
        console.log(err);

        const { error, type } = err;

        return reply({
          err,
          error,
          type
        });
      }

      console.log('successful upload:', data);

      return reply(data);
    });
  } catch (err) {
    reply(Boom.badRequest(err.message, err));
  }
};

const usersHandler = getUsersListHandler;
const driversHandler = getDriversListHandler;
const ridersHandler = getRidersListHandler;
const matchesHandler = getMatchesListHandler;
const matchesOtherDriverHandler = getMatchesOtherDriverListHandler;

server.register(
  [
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
  ],
  err => {
    if (err) {
      return console.error(err);
    }

    // only allow use of jwt strategy is valid key was defined
    if (validJWTSecret()) {
      server.auth.strategy('jwt', 'jwt', {
        key: jwt_secret,
        verifyOptions: { algorithms: ['HS256'] }
      });

      server.route({
        method: 'POST',
        path: '/createuser',
        config: {
          pre: [{ method: verifyUniqueUser }],
          handler: createUser,
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
          handler: bulkUploadHandler,
          auth: {
            strategy: 'jwt',
            scope: ['admin']
          }
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
      console.log(
        'cancel ride fn: ' +
          dbQueriesCancels.dbCancelRideRequestFunctionString()
      );
      console.log('reject ride fn: ' + dbQueries.dbRejectRideFunctionString());
      console.log('ops interval:' + logOptions.ops.interval);
    });
  }
);

loggingItem.logReqResp(server, pool);
