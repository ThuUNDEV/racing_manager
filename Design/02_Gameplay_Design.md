# Racing Manager — Thiết kế Gameplay v0.2

Ngày: 09/11/2026. Trạng thái: thiết kế đề xuất; mọi số liệu là **giá trị khởi đầu cho playtest**, chưa phải cân bằng đã xác nhận.

Tài liệu đi cùng: [UI](01_UI_Design.md). Tên làm việc: **Pitlane Club**.

> **Phạm vi tài liệu:** đây là đặc tả Gameplay của **prototype**. Thiết kế bản chính thức ở [03](03_Release_Overview.md)–[07](07_Technical_Architecture.md).
> **Ghi chú sau prototype:** đo trên bộ mô phỏng cho thấy công thức §6.2 làm Động cơ áp đảo, Khung gầm và Composure gần như vô tác dụng, đồng thời có một lỗi hai xe trùng vị trí khóa nhau làm cuộc đua treo (đã sửa trong mã prototype). Công thức đã hiệu chỉnh nằm ở [04 §2–3](04_Gameplay_Release.md). Mã prototype chưa chuyển sang công thức mới.

Phạm vi tham chiếu: ưu tiên vòng lặp nâng cấp, sưu tầm và đua tự động của game mẫu. Tên, số lượng nội dung, ngưỡng tiến trình và các công thức dưới đây là cấu hình prototype đề xuất để triển khai, chưa phải cơ chế hoặc thông số đã xác minh từ bên trong Race Star. Tính năng bổ sung ngoài vòng lặp tham chiếu cần được tách thành đề xuất để duyệt.

## 1. Tầm nhìn, người chơi và nguyên tắc

Người chơi xây một đội đua từ giải tập sự lên vô địch thông qua các phiên chơi ngắn. Thu nhập idle cung cấp tài nguyên; nâng xe và phát triển tay đua tạo thay đổi có thể quan sát trong cuộc đua tự động.

Ba trụ cột:

1. **Đầu tư có tác dụng rõ:** nâng lốp giúp giữ tốc độ qua cua; nâng cơ sở tăng tiền/giây; giá trị trước/sau luôn có thể kiểm tra.
2. **Lựa chọn đầu tư rõ ràng:** phân bổ tiền giữa hiệu suất thi đấu, phát triển tay đua và tăng thu nhập cơ sở.
3. **Thua vẫn tiến bộ:** vẫn có tiền thưởng và điểm; không có phí đua, năng lượng, mất xe hoặc tụt giải trong MVP.

Mục tiêu phiên: 3–5 phút. Cuộc đua đầu game khoảng 60–90 giây, nhanh hơn khi xe mạnh. Không ép thời gian bằng cách tăng sức mạnh AI giữa chừng.

## 2. Phạm vi sản phẩm

| Thành phần | Prototype | MVP | Sau MVP |
|---|---|---|---|
| Mô phỏng | 1 xe người chơi + 7 AI, 1 track | 3 track, chỉ số xe và tay đua | Thêm class, đặc tính chuyên biệt |
| Xe | 1 xe, 4 bộ phận | Cấp 0–20 mỗi bộ phận | Nhiều xe, cosmetic, gear |
| Tay đua | An | An / Bình / Chi | Tuyển thêm, duplicate nếu thật sự cần |
| Tiến trình | Đua thử | 3 giải, mỗi mùa 5 chặng | Career dài, sự kiện |
| Kinh tế | Tiền và cơ sở | Offline, nhiệm vụ, quà ngày | Ads/IAP theo thiết kế riêng |
| Hạ tầng | Save local | Save version, backup, resume | Backend khi có tính năng online |

MVP không có PvP, bảng xếp hạng online, club, gacha, merge, pit stop, lốp mòn, nhiên liệu, hỏng xe hoặc thời tiết. Các hệ thống này cần vòng thiết kế riêng trước khi bổ sung.

## 3. Vòng lặp và tiến trình phiên chơi

### 3.1. Vòng lặp chính

Thu nhập cơ sở → mua nâng cấp và phát triển tay đua → đua tự động → nhận tiền và điểm → hoàn thành mùa → thăng giải → tiếp tục đầu tư.

