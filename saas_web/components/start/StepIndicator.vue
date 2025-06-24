<template>
  <div class="d-flex justify-center mb-4 align-center">
    <div
      v-for="n in total"
      :key="n"
      class="step-wrapper d-flex align-center"
    >
      <div
        class="step-circle"
        :class="{ done: n < step, active: n === step }"
      >
        {{ n }}
      </div>
      <div
        v-if="n < total"
        class="step-line"
        :class="{ done: n < step }"
      ></div>
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
.step-wrapper {
  display: flex;
  align-items: center;
}
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
  background-color: white;
}
.step-line {
  width: 40px;
  height: 2px;
  background-color: var(--v-theme-secondary);
  opacity: 0.3;
}
.step-circle.active,
.step-circle.done {
  background-color: var(--v-theme-secondary);
  color: white;
}
.step-line.done {
  opacity: 1;
}
</style>
