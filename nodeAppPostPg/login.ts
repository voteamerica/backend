const bcrypt = require('bcrypt');
const routeFns    = require('./routeFunctions.js');


import { createToken } from './token';

const Boom = require('boom');

const hashPassword = (password, cb) => {
  bcrypt.genSalt(10, (err, salt) => {
    bcrypt.hash(password, salt, (err, hash) => {
      return cb(err, hash);
    })
  })
};

// const handler = (req, res)=>{

//     console.log("login handler", req);

//     let user = {        
//     }

//     user.email = req.payload.email
//     user.username = req.payload.username
//     user.admin = false

//     hashPassword(req.payload.password, (err, hash) => {
//         if (err) {
//             return res.error();            
//         }

//         user.password = hash
//         // save user
//         res({id_token: createToken(user)}).code(201)
//     })
// }

// const createUserSchema = Joi.object({
//   userName: Joi.string().alphanum().min(2).max(30).required(),
//   email: Joi.string().email().required(),
//   password: Joi.string().required()
// });

const verifyUniqueUser = async (req, res) => {
    const payload = req.query;

    const userInfo = await routeFns.getUsersInternal(req, res, payload);
  
    // pretty basic test for now
    const userExists = userInfo !== undefined;
  
    if (userExists) {
      return res(Boom.badRequest("user already exists"));
    }
  
    res(req.payload);
  };

  const user = {
    email: '123',
    userName: 'abc',
    // password: 'xyz',
    password: '$2a$10$Bt2vRGCw3udVph77lGBx8O1ffXFmEQv7d1gGI35nKzN.C1w.jeD32',
    admin: false
  };
  
  const verifyCredentials = async (req, res) => {
    const payload = req.query;
      
    const userInfo = await routeFns.getUsersInternal(req, res, payload);
    // const payload = JSON.parse( req.payload.info);
  
    const {password, email, userName} = payload;
  
    console.log("pwd", password);
    console.log("email", email);
    console.log("userName", userName);
  
    // TODO get user from db
  
    if (email !== user.email || userName !== user.userName) {
      return res(Boom.badRequest('invalid credentials'));
    }
  
    bcrypt.compare(password, user.password, (err, isValid) => {
      if (err) {
        return res(err);
      }
  
      if (isValid) {
        res(user);
      }
      else {
        res(Boom.badRequest('user not known'));
      }
    });
  };
  
  // const authenticateUserSchema = Joi.alternatives().try(
  //   Joi.object({
  //     userName: Joi.string().alphanum().min(2).max(30).required(),
  //     password: Joi.string().required()
  //   }),
  //   Joi.object({
  //     email: Joi.string().email().required(),
  //     password: Joi.string().required()
  //   })
  // );
  
  export { hashPassword, verifyUniqueUser, verifyCredentials };
  
// export server route
// module.exports = {
//     method: 'POST',
//     path: '/users',
//     config: {
//         pre: [
//             {method: verifyUniqueUser}
//         ], handler
//     }
// }