# Branding

This document proposes a playful yet professional brand identity for the Minecraft hosting service.

## Name & Domain Ideas
Feedback suggested avoiding "Craft Pals" in favor of original names. Below are
some invented words with no apparent brand associations. Domains were checked
via `nslookup` and returned **NXDOMAIN** at the time of writing.

- **Phthimble** – whimsical and unique. Example domain: `phthimble.com`.
- **Xylblox** – references blocks without direct Minecraft usage. Example domain: `xylblox.com`.
- **Mubtor** – short and punchy. Example domain: `mubtor.io`.
- **Yivcraft** – playful yet readable. Example domain: `yivcraft.net`.
- **Loftrix** – suggests building and creativity. Example domain: `loftrix.com`.

## Tone and Personality
- **Goofy/friendly**: approachable language, bright accent colors.
- **Clean and professional**: straightforward layout with minimal clutter, easy navigation.

## Visual Concepts
- Pixel art styled after Minecraft textures.
- Personified block characters ("Block Buddy") acting as mascots.
- Primary palette: warm browns and greens with accent colors for a playful pop.

## Asset Specs

### Iron Ore Buddy

🧱 Iron Ore Creature - Pixel Art Design Description
Base Form:

Body: Square block (16x16 pixels for default, scaleable), visually matching Minecraft’s iron ore block with a friendly twist.

Color Palette: Stone gray base with rusty orange and brown ore speckles — slightly exaggerated to read better in small resolution.

Expression: Big, happy pixel eyes (2x2 pixels each), simple smiling mouth—friendly and curious.

Limbs:

Arms & Legs: Stick-figure style!

Thin black or dark-gray lines (1 pixel wide).

Limbs have simple curves to show different gestures (e.g., waving, pointing, or holding a tooltip sign).

Hands/feet: Optional tiny mittens/boots (2x2 pixel blobs) to add personality.

Pose:
This one is in a welcoming pose—waving with one hand, standing upright with legs apart for a balanced, inviting look.

Cute Fact:
This iron ore creature likes to offer “solid” advice and is really good at helping new players get started. It secretly dreams of becoming a golem one day!

✅ Asset Use Ideas
Appears beside tooltips and tips.

Stands next to server uptime or player count panels.

Gives little tutorials on how to join a server.

I'll now generate a low-res pixel art image of this Iron Ore Helper Block in a few styles so you can choose the direction you'd like to go. Generating now... 🎨

🧱 Generating Pixel Art - Iron Ore Helper Block (Various Styles & Poses)
Styles include: chibi, classic pixel simplicity, slightly detailed variant, and one with more expressive poses.

{"prompt":"Pixel art of a cute Minecraft-inspired iron ore block creature with stick-figure arms and legs. It has big eyes and a friendly smile. The block looks like Minecraft's iron ore with stone texture and brown/orange ore speckles. The creature is waving hello in one version, standing with arms out in another. Display 4 variations in pixel art style, 16x16 block size, low resolution, 2D side view.","num_images":4,"size":"256x256","style":"pixel art"}

### Emerald Block Buddy

💎 Emerald Block Creature – “Pricing & Billing Buddy”
Pixel Art Design Description

📦 Body
Shape: 16x16 square block, Minecraft-style.

Texture: Emerald block-style (not the ore), so:

