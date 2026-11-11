# Racing Manager — Thiết kế v1.0: Gameplay và nội dung

> **Cập nhật nhịp đua 09/11/2026:** [10 — Đua liên tục theo thời gian](10_Continuous_Race_Loop.md) thay các quy tắc bấm bắt đầu, 3 vòng kết thúc, thời gian 60–90 giây phụ thuộc xe, khóa nâng cấp giữa race và chờ đóng kết quả/chuyển mùa trong tài liệu này. Thiết kế mới: tự nối lượt, countdown 3 giây, hết thời lượng cấu hình thì chốt hạng theo tiến trình; chưa triển khai vào gameplay. Số liệu lab bên dưới thuộc mô hình cũ.

Ngày: 09/11/2026. Trạng thái: đề xuất để duyệt. Thay thế [02 Gameplay v0.2](02_Gameplay_Design.md) cho bản phát hành; những gì không nhắc lại ở đây giữ nguyên v0.2 (khởi tạo tài khoản, state machine, save tối thiểu, thưởng theo vị trí). Đi cùng [03](03_Release_Overview.md), [05](05_Economy_Monetization.md).

Số liệu ở §2–3 đến từ **bộ mô phỏng thử nghiệm** (`tests/lab/`), 80 seed mỗi điểm đo, chưa phải playtest người thật.

## 1. Vòng lặp và nguyên tắc

Thu nhập cơ sở → nâng xe/tay đua/cơ sở → đua tự động → tiền, điểm mùa, điểm tuyển → hoàn tất mùa → thăng giải, mua xe mới → tiếp tục đầu tư. Song song: bộ sưu tầm xe, tuyển tay đua, nhiệm vụ ngày, Thử thách ngày.

Giữ các nguyên tắc v0.2: thua vẫn tiến bộ (không phí đua, năng lượng, mất xe, tụt giải); người chơi không điều khiển lái; AI không điều chỉnh theo người chơi; chỉ một cuộc đua tại một thời điểm; kết quả chặng được chốt.

## 2. Mô phỏng đua v1.0

### 2.1. Thay đổi so với v0.2

Prototype cho thấy công thức v0.2 không cân bằng (Động cơ áp đảo, Khung gầm và Composure gần như vô tác dụng) và có một lỗi treo cuộc đua. Bản v1.0 đổi như sau:

| Vấn đề ở v0.2 (đo được) | Sửa ở v1.0 |
|---|---|
| Tốc độ cua nhân theo tốc độ thẳng, nên Động cơ lợi ở mọi track | Tốc độ cua **độc lập** với Động cơ; Động cơ chỉ ảnh hưởng đoạn thẳng, Lốp chỉ ảnh hưởng cua |
| Khung gầm/Composure giảm 0,1 giây/race ở +40 chỉ số | Xác suất lỗi cao hơn nhiều, lỗi tốn hơn (còn 35% tốc độ trong 1,5 giây) |
| Hộp số chỉ giảm 0,4 giây | Gia tốc thấp hơn và dốc hơn; phanh cố định nhanh, nên Hộp số quyết định tốc độ ra cua |
| Hai xe trùng vị trí khóa nhau, cuộc đua treo (đã sửa trong prototype) | Quy tắc trùng vị trí + chốt an toàn "đứng yên > 2 giây thì bỏ cản" |
| "Giây mất do bám xe" đo thiếu | Đo bằng chênh lệch so với tốc độ nếu không bị cản |
| Quy tắc vượt không nói xe di chuyển thế nào khi thành công | Vượt thành công cho xe tấn công cộng thêm tốc độ trong 1,5 giây để vượt đúng 1 đơn vị, không bị cản bởi mục tiêu |

### 2.2. Công thức

Mọi chỉ số tính theo **độ lệch so với mức nền của giải** (`Δ = chỉ số − nền giải`): xe so với nền xe của giải, tay đua so với nền tay đua của giải (§4). Nhờ vậy mọi giải dùng chung công thức; ở giải 0 (nền 40) công thức giống v0.2 khi chỉ số = 40.

