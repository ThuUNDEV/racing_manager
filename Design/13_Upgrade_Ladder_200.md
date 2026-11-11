# Thang 200 cấp cho tám nâng cấp

Ngày: 10/11/2026. Trạng thái: **đã triển khai với D = 3** (chốt 10/11/2026): `data/economy.json`, `Pricing._cost`, `GameState.part_stat`/`plan_buy`/`buy_many`, save v5 (cấp cũ ×10), UI chọn ×1/×10/×Max. Các bảng thời gian ở §3 tính với D = 1; với D = 3 nhân khoảng 3 (đủ 200 cấp b0 ≈ 1,7 giờ, cả game ≈ 75 giờ online). Kịch bản "xe chậm nhất" cần đo lại với bước +0,2 mỗi cấp. Mở rộng giới hạn 20 cấp của [11](11_Eight_Upgrades.md) và [12](12_BigNumber_Economy.md) lên **200 cấp cho mỗi loại** (4 bộ phận xe + 4 nguồn doanh thu), không đổi hình dạng kinh tế v2 (6 bậc kinh doanh, BigNumber, thưởng, offline).

## 1. Nguyên tắc: chia nhỏ mỗi cấp cũ thành 10 cấp

Cấp mới `m` (0–200) tương ứng cấp cũ `n = m / 10`. Giữ nguyên **điểm cuối** (tổng hiệu ứng ở cấp tối đa, tổng tiền) và chỉ làm bước nhỏ hơn, để thang 200 cấp không phá cân bằng giải, bot và phần mở bậc đã thiết kế ở 12.

| Thành phần | Thang 20 cấp (hiện tại) | Thang 200 cấp |
|---|---|---|
| Chỉ số bộ phận xe | `nền + 2,0 × n` | `nền + 0,2 × m` (cấp tối đa vẫn +40) |
| Ticket Marketing | `8 + 2,5 × n` | `8 + 0,25 × m` |
| Victory Celebrations | `7,5 × n` | `0,75 × m` |
| Parking | `12,5 × n` | `1,25 × m` |
| Grandstands (sức chứa) | `10 + 5 × n` | `10 + 0,5 × m` |
| Mốc mở bậc kế (`reference_revenue_level`, `expansion_min_revenue_level`) | 12 | 120 (cùng 60% thang) |

Vì hiệu ứng tuyến tính nên rate ở cấp 120 đúng bằng rate ở cấp 12 cũ (`1,946 × S(b)`), và công thức phí mở bậc, giá xe bắt buộc ở 12 §5 **không phải sửa**.

## 2. Giá

```text
g = growth^(1/10) = 1,45^0,1 ≈ 1,0380
K = Σ g^j (j = 0..9) ≈ 11,855
cost(m → m+1) = S(b) × ceil( base × Q(b) × D × g^m / K )
```

- `base` giữ như 12: bộ phận 120, doanh thu 150 / 300 / 500 / 800; `Q`, `S` theo bậc như cũ.
- `K` chuẩn hóa để **tổng giá của 10 cấp nhỏ bằng đúng giá một cấp cũ** (nhân `D`). Làm tròn lên **trước** khi nhân `S`, như 12.
- `D` là **hệ số kéo dài thời gian**, mặc định 1, dùng chung cho cả tám loại (có thể tách riêng bộ phận và doanh thu sau). Chỉnh `D` là cách duy nhất để thay độ dài game; không sửa `g`, vì `g` giữ hình dạng đường giá.
- Cấp 0 không phải giá cấp 1 sau tăng trưởng (giống 12).

## 3. Kết quả mô hình (b0, `D = 1`, chỉ bốn nguồn doanh thu, chiến lược ROI)

Mô hình: [Economy/upgrade_ladder_200_model.py](Economy/upgrade_ladder_200_model.py). Chờ đủ tiền rồi mua mục có giá/Δrate nhỏ nhất, mua tức thời, không tính thưởng đua, offline, mua xe. **Đây là mô hình đối chiếu, không phải playtest.**

**Đối chiếu hai thang:**

