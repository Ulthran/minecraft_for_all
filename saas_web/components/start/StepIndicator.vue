<template>
  <div class="d-flex justify-center mb-4">
    <div
      v-for="n in total"
      :key="n"
      class="step-circle mx-1"
      :class="{ done: n < step, active: n === step }"
    >
      {{ n }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'StepIndicator',
  props: {
    step: { type: Number, required: true },
    total: { type: Number, default: 3 },
  },
};
</script>

<style scoped>
.step-circle {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid var(--v-theme-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--v-theme-secondary);
  font-weight: 500;
}
.step-circle.active,
.step-circle.done {
  background-color: var(--v-theme-secondary);
  color: white;
}
</style>
