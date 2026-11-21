# promotion_ui_v1

Runtime art for `ui/promotion_popup.gd`, matched to `Design/Demos/PromotionPopup/flare_A.png`. Text, values, league shields, and button states remain live Godot nodes.

| File | Use | Source |
|---|---|---|
| check_ok.png | Passed requirement | Existing Flare icon, transparent, max 192px |
| check_no.png | Legacy exclamation icon (unused) | Existing Flare icon |
| arrow_gold.png | League progression | Existing Flare icon, transparent, max 192px |
| league_backdrop.png | Sky, trees and track behind shields | Flare reference edit of approved demo, 1536×1024, opaque |
| car_requirement.png | Rounded red car requirement icon | Flare reference edit of approved demo, 1024×1024, RGBA |
| check_cross.png | Failed requirement | Flare edit of check_no.png replacing ! with X, 1024×1024, RGBA |
| skins/*.svg | Cream shell, colored tiles, pills, reward tray and CTA | Code-native SVG gradients and bevels, rendered as nine-slice StyleBoxTexture |

New raster assets generated with `tools/gen_image.py`, `gpt-image-2.5-flare`, quality `low` on 2026-11-20. Generation metadata is recorded in `manifest.json`. No generated text or values are baked into these assets. The ribbon, close button, cash, coins, gems and league shields reuse existing asset packs.
