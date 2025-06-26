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
  },
});

const useAuthStore = defineStore('auth', {
  state: () => ({
    loggedIn: false,
  }),
  actions: {
    async updateLoggedIn() {
      try {
        await Auth.currentAuthenticatedUser();
        this.loggedIn = true;
      } catch (_) {
        this.loggedIn = false;
      }
    },
  },
});

window.useAuthStore = useAuthStore;
window.Auth = Auth;
