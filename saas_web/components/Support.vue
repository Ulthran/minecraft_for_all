<template>
  <v-container>
    <v-row class="justify-center mb-4">
      <BlockBuddy sheet="iron" :index="1" background="gradient" />
    </v-row>
    <v-row>
      <v-col>
        <h2 class="text-h5"><i class="fas fa-question-circle mr-2"></i>FAQ</h2>
        <p>
          <strong>How do I manage my server?</strong> Through our intuitive web
          console you can start, stop and configure your world easily. You can
          also interact directly with your world through the Minecraft console.
        </p>
        <p>
          <strong>Can I upload my existing world?</strong> Yes, you can upload
          and download world saves at any time.
        </p>
        <p>
          <strong>Need more help?</strong> Email us at
          <a href="mailto:help@xylblox.com">help@xylblox.com</a>.
        </p>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: "Support",
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

<style scoped></style>
