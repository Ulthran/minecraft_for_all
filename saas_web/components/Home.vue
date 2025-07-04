<template>
  <div>
    <v-container fluid>
      <!-- Segment 1 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">Only pay for what you use</h2>
          <p>We are the only pure-usage based pricing for Minecraft hosting available.</p>
        </v-col>
        <v-col cols="12" md="6" class="text-center">
          <BlockBuddy sheet="iron" :index="0" :size="192" />
        </v-col>
      </v-row>

      <!-- Segment 2 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6" class="text-center order-md-first order-last">
          <BlockBuddy sheet="emerald" :index="1" :size="192" />
        </v-col>
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">Transparent pricing</h2>
          <p>You pay only for compute, network and storage.</p>
        </v-col>
      </v-row>

      <!-- Segment 3 -->
      <v-row class="py-16 segment" align="center" justify="center">
        <v-col cols="12" class="text-center">
          <v-btn color="primary" size="x-large" to="/start">
            Start
          </v-btn>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
export default {
  name: 'Home',
  components: {
    BlockBuddy: Vue.defineAsyncComponent(() =>
      window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/BlockBuddy.vue`, window.loaderOptions)
    ),
  },
};
</script>

<style scoped>
.segment {
  min-height: 50vh;
}
</style>
