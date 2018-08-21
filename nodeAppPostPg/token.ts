const jwt = require('jsonwebtoken')
const jwt_secret = process.env.JWT_SECRET || ''

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
    jwt_secret, 
    {
        algorithm: 'HS256', expiresIn: '1h'
    }
  );
};
  
export { UserType, createToken };
