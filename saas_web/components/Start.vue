<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8" lg="6">
        <h2 class="text-h5 mb-4">Start your server</h2>

        <!-- Step 1 - account creation and verification -->
        <div v-if="step === 1">
          <v-form v-if="!awaitingVerification" @submit.prevent="signUp">
            <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
            <v-text-field v-model="password" label="Password" type="password" required></v-text-field>
            <v-text-field v-model="confirm" label="Confirm Password" type="password" required></v-text-field>
            <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Create Account</v-btn>
          </v-form>

          <div v-else>
            <v-form @submit.prevent="verifyCode">
              <v-text-field v-model="code" label="Verification Code" required></v-text-field>
              <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Verify</v-btn>
            </v-form>
            <v-btn
              color="deep-purple-accent-2"
              class="mt-2"
              variant="outlined"
              @click="resendCode"
              :disabled="resendSeconds > 0"
            >Resend Code</v-btn>
            <small v-if="resendSeconds > 0" class="ml-1 text-caption">{{ resendSeconds }}</small>
          </div>
        </div>

        <!-- Step 2 - mock payment -->
        <div v-else-if="step === 2">
          <h3 class="text-h6 mb-2">Payment Setup</h3>
          <p class="mb-2">Payment integration coming soon.</p>
          <v-btn color="deep-purple-accent-2" @click="completePayment">Complete Payment</v-btn>
        </div>

        <!-- Step 3 - configuration -->
        <div v-else-if="step === 3">
          <v-form @submit.prevent="submitConfig">
            <v-select v-model="players" :items="playerOptions" label="Players" required></v-select>
            <v-checkbox v-model="pregen" label="Pregenerate world"></v-checkbox>
            <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Launch</v-btn>
          </v-form>
        </div>

        <div class="mt-2">{{ message }}</div>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'Start',
  data() {
    return {
      step: 1,
      awaitingVerification: false,
      resendSeconds: 0,
      timer: null,
      email: '',
      password: '',
      confirm: '',
      code: '',
      players: 4,
      pregen: true,
      message: '',
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
    };
  },
  beforeUnmount() {
    if (this.timer) clearInterval(this.timer);
  },
  methods: {
    validateEmail(email) {
      return /^[^@]+@[^@]+\.[^@]+$/.test(email);
    },
    validatePassword() {
      if (this.password.length < 8) {
        return 'be at least 8 characters long';
      }
      if (!/[A-Za-z]/.test(this.password)) {
        return 'include at least one letter';
      }
      if (!/[0-9]/.test(this.password)) {
        return 'include at least one number';
      }
      return '';
    },
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
    async signUp() {
      this.message = 'Submitting...';
      if (!this.validateEmail(this.email)) {
        this.message = 'Please enter a valid email address.';
        return;
      }
      const pwError = this.validatePassword();
      if (pwError) {
        this.message = `Password must ${pwError}.`;
        return;
      }
      if (this.password !== this.confirm) {
        this.message = 'Passwords do not match.';
        return;
      }
      try {
        const attributeList = [
          new AmazonCognitoIdentity.CognitoUserAttribute({
            Name: 'email',
            Value: this.email,
          }),
        ];

        await new Promise((resolve, reject) => {
          userPool.signUp(
            this.email,
            this.password,
            attributeList,
            null,
            (err, result) => {
              if (err) return reject(err);
              return resolve(result);
            },
          );
        });

        sessionStorage.setItem(
          'pendingCreds',
          JSON.stringify({ email: this.email, password: this.password }),
        );

        this.message = 'Check your email for the verification code.';
        this.awaitingVerification = true;
        this.startTimer();
      } catch (err) {
        console.error(err);
        this.message = err.message || 'Request failed. Please try again later.';
      }
    },
    async verifyCode() {
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

        const creds = JSON.parse(sessionStorage.getItem('pendingCreds') || '{}');
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
            sessionStorage.removeItem('pendingCreds');
          } catch (e) {
            console.error('Auto login failed', e);
          }
        }

        this.awaitingVerification = false;
        this.step = 2;
        this.message = '';
      } catch (err) {
        console.error(err);
        this.message = 'Verification failed. Please try again.';
      }
    },
    async resendCode() {
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
    completePayment() {
      this.message = 'Payment confirmed!';
      this.step = 3;
    },
    async submitConfig() {
      this.message = 'Provisioning your server...';
      setTimeout(() => {
        this.$router.push('/console');
      }, 2000);
    },
  },
};
</script>

<style scoped>
</style>