```text
ΔS,ΔH,ΔB,ΔA = chỉ số xe − nền_xe(giải)       ΔP,ΔT,ΔC = chỉ số tay đua − nền_tay_đua(giải)

straight_speed = 20 + 0.05×ΔS + 0.04×ΔP
corner_speed   = min(straight_speed, 18 + 0.045×ΔH + 0.04×ΔT)
target_speed   = (straight_speed hoặc corner_speed) × race_form × (0,35 nếu đang lỗi)
acceleration   = max(1.5, 3.8 + 0.07×ΔA)     # tăng tốc
braking        = 14                           # giảm tốc, cố định
p_error        = clamp(0.35 − 0.0075×ΔB − 0.005×ΔC, 0.01, 0.60)   # mỗi lần kiểm tra
```

- `race_form`: lấy một lần mỗi xe trước xuất phát, đều trong 0,985–1,015, giữ cả race.
- **Lỗi:** kiểm tra một lần tại cuối **mỗi sector cua**; tối đa một lỗi mỗi vòng (lưu cờ vòng). Lỗi giữ tốc độ mục tiêu ở 35% trong **1,5 giây**, sau đó tăng tốc lại theo `acceleration`. Xác suất 35% là **mỗi lần kiểm tra**, không phải mỗi giây; track nhiều cua có nhiều lần kiểm tra nên xác suất có lỗi trong một vòng cao hơn p (Harbor: 2 lần/vòng; City: 6 lần/vòng).
- Các quy tắc còn lại của v0.2 giữ nguyên: 8 xe, 3 vòng × 400 đơn vị, fixed tick 10 Hz, grid xáo bằng seed cách 3 đơn vị và mọi xe chạy đủ 1.200 đơn vị, không DNF, bám xe khi gap < 4, vượt tối đa một lần kiểm tra/giây trong vùng vượt khi nhanh hơn ≥ 0,2, `p_overtake = clamp(0.5 + 0.005×(T_tấn công − T_phòng thủ), 0.25, 0.75)`.

### 2.3. Quy tắc bổ sung

1. **Trùng vị trí:** hai xe cùng quãng đường → xe `id` nhỏ hơn được coi là ở phía trước; không xe nào bị khóa chéo.
2. **Chốt an toàn:** một xe đứng yên liên tục quá 2 giây thì bỏ qua cản trong lượt đó. Race vượt 1.200 giây bị chốt cưỡng bức và ghi sự kiện (coi là lỗi, không kỳ vọng xảy ra).
3. **Vượt thành công:** xe tấn công nhận thêm tốc độ `(gap + 1) / 1,5` trong 1,5 giây, bỏ cản của xe mục tiêu; một xe chỉ là mục tiêu của một lượt vượt cùng lúc; xử lý ứng viên theo thứ tự tiến trình giảm dần.
4. **Đo thời gian mất do bám xe:** `Σ max(0, tốc_độ_nếu_không_cản − tốc_độ_thực) × dt / tốc_độ_mục_tiêu`.
5. Mỗi cuộc đua lưu log: thời gian vòng, số lỗi, giây mất do lỗi, giây mất do bám xe, vượt thành công, đặc tính tay đua đã kích hoạt.

### 2.4. Đặc tính tay đua (chỉ người chơi)

Mỗi tay đua (trừ An) có một đặc tính nhỏ, đều có móc rõ ràng trong mô phỏng. AI không dùng đặc tính (chỉ dùng chỉ số) để bảng cân bằng AI đơn giản. Mỗi đặc tính phải được lab xác nhận tác động ≤ ~1 giây/race trước khi chốt.

