const { defineStore } = Pinia;
const VueJwtDecode = window['vue-jwt-decode'];

const poolData = {
  UserPoolId: 'USER_POOL_ID',
  ClientId: 'USER_POOL_CLIENT_ID',
};
const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

const useAuthStore = defineStore('auth', {
  state: () => ({
    loggedIn: !!localStorage.getItem('token'),
  }),
  actions: {
    updateLoggedIn() {
      this.loggedIn = !!localStorage.getItem('token');
    },
  },
});

async function refreshTokenIfNeeded() {
  const token = localStorage.getItem('token');
  const refreshTokenStr = localStorage.getItem('refreshToken');
  if (!token || !refreshTokenStr) return;
  let payload;
  try {
    payload = VueJwtDecode.decode(token);
  } catch (e) {
    console.error('Token decode failed', e);
    return;
  }
  const exp = payload.exp || 0;
  const now = Date.now() / 1000;
  if (exp - now > 60) return; // still valid
  const username = payload['cognito:username'] || payload.email || '';
  const cognitoUser = new AmazonCognitoIdentity.CognitoUser({
    Username: username,
    Pool: userPool,
  });
  const refreshToken = new AmazonCognitoIdentity.CognitoRefreshToken({
    RefreshToken: refreshTokenStr,
  });
  try {
    const session = await new Promise((resolve, reject) => {
      cognitoUser.refreshSession(refreshToken, (err, session) => {
        if (err) return reject(err);
        resolve(session);
      });
    });
    localStorage.setItem('token', session.getIdToken().getJwtToken());
    localStorage.setItem('refreshToken', session.getRefreshToken().getToken());
    useAuthStore().updateLoggedIn();
  } catch (err) {
    console.error('Token refresh failed', err);
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    useAuthStore().updateLoggedIn();
  }
}

window.useAuthStore = useAuthStore;
window.refreshTokenIfNeeded = refreshTokenIfNeeded;
