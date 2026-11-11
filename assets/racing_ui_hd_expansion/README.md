# Racing UI HD Expansion — 11/11/2026

Bộ art raster được gen trực tiếp theo ảnh tham chiếu của Racing UI HD hiện có. Bổ sung vật thể và nhân vật cho layout; giữ nguyên panel, button, HUD và nav trong `assets/racing_ui_hd/`.

## Nội dung

| PNG sheet | Nội dung | Số ô |
|---|---|---:|
| `sheets/layout_icons.png` | 4 phụ tùng, 4 doanh thu, kiếm/khiên, 2 coupon, 4 phong cách | 16 |
| `sheets/gear_items_01_15.png` | 15 món đầu trong catalog gear | 15 |
| `sheets/gear_items_16_30.png` | 15 món tiếp theo trong catalog gear | 15 |
| `sheets/driver_portraits.png` | An, Bình, Chi, Dũng, Hà, Khôi, Lâm, My, Nhân, Phương, Quang, Sơn | 12 |
| `sheets/garage.png` | 5 thân xe × góc 3/4 và top-down; showroom, 3 decal, bóng xe | 15 |
| `sheets/packs_facilities.png` | 2 gói gear, 2 gói tay đua, 5 vignette cơ sở | 9 |

Tổng: **6 PNG RGBA, 82 ô art**, ánh xạ đủ 77 mục A01–A77 của backlog; năm thân xe có thêm góc nhìn thứ hai. 30 món gear giữ đúng thứ tự ID của `data/gear.json`; tên sheet không chỉ rarity hay loại gói nhận.

## Sử dụng

- `sprites/*.tres` là 82 AtlasTexture riêng, trỏ vào ô tương ứng trên sheet; không cần cắt PNG để xem từng món trong Godot. `manifest.json` ghi ID, tên, backlog, tọa độ và resource.
- Atlas region đã bỏ khoảng trống thừa bằng metadata (PNG gốc không đổi); UI giữ tỷ lệ khi thu nhỏ. Đã kiểm trong Godot 4.7.2 bằng renderer native và headless.
- Nền ảnh là alpha; không có tên, giá, level hay rarity bake vào art (biển P tại bãi đỗ là ký hiệu của vật thể). Các lớp chữ/trạng thái đặt bằng UI hiện có.
- Xe top-down hướng mũi lên. Garage chọn thân theo hạng; shader đổi vùng thân bạc theo màu sơn lưu, giữ kính xanh và chi tiết cam. Khi chỉnh hoặc có decal đã lưu, preview chuyển sang góc top-down và dùng lớp decal hiện hành. Chưa có source nhiều layer hoặc mask sơn vẽ tay theo từng thân.
- Công trình là vignette cho card UI; không phải map/scene chạy gameplay.

## Kiểm tra và giới hạn

Đã xem cả sáu sheet; sửa sheet xe để loại nền mờ và thống nhất hướng top-down. Đã kiểm PNG có alpha, các region không rỗng/nằm trong ảnh, ID không trùng và đủ A01–A77. Ảnh raster do AI tạo có thể cần chỉnh mép/padding ở kích thước hiển thị cuối; chưa coi là bộ source nhiều layer hoàn thiện.

Đã tích hợp vào kho và kết quả mở gear, roster/hồ sơ/kết quả rút tay đua, Garage/bộ sưu tập/phụ tùng/ngoại hình, hàng nâng nhanh, gói Shop và card mở cơ sở. Gói tay đua Pro/All-Star dùng lần lượt art Standard/Elite; tên, giá và bảo đảm vẫn từ dữ liệu hiện hành. Panel/button tiếp tục dùng skin Racing UI HD gốc.

Save, giá, chỉ số, xác suất và gameplay không đổi. Xe trong mô phỏng đua vẫn dùng ký hiệu/chấm màu hiện hành; top-down mới dùng cho preview ngoại hình. Không tạo cơ sở bậc thứ sáu khi catalog chỉ có năm vignette: các tier cao dùng lại vignette cao nhất.

Kiểm thử: `tests/asset_integration_test.gd`, `gear_ui_test`, `shop_ui_test`, `gear_test`, `garage_test`, `driver_gacha_test` đều qua; smoke kiểm đủ 82 resource, mapping 15 xe, 12 portrait, pack đúng loại, màu/decal và chiều rộng 320/360/390/412. Có cảnh báo resource/RID khi đóng test runner (cũng có ở test UI cũ); không gặp lỗi parse/shader hoặc assertion. Ảnh native: `Design/Previews/asset_*.png`.

Nguồn ảnh gốc: `C:/Users/thupv/.codex/generated_images/01a1c996-97d3-7031-a4bd-496e496e6bb3/`. SHA-256 và tên từng ảnh gen ghi trong manifest.
