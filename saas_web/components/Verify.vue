<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="6" lg="4">
        <h2 class="text-h5 mb-4">Verify Email</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="code" label="Verification Code" required></v-text-field>
          <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Verify</v-btn>
        </v-form>
        <v-btn
          color="deep-purple-accent-2"
          class="mt-2"
          variant="outlined"
          @click="resend"
        >Resend Code</v-btn>
        <div class="mt-2">{{ message }}</div>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'Verify',
  data() {
    return {
      email: '',
      code: '',
      message: '',
    };
  },
  created() {
    this.email = this.$route.query.email || '';
  },
  methods: {
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

        this.message = 'Email verified! You can now log in.';
        setTimeout(() => {
          this.$router.push('/login');
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
