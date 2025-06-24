<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8" lg="6">
        <h2 class="text-h5 mb-4">Start your server</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
          <v-text-field v-model="password" label="Password" type="password" required></v-text-field>
          <v-text-field v-model="confirm" label="Confirm Password" type="password" required></v-text-field>
          <v-select v-model="players" :items="playerOptions" label="Players" required></v-select>
          <v-checkbox v-model="pregen" label="Pregenerate world"></v-checkbox>
          <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Launch</v-btn>
        </v-form>
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
      email: '',
      players: 4,
      pregen: true,
      password: '',
      confirm: '',
      message: '',
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
    };
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
    async submit() {
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

        // Store credentials temporarily so Verify.vue can log in
        sessionStorage.setItem(
          'pendingCreds',
          JSON.stringify({ email: this.email, password: this.password }),
        );

        this.message = 'Check your email for the verification code.';
        setTimeout(() => {
          this.$router.push({ path: '/verify', query: { email: this.email } });
        }, 3000);
      } catch (err) {
        console.error(err);
        this.message = err.message || 'Request failed. Please try again later.';
      }
    },
  },
};
</script>

<style scoped>
</style>
