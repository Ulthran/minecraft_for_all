<template>
  <v-container>
    <v-row>
      <v-col>
      <h2 class="text-h5 mb-4">Server Console</h2>
      <div v-if="userEmail" class="mb-2">Welcome {{ userEmail }}</div>
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
      userEmail: '',
      interval: null,
    };
  },
  mounted() {
    this.fetchStatus();
    this.fetchCost();
    this.interval = setInterval(this.fetchStatus, 30000);
    const token = localStorage.getItem('token');
    if (token) {
      const payload = this.parseJwt(token);
      this.userEmail = payload.email || '';
    }
  },
  beforeUnmount() {
    clearInterval(this.interval);
  },
  methods: {
    authHeader() {
      const token = localStorage.getItem('token');
      return token ? { Authorization: `Bearer ${token}` } : {};
    },
    async fetchStatus() {
      try {
        const res = await fetch('STATUS_API_URL', { headers: this.authHeader() });
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
        const res = await fetch('START_API_URL', { method: 'POST', headers: this.authHeader() });
        if (!res.ok) throw new Error('Failed');
      } catch (err) {
        console.error(err);
        this.status = 'Could not start server.';
        this.showStart = true;
      }
    },
    async fetchCost() {
      try {
        const res = await fetch('COST_API_URL', { headers: this.authHeader() });
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
    parseJwt(token) {
      try {
        const base = token.split('.')[1];
        const base64 = base.replace(/-/g, '+').replace(/_/g, '/');
        const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, '=');
        return JSON.parse(atob(padded));
      } catch (err) {
        console.error('Invalid token', err);
        return {};
      }
    },
  },
};
</script>

<style scoped>
</style>
