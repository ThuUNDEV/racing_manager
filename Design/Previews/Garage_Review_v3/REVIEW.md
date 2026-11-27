# Garage review v3 — 27/11/2026

Kết luận: đã sửa các lỗi bố cục/cắt nội dung được xác nhận trong phạm vi Garage, nhưng **chưa khớp hoàn toàn concept**. Model xe, shader/vật liệu, độ bóng icon và tỷ lệ màn hình vẫn khác. Không chấm phần trăm giống.

## Đã đọc và thực hiện skill

Đã mở và đọc toàn bộ [.agents/skills/racing-ui-review/SKILL.md](/home/thupv/Desktop/DataSSD/racing_manager/.agents/skills/racing-ui-review/SKILL.md), [CLAUDE.md](/home/thupv/Desktop/DataSSD/racing_manager/CLAUDE.md), [AGENTS.md](/home/thupv/Desktop/DataSSD/racing_manager/AGENTS.md), [Design/34_Layer_Layout_Spec.md](/home/thupv/Desktop/DataSSD/racing_manager/Design/34_Layer_Layout_Spec.md), [.claude/skills/godot-ui/SKILL.md](/home/thupv/Desktop/DataSSD/racing_manager/.claude/skills/godot-ui/SKILL.md). Đã đọc thêm skill imagegen; dùng CLI/model/quality theo yêu cầu trực tiếp của người dùng.

| Bước của skill | Cách thực hiện và bằng chứng |
|---|---|
| Xác định chuẩn | Mở xem thật 01-car/02-parts/03-look trong `Design/Concepts/Garage_Redesign_v2/`; đọc git status/diff trước khi sửa. Garage 3 tab, vi, Pico Tia chớp active, engine 40, các cấp 40/30/20/10; look có bản nháp teal/lightning như concept. Header avatar/cấp độ ngoài phạm vi. |
| Thu thập runtime | CLI cửa sổ `--screen 1 --audio-driver Dummy`, mỗi lần XDG_DATA_HOME mới, kèm `--economy-test`, không `--reset`. Harness [tests/garage_review_v3_capture.gd](/home/thupv/Desktop/DataSSD/racing_manager/tests/garage_review_v3_capture.gd) dựa trên fixture sẵn có; chờ 16 frame và frame_post_draw. Chụp 9 ảnh trước + 9 ảnh sau. Dump mọi Control và minimum size vào 9 file `geometry_*.json`. |
| So sánh | Xem ảnh thật trước/sau, contact sheet cả 9 viewport; bảng dưới đi từ trên xuống. Ảnh chuẩn 1024×1536 được scale **đồng nhất** xuống 390×585; runtime 390×845 được giữ nguyên. So bề rộng, không ép hai tỷ lệ bằng nhau, không crop để che sai lệch. |
| Sửa và lặp | Nhiều lượt chụp/sửa cho swatch, decal, badge, tabs, stats, showroom, thẻ và 320. Dùng native Control, helper, StyleBox; không flatten màn hình, không tạo scene mới. Tạo huy hiệu bằng gen_image.py / gpt-image-2.6-flare / medium; prompt và provenance trong asset pack. |
| Responsive/i18n | Chụp 320×693, 390×845, 412×893. Test 3 tab × 3 width × 8 ngôn ngữ; kiểm width và text trong thẻ phụ tùng. Harness bổ sung kiểm đủ 8 paint/4 decal, vùng chạm ≥44, các lựa chọn/thẻ phụ tùng nằm trọn trong vùng thấy. |
| Tương tác | `garage_redesign_ui_test`: guard bản nháp, lưu qua GameState, bấm CTA mua thật tăng đúng một cấp; `garage_test`: lưu/tải, rollback lỗi ghi, snapshot đua; `garage_car_preview_test`: 15 xe/5 thân, màu/decal, vật liệu không lan sang preview khác. TeamTabs kiểm chọn tab và hit area. Chưa tự động kiểm drag/cuộn bằng input chuột. |
| Báo cáo | Ảnh chuẩn/runtime tách tên, bảng trước/sau, file sửa, log test, phân tích 316 lỗi và giới hạn ở tài liệu này. |

