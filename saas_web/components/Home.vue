<template>
  <div>
    <v-container fluid>
      <!-- Segment 1 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">
            The ONLY pure usage-based pricing available
          </h2>
          <p>
            We are the only Minecraft server hosting service that has NO FLAT
            MONTHLY RATES. If you don't use our services for the month, you'll
            pay $0!
          </p>
        </v-col>
        <v-col cols="12" md="6" class="text-center">
          <BlockBuddy
            sheet="iron"
            :index="0"
            :size="192"
            message="No minimums!"
            with-background
          />
        </v-col>
      </v-row>

      <!-- Segment 2 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6" class="text-center order-md-first order-last">
          <BlockBuddy sheet="emerald" :index="1" :size="192" with-background />
        </v-col>
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">Transparent pricing</h2>
          <p>
            You can track your usage of <i>compute</i>, <i>storage</i>, and
            <i>network bandwidth</i> in the Console.
          </p>
        </v-col>
      </v-row>

      <!-- Segment 3 -->
      <v-row class="py-16 segment" align="center" justify="center">
        <v-col cols="12" class="text-center">
          <v-btn color="primary" size="x-large" to="/start"> Start </v-btn>
        </v-col>
      </v-row>

      <!-- Segment 4 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6" class="text-center">
          <BlockBuddy
            sheet="diamond"
            :index="2"
            :size="192"
            message="Control your server!"
            with-background
          />
        </v-col>
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">Complete control</h2>
          <p>You are given complete control over the</p>
        </v-col>
      </v-row>

      <!-- Segment 5 -->
      <v-row class="py-16 segment" align="center">
        <v-col cols="12" md="6">
          <h2 class="text-h4 mb-4">
            Enterprise-level features for peace of mind
          </h2>
          <p>
            We provide all the "enterprise-level" features you'll see from other
            hosters such as automatic backups, DDoS protection, and more. Plus
            we've decoded what they even mean:
          </p>
        </v-col>
        <v-col cols="12" md="6" class="text-center">
          <v-list class="text-left">
            <v-list-item prepend-icon="fas fa-check">
              <v-list-item-content>
                <div>
                  <h3>Automatic backups</h3>
                  <p>
                    We automatically backup your server to our storage with
                    industry leading availability and durability
                    (99.999999999%).
                  </p>
                </div>
              </v-list-item-content>
            </v-list-item>
            <v-list-item prepend-icon="fas fa-check">
              <v-list-item-content>
                <div>
                  <h3>DDoS protection</h3>
                  <p>
                    Protection against a wide range of known attacks is standard
                    with every server you can use with us.
                  </p>
                </div>
              </v-list-item-content>
            </v-list-item>
            <v-list-item prepend-icon="fas fa-check">
              <v-list-item-content>
                <div>
                  <h3>Resource analytics</h3>
                  <p>
                    Dive deep on your resource usage to optimize costs for your
                    players. It's what we're built for!
                  </p>
                </div>
              </v-list-item-content>
            </v-list-item>
            <v-list-item prepend-icon="fas fa-check">
              <v-list-item-content>
                <div>
                  <h3>Global availability</h3>
                  <p>
                    We provide servers across 100+ availability zones, offering
                    near global single-digit millisecond ping times.
                  </p>
                </div>
              </v-list-item-content>
            </v-list-item>
          </v-list>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
export default {
  name: "Home",
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
.segment {
  min-height: 50vh;
}
</style>