### 3.2. Nhịp tiến trình

- **Ngắn hạn:** đủ tiền cho một cấp nâng; cải thiện một vị trí hoặc một thời gian vòng.
- **Trong phiên:** hoàn tất 1–3 chặng; điều chỉnh đầu tư sau khi thấy kết quả.
- **Trung hạn:** kết thúc mùa 5 chặng, đạt ít nhất 36 điểm để thăng giải.
- **Dài hạn MVP:** vô địch 3 giải và phát triển 3 tay đua; tiếp tục bảo vệ danh hiệu ở giải cuối.

Không dùng reset/prestige trong MVP. Không có giới hạn số lần đua.

## 4. Tài nguyên và kinh tế

### 4.1. Khởi tạo tài khoản

| Dữ liệu | Giá trị |
|---|---:|
| Tiền mềm | 1.000 |
| Gem | 100 |
| Tay đua sở hữu | An, cấp huấn luyện 0 |
| Xe | 1 xe, 4 bộ phận cấp 0 |
| Cơ sở | Cấp 0 |
| Giải | Tập sự, mùa 1, chặng 1 |
| Thu nhập | 8 tiền/giây online |

Gem được lưu để chuẩn bị mở rộng, **không có nguồn mua hoặc điểm tiêu trong MVP**. Không đưa gem vào onboarding hay dùng gem để vá cân bằng tiền mềm. Có thể ẩn gem khi triển khai MVP nếu chưa có nhu cầu UX.

### 4.2. Nguồn và điểm tiêu

| Tiền vào | Quy tắc | Tiền ra | Quy tắc |
|---|---|---|---|
| Cơ sở online | Liên tục khi app foreground | Xe | 4 bộ phận, tối đa 20 cấp |
| Thu nhập vắng mặt | 50% rate, tối đa 2 giờ | Tay đua | Huấn luyện, tối đa 20 cấp/người |
| Cuộc đua | Theo vị trí, mọi vị trí đều có | Cơ sở | Tối đa 20 cấp |
| Kết thúc mùa | Có thưởng hoàn tất; thưởng thăng giải riêng | Mở tay đua | Miễn phí theo mốc |
| Nhiệm vụ / quà ngày | Mỗi mốc/ngày nhận một lần | Vào cuộc đua | Miễn phí |

Chỉ có một loại tiền mềm cho toàn MVP. Không thêm mảnh, coupon hoặc tiền sự kiện ở giai đoạn này.

### 4.3. Công thức kinh tế

Ký hiệu `v` là cấp cơ sở 0–20, `d` là chỉ số giải 0–2.

```text
online_rate = 8 × (1 + 0.12 × v) × (1 + 0.20 × d)
venue_next_cost(v) = ceil(150 × 1.20^v), nếu v < 20
car_next_cost(n) = ceil(120 × 1.17^n), nếu n < 20
driver_next_cost(n) = ceil(100 × 1.18^n), nếu n < 20
```

Giá dựa trên cấp **trước khi mua**. Không có mua x10/xMax trong MVP. Nâng từ 0 → 1 lần lượt tốn 150 / 120 / 100.

Tiền được lưu dạng nguyên; phần thu nhập lẻ tích lũy trong `income_remainder`. Mỗi tick cộng `floor(remainder + rate × delta)` và giữ phần thập phân. UI có thể hiển thị rate 8,96/s. Không làm tròn rate thành 9 ở tầng logic.

Ví dụ ở Tập sự: cơ sở 0 cho 8/s; cơ sở 1 cho 8,96/s. Chi 150 để tăng 0,96/s; hoàn vốn khoảng 156,25 giây online. Đây là điểm neo cân bằng để người chơi có thể so sánh với đầu tư thi đấu.

### 4.4. Thưởng cuộc đua và mùa

| Vị trí | Điểm mùa | Tiền cơ bản |
|---|---:|---:|
| 1 | 10 | 120 |
| 2 | 8 | 100 |
| 3 | 6 | 85 |
| 4 | 5 | 70 |
| 5 | 4 | 60 |
| 6 | 3 | 50 |
| 7 | 2 | 40 |
| 8 | 1 | 35 |

