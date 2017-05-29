export interface CustomLog {
  logReqResp (server: any, pool: any): any;
}

export { logging };

// lower case class name to avoid git rename issues 
class logging implements CustomLog {

  logReqResp(server: any, pool: any): any {

    server.on('request', (request: any, event: any, tags: any) => {

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

    server.on('response', (request: any) => {  
      console.log(
          "server resp: " 
        + request.info.remoteAddress 
        + ': ' + request.method.toUpperCase() 
        + ' ' + request.url.path 
        + ' --> ' + request.response.statusCode);
    });

    pool.on('error', (err: any, client: any) => {
      if (err) {
        console.error("db err: " + err);
      } 
    });
  }
}
