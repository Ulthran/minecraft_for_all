<template>
  <div>
    <v-form @submit.prevent="submit">
      <v-select v-model="serverType" :items="serverTypeOptions" label="Server Type" required></v-select>
      <v-select v-model="instanceType" :items="instanceTypeOptions" label="Instance Type" required></v-select>
      <v-select v-model="players" :items="playerOptions" label="Players" required></v-select>
      <v-text-field v-model.number="overworld" label="Overworld Border Radius" type="number" required></v-text-field>
      <v-text-field v-model.number="nether" label="Nether Border Radius" type="number" required></v-text-field>
      <v-checkbox v-model="pregen" label="Pregenerate world"></v-checkbox>
      <v-btn type="submit" color="secondary" class="mt-2">Launch</v-btn>
    </v-form>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
import VueJwtDecode from 'vue-jwt-decode'
export default {
  name: 'StepConfig',
  data() {
    return {
      serverType: 'papermc',
      instanceType: 't4g.medium',
      players: 4,
      overworld: 3000,
      nether: 3000,
      pregen: false,
      message: '',
      serverTypeOptions: ['papermc', 'vanilla'],
      instanceTypeOptions: ['t4g.small', 't4g.medium', 't4g.large'],
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
    };
  },
  methods: {
    async initTenantServer() {
      this.message = 'Provisioning your server...';
      const token = localStorage.getItem('token');
      let tenantId = '';
      if (token) {
        try {
          const payload = VueJwtDecode.decode(token);
          tenantId = payload['custom:tenant_id'] || '';
        } catch (e) {
          console.error('Failed to decode token', e);
        }
      }
      try {
        const res = await fetch('INIT_SERVER_API_URL', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          body: JSON.stringify({
            tenant_id: tenantId,
            server_type: this.serverType,
            instance_type: this.instanceType,
            players: this.players,
            pregen: this.pregen,
            overworld_border: this.overworld,
            nether_border: this.nether,
          }),
        });
        if (!res.ok) throw new Error('failed');
        this.$emit('complete');
      } catch (err) {
        console.error(err);
        this.message = 'Provisioning failed.';
      }
    },
    submit() {
      this.initTenantServer();
    },
  },
};
</script>

<style scoped>
</style>
