<template>
  <div class="block-buddy" :style="style" aria-hidden="true"></div>
</template>

<script>
export default {
  name: 'BlockBuddy',
  props: {
    sheet: { type: String, default: 'emerald' },
    index: { type: Number, default: 0 },
    size: { type: Number, default: 128 },
  },
  computed: {
    style() {
      const sheets = {
        emerald: 'assets/emerald_block_buddies.png',
        iron: 'assets/iron_ore_buddies.png',
      };
      const size = this.size;
      const sheetSize = size * 2;
      const positions = [
        '0px 0px',
        `-${size}px 0px`,
        `0px -${size}px`,
        `-${size}px -${size}px`,
      ];
      return {
        width: `${size}px`,
        height: `${size}px`,
        'background-image': `url(${sheets[this.sheet] || sheets.emerald})`,
        'background-size': `${sheetSize}px ${sheetSize}px`,
        'background-position': positions[this.index % 4],
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
