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
  width: 32px;
  height: 32px;
  border-radius: 2px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-family: 'Press Start 2P', cursive;
  color: #fff;
  background-color: #4caf50;
}

.step-circle.active {
  border: 2px solid #ffa500;
  background-color: #262626;
}

.step-line {
  width: 40px;
  height: 4px;
  background-color: #4caf50;
}
</style>
