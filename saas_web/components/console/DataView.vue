<template>
  <div>
    <h3 class="text-h6 mb-2">Server Metrics</h3>
    <v-container v-if="loading" class="d-flex justify-center">
      <v-progress-circular indeterminate></v-progress-circular>
    </v-container>
    <div v-else>
      <p>Network In (last hour): {{ formatBytes(metrics.network_in) }}</p>
      <p>Network Out (last hour): {{ formatBytes(metrics.network_out) }}</p>
      <h4 class="text-h6 mt-4 mb-2">EBS Volumes</h4>
      <v-table density="compact" class="mb-4">
        <thead>
          <tr>
            <th class="text-left">ID</th>
            <th class="text-left">Size (GiB)</th>
            <th class="text-left">Read</th>
            <th class="text-left">Write</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="vol in metrics.volumes" :key="vol.id">
            <td>{{ vol.id }}</td>
            <td>{{ vol.size_gb }}</td>
            <td>{{ formatBytes(vol.read_bytes) }}</td>
            <td>{{ formatBytes(vol.write_bytes) }}</td>
          </tr>
        </tbody>
      </v-table>
    </div>
  </div>
</template>

<script>
const { Auth } = aws_amplify;
export default {
  name: "DataView",
  data() {
    return {
      loading: true,
      metrics: { network_in: 0, network_out: 0, volumes: [] },
      apiUrl: "MC_API_URL",
    };
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
    async fetchMetrics() {
      try {
        const res = await fetch(this.endpoint("metrics"), {
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        this.metrics = data;
      } catch (err) {
        console.error(err);
      } finally {
        this.loading = false;
      }
    },
    formatBytes(v) {
      let value = v;
      const units = ["B", "KB", "MB", "GB", "TB"];
      let i = 0;
      while (value >= 1024 && i < units.length - 1) {
        value /= 1024;
        i += 1;
      }
      return `${value.toFixed(1)} ${units[i]}`;
    },
  },
  mounted() {
    this.fetchMetrics();
  },
};
</script>

<style scoped></style>
