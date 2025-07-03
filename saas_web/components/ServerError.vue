<template>
  <ErrorPage
    title="Oops! Something went wrong."
    icon="fas fa-exclamation-triangle"
    buddy-sheet="iron"
    :buddy-index="1"
  >
    <p>Please try again later. <a href="/">Return Home</a></p>
  </ErrorPage>
</template>

<script>
import ErrorPage from './ErrorPage.vue';
export default {
  name: 'ServerError',
  components: { ErrorPage },
};
</script>

<style scoped>
</style>
