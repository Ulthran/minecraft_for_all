<template>
  <v-container v-if="loading" class="d-flex justify-center">
    <v-progress-circular indeterminate></v-progress-circular>
  </v-container>
  <v-container v-else>
    <v-slide-group v-model="selectedServer" show-arrows mandatory class="mb-4">
      <v-slide-group-item
        v-for="server in servers"
        :key="server"
        :value="server"
      >
        <v-btn>{{ server }}</v-btn>
      </v-slide-group-item>
    </v-slide-group>
    <v-row>
      <v-col cols="12" md="3">
        <v-list nav dense>
          <v-list-item
            v-for="item in menuItems"
            :key="item.value"
            @click="menu = item.value"
            :active="menu === item.value"
          >
            <v-list-item-title>{{ item.label }}</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-col>
      <v-col cols="12" md="9">
        <template v-if="menu === 'server'">
          <h2 class="text-h5 mb-4">Server Console</h2>
          <div>{{ status }}</div>
          <div class="mt-2">{{ cost }}</div>
          <div v-if="progress" class="mt-2">{{ progress }}</div>
          <v-btn v-if="showStart" @click="start" class="mt-2"
            >Start Server</v-btn
          >
          <v-btn
            v-if="serverExists"
            :disabled="deleting"
            @click="deleteStack"
            class="mt-2"
            color="error"
          >
            <span v-if="!deleting">Delete Server</span>
            <span v-else>Deleting...</span>
          </v-btn>
          <h3 v-if="!serverExists" class="text-h6 mt-8 mb-2">
            Start a New Server
          </h3>
          <StepConfig v-if="!serverExists" @complete="handleInitComplete" />
        </template>
        <DataView v-else-if="menu === 'data'" />
        <BillingView v-else-if="menu === 'billing'" />
        <ModsView v-else-if="menu === 'mods'" />
        <HelpView v-else-if="menu === 'help'" />
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
const { Auth } = aws_amplify;
export default {
  name: "Console",
  components: {
    StepConfig: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/start/StepConfig.vue`,
        window.loaderOptions,
      ),
    ),
    DataView: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/console/DataView.vue`,
        window.loaderOptions,
      ),
    ),
    BillingView: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/console/BillingView.vue`,
        window.loaderOptions,
      ),
    ),
    ModsView: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/console/ModsView.vue`,
        window.loaderOptions,
      ),
    ),
    HelpView: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/console/HelpView.vue`,
        window.loaderOptions,
      ),
    ),
  },
  data() {
    return {
      status: "",
      showStart: false,
      cost: "Fetching cost...",
      interval: null,
      progressInterval: null,
      progress: "",
      buildId: "",
      serverExists: false,
      loading: true,
      api_url: "MC_API_URL",
      servers: ["Server 1", "Server 2"],
      selectedServer: "Server 1",
      menu: "server",
      menuItems: [
        { label: "Server", value: "server" },
        { label: "Data", value: "data" },
        { label: "Billing", value: "billing" },
        { label: "Mods", value: "mods" },
        { label: "Help", value: "help" },
      ],
    };
  },
  mounted() {
    this.fetchStatus();
    this.fetchCost();
    this.interval = setInterval(this.fetchStatus, 30000);
  },
  beforeUnmount() {
    clearInterval(this.interval);
    if (this.progressInterval) clearInterval(this.progressInterval);
  },
  methods: {
    // No initialization needed; the backend uses the JWT to determine the tenant
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
      const normalizedApiUrl = this.api_url.replace(/\/+$/, "");
      return `${normalizedApiUrl}/${path}`;
    },
    async fetchStatus() {
      try {
        const res = await fetch(this.endpoint("status"), {
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        this.serverExists = data.exists ?? false;
        if (data.state === "running") {
          const players = data.players ?? 0;
          this.status = `Server is running with ${players} player${players === 1 ? "" : "s"} online.`;
          this.showStart = false;
        } else {
          this.status = this.serverExists
            ? "Server is offline."
            : "No server found.";
          this.showStart = this.serverExists;
        }
        this.loading = false;
      } catch (err) {
        console.error(err);
        this.status = "Error fetching status.";
        this.loading = false;
      }
    },
    async start() {
      this.showStart = false;
      this.status = "Starting...";
      try {
        const res = await fetch(this.endpoint("start"), {
          method: "POST",
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error("Failed");
      } catch (err) {
        console.error(err);
        this.status = "Could not start server.";
        this.showStart = true;
      }
    },
    async fetchCost() {
      try {
        const res = await fetch(this.endpoint("cost"), {
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        let text = `Monthly cost so far: $${data.total ?? 0}`;
        if (data.breakdown) {
          const parts = Object.entries(data.breakdown).map(
            ([k, v]) => `${k}: $${v}`,
          );
          if (parts.length) text += ` ( ${parts.join(", ")} )`;
        }
        this.cost = text;
      } catch (err) {
        console.error(err);
        this.cost = "Error fetching cost.";
      }
    },

    handleInitComplete(buildId) {
      this.fetchStatus();
      if (buildId) {
        this.buildId = buildId;
        this.progress = "Provisioning...";
        this.pollBuildStatus();
      }
    },

    async pollBuildStatus() {
      await this.fetchBuildStatus();
      if (this.progressInterval) clearInterval(this.progressInterval);
      this.progressInterval = setInterval(() => this.fetchBuildStatus(), 5000);
    },

    async fetchBuildStatus() {
      if (!this.buildId) return;
      try {
        const res = await fetch(this.endpoint(`build/${this.buildId}`), {
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error("failed");
        const data = await res.json();
        if (data.build) {
          this.progress = `${data.build.current_phase} - ${data.build.status}`;
          if (
            ["SUCCEEDED", "FAILED", "FAULT", "STOPPED", "TIMED_OUT"].includes(
              data.build.status,
            )
          ) {
            clearInterval(this.progressInterval);
            this.progressInterval = null;
          }
        }
      } catch (err) {
        console.error(err);
        this.progress = "Error fetching build status.";
      }
    },

    async deleteStack() {
      try {
        const res = await fetch(this.endpoint("delete"), {
          method: "POST",
          headers: await this.authHeader(),
        });
        if (!res.ok) throw new Error("failed");
        this.serverExists = false;
        this.showStart = false;
        this.status = "Deletion started.";
      } catch (err) {
        console.error(err);
        this.status = "Failed to delete server.";
      }
    },
  },
};
</script>

<style scoped></style>
