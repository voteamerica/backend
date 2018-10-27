"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const jwt = require("jsonwebtoken");
const login_1 = require("./login");
const jwt_secret = login_1.getJWTSecretFromEnv();
const createToken = (user) => {
    let scopes;
    if (user.admin) {
        scopes = 'admin';
    }
    return jwt.sign({
        //   id: user.id,
        username: user.username,
        scope: scopes
    }, jwt_secret, {
        algorithm: 'HS256',
        expiresIn: '1h'
    });
};
exports.createToken = createToken;
//# sourceMappingURL=token.js.map