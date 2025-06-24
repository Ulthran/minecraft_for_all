<template>
  <div>
    <v-container>
      <v-row class="mb-6">
        <v-col>
          <h2 class="text-h5"><i class="fas fa-users mr-2"></i>Small servers, big fun</h2>
          <p>Launch a customizable Minecraft server with just a few clicks. Our simple web interface makes it easy to manage your world.</p>
        </v-col>
      </v-row>
      <v-row class="mb-6">
        <v-col>
          <h2 class="text-h5"><i class="fas fa-clock mr-2"></i>Only pay for uptime</h2>
          <p>No monthly commitments. Keep costs low by paying only while your server is running.</p>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="12" md="6" lg="5">
          <CostCalculator />
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
import CostCalculator from './CostCalculator.vue';
export default {
  name: 'Home',
  components: { CostCalculator },
};
</script>