Tiền đua nhân `1 + 0.25 × d`, sau đó làm tròn xuống. Không nhân điểm mùa. Thưởng hoàn tất mùa = `floor(150 × (1 + 0.25 × d))`. Thưởng thăng lên giải kế tiếp = 300 tiền thêm, chỉ một lần cho mỗi lần mở giải mới. Hoàn tất mùa ở giải cuối vẫn nhận thưởng hoàn tất, không nhận lại thưởng mở giải.

Ví dụ về nhất một chặng Tập sự: +120 tiền và +10 điểm, cộng riêng thu nhập cơ sở trong thời gian cuộc đua. Không tính tiền đua vào chỉ số tiền/giây.

### 4.5. Offline và nền ứng dụng

```text
elapsed = max(0, now_utc - last_accrual_utc)
eligible = min(elapsed, 7200)
offline_reward = floor(saved_online_rate × 0.50 × eligible)
```

- Dùng rate đã lưu lúc app ra nền; không dùng cấp mới hoặc thưởng giải mới để tính ngược thời gian.
- Dưới 60 giây vẫn cộng thu nhập đúng nhưng không mở panel.
- Lần mở đầu tiên không phát thưởng offline. Khi giờ thiết bị lùi, cộng 0 và cập nhật mốc thời gian khi ghi save thành công.
- Khoảng thời gian foreground chỉ nhận online; khoảng background chỉ nhận offline. Resume đưa mốc accrual về hiện tại trước khi tick foreground, tránh trả trùng.
- MVP không mô phỏng đua khi app background/đóng. Đua đang chạy tạm dừng và tiếp tục từ snapshot sau khi trở lại.
- Local UTC và trần 2 giờ chỉ là cách xử lý prototype; chỉnh giờ thiết bị vẫn có thể khai thác. Thời gian server cần thiết nếu mở kinh tế cạnh tranh online.

Ví dụ: vắng 1 giờ ở rate 8/s nhận 14.400 tiền; vắng 8 giờ nhận tối đa 28.800. So với giá nâng đầu game, đây có thể là nguồn tiến bộ rất lớn. Nếu một lần quay lại mua được quá nhiều cấp, ưu tiên giảm tỷ lệ offline hoặc rate, rồi playtest lại; không thêm nhiều tiền tệ để che vấn đề.

## 5. Xe và tay đua

### 5.1. Xe

| Bộ phận | Chỉ số | Giá trị | Tác dụng |
|---|---|---|---|
| Động cơ | Speed | `40 + 2 × level` | Tốc độ đoạn thẳng |
| Lốp | Handling | `40 + 2 × level` | Giữ tốc độ qua cua |
| Khung gầm | Stability | `40 + 2 × level` | Giảm xác suất lỗi |
| Hộp số | Acceleration | `40 + 2 × level` | Thời gian tăng tốc đầu đua và sau lỗi |

Mọi bộ phận tối đa cấp 20 → chỉ số 80. Dùng 4 bộ phận để giữ mỗi quyết định dễ hiểu; không có trang bị ẩn làm thay đổi chỉ số.

### 5.2. Tay đua

Mỗi người có một cấp huấn luyện `n` 0–20. Mỗi cấp cộng 1 cho cả Pace, Technique, Composure; giữ nguyên khác biệt về chuyên môn ban đầu.

| Tay đua | Pace | Technique | Composure | Điều kiện |
|---|---:|---:|---:|---|
| An — toàn diện | 40 | 40 | 40 | Có sẵn |
| Bình — tốc độ | 50 | 34 | 36 | Hoàn tất mùa đầu, nhận miễn phí |
| Chi — kỹ thuật | 34 | 50 | 42 | Mở giải Chuyên nghiệp, nhận miễn phí |

Pace ảnh hưởng đoạn thẳng; Technique ảnh hưởng cua và vượt xe; Composure giảm lỗi. Tay đua giữ cấp huấn luyện riêng khi đổi người. Không mất tiến trình, không tiêu tiền để đổi, không có gacha trong MVP.

