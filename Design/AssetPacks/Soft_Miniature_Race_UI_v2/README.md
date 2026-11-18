> Superseded: these are composite reference crops, not a reusable layered asset kit. Do not use the complete controls as production UI sprites. See Soft_Miniature_Race_UI_v3 for separate icons and empty skins.

# Soft Miniature Race UI v2 sprites

Source: `Design/Demos/SoftMiniature/race_rewards_v1/race-daily-gift-x2-v2.png`.
Extracted using art-tools MCP `remove_background` at the user-provided endpoint, with local crop and alpha cleanup. The source image is preserved.

15 transparent PNGs: 8 complete UI controls and 7 separate icons. `manifest.json` records source rectangles, output dimensions and trim offsets. `crops/` retains the input crops and service metadata.

Complete controls: rank_badge, income_chip, facilities_button, daily_gift_button, ads_x2_button, leaderboard, lap_badge, player_position.
Icons: trophy_icon, coin_icon, facility_icon, gift_icon, cash_icon, video_icon, notification_dot.

Complete controls retain the text and numbers baked into the generated demo. They are reference/composite sprites; dynamic income, rank, laps and leaderboard should be drawn as live labels when integrated, with separate background skins. The extracted source has no layers to recover text-free backgrounds directly.

Track, cars and 3D scenery are excluded. No game code has been changed by this extraction. Background and outer frame are not included in this pack.
