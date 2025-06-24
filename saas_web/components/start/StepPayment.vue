<template>
  <div>
    <h3 class="text-h6 mb-2">Payment Setup</h3>
    <p class="mb-2">Payment integration coming soon.</p>
      <v-btn color="secondary" @click="$emit('complete')">Complete Payment</v-btn>
  </div>
</template>

<script>
export default { name: 'StepPayment' };
</script>

<style scoped>
</style>
