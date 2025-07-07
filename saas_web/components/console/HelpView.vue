<template>
  <Support />
</template>

<script>
export default {
  name: "HelpView",
  components: {
    Support: Vue.defineAsyncComponent(() =>
      window["vue3-sfc-loader"].loadModule(
        `${window.componentsPath}/Support.vue`,
        window.loaderOptions,
      ),
    ),
  },
};
</script>

<style scoped></style>
