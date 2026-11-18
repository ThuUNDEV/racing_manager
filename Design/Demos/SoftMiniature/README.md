# Soft Miniature — demo

Style hiện hành của game. Demo duyệt nằm ở đây; ảnh chụp game nằm ở `Design/Previews/`.

| Thư mục | Nội dung |
|---|---|
| `approved/` | Bộ demo được duyệt: `01-race` … `06-shop`, `prototype.html` (bấm được), `index.html`, `prompts.json`. Asset pack cắt từ đây. |
| `asset_sources/` | Sheet nguồn ImageGen: `clay_icons`, `drivers`, `cars`, `concept-reference`, `Roboto-Bold.ttf`. `prototype.html` nạp trực tiếp từ đây; `facility_garage` cắt từ `clay_icons.png`. |
| `concept_options/` | Phương án concept đã so sánh: `Pocket_Circuit_Options_v1` (3 style; `02-soft-miniature` là bản được chọn). |
| `layout-review.html` | Bố cục chuẩn khi triển khai. |

Nguồn khác: `Design/AssetPacks/Soft_Miniature_UI_v1/` (pack cắt), `assets/soft_miniature_ui_v1/` (runtime).
So sánh demo và game: `python tools/compare_soft_miniature.py` → `Design/Previews/Soft_Miniature_Integrated/compare/`.

Chuyển từ `Design/Mockups/Layout_v1/` ngày 2026-11-18: `Soft_Miniature_Review_v2` → `approved/`, assets của `Soft_Miniature_Review_v1` → `asset_sources/`. Đã bỏ `index.html` của v1 (prototype cũ, thay bằng `approved/prototype.html`). File `.import` do Godot tạo lại.