Base color: Vibrant emerald green (#00C080 to #007750 gradient).

Subtle shimmering lines to resemble facets or the block’s beveled square pattern.

Add a few bright highlight streaks to suggest shininess.

😊 Face
Eyes: Larger, bright teal or white 2x2 eyes with twinkles (friendly, knowledgeable look).

Mouth: Small confident smile — this creature knows its math.

🦾 Arms & Legs (Stick-Figure Style)
Arms: Stick-style, 1 pixel wide, darker green or black.

Hands: Optional small “coin” or ledger in one hand (can be just a yellow circle or tan rectangle).

Legs: Positioned firmly — stable, like a reliable accountant.

Pose Suggestions:

One arm holding a “$” sign or a scroll.

One waving, one arm outstretched toward a pricing chart.

Standing on a small stack of coins (2-3 pixels tall).

✨ Cute Personality Fact
This little buddy loves spreadsheets and always balances your books — even if you accidentally bought 12 servers instead of one. Their favorite number is 64 (because that’s a stack!).

🧠 Function on Website
Pops up during plan selection, upgrade prompts, or when asking billing questions.

Can animate a wink or coin flip when hovering over premium features.

May say lines like:

“Looking for value? I’ve got stacks!”

“Need help choosing the right plan?”

### Speech Bubbles


💬 Speech Bubble System – Pixel Art Spec
🧱 1. Style & Aesthetic
Resolution: Designed for 8x8 or 16x16 tile scaling, so it’s modular and can grow/shrink easily.

Look: Clean pixel border (1–2 pixels thick), with square corners or slightly rounded square (not smooth, no anti-aliasing).

Outline: Dark gray or black (#222 or #111), depending on theme contrast.

Fill:

Default: Off-white or light gray (#F4F4F4 / #DDDDDD)

Optional: Slightly tinted fill for roles (e.g., greenish for Emerald, orange for Iron, blue for Diamond)

🟩 Stays consistent with blocky, low-res Minecraft vibe. Think NES/SNES RPG dialog boxes, but more compact.

🔲 2. Scalable Structure (9-Slice Style)
To make the bubbles expandable based on content, we design them with a 9-slice layout:

css
Copy
Edit
[TL][T ][TR]
[L ][C ][R ]
[BL][B ][BR]
Each corner and edge is a separate tile (8x8 or 16x16), and the center tile can be repeated horizontally or vertically to scale the bubble up.

Corners (TL, TR, BL, BR): Fixed L-shaped pieces.

Edges (T, B, L, R): 1-tile strips that tile along sides.

Center (C): Empty or lightly patterned for large text bodies.

🗨️ 3. Tail Attachment (Buddy “Pointer”)
Small triangle or rectangular pointer (5x5 or 8x8) that can be anchored on any side.

Points toward the buddy's head or hand.

Can be rotated or mirrored for placement on:

Bottom-left (default for top pop-ups)

Top-right (default for footer tips)

Left/right (for side tooltips)

💬 4. Text Guidelines
Font: Pixel font or monospace, preferably 5x5 or 6x6 pixel character height.

Padding: At least 1 tile (8 pixels) of space between text and borders.

Max width: About 5–8 words per line for readability.

🧰 Optional Variants
🟩 Emerald Buddy (Billing): Emerald-tinted frame

🧱 Iron Buddy (Help Tips): Blocky stone border

💎 Diamond Buddy (Premium Notices): Sparkly/cyan border

🔥 Error or Warning: Red or orange border, zigzag edge

📦 Export Format
You can export each part as:

Individual 8x8 PNG tiles

Or one full sprite sheet (e.g., 48x48 or 64x64) with a layout key

### Village Background

 Minecraft Village Background – Pixel Art Spec
🧱 1. Purpose
A backdrop for your block buddies (like the Iron or Emerald helper) to stand in front of, especially when:

Giving tips

Appearing in pop-ups

Standing near buttons or floating UI cards

It should not be a full scene but rather a partial diorama-style background, enough to give depth and context.

🎨 2. Dimensions
Default size: 128x64 or 128x96 pixels (scalable to fit buddy + bubble)

Tile Style: Still built on a 16x16 tile grid for visual consistency

Resolution: True pixel art, with block textures matching Minecraft (stone, wood, grass, etc.)

🏘️ 3. Visual Elements
🧱 Foreground (bottom half)
Path: Dirt or gravel with pixel shading (like Minecraft paths)

Foliage: A couple tufts of pixelated grass or a flower

Fence: Wooden fence posts (2–3 tiles wide) for framing

Villager House Wall: Cobblestone base with oak wood planks and window; maybe 1 door

🌳 Background (middle to top)
Sky: Flat blue with optional clouds (no dithering)

Tree Tops: Oak tree pixel canopy peeking in from the edge

Roof: One thatched/stair-stepped roof (partial, 3–4 tiles wide) behind the buddy

🎨 4. Pixelated Border (Edge Fade Effect)
Rough, irregular outline

~4–8 pixels of "fuzzy" edge blending into transparency

Uses scattered filler pixels (like blurred grass, sky speckles, etc.)

Maintains sharp pixel style, no gradients or anti-aliasing

Imagine it as a “cut-out” sticker feel — the background has been roughly popped out from a Minecraft world, and plopped behind your buddy.

🧩 5. Export/Usage Format
PNG with transparent background outside the faded edge

Works with both light and dark mode (dark site backdrop assumed)

Can be placed behind buddy + speech bubble or layered under popup panels

💡 Use Cases
Iron Buddy appears here when giving new user tips

Emerald Buddy stands in front of a villager house when explaining pricing

Future buddies (like a Slime Moderator) could get swamp or plains-themed variants