
module.exports = {
  user: 'user', //env var: PGUSER
  database: 'db', //env var: PGDATABASE
  password: 'pwd', //env var: PGPASSWORD
  host: 'host', // Server hosting the postgres database
  port: 5432, //env var: PGPORT
  max: 10, // max number of clients in the pool
  idleTimeoutMillis: 30000, // how long a client is allowed to remain idle before being closed
};