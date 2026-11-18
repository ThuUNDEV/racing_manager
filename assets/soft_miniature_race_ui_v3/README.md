# Race HUD runtime art

Copied from `Design/AssetPacks/Soft_Miniature_Race_UI_v3/sprites`.
Ten independent icons (7 copied from the pack, plus `pack_starter`, `pack_offer`, `pack_weekly`: 256x256 RGBA, generated with `tools/gen_image.py` at quality low from `icons/gift.png`; raw images and prompts in `output/imagegen/pack_promo_icons_v1/`) and nine empty skins. Live text, income, rank, laps and reward states are rendered by the game.

`ui/race_hud_art.gd` loads the textures and skins; `ui/main.gd` assembles the fixed cluster; `ui/ads_race_controls.gd` owns the rewarded-ad action and its live states; `ui/race_view.gd` draws the leaderboard and player marker over the transparent 3D scene.

Validation: `godot --path . -s res://tests/race_hud_v3_ui_test.gd -- --capture` (set `RM_LANG=vi` or `RM_LANG=en`). Test saves are isolated. Screenshots are written to `output/race_hud_v3/`.
