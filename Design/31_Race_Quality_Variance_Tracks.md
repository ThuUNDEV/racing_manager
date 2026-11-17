# 31. Chất lượng đua: biến động theo stat và đường đua có tính cách

Ngày 16/11/2026. Trạng thái: **hướng A/B (nhiễu theo đoạn, `kind` đoạn đường) vẫn là đề xuất chưa duyệt; §7 (hút gió, nhiễu `form`, thang bot) đã đo và áp dụng một phần bằng dữ liệu (không sửa mã)**.

Phạm vi: hai hướng cải thiện chất lượng đua.

- **A. Biến động có kiểm soát**: nhiễu theo từng đoạn, biên độ phụ thuộc stat của xe.
- **B. Đường đua có tính cách**: thêm loại đoạn đường để mỗi stat có chỗ quan trọng riêng, hiển thị hồ sơ đường trước race.

Liên quan: [04 §2–3](04_Gameplay_Release.md) (công thức tốc độ), [08 §10](08_Race_Traffic_Revision.md) (đua không cản nhau), [10](10_Continuous_Race_Loop.md) (vòng lặp liên tục), [22](22_Race_Classes.md) (class và đường).

## 1. Hiện trạng (đọc từ mã)

| Hạng mục | Hiện tại | Nơi |
|---|---|---|
| Nhiễu | Một giá trị `form` mỗi xe, bốc một lần trước xuất phát, giữ cả race. Khoảng `traffic.form_min/max` = 0,97–1,03, giãn bằng `form_spread` 2,2; class có thể ghi đè (Rally 0,975–1,025, Stock 0,99–1,01…) | `TrafficSim.setup()` |
| Lỗi tay đua | **Tắt** (`traffic.errors_enabled = false`); `corner_grip_*` chỉ cộng/trừ tối đa ±3% tốc độ cua theo B và C | `data/sim.json`, `TrafficSim.step()` |
| Loại đoạn | Chỉ hai: `S` (thẳng) và `C` (cua). Tốc độ thẳng dùng S, P; tốc độ cua dùng H, T, R, B, C; A (gia tốc) chỉ ảnh hưởng lúc tăng tốc | `step()` |
| Đường đua thật | `track_circuit_b…k` (vòng 924), mỗi class một đường. Tỉ lệ thẳng/cua khác nhau (ví dụ f: 298 thẳng / 626 cua, d: 508 / 416). Các track `harbor, pine…` (vòng 400) là dữ liệu cũ của v1.0 | `data/tracks.json`, `data/classes.json` |
| Gợi ý trước race | Trường `important` ("engine", "tyre", "gearbox") và `hint` có trong dữ liệu track nhưng chỉ là chữ | `data/tracks.json` |

Hệ quả:

1. Nhiễu hiện nay là **một hằng số cho cả race**. Xe có `form` thấp thua đều đặn từ đầu tới cuối, không có "khoảnh khắc" (một xe chậm lại ở cua rồi bị vượt). Nhiễu cũng **không liên quan stat**, nên nâng cấp không làm xe ổn định hơn.
2. Đường đã khác nhau về tỉ lệ thẳng/cua, nhưng chỉ có hai loại đoạn. Stat Hộp số (A) và Ổn định (B) ít chỗ phát huy, và người chơi không được báo trước đường nào cần stat nào.

## 2. Hướng A: biến động theo đoạn, gắn với stat

### 2.1. Mô hình

Chia mỗi vòng thành các **đoạn nhiễu** (mỗi sector hiện có là một đoạn). Khi xe vào một đoạn, bốc một hệ số nhiễu cho đoạn đó:

```text
noise(xe, đoạn) = 1 + amp(xe, loại đoạn) × u
u  = RNG(race_seed, xe.id, chỉ số đoạn tuyệt đối)   # phân phối đều [-1, 1]
amp = amp_base[loại đoạn] × (1 - giảm_theo_stat)
target_speed *= noise
```

