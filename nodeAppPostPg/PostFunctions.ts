export { PostFunctions };

import { PostgresQueries }  from "./postgresQueries";
let postgresQueries = new PostgresQueries();

class PostFunctions {

  getExecResultStrings: any = undefined;  
  rfPool: any = undefined;

  setPool (pool: any) {
    this.rfPool = pool;
  }

  logPost (req: any) {
    req.log();
  }

  constructor () {
    this.getExecResultStrings = this.createResultStringFn(' fn called: ', ' fn call failed: '); 
  }

  createResultStringFn (successText: string, failureText: string) {

    function getResultStrings (tableName: string) {
      var resultStrings = {
        success: ' xxx ' + successText,
        failure: ' ' + failureText 
      }

      resultStrings.success = tableName + resultStrings.success; 
      resultStrings.failure = tableName + resultStrings.failure; 

      return resultStrings;
    }

    return getResultStrings;
  }

  createPostFn (resultStringText: string, 
    dbQueryFn: any, payloadFn: any, logFn: any) {
    
    var rfPool = this.rfPool;
    var logPost = this.logPost;
    var getExecResultStrings = this.getExecResultStrings;
  
    function postFn (req: any, reply: any) {
      var payload = req.payload;
      var results = getExecResultStrings(resultStringText);

      if (logFn !== undefined) {
        logFn(req);
      } 
      else {
        logPost(req);
      }

      postgresQueries.dbExecuteCarpoolAPIFunction_Insert(
        payload, rfPool, dbQueryFn, payloadFn, req, reply, results
      );
    }

    return postFn; 
  }
}
