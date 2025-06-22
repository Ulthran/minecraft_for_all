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
    async submit() {
      this.message = 'Submitting...';
      if (this.password !== this.confirm) {
        this.message = 'Passwords do not match.';
        return;
      }
      try {
        const res = await fetch('SIGNUP_API_URL', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: this.email,
            password: this.password,
            players: this.players,
            pregen: this.pregen,
          }),
        });
        if (!res.ok) throw new Error('Failed');
        this.message = 'Check your email for the verification code.';
        this.$router.push({ path: '/verify', query: { email: this.email } });
      } catch (err) {
        console.error(err);
        this.message = 'Request failed. Please try again later.';
      }
    },
  },
};
</script>

<style scoped>
</style>
