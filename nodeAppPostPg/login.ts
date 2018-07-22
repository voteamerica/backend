// const bcrypt = require('bcrypt');
const createToken = require('./token');
const Boom = require('boom');

const hashPassword = (password, cb) => {
    bcrypt.genSalt(10, (err, salt)=>{
        bcrypt.hash(password, salt, (err, hash)=>{
            return cb(err, hash);
        });
    });
}

const handler = (req, res)=>{

    console.log("login handler", req);

    let user = {        
    }

    user.email = req.payload.email
    user.username = req.payload.username
    user.admin = false

    hashPassword(req.payload.password, (err, hash) => {
        if (err) {
            return res.error();            
        }

        user.password = hash
        // save user
        res({id_token: createToken(user)}).code(201)
    })
}

const verifyUniqueUser = (req,res) =>{
    // find user with email or username
    if (false) {
        // user already exsits

        const bm = Boom.badRequest('username already exists')

        res(bm);
    }

    res(req.payload);
}

// export server route
module.exports = {
    method: 'POST',
    path: '/users',
    config: {
        pre: [
            {method: verifyUniqueUser}
        ], handler
    }
}