## 6. Cuộc đua và mô phỏng

### 6.1. Hợp đồng cuộc đua

- 8 xe, gồm 1 xe người chơi và 7 AI; mỗi xe 1 tay đua.
- 3 vòng, mỗi vòng dài 400 đơn vị quy ước. Đường đua có các sector thẳng/cua và vùng được vượt.
- Grid đầu đua do seed xáo trộn; cách nhau 3 đơn vị; tất cả xe có cùng 1.200 đơn vị phải hoàn tất từ vị trí xuất phát riêng. Xe sau không phải chạy thêm do offset grid.
- Mô phỏng logic fixed tick 10 Hz; render nội suy theo frame. Kết quả dựa trên tiến trình và thời gian vượt mốc, không dựa thứ tự node vẽ.
- Cuộc đua chạy tự động theo chỉ số xe và tay đua; người chơi không chọn chế độ lái hay điều khiển lái, ga, phanh hoặc pit stop.
- Chỉ một cuộc đua tồn tại tại một thời điểm. Không có chạy lại riêng một chặng; kết quả chặng được chốt, mùa tiếp tục.

### 6.2. Công thức tốc độ và lỗi

Ký hiệu `S/H/B/A` là Speed/Handling/Stability/Acceleration; `P/T/C` là Pace/Technique/Composure. Các công thức áp dụng như nhau cho người chơi và AI.

```text
straight_speed = 16 + 0.07 × S + 0.03 × P
corner_factor = clamp(0.70 + 0.003 × H + 0.002 × T, 0.70, 1.08)
target_speed = straight_speed × (corner_factor nếu sector cua, ngược lại 1)
target_speed *= race_form
acceleration = 3 + 0.05 × A
actual_speed tiến về target_speed với giới hạn acceleration × dt

p_error = clamp(0.10 - 0.0006 × B - 0.0004 × C, 0.005, 0.15)
```

- `race_form` được lấy đúng một lần mỗi xe trước xuất phát, phân phối đều 0,985–1,015, giữ nguyên cả race.
- Kiểm tra lỗi một lần tại cuối mỗi sector cua, không kiểm tra mỗi frame. Lỗi làm tốc độ mục tiêu còn 50% trong 1 giây; sau đó tăng tốc lại theo Acceleration.
- Mỗi xe tối đa 1 lỗi trong mỗi vòng. Lưu cờ vòng đã lỗi để chặn kiểm tra lỗi tiếp theo trong vòng đó.
- Không xảy ra DNF/hỏng xe trong MVP. Nếu hai xe về đích cùng tick, nội suy thời gian vượt mốc; nếu vẫn bằng nhau dùng thứ tự seed ổn định.
- Không có thay đổi sức mạnh đối thủ theo vị trí người chơi hoặc để bảo đảm một trận thắng/thua.

Ví dụ xe khởi đầu và An: straight_speed = 20 đơn vị/s; corner_factor = 0,90; p_error = 6% **mỗi lần kiểm tra đủ điều kiện**, không phải 6%/giây. Mức tác động thực tế phụ thuộc số sector cua của track.

### 6.3. Bám xe và vượt

Mỗi track đánh dấu vùng vượt. Quy tắc thực thi MVP:

1. Tìm xe gần nhất phía trước trên vòng tròn, kể cả xe đang bị bắt vòng. Loại xe đã về đích khỏi xét bám.
2. Ngoài vùng vượt, nếu khoảng cách <4 đơn vị, tốc độ xe sau không vượt tốc độ xe trước; giải quyết từ trước ra sau để không xuyên xe.
3. Trong vùng vượt và gap <4, mỗi giây thực hiện tối đa một lần kiểm tra; chỉ xét khi tốc độ tự do của xe sau cao hơn xe trước ít nhất 0,2.
4. `p_overtake = clamp(0.50 + 0.005 × (T_attacker - T_defender), 0.25, 0.75)`.
5. Thành công: cho phép vượt xe mục tiêu trong 1,5 giây, hiển thị lệch làn rồi nhập lại. Một xe chỉ là mục tiêu của một lượt vượt tại cùng thời điểm; xử lý ứng viên theo thứ tự tiến trình giảm dần.
6. Thất bại: tiếp tục bám; có thể thử lại ở giây đủ điều kiện tiếp theo. Sau khi vượt xong mới xét mục tiêu mới.

