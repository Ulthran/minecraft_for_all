<template>
  <v-app>
    <v-app-bar color="secondary" dark app>
      <router-link
        to="/"
        class="mr-2"
        style="min-width: 0; display: flex; align-items: center; text-decoration: none;"
      >
        <BlockBuddy sheet="iron" :index="0" :size="64" />
      </router-link>
      <v-spacer></v-spacer>
      <v-btn to="/pricing" variant="text" router>Pricing</v-btn>
      <v-btn to="/support" variant="text" router>Support</v-btn>
      <v-btn to="/privacy" variant="text" router>Privacy</v-btn>
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
const { computed } = Vue;
const { useRouter } = VueRouter;
const useAuthStore = window.useAuthStore;
const { Auth } = aws_amplify;
export default {
  name: 'App',
  components: {
    BlockBuddy: Vue.defineAsyncComponent(() =>
      window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/BlockBuddy.vue`, window.loaderOptions)
    ),
  },
  setup() {
    const router = useRouter();
    const auth = useAuthStore();
    const logout = async () => {
      localStorage.removeItem('urls');
      try {
        await Auth.signOut();
      } catch (_) {}
      auth.updateLoggedIn();
      router.push('/');
    };
    return { loggedIn: computed(() => auth.loggedIn), logout };
  },
};
</script>