| Tay đua | Đặc tính | Hiệu ứng |
|---|---|---|
| Bình | Xuất phát nhanh | Gia tốc ×1,25 trong 10 giây đầu |
| Chi | Cua mượt | Tốc độ cua +1,5% |
| Dũng | Điềm tĩnh | Thời gian lỗi ×0,7 (1,05 giây) |
| Hà | Nước rút | Vòng cuối +1% tốc độ |
| Khôi | Săn đuổi | +5 điểm phần trăm xác suất vượt |
| Lâm | Phòng thủ | Xe tấn công vượt Lâm −5 điểm phần trăm |
| My | Đoạn thẳng | Tốc độ thẳng +1,5% |
| Nhân | Ổn định | `p_error` ×0,85 |
| Phương | Phục hồi | Sau lỗi, gia tốc ×1,3 trong 3 giây |
| Quang | Nhịp vàng | `race_form` thu hẹp 0,995–1,015 |
| Sơn | Kỷ luật | Không kiểm tra lỗi ở vòng 1 |

## 3. Cân bằng chỉ số

### 3.1. Tiêu chí

1. Mỗi chỉ số xe ở +40 phải tiết kiệm **≥ 1,5 giây** trên mọi track (đạt: thấp nhất là Lốp ở Desert Highway 1,6 giây) và có **một track** nơi nó là chỉ số mạnh nhất hoặc nhì (để lựa chọn đầu tư theo track có ý nghĩa).
2. Động cơ phải dẫn đầu ở track nhiều đoạn thẳng, Lốp ở track nhiều cua; không chỉ số nào áp đảo mọi track.
3. Thời lượng cuộc đua đầu mỗi giải 60–90 giây.
4. Không race nào treo hay phải chốt cưỡng bức (kiểm thử 600+ race ngẫu nhiên).
5. Từ Δxe ≥ +8 gần như chắc thăng hạng; ở Δxe 0 gần như không (xem §3.3).

### 3.2. Kết quả lab (bộ tham số D, thay đổi một chỉ số từ nền sang +40)

Giây tiết kiệm trên một race (trung bình 80 seed); cuối dòng là thời gian race ở chỉ số nền.

| Track | Động cơ S | Lốp H | Khung B | Hộp số A | Pace P | Technique T | Composure C | Race nền |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Harbor Oval | 4,8 | 2,7 | 2,5 | 2,4 | 3,9 | 2,3 | 1,3 | 69,3 s |
| Pine Circuit | 3,3 | 3,6 | 2,7 | 3,1 | 2,6 | 3,5 | 1,3 | 72,7 s |
| City Technical | 2,1 | 5,0 | 3,0 | 3,5 | 1,8 | 4,3 | 1,2 | 75,0 s |
| Desert Highway | 5,2 | 1,6 | 2,4 | 2,6 | 4,5 | 1,7 | 1,5 | 68,6 s |
| Lakeside | 4,0 | 3,1 | 2,9 | 2,8 | 3,7 | 3,2 | 1,8 | 71,2 s |
| Quarry Loop | 4,0 | 3,3 | 3,3 | 3,3 | 3,4 | 3,1 | 1,9 | 72,5 s |
| Mountain Pass | 2,5 | 4,4 | 2,6 | 3,2 | 2,2 | 4,7 | 2,0 | 73,8 s |
| Old Town | 2,8 | 5,7 | 3,5 | 3,9 | 2,7 | 5,3 | 1,6 | 75,3 s |
| Neon Docks | 3,6 | 3,8 | 3,3 | 3,4 | 3,1 | 3,6 | 1,4 | 72,7 s |
| Grand Speedway | 4,8 | 2,8 | 2,8 | 2,9 | 3,5 | 2,5 | 1,9 | 70,9 s |

Cả 10 track cho race nền 68,6–75,3 giây (đạt tiêu chí 60–90 giây). Động cơ dẫn đầu ở Harbor, Desert, Grand Speedway, Quarry và Lakeside; Lốp dẫn đầu ở City, Mountain, Old Town, Pine, Neon Docks (sát Động cơ). Hộp số và Khung gầm cho 2,4–3,9 giây ở mọi track, nên không còn là bộ phận "chết" như ở v0.2 (0,1–0,4 giây).