- `amp_base`: cua 0,020; thẳng 0,008 (khởi điểm để lab chỉnh).
- `giảm_theo_stat` ở cua theo B (Ổn định) và C (Điềm tĩnh), tái dùng ý của `corner_grip_*`: mỗi điểm stat hơn chuẩn giải giảm biên độ một tỉ lệ, kẹp trong [0,3; 1,0]. Ở đoạn thẳng theo C.
- Tổng nhiễu cả race phải **nhỏ hơn** `form` hiện nay: khi bật nhiễu theo đoạn, thu hẹp `form_min/max` tương ứng (ví dụ 0,985–1,015) để biến động tổng không tăng.

### 2.2. Tính chất cần giữ

- **Xác định theo seed**: dùng RNG riêng được băm từ `race_seed`, `id`, `chỉ số đoạn tuyệt đối`, không dùng chung `rng` hiện có. Như vậy bật hay tắt nhiễu không làm đổi kết quả bốc `form` và grid.
- **Xe không ảnh hưởng nhau**: nhiễu của xe này không phụ thuộc xe kia (giữ nguyên tắc 08 §10.3).
- **Bot không đuổi theo người chơi**: biên độ chỉ phụ thuộc stat của chính xe đó. Không thêm hiệu chỉnh nào theo vị trí người chơi.
- **Checkpoint**: vì nhiễu là hàm của (seed, xe, đoạn) nên không cần lưu thêm trạng thái; chơi lại đủ số tick cho cùng kết quả (khớp [10 §8](10_Continuous_Race_Loop.md)).
- **Tắt được**: `traffic.segment_noise = 0` cho kết quả giống hệt hiện tại (điều kiện của test golden).

### 2.3. Giá trị cho người chơi

Nâng Ổn định/Điềm tĩnh không chỉ nhanh hơn (±3% hiện có) mà còn **ít dao động hơn**. Người chơi thấy rõ qua thẻ kết quả: "Thua ở đoạn cua số 3, Ổn định thấp hơn rival".

### 2.4. Việc cần đo trước khi duyệt

| Chỉ số | Cách đo | Mục tiêu (đề xuất, chưa xác nhận) |
|---|---|---|
| Tỉ lệ thắng theo chênh sức mạnh Δ | 1000 race mỗi Δ ∈ {0, 3, 6, 10} stat, mỗi class | Δ=+10% sức mạnh thắng ≥ 85%; Δ=0 gần chia đều; đường cong đơn điệu |
| Đổi hạng mỗi race | Đếm cặp đổi chỗ | Không thấp hơn hiện tại (08 §10.11 ≥ 10 ở nền) |
| Phương sai hạng cuối của build mạnh | Độ lệch chuẩn hạng | Giảm khi tăng B và C |
| Thời lượng và thưởng | Chạy lại `economy_v2_model.py` | Nhịp kinh tế không lệch quá ngưỡng đã duyệt ở [13](13_Economy_v2_Implementation.md) |

Chưa có số đo hiện trạng cho các cột này trong tài liệu. Lần đo nhanh khi soạn (150 race mỗi cấu hình, đường b, d, f) chưa hoàn tất nên **không dùng làm căn cứ**; cần chạy lab chính thức trước khi chốt hệ số.

## 3. Hướng B: đường đua có tính cách

### 3.1. Loại đoạn mới

Giữ `S` và `C` làm gốc để không phá hình học và dữ liệu hiện có. Thêm trường **tùy chọn** `kind` cho sector; thiếu `kind` thì mặc định theo `type` như hiện nay.

| `type` | `kind` | Ý nghĩa | Stat chi phối thêm | Hiệu ứng khởi điểm |
|---|---|---|---|---|
| S | `long` (mặc định) | Thẳng dài | S, P | Như hiện tại |
| S | `accel` | Thẳng ngắn sau cua gấp | A | Tốc độ mục tiêu bị giới hạn bởi gia tốc: `min(target, speed_vào + accel × thời_gian_đoạn)` |
| C | `fast` (mặc định) | Cua rộng, tốc độ cao | H | Như hiện tại |
| C | `hairpin` | Cua gấp | R (phanh), T, B | Giảm tốc độ mục tiêu mạnh hơn khi R thấp |
| C | `rough` | Đoạn gập ghềnh | B, C | Biên độ nhiễu ×1,5 (nối với hướng A) |

