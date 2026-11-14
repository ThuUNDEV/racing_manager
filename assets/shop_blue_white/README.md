# Shop xanh–trắng

Tích hợp theo demo đã duyệt trong chat ngày 13/11/2026. Dùng cho Shop, không đổi skin toàn game.

- `items.png`: sheet RGBA 1536×1024, 12 hình mới; giữ nguyên byte ảnh sinh gốc.
- `sprites/*.tres`: 12 AtlasTexture với vùng cắt theo alpha thật, không chia/cắt PNG thành file mới.
- `banner.svg`, `tile.svg`, `free.svg`: nền thẻ xanh–trắng, dùng 9-slice để co giãn.
- `section.svg`: thanh tiêu đề nhóm xanh dương.
- `buy.svg`, `action.svg`, `tab.svg`, `disabled.svg`: nền nút không chữ và trạng thái.
- `flags.svg`: họa tiết cờ đua cho tiêu đề Shop.
- `manifest.json`: nguồn, SHA-256 và tọa độ 12 sprite.

Runtime: `ui/shop_demo_skin.gd` và `ui/shop_page.gd`. `demo_reference.png` là ảnh mẫu người dùng gửi ngày 14/11/2026, giữ nguyên file gốc. `ShopSkin.demo_picture()` dùng AtlasTexture cho chân dung Tân binh, My, Lâm và các icon vé/mảnh để khớp mẫu. Các chân dung còn lại dùng manifest IAP. Giá và số thưởng bên cạnh icon lấy từ dữ liệu game; hình minh họa gói ngày trong mẫu có sẵn dấu ×2 (đúng cấu hình hiện tại).

Banner chứa tranh bên trái, nội dung thưởng động và giá bên phải; nút ⓘ 44 px mở popup có giá thật và tỉ lệ. Gói ngày dùng hai cột, gem/đổi tiền ba cột ở 320/390/412 px. Chỉ hiện một gói khởi đầu hợp lệ và tự chuyển gói tiếp theo khi đã mua, không có hàng tab phụ. My/Lâm đứng trước Quà hôm nay; các tay đua khác nằm ở nhóm sau. Tiêu đề và bộ lọc nằm trong `Main.ShopChrome`, cố định bên trên vùng cuộn. Mọi SKU vẫn qua điều kiện hiển thị và luồng IAP cũ.

Giữ nguyên dữ liệu IAP, phần thưởng, giá store, giới hạn mua, cờ XL, quảng cáo và save. Đổi tiền vẫn “Sắp có”. Header và nút thiết lập khác của game vẫn dùng chung; ảnh sân đua sau ví được ẩn riêng khi vào Shop để đúng nền xanh–trắng trong demo.

Tạo lại asset bằng `python tools/build_shop_blue_assets.py`. Script dùng file sinh gốc khi còn trên máy, hoặc sheet `items.png` đã đóng gói nếu file nguồn không còn.

Kiểm tra: `tests/shop_blue_demo_test.gd`, `tests/shop_ui_test.gd`, `tests/shop_redesign_test.gd`, `tests/ads_shop_test.gd`, `tests/touch_scroll_test.gd`. Render native dùng `-- --shop-blue-shots`. Ảnh ở `Design/Previews/shop_blue_<width>_<state>.png`.


## Dựng lại theo tọa độ mẫu (14/11)

`ui/shop_reference_shell.gd` dựng HUD, tiêu đề, bộ lọc và điều hướng riêng cho Shop trên hệ tọa độ rộng 600 px của ảnh gốc. Thẻ gói dùng canvas rộng 550 px; gói ngày rộng 264 px, gem 175×148 px và đổi tiền 175×170 px. Canvas co giãn theo chiều rộng thực tế, không tăng riêng nút giá làm lệch bố cục. Nút vẫn nối các signal, dữ liệu IAP và điều kiện mua hiện có. Entry thưởng đăng nhập riêng được chuyển xuống sau catalog; Quà hôm nay giữ thẻ gọn đúng vị trí mẫu.


## Sửa icon Gem

Năm gói Gem và ô Gem miễn phí dùng các sprite RGBA đầy đủ từ `items.png` (vùng nguồn rộng 262–338 px), không cắt icon từ ảnh chụp demo. Bật mipmap cho sheet và dùng linear mipmap khi thu nhỏ. Thẻ Gem cao 180 px trong canvas thiết kế để có vùng riêng cho icon, số lượng và nút giá.
