import { userPool } from './cognito.js';

export function signUpUser(email, password) {
  const attributeList = [
    new AmazonCognitoIdentity.CognitoUserAttribute({
      Name: 'email',
      Value: email,
    }),
  ];
  return new Promise((resolve, reject) => {
    userPool.signUp(email, password, attributeList, null, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

export function confirmUser(email, code) {
  const user = new AmazonCognitoIdentity.CognitoUser({
    Username: email,
    Pool: userPool,
  });
  return new Promise((resolve, reject) => {
    user.confirmRegistration(code, true, (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

export function resendConfirmation(email) {
  const user = new AmazonCognitoIdentity.CognitoUser({
    Username: email,
    Pool: userPool,
  });
  return new Promise((resolve, reject) => {
    user.resendConfirmationCode((err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

export function loginUser(email, password) {
  const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({
    Username: email,
    Password: password,
  });
  const user = new AmazonCognitoIdentity.CognitoUser({
    Username: email,
    Pool: userPool,
  });
  return new Promise((resolve, reject) => {
    user.authenticateUser(authDetails, {
      onSuccess: resolve,
      onFailure: reject,
    });
  });
}