Chỉ 4–5 loại để người chơi nhớ được. Mỗi stat phải có ít nhất một loại đoạn mà nó rõ ràng quan trọng; lab phải xác nhận không còn stat "chết" trên toàn bộ đường của mọi class.

### 3.2. Hồ sơ đường

- Tính từ dữ liệu sector: tỉ lệ độ dài theo `kind` (ví dụ "Cua gấp 35% · Thẳng dài 40% · Gập ghềnh 10% · Thẳng ngắn 15%").
- Rút ra **stat gợi ý** (2 stat có trọng số cao nhất). Thay trường `important` viết tay bằng giá trị tính được, để dữ liệu không lệch nhau.
- Chuẩn hóa: phần thưởng không phụ thuộc độ dài vòng (vòng hiện đều 924 cho b–k).

### 3.3. Gắn với class

Mỗi class chọn đường theo bản sắc của nó ([22 §3](22_Race_Classes.md)):

| Class | Hồ sơ đường mục tiêu |
|---|---|
| Racing | Cân bằng các loại |
| Rally | Nhiều `rough` và `hairpin` |
| Stock Car | Nhiều `long`, ít `hairpin` |
| Superbike | Nhiều `accel` và `hairpin` |
| Speedster | Nhiều `long` |

Đây là dữ liệu đường (`kind` trong `data/tracks.json`), không đổi công thức class.

### 3.4. Hiển thị trước race

Thẻ "Đối thủ và đường" gồm: thanh tỉ lệ loại đoạn, 2 stat gợi ý, và ước lượng tỉ lệ thắng (từ bảng đo ở §2.4, không bịa công thức riêng). Đặt trong tab Đua cạnh grid xem trước (countdown), không mở modal chắn màn hình (khớp [10 §7](10_Continuous_Race_Loop.md)).

## 4. Tác động và rủi ro

- **Kinh tế**: đổi công thức tốc độ làm đổi tỉ lệ thắng, nên phải chạy lại mô hình kinh tế ([13](13_Economy_v2_Implementation.md), `Design/Economy/*.py`) và kiểm tra bảng thưởng.
- **Golden**: bật tính năng làm đổi `tests/golden/*`; chỉ sinh lại sau khi lab đạt. Với cờ tắt phải giữ nguyên từng bit.
- **Người chơi thấy bị "xui"**: nhiễu theo đoạn làm kết quả khó đoán hơn. Cần thẻ giải thích thua/thắng và tỉ lệ thắng ước lượng kèm theo, nếu không sẽ có cảm giác thiếu công bằng.
- **Độ phức tạp UI**: tối đa 4–5 loại đoạn; hơn nữa người chơi không đọc nổi.
- **Dữ liệu cũ**: các track `harbor…speedway` (vòng 400) không dùng trong class; chỉ cập nhật `kind` cho `circuit_b…k`, để các track cũ ở mặc định.

## 5. Kế hoạch triển khai đề xuất

1. **Lab nền** (trước khi sửa mã): viết lab đo tỉ lệ thắng theo Δ và đổi hạng cho từng class; lưu số liệu hiện trạng vào tài liệu này.
2. **B tối thiểu**: thêm `kind` vào dữ liệu và validation (`GameData.validate()`), hiệu ứng `accel` và `hairpin`; tính hồ sơ đường. Cờ tắt giữ golden.
3. **Lab**: mỗi stat đóng góp đo được trên ít nhất một đường; chỉnh hệ số.
4. **A**: nhiễu theo đoạn với RNG riêng, `rough`, thu hẹp `form`. Lab lại đường cong thắng.
5. **UI**: thẻ đường và ước lượng tỉ lệ thắng, thẻ giải thích sau race (hướng 1 trong đề xuất chất lượng đua).
6. **Test**: xác định theo seed, bật/tắt nhiễu, hồ sơ đường, validation `kind`, `traffic_test` và `golden_test` cập nhật; chạy `tools/run_tests.sh`.

## 6. Câu hỏi cần duyệt

