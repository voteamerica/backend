var jwt = require('jsonwebtoken');
var secret = process.env.secret || 'secret';
var createToken = function (user) {
    var scopes;
    if (user.admin) {
        scopes = 'admin';
    }
    return jwt.sign({ id: user.id, username: user.username, scope: scopes }, secret, { algorithm: 'HS256', expiresIn: "1h" });
};
module.exports = createToken;
//# sourceMappingURL=token.js.map