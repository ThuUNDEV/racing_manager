# Garage Car v4

Ba vòng dựng → chụp Vulkan Forward+ → đối chiếu `Design/Concepts/Garage_Redesign_v2/01-car.png`, `03-look.png` và lưới xe trong `01-car.png`. Không dùng art từ RaceStar_Garage_Extract; toàn bộ mesh, vật liệu, decal và số xe được dựng bằng code. Không đổi dữ liệu, giá, save, race_view/race_world_3d; không tạo branch/commit.

## Thay đổi

- Sơn giữ nguyên màu từ GameData. Hai sọc dọc và caro dùng bản sao chính mesh Body/Roof với shader mask, bám độ vồng và góc bo. Tia chớp có sọc trắng trên mui và biểu tượng hai cạnh cửa. Sơn trắng dùng sọc đỏ cam, các màu còn lại dùng tương phản theo độ sáng.
- Huy hiệu tròn kem và Label3D hai cửa; số ổn định theo thứ tự danh mục xe + 3 (03–17), không thêm trường save. Huy hiệu vẫn hiện khi chọn Không họa tiết.
- Thân rộng/thấp, capo và cabin vồng, đèn tròn lớn, lốp torus bo tròn, vành/lỗ vành, cản/skirt/gương/cánh gió tương phản. Pico có cánh gió nhỏ; Nova coupe dài; Apex thấp/rộng; Titan vai cao/cabin ngắn/hai vent; Zenith dài nhất/thấp nhất/intake và cánh cao.
- Clearcoat nhẹ, sky reflection, vệt phản chiếu kính bám mesh, ánh sáng key/fill/rim và bóng tiếp đất. Không dùng texture ảnh cho livery/số.

## Ảnh và các vòng

- `round1/`: tỷ lệ thân mới, đèn tròn, huy hiệu và livery trên mesh; nhận thấy capo/cabin còn phẳng, xanh ngọc dùng mực tối.
- `round2/`: vồng thân/nóc và cập nhật normals, kính phản chiếu môi trường, dùng sọc sáng trên xanh ngọc, tia chớp đưa lên cạnh cửa.
- `round3/`: lốp bo bằng torus, vành lớn hơn, sọc đỏ cam/viền cam trên sơn trắng, vệt phản chiếu kính, giảm key/ambient để bớt cháy sáng. Đây là bản cuối.

Mỗi vòng có `five_bodies.png`: 5 hàng thân × 3 cột **trắng/sọc đôi – xanh ngọc/tia chớp – tím/caro**, tổng 15 phối. `390_tab0.png`, `390_tab1.png`, `390_tab2.png` là 3 tab Garage. Ngoài ra có framing 320/390/412 và ảnh từng thân/từng decal. Save hoàn toàn tạm; dữ liệu ví/sở hữu/chỉ số của harness không phải dữ liệu trong concept.

`comparison_car.png`, `comparison_look.png`: ảnh chuẩn đầy đủ cạnh runtime cuối, scale đồng nhất, không kéo méo/crop che khác biệt. Hai ảnh chuẩn có tỷ lệ màn hình khác runtime nên chừa nền bên dưới. Mỗi ảnh nguồn vẫn truy được từ đường dẫn ở đầu README.

## Kiểm tra

Chạy bằng Godot 4.7.2, `RM_LANG=vi`, XDG_DATA_HOME tạm và `--economy-test`. Capture cửa sổ luôn có `--screen 1 --audio-driver Dummy`.

- `garage_test.gd`: 0 lỗi.
- `garage_car_preview_test.gd`: 0 lỗi; kiểm 15 xe, đủ 8 sơn và 4 họa tiết, cách ly vật liệu, huy hiệu/số đúng danh mục và livery dùng đúng mesh cong.
- `garage_car_v4_capture.gd`: 0 lỗi trên renderer thật, đủ các phối và ảnh UI.
- `garage_redesign_ui_test.gd`: 0 lỗi, 320/390/412 và 8 ngôn ngữ.
- `race_world_3d_test.gd`, `race_diorama_test.gd`, `race_hud_v3_ui_test.gd`: failures=0.
- GLTFDocument nạp trực tiếp race_car.glb thành công, 70 mesh; race_car.tscn nạp được, class=1 và Body hợp lệ.
- `git diff --check` các file code/tài liệu sửa: đạt. CLI biên dịch/thực thi thay cho Godot MCP không có trong phiên.

Log cuối trong `logs/`. Vẫn có cảnh báo ObjectDB/resource/RID khi thoát như v3, cả test race cũng gặp. Lần đầu kiểm UI gặp hai ảnh IAP đang được thêm ngoài phạm vi chưa có cache import; sau import đã chạy lại và không còn lỗi thiếu loader/parse/script.

Chạy lại capture: `XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy -s res://tests/garage_car_v4_capture.gd -- --economy-test`.

## Còn lệch

Cabin/kính còn là hình học giản lược, chưa có độ phồng hữu cơ và khung kính chi tiết bằng concept. Màu trắng dữ liệu dưới ánh sáng vẫn sáng hơn màu kem mẫu; không sửa bảng màu game. Vành/lốp và độ mềm bóng chưa đạt render minh họa; số nhỏ ở thumbnail. Tia chớp cạnh cửa bị che một phần theo góc xoay bởi huy hiệu/bánh. Năm thân khác tỷ lệ nhưng vẫn cùng ngôn ngữ mesh bo; chưa đo FPS mobile/web.

Màn đua vẫn dùng default Pico được rebuild; số động/livery và phản chiếu trang trí là phần của CarPreview Garage, chưa tích hợp vào renderer đua vì hai file được yêu cầu giữ nguyên. Layout Garage khác concept nằm ngoài phạm vi chỉnh xe.

`files_changed.txt` liệt kê chính xác các file dành cho phần việc này để điều phối tách commit. Không bao gồm `.png.import` tự sinh của ảnh tài liệu (có thể bỏ khỏi commit), hoặc thay đổi đồng thời của tác vụ khác.
