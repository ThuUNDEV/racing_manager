# Garage polish implementation v2 — 27/11/2026

Chuẩn: `Design/Concepts/Garage_Redesign_v2/01-car.png`, `02-parts.png`, `03-look.png`. Phong cách: `Design/Demos/SoftMiniature/approved/04-garage.png`. Đã mở ảnh thật của cả ba concept, ảnh v1 và 9 ảnh v2 để đối chiếu từ trên xuống. `comparison.html` cho xem cạnh nhau, giữ tỷ lệ gốc, chọn tab và rộng.

## Kết quả

- Tab Xe đúng thứ tự showroom → tên + badge hạng → 4 chỉ số → Nâng cấp/Đang dùng → tab → Bộ sưu tập.
- Nâng cấp tại tab Xe xanh lá; CTA mua nâng phụ tùng vẫn cam theo concept 02.
- Tạo 4 icon phụ tùng và 4 icon chỉ số đất sét bằng **tools/gen_image.py / gpt-image-2.6-flare / medium**. Alpha thật từ API, đã xem trên nền xám và runtime. Icon phụ tùng lớn bên trái thông tin; chỉ số dùng icon 30 thay 20.
- Nền showroom mới không xe: bục xanh viền caro, cúp, lốp, tủ, cây, cờ và ánh sáng ấm. Xe 3D thật đặt lên trên; camera nền mới được chỉnh riêng, không đổi preview ngoài Garage.
- Collection có nền xanh, màu biến thể, pill trạng thái và icon khóa. Cosmetics người chơi đã lưu được ưu tiên; active không lưu giữ màu mặc định thật. Map trình bày: family hạng lẻ cam/xanh dương/xanh ngọc; hạng chẵn tím/vàng/đỏ theo archetype. Không ghi màu map vào save.
- 320 thu showroom còn 92, giảm padding chỉ số/footer phụ tùng, thẻ phụ tùng 96. Hàng đầu bộ sưu tập và cả bốn thẻ phụ tùng đều nhìn thấy đủ.

## Ảnh runtime

| Logical width | Xe | Phụ tùng | Ngoại hình |
|---|---|---|---|
| 320 | [320_tab0.png](320_tab0.png) | [320_tab1.png](320_tab1.png) | [320_tab2.png](320_tab2.png) |
| 390 | [390_tab0.png](390_tab0.png) | [390_tab1.png](390_tab1.png) | [390_tab2.png](390_tab2.png) |
| 412 | [412_tab0.png](412_tab0.png) | [412_tab1.png](412_tab1.png) | [412_tab2.png](412_tab2.png) |

Harness: `tests/garage_redesign_ui_test.gd`. Tỷ lệ 390×845; ngôn ngữ Việt, 120K coins, 100 gem, 2 xe sở hữu, cấp 40/30/20/10. Các giá/chỉ số dùng dữ liệu hiện hành. Chụp Vulkan Forward+, screen 1, audio Dummy, XDG_DATA_HOME tạm + economy-test. Không chụp ảnh editor.

Lặp 1: asset/layout mới, phát hiện xe thấp khỏi bục và clipping ở 320. Bằng chứng giữ tại `round1/`.
Lặp 2: chỉnh camera span/target; giảm chiều cao và padding ở 320, chỉnh thẻ 112/96; kiểm đủ 9 ảnh.
Lượt xác nhận cuối: harness có thêm assertion thứ tự, toàn bộ hàng xe đầu, màu biến thể, khóa, và chữ nằm trong thẻ ở 8 ngôn ngữ. Ảnh gốc thư mục là lượt cuối.

## Bảng điểm lệch còn lại

Thang định tính: **0** = tiêu chí đã đạt; **1** = còn khác chi tiết mỹ thuật; **2** = còn khác rõ, cần asset hoặc phạm vi khác. Không dùng phần trăm pixel/độ giống vì concept AI và runtime khác tỷ lệ màn hình, model và dữ liệu.

