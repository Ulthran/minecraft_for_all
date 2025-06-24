<template>
  <div class="d-flex justify-center mb-4 align-center">
    <div
      v-for="n in total"
      :key="n"
      class="step-wrapper d-flex align-center"
    >
      <div
        class="step-circle"
        :class="{ active: n === step }"
      >
        {{ n }}
      </div>
      <div
        v-if="n < total"
        class="step-line"
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
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 500;
  color: white;
  background-color: #603652;
}

.step-circle.active {
  border: 2px solid white;
  background-color: transparent;
}

.step-line {
  width: 40px;
  height: 2px;
  background-color: #603652;
}
</style>