1. Giữ `S/C` làm gốc và thêm `kind` tùy chọn, hay đổi thẳng sang tập loại đoạn mới?
2. Bật nhiễu theo đoạn cho mọi class, hay chỉ vài class (ví dụ Rally, Monster Truck) trước?
3. Có hiện **ước lượng tỉ lệ thắng** cho người chơi không (cần lab đủ tin cậy trước)?
4. Có cho `form` cũ giữ nguyên rồi cộng nhiễu theo đoạn, hay thu hẹp `form` như §2.1 (tổng biến động không đổi)?

## 7. Đo lab và điều chỉnh đã áp dụng (16/11/2026)

Triệu chứng người chơi thấy: nhiều xe chạy ngang nhau, cảm giác sức mạnh như nhau. Đo bằng `TrafficSim`, class Racing, `track_circuit_b`, 60 lượt 60 giây mỗi cấu hình, mọi chỉ số người chơi = nền giải (Δ = 0). "Sát" = tỉ lệ thời gian hai xe liền hạng cách nhau dưới 2 thân xe.

| Cấu hình | Sát | Đổi chỗ/race | Hạng TB bot mạnh nhất | Hạng người chơi Δ0 / Δ6 / Δ12 | Thắng Δ12 |
|---|---:|---:|---:|---|---:|
| Trước | 45% | 8,4 | 1,4 | 4,92 / 3,30 / 2,18 | 33% |
| A: hút gió 0,05 → 0,015 | 28% | 8,3 | 1,5 | 4,90 / 3,28 / 2,20 | 33% |
| B: A + `form` ±2% (không giãn) | 27% | 4,2 | 1,0 | 4,82 / 2,93 / 1,82 | 20% |
| C: B + thang bot rộng hơn (offset −6…+19) | 18% | 3,3 | 1,0 | 5,23 / 3,90 / 2,73 | 0% |
| **Đã áp dụng** (hút gió 0,015 + `form` ±4,4%) | 29% | 6,8 | 1,1 | 4,85 / 3,03 / 1,92 | 33% |

Đọc kết quả:
- **Hút gió là nguyên nhân chính của việc dồn chùm.** +5% lớn hơn chênh tốc độ giữa hai xe liền kề (khoảng 0,4–1,5%); xe sau luôn bắt kịp. Hạ xuống 0,015 giảm "sát" từ 45% còn 28%, không đổi số lần đổi chỗ hay tỉ lệ thắng.
- **Nhiễu `form` quyết định có "mạnh yếu thật" hay không.** Trước đây `form` ±6,6% (khoảng form 0,97–1,03 nhân `form_spread` 2,2), lớn hơn cả khoảng cách từ bot yếu nhất đến mạnh nhất (khoảng 7,8% tốc độ thẳng). Giảm nhiễu làm thứ hạng rõ ràng hơn nhưng giảm đổi chỗ: cấu hình B còn một nửa.
- **Thang bot rộng (C) làm người chơi khó thắng hơn hẳn** (không thắng nổi dù Δ12) nên đổi nhịp thăng giải và kinh tế; chưa áp dụng.

Tham chiếu game gốc (`Team_Manager/data/leagues_campaign.json`, giải 0, 9 đội): power 40, 42, 50, 62, 80, 102, 130, 162, 200; chênh liền kề 5%, 19%, 24%, 29%, 27%, 27%, 25%, 23%. Hai bot đáy sát nhau, các bậc sau cách nhau đều 19–29%, tức khoảng cách lớn hơn nhiễu nhiều lần. Đơn vị power của game gốc không quy đổi được ra tốc độ của dự án này; chỉ dùng **hình dạng** thang.

**Đã áp dụng:**
1. `data/classes.json`: Racing có `traffic_mult.draft_bonus` = 0,3 (hút gió 0,015). Các class khác giữ nguyên.
2. `data/sim.json`: `traffic.form_min/max` 0,97–1,03 → **0,98–1,02** (nhiễu hiệu dụng ±6,6% → ±4,4%). Chỉ ảnh hưởng đua chính của Racing và tính thời lượng tham chiếu; class có `form` riêng không đổi. Đã cân nhắc ±2,2% (cấu hình B) nhưng số đổi chỗ giảm một nửa.
3. Test: `class_test` (Racing có ghi đè hút gió), `traffic_test` ngưỡng đổi chỗ 8 → 6 (đo được 7,0; lý do ở chú thích test), sinh lại `traffic_golden.json`.

