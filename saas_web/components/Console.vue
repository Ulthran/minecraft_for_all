<template>
  <v-container>
    <v-row>
      <v-col>
      <h2 class="text-h5 mb-4">Server Console</h2>
      <div>{{ status }}</div>
      <div class="mt-2">{{ cost }}</div>
      <v-btn v-if="showStart" @click="start" class="mt-2">Start Server</v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'Console',
  data() {
    return {
      status: 'Checking status...',
      showStart: false,
      cost: 'Fetching cost...',
      interval: null,
      api_url: MC_API_URL,
      };
    },
  mounted() {
    this.fetchStatus();
    this.fetchCost();
    this.interval = setInterval(this.fetchStatus, 30000);
  },
  beforeUnmount() {
    clearInterval(this.interval);
  },
  methods: {
    // No initialization needed; the backend uses the JWT to determine the tenant
  authHeader() {
      const token = localStorage.getItem('token');
      return token ? { Authorization: `Bearer ${token}` } : {};
    },
    endpoint(path) {
      const normalizedApiUrl = this.api_url.replace(/\/+$/, '');
      return `${normalizedApiUrl}/${path}`;
    },
    async fetchStatus() {
      try {
        const res = await fetch(this.endpoint('status'), {
          headers: this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (data.state === 'running') {
          const players = data.players ?? 0;
          this.status = `Server is running with ${players} player${players === 1 ? '' : 's'} online.`;
          this.showStart = false;
        } else {
          this.status = 'Server is offline.';
          this.showStart = true;
        }
      } catch (err) {
        console.error(err);
        this.status = 'Error fetching status.';
      }
    },
    async start() {
      this.showStart = false;
      this.status = 'Starting...';
      try {
        const res = await fetch(this.endpoint('start'), { method: 'POST', headers: this.authHeader() });
        if (!res.ok) throw new Error('Failed');
      } catch (err) {
        console.error(err);
        this.status = 'Could not start server.';
        this.showStart = true;
      }
    },
    async fetchCost() {
      try {
        const res = await fetch(this.endpoint('cost'), {
          headers: this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        let text = `Monthly cost so far: $${data.total ?? 0}`;
        if (data.breakdown) {
          const parts = Object.entries(data.breakdown).map(([k, v]) => `${k}: $${v}`);
          if (parts.length) text += ` ( ${parts.join(', ')} )`;
        }
        this.cost = text;
      } catch (err) {
        console.error(err);
        this.cost = 'Error fetching cost.';
      }
    },
  },
};
</script>

<style scoped>
</style>