Lưu ý khi đọc: chỉ số tay đua thực tế chỉ tăng tối đa +20 (huấn luyện) nên tác động thực của P/T/C khoảng một nửa cột này. Composure có tác động nhỏ nhất (1,2–1,3 giây ở +40); đây là chủ ý vì nó là chỉ số phụ, nhưng cần xem lại sau playtest nếu người chơi bỏ qua hoàn toàn.

### 3.3. Ngưỡng thăng hạng (giải 0, Δtay đua = Δxe/2)

| Δxe so với nền giải | Điểm mùa trung bình | Tỉ lệ đạt ≥ 36 điểm |
|---:|---:|---:|
| −14 | 5,7 | 0% |
| −8 | 8,8 | 0% |
| 0 | 24,1 | 0% |
| +4 | 34,8 | 38% |
| +8 | 43,4 | 98% |
| +12 | 46,6 | 100% |

Đường cong dốc: hai cấp nâng đều bốn bộ phận (Δ +4) thay đổi từ "không thăng được" sang "38%". Điều này giúp người chơi thấy tiến bộ rõ nhưng cũng có nghĩa đối thủ nền phải được đặt cẩn thận (§4); AI chỉ lệch nhau ±4 nên trường đua khá hẹp. Cân nhắc nới độ lệch AI ở giải cao nếu playtest thấy hạng thay đổi quá đột ngột.

### 3.4. Việc còn lại

- Chạy lab trên **cả 6 giải** (mô phỏng đối thủ nền giải cao) và với đặc tính tay đua bật.
- Đo tác động tổ hợp (2–3 chỉ số cùng nâng), không chỉ từng chỉ số riêng.
- Đo phân phối vị trí theo ngân sách tiền cố định (3 build: Động cơ, Handling, cân bằng) ở từng track.

## 4. Giải đấu và track

### 4.1. Sáu giải

Mùa gồm đúng 5 chặng, đạt ≥ 36 điểm (trong 5–50) thì mở giải kế tiếp; dưới mốc ở lại, không tụt hạng. Nền AI áp dụng offset `-4, -3, -2, 0, +2, +3, +4` cho 7 AI, như v0.2.

| L | Giải | Nền xe AI | Nền tay đua AI | Xe tối thiểu để vào | Màu chủ đạo |
|---:|---|---:|---:|---|---|
| 0 | Tập sự | 40 | 40 | Hạng 1 | Xanh lá |
| 1 | Bán chuyên | 52 | 44 | Hạng 1 | Xanh dương |
| 2 | Chuyên nghiệp | 68 | 50 | Hạng 2 | Tím |
| 3 | Quốc gia | 86 | 56 | Hạng 3 | Cam |
| 4 | Châu lục | 106 | 62 | Hạng 4 | Đỏ |
| 5 | Thế giới | 128 | 68 | Hạng 5 | Vàng |

Nền xe AI = nền hạng xe tương ứng + 12 (nền xe người chơi ở cấp 6 bằng nền AI), trừ giải 0 dùng đúng nền hạng 1. Xe người chơi không đủ hạng bị khóa kèm lý do, không bị chặn ngầm.

Sau giải cuối (Thế giới) hiển thị "Bảo vệ danh hiệu": chơi lại mùa với cùng độ khó, thưởng hoàn tất mùa vẫn có; không tăng chỉ số giải vô hạn. Prestige xem ở 1.2 (D3).

### 4.2. Mười track

Tỉ lệ thẳng/cua là tỉ lệ chiều dài, cộng đúng 400 đơn vị mỗi vòng. Vùng vượt là các đoạn thẳng. Cột "quan trọng" lấy từ lab §3.2 (hai bộ phận xe tiết kiệm nhiều giây nhất) và quyết định hai ô nâng cấp nhanh ở màn Đua (06 §4).

