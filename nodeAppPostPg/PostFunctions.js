"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var postgresQueries_1 = require("./postgresQueries");
var postgresQueries = new postgresQueries_1.PostgresQueries();
var PostFunctions = (function () {
    function PostFunctions() {
        this.getExecResultStrings = undefined;
        this.rfPool = undefined;
        this.getExecResultStrings = this.createResultStringFn(' fn called: ', ' fn call failed: ');
    }
    PostFunctions.prototype.setPool = function (pool) {
        this.rfPool = pool;
    };
    PostFunctions.prototype.logPost = function (req) {
        req.log();
    };
    PostFunctions.prototype.createResultStringFn = function (successText, failureText) {
        function getResultStrings(tableName) {
            var resultStrings = {
                success: ' xxx ' + successText,
                failure: ' ' + failureText
            };
            resultStrings.success = tableName + resultStrings.success;
            resultStrings.failure = tableName + resultStrings.failure;
            return resultStrings;
        }
        return getResultStrings;
    };
    PostFunctions.prototype.createPostFn = function (resultStringText, dbQueryFn, payloadFn, logFn) {
        var rfPool = this.rfPool;
        var logPost = this.logPost;
        var getExecResultStrings = this.getExecResultStrings;
        function postFn(req, reply) {
            var payload = req.payload;
            var results = getExecResultStrings(resultStringText);
            if (logFn !== undefined) {
                logFn(req);
            }
            else {
                logPost(req);
            }
            postgresQueries.dbExecuteCarpoolAPIFunction_Insert(payload, rfPool, dbQueryFn, payloadFn, req, reply, results);
        }
        return postFn;
    };
    return PostFunctions;
}());
exports.PostFunctions = PostFunctions;
//# sourceMappingURL=PostFunctions.js.map