<template>
  <div>
    <h3 class="text-h6 mb-2">Billing</h3>
    <v-container v-if="loading" class="d-flex justify-center">
      <v-progress-circular indeterminate></v-progress-circular>
    </v-container>
    <div v-else>
      <p class="mb-2">{{ costMessage }}</p>
    </div>
  </div>
</template>

<script>
const { Auth } = aws_amplify;
export default {
  name: "BillingView",
  props: {
    selectedServer: {
      type: String,
      default: "Server 1",
    },
  },
  data() {
    return {
      loading: true,
      costMessage: "Fetching cost...",
      costTotal: 0,
      serverCosts: {},
      costBreakdown: {},
      apiUrl: "MC_API_URL",
    };
  },
  computed: {
    selectedServerCost() {
      return this.serverCosts[this.selectedServer] ?? 0;
    },
  },
  watch: {
    selectedServer() {
      this.updateCostMessage();
    },
  },
  methods: {
    async authHeader() {
      try {
        const session = await Auth.currentSession();
        const token = session.getIdToken().getJwtToken();
        return { Authorization: `Bearer ${token}` };
      } catch (err) {
        console.error("No auth token", err);
        return {};
      }
    },
    endpoint(path) {
      const normalizedApiUrl = this.apiUrl.replace(/\/+$/, "");
      return `${normalizedApiUrl}/${path}`;
    },
    async fetchCost() {
      try {
        const res = await fetch(this.endpoint("cost"), {
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        this.costTotal = data.total ?? 0;
        this.serverCosts = data.servers ?? {};
        this.costBreakdown = data.breakdown ?? {};
        this.updateCostMessage();
      } catch (err) {
        console.error(err);
        this.costMessage = "Error fetching cost.";
      } finally {
        this.loading = false;
      }
    },
    updateCostMessage() {
      const parts = [];
      if (this.costBreakdown.compute !== undefined)
        parts.push(`compute: $${this.costBreakdown.compute}`);
      if (this.costBreakdown.network !== undefined)
        parts.push(`network: $${this.costBreakdown.network}`);
      if (this.costBreakdown.storage !== undefined)
        parts.push(`storage: $${this.costBreakdown.storage}`);
      const breakdown = parts.length ? ` ( ${parts.join(", ")} )` : "";
      this.costMessage = `Monthly cost so far: $${this.selectedServerCost} for this server, $${this.costTotal} total${breakdown}`;
    },
  },
  mounted() {
    this.fetchCost();
  },
};
</script>

<style scoped></style>