**Chưa áp dụng (cần duyệt):** thang bot rộng hơn theo hình dạng game gốc. Làm đổi tỉ lệ thắng và nhịp thăng giải nên phải chạy lại mô hình kinh tế ([13](13_Economy_v2_Implementation.md)) và `promotion_lab` trước.

Ghi chú: `state_test` đã thất bại một mục ("Ticket Marketing cấp 1 => 8,25075/giây") **trước khi sửa** và không liên quan thay đổi này.

## 8. Đường cong nâng cấp dồn vào cấp đầu (16/11/2026)

**Vấn đề.** Xe khởi đầu (Pico, tay đua An) đã ở giữa bảng (hạng TB 4,94, top 3 khoảng 13%), và mỗi cấp nâng cấp chỉ cộng +0,15…+0,25 chỉ số tuyến tính, nên 10 cấp đầu gần như không đổi hạng (4,94 → 4,66). Tham chiếu Race Star: nâng cấp đầu rẻ, +2%/cấp, bậc bot cách nhau 19–29%, nên vài cấp đầu đã vượt được một bot (dải tăng của người chơi lớn hơn dải bot nhiều lần).

**Thay đổi.** `economy.json["part_stat_curve_exp"]` = **0,7**. Chỉ số cộng thêm của bộ phận:

```text
gain(cấp) = hệ_số_bộ_phận × max_level × (cấp / max_level)^0,7
```

- `max_level` 200 và hệ số riêng (động cơ 0,25; chassis 0,2; hộp số 0,18; lốp 0,15) **không đổi**: cấp 200 vẫn cộng đúng như tuyến tính cũ (động cơ +50), nên đích cuối không dịch.
- Mặc định 1,0 khi thiếu khóa = tuyến tính cũ (bit-giống). Hợp lệ trong 0,3–1,0.
- Hàm duy nhất `Pricing.part_stat_gain(kind, level)`, dùng cho `GameState.part_stat` và `car_part_stat`. Giá nâng cấp, thu nhập và thưởng **không đổi**.

**Đo** (Racing, `track_circuit_b`, đua 3 vòng, 60–80 race mỗi điểm, nâng đều 4 bộ phận từ xe khởi đầu):

| Cấp mỗi bộ phận | Tuyến tính cũ: hạng TB / top 3 | p = 0,7 (áp dụng) | p = 0,55 (không chọn) |
|---:|---|---|---|
| 5 | 4,80 / 15% | 4,43 / 26% | 4,13 / 31% |
| 10 | 4,66 / 18% | 4,17 / 31% | 3,77 / 38% |
| 20 | 4,38 / 25% | 3,75 / 38% | 3,47 / 46% |
| 40 | 3,80 / 36% | 3,27 / 56% | 2,87 / 81% |
| 80 | 2,89 / 76% | 2,55 / 85% | 2,28 / 91% |
| 120 | 2,31 / 92% | 2,08 / 96% | 1,93 / 96% |
| 200 | 1,43 / 100% (top 1: 57%) | không đổi | không đổi |

p = 0,55 kéo top 3 lên 81% chỉ sau 40 cấp, rút ngắn quá nhiều giữa game. p = 0,7 đủ để 10 cấp đầu đã cải thiện khoảng nửa hạng.

**Tác động cần theo dõi.**
- Giữa game mạnh hơn trước một chút (cấp 80: top 3 từ 76% lên 85%): tiền thưởng và cúp theo hạng đến sớm hơn. Chưa chạy lại mô hình nhịp kinh tế ([05](05_Economy_Monetization.md), [12](12_BigNumber_Economy.md), `Design/Economy/*.py`); cần làm trước khi phát hành.
- Chỉ đo class Racing trên `track_circuit_b`; các class khác có hệ số riêng (`tuning_mult`) chưa đo.
- Chỉ hướng 1 trong hai hướng đã đề xuất; thang bot bám tiến trình vẫn chưa làm.
