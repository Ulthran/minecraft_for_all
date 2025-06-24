const options = {
  moduleCache: {
    vue: Vue,
    'vue-router': VueRouter,
    'vue-jwt-decode': window['vue-jwt-decode'],
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

(async () => {
  const [App] = await Promise.all([
    window['vue3-sfc-loader'].loadModule('./components/App.vue', options),
  ]);

  const router = VueRouter.createRouter({
    history: VueRouter.createWebHistory(),
    routes: [
      { path: '/', component: () => window['vue3-sfc-loader'].loadModule('./components/Home.vue', options) },
      { path: '/pricing', component: () => window['vue3-sfc-loader'].loadModule('./components/Pricing.vue', options) },
      { path: '/support', component: () => window['vue3-sfc-loader'].loadModule('./components/Support.vue', options) },
      { path: '/about', component: () => window['vue3-sfc-loader'].loadModule('./components/About.vue', options) },
      { path: '/login', component: () => window['vue3-sfc-loader'].loadModule('./components/Login.vue', options) },
      { path: '/console', component: () => window['vue3-sfc-loader'].loadModule('./components/Console.vue', options) },
      { path: '/start', component: () => window['vue3-sfc-loader'].loadModule('./components/Start.vue', options) },
      { path: '/verify', component: () => window['vue3-sfc-loader'].loadModule('./components/Verify.vue', options) },
      { path: '/:pathMatch(.*)*', component: () => window['vue3-sfc-loader'].loadModule('./components/NotFound.vue', options) },
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
            primary: '#00e5ff',
            secondary: '#ff1493',
          },
        },
      },
    },
  });

  Vue.createApp(App).use(router).use(vuetify).mount('#app');
})();
