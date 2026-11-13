# Tutorial — Linh

Ngày 12/11/2026. Art mới theo `Design/23_Tutorial_Script.md` §2 và style portrait tay đua hiện hành.

- `linh_expressions.png`: sheet RGBA 1536 × 1024, 3 biểu cảm của cùng nhân vật; không bake chữ hay khung avatar.
- `portraits/linh_smile.tres`: cười chào mừng; `linh_point.tres`: chỉ tay hướng dẫn; `linh_excited.tres`: hào hứng sau thao tác/kết thúc.
- AtlasTexture giữ ảnh gốc, lấy mỗi vùng 512 × 560; dùng trực tiếp trong Godot. `manifest.json` ghi nguồn, SHA-256 và tọa độ.
- `avatar_circle.gdshader`: mask tròn cho avatar 56 × 56 của callout. Nền xanh, tên và lời thoại là UI thật; không nằm trong ảnh.

Đã tích hợp trong `ui/tutorial_overlay.gd`, thay icon staff dự phòng. Khi hỏi bỏ qua dùng biểu cảm cười. Bàn tay tiếp tục dùng `assets/workshop_gp/ui/tutorial_hand.svg`; spotlight vẫn vẽ động theo mục tiêu.

Kiểm tra: Godot 4.7.2 import thành công; `tests/tutorial_test.gd`: 0 failures. Native OpenGL render 9 ảnh ở 320/390/412 px × 3 biểu cảm bằng `tools/preview_tutorial_art.gd`, lưu `Design/Previews/tutorial_linh_*.png`. Đã xem ảnh 320 px chỉ tay và 390 px hào hứng. Có cảnh báo resource/RID leak khi đóng runner; chưa kiểm trên điện thoại thật.

Phạm vi là art nhân vật và gắn avatar. Hiệu ứng số thu nhập A3, khóa tính năng Phần B và mẹo Phần C vẫn theo trạng thái riêng trong tài liệu tutorial.

## UI callout mới — 12/11/2026

Khung trắng xanh nhạt, viền xanh 2 px, góc bo 20 px và bóng nhẹ. Header riêng gồm avatar tròn 56 px, tên Linh, vai trò Trưởng kỹ thuật; bên phải là bước `1 / 7`, nhãn MỞ KHÓA hoặc MẸO theo nội dung. Lời thoại dùng toàn chiều ngang dưới header, cỡ 15 px, cách dòng 3 px. Footer đặt Bỏ qua bên trái và CTA cam bên phải; xác nhận bỏ qua dùng nhãn Tiếp tục để vừa màn hẹp. Vùng chạm nút tối thiểu 44 px.

Giữ cách neo callout cạnh mục tiêu và hoạt động của spotlight/bàn tay. Bộ preview hiện xuất thêm trạng thái xác nhận, tổng 12 ảnh ở 320/390/412 px. Đã xem native A1 ở 320/390, A4 ở 390 và xác nhận bỏ qua ở 320. Ba test `tutorial_test`, `tutorial_unlock_test`, `tutorial_tips_test` đều 0 failures; vẫn có cảnh báo resource/RID khi đóng runner. Chưa kiểm trên điện thoại thật.

### Bản hộp thoại nhân vật — thay giao diện trắng phía trên

Theo yêu cầu thiết kế lại, callout hiện dùng nền navy `#122B4B`, viền xanh, tên Linh và nhãn trạng thái màu vàng, lời thoại trắng. Chân dung 84 × 92 px không còn mask tròn, nhô lên 26 px khỏi mép khung; header chừa chỗ cho nhân vật. Đường phân cách ngăn header với nội dung. Giữ CTA cam và nền đen mờ 60%, chừa sáng mục tiêu cần thao tác. Vị trí callout có thêm khoảng trống phía trên cho chân dung.

Preview thêm thông báo U2 giống trường hợp người dùng gửi: `tutorial_linh_<width>_unlock.png`; tổng 15 ảnh ở 320/390/412 px. Đã xem thông báo mở khóa ở 390 và chào mừng ở 320. Cả ba test tutorial tiếp tục đạt 0 failures sau cập nhật.
