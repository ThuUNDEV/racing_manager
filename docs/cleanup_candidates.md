# Ứng viên dọn nguồn cũ (đợt 1)

Lập ngày 26/11/2026. Nhóm A đã xóa, nhóm B chưa. Cách kiểm: tìm đường dẫn `res://`, tên và `uid://` trong file văn bản của repo (bỏ `.godot/`, `output/`, `export/`). Đường dẫn ghép chuỗi lúc chạy có thể lọt, nên sau khi xóa phải chạy test và build web.

Dung lượng tính cả `.import`/`.uid`. Mọi mục đều đang được git theo dõi, khôi phục được.

## A. Đã xóa ngày 26/11/2026 (chưa commit)

- `ui/shop_reference_shell.gd`, `ui/shop_banner.gdshader`
- `ui/shop_horizontal/`: `shop_horizontal`, `shop_currency_pill`, `shop_section_ribbon`, `shop_recruit_card`
- `assets/upgrade_cards/`
- `assets/soft_miniature_ui_v1/`: `flare_v2`, `flare_prev_v1`, `runtime_flare_prev_v1`, `godot_styles_prev_v1`

234 file được git theo dõi, khôi phục bằng `git restore <đường dẫn>` khi chưa commit.

Kiểm sau xóa: Godot import lại không lỗi; `soft_miniature_ui`, `shop_merged_gift`, `boot` qua. `shop_ui`, `shop_packs`, `shop_redesign`, `clean_modern_ui` lỗi giống hệt trên bản HEAD `77755be` chưa xóa (`shop_ui` và `shop_redesign` treo đến hết giờ). Chưa build web.

`assets/shop_blue_white/README.md` và `Design/Previews/shop_fixed_validation.md` vẫn nhắc `shop_reference_shell`.

## B. Xóa được, nhưng phải sửa kèm

| # | Đường dẫn | MB | Việc kèm theo |
|---|---|---:|---|
| 12 | `assets/daily_rewards/` | 6,6 | Bỏ `tools/export_daily_crops.py`; ghi chú lại trong `Design/30`, `Design/34`. Logic `game/daily_rewards.gd`, dữ liệu và key `daily.*` giữ nguyên |
| 13 | `assets/tutorial/` (ảnh Linh cũ; bản đang dùng ở `soft_miniature_ui_v1/tutorial/`) | 1,0 | Xem bên dưới |

Mục 13: `assets/clean_modern/manifest.json` còn 4 dòng trỏ tới thư mục này (1 `replacements`, 3 `atlas_resources`). Xóa thì phải:
- bỏ 4 dòng đó và đổi số `467` trong `tests/clean_modern_export_test.gd` thành `463`;
- xóa luôn `assets/clean_modern/replacements/tutorial/`, `resources/tutorial/`, `sheets/tutorial_linh.png`;
- bỏ job `tutorial_linh` trong `tools/plan_clean_modern_assets.py` và cập nhật `source_inventory.json`, `generation_plan.json`, `coverage.csv`;
- `avatar_circle.gdshader` nằm trong thư mục này, không thấy nơi nào gọi.

Mục 14: thẻ hàng ngang `ui/shop_horizontal/shop_offer_card.*` chỉ được dùng bởi `_h_card` trong `ui/shop_page.gd`, mà hàm này không ai gọi. Xóa thì gỡ cả `_h_card` và các hằng đi kèm. **Giữ** `shop_horizontal_theme.tres`.

## Chưa nằm trong đợt này

- Skin shop blue-white, `clean_modern`, `workshop_gp`, `racing_ui_hd`: đang chạy.
- `Design/` (AssetPacks, Previews, tài liệu trùng số): chưa kiểm từng file.
- File lẻ không dùng bên trong các thư mục đang chạy: chưa kiểm.

## Kiểm sau khi xóa

1. Mở Godot cho import lại, grep `SCRIPT ERROR|Parse Error`.
2. Chạy `tests/clean_modern_ui_test.gd`, `tests/soft_miniature_ui_test.gd`, các `tests/shop_*_test.gd`.
3. Build web, so dung lượng `index.pck`.