Không có tool Godot MCP `project_info`/`script_check` trong phiên; dùng Godot CLI import và grep log parse/script error. Ảnh là viewport runtime Vulkan Forward+, không phải ảnh editor/headless.

## Bảng sai lệch trước/sau

| Vùng từ trên xuống | Mức độ | Trước | Sau / còn lại |
|---|---|---|---|
| Tỷ lệ màn hình, shell | Lớn | Concept 2:3, game ~390:845; header/nav có hình thức và thứ tự khác | Giữ shell ngoài Garage. So ảnh theo cùng bề rộng; khoảng trống dọc/nhịp bố cục vẫn khác. Header avatar/cấp độ không làm theo phạm vi đã chốt. |
| Showroom | Lớn | 320 chỉ 92 px cao, nền bị stretch dẹt; xe 3D khác xe đất sét của ảnh | 320: Xe 120 / Parts 104 / Look 108 px; 390/412: 170/185/185. Nền dùng uniform cover, giữ tỷ lệ, crop phần trên để giữ bục. Màn hẹp mất một phần cờ/tủ/dụng cụ; model xe hiện hành vẫn khác concept. |
| Tên xe / huy hiệu | Vừa | Chữ tên rời, pill vàng chỉ có Hạng 1 | Badge native text chồng sprite vương miện + nguyệt quế 90×32. Đã thêm khay kem bo16 bao tên và badge, co theo nội dung; độ dài khác thanh trong concept. |
| Stat chips | Vừa | Icon nằm trên chữ và số, thẻ ~99 px, khác hàng ngang trong concept | Icon trái, nhãn/số phải, padding 4, bo 14; cao 65 ở 320 và 71 ở 390/412. Nhãn dài vẫn xuống dòng; chữ nhỏ hơn ảnh concept, khác tỷ lệ native và yêu cầu fit 4 cột. Không sửa số 62,2 / 46 / 46 / 42,4 để giống số minh họa. |
| CTA Xe | Nhỏ | Nâng cấp xanh, đang dùng xám; kích thước cao hơn concept chuẩn hóa | Giữ hit area 44/48 và helper nút dùng chung; đã thêm mũi tên native; hình dáng vẫn khác artwork trong concept. |
| Thanh tab | Vừa | Không có vạch phân đoạn, khoảng tách 4 | Thêm vạch giữa các mục, bỏ khoảng tách, giữ khay kem + pill cam; min 52 để nút chạm 44. Chưa giống gradient vàng của concept (palette cam dùng chung). |
| Thẻ phụ tùng | Vừa | Thẻ phẳng, độ sâu thấp; 320 hàng thứ hai bị che bởi footer | Bổ sung bóng mềm/viền đáy, bo 18; ở 320 thẻ 88, icon 46×60, showroom 104 nên thấy đủ 2×2. 390/412 giữ thẻ 112 và icon 62×76. Icon hiện hành vẫn khác chi tiết sprite trong concept. |
| Nhãn/tiến trình phụ tùng | Nhỏ | Số thuần, thiếu pill cấp như concept; progress phẳng | Giữ dữ liệu/giá thật; cấp 40/200 và max 200 vẫn đúng. Đã thêm pill cấp xám và thanh tiến trình gradient vàng/cam, bo4. |
| Bộ sưu tập Xe | Vừa | Khay/heading lớn; sau tăng showroom có lúc cắt hàng đầu | Heading padding 3; thẻ 94, preview 48 ở 320; thấy trọn hàng đầu. 390/412 thấy nhiều hàng hơn. Khóa vẫn dùng asset hiện hành; màu/owned lấy từ fixture thật (xe thứ ba chưa mua), không giả trạng thái để giống concept. |
| Khay Ngoại hình | Lớn | Tiêu đề trái, không có khay nhóm/đường kẻ | Hai khay bo 18, bóng nhẹ; tiêu đề pill xanh giữa hai vạch. Mật độ khác concept vì game dài hơn và kích thước chạm. |
| Swatch | Lớn | Vòng tròn 22 px phẳng, selected là viền cả thẻ | Vòng màu có highlight, bóng/viền, dấu ✓ và vòng cam; control 42 ở 390/412, 30 ở 320 (đĩa vẽ thực ~34/~24 px); hit target 60/48. Màu lấy đúng catalog, không đổi palette dữ liệu. Vẫn là hình native nên không có texture đất sét raster chính xác. |
| Họa tiết | Lớn | Icon 20 px rất nhỏ, thiếu icon None, lightning sai màu ảnh | Glyph native 40×42 (320:34×34), có None, sọc đỏ, tia xanh, caro; badge ✓ cam, thẻ 74/56. Native SVG gradient vẫn ít chiều sâu hơn sprite concept. |
| Chữ họa tiết vi | Nhỏ | Trống / Ô bàn cờ khác nhãn concept | Đổi đúng key i18n thành Không / Caro; giữ bản dịch khác và dữ liệu giao dịch. |
| Hủy/Lưu và ghi chú | Vừa | Hủy xanh, trạng thái căn trái; note dữ liệu chiếm chiều cao | Hủy xám gradient, Lưu cam; trạng thái căn giữa, có glyph info native. Ghi chú miễn phí/không tăng stat chuyển tooltip footer để không đẩy mất lựa chọn ở 320. |
| Bo góc, bóng, chữ | Nhỏ | Thẻ phẳng, font/độ bóng không đồng nhất với ảnh | Bo 18, shadow size 3 offset (0,2), viền đáy 2/4. Font dùng font dự án; không thể khớp chính xác font/raster/anti-alias từ ảnh sinh AI. |

