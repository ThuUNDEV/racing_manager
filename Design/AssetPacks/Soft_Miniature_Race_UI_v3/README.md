# Soft Miniature Race UI v3

This kit replaces the composite v2 crops. All 16 sprites are separate transparent PNGs: seven icons and nine EMPTY UI skins. No text or icon is baked into a skin. Text and values must be live labels in game.

The approved demo is a flattened raster image. ImageGen reconstructed the occluded components from that reference; these are reconstructed matching assets, not recovered original layers. art-tools MCP remove_background was called per cell for alpha refinement. Where it erased an empty panel face, original transparent alpha was retained. manifest.json records the alpha method for each item.

icons/: trophy, coin, facility, gift, cash, video, notification.
skins/: rank_cream, income_green, facilities_orange, reward_cream, reward_blue, leaderboard_teal, lap_teal, position_teal, selected_row_gold.

The small star relief belongs to the coin; the play symbol belongs to the video icon. Neither is embedded into a separate UI button skin. No track, cars, scenery, text, or full screen background is included.

Original source-sheet.png, extraction manifest, and MCP response metadata are retained. Game code is unchanged.
