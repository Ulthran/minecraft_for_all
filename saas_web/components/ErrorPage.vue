<template>
  <v-container class="text-center">
    <i :class="`${icon} fa-3x mb-4`"></i>
    <BlockBuddy :sheet="buddySheet" :index="buddyIndex" />
    <h1>{{ title }}</h1>
    <slot>
      <p><a href="/">Return Home</a></p>
    </slot>
  </v-container>
</template>

<script>
export default {
  name: "ErrorPage",
  props: {
    title: { type: String, default: "Error" },
    icon: { type: String, default: "fas fa-exclamation-triangle" },
    buddySheet: { type: String, default: "emerald" },
    buddyIndex: { type: Number, default: 0 },
  },
};
</script>

<style scoped></style>
