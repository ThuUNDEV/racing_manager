# Shop v9 — runtime review

Approved reference: `Design/Demos/SoftMiniature/approved/shop_v9/shop.png` (user attachment selected 26/11/2026).

Implementation uses native Godot Controls, live labels, native buttons and local Shop styles. Gold rounded special cards, subdued gray-cream surfaces, azure purchases, pale-blue videos and green FREE follow the selected reference. Existing catalog/eligibility and reward identity remain authoritative.

## Evidence

- `320_*`, `390_*`, `412_*`: actual Forward+ viewport renders on secondary screen with Dummy audio and isolated XDG_DATA_HOME.
- `geometry.json`: SceneTree measurements, logical units, same catalog fixture as captures.
- `runtime-board.png`: three actual 390px viewport renders composed as a review board.
- `comparison.png`: approved demo (left) and actual runtime board (right), uniformly scaled, no hiding or stretching of content.

## Validation

`tests/shop_demo_v9_ui_test.gd` checks native purchase clicks, inert card-body clicks (no detail popup or purchase), store busy/owned visibility, scroll retention, three currency columns, containment and 44px targets at 320/390/412 in all eight languages. `shop_merged_gift_test.gd` covers daily-to-video flow. `shop_packs_test.gd` covers x1/x10 payment, coupon identity, rates and shortcuts. `pack_promo_popup_test.gd` covers existing popup regressions; `boot_test.gd` covers startup; `tools/i18n_check.py` checks keys/placeholders.

## Material differences from the bitmap concept

- Larger native 44px touch targets and translated labels make some cards taller. The second viewport needs a little more scroll to see the second pack row; all content remains accessible.
- The actual driver in starter2 is Marchetti, using the current catalog portrait, not the illustrative Hà placeholder in the concept.
- Existing proper assets are reused for helmets/toolboxes/gem chests; coupon tiers retain their actual red/gold/purple identities.
- Cash exchange remains upcoming (unchanged behavior); duration previews follow Design/28 §4.8 rather than the prior dummy B values. No economy/purchase/save logic was added.
- Global resource header and bottom navigation retain the game's existing art rather than raster text from the concept.
- Godot logs still include resource/RID cleanup warnings at exit; the boot test also reproduces these. They are distinct from parse/runtime script failures.

The daily gear gift sprite was regenerated with `gpt-image-2.5-flare --quality low` from the demo crop after extraction/upscale QA, then background removed through art-tools. Provenance: `assets/shop_demo_v9/manifest.json`.
