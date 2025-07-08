<template>
  <div
    class="block-buddy-wrapper"
    :class="{ 'slow-float': float }"
    :style="wrapperStyle"
  >
    <img
      v-if="backgroundImage"
      :src="bgImageSrc"
      alt=""
      class="buddy-background"
    />
    <div v-if="message" class="speech-bubble" role="status" aria-live="polite">
      {{ message }}
    </div>
    <div
      class="block-buddy"
      :class="{ 'slow-float': float }"
      :style="style"
      aria-hidden="true"
    ></div>
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
    backgroundImage: { type: String, default: "" },
    float: { type: Boolean, default: false },
  },
  computed: {
    style() {
      const sheets = {
        emerald: "assets/emerald_block_buddies.png",
        iron: "assets/iron_ore_buddies.png",
        grassland: "assets/grassland_background.png",
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
        "background-image": `url(${sheets[this.sheet] || sheets.grassland})`,
        "background-size": `${sheetSize}px ${sheetSize}px`,
        "background-position": positions[this.index % 4],
        "image-rendering": "pixelated",
      };
    },
    bgImageSrc() {
      if (!this.backgroundImage) return "";
      let path = this.backgroundImage;
      if (!/^https?:\/\//.test(path) && !path.startsWith("assets/")) {
        path = `assets/${path}`;
      }
      return path;
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
        "background-repeat": "no-repeat",
        "background-size": "100% 100%",
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

.buddy-background {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  pointer-events: none;
  user-select: none;
  z-index: 0;
  border-radius: 50%;
}

.block-buddy {
  display: inline-block;
  position: relative;
  z-index: 1;
}

.slow-float {
  animation: slow-float 8s ease-in-out infinite alternate;
}

@keyframes slow-float {
  0% {
    transform: translate(0, 0) rotate(0deg);
  }
  100% {
    transform: translate(6px, -4px) rotate(3deg);
  }
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
