<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="6" lg="4">
        <h2 class="text-h5 mb-4">Verify Email</h2>
        <v-form @submit.prevent="submit">
          <v-text-field v-model="code" label="Verification Code" required></v-text-field>
          <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Verify</v-btn>
        </v-form>
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
        const res = await fetch('CONFIRM_API_URL', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: this.email, code: this.code }),
        });
        if (!res.ok) throw new Error('Failed');
        this.message = 'Email verified! You can now log in.';
        this.$router.push('/login');
      } catch (err) {
        console.error(err);
        this.message = 'Verification failed. Please try again.';
      }
    },
  },
};
</script>

<style scoped>
</style>
