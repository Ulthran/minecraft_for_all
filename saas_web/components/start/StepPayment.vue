<template>
  <div>
    <h3 class="text-h6 mb-2">Payment Setup</h3>
    <p class="mb-2">Enter your payment information to start your subscription.</p>
    <form @submit.prevent="submitPayment">
      <div id="card-element" class="mb-2"></div>
      <v-btn type="submit" color="secondary">Complete Payment</v-btn>
    </form>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
export default {
  name: 'StepPayment',
  data() {
    return {
      message: '',
      api_url: 'MC_API_URL',
      stripe_pk: 'STRIPE_PUBLISHABLE_KEY',
      stripe: null,
      card: null,
    };
  },
  mounted() {
    if (window.Stripe) {
      this.stripe = window.Stripe(this.stripe_pk);
      const elements = this.stripe.elements();
      this.card = elements.create('card');
      this.card.mount('#card-element');
    }
  },
  methods: {
    endpoint(path) {
      const base = this.api_url.replace(/\/+$/, '');
      return `${base}/${path}`;
    },
    async submitPayment() {
      this.message = 'Processing payment...';
      await window.refreshTokenIfNeeded();
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(this.endpoint('checkout'), {
          method: 'POST',
          headers: {
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
        });
        const data = await res.json();
        if (!res.ok) throw new Error('failed');
        const result = await this.stripe.confirmCardPayment(data.client_secret, {
          payment_method: { card: this.card },
        });
        if (result.error) throw result.error;
        this.$emit('complete');
      } catch (err) {
        console.error(err);
        this.message = 'Payment failed.';
      }
    },
  },
};
</script>

<style scoped>
</style>
