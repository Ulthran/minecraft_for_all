<template>
  <div class="block-buddy" :style="style"></div>
</template>

<script>
export default {
  name: 'BlockBuddy',
  props: {
    sheet: { type: String, default: 'emerald' },
    index: { type: Number, default: 0 },
  },
  computed: {
    style() {
      const sheets = {
        emerald: 'assets/emerald_block_buddies.png',
        iron: 'assets/iron_ore_buddies.png',
      };
      const pos = [
        '0px 0px',
        '-128px 0px',
        '0px -128px',
        '-128px -128px',
      ];
      return {
        width: '128px',
        height: '128px',
        'background-image': `url(${sheets[this.sheet] || sheets.emerald})`,
        'background-size': '256px 256px',
        'background-position': pos[this.index % 4],
        'image-rendering': 'pixelated',
      };
    },
  },
};
</script>

<style scoped>
.block-buddy {
  display: inline-block;
}
</style>
