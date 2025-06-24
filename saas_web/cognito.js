export const poolData = {
  UserPoolId: 'USER_POOL_ID',
  ClientId: 'USER_POOL_CLIENT_ID',
};

export const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

if (typeof window !== 'undefined') {
  window.userPool = userPool;
}
