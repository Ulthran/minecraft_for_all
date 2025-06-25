<template>
  <div>
    <h2 class="text-h5 mb-2"><i class="fas fa-calculator mr-2"></i>Projected Cost Calculator</h2>
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
  </div>
</template>

<script>
const baseRates = {
  Vanilla: 0.0168,
  'Vanilla-ish PaperMC': 0.0336,
  'PaperMC (heavier mods)': 0.0832,
};

const styleMultipliers = {
  'Adventure and build bases together': 1,
  'We like to make a lot of farms': 1.5,
  "It's really best to have a villager breeder per chunk...": 2,
};

const hoursPerWeekToMonth = 4.3;
const storageRate = 0.08;
const dataTransferPerPlayerPerHour = 0.1;
const freeDataTransferGb = 1;
const dataTransferRate = 0.09;

const vcpuRate = 0.008;
const memoryRate = 0.004;

export default {
  name: 'CostCalculator',
  data() {
    return {
      statsMode: false,
      players: 4,
      playtime: 10,
      mod: 'Vanilla',
      mods: Object.keys(baseRates),
      worldSize: 1,
      playStyle: 'Adventure and build bases together',
      playStyles: Object.keys(styleMultipliers),
      vcpus: 2,
      memory: 4,
      uptime: 10,
      statsWorldSize: 1,
    };
  },
  computed: {
    projectedCost() {
      if (!this.statsMode) {
        const rate = baseRates[this.mod] ?? baseRates['Vanilla'];
        const styleMult = styleMultipliers[this.playStyle] ?? 1;
        const hoursPerMonth = this.playtime * hoursPerWeekToMonth;
        const server = rate * styleMult * hoursPerMonth;
        const dataOut = this.players * this.playtime * dataTransferPerPlayerPerHour * hoursPerWeekToMonth;
        const dataCost = Math.max(0, dataOut - freeDataTransferGb) * dataTransferRate;
        const storage = this.worldSize * storageRate;
        return (server + dataCost + storage).toFixed(2);
      }
      const hoursPerMonth = this.uptime * hoursPerWeekToMonth;
      const rate = this.vcpus * vcpuRate + this.memory * memoryRate;
      const server = rate * hoursPerMonth;
      const storage = this.statsWorldSize * storageRate;
      return (server + storage).toFixed(2);
    },
  },
};
</script>

<style scoped>
</style>

