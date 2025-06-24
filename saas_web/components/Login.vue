<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="6" lg="4">
        <h2 class="text-h5 mb-4">Login</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
          <v-text-field v-model="password" label="Password" type="password" required></v-text-field>
          <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Login</v-btn>
        </v-form>
        <div class="mt-2">{{ message }}</div>
        <div class="mt-2">
          Don't have an account?
          <router-link to="/start">Sign up here</router-link>
        </div>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import VueJwtDecode from 'vue-jwt-decode'
import { userPool } from '../cognito.js';

export default {
  name: 'Login',
  data() {
    return {
      email: '',
      password: '',
      message: '',
    };
  },
  methods: {
    async submit() {
      this.message = 'Logging in...';
      try {
        const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({
          Username: this.email,
          Password: this.password,
        });

        const cognitoUser = new AmazonCognitoIdentity.CognitoUser({
          Username: this.email,
          Pool: userPool,
        });

        const session = await new Promise((resolve, reject) => {
          cognitoUser.authenticateUser(authDetails, {
            onSuccess: resolve,
            onFailure: reject,
          });
        });

        const token = session.getIdToken().getJwtToken();
        localStorage.setItem('token', token);
        try {
          const payload = VueJwtDecode.decode(token);
          const urls = {
            start_url: payload['custom:start_url'] || '',
            status_url: payload['custom:status_url'] || '',
            cost_url: payload['custom:cost_url'] || '',
          };
          localStorage.setItem('urls', JSON.stringify(urls));
        } catch (e) {
          console.error('Failed to parse token', e);
        }
        this.message = 'Logged in!';
        this.$router.push('/console');
      } catch (err) {
        console.error(err);
        this.message = 'Login failed. Please try again later.';
      }
    },
  },
};
</script>

<style scoped>
</style>
