<template>
  <div class="block-buddy-wrapper" :style="wrapperStyle">
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
    background: { type: String, default: "" },
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
    wrapperStyle() {
      if (!this.background) return {};
      const size = `${this.size}px`;
      if (this.background === "gradient") {
        return {
          width: size,
          height: size,
          background:
            "radial-gradient(circle, rgba(240,229,196,0.8), rgba(240,229,196,0) 70%)",
          "border-radius": "50%",
        };
      }
      let path = this.background;
      if (!path.startsWith("assets/")) path = `assets/${path}`;
      return {
        width: size,
        height: size,
        "background-image": `url(${path})`,
        "background-size": "cover",
        "border-radius": "50%",
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