| Mốc | 20 cấp | 200 cấp |
|---|---|---|
| Đạt cấp thấp nhất = 60% thang (mốc mở bậc) | 6,7 phút | 6,3 phút |
| Doanh thu ở mốc đó | 1,95K/s | 1,95K/s |
| Đủ cấp tối đa | 34,0 phút | 33,0 phút |
| Tổng giá đủ cấp tối đa | 6,56M | 6,56M |
| Doanh thu ở cấp tối đa | 5,04K/s | 5,04K/s |

Thời gian và tổng tiền khớp trong khoảng 5%, nên thang 200 cấp **không làm game dài hơn hay ngắn hơn** khi `D = 1`; chỉ làm nhịp mua mịn hơn (800 lần mua thay vì 80).

**Mốc trong thang 200 cấp (b0, `D = 1`)**, cấp thấp nhất của bốn nguồn:

| Cấp | Thời gian | Doanh thu/s | Đã chi | Số lần mua |
|---:|---:|---:|---:|---:|
| 10 | 0,8 phút | 89 | 3,5K | 66 |
| 25 | 1,4 phút | 215 | 9,2K | 126 |
| 50 | 2,4 phút | 548 | 30K | 228 |
| 100 | 5,2 phút | 1,64K | 222K | 430 |
| 120 | 7,4 phút | 2,23K | 471K | 510 |
| 150 | 13,3 phút | 3,31K | 1,47M | 631 |
| 200 | 33,0 phút | 5,04K | 6,56M | 800 |

**Hệ số kéo dài D** (đủ 200 cấp b0): D=1 → 33 phút, D=2 → 1,1 giờ, D=3 → 1,7 giờ, D=5 → 2,8 giờ, D=10 → 5,6 giờ. Thời gian gần tỷ lệ với D. Các bậc sau nhân thêm theo `Q`: ở 12 mô hình v2 cho tổng khoảng 25 giờ online qua sáu bậc, nên D=1 giữ nguyên con số đó, D=3 thì khoảng 75 giờ. **Chọn D là quyết định thiết kế còn mở** (xem §7).

**Giá một bộ phận xe (b0, xe hạng 1, `D = 1`):**

| Cấp | Giá bước | Cộng dồn | Chỉ số cộng thêm |
|---:|---:|---:|---:|
| 1 | 11 | 11 | +0,2 |
| 10 | 15 | 126 | +2,0 |
| 50 | 63 | 1,47K | +10 |
| 100 | 400 | 10,7K | +20 |
| 150 | 2,56K | 70K | +30 |
| 200 | 16,4K | 450K | +40 |

Bốn bộ phận lên cấp 200 tốn khoảng 1,8M, rẻ hơn tổng doanh thu cần để đạt thu nhập tối đa (6,56M), như thiết kế v2.

## 4. Ảnh hưởng tới đua

- Mỗi cấp bộ phận chỉ +0,2 chỉ số: +0,2 Speed ≈ +0,01 đơn vị/giây (khoảng 0,05%) trên đoạn thẳng. Một cấp lẻ **không đủ để đổi hạng**; người chơi thấy khác biệt sau khoảng 10–30 cấp. UI phải gom hiệu ứng (§5) để tránh cảm giác "mua mà không thấy gì".
- Cấp 200 của một bộ phận = +40 chỉ số ≈ +2 đơn vị/giây (+10%) cho Speed, +1,8 (+10%) cho Handling, vẫn trong khoảng cách giữa các hạng xe (nền xe chênh 16–22 giữa hạng). Mô phỏng đua không đổi: chỉ `part_stat` trả số thực thay vì số nguyên; sim vốn dùng float.
- **Kịch bản "xe chậm nhất rồi mạnh dần"** cần đo lại bằng `tests/lab/scenario_lab.gd`, đổi bước nâng cấp từ +2 sang +0,2 mỗi cấp. Với thang này đủ chỗ để bot cao nhất tương đương khoảng +7% (offset +14), và xe người chơi vượt họ khi bốn bộ phận ở khoảng cấp 120–150.

## 5. UI bắt buộc

