# IAP Illustrated Assets v1

Created 13 November 2026 from the asset-aligned V4 concept. Scope: **starter_1, char_my, income_x2**. The other catalog SKUs do not yet have bespoke illustrations in this package.

## Contents

- `illustrations/hero_starter.png`: Linh presenting blue Pro/Standard packs, Pico and blue-orange garage.
- `illustrations/hero_driver_my.png`: My recruitment, silver sports coupe and garage.
- `illustrations/hero_income_x2.png`: excited Linh, business garage, cash and sports coupe. The multiplier is a dynamic UI label, not baked into the image.
- `sheets/characters.png`: real RGBA transparency; three waist-up poses.
- `resources/*.tres`: six Godot AtlasTexture resources, three full-scene textures and three character regions.
- `manifest.json`: dimensions, regions, hashes, references to existing reward icons and reusable UI assets.
- `preview.html`: open locally to view the three assembled popups and cutouts at mobile sizes; no server required. Prices and quantities are a snapshot of `data/iap.json` when packaged, not live store prices.

All three illustrations are **1536 × 1024** (3:2), with **no title, price, quantity, button or multiplier baked in**. Source pixels are unchanged. Character atlas boundaries are x=0/512/990/1536, not three equal cells: the right character extends left of x=1024. Empty gutter columns are checked by the packager.

The scenes and new character poses are generated drawings referenced to the game's existing assets; they are not identical pixel copies of the original character portraits. The existing yellow gem, green cash, blue/purple packs, green buy button and red close button remain the canonical UI assets. Do not use the scene illustration as an item-reward icon.

## Godot usage

Load `res://assets/iap_offers/resources/hero_starter.tres` into a TextureRect. Use `EXPAND_IGNORE_SIZE` and `STRETCH_KEEP_ASPECT_CENTERED`, with a 366 × 244 design area (or proportional smaller width). Keep the complete frame visible: aggressive banner crops can remove hands, packs and cars. Place the title above and reward shelf/CTA below. Do not overlay the bottom of the scene with opaque panels.

Load `linh_present.tres`, `my_welcome.tres` or `linh_victory.tres` for transparent banner characters. Keep aspect ratio; do not stretch each cell to the same width. They have transparent padding and soft semi-transparent edge shading, so test on the final panel color. Avoid displaying both a scene's baked character and the same cutout on top of it.

Use existing `HdUi` helpers for the panel, buy button and close button. UI text, local prices, quantities, state, multiplier and odds links are live controls. Characters, car and garage are illustrative; Starter does **not** grant Linh, a car or a building. Income art's money stacks illustrate the multiplier and are **not** a one-time cash reward. For My already owned, replace the character grant + 30 shards with **70 total shards**, rather than granting both.

## Rebuild and package

From repository root: `python tools/package_iap_assets.py`. This copies the original generated images, verifies image integrity and atlas gutters, emits resources/manifest/preview and rebuilds `Design/AssetPacks/Racing_IAP_Illustrated_v1.zip`. The source generation folder is recorded in the script and manifest; preserve the packaged PNGs when moving the project.

The ZIP keeps repository-relative paths and includes shared icon, pack atlas and surface dependencies used by the preview. Extract into the project root, preserving paths. No source image pixels are resized, cropped, recolored or background-removed during packaging.

Verification covers PNG integrity, real alpha, empty atlas gutters, resource paths and browser preview. Godot Editor import and native/device rendering remain unverified; gameplay UI is not integrated in this step.
