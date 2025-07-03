<template>
  <v-app>
    <v-main class="d-flex align-center justify-center">
      <v-container class="text-center">
        <BlockBuddy sheet="iron" :index="3" class="mb-4" />
        <i class="fas fa-exclamation-triangle fa-3x mb-4"></i>
        <h1>Oops! Something went wrong.</h1>
        <p>Please try again later. <a href="/">Return Home</a></p>
      </v-container>
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: 'Error50x',
  components: {
    BlockBuddy: Vue.defineAsyncComponent(() =>
      window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/BlockBuddy.vue`, window.loaderOptions)
    ),
  },
};
</script>

<style scoped>
a { color: #89cff0; }
h1 { color: #ffb6c1; }
</style>
