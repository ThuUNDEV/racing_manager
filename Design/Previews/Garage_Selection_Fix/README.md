# Garage selection preview fix — 27 November 2026

Reported: selecting Pico Bám đường changes its title and number but leaves an orange, heavily faded car in the showroom, while the collection card is blue.

Cause: Garage collection cards assigned catalogue preview colours, while the showroom explicitly assigned the global default paint to every unowned car. Cars within one family intentionally share a body mesh; their catalogue colour and race number distinguish the variants.

Fix: `GaragePage._preview_cosmetics()` supplies the same appearance to the collection and showroom. Unowned cars use the existing catalogue palette; owned cars use their actual saved/default cosmetics. Removed the showroom fade for unowned cars. Browsing does not buy/equip a car or write cosmetics. No model, game data, pricing or save implementation changes.

Evidence: `320_car_pico_bam_duong.png`, `390_car_pico_bam_duong.png`, `390_car_pico_ben_bi.png`, `390_car_nova_tia_chop.png`, `412_car_pico_bam_duong.png`. These are Vulkan runtime captures with isolated saves and muted audio on screen 1.

Validation: `tests/garage_selection_ui_test.gd` clicks all 15 catalogue entries at 320/390/412, checks selected ID, body class, race number, matching thumbnail paint/decal, actual paint material and full opacity. It also verifies browsing leaves owned/active cars and saved cosmetics unchanged, then tests real purchase/default appearance and selection of a saved white/checker car. `garage_redesign_ui_test.gd` covers the existing layout, eight languages, preview/draft/save and upgrade flows. Godot reports resource/RID cleanup warnings at shutdown.
