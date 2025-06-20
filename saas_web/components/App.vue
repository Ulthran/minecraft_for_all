<template>
  <v-app>
    <v-app-bar color="deep-purple-darken-4" dark>
      <v-toolbar-title>Minecraft for All</v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn to="/pricing" variant="text" router>Pricing</v-btn>
      <v-btn to="/support" variant="text" router>Support</v-btn>
      <v-btn to="/start" color="deep-purple-accent-2" router>Start</v-btn>
    </v-app-bar>
    <v-main class="py-4">
      <router-view></router-view>
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: 'App',
};
</script>

<style scoped>
</style>
