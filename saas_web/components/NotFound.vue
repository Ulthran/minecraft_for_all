<template>
  <ErrorPage
    title="404 - Page Not Found"
    icon="fas fa-question-circle"
    buddy-sheet="iron"
    :buddy-index="3"
  />
</template>

<script>
import ErrorPage from './ErrorPage.vue';
export default {
  name: 'NotFound',
  components: { ErrorPage },
};
</script>

<style scoped>
</style>
