<template>
  <div>
    <v-container>
      <v-row class="mb-6">
        <v-col>
          <h2 class="text-h5">Small servers, big fun</h2>
          <p>Launch a customizable Minecraft server with just a few clicks. Our simple web interface makes it easy to manage your world.</p>
        </v-col>
      </v-row>
      <v-row class="mb-6">
        <v-col>
          <h2 class="text-h5">Only pay for uptime</h2>
          <p>No monthly commitments. Keep costs low by paying only while your server is running.</p>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="12" md="6" lg="5">
          <h2 class="text-h5 mb-2">Projected Cost Calculator</h2>
          <v-form>
            <v-switch v-model="statsMode" label="Stats mode" class="mb-4"></v-switch>
            <div v-if="!statsMode">
              <v-text-field v-model.number="players" label="Expected number of players" type="number"></v-text-field>
              <v-text-field v-model.number="playtime" label="Expected playtime per week (hrs)" type="number"></v-text-field>
              <v-select v-model="mod" :items="mods" label="Mod options"></v-select>
              <v-expansion-panels multiple>
                <v-expansion-panel>
                  <v-expansion-panel-title>Advanced</v-expansion-panel-title>
                  <v-expansion-panel-text>
                    <v-text-field v-model.number="worldSize" label="Expected world size (GB)" type="number"></v-text-field>
                    <v-select v-model="playStyle" :items="playStyles" label="Play style"></v-select>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>
            </div>
            <div v-else>
              <v-text-field v-model.number="vcpus" label="vCPUs" type="number"></v-text-field>
              <v-text-field v-model.number="memory" label="Memory (GB)" type="number"></v-text-field>
              <v-text-field v-model.number="uptime" label="Uptime per week (hrs)" type="number"></v-text-field>
              <v-text-field v-model.number="statsWorldSize" label="World size (GB)" type="number"></v-text-field>
            </div>
            <div class="mt-4">Estimated monthly cost: ${{ projectedCost }}</div>
          </v-form>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
export default {
  name: 'Home',
  data() {
    return {
      statsMode: false,
      players: 4,
      playtime: 10,
      mod: 'Vanilla',
      mods: ['Vanilla', 'Vanilla-ish PaperMC', 'PaperMC (heavier mods)'],
      worldSize: 1,
      playStyle: 'Adventure and build bases together',
      playStyles: [
        'Adventure and build bases together',
        'We like to make a lot of farms',
        "It's really best to have a villager breeder per chunk...",
      ],
      vcpus: 2,
      memory: 4,
      uptime: 10,
      statsWorldSize: 1,
    };
  },
  computed: {
    projectedCost() {
      if (!this.statsMode) {
        const rateMap = {
          Vanilla: 0.0168,
          'Vanilla-ish PaperMC': 0.0336,
          'PaperMC (heavier mods)': 0.0832,
        };
        const styleMap = {
          'Adventure and build bases together': 1,
          'We like to make a lot of farms': 1.5,
          "It's really best to have a villager breeder per chunk...": 2,
        };
        const rate = rateMap[this.mod] ?? 0.0168;
        const styleMult = styleMap[this.playStyle] ?? 1;
        const hoursPerMonth = this.playtime * 4.3;
        const server = rate * styleMult * hoursPerMonth;
        const dataOut = this.players * this.playtime * 0.1 * 4.3;
        const dataCost = Math.max(0, dataOut - 1) * 0.09;
        const storage = this.worldSize * 0.08;
        return (server + dataCost + storage).toFixed(2);
      }
      const hoursPerMonth = this.uptime * 4.3;
      const rate = this.vcpus * 0.008 + this.memory * 0.004;
      const server = rate * hoursPerMonth;
      const storage = this.statsWorldSize * 0.08;
      return (server + storage).toFixed(2);
    },
  },
};
</script>
