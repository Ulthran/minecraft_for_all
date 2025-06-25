<template>
  <div>
    <v-form v-if="!awaitingVerification" @submit.prevent="signUp">
      <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
      <v-text-field v-model="password" label="Password" type="password" required></v-text-field>
      <v-text-field v-model="confirm" label="Confirm Password" type="password" required></v-text-field>
        <v-btn type="submit" color="secondary" class="mt-2">Create Account</v-btn>
    </v-form>
    <div v-else>
      <v-form @submit.prevent="verifyCode">
        <v-text-field v-model="code" label="Verification Code" required></v-text-field>
          <v-btn type="submit" color="secondary" class="mt-2">Verify</v-btn>
      </v-form>
        <v-btn
          color="secondary"
        class="mt-2"
        variant="outlined"
        @click="resendCode"
        :disabled="resendSeconds > 0"
      >Resend Code</v-btn>
      <small v-if="resendSeconds > 0" class="ml-1 text-caption">{{ resendSeconds }}</small>
    </div>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
const poolData = {
  UserPoolId: 'USER_POOL_ID',
  ClientId: 'USER_POOL_CLIENT_ID',
};
const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

export default {
  name: 'StepAccount',
  data() {
    return {
      email: '',
      password: '',
      confirm: '',
      code: '',
      awaitingVerification: false,
      resendSeconds: 0,
      timer: null,
      message: '',
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
    signUpUser(email, password) {
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
    },
    confirmUser(email, code) {
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
    },
    resendConfirmation(email) {
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
    },
    loginUser(email, password) {
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
        await this.signUpUser(this.email, this.password);
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
        await this.confirmUser(this.email, this.code);
        try {
          const session = await this.loginUser(this.email, this.password);
          const token = session.getIdToken().getJwtToken();
          localStorage.setItem('token', token);
        } catch (e) {
          console.error('Auto login failed', e);
        }
        this.awaitingVerification = false;
        this.message = '';
        this.$emit('complete');
      } catch (err) {
        console.error(err);
        this.message = 'Verification failed. Please try again.';
      }
    },
    async resendCode() {
      this.message = 'Resending code...';
      try {
        await this.resendConfirmation(this.email);
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
