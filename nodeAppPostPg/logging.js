"use strict";
// lower case class name to avoid git rename issues 
var logging = (function () {
    function logging() {
    }
    logging.prototype.logReqResp = function (server, pool) {
        server.on('request', function (request, event, tags) {
            // Include the Requestor's IP Address on every log
            if (!event.remoteAddress) {
                event.remoteAddress = request.headers['x-forwarded-for'] || request.info.remoteAddress;
            }
            // Put the first part of the URL into the tags
            if (request && request.url && event && event.tags) {
                event.tags.push(request.url.path.split('/')[1]);
            }
            console.log('server req: %j', event);
        });
        server.on('response', function (request) {
            console.log("server resp: "
                + request.info.remoteAddress
                + ': ' + request.method.toUpperCase()
                + ' ' + request.url.path
                + ' --> ' + request.response.statusCode);
        });
        pool.on('error', function (err, client) {
            if (err) {
                console.error("db err: " + err);
            }
        });
    };
    return logging;
}());
exports.logging = logging;
//# sourceMappingURL=logging.js.map