800 lần mua một nút là không chấp nhận được, nên **mua ×1 / ×10 / ×Max bắt buộc** cùng đợt (12 §5 đã chuẩn bị API, nay thành yêu cầu):

- Mỗi thẻ hiển thị cấp hiện tại `m/200`, giá bước kế, và tổng giá/hiệu ứng của lựa chọn ×10 hoặc ×Max.
- ×Max tìm nhị phân số cấp đủ tiền, **tính tổng bằng cộng từng cấp có ceil** (không dùng công thức tổng hình học) và kiểm tra lại trước khi trừ tiền, theo 12 §5.
- Chỉ số bộ phận hiển thị 1 chữ số thập phân ("Speed 46,0 → 46,2").
- Ba mốc hiển thị tiến độ (cấp 60/120/200) và mốc mở bậc ở cấp 120 trên màn Giải.

## 6. Thay đổi cần làm khi triển khai

| Nơi | Thay đổi |
|---|---|
| `data/economy.json` | `max_level` 200; `per_level` doanh thu chia 10; `reference_revenue_level`, `expansion_min_revenue_level` = 120; thêm `part_stat_per_level` = "0.2", `level_subdivision` = 10, `duration_factor` (D) = "1" |
| `core/economy/pricing.gd` | `_cost` dùng `g^m / K` (BigNumber `pow` với số mũ phân số: dùng bảng `g^m` dựng sẵn bằng BigNumber cho 200 cấp) |
| `core/data/game_data.gd` | Bỏ kiểm tra cứng `max_level == 20`; kiểm `reference_revenue_level ≤ max_level`, `part_stat_per_level > 0`, `level_subdivision ≥ 1`, `duration_factor > 0`, giá và rate hữu hạn ở cấp 200 |
| `game/game_state.gd` | `part_stat` trả `float` (`nền + part_stat_per_level × m`); `player_stats` đã là float; giới hạn cấp theo `max_level` |
| `ui/main.gd` | Thẻ nâng cấp: ×1/×10/×Max, cấp `m/200`, 1 chữ số thập phân |
| Save | Tăng `SAVE_VERSION`; **migration nhân cấp cũ với 10** (cấp 7 → cấp 70) để hiệu ứng giữ nguyên; không hoàn/ thu tiền; hỗ trợ save đã ở thang mới |
| Test | Giá cấp 0/1/9/10/199, tổng 10 cấp nhỏ = giá một cấp cũ (đến sai số ceil), ×Max khớp cộng từng cấp, migration, validate cấu hình sai, golden đua không đổi |

## 7. Quyết định còn mở

1. **Hệ số D (độ dài game): ĐÃ CHỐT D = 3** (`duration_factor` trong `economy.json`). Lựa chọn ban đầu để tham khảo: D=1 giữ nguyên độ dài v2 (~25 giờ qua sáu bậc, ~33 phút đủ b0). Nếu muốn mỗi bậc kéo dài hơn khi có 200 cấp thì tăng D (D=3 ≈ 1,7 giờ b0, ≈ 75 giờ cả game) — nên chốt sau khi có playtest, không đoán trước.
2. **Thang 200 áp dụng cho mọi bậc hay chỉ b0.** Thiết kế này dùng cùng thang cho cả sáu bậc (mỗi cơ sở mới bắt đầu cấp 0 như 12 §3). Nếu nhiều bậc × 800 lần mua là quá dài, có thể dùng thang 200 cho b0–b1 rồi 100 cho bậc sau.
3. **Cột mốc thưởng** (ví dụ ×2 thu nhập ở cấp 50/100/150/200 như nhiều game idle) chưa đưa vào, vì sẽ đổi điểm cuối đã khớp ở §3; nếu muốn, phải mô hình lại.

## 8. Giới hạn bằng chứng

Mô hình chỉ bậc b0, chỉ doanh thu, mua tức thời, một chiến lược. Chưa mô phỏng thưởng đua, offline, mua xe, các bậc sau và thao tác bấm thật của người chơi. Kết quả "khớp 5%" chỉ chứng minh phép chia nhỏ bảo toàn thời gian và tổng tiền trong mô hình này, không chứng minh cân bằng đã đủ hay game đã đủ dài.
