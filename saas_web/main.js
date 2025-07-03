const options = {
  moduleCache: {
    vue: Vue,
    'vue-router': VueRouter,
    pinia: Pinia,
    'aws-amplify': aws_amplify,
  },
  async getFile(url) {
    const res = await fetch(url);
    if (!res.ok) throw Object.assign(new Error(res.statusText + ' ' + url), { res });
    return {
      getContentData: asBinary => asBinary ? res.arrayBuffer() : res.text(),
    };
  },
  addStyle(textContent) {
    const style = Object.assign(document.createElement('style'), { textContent });
    const ref = document.head.getElementsByTagName('style')[0] || null;
    document.head.insertBefore(style, ref);
  },
};
window.loaderOptions = options;
window.componentsPath = './components';

(async () => {
  const [App] = await Promise.all([
    window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/App.vue`, options),
  ]);

  const router = VueRouter.createRouter({
    history: VueRouter.createWebHistory(),
    routes: [
      { path: '/', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Home.vue`, options) },
      { path: '/pricing', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Pricing.vue`, options) },
      { path: '/support', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Support.vue`, options) },
      { path: '/privacy', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/DataPrivacy.vue`, options) },
      { path: '/about', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/About.vue`, options) },
      { path: '/login', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Login.vue`, options) },
      { path: '/console', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Console.vue`, options) },
      { path: '/start', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/Start.vue`, options) },
      { path: '/404', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/NotFound.vue`, options) },
      { path: '/error', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/ServerError.vue`, options) },
      // Debug routes to view individual steps without the wizard
      { path: '/debug-payment', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/start/StepPayment.vue`, options) },
      { path: '/debug-config', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/start/StepConfig.vue`, options) },
      { path: '/:pathMatch(.*)*', component: () => window['vue3-sfc-loader'].loadModule(`${window.componentsPath}/NotFound.vue`, options) },
    ],
  });

  const vuetify = Vuetify.createVuetify({
    theme: {
      defaultTheme: 'dark',
      themes: {
          dark: {
            colors: {
              background: '#000000',
              surface: '#1a1a2e',
              primary: '#89cff0',
              secondary: '#ffb6c1',
            },
          },
      },
    },
  });

  const pinia = Pinia.createPinia();
  const auth = window.useAuthStore(pinia);

  router.beforeEach((to, from, next) => {
    auth.updateLoggedIn();
    if (to.path === '/start' && auth.loggedIn) {
      next('/console');
    } else {
      next();
    }
  });

  Vue.createApp(App).use(router).use(vuetify).use(pinia).mount('#app');
})();
