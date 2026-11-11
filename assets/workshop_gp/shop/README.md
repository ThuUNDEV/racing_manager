# Workshop GP — Shop asset v1.0

Bộ hình 2D cho concept Shop kem–cam, gồm 16 icon, 2 banner và 8 bộ khung/nút SVG + StyleBoxTexture. Đây là asset, chưa nối vào màn Shop hoặc hệ thống mua hàng.

## Dùng trong Godot

Giữ đường dẫn `res://assets/workshop_gp/shop/`. Gán `icons/*.tres` cho TextureRect/Texture2D; mỗi resource trỏ một ô của atlas PNG có alpha. Bật Linear filter, dùng KEEP_ASPECT_CENTERED. Atlas giữ nguyên ảnh nguồn; không cần cắt PNG bằng tay.

Banner `textures/offer_combo.png` và `textures/offer_starter.png` là ảnh nền đầy khung. Dùng TextureRect giữ tỉ lệ, bọc trong Panel/Control có clipping nếu cần bo góc. Chừa vùng trái để đặt chữ trắng; tránh crop vùng nhân vật và phần thưởng bên phải.

Gán `styles/card.tres`, `pass.tres`, `reward.tres`, `currency.tres` vào Panel. Button dùng `button_normal`, `button_hover`, `button_pressed`, `button_disabled` cho các trạng thái tương ứng. Các khung có 9-slice 24 px; không dùng nhỏ hơn 48 px mỗi chiều.

Chữ, giá, số lượng, x2/x3, thời gian, tiến độ, thông báo đỏ và trạng thái sở hữu phải do UI vẽ. Icon income_boost_small/large dùng cùng với nhãn x2/x3 trong engine. Gem grid dùng lại icon gem cho mọi mệnh giá. Cash dùng cash_small/medium/large. Banner không chứa giá, tên gói hoặc bộ đếm.

## Nguồn và kiểm tra

Art PNG được tạo bằng ImageGen từ concept Shop trong chat ngày 2026-11-10, giữ bản gốc trong thư mục generated_images của Codex. SVG được viết riêng cho bộ này. Không đóng gói font hoặc ảnh chụp tham chiếu của game khác.

`manifest.json` ghi vùng atlas, kích thước và SHA-256. `tools/package_assets.py` sao chép nguyên byte PNG, đọc kích thước/alpha bằng Pillow rồi tạo resource và manifest. Không xử lý/chỉnh sửa pixel nguồn.

`preview/gallery.gd` nạp tất cả texture/style trong project Godot độc lập, vẽ contact sheet và thoát với mã lỗi nếu resource không nạp được. Đặt `SHOP_PREVIEW_OUTPUT` để lưu ảnh khi chạy bằng renderer có cửa sổ. Không kiểm tra gameplay, giao dịch, SDK hay thiết bị di động.