| # | Track | Thẳng/Cua | Sector (S = thẳng, C = cua, độ dài) | Hai bộ phận xe quan trọng nhất (lab) |
|---:|---|---|---|---|
| 1 | Harbor Oval | 75/25 | S150 C50 S150 C50 | Động cơ, Lốp |
| 2 | Pine Circuit | 50/50 | S100 C50 C50 S100 C50 C50 | Lốp, Động cơ |
| 3 | City Technical | 30/70 | S120 C40 C50 C50 C50 C40 C50 | Lốp, Hộp số |
| 4 | Desert Highway | 85/15 | S170 C30 S170 C30 | Động cơ, Hộp số |
| 5 | Lakeside | 65/35 | S130 C50 S130 C40 C50 | Động cơ, Lốp |
| 6 | Quarry Loop | 60/40 | S120 C40 C40 S120 C40 C40 | Động cơ, Lốp (sát Khung/Hộp số) |
| 7 | Mountain Pass | 40/60 | S80 C60 C60 S80 C60 C60 | Lốp, Hộp số |
| 8 | Old Town | 35/65 | S70 C45 C45 C45 S70 C45 C45 C35 | Lốp, Hộp số |
| 9 | Neon Docks | 55/45 | S110 C45 C45 S110 C45 C45 | Lốp, Hộp số (cân bằng) |
| 10 | Grand Speedway | 70/30 | S140 C40 C40 S140 C40 | Động cơ, Hộp số |
| (thử nghiệm) | Circuit A ([08](08_Race_Traffic_Revision.md) §3) | 40/60 | S34 C70 S67 C31 C38 C36 C64 S60, đường rộng 3,5–4 bề ngang xe | Lốp, Động cơ (lab sơ bộ) |

Mỗi track có nền và centerline riêng khớp với định nghĩa sector (06 §5), thông tin chặng (UI-08) và **kỷ lục cá nhân** (thời gian đua nhanh nhất của người chơi).

### 4.3. Lịch 5 chặng mỗi giải (cố định, không ngẫu nhiên)

| Giải | Chặng 1 | Chặng 2 | Chặng 3 | Chặng 4 | Chặng 5 |
|---|---|---|---|---|---|
| 0 Tập sự | Harbor | Pine | Harbor | City | Pine |
| 1 Bán chuyên | Lakeside | Quarry | Harbor | Old Town | Neon Docks |
| 2 Chuyên nghiệp | Pine | Desert | City | Mountain | Lakeside |
| 3 Quốc gia | Quarry | Neon Docks | Old Town | Grand Speedway | Mountain |
| 4 Châu lục | Desert | City | Lakeside | Quarry | Grand Speedway |
| 5 Thế giới | Grand Speedway | Mountain | Old Town | Desert | Neon Docks |

## 5. Xe và bộ sưu tầm

### 5.1. Hạng và biến thể

Năm hạng, mỗi hạng ba xe, tổng 15. Chỉ số bộ phận = `nền_hạng + biến_thể + 2×cấp` (cấp 0–20).

| Hạng | Tên | Nền (cấp 0) | Tối đa (cấp 20) | Mở mua |
|---:|---|---:|---:|---|
| 1 | Pico | 40 | 80 | Xe khởi đầu miễn phí |
| 2 | Nova | 56 | 96 | Giải Chuyên nghiệp |
| 3 | Apex | 74 | 114 | Giải Quốc gia |
| 4 | Titan | 94 | 134 | Giải Châu lục |
| 5 | Zenith | 116 | 156 | Giải Thế giới |

Biến thể (cộng vào nền, tổng 0): **Tia chớp** (+6 Speed, −2 mỗi chỉ số còn lại), **Bám đường** (+6 Handling, −2 mỗi chỉ số còn lại), **Bền bỉ** (+3 Stability, +3 Acceleration, −3 Speed, −3 Handling). Hạng 1: Tia chớp là xe khởi đầu; hai biến thể còn lại 2.500 và 5.000 tiền. Giá xe hạng 2–5 ở [05 §3](05_Economy_Monetization.md).

### 5.2. Luật

