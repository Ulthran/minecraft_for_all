const { defineStore } = Pinia;

function decodeJwt(token) {
  if (typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const header = JSON.parse(atob(parts[0]));
    const payload = JSON.parse(atob(parts[1]));
    return Object.assign({}, header, payload);
  } catch (e) {
    console.error('Token decode failed', e);
    return null;
  }
}

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
  const payload = decodeJwt(token);
  if (!payload) return;
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
