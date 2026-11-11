# 16. Chỉ số tay đua, phong cách đua và stamina

Nguồn tham khảo: prototype "Mini Moto" (chỉ lấy ý tưởng, không chép mã/văn bản). Chỉ áp dụng cho `TrafficSim`; `RaceSim` v1.0 giữ nguyên làm chuẩn.

## 1. Bảy chỉ số tay đua (`data/drivers.json`)
| Hiển thị | Khóa JSON | Khóa sim | Tác động |
|---|---|---|---|
| Launch | `launch` | `L` | cộng vào gia tốc (`driver_stats.launch_accel_per_point` × lệch so với chuẩn giải) |
| Speed | `pace` | `P` | tốc độ thẳng (như cũ) |
| Braking | `braking` | `R` | tăng lực phanh và tốc độ vào cua |
| Cornering | `technique` | `T` | tốc độ cua (như cũ) |
| Racecraft | `racecraft` | `K` | nhân độ mạnh thế vượt/giữ của phong cách (0,5–1,8×) |
| Composure | `composure` | `C` | giảm xác suất lỗi (như cũ) + giữ chế độ ga lâu hơn |
| Endurance | `endurance` | `E` | giảm tốc độ hao stamina |

Giữ nguyên khóa `pace/technique/composure` để không đổi save và test. Chỉ số bot lấy theo `offset`, ghi đè được trong `ai_cars[].stats` (L,R,K,E).

## 2. Bốn phong cách (`sim.json["styles"]`, `drivers.json["style"]`, `ai_cars[].style`)
- **inside – Late-brake attacker:** +1,2% khi có xe sát phía trước, đổi lại accel ×0,96 và cua ×0,995.
- **sweeper – Momentum rider:** cua thoáng (không xe trong 4 thân) +1,2%, cua bị kẹp −0,6%.
- **counter – Counterpuncher:** hút gió ×2 và +0,4% khi có xe phía trước.
- **defender – Tactical defender:** +1,2% khi có xe sát phía sau, giữ chế độ ga lâu hơn ×1,3.

Mọi bonus nhân với hệ số racecraft. Không dùng RNG thêm.

## 3. Stamina và chế độ ga (`sim.json["stamina"]`)
Stamina 100 → hao theo chế độ: `balanced` 0,9/s, `push` 1,8/s (×hệ số endurance), `conserve` hồi 0,5/s. Tốc độ: push ×1,012, conserve ×0,992, dưới 20 stamina bị phạt tới −2%.
Chọn chế độ: dưới 25 stamina và chưa vào 20% cuối → `conserve`; có xe trong 3 thân hoặc vào 20% cuối và stamina > 35 → `push`; còn lại `balanced`. Giữ tối thiểu `3 s × (1 + 0,03 × lệch composure)` (1–6 s) rồi mới đổi.

## 4. Kiểm tra
`tests/traffic_test.gd` (`_test_driver_stats`), `tests/lab/stats_lab.gd` (hạng TB theo tay đua). HUD đua hiện thanh stamina và chế độ ga; thẻ tay đua hiện phong cách và 7 chỉ số.