## 316 lỗi skin nút

Test xác định: [tests/button_skin_ui_test.gd](/home/thupv/Desktop/DataSSD/racing_manager/tests/button_skin_ui_test.gd).

- HEAD sạch chạy từ `git archive HEAD` trong thư mục `/tmp` riêng, không stash, không checkout/branch, không đụng working tree: **271 lỗi**, 435 nút kiểm.
- Working tree trước review: **316 lỗi**, 477 nút kiểm.
- Sau sửa Garage: **316 lỗi**, 477 nút kiểm; danh sách lỗi chuẩn hóa node ID trước/sau giống nhau hoàn toàn ([button_comparison.json](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/button_comparison.json): added_by_review và removed_by_review rỗng).
- 271 lỗi HEAD: RaceStageRow 45, FacilitiesButton 45, BoostChip 45, PackPromo_starter 45, PackPromo_perk 45, DriverDetails_driver_an 15, DriverDetails_driver_binh 15, TrophyInfo 15, kiểm màu nút upgrade 1.
- 45 lỗi tăng ở working tree ban đầu đều là PackPromo_daily (9 lượt kiểm × 5 state), do mục daily đã được thêm trong [ui/main.gd](/home/thupv/Desktop/DataSSD/racing_manager/ui/main.gd) trước review. Không có path lỗi Garage. Không sửa vì ngoài phạm vi và có sẵn trước nhiệm vụ.

HEAD: `25cf104717f3ce0223a900ff364d6340d5395e69`.

## Tests

| Kiểm tra | Kết quả |
|---|---|
| tests/garage_test.gd | 0 lỗi assertion |
| tests/garage_car_preview_test.gd | 0 lỗi assertion |
| tests/garage_redesign_ui_test.gd | 0 lỗi; 3 width × 8 language × 3 tab + guard/save/upgrade |
| tests/garage_review_v3_capture.gd | 0 lỗi; 9 ảnh, 9 dump, full visible choices/parts, hit area |
| team_tabs_preview_test fixture | 6/6 PASS; bản copy chỉ chuyển output sang thư mục review để bảo toàn preview người dùng; chạy windowed vì frame_post_draw không chạy trong headless |
| tools/i18n_check.py | OK |
| tests/button_skin_ui_test.gd | 316 lỗi có sẵn như phân tích trên |
| Godot import / log | Không Parse Error hoặc SCRIPT ERROR |

