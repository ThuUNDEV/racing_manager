# Flare assets

Sinh bằng gpt-image-2.5-flare (qua Figma generate_image), tách nền bằng chroma-key (nền xanh #00FF00, riêng currency_cash nền magenta) + despill. race_car_purple/yellow/green là đổi hue từ race_car_red; star_locked là bản xám của star_gold. Banner shop_* và harbor_background không tách nền. Nguồn thô: Design/AssetPacks/Soft_Miniature_UI_v1/flare_candidates/raw/.

| file | size | mode |
|---|---|---|
| brake.png | 1024x1024 | RGBA |
| car_showroom.png | 1024x1024 | RGBA |
| chassis.png | 1024x1024 | RGBA |
| currency_cash.png | 1024x1024 | RGBA |
| currency_coins.png | 1024x1024 | RGBA |
| engine.png | 1024x1024 | RGBA |
| gearbox.png | 1024x1024 | RGBA |
| gift_red.png | 1024x1024 | RGBA |
| harbor_background.png | 1536x864 | RGB |
| helmet_pit.png | 1024x1024 | RGBA |
| inventory_crate.png | 1024x1024 | RGBA |
| nav_bag.png | 1024x1024 | RGBA |
| nav_league.png | 1024x1024 | RGBA |
| nav_race.png | 1024x1024 | RGBA |
| nav_shop.png | 1024x1024 | RGBA |
| nav_team.png | 1024x1024 | RGBA |
| race_car_blue.png | 1024x1024 | RGBA |
| race_car_green.png | 1024x1024 | RGBA |
| race_car_purple.png | 1024x1024 | RGBA |
| race_car_red.png | 1024x1024 | RGBA |
| race_car_yellow.png | 1024x1024 | RGBA |
| rocket_acceleration.png | 1024x1024 | RGBA |
| settings.png | 1024x1024 | RGBA |
| shop_combo.png | 1536x1024 | RGB |
| shop_income_x2.png | 1536x1024 | RGB |
| shop_no_ads.png | 1536x1024 | RGB |
| shop_starter.png | 1536x1024 | RGB |
| speedometer.png | 1024x1024 | RGBA |
| spoiler.png | 1024x1024 | RGBA |
| stability_scales.png | 1024x1024 | RGBA |
| star_gold.png | 1024x1024 | RGBA |
| star_locked.png | 1024x1024 | RGBA |
| ticket.png | 1024x1024 | RGBA |
| trophy_large.png | 1024x1024 | RGBA |
| button_orange.png | 1092x353 | RGBA |
| button_blue.png | 1116x366 | RGBA |
| button_disabled.png | 1108x381 | RGBA |
| panel_inventory.png | 965x637 | RGBA |
| panel_inventory_selected.png | 1032x628 | RGBA |
| panel_upgrade.png | 1728x350 | RGBA |
| section_blue.png | 1851x244 | RGBA |
| segmented_tray.png | 1417x336 | RGBA |
| navigation_tray.png | 1822x291 | RGBA |
| hud_resource.png | 1742x232 | RGBA |
| avatar_frame.png | 636x659 | RGBA |

UI (nút, panel, khay, HUD, khung avatar): sinh nền magenta #FF00FF rồi chroma-key, cắt sát viền; dùng làm tham chiếu/nine-slice, phần giữa phẳng. Nguồn thô: flare/raw/.
| tyre.png | 1024x1024 | RGBA |
| currency_gem.png | 1024x1024 | RGBA |
| facility_garage.png | 1024x1024 | RGBA |
| badge_blue.png | 1536x768 | RGBA |
| badge_mint.png | 1536x768 | RGBA |
| driver_an.png | 1024x1024 | RGBA |
| driver_binh.png | 1024x1024 | RGBA |
| driver_chi.png | 1024x1024 | RGBA |
| driver_lam.png | 1024x1024 | RGBA |
| driver_my.png | 1024x1024 | RGBA |
| garage_background_empty.png | 1536x1024 | RGB |
| garage_with_car.png | 1536x1024 | RGB |

Đợt 2: sinh trực tiếp bằng OpenAI Images API gpt-image-2.5-flare qua tools/gen_image.py (nền trong suốt native, không chroma-key). driver_* dùng edits với ảnh gốc Design/AssetPacks/Soft_Miniature_UI_v1/crops_original/driver_*.png làm tham chiếu; garage_with_car dùng edits từ garage_background_empty + car_showroom (cùng cảnh, có xe). driver_lam_shop chưa sinh: dùng driver_lam.
