# Permanent perk heroes

`heroes.png`: 1254×1254 RGBA, transparent, 2×2 atlas (each627×627). Top-left income_x2; top-right income_x3; bottom-left income_x3_up; bottom-right offline_plus. `ui/shop_perk_card.gd` selects an AtlasTexture region without resampling the source. All lettering, multipliers, Permanent labels and prices are runtime UI, not baked in.

Created with built-in image_gen from approved `Design/Demos/PerkCards/perk_cards_section.png`. Original output and exact prompt: `output/imagegen/perk_cards_runtime/`. The image model returned1254square instead of requested2048; the original RGBA is retained, enough for the ~90–128logical hero at2.272× output scale. No new API credentials used. Light contact shadows stay in alpha. This pack is separate from existing UI art.
