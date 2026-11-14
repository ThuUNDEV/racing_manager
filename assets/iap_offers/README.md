# Racing IAP Complete Art Kit v2

Created 13 November 2026. Artwork now covers **all 30 SKUs in data/iap.json**, with shared family art and per-SKU scene recipes. This supersedes the earlier three-pack v1 package. It does not connect purchase UI to gameplay.

## Contents

| Component | Count | Location |
|---|---:|---|
| Scene illustrations / recruitment backgrounds | 15 | 3 standalone PNGs + 12 regions across 3 scene sheets |
| Transparent character poses | 9 | 3 RGBA sheets; Linh, My, Hà, Lâm, Nhân, Phương, Quang, Sơn |
| Blank panel skins | 4 | Blue, purple, gold, teal; ui_panels.png |
| Blank button skins | 6 | Normal/hover/pressed/disabled purchase, blue secondary, amber secondary; ui_buttons.png |
| AtlasTexture resources | 34 | resources/ |
| StyleBoxTexture 9-slice resources | 10 | styles/ |
| Per-SKU artwork scenes | 30 | art/<sku>.tscn |
| Source PNG files | 11 | illustrations/ and sheets/ |

Existing yellow gem, green cash, coupon packs, portrait reward icons and red close button remain canonical and are included as ZIP dependencies. No text, price or reward quantity is baked into the new artwork. The income source filename hero_income_x2 is historical; it contains no multiplier numeral and serves ×2 / ×3 / ×2→×3 through separate UI text.

## Backgrounds and buttons

The 15 hero/backdrop textures illustrate benefits and supply a scene for characters. They are separate from the four blank panel skins used behind popup content or reward shelves. The dim overlay is a runtime ColorRect using manifest backdrop_color, not a raster image.

Six button textures include the four core purchase states. Use a dynamic spinner/label for busy/pending over the normal button, rather than baking localized wording into PNG. Blue/amber are secondary actions; red close uses the existing SVG. Selection/focus rings are runtime controls.

The original surfaces are high-resolution. **Use iap_skin.gd to scale their 9-slice borders to logical screen pixels**, following the project's existing HdUi image-cache approach. The helper only creates runtime ImageTextures and never edits source files:

```gdscript
var Skin = preload("res://assets/iap_offers/iap_skin.gd")
button.add_theme_stylebox_override("normal", Skin.style("buy_normal"))
button.add_theme_stylebox_override("hover", Skin.style("buy_hover"))
button.add_theme_stylebox_override("pressed", Skin.style("buy_pressed"))
button.add_theme_stylebox_override("disabled", Skin.style("buy_disabled"))
panel.add_theme_stylebox_override("panel", Skin.style("panel_purple"))
```

Default scale is 0.25. Override deliberately for another design scale. These resources are cached; duplicate a returned StyleBox before mutating it. Keep a 44–52 px button touch target regardless of texture size.

## Using artwork

Instantiate `res://assets/iap_offers/art/<sku>.tscn`. Each is an artwork-only Control with a background TextureRect and, where needed, a separate character TextureRect. Design size is 366 × 244 (3:2); resize proportionally. No scripts, save access, billing calls or labels exist in these scenes. Build title, grants, price, limit and odds links around the art.

Use resources/<id>.tres for individual textures. Every atlas region is recorded in manifest.json. Character sheets use measured unequal regions and checked alpha gutters; do not divide all sheets into equal columns. The first Hà/Lâm/Nhân generation was rejected for overlapping atlas bounds; only the repaired source is included. Semi-transparent edge shading from generation is retained. PNG pixels are copied unchanged; atlas resource regions provide the crop.

For all SKU-to-hero/foreground/panel assignments see manifest.json → recipes and coverage.csv. Gem quantities, weekly sizes and income multipliers intentionally reuse family illustration. Character bundles use their correct named driver. The XL weekly art exists but its enabled_by_default flag remains false, matching the source config. Art availability never authorizes selling an ineligible SKU.

## Reward semantics

- Linh, cars, garage buildings, calendar props and tools in illustrations are scene decoration, not additional grants. Named driver rewards come from product data only.
- Income/offline money imagery illustrates the perk; it is not a one-time cash grant. Apply the configured multiplier through UI/code.
- Characters already owned convert to 40 shards plus bundled shards: 70 total for character products, 40 for starters. Max-level character offers must be hidden by the service.
- Monthly pass and Growth Fund milestones remain dynamic UI. First-purchase gem doubling and changing quantities are never baked into art.
- Price comes from the store in the real UI. The preview embeds a packaging-time snapshot of price_fallback for review only. Coupon probability links display the current config snapshot.

## Preview and rebuild

Open preview.html locally: all 30 recipes, core purchase states, ownership conversion, the four panels, six buttons and nine character poses. No HTTP server is required. preview.template.html is the older v1 preview source; catalog.template.html is the current v2 source.

Run `python tools/package_iap_assets_v2.py` from repository root to rebuild the manifest, textures/styles/scenes, coverage CSV, preview and `Design/AssetPacks/Racing_IAP_Complete_v2.zip`. The original generated files are referenced by source path in the script and manifest. Existing PNGs remain usable if that external generation folder is unavailable; copy them with the project. Rebuilding v1 with package_iap_assets.py restores the OLD three-pack manifest; rerun the v2 packager afterwards.

The ZIP retains repository-relative paths and includes shared art dependencies, so extract into a project root preserving paths. No gameplay files are overwritten. Native Godot users can load the .tres and .tscn resources directly; iap_skin.gd is an optional rendering helper, not an autoload.

## Verification

- All 30 catalog SKUs mapped; XL disabled flag retained; all texture/scene/style dependencies present.
- Real RGBA alpha and non-overlapping character atlas boundaries checked; source PNG integrity and ZIP CRC checked.
- Godot 4.7.2 imported the package in an isolated temporary project without game autoloads/save access: 34 textures, 10 scaled StyleBox skins, 30 instantiated artwork scenes, **0 failures**.
- Browser visual preview checked at 320/390/412 px; button nine-slice bounds, ownership conversion, disabled state and XL state checked.
- Screenshots: Design/Previews/iap_assets_v2_catalog.png, iap_assets_v2_lam.png and iap_assets_v2_buttons_backgrounds.png. Godot log: Design/Previews/iap_assets_v2_godot_validation.log.

Headless import and instantiation are not native visual/device QA. Final Shop layout, gameplay state filtering, animations and store transactions are separate integration work.
