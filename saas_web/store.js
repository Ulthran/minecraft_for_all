import { defineStore } from 'pinia';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    loggedIn: !!localStorage.getItem('token'),
  }),
  actions: {
    updateLoggedIn() {
      this.loggedIn = !!localStorage.getItem('token');
    },
  },
});
