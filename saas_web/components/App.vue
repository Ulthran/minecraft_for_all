<template>
  <v-app>
    <v-app-bar color="secondary" dark app>
      <v-toolbar-title>
        <router-link to="/" style="color: inherit; text-decoration: none;">Minecraft for All</router-link>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn to="/pricing" variant="text" router>Pricing</v-btn>
      <v-btn to="/support" variant="text" router>Support</v-btn>
      <v-btn to="/about" variant="text" router>About Us</v-btn>
      <v-btn v-if="!loggedIn" to="/login" variant="text" router>Login</v-btn>
      <v-btn v-if="loggedIn" @click="logout" variant="text">Logout</v-btn>
      <v-btn v-if="loggedIn" to="/console" variant="text" router>Console</v-btn>
      <v-btn to="/start" color="primary" router>Start</v-btn>
    </v-app-bar>
    <v-main class="pa-15">
      <router-view></router-view>
    </v-main>
  </v-app>
</template>

<script>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
export default {
  name: 'App',
  setup() {
    const authState = ref(!!localStorage.getItem('token'));
    const logout = () => {
      localStorage.removeItem('token');
      localStorage.removeItem('urls');
      authState.value = false;
      router.push('/');
    };
    return { authState, logout };
  },
};
</script>
