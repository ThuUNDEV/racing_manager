# pack_promo_v1

Text-free art for the pack promo popup and perk cards (concepts: `Design/Demos/SoftMiniature/approved/pack_promo_*.png`, `perk_cards_section.png`).
All text, numbers, prices and badge values are live Labels/Buttons; see `manifest.json` for file sizes, modes and provenance.

The promo reward panel (`ui/pack_promo_ui.gd`) is one translucent cream frame with an icon-over-value grid, like the Shop offer card; it uses `ticket_*.png` for Pro / All-Star / Standard / Elite tickets. The header ribbon overhangs the card top and is centered; the close button overlaps its right flag.

Income ×N identity: the Shop perk card and the promo popup share one hero (`perk_income.png`), one rosette (`PromoUi.badge`), and the reward-catalog icons `income_online` (`icon_income.png`) and `race_reward` (`icon_race.png`) from `data/reward_items/`.
