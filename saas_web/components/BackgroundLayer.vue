<template>
  <div class="background-layer" aria-hidden="true">
    <div class="bg-image"></div>
    <BlockBuddy class="buddy" :sheet="sheet" :index="index" :size="size" />
  </div>
</template>

<script>
export default {
  name: "BackgroundLayer",
  props: {
    sheet: { type: String, default: "emerald" },
    index: { type: Number, default: 0 },
    size: { type: Number, default: 128 },
  },
  components: {
    BlockBuddy: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/BlockBuddy.vue`,
        window.loaderOptions,
      ),
    ),
  },
};
</script>

<style scoped>
.background-layer {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  overflow: hidden;
  z-index: 0;
}
.bg-image {
  position: absolute;
  top: -50%;
  left: -50%;
  right: -50%;
  bottom: -50%;
  background-image: url("assets/background.png");
  background-size: cover;
  animation: drift-bg 60s linear infinite;
}
.buddy {
  position: absolute;
  top: 20%;
  left: 10%;
  animation: drift-buddy 30s linear infinite alternate;
}
@keyframes drift-bg {
  from {
    transform: translate(0, 0);
  }
  to {
    transform: translate(-100px, -100px);
  }
}
@keyframes drift-buddy {
  from {
    transform: translate(0, 0);
  }
  to {
    transform: translate(80px, 40px);
  }
}
</style>