- Người chơi giữ nhiều xe; mỗi xe có cấp riêng 4 bộ phận. Chọn xe đua khi trạng thái sẵn sàng. Không bán/đổi xe; không mất cấp khi mua xe mới.
- **Hoàn thiện xe** (cả 4 bộ phận cấp 20): +1% thu nhập cho mỗi xe, tối đa +15%, tính vào `legacy` nhân kinh tế.
- Chọn xe yêu cầu hạng tối thiểu theo §4.1; xe thấp hơn bị khóa ở giải đó (không phải một "mất" mà là bộ sưu tầm và Thử thách ngày vẫn dùng được).
- Livery là mỹ phẩm, không đổi chỉ số (05 §7.2).

## 6. Tay đua và tuyển

### 6.1. Danh mục 12 tay đua

Chỉ số cơ sở (Pace/Technique/Composure); mỗi cấp huấn luyện (0–20) cộng +1 cả ba. Tầng quyết định giá huấn luyện và giải mở.

| Tầng | Tay đua | Vai trò | P / T / C | Mở khi |
|---:|---|---|---|---|
| 0 | An | Toàn diện | 40 / 40 / 40 | Có sẵn |
| 0 | Bình | Tốc độ | 50 / 34 / 36 | Hoàn tất mùa đầu |
| 0 | Chi | Kỹ thuật | 34 / 50 / 42 | Mở giải Chuyên nghiệp |
| 1 | Dũng | Điềm tĩnh | 41 / 43 / 53 | Giải Bán chuyên |
| 1 | Hà | Tốc độ | 55 / 39 / 41 | Giải Bán chuyên |
| 1 | Khôi | Kỹ thuật | 39 / 55 / 47 | Giải Bán chuyên |
| 2 | Lâm | Toàn diện | 50 / 50 / 50 | Giải Quốc gia |
| 2 | My | Tốc độ | 60 / 44 / 46 | Giải Quốc gia |
| 2 | Nhân | Kỹ thuật | 44 / 60 / 52 | Giải Quốc gia |
| 3 | Phương | Điềm tĩnh | 51 / 53 / 61 | Giải Châu lục |
| 3 | Quang | Tốc độ | 65 / 49 / 51 | Giải Châu lục |
| 3 | Sơn | Kỹ thuật | 49 / 65 / 51 | Giải Châu lục |

Tay đua giữ cấp huấn luyện riêng khi đổi người; không mất tiến trình, không tốn tiền đổi. Chân dung và tên là nội dung gốc.

### 6.2. Tuyển (thay cho gacha, D1)

- Toàn bộ danh mục công khai; điều kiện mở hiển thị trước.
- Tuyển người đủ điều kiện mở: tốn **điểm tuyển (SP)** theo thứ tự tuyển (`40 + 20×i`) và một khoản tiền theo tầng (`100 × 5^tầng × 6` cho tầng đó, tức 6 lần giá huấn luyện cấp đầu). Không có ngẫu nhiên, không có duplicate.
- Điểm tuyển nhận mỗi chặng: `điểm mùa + 4` (5–14), cộng nhiệm vụ. Học viện tăng SP +2% mỗi cấp.
- Khi đã tuyển, huấn luyện tốn `driver_next_cost(tầng, n)` ở 05 §3.

## 7. Cơ sở

| Cơ sở | Phạm vi | Hiệu ứng | Cấp |
|---|---|---|---:|
| **Trụ sở** | Riêng từng giải | +12% thu nhập mỗi cấp (cộng dồn tuyến tính) | 0–20 |
| **Xưởng** | Toàn cục | −1,5% giá nâng xe mỗi cấp (tối đa −30%) | 0–20 |
| **Học viện** | Toàn cục | −1,5% giá huấn luyện và +2% SP mỗi cấp | 0–20 |

Trụ sở của giải đã qua giữ cấp và đóng góp `legacy` (+1% mỗi cấp, tối đa +30%). Công thức giá ở 05 §3. Khi đang đua chỉ mua được cơ sở (không đổi chỉ số thi đấu).

## 8. Nội dung ngày