Thứ hạng dựa tổng quãng đường từ xuất phát, không dùng vị trí trên spline vì xe dẫn đầu có thể đang gần xe bị bắt vòng. Xe người chơi luôn nhận diện bằng số 01 và nhãn Bạn.

### 6.4. Seed và dữ liệu giải thích kết quả

Seed gắn với `race_id`, tạo và lưu trước khi mô phỏng. Lưu RNG state, thời gian mô phỏng, từng xe, sector, tốc độ, lỗi và trạng thái vượt khi checkpoint. Resume không reroll race_form hay đối thủ.

Log tối thiểu: thời gian vòng, thời gian về đích, số lần lỗi, giây bị phạt lỗi, giây bị bám xe và số lần vượt thành công. UI dùng các số này để giải thích kết quả. Công cụ debug có thể chạy cùng seed trước/sau nâng cấp để kiểm tra tác động; không đưa chỉ báo debug vào sản phẩm.

## 7. Track, AI và giải đấu

### 7.1. Ba track

Tỷ lệ thẳng/cua là tỷ lệ **chiều dài**, không phải số node spline. Sector phải cộng đúng 400 đơn vị mỗi vòng.

| Track | Thẳng / cua | Sector cua/vòng | Vùng vượt | Đặc điểm |
|---|---|---:|---|---|
| Harbor Oval | 75% / 25% | 2 | Hai đoạn thẳng | Động cơ và Pace có ảnh hưởng rõ |
| Pine Circuit | 50% / 50% | 4 | Hai đoạn thẳng dài | Cần đầu tư cân bằng |
| City Technical | 30% / 70% | 6 | Một đoạn thẳng | Handling và Technique quan trọng hơn |

Lịch 5 chặng: Harbor → Pine → Harbor → City → Pine. MVP dùng lịch cố định để dễ kiểm chứng; không random track theo mỗi lần mở app.

### 7.2. Đối thủ

AI mỗi giải có base stats sau:

| Giải d | S/H/B/A của xe | P/T/C tay đua | Nội dung mở |
|---|---:|---:|---|
| Tập sự 0 | 40 | 40 | Có sẵn |
| Bán chuyên 1 | 48 | 43 | Đạt ít nhất 36 điểm ở Tập sự |
| Chuyên nghiệp 2 | 58 | 47 | Đạt ít nhất 36 điểm ở Bán chuyên |

7 AI có offset lần lượt `-4, -3, -2, 0, +2, +3, +4` cộng vào cả stats xe và tay đua. AI dùng cùng quy tắc mô phỏng tự động như xe người chơi. AI đã được tạo giữ nguyên trong race, không scale theo build người chơi.

Đây là mốc khởi đầu; phải đo phân phối vị trí để chỉnh. Không quảng bá tỷ lệ thắng khi chưa mô phỏng/playtest.

### 7.3. Chốt mùa

Mùa gồm đúng 5 kết quả; điểm 5–50. Đạt >=36 điểm ở hai giải đầu mở giải kế tiếp; dưới mốc giữ giải hiện tại. Không tụt hạng. Kết thúc Chuyên nghiệp >=36 ghi danh hiệu vô địch, vẫn chơi lại cùng giải.

Sau chặng 5: ghi kết quả, thưởng chặng, thưởng hoàn tất và thưởng mở giải nếu đủ điều kiện theo một giao dịch save. Màn tổng kết giữ lại cho tới khi bấm Bắt đầu mùa mới; khi đó đặt điểm/chặng mới, cập nhật rate theo giải mới và bắt đầu mùa. Thu nhập trước thời điểm này dùng rate giải cũ; không hồi tố.

## 8. Nhiệm vụ và phần thưởng phụ

