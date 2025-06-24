<template>
  <div>
    <v-form @submit.prevent="submit">
      <v-select v-model="players" :items="playerOptions" label="Players" required></v-select>
      <v-checkbox v-model="pregen" label="Pregenerate world"></v-checkbox>
      <v-btn type="submit" color="deep-purple-accent-2" class="mt-2">Launch</v-btn>
    </v-form>
    <div class="mt-2">{{ message }}</div>
  </div>
</template>

<script>
export default {
  name: 'StepConfig',
  data() {
    return {
      players: 4,
      pregen: true,
      message: '',
      playerOptions: Array.from({ length: 20 }, (_, i) => i + 1),
    };
  },
  methods: {
    submit() {
      this.message = 'Provisioning your server...';
      setTimeout(() => {
        this.$emit('complete');
      }, 2000);
    },
  },
};
</script>

<style scoped>
</style>
