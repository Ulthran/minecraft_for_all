<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8" lg="6">
        <h2 class="text-h5 mb-4">Start your server</h2>
        <StepIndicator :step="step" />
        <StepAccount v-if="step === 1" @complete="step = 2" />
        <StepPayment v-else-if="step === 2" @complete="step = 3" />
        <StepConfig v-else-if="step === 3" @complete="goConsole" />
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import StepAccount from './start/StepAccount.vue';
import StepPayment from './start/StepPayment.vue';
import StepConfig from './start/StepConfig.vue';
import StepIndicator from './start/StepIndicator.vue';

export default {
  name: 'Start',
  components: { StepAccount, StepPayment, StepConfig, StepIndicator },
  data() {
    return { step: 1 };
  },
  methods: {
    goConsole() {
      this.$router.push('/console');
    },
  },
};
</script>

<style scoped>
</style>
