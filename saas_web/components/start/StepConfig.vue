<template>
  <div>
    <v-form @submit.prevent="submit">
      <v-select
        v-model="serverType"
        :items="serverTypeOptions"
        label="Server Type"
        required
      ></v-select>
      <v-select
        v-model="instanceType"
        :items="instanceTypeOptions"
        label="Instance Type"
        required
      ></v-select>
      <v-select
        v-model="players"
        :items="playerOptions"
        label="Players"
        required
      ></v-select>
      <v-text-field
        v-model="whitelist"
        label="Whitelisted Players (comma separated)"
      ></v-text-field>
      <v-text-field
        v-if="serverType === 'papermc'"
        v-model.number="overworld"
        label="Overworld Border Radius"
        type="number"
        required
      ></v-text-field>
      <v-text-field
        v-if="serverType === 'papermc'"
        v-model.number="nether"
        label="Nether Border Radius"
        type="number"
        required
      ></v-text-field>
      <v-btn type="submit" color="secondary" class="mt-2">Launch</v-btn>
    </v-form>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
const { Auth } = aws_amplify;
export default {
  name: "StepConfig",
  data() {
    return {
      serverType: "vanilla",
      instanceType: "t4g.medium",
      players: 4,
      whitelist: "",
      overworld: 3000,
      nether: 3000,
      message: "",
      serverTypeOptions: ["vanilla", "papermc"],
      instanceTypeOptions: ["t4g.small", "t4g.medium", "t4g.large"],
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
      apiUrl: "MC_API_URL",
    };
  },
  methods: {
    endpoint(path) {
      const normalizedApiUrl = this.apiUrl.replace(/\/+$/, "");
      return `${normalizedApiUrl}/${path}`;
    },
    async initTenantServer() {
      this.message = "Provisioning your server...";
      let token = "";
      try {
        const session = await Auth.currentSession();
        token = session.getIdToken().getJwtToken();
      } catch (err) {
        console.error("Failed to get token", err);
      }
      try {
        const res = await fetch(this.endpoint("init"), {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          body: JSON.stringify({
            server_type: this.serverType,
            instance_type: this.instanceType,
            players: this.players,
            whitelisted_players: this.whitelist
              .split(",")
              .map((p) => p.trim())
              .filter((p) => p.length > 0),
            ...(this.serverType === "papermc"
              ? {
                  overworld_border: this.overworld,
                  nether_border: this.nether,
                }
              : {}),
          }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error("failed");
        this.$emit("complete", data.build_id);
      } catch (err) {
        console.error(err);
        this.message = "Provisioning failed.";
      }
    },
    submit() {
      this.initTenantServer();
    },
  },
};
</script>

<style scoped></style>
