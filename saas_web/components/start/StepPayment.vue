<template>
  <div>
    <h3 class="text-h6 mb-2">Payment Setup</h3>
    <p class="mb-2">Enter your payment information to start your subscription.</p>
    <form @submit.prevent="submitPayment">
      <div v-show="paymentRequestSupported" id="payment-request-button" class="mb-3"></div>
      <v-text-field v-model="billing.name" label="Name" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.email" label="Email" type="email" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.line1" label="Address Line 1" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.city" label="City" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.state" label="State" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.postal" label="Postal Code" required class="mb-2"></v-text-field>
      <v-text-field v-model="billing.country" label="Country" required class="mb-2"></v-text-field>
      <div id="card-element" class="mb-2"></div>
      <v-btn
        type="submit"
        color="secondary"
        :loading="loading"
        :disabled="loading || !stripe"
      >
        Complete Payment
      </v-btn>
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
      paymentRequest: null,
      paymentRequestSupported: false,
      prButton: null,
      billing: {
        name: '',
        email: '',
        line1: '',
        city: '',
        state: '',
        postal: '',
        country: '',
      },
      loading: false,
    };
  },
  mounted() {
    if (window.Stripe) {
      this.stripe = window.Stripe(this.stripe_pk);
      const elements = this.stripe.elements({
        fonts: [{ cssSrc: 'https://fonts.googleapis.com/css?family=Roboto' }],
      });
      this.card = elements.create('card', {
        hidePostalCode: true,
        style: {
          base: {
            color: '#32325d',
            fontFamily: 'Roboto, sans-serif',
            fontSize: '16px',
            '::placeholder': { color: '#a0aec0' },
          },
        },
      });
      this.card.mount('#card-element');
      this.card.on('change', (e) => {
        this.message = e.error ? e.error.message : '';
      });

      this.paymentRequest = this.stripe.paymentRequest({
        country: 'US',
        currency: 'usd',
        total: { label: 'Subscription', amount: 500 },
        requestPayerName: true,
        requestPayerEmail: true,
      });
      this.paymentRequest.canMakePayment().then((result) => {
        if (result) {
          this.paymentRequestSupported = true;
          this.prButton = elements.create('paymentRequestButton', {
            paymentRequest: this.paymentRequest,
          });
          this.prButton.mount('#payment-request-button');
        }
      });

      this.paymentRequest?.on('paymentmethod', this.handlePaymentRequest);
    }
  },
  methods: {
    endpoint(path) {
      const base = this.api_url.replace(/\/+$/, '');
      return `${base}/${path}`;
    },
    async fetchClientSecret() {
      await window.refreshTokenIfNeeded();
      const token = localStorage.getItem('token');
      const res = await fetch(this.endpoint('checkout'), {
        method: 'POST',
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      });
      const data = await res.json();
      if (!res.ok) throw new Error('failed');
      return data.client_secret;
    },
    async handlePaymentRequest(ev) {
      this.loading = true;
      try {
        const clientSecret = await this.fetchClientSecret();
        const { error } = await this.stripe.confirmCardPayment(
          clientSecret,
          {
            payment_method: ev.paymentMethod.id,
          },
          { handleActions: false }
        );
        if (error) {
          ev.complete('fail');
          this.message = error.message || 'Payment failed.';
          return;
        }
        ev.complete('success');
        const finalResult = await this.stripe.confirmCardPayment(clientSecret);
        if (finalResult.error) {
          this.message = finalResult.error.message || 'Payment failed.';
        } else {
          this.$emit('complete');
        }
      } catch (err) {
        console.error(err);
        ev.complete && ev.complete('fail');
        this.message = err.message || 'Payment failed.';
      } finally {
        this.loading = false;
      }
    },
    async submitPayment() {
      if (!this.stripe) return;
      this.loading = true;
      this.message = '';
      try {
        const clientSecret = await this.fetchClientSecret();
        const result = await this.stripe.confirmCardPayment(clientSecret, {
          payment_method: {
            card: this.card,
            billing_details: {
              name: this.billing.name,
              email: this.billing.email,
              address: {
                line1: this.billing.line1,
                city: this.billing.city,
                state: this.billing.state,
                postal_code: this.billing.postal,
                country: this.billing.country,
              },
            },
          },
        });
        if (result.error) throw result.error;
        this.$emit('complete');
      } catch (err) {
        console.error(err);
        this.message = err.message || 'Payment failed.';
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<style scoped>
#card-element {
  padding: 12px;
  border: 1px solid #ccc;
  border-radius: 4px;
  background: white;
}
</style>
