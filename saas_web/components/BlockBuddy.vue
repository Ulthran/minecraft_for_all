<template>
  <div :class="wrapperClass">
    <div v-if="background" class="bg-image" aria-hidden="true"></div>
    <div v-if="message" class="speech-bubble" role="status" aria-live="polite">
      {{ message }}
    </div>
    <div class="block-buddy" :style="style" aria-hidden="true"></div>
  </div>
</template>

<script>
export default {
  name: "BlockBuddy",
  props: {
    sheet: { type: String, default: "emerald" },
    index: { type: Number, default: 0 },
    size: { type: Number, default: 128 },
    background: { type: Boolean, default: false },
    message: { type: String, default: "" },
  },
  computed: {
    style() {
      const sheets = {
        emerald: "assets/emerald_block_buddies.png",
        iron: "assets/iron_ore_buddies.png",
      };
      const size = this.size;
      const sheetSize = size * 2;
      const positions = [
        "0px 0px",
        `-${size}px 0px`,
        `0px -${size}px`,
        `-${size}px -${size}px`,
      ];
      return {
        width: `${size}px`,
        height: `${size}px`,
        "background-image": `url(${sheets[this.sheet] || sheets.emerald})`,
        "background-size": `${sheetSize}px ${sheetSize}px`,
        "background-position": positions[this.index % 4],
        "image-rendering": "pixelated",
      };
    },
    wrapperClass() {
      return {
        "block-buddy-wrapper": true,
        background: this.background,
      };
    },
  },
};
</script>

<style scoped>
.block-buddy-wrapper {
  position: relative;
  display: inline-block;
}

.block-buddy-wrapper.background {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  overflow: hidden;
  z-index: 0;
}

.bg-image {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: url("assets/background.png");
  background-size: cover;
}

.block-buddy-wrapper.background .block-buddy {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.block-buddy {
  display: inline-block;
}

.speech-bubble {
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: #fff;
  border: 2px solid #000;
  padding: 4px 8px;
  border-radius: 4px;
  color: #000;
  white-space: nowrap;
  font-size: 0.75rem;
}

.speech-bubble::after {
  content: "";
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border: 6px solid transparent;
  border-top-color: #fff;
}
</style>
