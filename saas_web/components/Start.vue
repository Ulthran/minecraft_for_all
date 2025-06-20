<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8" lg="6">
        <h2 class="text-h5 mb-4">Start your server</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="email" label="Email" type="email" required></v-text-field>
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
      message: '',
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
    };
  },
  methods: {
    async submit() {
      this.message = 'Submitting...';
      try {
        const res = await fetch('SIGNUP_API_URL', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: this.email,
            players: this.players,
            pregen: this.pregen,
          }),
        });
        if (!res.ok) throw new Error('Failed');
        this.message = 'Check your email for server details.';
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
