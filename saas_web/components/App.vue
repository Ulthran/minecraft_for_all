<template>
  <v-app>
    <v-app-bar color="secondary" dark>
      <v-toolbar-title>
        <router-link to="/" style="color: inherit; text-decoration: none;">Minecraft for All</router-link>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn to="/pricing" variant="text" router>Pricing</v-btn>
      <v-btn to="/support" variant="text" router>Support</v-btn>
      <v-btn to="/start" color="primary" router>Start</v-btn>
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
.v-application {
  background: transparent;
}
</style>
