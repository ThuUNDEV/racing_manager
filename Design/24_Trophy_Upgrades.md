# 24 — Nâng cấp bằng cúp

Cấu hình: `data/trophy_upgrades.json`. Code: `GameData.trophy_*`, `GameState` (mục "Nâng cấp bằng cúp"), bảng ở tab Giải (`ui/main.gd:_build_trophy_panel`). Test: `tests/trophy_test.gd`, `tests/trophy_ui_test.gd`.

## Luật

- **Cúp chỉ nhận khi về đích top 3.** P1 = 3, P2 = 2, P3 = 1, từ P4 trở xuống = 0, nhân hệ số giải (1, 2, 3, 4, 5, 6).
- **Trần tổng cúp đã kiếm** (tích lũy, tính cả phần đã tiêu): 100. Chạm trần thì không nhận thêm; lượt cuối được cắt cho vừa trần. Trần hiệu lực = `cap.base` + `trophy_cap_bonus` (cơ chế nâng trần sẽ bổ sung sau, chỉ cần tăng `trophy_cap_bonus`).
- Không đạt top 3 thì không có cúp và không nâng được bảng này. Tiến trình chính (tiền, xe, thăng giải) không phụ thuộc cúp.
- Giá nâng từ cấp `l` lên `l+1` = `cost_by_level[l]` (mặc định cấp + 1; nâng cấp kép gấp đôi).
- Hiệu ứng là số cụ thể (`effect_by_level`), không phải phần trăm. Chỉ số xe cộng thẳng vào S/H/B/A; thu nhập tính bằng giây thu nhập thụ động.
- Nâng cấp mới áp dụng từ lượt sau (giống nâng cấp xe: lượt đang chạy dùng chỉ số đã chốt).

## 8 nâng cấp

| Nhóm | Nâng cấp | Hiệu ứng tối đa | Cấp | Mở từ giải |
|---|---|---|---:|---:|
| Tấn công | Động cơ đua | Tốc độ +12 | 10 | 0 |
| Tấn công | Xuất phát nhanh | Tăng tốc +12 | 10 | 0 |
| Tấn công | Đà vượt xe | Tốc độ +6, Tăng tốc +6 | 6 | 2 |
| Phòng thủ | Bám cua | Bám cua +12 | 10 | 0 |
| Phòng thủ | Ổn định thân xe | Ổn định +12 | 10 | 0 |
| Phòng thủ | Khung gầm đua | Bám cua +6, Ổn định +6 | 6 | 2 |
| Thu nhập | Nhà tài trợ | +15 giây thu nhập mỗi lượt | 10 | 0 |
| Thu nhập | Khán đài đông | +300 giây thu nhập mỗi quà ngày | 10 | 1 |

Tổng giá mua hết: 414 cúp; trần gốc 100 nên người chơi phải chọn.

## Save

Thêm khóa `trophies`, `trophies_earned`, `trophy_levels`, `trophy_cap_bonus` (không bump `SAVE_VERSION`; thiếu khóa = 0). `_apply_trophies` làm sạch: id lạ bị bỏ, cấp chặn theo cấu hình, không âm.

## Layout Giải — cập nhật 2026-11-12

- Tiêu đề giải và hệ số cúp nằm trên nền xanh nhạt, tách khỏi ảnh đường đua.
- Banner phân biệt **Cúp đang có** và **Tổng đã kiếm / trần**. Thưởng top 3 gói trong một hàng; nút `i` mở giải thích giới hạn tích lũy.
- Ba nhóm dùng thanh chọn chung; mỗi thẻ hiển thị tên, cấp, mô tả và hiệu ứng bên trái nút giá. Nút chỉ có icon cúp và số giá, không có chữ “Nâng”.
- Thẻ chưa mở chỉ hiện tên, cấp và giải yêu cầu.- Giữ nguyên dữ liệu, giá, hiệu ứng và điều kiện mua; nâng cấp vẫn áp dụng từ lượt sau.
- Kiểm tra: `tests/trophy_ui_test.gd` (headless và native, 320/360/390/412 px), `tests/trophy_test.gd`. Ảnh: `Design/Previews/trophy_layout_390.png`.

## Cần cân bằng bằng mô phỏng

Giá và hiệu ứng là giá trị khởi điểm chưa qua playtest: mức +12 chỉ số, +15 giây thu nhập/lượt, tốc độ kiếm cúp so với trần 100.
