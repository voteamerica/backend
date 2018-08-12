const bcrypt = require('bcrypt');
const routeFns    = require('./routeFunctions.js');
const Boom = require('boom');

import { UserType, createToken } from './token';

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
    // const { payload } = req;
    const { password, email, username } = payload;
        
    console.log("pwd", password);
    console.log("email", email);
    console.log("username", username);
  
    const userInfo = await routeFns.getUsersInternal(req, res, payload);

    let user:UserType = {}

    try{
      user = JSON.parse(userInfo);
    } 
    catch(e){
      return res(Boom.badRequest(verifyCredentialsError));
    }

    if (email !== user.email && username !== user.username) {
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
  
    let user: UserType = payload || {}
  
    const password = user.password;
  
    hashPassword(password, async (err, hash) => {
      if (err) {
        console.log("bad info");
  
        return res(Boom.badRequest(createUserErrorMessage));
      }
  
      // correct querystring boolean to be an actual boolean
      user.admin = user.admin && user.admin === "true" ? true : false;
  
      // store info, and the hash rather than the pwd
      user.password = hash;
  
      console.log("user:", user);            
  
      const uuid = await routeFns.addUserInternal(req, res, user);
  
      if (!uuid) {
        return res(Boom.badRequest(createUserErrorMessage));
      }

      return createTokenAndRespond(res, user, 201);
    });
  }
  // ,
  // validate: {
  //   payload: createUserSchema
  // }

  const createTokenAndRespond =  (reply, user: UserType, code) => {
    const token = createToken(user);

    return reply({ id_token: token }).code(code);
    
    // reply.state('id_token', token);
    // return reply().code(code);
  }
      
  export { hashPassword, verifyUniqueUser, verifyCredentials, createUser, createTokenAndRespond };
  
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