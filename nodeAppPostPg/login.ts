const bcrypt = require('bcrypt');
const routeFns    = require('./routeFunctions.js');
const Boom = require('boom');

import { createToken } from './token';

const createUserErrorMessage = "failed to add user";  
const existingUserError = "user already exists";
const verifyCredentialsError = "bad credentials";

const hashPassword = (password, cb) => {
  bcrypt.genSalt(10, (err, salt) => {
    bcrypt.hash(password, salt, (err, hash) => {
      return cb(err, hash);
    })
  })
};

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
      return res(Boom.badRequest(existingUserError));
    }
  
    res(req.payload);
  };

  // const user = {
  //   email: '123',
  //   userName: 'abc',
  //   // password: 'xyz',
  //   password: '$2a$10$Bt2vRGCw3udVph77lGBx8O1ffXFmEQv7d1gGI35nKzN.C1w.jeD32',
  //   admin: false
  // };
  
  const verifyCredentials = async (req, res) => {
    // const payload = JSON.parse( req.payload.info);
    const payload = req.query;
    const {password, email, userName} = payload;
        
    console.log("pwd", password);
    console.log("email", email);
    console.log("userName", userName);
  
    const userInfo = await routeFns.getUsersInternal(req, res, payload);

    const user = JSON.parse(userInfo);
  
    if (email !== user.email && userName !== user.userName) {
      return res(Boom.badRequest(verifyCredentialsError));
    }
  
    bcrypt.compare(password, user.password, (err, isValid) => {
      if (err) {
        return res(err);
      }
  
      if (!isValid) {
        res(Boom.badRequest(verifyCredentialsError));
      }
      else {
        res(user);
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

  const createUser = (req, res) => {
    // const payload = JSON.parse( req.payload.info);
    const payload = req.query;
  
    let user = payload || {}
  
    const password = user.password;
  
    hashPassword(password, async (err, hash) => {
      if (err) {
        console.log("bad info");
  
        return res(Boom.badRequest(createUserErrorMessage));
      }
  
      // correct querystring boolean to be an actual boolean
      user.isAdmin = user.isAdmin && user.isAdmin === "true" ? true : false;
  
      // store info, and the hash rather than the pwd
      user.password = hash;
  
      console.log("user:", user);            
  
      const uuid = await routeFns.addUserInternal(req, res, user);
  
      if (!uuid) {
        return res(Boom.badRequest(createUserErrorMessage));
      }
    
      const token = createToken(user);
  
      console.log("token:", token);
  
      return res({ id_token: token}).code(201);
    });
  }
  // ,
  // validate: {
  //   payload: createUserSchema
  // }
    
  export { hashPassword, verifyUniqueUser, verifyCredentials, createUser };
  
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