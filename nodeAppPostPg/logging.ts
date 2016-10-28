// module.exports = {
//   logReqResp: logReqResp
// }

export interface CustomLog {
  logReqResp (server: Any, pool: Any): Any
}

function logReqResp(server, pool) {

  server.on('request', (request, event, tags) => {

    // Include the Requestor's IP Address on every log
    if( !event.remoteAddress ) {
      event.remoteAddress = request.headers['x-forwarded-for'] || request.info.remoteAddress;
    }

    // Put the first part of the URL into the tags
    if(request && request.url && event && event.tags) {
      event.tags.push(request.url.path.split('/')[1]);
    }

    console.log('server req: %j', event) ;
  });

  server.on('response', (request) => {  
    console.log(
        "server resp: " 
      + request.info.remoteAddress 
      + ': ' + request.method.toUpperCase() 
      + ' ' + request.url.path 
      + ' --> ' + request.response.statusCode);
  });

  pool.on('error', (err, client) => {
    if (err) {
      console.error("db err: " + err);
    } 
  });
}