| Vùng | Điểm lệch | Đối chiếu còn lại |
|---|---:|---|
| Thứ tự tab Xe/Phụ tùng/Ngoại hình | 0 | Đúng thứ tự người dùng yêu cầu ở cả ba rộng. |
| Nút Nâng cấp | 0 | Xanh lá, vùng chạm ≥44; CTA phụ tùng cam như concept. |
| Icon phụ tùng/chỉ số | 1 | Đã đúng nhóm chất liệu/màu và to hơn; hình khối là bộ sinh mới, không trùng nét từng pixel của concept. Stat bố cục dọc để giữ chữ ở rộng 320. |
| Showroom | 1 | Đủ đồ trang trí, bục caro và bánh xe trên mặt bục; tỷ lệ phòng nén tại 320, xe 3D hiện có khác thân xe AI. |
| Tên/hạng/collection | 1 | Badge dạng pill không có vương miện; xe xanh ngọc thay xanh lá vì dùng bảng màu sẵn có; số xe sở hữu đúng fixture, không giả trạng thái theo concept. |
| Responsive 320 | 0 | Đủ hàng xe đầu, 2×2 phụ tùng, CTA không chồng; các hàng collection sau vẫn cuộn. |
| Ngoại hình | 2 | Giữ swatch/decal native sẵn có: nhỏ và phẳng hơn concept; phần này chưa được thay bộ art. Thứ tự showroom → tab → nội dung đúng. |
| HUD/nav | Ngoài phạm vi | Giữ header/nav toàn game, không thêm avatar/cấp độ và không đổi thứ tự nav. |

## Kiểm tra

| Test | Kết quả |
|---|---|
| garage_test.gd | PASS, 0 lỗi |
| garage_car_preview_test.gd (headless) | PASS, 0 lỗi; model, màu độc lập, decal/snapshot |
| garage_redesign_ui_test.gd (headless + cửa sổ) | PASS, 0 lỗi; 3 rộng × 3 tab × 8 ngôn ngữ; thứ tự, hàng đầu, khóa, màu, bounds chữ phụ tùng, draft/save/mua |
| asset_layout_test.gd | PASS, failures=0 |
| team_tabs_preview_test.gd (cửa sổ) | PASS, cả 320/390/412 và hai tab Đội |
| soft_miniature_ui_test.gd | PASS, failures=0 |
| button_skin_ui_test.gd (toàn game) | FAIL, 316 assertions tại Race/Tay đua/Giải/IAP và màu upgrade Race; không có lỗi Garage được báo. Giữ ngoài phạm vi, không sửa race_view/race_world. |
| i18n_check.py | OK, 0 khóa mới thiếu / 0 lệch placeholder; cảnh báo xuống dòng và 6 chuỗi Việt ngoài Garage còn tồn tại. |
| git diff --check (file liên quan) | PASS |

Log lưu tại `logs/`. Godot còn báo RID/ObjectDB/resource leak khi thoát ở các harness renderer, cũng có ở v1; assertion pass không đồng nghĩa exit sạch. Test TeamTabs phải có renderer vì harness await frame_post_draw; lần headless đã dừng, lần cửa sổ hoàn tất.

Godot MCP project_info/script_check không có trong bộ tool phiên này; dùng import/editor headless, thực thi test và kiểm log SCRIPT ERROR/Parse Error. Không có lỗi cú pháp trong các lượt cuối.

## File sửa/tạo trong lượt polish này

Sửa tiếp trên thay đổi người dùng/v1 đang có, không ghi đè/hoàn tác các thay đổi đó:

- `ui/garage_page.gd`: bố cục, icon mới, màu nút/xe, badge, responsive.
- `ui/car_preview.gd`: texture showroom tùy chọn, camera riêng khi dùng texture đó.
- `i18n/{en,vi,id,ms,th,ja,ko,zh_Hans}.json`: thêm `garage.class_badge`.
- `tests/garage_redesign_ui_test.gd`: thư mục ảnh v2 và assertion bổ sung.
- `Design/34_Layer_Layout_Spec.md`: cập nhật phần Garage hiện hành.
- `assets/garage_soft_miniature_v2/`: 9 PNG, lock.svg, README, prompts.json, manifest.json, metadata import Godot.
- `output/imagegen/garage_polish_v2/`: 9 ảnh thô, prompts.json, script sinh, contact sheet (output bị gitignore).
- `Design/Previews/Garage_Impl_v2/`: 9 ảnh cuối, ảnh vòng 1, comparison.html, README, logs.

## Điểm cần người dùng quyết định

Không có quyết định chặn sử dụng Garage. Muốn tiến sát concept hơn nữa cần duyệt riêng: (1) thay model 3D hiện tại bằng thân xe đất sét mới; (2) bổ sung bộ art swatch/decal/crown và màu xanh lá trong bảng sơn. Chưa thực hiện vì vượt các hạng mục asset được chỉ định trong lượt này.

Không sửa avatar/cấp độ header, `ui/race_view.gd`, `ui/race_world_3d.gd`, dữ liệu cân bằng/giá/save; không dùng RaceStar art; không commit/tạo branch.
