# Popup pack — quyền lợi chính + quà kèm

Ảnh chụp runtime ngày 26/11/2026 bằng Godot 4.7.2, OpenGL compatibility, màn hình phụ và audio Dummy; save trong XDG_DATA_HOME tạm. Không dùng ảnh concept thay UI.

Mỗi SKU có ảnh tại 320×694, 390×778, 412×915 và JSON tọa độ lấy từ cây node thật. Trạng thái nút phản ánh điều kiện mua của fixture, nên một số gói đang khóa có nút xám.

Concept nguồn: `Design/Demos/SoftMiniature/approved/pack_popup_benefit_gifts_v1/01_benefit_gifts.png`.

Kiểm tra: cú pháp qua Godot MCP; đủ thưởng ở toàn bộ catalog, cả trường hợp đã có tay đua; 6 pack tại 3 độ rộng; text trong 8 ngôn ngữ; chạm X; liên kết tỉ lệ; giá, trạng thái busy/locked và phát đúng một tín hiệu mua. IAP và popup close regression cũng chạy riêng.

Các test UI vẫn có cảnh báo resource/ObjectDB khi Godot thoát (cũng xuất hiện trong popup_close_ui_test không mở popup pack).

Tái tạo ảnh: `XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy --rendering-method gl_compatibility -s res://tests/pack_promo_popup_test.gd -- --economy-test --capture`