| Mốc | Điều kiện | Thưởng |
|---|---|---:|
| Cuộc đua đầu tiên | Hoàn tất 1 race bất kể vị trí | 150 tiền |
| Đội đang phát triển | Mua tổng 3 cấp xe/tay đua/cơ sở | 200 tiền |
| Mùa đầu tiên | Hoàn tất 5 chặng | 300 tiền + mở Bình |
| Quà ngày | Nhận tối đa 1 lần/ngày UTC | 200 tiền |

Nhiệm vụ là thành tích một lần, không đặt lại khi sang mùa. Điều kiện và trạng thái đã nhận lưu riêng. Mở Chi tự động cùng giao dịch mở Chuyên nghiệp, không phụ thuộc việc nhận thưởng nhiệm vụ mùa đầu.

## 9. State machine, save và giao dịch

```text
Boot → Load → SettleOffline → Ready
Ready → Racing → RaceResolved
RaceResolved → Ready, nếu chưa đủ 5 chặng
RaceResolved → SeasonSummary, nếu đủ 5 chặng
SeasonSummary → Ready của mùa mới, khi người chơi xác nhận
Racing → Suspended → SettleOffline → Racing, khi background/resume
```

- Ready: đổi tay đua và mọi nâng cấp.
- Racing/Suspended: khóa thay đổi thi đấu; chỉ nâng Cơ sở khi foreground. Snapshot race không thay đổi vì giao dịch kinh tế.
- RaceResolved/SeasonSummary: không bắt đầu race mới; thưởng đã chốt, UI chỉ trình bày. Chỉ mua nâng cấp sau khi đóng panel kết quả về Ready.
- Người chơi đổi tab khi race chạy không đổi game state.

Save tối thiểu:

```text
schema_version, save_revision
wallet: coins, income_remainder, gems
car: engine_level, tyre_level, chassis_level, gearbox_level
venue_level, drivers_owned, driver_training_levels, active_driver_id
league_id, pending_league_id, season_number, stage_index, season_results
game_state
active_race: race_id, seed, rng_state, simulation_snapshot
last_result, processed_reward_ids, pending_reward_panel
mission_progress, mission_claimed, last_daily_claim_utc
last_accrual_utc, saved_online_rate
tutorial_step, settings
```

Yêu cầu giao dịch:

- Mua nâng cấp kiểm tra đủ tiền và chưa tối đa; trừ tiền và tăng cấp trong cùng giao dịch. Bấm nhanh không gây âm tiền.
- Reward dùng ID duy nhất, ví dụ `race_id/base`, `season_id/completion`, `unlock/league_1`, `offline/save_revision`; đã xử lý thì không phát lại.
- Offline cập nhật tiền và mốc thời gian trong cùng lần ghi; restart ở panel không nhận lần hai.
- Ghi file tạm, xác thực rồi thay thế save chính; giữ một backup hợp lệ. Save hỏng không tự ghi đè trắng.
- Checkpoint race mỗi 5 giây, khi pause/background và trước/sau kết quả; checkpoint thưởng và giao dịch quan trọng ngay. Crash có thể mất tối đa 5 giây mô phỏng, không lặp thưởng đã ghi.
- Sau crash foreground, khoảng từ checkpoint tới mở lại được coi là offline theo last_accrual_utc. UI không hứa hẹn tiến trình giải đã chạy trong lúc app đóng.

## 10. Kiếm tiền sau MVP

MVP cần vui khi chưa có quảng cáo/mua hàng. Khi triển khai thương mại:

- Rewarded ad sau đua chỉ cộng thêm lượng tiền bằng thưởng chặng cơ bản, tối đa một lần/race; không nhân điểm hoặc tự thăng hạng.
- Chỉ phát phần cộng thêm sau callback thành công; dùng transaction/ad reward ID để chống nhận trùng. Hủy/lỗi quảng cáo giữ nguyên thưởng cơ bản.
- Gói No Ads phải xác định rõ: nếu bỏ nhu cầu xem rewarded ad thì nút đổi thành nhận thưởng tương đương. Không dùng từ “No Ads” khi vẫn yêu cầu xem cùng loại quảng cáo.
- Cosmetic có thể bán mà không làm thay đổi kết quả. Gói tài nguyên và pass cần vòng cân bằng riêng; chưa có giá hoặc rate đề xuất chính thức.
- ~~Không ép quảng cáo giữa các chặng~~ **(đổi 12/11/2026, xem [26](26_Ads_Placements.md) §7):** có Ads Break xen giữa hai lượt, thưa và có đền bù, không bao giờ trong lúc đua. Vẫn không tự bật offer khi người chơi thua.

