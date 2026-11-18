# Daily Gift — bộ sprite để setup Godot

- `skins/`: 16 PNG RGBA rời; khung/card/button/badge đã bỏ chữ và icon thưởng. Nút đóng có X và mốc đã nhận có tick.
- `icons/`: 18 PNG icon thưởng và dấu tick đã tách nền từ concept gốc.
- `godot/`: 13 StyleBoxTexture `.tres` có sẵn lề 9-slice ban đầu. Các nút mốc tròn và nút đóng dùng TextureRect/TextureButton.
- `manifest.json`: kích thước và lề 9-slice theo thứ tự trái, trên, phải, dưới.

## Cách ráp

1. Dùng `panel_cream.tres` cho PanelContainer ngoài; header dùng `header_cyan.tres`.
2. GridContainer 3 cột, 2 hàng: mỗi PanelContainer dùng `card_normal`, `card_today` hoặc `card_claimed`.
3. Đặt icon thưởng trong TextureRect với STRETCH_KEEP_ASPECT_CENTERED, chữ ngày/số lượng dùng Label riêng.
4. `badge_today_gold` / `badge_claimed_green` là nền trống cho Label HÔM NAY / ĐÃ NHẬN.
5. `panel_grand` là nền quà ngày 7; gắn gift_grand, gem và driver bên trên bằng các TextureRect riêng.
6. Thanh tích lũy dùng progress_track/progress_fill và các milestone; số ngày dùng Label động.
7. Nút nhận dùng button_claim_orange.tres cho theme normal; gift_claim là icon riêng; NHẬN QUÀ là Label.
8. `button_close.png` làm texture_normal của TextureButton. Tạo vùng bấm tối thiểu 48px.

Các `.tres` tham chiếu vị trí hiện tại trong dự án. Nếu chuyển bộ sprite sang `assets/`, hãy cập nhật texture path. Lề 9-slice là gợi ý ban đầu, điều chỉnh theo kích thước hiển thị. Đây là bộ art setup, chưa thay UI runtime.

Khung trống được tái tạo bằng ImageGen từ ảnh concept phẳng, rồi cắt/tách nền bằng MCP art-tools và làm sạch alpha; không phải khôi phục layer gốc 1:1. Icon thưởng giữ art concept ban đầu.
