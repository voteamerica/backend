const jwt = require('jsonwebtoken')
const secret = process.env.secret || 'secret'

const createToken=user =>{
    let scopes;

    if (user.admin){
        scopes = 'admin'
    }

    return jwt.sign({id: user.id, username: user.username, scope: scopes}, secret, {algorithm: 'HS256', expiresIn: "1h"});
}

module.exports = createToken;