<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="6" lg="4">
        <h2 class="text-h5 mb-4">Verify Email</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="code" label="Verification Code" required></v-text-field>
            <v-btn type="submit" color="secondary" class="mt-2">Verify</v-btn>
        </v-form>
        <v-btn
          color="secondary"
          class="mt-2"
          variant="outlined"
          @click="resend"
          :disabled="resendSeconds > 0"
        >Resend Code</v-btn>
        <small v-if="resendSeconds > 0" class="ml-1 text-caption">{{ resendSeconds }}</small>
        <div class="mt-2">{{ message }}</div>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import VueJwtDecode from 'vue-jwt-decode'
export default {
  name: 'Verify',
  data() {
    return {
      email: '',
      code: '',
      message: '',
      resendSeconds: 10,
      timer: null,
    };
  },
  created() {
    this.email = this.$route.query.email || '';
    this.startTimer();
  },
  methods: {
    startTimer() {
      this.resendSeconds = 10;
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        if (this.resendSeconds > 0) {
          this.resendSeconds -= 1;
        } else {
          clearInterval(this.timer);
          this.timer = null;
        }
      }, 1000);
    },
    async submit() {
      this.message = 'Verifying...';
      try {
        const cognitoUser = new AmazonCognitoIdentity.CognitoUser({
          Username: this.email,
          Pool: userPool,
        });

        await new Promise((resolve, reject) => {
          cognitoUser.confirmRegistration(this.code, true, (err, result) => {
            if (err) return reject(err);
            return resolve(result);
          });
        });
        this.message = 'Email verified! Logging in...';

        const creds = JSON.parse(sessionStorage.getItem('pendingCreds') || '{}');
        let loggedIn = false;
        if (creds.email === this.email && creds.password) {
          try {
            const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({
              Username: creds.email,
              Password: creds.password,
            });
            const loginUser = new AmazonCognitoIdentity.CognitoUser({
              Username: creds.email,
              Pool: userPool,
            });
            const session = await new Promise((resolve, reject) => {
              loginUser.authenticateUser(authDetails, {
                onSuccess: resolve,
                onFailure: reject,
              });
            });
            const token = session.getIdToken().getJwtToken();
            localStorage.setItem('token', token);
            try {
              const payload = VueJwtDecode.decode(token);
              const apiUrl = payload['custom:mc_api_url'] || '';
              localStorage.setItem('api_url', apiUrl);
            } catch (e) {
              console.error('Failed to parse token', e);
            }
            sessionStorage.removeItem('pendingCreds');
            loggedIn = true;
          } catch (e) {
            console.error('Auto login failed', e);
          }
        }

        this.message = 'Email verified! Redirecting...';
        setTimeout(() => {
          this.$router.push('/console');
        }, 2000);
      } catch (err) {
        console.error(err);
        this.message = 'Verification failed. Please try again.';
      }
    },
    async resend() {
      this.message = 'Resending code...';
      try {
        const cognitoUser = new AmazonCognitoIdentity.CognitoUser({
          Username: this.email,
          Pool: userPool,
        });

        await new Promise((resolve, reject) => {
          cognitoUser.resendConfirmationCode((err, result) => {
            if (err) return reject(err);
            return resolve(result);
          });
        });

        this.message = 'Verification code resent.';
        this.startTimer();
      } catch (err) {
        console.error(err);
        this.message = 'Failed to resend code. Please try again later.';
      }
    },
  },
};
</script>

<style scoped>
</style>
