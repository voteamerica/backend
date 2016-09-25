'use strict';

const Hapi = require('hapi');

var config = require('./dbInfo.js');

var Pool = require('pg').Pool;
var pool = new Pool(config);

const server = new Hapi.Server();

const DEFAULT_PORT = 8000;
const SCHEMA_NAME = '"NOV2016"';
const DRIVER_TABLE = '"DRIVER"';

if (process.env.NODE_ENV !== undefined) {
  console.error("NODE_ENV exists");

  if (process.env.NODE_ENV === "production") {
    console.error("NODE_ENV = production");

    appPort = process.env.PORT;
  }
  else if (process.env.NODE_ENV === "development") {
    console.error("NODE_ENV = development");
  }
  else {
    console.error("NODE_ENV = other");
  }
}
else {
  console.error("no NODE_ENV found");
}

server.connection({ port: DEFAULT_PORT });

var rowId = 8;

server.route({
  method: 'GET',
  path: '/',
  handler: (req, reply) => {

    console.log(req.payload);

    pool.query('SELECT * FROM ' + SCHEMA_NAME + '.' + DRIVER_TABLE, (err, result) => {
      result.rows.forEach( val => console.log(val));

      reply('get received at carpool' + JSON.stringify(result.rows[0]));
    });
  }
});

server.route({
  method: 'POST',
  path: '/',
  handler: (req, reply) => {

    console.log(req.payload);

//     'INSERT INTO "NOV2016"."DRIVER"(Name, Phone, Email, EmailValidated, RideDate, RideTimeStart, RideTimeEnd, State, City, Origin, RiderDestination, Capability, Seats, DriverHasInsurance, Notes, Active, CreatedTimestamp, CreatedBy, ModifiedTimestamp, ModifiedBy) 
// values('George', '602-481-6000', 'testing2@ericanderson.com', '0', '2016-09-01T00:00:00.000Z', '12:00:00+00', '13:00:00+00', 'IL', 'CHICAGO', 'THE L2', 'THE POLLS', 'TBD', 4, '1',
//              'Notes on driver', '1', '2016-09-21T00:48:32.055Z', 'SYSTEM', '2016-09-21T00:48:32.055Z', 'SYSTEM')
             
// INSERT INTO "NOV2016"."DRIVER"
// values(3, 'Bill', '602-481-6000', 'testing2@ericanderson.com', '0', '2016-09-01T00:00:00.000Z', '12:00:00+00', '13:00:00+00', 'IL', 'CHICAGO', 'THE L2', 'THE POLLS', 'TBD', 4, '1',
//              'Notes on driver', '1', '2016-09-21T00:48:32.055Z', 'SYSTEM', '2016-09-21T00:48:32.055Z', 'SYSTEM')
             

    pool.query({
    // name: 'insert driver',
    // text: 'INSERT INTO "NOV2016"."DRIVER"(Id, Name, Phone, Email, EmailValidated, RideDate, RideTimeStart, RideTimeEnd, State, City, Origin, RiderDestination, Capability, Seats, DriverHasInsurance, Notes, Active, CreatedTimestamp, CreatedBy, ModifiedTimestamp, ModifiedBy) values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)',
    // values: [4, 'George', '602-481-6000', 'testing2@ericanderson.com', '0', '2016-09-01T00:00:00.000Z', '12:00:00+00', '13:00:00+00', 'IL', 'CHICAGO', 'THE L2', 'THE POLLS', 'TBD', 4, '1',
    //          'Notes on driver', '1', '2016-09-21T00:48:32.055Z', 'SYSTEM', '2016-09-21T00:48:32.055Z', 'SYSTEM']

    // text: 'INSERT INTO "NOV2016"."DRIVER" values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)',
    // values: [4, 'George', '602-481-6000', 'testing2@ericanderson.com', '0', '2016-09-01T00:00:00.000Z', '12:00:00+00', '13:00:00+00', 'IL', 'CHICAGO', 'THE L2', 'THE POLLS', 'TBD', 4, '1',
    //          'Notes on driver', '1', '2016-09-21T00:48:32.055Z', 'SYSTEM', '2016-09-21T00:48:32.055Z', 'SYSTEM']

    text: 'INSERT INTO ' + SCHEMA_NAME + '.' + DRIVER_TABLE + ' values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)',
    values: [rowId++, 'George', '602-481-6000', 'testing2@ericanderson.com', '0', '2016-09-01T00:00:00.000Z', '12:00:00+00', '13:00:00+00', 'IL', 'CHICAGO', 'THE L2', 'THE POLLS', 'TBD', 4, '1',
             'Notes on driver', '1', '2016-09-21T00:48:32.055Z', 'SYSTEM', '2016-09-21T00:48:32.055Z', 'SYSTEM']

//  DriverID: 2,
//   Name: 'John Smith',
//   Phone: '602-481-6000',
//   Email: 'testing2@ericanderson.com',
//   EmailValidated: '0',
//   RideDate: 2016-09-01T00:00:00.000Z,
//   RideTimeStart: '16:00:00+00',
//   RideTimeEnd: '17:00:00+00',
//   State: 'IL',
//   City: 'CHICAGO',
//   Origin: 'THE L',
//   RiderDestination: 'THE POLLS',
//   Capability: 'TBD',
//   Seats: 3,
//   DriverHasInsurance: '1',
//   Notes: 'Notes Go Here',
//   Active: '1',
//   CreatedTimestamp: 2016-09-21T00:48:32.055Z,
//   CreatedBy: 'SYSTEM',
//   ModifiedTimestamp: 2016-09-21T00:48:32.055Z,
//   ModifiedBy: 'SYSTEM'

});

    reply('row inserted');
  }
});

server.start((err) => {

    if (err) {
        throw err;
    }
    console.log(`Server running at: ${server.info.uri}`);
});