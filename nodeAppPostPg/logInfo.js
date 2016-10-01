module.exports = {
  includes: {
    request:  ['headers', 'payload'],
    response: ['payload']
  },  
  ops: {
      // overridden in main app
      interval: 60000
  },
  reporters: {
    consoleReporter: [
      {
        module: 'good-squeeze',
        name: 'Squeeze',
        args: [{ 
          ops: '*', 
          error: '*',
          request: '*',
          log: '*', 
          response: '*' 
        }]
      }, 
      { 
          module: 'good-console'
      }, 
      'stdout'
    ]
    ,
    fileReporter: [{
        module: 'good-squeeze',
        name: 'Squeeze',
        args: [{ 
          ops: '*', 
          error: '*',
          request: '*',
          log: '*', 
          response: '*'
        }]
      }, 
      {
          module: 'good-squeeze',
          name: 'SafeJson',
          args: [
              null,
              { separator: ', \n' }
          ]
      }, 
      {
          module: 'good-file',
          args: ['./cp_web_log']
      }
    ]
  }
};