"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var postgresQueries_1 = require("./postgresQueries");
var postgresQueries = new postgresQueries_1.PostgresQueries();
var dbQueries = require('./dbQueries.js');
var PostFunctions = (function () {
    function PostFunctions() {
        this.DRIVER_ROUTE = 'driver';
        this.RIDER_ROUTE = 'rider';
        this.HELPER_ROUTE = 'helper';
        this.rfPool = undefined;
        this.getExecResultStrings = undefined;
        this.postRider = undefined;
        this.postHelper = undefined;
        this.postDriver = undefined;
        this.getExecResultStrings = this.createResultStringFn(' fn called: ', ' fn call failed: ');
    }
    PostFunctions.prototype.setPool = function (pool) {
        this.rfPool = pool;
        this.postDriver =
            this.createPostFn(this.DRIVER_ROUTE, dbQueries.dbGetSubmitDriverString, this.createPayloadFn(this.getDriverPayloadAsArray), this.logPostDriver);
        this.postHelper =
            this.createPostFn(this.HELPER_ROUTE, dbQueries.dbGetSubmitHelperString, this.createPayloadFn(this.getHelperPayloadAsArray), this.logPostHelper);
        this.postRider =
            this.createPostFn(this.RIDER_ROUTE, dbQueries.dbGetSubmitRiderString, this.createPayloadFn(this.getRiderPayloadAsArray), this.logPostRider);
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
        var self = this;
        function postFn(req, reply) {
            var payload = req.payload;
            var results = self.getExecResultStrings(resultStringText);
            if (logFn !== undefined) {
                logFn(self, req);
            }
            else {
                self.logPost(req);
            }
            postgresQueries.dbExecuteCarpoolAPIFunction_Insert(payload, self.rfPool, dbQueryFn, payloadFn, req, reply, results);
        }
        return postFn;
    };
    PostFunctions.prototype.createPayloadFn = function (payloadFn) {
        var self = this;
        function callPayloadFn(req, payload) {
            return payloadFn(self, req, payload);
        }
        return callPayloadFn;
    };
    PostFunctions.prototype.getDriverPayloadAsArray = function (self, req, payload) {
        var ip = self.getClientAddress(req);
        return [
            ip,
            payload.DriverCollectionZIP,
            payload.DriverCollectionRadius,
            payload.AvailableDriveTimesJSON,
            (payload.DriverCanLoadRiderWithWheelchair ? 'true' : 'false'),
            payload.SeatCount,
            payload.DriverLicenceNumber,
            payload.DriverFirstName,
            payload.DriverLastName,
            payload.DriverEmail,
            payload.DriverPhone,
            (payload.DrivingOnBehalfOfOrganization ? 'true' : 'false'),
            payload.DrivingOBOOrganizationName,
            (payload.RidersCanSeeDriverDetails ? 'true' : 'false'),
            (payload.DriverWillNotTalkPolitics ? 'true' : 'false'),
            (payload.PleaseStayInTouch ? 'true' : 'false'),
            payload.DriverPreferredContact.toString(),
            (payload.DriverWillTakeCare ? 'true' : 'false')
        ];
    };
    PostFunctions.prototype.getHelperPayloadAsArray = function (self, req, payload) {
        return [
            payload.Name, payload.Email, payload.Capability
            // 1, moment().toISOString()
        ];
    };
    PostFunctions.prototype.getRiderPayloadAsArray = function (self, req, payload) {
        var ip = self.getClientAddress(req);
        return [
            ip,
            payload.RiderFirstName,
            payload.RiderLastName,
            payload.RiderEmail,
            payload.RiderPhone,
            payload.RiderCollectionZIP,
            payload.RiderDropOffZIP,
            payload.AvailableRideTimesJSON // this one should be in local time as passed along by the forms
            ,
            payload.TotalPartySize,
            (payload.TwoWayTripNeeded ? 'true' : 'false'),
            (payload.RiderIsVulnrable ? 'true' : 'false'),
            (payload.RiderWillNotTalkPolitics ? 'true' : 'false'),
            (payload.PleaseStayInTouch ? 'true' : 'false'),
            (payload.NeedWheelchair ? 'true' : 'false'),
            payload.RiderPreferredContact.toString(),
            payload.RiderAccommodationNotes,
            (payload.RiderLegalConsent ? 'true' : 'false'),
            (payload.RiderWillBeSafe ? 'true' : 'false'),
            payload.RiderCollectionAddress,
            payload.RiderDestinationAddress
        ];
    };
    PostFunctions.prototype.getClientAddress = function (req) {
        // See http://stackoverflow.com/questions/10849687/express-js-how-to-get-remote-client-address
        // and http://stackoverflow.com/questions/19266329/node-js-get-clients-ip/19267284
        return (req.headers['x-forwarded-for'] || '').split(',')[0]
            || req.connection.remoteAddress;
    };
    PostFunctions.prototype.logPostDriver = function (self, req) {
        var payload = req.payload;
        console.log("driver radius1 : " + payload.DriverCollectionRadius);
        self.sanitiseDriver(payload);
        console.log("driver radius2 : " + payload.DriverCollectionRadius);
        console.log("driver payload: " + JSON.stringify(payload, null, 4));
        console.log("driver zip: " + payload.DriverCollectionZIP);
        req.log();
    };
    PostFunctions.prototype.logPostHelper = function (self, req) {
        var payload = req.payload;
        req.log();
        console.log("helper payload: " + JSON.stringify(payload, null, 4));
    };
    PostFunctions.prototype.logPostRider = function (self, req) {
        var payload = req.payload;
        //console.log("rider state1 : " + payload.RiderVotingState);
        self.sanitiseRider(payload);
        //console.log("rider state2 : " + payload.RiderVotingState);
        req.log();
        console.log("rider payload: " + JSON.stringify(payload, null, 4));
        console.log("rider zip: " + payload.RiderCollectionZIP);
    };
    PostFunctions.prototype.sanitiseRider = function (payload) {
        // if (payload.RiderVotingState === undefined) {
        //   payload.RiderVotingState = "MO";
        // }
    };
    PostFunctions.prototype.sanitiseDriver = function (payload) {
        if (payload.DriverCollectionRadius === undefined ||
            payload.DriverCollectionRadius === "") {
            // console.log("santising...");
            payload.DriverCollectionRadius = 0;
        }
    };
    return PostFunctions;
}());
exports.PostFunctions = PostFunctions;
//# sourceMappingURL=PostFunctions.js.map