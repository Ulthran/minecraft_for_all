<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="6" lg="4">
        <h2 class="text-h5 mb-4">Login</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
          <v-text-field v-model="password" label="Password" type="password" required></v-text-field>
            <v-btn type="submit" color="secondary" class="mt-2">Login</v-btn>
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
const { Auth } = aws_amplify;

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
        await Auth.signIn(this.email, this.password);
        window.useAuthStore().updateLoggedIn();
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