## 11. Nội dung phát triển và thứ tự triển khai

1. **Vertical slice:** một track, tám xe, công thức tốc độ/lỗi, kết quả lặp lại theo seed. Chưa cần shop.
2. **Core idle:** tiền, bốn nâng cấp, cơ sở, khóa giao dịch trong race và offline.
3. **Tiến trình:** 3 track, 5 chặng/mùa, 3 giải, 3 tay đua, nhiệm vụ và onboarding.
4. **Hoàn thiện:** save/resume/backup, ngôn ngữ, âm thanh và playtest trên điện thoại.
5. **Thương mại:** SDK và offer sau khi vòng lặp cơ bản đạt mục tiêu playtest.

Gợi ý chia trách nhiệm Godot: RaceSimulation (logic không phụ thuộc UI), TrackDefinition, DriverDefinition, EconomyService, ProgressionService, SaveService, các màn UI. Dùng Resource/JSON cho cấu hình; không rải các hệ số cân bằng trực tiếp trong scene. Đây là định hướng triển khai, chưa có code game.

## 12. Kiểm chứng và tiêu chí hoàn thành

### 12.1. Kiểm tra chức năng khi triển khai

- Cùng seed + stats cho cùng kết quả, không phụ thuộc FPS render.
- Nâng đúng một bộ phận làm thay đổi đúng chỉ số/công thức; không tăng sức mạnh AI.
- Xe hoàn tất 3 vòng được xếp hạng theo thời gian, không lỗi khi bắt vòng hoặc vượt cùng tick.
- Tiền online/offline không trả trùng, phần lẻ không mất, trần offline đúng; giờ lùi không gây tiền âm.
- Đúng 5 chặng mới chốt mùa; điểm 35 ở lại, 36 thăng; không nhận lại thưởng mở giải.
- Đóng app ở Ready/Racing/Result/SeasonSummary/OfflinePanel phục hồi đúng; không đổi seed hay lặp thưởng.
- Nâng cấp tối đa không còn giao dịch; không nhận quà ngày/nhiệm vụ hai lần.

### 12.2. Mục tiêu playtest, không phải kết quả đã có

- Hoàn tất hướng dẫn trong 3 phút; người chơi hiểu khác biệt tiền/giây và tiền đua.
- Thắng/thua có dấu hiệu giải thích bằng thời gian vòng, lỗi hoặc bám xe; tránh thông số chỉ tăng trên UI.
- Trên nhiều seed và mỗi track, thử 3 build bằng cùng ngân sách: động cơ, handling, cân bằng. Cần thấy lợi thế theo track, không yêu cầu mọi build ngang nhau.
- So sánh kết quả trước/sau nâng cấp trên ít nhất 100 seed/build/track trong công cụ mô phỏng; kiểm tra tác động thực tế của từng chỉ số trước khi thêm nội dung.
- Thử tài khoản mới sau 15 phút active, 1 giờ và 8 giờ vắng mặt; kiểm tra offline không làm vượt phần lớn nội dung trong một lần nhận.
- Đo thời gian tới nâng cấp đầu, mùa đầu, lần thăng giải đầu; chưa đặt cam kết retention hoặc doanh thu khi chưa có dữ liệu.

### 12.3. Các quyết định cần duyệt ở v0.2

Đề xuất hiện tại đã có giá trị mặc định để làm prototype: mobile dọc, 2D top-down, một xe, 8 người đua tự động, ba track, ba giải, offline 50%/2h, không backend. Các hằng số và hướng nghệ thuật có thể đổi sau khi duyệt mockup và kiểm chứng vòng lặp; không cần chờ quyết định về PvP/gacha để triển khai vertical slice.
