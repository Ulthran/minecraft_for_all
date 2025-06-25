const { defineStore } = Pinia;

const useAuthStore = defineStore('auth', {
  state: () => ({
    loggedIn: !!localStorage.getItem('token'),
  }),
  actions: {
    updateLoggedIn() {
      this.loggedIn = !!localStorage.getItem('token');
    },
  },
});
window.useAuthStore = useAuthStore;
