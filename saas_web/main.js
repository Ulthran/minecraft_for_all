const options = {
  moduleCache: { vue: Vue },
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
    history: VueRouter.createWebHashHistory(),
    routes: [
      { path: '/', component: () => window['vue3-sfc-loader'].loadModule('./components/Home.vue', options) },
      { path: '/pricing', component: () => window['vue3-sfc-loader'].loadModule('./components/Pricing.vue', options) },
      { path: '/support', component: () => window['vue3-sfc-loader'].loadModule('./components/Support.vue', options) },
      { path: '/about', component: () => window['vue3-sfc-loader'].loadModule('./components/About.vue', options) },
      { path: '/start', component: () => window['vue3-sfc-loader'].loadModule('./components/Start.vue', options) },
    ],
  });

  const vuetify = Vuetify.createVuetify({
    theme: {
      defaultTheme: 'dark',
      themes: {
        dark: {
          colors: {
            background: '#1a1a2e',
            surface: '#1a1a2e',
            primary: '#81d4fa',
            secondary: '#b39ddb',
          },
        },
      },
    },
  });

  Vue.createApp(App).use(router).use(vuetify).mount('#app');
})();
