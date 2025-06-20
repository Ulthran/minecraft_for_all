<template>
  <v-container>
    <v-row>
      <v-col>
        <h2 class="text-h5 mb-4">Server Console</h2>
        <div>{{ status }}</div>
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
      interval: null,
    };
  },
  mounted() {
    this.fetchStatus();
    this.interval = setInterval(this.fetchStatus, 30000);
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
  },
};
</script>

<style scoped>
</style>
