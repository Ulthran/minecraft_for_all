const { defineStore } = Pinia;
const { Amplify, Auth } = aws_amplify;

const userPoolId = 'USER_POOL_ID';
const clientId = 'USER_POOL_CLIENT_ID';
const region = userPoolId.split('_')[0];

Amplify.configure({
  Auth: {
    region,
    userPoolId,
    userPoolWebClientId: clientId,
    authenticationFlowType: 'USER_PASSWORD_AUTH',
    storage: window.localStorage,
  },
});

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
  try {
    const session = await Auth.currentSession();
    localStorage.setItem('token', session.getIdToken().getJwtToken());
    useAuthStore().updateLoggedIn();
  } catch (err) {
    console.error('Token refresh failed', err);
    localStorage.removeItem('token');
    try {
      await Auth.signOut();
    } catch (_) {}
    useAuthStore().updateLoggedIn();
  }
}

window.useAuthStore = useAuthStore;
window.refreshTokenIfNeeded = refreshTokenIfNeeded;
