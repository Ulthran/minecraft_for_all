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
import VueJwtDecode from 'vue-jwt-decode'

const poolData = {
  UserPoolId: 'USER_POOL_ID',
  ClientId: 'USER_POOL_CLIENT_ID',
};
const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
export default {
  name: 'Console',
  data() {
    return {
      status: 'Checking status...',
      showStart: false,
      cost: 'Fetching cost...',
      interval: null,
      tenant_id: localStorage.getItem('tenant_id') || '',
      api_url: localStorage.getItem('api_url') || '',
    };
  },
  mounted() {
    this.initApiUrl();
  },
  beforeUnmount() {
    clearInterval(this.interval);
  },
  methods: {
    async initApiUrl() {
      if (this.api_url) {
        this.fetchStatus();
        this.fetchCost();
        this.interval = setInterval(this.fetchStatus, 30000);
        return;
      }

      const token = localStorage.getItem('token');
      if (!token) {
        this.status = 'Please log in.';
        return;
      }

      try {
        const payload = VueJwtDecode.decode(token);
        const tenantId = payload['custom:tenant_id'] || '';
        if (tenantId) {
          const url = `/MC_API/${tenantId}`;
          localStorage.setItem('tenant_id', tenantId);
          localStorage.setItem('api_url', url);
          this.tenant_id = tenantId;
          this.api_url = url;
          this.fetchStatus();
          this.fetchCost();
          this.interval = setInterval(this.fetchStatus, 30000);
        } else {
          this.status = 'Provisioning your server...';
          setTimeout(this.initApiUrl, 15000);
        }
      } catch (err) {
        console.error(err);
        this.status = 'Error checking server setup.';
        setTimeout(this.initApiUrl, 30000);
      }
    },
    authHeader() {
      const token = localStorage.getItem('token');
      return token ? { Authorization: `Bearer ${token}` } : {};
    },
    endpoint(path) {
      const normalizedApiUrl = this.api_url.replace(/\/+$/, ''); // Remove trailing slashes
      return normalizedApiUrl ? `${normalizedApiUrl}/${path}` : path;
    },
    async fetchStatus() {
      try {
        const res = await fetch(this.endpoint('status'), { headers: this.authHeader() });
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
        const res = await fetch(this.endpoint('cost'), { headers: this.authHeader() });
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
