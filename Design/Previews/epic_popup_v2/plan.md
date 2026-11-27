# Popup Xe Epic: đối chiếu demo (skill setup-ui-from-demo)

- Demo chuẩn: `Design/Concepts/IAP_Epic_Garage_v1/epic_car_popup_v1.png` (916x1716, scale về rộng 390 → 390x731).
- Màn: popup chi tiết `epic_car_zenith`, ngôn ngữ vi, rộng 390. Code: `ui/shop_epic_detail.gd`, nhánh Epic trong `ui/main.gd::_fill_iap_detail`.
- Chụp: `tests/epic_popup_capture.gd` (in toạ độ node `RECT ...`).
- Quyết định người dùng (27/11/2026): xe trong popup dùng sprite 2D cắt từ demo; mục tiêu ≥ 90%.

## Vùng đo (cố định)

Toạ độ logical ở rộng 390, neo theo đỉnh thanh tiêu đề:
- Demo: `--demo-crop 9,83,372,612` (thanh tiêu đề y=83).
- Game: `--game-crop 9,<y EpicHeader>,372,612`; tại 390 EpicHeader y=98 → `9,98,372,612`.

## Điểm

| Lần | Điểm | Màu | Đường nét |
|---|---|---|---|
| Trước (bản cũ) | 67,6% | 72,8 | 62,3 |
| Sau | **90,0%** | 94,6 | 85,4 |

Ảnh: `compare_before.png`, `compare_after.png`, `score_before_heatmap.png`, `score_final_heatmap.png`.

## Bảng đối chiếu

Toạ độ: demo tuyệt đối / game tính từ đỉnh thanh tiêu đề (demo 83, game 98).

| # | Phần | Demo | Cách làm | Kết quả |
|---|---|---|---|---|
| 1 | Khung | viền kem 9..381, dày 7, bo 24, đáy 693 | CODE `EpicDetail.shell()` `#f8e5d6`, mép `#e2c6b1` | KHỚP (x 9..381, đáy +612) |
| 2 | Thẻ trong | `#fcede2`, mép `#e7cfbe`, bo 18 | CODE (vẽ trên `EpicDetail`) | KHỚP |
| 3 | Thanh tiêu đề | 13..376 x 83..135, xanh bóng, ca rô phải | ASSET MỚI `header_bar` (9-slice) | KHỚP |
| 4 | Hộp quà | 26..90 x 66..134 | ASSET MỚI `header_gift` | KHỚP |
| 5 | Chữ tiêu đề | trắng viền xanh đậm, ~23 | CODE Label | KHỚP |
| 6 | Nút đóng | tròn đỏ viền trắng, tâm (352,89) r21 | ASSET MỚI `close_round` (vùng chạm 45x45) | KHỚP |
| 7 | Sân khấu xe | 18..372 x 140..394: ruy băng EPIC, ánh tím, xe F1, bệ ca rô | ASSET MỚI `stage_zenith` (2D, chỉ xe Zenith) | KHỚP |
| 8 | Tên xe | 395..428, cỡ ~40, `#021650` | CODE Label 40 trong ô 38 | KHỚP |
| 9 | Chip | 56.5..333.5 x 434..465 | ASSET MỚI `chip` (9-slice) + Label 16 | KHỚP (rộng 278 vs 277) |
| 10 | 3 ô lợi ích | 25..365 x 476..567, rộng 110, cách 5 | ASSET MỚI `tile` (9-slice) | KHỚP (cao 91) |
| 11 | Icon ô | đồng hồ / thẻ xe / cờ ca rô ~50 cao | ASSET MỚI `tile_speed`, `tile_collect`, `tile_flag` | KHỚP |
| 12 | Chữ ô | 2 dòng, cỡ ~16 | CODE Label 16 | CÒN LỆCH: xuống dòng khác ("Xe sưu / tầm", "Dùng / được ngay"); concept ngắt dòng không theo quy luật bề rộng, không ép xuống dòng trong i18n |
| 13 | Nút giá | 23..367 x 577..642, viên thuốc cam | ASSET MỚI `button` (9-slice) + chữ 46 | KHỚP |
| 14 | Chữ giá | "$9,99" | GIỮ NHƯ GAME: giá do store/locale (`$9.99`) | Khác dấu thập phân |
| 15 | "Để sau" | xám `#6b6b6d` gạch chân, tâm y≈666 | CODE, vùng chạm 44 | KHỚP |
| 16 | Nền sau popup | ảnh garage mờ | GIỮ NHƯ GAME: lớp phủ trên Shop | Ngoài vùng đo |

## Còn lại

- Bộ sơn Epic (`epic_paint_*`) dùng chung khung/thanh tiêu đề/ô/nút mới nhưng vẫn là sân khấu 3D và icon cũ: chưa có concept riêng.
- 4 xe Epic khác (Pico, Nova, Apex, Titan) chưa có ảnh 2D: dùng sân khấu 3D tới khi có concept.
- Ở rộng 412 thẻ giữ rộng 358 như 390 (scale tối đa 1.0) để chữ không tràn.