Có cảnh báo leak/RID/resources lúc thoát trong preview/UI tests; cùng dạng đã có ở baseline/head. Không xem exit code 0 là bằng chứng không có cảnh báo. Không chạy toàn bộ suite toàn game.

## Ảnh và file sửa

Chuẩn gốc: [Design/Concepts/Garage_Redesign_v2/01-car.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Concepts/Garage_Redesign_v2/01-car.png), `02-parts.png`, `03-look.png`.
Bản sao chuẩn: [reference_01-car.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/reference_01-car.png), [reference_02-parts.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/reference_02-parts.png), [reference_03-look.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/reference_03-look.png) trong thư mục này.

Ảnh runtime: `before_runtime_{320,390,412}_tab{0,1,2}.png` và `after_runtime_{320,390,412}_tab{0,1,2}.png`. Tab 0 Xe, 1 Phụ tùng, 2 Ngoại hình. Xem [comparison.html](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/comparison.html), [compare_car_390.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/compare_car_390.png), [compare_parts_390.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/compare_parts_390.png), [compare_look_390.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/compare_look_390.png), [runtime_contact_sheet.png](/home/thupv/Desktop/DataSSD/racing_manager/Design/Previews/Garage_Review_v3/runtime_contact_sheet.png). Chưa tạo overlay pixel diff vì khác aspect ratio và font; không dùng pixel diff làm thước đo giống.

File chỉnh trong review:

- [ui/garage_page.gd](/home/thupv/Desktop/DataSSD/racing_manager/ui/garage_page.gd): thẻ/stat/segmented/badge, swatch/họa tiết, responsive, footer.
- [ui/car_preview.gd](/home/thupv/Desktop/DataSSD/racing_manager/ui/car_preview.gd): chỉ thay vẽ nền Garage thành uniform cover; preview khác giữ cách vẽ trước.
- [i18n/vi.json](/home/thupv/Desktop/DataSSD/racing_manager/i18n/vi.json): hai nhãn None/Caro.
- `assets/garage_soft_miniature_v2/`: rank_badge.png, 4 decal SVG, manifest.json, README.md, review_v3_prompts.json.
- [Design/34_Layer_Layout_Spec.md](/home/thupv/Desktop/DataSSD/racing_manager/Design/34_Layer_Layout_Spec.md): bổ sung số đo review v3.
- [tests/garage_review_v3_capture.gd](/home/thupv/Desktop/DataSSD/racing_manager/tests/garage_review_v3_capture.gd) và uid: harness bằng chứng/assertions bổ sung.
- `Design/Previews/Garage_Review_v3/`: ảnh, geometry, log, báo cáo và fixture TeamTabs chuyển output.

Không sửa race_view.gd/race_world_3d.gd, balance/giá/save, không commit hoặc tạo branch. Không dùng art trong Design/References/RaceStar_Garage_Extract/. Các thay đổi chưa commit trước đó được giữ.

## Giới hạn chưa khớp

Cần asset/model riêng được duyệt để xe có thân bo tròn, kính, đèn, bánh, số 03 và chất liệu đất sét đúng ảnh. Việc sửa mesh dùng chung có thể tác động màn đua nên không thực hiện trong scope UI Garage. Nền phòng hiện hành khác phối cảnh và không đủ panorama cho 320; uniform crop giữ tỷ lệ nhưng mất đồ trang trí phía trên. Muốn vừa đủ toàn bộ phòng và giữ chiều cao hiện tại cần ảnh panorama mới, không thể khôi phục nội dung ngoài ảnh bằng layout. Font và độ bóng icon raster cũng chưa đúng tuyệt đối. Đã polish thêm title tray, pill cấp, gradient progress, info glyph và mũi tên native. Các khác biệt art/model/font và tỷ lệ nêu trên chưa giải quyết được trong phạm vi UI hiện tại; không tuyên bố giống tuyệt đối.