- **Quà ngày:** 200 tiền (nhân hệ số giải hiện tại 3^L, tối thiểu 200), reset 00:00 UTC; không cần mạng.
- **Nhiệm vụ ngày:** 3 nhiệm vụ cố định theo giải (ví dụ đua 3 chặng, mua 5 cấp nâng, vượt 4 lần), thưởng tiền và SP; reset UTC; có thể làm mới 1 nhiệm vụ bằng 10 gem.
- **Thử thách ngày:** một cuộc đua đặc biệt, seed và track theo ngày UTC, dùng xe chuẩn do game cấp (không dùng xe người chơi) hoặc xe người chơi giới hạn tại hạng nhất định; mọi người cùng điều kiện. Điểm xếp hạng theo thời gian về đích; bảng xếp hạng bạn bè/toàn cầu qua dịch vụ nền tảng. Thưởng gem 5–20 theo hạng. 1 lượt miễn phí, 1 lượt thêm qua quảng cáo thưởng (05 §7.1). Có thể chơi offline và gửi điểm khi có mạng.

## 9. Thành tích và sưu tầm

- 40 thành tích đề xuất: đua (thắng 1/10/100 chặng), mùa (hoàn tất mùa, đủ 50 điểm), sưu tầm (có đủ 3 xe một hạng, 15 xe, 12 tay đua), kinh tế (tiền tích lũy mốc), thời gian (kỷ lục từng track), Thử thách ngày.
- Thưởng 10–50 gem và danh hiệu hiển thị ở Hồ sơ. Không thành tích nào yêu cầu mua hàng.
- Nhiệm vụ một lần của v0.2 (đua đầu, 3 cấp nâng, mùa đầu) trở thành chuỗi hướng dẫn trong thành tích và giữ nguyên thưởng.

## 10. Máy trạng thái và khóa giao dịch

Giữ máy trạng thái v0.2 (`Boot → Load → SettleOffline → Ready → Racing → RaceResolved → SeasonSummary`, `Suspended`). Thêm:

- `Ready` có thêm đổi xe và tuyển tay đua. Trạng thái khác khóa mọi thay đổi thi đấu. Chỉ mua cơ sở khi `Ready` hoặc `Racing` (foreground).
- Mở giải mới, thưởng mùa, thưởng hoàn tất, điểm tuyển và kỷ lục được ghi **trong cùng một giao dịch save** với kết quả chặng cuối mùa.
- Mọi thưởng dùng ID duy nhất (xem 07 §5.1).
- Thử thách ngày là một cuộc đua riêng (`ChallengeRacing`), không ảnh hưởng mùa; kết quả lưu theo ngày để không nhận thưởng hai lần.

## 11. Kiểm chứng và tiêu chí hoàn thành

### Kiểm tra chức năng
- Cùng seed + cấu hình cho cùng kết quả; không phụ thuộc FPS (golden test, 07 §4).
- Không race nào treo hoặc chốt cưỡng bức trong ≥ 600 race ngẫu nhiên mỗi lần đổi công thức.
- Đúng 5 chặng mới chốt mùa; điểm 35 ở lại, 36 thăng; không nhận lại thưởng mở giải.
- Mua/chọn xe và tay đua đúng điều kiện giải; khóa đúng trạng thái.
- Mọi công thức kinh tế khớp 05 §3 (test bảng giá, rate, thưởng).

### Mục tiêu playtest (không phải kết quả đã có)
- Người chơi hiểu vì sao thắng/thua nhờ lỗi, bám xe, vượt xe; không có cảm giác "con số chỉ tăng trên UI".
- 3 build cùng ngân sách (Động cơ, Handling, cân bằng) cho lợi thế khác nhau theo track.
- Mùa đầu hoàn tất trong 2–3 phiên (≈ 8–10 phút); giải đầu → thứ hai ≈ 10 phút; mỗi mốc thăng giải theo nhịp ở 05 §5.
- Một lần quay lại sau 8 giờ vắng không làm người chơi bỏ qua phần lớn nội dung của giải hiện tại.
