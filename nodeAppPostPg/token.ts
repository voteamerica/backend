import jwt = require('jsonwebtoken');

import { getJWTSecretFromEnv } from './login';

const jwt_secret = getJWTSecretFromEnv();

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
      algorithm: 'HS256',
      expiresIn: '1h'
    }
  );
};

export { UserType, createToken };
