// const bcrypt = require('bcrypt');
var createToken = require('./token');
var Boom = require('boom');
var hashPassword = function (password, cb) {
    bcrypt.genSalt(10, function (err, salt) {
        bcrypt.hash(password, salt, function (err, hash) {
            return cb(err, hash);
        });
    });
};
var handler = function (req, res) {
    console.log("login handler", req);
    var user = {};
    user.email = req.payload.email;
    user.username = req.payload.username;
    user.admin = false;
    hashPassword(req.payload.password, function (err, hash) {
        if (err) {
            return res.error();
        }
        user.password = hash;
        // save user
        res({ id_token: createToken(user) }).code(201);
    });
};
var verifyUniqueUser = function (req, res) {
    // find user with email or username
    if (false) {
        // user already exsits
        var bm = Boom.badRequest('username already exists');
        res(bm);
    }
    res(req.payload);
};
// export server route
module.exports = {
    method: 'POST',
    path: '/users',
    config: {
        pre: [
            { method: verifyUniqueUser }
        ], handler: handler
    }
};
//# sourceMappingURL=login.js.map