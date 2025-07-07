<template>
  <div>
    <h3 class="text-h6 mb-2">Payment Setup</h3>
    <p class="mb-2">
      Provide a payment method. Usage charges occur after your first month.
    </p>
    <form @submit.prevent="submitPayment">
      <div id="payment-element" class="mb-2"></div>
      <v-btn
        type="submit"
        color="secondary"
        :loading="loading"
        :disabled="loading || !stripe || !elements || !initializationComplete"
      >
        Save Card
      </v-btn>
    </form>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
export default {
  name: "StepPayment",
  data() {
    return {
      message: "",
      apiUrl: "MC_API_URL",
      stripe_pk: "STRIPE_PUBLISHABLE_KEY",
      stripe: null,
      elements: null,
      clientSecret: "",
      loading: false,
    };
  },
  async mounted() {
    if (window.Stripe) {
      this.stripe = window.Stripe(this.stripe_pk);
      this.clientSecret = await this.fetchClientSecret();
      this.elements = this.stripe.elements({
        clientSecret: this.clientSecret,
        appearance: {},
      });
      const options = {
        layout: {
          type: "tabs",
          defaultCollapsed: false,
        },
      };
      const paymentElement = this.elements.create("payment", options);
      paymentElement.mount("#payment-element");
    }
  },
  methods: {
    endpoint(path) {
      const base = this.apiUrl.replace(/\/+$/, "");
      return `${base}/${path}`;
    },
    async fetchClientSecret() {
      await window.refreshTokenIfNeeded();
      const token = localStorage.getItem("token");
      const res = await fetch(this.endpoint("checkout"), {
        method: "POST",
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      });
      const data = await res.json();
      if (!res.ok) throw new Error("failed");
      return data.client_secret;
    },
    async submitPayment() {
      if (!this.stripe || !this.elements) return;
      this.loading = true;
      this.message = "";
      try {
        const { error } = await this.stripe.confirmSetup({
          elements: this.elements,
          confirmParams: {},
          redirect: "if_required",
        });
        if (error) throw error;
        this.$emit("complete");
      } catch (err) {
        console.error(err);
        this.message = err.message || "Payment failed.";
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<style scoped></style>
