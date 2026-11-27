# Garage Car v3 — implementation review

## Phạm vi và nguồn gốc

Toàn bộ hình học xe được tự dựng bằng `tools/models/build_race_car.gd`.
Không dùng model/texture bên ngoài hoặc art trong `Design/References/RaceStar_Garage_Extract/`.
Tham chiếu phong cách: `Design/Demos/SoftMiniature/approved/04-garage.png` và
`Design/Concepts/Garage_Redesign_v2/01-car.png`. Đây là bản runtime bằng mesh/PBR,
không phải ảnh concept hoặc bản sao asset của ảnh tham chiếu.

5 thân theo `data/cars.json.class`: Pico hatch ngắn/đèn tròn, Nova coupe,
Apex GT thấp/rộng, Titan muscle GT/vent mui, Zenith mũi thuôn/intake/cánh lớn.
Mỗi hạng dùng cho 3 biến thể chỉ số hiện có. Sơn và decal vẫn lưu theo xe như cũ.
Chất đất sét/nhựa mềm thể hiện qua normals bo mượt và vật liệu PBR; không có bitmap texture.

## File sửa/tạo

- `tools/models/build_race_car.gd`: builder 5 thân, normals, vành/lốp/đèn/chi tiết,
  metadata mặt decal và vị trí bánh.
- `ui/car_preview.gd`: chọn thân theo class, giữ sơn riêng mỗi instance, decal theo
  mặt xe, camera góc cao hơn, key/fill/rim light, bóng gầm và bóng tiếp đất 4 bánh.
- `assets/models/race_car/{pico,nova,apex,titan,zenith}.tscn`: 5 thân mới.
- `assets/models/race_car/race_car.{tscn,glb}`: model mặc định mới, tương thích màn đua.
- `assets/models/race_car/README.md`: mapping, nguồn gốc và cách build.
- `tests/garage_car_preview_test.gd`: kiểm tra 15 xe, 8 sơn, 4 lựa chọn decal,
  cách ly vật liệu và capture.
- Thư mục này: 13 PNG và báo cáo.

## Ảnh

- `320_car.png`, `390_car.png`, `412_car.png`: Garage thực ở ba kích thước,
  chiều cao theo tỷ lệ 390×844, render Vulkan Forward+; save tạm.
- `390_{pico,nova,apex,titan,zenith}.png`: Garage thực từng hạng; xe chưa sở hữu
  vẫn mờ theo hành vi hiện có.
- `390_look.png`, `390_look_{double_stripe,lightning,checker}.png`: tab ngoại hình.
- `five_bodies.png`: render 5 thân cùng màu/góc nhìn, không làm mờ, để so silhouette.

## Các vòng tự đánh giá

1. Vòng đầu: cabin và đèn quá vuông, normals một số mặt sai winding.
   Sửa winding, normals và độ cong; đèn Pico thành lens tròn.
2. Vòng tiếp: nóc như tấm rời, kính gần đứng. Đổi nóc thành mặt liền của canopy,
   kính nghiêng và normals theo độ thuôn; thay scoop Titan bằng hai vent.
3. Chỉnh khung camera ngoại hình tránh cắt mũi, đổi chiều dài decal theo mặt phẳng
   thật, thêm bóng bánh, tăng khác biệt mũi xe theo hạng.
4. Kiểm tra ảnh cuối ở 320/390/412 và decal: không cắt xe; màu/đèn/kính/vành rõ.
   Vật liệu sạch theo kiểu đồ chơi, chưa có sơn mòn/bẩn hoặc texture bitmap.
   Ở 320 phần nâng cấp phải cuộn theo layout hiện có; không đổi bố cục ngoài phạm vi.

## Kiểm tra

Đã chạy với `XDG_DATA_HOME` tạm, `RM_LANG=vi`, `--economy-test`:

- `tests/garage_test.gd`: 0 lỗi.
- `tests/garage_car_preview_test.gd`: 0 lỗi; headless và cửa sổ Vulkan.
- `tests/race_world_3d_test.gd`: failures=0.
- `tests/race_diorama_test.gd`: failures=0.
- `git diff --check` các file sửa: đạt.

Chạy cửa sổ luôn có `--screen 1 --audio-driver Dummy`.
Các test UI/3D báo resource/RID còn tồn tại khi thoát. Log verbose xác định orphan
`Art_driver_ha`, `Art_driver_my` và texture portrait tương ứng; cả hai test race
cũng có cảnh báo tương tự. Không sửa luồng portrait ngoài phạm vi.
Godot MCP `script_check` không khả dụng trong phiên; CLI thực thi builder/test để
kiểm tra biên dịch thay thế.

## Phần cần quyết định / tích hợp sau

Garage đã chọn đủ 5 thân. Màn đua hiện vẫn tải `race_car.tscn` mặc định (Pico mới).
Muốn xe trong đua chọn đúng thân theo class cần tích hợp trong `ui/race_world_3d.gd`
và có thể phần truyền car_id của `ui/race_view.gd`; hai file được yêu cầu giữ nguyên.
Chưa đo FPS trên thiết bị mobile/web thật. Không đổi balance/giá/save, không commit,
không tạo branch và không sửa các thay đổi khác của người dùng.
