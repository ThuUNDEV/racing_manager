# Soft Miniature UI · Asset Kit v1

52 asset được tách/phục hồi từ 6 demo trong `Soft_Miniature_Review_v2`.

- 19 icon tài nguyên, điều hướng, trạng thái và thông số.
- 6 phụ tùng: engine, tyre, spoiler, gearbox, brake, chassis.
- 6 chân dung: An, Bình, Chi, Lâm, Mỹ và Lâm bản Shop.
- 1 xe showroom nền trong suốt.
- 4 minh họa gói Shop.
- 3 cảnh: Garage có xe, Garage trống và Harbor đã bỏ HUD/xe chạy.
- 1 khung avatar HUD.
- 12 nền UI trống: nút, panel, thẻ, thanh mục, thanh tài nguyên, badge.

44 asset có alpha trong suốt, 8 asset là ảnh nguyên nền. Chưa tích hợp vào game.

## Dùng file nào

- `native/`: bản cắt đã tách nền ở độ phân giải nguồn, giữ RGB từ demo.
- `png_2x/`: PNG RGBA gấp đôi kích thước native, Lanczos trong premultiplied alpha và UnsharpMask nhẹ; alpha không bị sharpen.
- `catalog.html`: xem/lọc từng nhóm, kiểm tra alpha trên nền sáng/tối, mở hoặc tải từng PNG.
- `preview_*.png`: contact sheet các nhóm, xem nhanh khi không mở HTML.
- `crops_original/`: vùng cắt nguyên bản trước khi tách nền.
- `sources/`: demo và ảnh phục hồi gốc, không chỉnh sửa.
- `manifest.json`: ID, kích thước, nguồn, tọa độ cắt, cách xử lý, SHA-256 và thông số 9-slice.
- `restoration_prompts.json`: prompt dùng với built-in ImageGen để phục hồi nền UI/cảnh.

## Pixel nguồn và phần phục hồi

Icon, phụ tùng, chân dung, xe và các minh họa được cắt trực tiếp. Mask foreground dùng GrabCut hoặc U2Net, chỉnh các vùng kính/tóc và chống viền. Ảnh cắt gốc được giữ lại để đối chiếu.

12 nền UI che chữ được phục hồi bằng ImageGen, sau đó cắt và tạo alpha sạch; mọi nền đều trống để đặt chữ/số động. Harbor và Garage trống được phục hồi ở độ phân giải cao. Các mục này có `method: imagegen_restored_from_demo...` trong manifest, chi tiết có thể khác nhẹ so với pixel demo.

Các cảnh là tranh nền 2D. Xe showroom là một góc nhìn cố định; chân dung được giữ theo phần thân hiển thị trong demo.

## Tài nguyên Godot chuẩn bị sẵn

`godot_textures/skins/` gồm 12 PNG theo kích thước UI mobile, đi kèm `godot_styles/*.tres`. Bản này dùng cap 9-slice theo đơn vị logic để tránh nút 2× làm control bị cao quá mức.

Khi bạn quyết định tích hợp, chép bộ này vào `res://assets/soft_miniature_ui_v1/` để các đường dẫn `.tres` khớp. Mỗi style có texture cùng ID. Dùng `png_2x` cho TextureRect có EXPAND_IGNORE_SIZE và giữ tỉ lệ. Chữ, giá, trạng thái và progress nên dựng động bằng UI.

## Chạy lại

Cài các gói trong `requirements.txt` vào môi trường riêng, rồi chạy `python tools/extract_soft_miniature_assets.py` từ bộ asset. Model `u2netp` được tải/cache ở lần chạy đầu. Script dùng các ảnh nguồn đóng kèm, không gọi API tạo ảnh. Các nguồn phục hồi đã được lưu sẵn.

Bộ kiểm tra đã xác minh: PNG đọc được, kích thước 2×, alpha/gutter sạch, SHA-256 khớp nguồn. 12 StyleBoxTexture được nạp và render trong dự án Godot tách biệt; xem `preview_nine_slice.png`.
