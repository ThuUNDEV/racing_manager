# 24 — Nâng cấp bằng cúp

Cấu hình: `data/trophy_upgrades.json`. Code: `GameData.trophy_*`, `GameState` (mục "Nâng cấp bằng cúp"), bảng ở tab Giải (`ui/main.gd:_build_trophy_panel`). Test: `tests/trophy_test.gd`, `tests/trophy_ui_test.gd`.

## Luật

- **Cúp chỉ nhận khi về đích top 3.** P1 = 3, P2 = 2, P3 = 1, từ P4 trở xuống = 0, nhân hệ số giải (1, 2, 3, 4, 5, 6).
- **Trần tổng cúp đã kiếm** (tích lũy, tính cả phần đã tiêu): theo giải, 100 → 420 (mục "Nâng trần theo giải"). Chạm trần thì không nhận thêm; lượt cuối được cắt cho vừa trần. Trần hiệu lực = `cap.by_league[giải]` + `trophy_cap_bonus`.
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

Tổng giá mua hết: 414 cúp; trần giải 0 là 100 và chỉ đạt 420 ở giải 5, nên người chơi phải chọn ở các giải đầu.

## Save

Thêm khóa `trophies`, `trophies_earned`, `trophy_levels`, `trophy_cap_bonus` (không bump `SAVE_VERSION`; thiếu khóa = 0). `_apply_trophies` làm sạch: id lạ bị bỏ, cấp chặn theo cấu hình, không âm.

## Layout Giải — cập nhật 2026-11-12

- Tiêu đề giải và hệ số cúp nằm trên nền xanh nhạt, tách khỏi ảnh đường đua.
- Banner phân biệt **Cúp đang có** và **Tổng đã kiếm / trần**. Thưởng top 3 gói trong một hàng; nút `i` mở giải thích giới hạn tích lũy.
- Ba nhóm dùng thanh chọn chung; mỗi thẻ hiển thị tên, cấp, mô tả và hiệu ứng bên trái nút giá. Nút chỉ có icon cúp và số giá, không có chữ “Nâng”.
- Thẻ chưa mở chỉ hiện tên, cấp và giải yêu cầu.- Giữ nguyên dữ liệu, giá, hiệu ứng và điều kiện mua; nâng cấp vẫn áp dụng từ lượt sau.
- Kiểm tra: `tests/trophy_ui_test.gd` (headless và native, 320/360/390/412 px), `tests/trophy_test.gd`. Ảnh: `Design/Previews/trophy_layout_390.png`.

## Layout Giải — cập nhật 2026-11-14

- Tích hợp demo đã chọn với bộ ssets/league_redesign/ phiên bản 2 giảm bóng: tiêu đề xanh họa tiết cờ, banner cúp kem vàng, ba tab có icon.
- Thẻ dùng hình riêng cho đủ 8 nâng cấp, vạch cấp theo cấu hình, chỉ số và nút mua chỉ gồm cúp + giá. Thẻ khóa có icon khóa và giải yêu cầu.
- Giữ nguyên luồng callback, dữ liệu kinh tế, bản dịch và điều kiện mua hiện có. Nút i vẫn mở giải thích trần tích lũy.
- Nền dùng nine-patch; icon bật mipmap để giảm răng cưa khi thu nhỏ. Các thẻ tiếp tục cuộn khi màn hẹp hoặc nội dung dài.
- Kiểm tra: 	rophy_test.gd, 	rophy_ui_test.gd và league_redesign_preview_test.gd đều qua. Preview native OpenGL ở 320/390/412 px cho đủ 3 nhóm; kiểm tra thêm trạng thái tối đa, chạm trần và VI/EN ở 320 px. Chưa kiểm tra điện thoại thật; Godot còn báo resource leak khi thoát test.
- Ảnh thực tế: Design/Previews/league_redesign_390_offense.png (các ảnh còn lại cùng tiền tố).

## Nâng trần theo giải (đã code)

**Vấn đề.** Trần cố định 100 chạm sau ~6 lượt P1 ở giải 5 (3 × 6 = 18 cúp/lượt). Hệ số giải ×1–×6 chỉ làm chạm trần nhanh hơn, không thêm tiến triển, và 414 cúp để mua hết không bao giờ đạt được.

**Luật.** Trần gốc phụ thuộc giải hiện tại (`business_tier`, 0–5), bảng nằm trong `data/trophy_upgrades.json`:

```json
"cap": { "base": 100, "by_league": [100, 160, 230, 300, 365, 420] }
```

`trophy_cap() = by_league[min(business_tier, len-1)] + trophy_cap_bonus`. Nếu thiếu `by_league` thì dùng `base` như cũ.

| Giải | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---:|---:|---:|---:|---:|---:|
| Trần tổng cúp đã kiếm | 100 | 160 | 230 | 300 | 365 | 420 |
| Phần trần mở thêm khi lên giải | — | +60 | +70 | +70 | +65 | +55 |
| Cúp/lượt khi P1 (3 × hệ số) | 3 | 6 | 9 | 12 | 15 | 18 |
| Số lượt P1 để lấp phần mở thêm | — | 10 | ~8 | ~6 | ~4 | ~3 |

- Trần giải 0 giữ nguyên 100 nên không đổi hành vi với người chơi hiện tại. Trần giải 5 là 420, vừa đủ 414 để mua hết mọi nâng cấp.
- Trần vẫn là tổng tích lũy kể cả phần đã tiêu. Lên giải **không reset** `trophies_earned`, chỉ mở thêm chỗ để kiếm tiếp.
- Mức mở thêm giữ số lượt cần để lấp đầy trong khoảng 10 → 3 lượt P1, nghĩa là nhịp mở khóa thưởng cho việc thăng giải chứ không bắt cày thêm ở giải thấp. Đây là giá trị khởi điểm, cần mô phỏng.
- `trophy_cap_bonus` giữ nguyên cho nguồn nâng trần khác (sự kiện, IAP nếu có), cộng sau bảng giải.
- Giải không lùi, nên trần không giảm. Nếu sau này có tụt giải thì dùng giải cao nhất đã đạt.

**Phần cần sửa khi làm:**
- `core/data/game_data.gd`: thêm `trophy_cap_for_league(tier)`, kiểm `by_league` đơn điệu không giảm và không âm trong bước validate (đã có kiểm `cap.base` ở dòng ~1000).
- `game/game_state.gd:1537` `trophy_cap()` dùng `business_tier`.
- UI banner `ui/trophy_panel.gd` đã đọc `gs.trophy_cap()`, không cần đổi; nên thêm dòng gợi ý “Lên giải X để mở trần Y” cho nút `i`.
- Test: `tests/trophy_test.gd` thêm ca trần theo từng giải, lên giải không reset tổng đã kiếm, thiếu `by_league` thì về `base`.
- Save: không đổi, trần suy ra từ giải.

## Cần cân bằng bằng mô phỏng

Giá và hiệu ứng là giá trị khởi điểm chưa qua playtest: mức +12 chỉ số, +15 giây thu nhập/lượt, tốc độ kiếm cúp so với trần 100.
