const jwt = require('jsonwebtoken')
const secret = process.env.secret || 'secret'

interface UserType {
    id: string;
    email: string;
    username: string;
    password: string;
    admin: boolean;
  }
  
const createToken = (user: UserType) => {
  let scopes;

  if (user.admin) {
      scopes = 'admin';
  }

  return jwt.sign(
    { 
        //   id: user.id, 
        username: user.username, 
        scope: scopes
    }, 
    secret, 
    {
        algorithm: 'HS256', expiresIn: '1h'
    }
  );
};
  
export { UserType, createToken };
