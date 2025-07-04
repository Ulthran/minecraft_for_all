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
      <div class="d-none d-md-flex align-center">
        <v-btn to="/pricing" variant="text" router>Pricing</v-btn>
        <v-btn to="/support" variant="text" router>Support</v-btn>
        <v-btn to="/privacy" variant="text" router>Privacy</v-btn>
        <v-btn to="/about" variant="text" router>About Us</v-btn>
        <v-btn v-if="!loggedIn" to="/login" variant="text" router>Login</v-btn>
        <v-btn v-if="loggedIn" @click="logout" variant="text">Logout</v-btn>
        <v-btn v-if="loggedIn" to="/console" variant="text" router>Console</v-btn>
        <v-btn to="/start" color="primary" router>Start</v-btn>
      </div>
      <div class="d-md-none">
        <v-menu location="bottom end">
          <template #activator="{ props }">
            <v-btn icon v-bind="props">
              <i class="fas fa-bars"></i>
            </v-btn>
          </template>
          <v-list>
          <v-list-item to="/pricing" link><v-list-item-title>Pricing</v-list-item-title></v-list-item>
          <v-list-item to="/support" link><v-list-item-title>Support</v-list-item-title></v-list-item>
          <v-list-item to="/privacy" link><v-list-item-title>Privacy</v-list-item-title></v-list-item>
          <v-list-item to="/about" link><v-list-item-title>About Us</v-list-item-title></v-list-item>
          <v-list-item v-if="!loggedIn" to="/login" link><v-list-item-title>Login</v-list-item-title></v-list-item>
          <v-list-item v-if="loggedIn" @click="logout"><v-list-item-title>Logout</v-list-item-title></v-list-item>
          <v-list-item v-if="loggedIn" to="/console" link><v-list-item-title>Console</v-list-item-title></v-list-item>
          <v-list-item to="/start" link><v-list-item-title>Start</v-list-item-title></v-list-item>
          </v-list>
        </v-menu>
      </div>
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
