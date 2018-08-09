const jwt = require('jsonwebtoken')
const secret = process.env.secret || 'secret'

const createToken = user => {
  let scopes;

  if (user.isAdmin) {
      scopes = 'admin';
  }

  return jwt.sign(
      { id: user.id, userName: user.userName, scope: scopes}, 
      secret, 
      {algorithm: 'HS256', expiresIn: '1h'
      }
  );
};
  
export {createToken};
