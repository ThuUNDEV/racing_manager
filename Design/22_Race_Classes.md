# 22. Class đua (bộ môn) — đa dạng hóa cuộc đua

Ngày 12/11/2026. Trạng thái: **đã duyệt; P0–P2 đã triển khai 12/11/2026; cơ sở độc lập (doanh thu, giải, nâng cấp riêng): xem [26](26_Independent_Facilities.md)** (dữ liệu `data/classes.json`, mua/đổi class, save v9, modal `ui/class_page.gd`, nút Class trên HUD; test `class_test`, `class_ui_test`). Chưa làm: thang giải/mùa riêng từng class và Advance/Details (P3), số "sức mạnh đề xuất"/"cơ hội thắng" thật (P4), sự kiện riêng, asset riêng (P5). Hiện thẻ class đã mua hiển thị tên đội và giải chung (`business_tier`); mọi class dùng chung track `circuit_b`. Nguồn tham chiếu: 3 ảnh màn hình "Classes" do người dùng cung cấp (modal danh sách thẻ Racing, Rally, Stock Car, Superbike, Speedster, Monster Truck, "More Coming Soon"). Chỉ lấy ý tưởng bố cục và cấu trúc, không chép nội dung.

## 1. Mục tiêu

Hiện mọi lượt đều là cùng một kiểu: xe nhiều bánh chạy `track_circuit_b`, cùng công thức. Class biến "một cuộc đua" thành **nhiều bộ môn có luật chơi và chiến lược nâng cấp khác nhau**, mà không phải xây lại mô phỏng.

- Mỗi class thay đổi **trọng số chỉ số nào quan trọng**, mức rủi ro, hút gió, độ ngẫu nhiên và bối cảnh (đường, kiểu xe hiển thị).
- Cùng một garage (xe, tay đua, trang bị, 8 nâng cấp) dùng cho mọi class, nhưng mỗi class **thưởng một kiểu build khác nhau** → người chơi có lý do đổi xe/tay đua/gear theo class.
- Giữ nguyên nguyên tắc cũ: một cuộc đua tại một thời điểm, thua vẫn tiến bộ, người chơi không điều khiển lái, AI không thích nghi theo người chơi.

## 2. Đặt tên để tránh nhầm

`data/cars.json` đã có trường `class` (1–5: Pico, Nova…) nghĩa là **hạng xe**. Tính năng mới gọi là **Class (bộ môn)**, khóa dữ liệu `race_class` / `class_id`, không dùng lại `class`. Giao diện giữ chữ "Hạng xe" cho 1–5 và "Class" cho bộ môn.

## 3. Sáu class bản đầu

Racing là class hiện tại; mọi tham số của nó = giá trị mặc định nên **kết quả không đổi một bit** so với bản hiện tại (điều kiện bắt buộc của test golden).

| Class | Bản sắc | Chỉ số quan trọng | Rủi ro / ngẫu nhiên | Hút gió | Cơ sở |
|---|---|---|---|---|---|
| Racing | Cân bằng, bản gốc | S H B A đều | chuẩn | chuẩn | Cơ sở đầu, có sẵn |
| Rally | Đường đất, nhiều cua, trơn | Handling, Stability | lỗi nhiều, form lệch lớn | gần như không (bụi) | Chọn tự do |
| Stock Car | Oval dài, đoàn xe sát nhau | Stability, Accel nhẹ | lỗi ít, có cờ vàng | rất mạnh | Chọn tự do |
| Superbike | Hai bánh, bốc và nghiêng | Accel, Handling, Stability | té xe đau hơn, tốn stamina | yếu | Chọn tự do |
| Speedster | Đường thẳng dài, tốc độ tối đa | Speed | ít lỗi, ít ngẫu nhiên | mạnh | Chọn tự do |
| Monster Truck | Vật cản, nhảy, hỗn loạn | Stability, Accel | lỗi rất nhiều, form lệch rất lớn | không | Chọn tự do |

**Người chơi mới chỉ có một cơ sở, dành cho Racing. Muốn chơi class khác phải mở cơ sở mới bằng tiền rồi chọn class cho cơ sở đó** (§5.0).

### 3.1. Tham số mô phỏng (đề xuất ban đầu, lab sẽ chốt)

`TrafficSim.setup()` đã nhận `opts.tuning` và `opts.traffic_tuning` ghi đè `data/sim.json` — **class chỉ cần là một bộ ghi đè**, không sửa công thức. Các hệ số dưới đây là **bội số** của giá trị Racing:

| Class | `straight_per_speed` | `corner_per_handling` | `error_per_stability` | `accel_per_accel` | `error_base` | `form_min/max` | `draft_bonus` |
|---|---|---|---|---|---|---|---|
| Racing | ×1,0 | ×1,0 | ×1,0 | ×1,0 | 0,35 | 0,985–1,015 | 0,03 |
| Rally | ×0,7 | ×1,2 | ×1,4 | ×1,0 | 0,42 | 0,975–1,025 | 0,01 |
| Stock Car | ×1,0 | ×0,7 | ×0,8 | ×0,9 | 0,25 | 0,990–1,010 | 0,06 |
| Superbike | ×0,9 | ×1,3 | ×1,2 | ×1,4 | 0,38 | 0,985–1,015 | 0,02 |
| Speedster | ×1,5 | ×0,6 | ×0,8 | ×1,0 | 0,22 | 0,990–1,010 | 0,045 |
| Monster Truck | ×0,6 | ×0,8 | ×1,5 | ×1,3 | 0,50 | 0,970–1,030 | 0 |

Quy tắc giữ cân bằng: tổng trọng số bốn chỉ số mỗi class xấp xỉ bằng Racing (≈ 4,0), để không class nào "đáng tiền hơn" chỉ vì cộng chỉ số nhiều hơn.

### 3.2. Sự kiện riêng (tùy chọn, làm sau khi lõi ổn)

Mỗi class có thể có **một** sự kiện nhẹ, dùng móc đã có trong `TrafficSim`:

- Stock Car: **cờ vàng** một lần ở 55–70% thời lượng, kéo khoảng cách giữa các xe về `follow_gap` rồi chạy lại. Thêm kịch tính, không đổi tổng chỉ số.
- Rally: mỗi chặng đổi **mặt đường** (đất/sỏi/bùn): đổi `corner_per_handling` ±10% cho cả lượt, hiện trước giờ xuất phát.
- Monster Truck: đoạn **nhảy** là sector đặc biệt, kiểm tra lỗi như cua nhưng thưởng nếu Stability cao.
- Superbike: **launch** ở xuất phát nhân hiệu quả `Launch` của tay đua ×1,5.
- Racing, Speedster: không có sự kiện riêng.

## 4. Xe, tay đua, trang bị trong class

**Xe:** giữ chung 15 xe. Ba biến thể có sẵn đã khớp class tự nhiên, không cần thêm xe:

| Biến thể | Mạnh ở | Hợp class |
|---|---|---|
| Tia chớp (S cao) | Speed | Speedster, Racing |
| Bám đường (H cao) | Handling | Rally, Superbike |
| Bền bỉ (B, A cao) | Stability, Accel | Stock Car, Monster Truck |

Thẻ class hiện nhãn **Xe gợi ý** theo bảng này. Nhờ trọng số §3.1, lợi thế này tự nảy sinh, không cộng thêm hệ số "fit" nhân tạo.

**Hiển thị:** `RaceView` hiện vẽ xe bằng chấm tròn, nên khác biệt xe giữa các class chỉ cần màu viền/biểu tượng class trên HUD, chưa cần sprite xe riêng. Sprite xe theo class (xe công thức, xe rally, stock, xe máy, speedster, monster) cần cho **icon thẻ class** và màn xem sau.

**Tay đua:** bốn phong cách ở Design/16 được thưởng theo class (nhân vào bonus phong cách hiện có):

| Phong cách | ×1,25 ở |
|---|---|
| Late-brake attacker | Racing, Superbike |
| Momentum rider | Rally, Speedster |
| Counterpuncher | Stock Car |
| Tactical defender | Stock Car, Monster Truck |

**Trang bị:** không đổi. Chỉ số gear cộng vào xe như hiện tại; class quyết định chỉ số nào đáng đầu tư.

## 5. Tiến trình theo class

### 5.0. Cơ sở: mở bằng tiền, rồi chọn class

Mỗi class là **một cơ sở thật**. Giá không gắn với từng class mà gắn với **số cơ sở đã mở**:

- Vào game có **1 cơ sở, dành cho Racing**. Tối đa bằng số class (6); mỗi class chỉ có một cơ sở.
- **Mở cơ sở mới** (nút ở đầu màn Classes): giá = `facility_price_mult[n-1]` × `Pricing.expansion_cost(business_tier)`, hệ số trong `data/classes.json` là 0,5 / 1 / 2 / 4 / 8 cho cơ sở thứ 2 đến 6 (lab chốt sau). Cơ sở mới ở trạng thái **chờ chọn class**.
- **Chọn loại**: ngay sau khi mở, hiện popup lưới 2 cột liệt kê các class chưa có cơ sở; chạm một ô rồi bấm **OK** là xong. Bấm ra ngoài popup thì cơ sở vẫn chờ và nút đổi thành "Chọn loại". Chọn xong **không đổi lại**; không tự chuyển Active, người chơi bấm Watch khi muốn (§5.1).
- Phải chọn class cho cơ sở đang chờ trước khi mở cơ sở tiếp theo.
- Mở và chọn đều đi qua giao dịch hoàn nguyên như `buy_car` (lỗi lưu thì hoàn tiền và trạng thái).
- Thiếu tiền: nút xám, ghi số còn thiếu. Đủ 6 cơ sở: ẩn nút, ghi "đã mở đủ".
- Danh sách chỉ hiện các class đã có cơ sở; class chưa có thì ẩn.

Ghi chú: việc mỗi cơ sở có **doanh thu và giải riêng** thuộc P3, chưa làm; hiện cơ sở chỉ quyết định class nào chơi được.

Thẻ trong ảnh có: biểu tượng, tên, **Active/Watch**, tên đội, giải hiện tại + **Advance**, điểm mùa (Season, Score, Rank) + **Details**. Ánh xạ sang game:

- `business_tier` giữ vai trò **bậc kinh tế toàn cục** (doanh thu, giá nâng cấp, tuyển). Class **không** tạo thêm nền kinh tế riêng.
- Mỗi class có **thang giải riêng** `class_league` (0–5, cùng 6 tên giải hiện có) và mùa/điểm/hạng riêng. Trần: `class_league ≤ business_tier`.
- Class vừa mua bắt đầu ở giải 0 nhưng nhận **catch-up**: đối thủ AI theo giải của class nên người chơi mạnh sẽ thắng nhiều và leo nhanh, không phải cày lại từ đầu.
- **Advance** (lên giải trong class): hoàn tất một mùa (5 lượt theo lịch giải) với hạng ≤ 3 và trả phí nhỏ (đề xuất 25% phí mở rộng giải cùng bậc, lab chốt). Không phải thua mà bị tụt giải.
- **Phần thưởng:** tiền mỗi lượt **bằng Racing** ở cùng sức mạnh để không phá cân bằng Design/12–13. Phần thưởng đa dạng đến từ **Huy hiệu class** (1 huy hiệu mỗi mùa hạng ≤ 3, 2 nếu hạng 1) đổi lấy cosmetic riêng của class và gem lần đầu; chưa cộng chỉ số vĩnh viễn ở bản đầu.
- Tên đội: giữ **một tên toàn cục** (`player_team_name`). Ảnh có ô sửa tên từng class, nhưng ở đây tách ra dễ nhầm và hồ sơ (Design/20) đã có chỗ sửa tên; thẻ class chỉ hiển thị.

### 5.1. Một cuộc đua tại một thời điểm

Chỉ class **Active** chạy đua trực tiếp. Bấm **Watch** ở class khác để chọn nó làm Active:

1. Cuộc đua đang chạy **chạy nốt và chốt kết quả** (không hủy, không mất thưởng).
2. Từ countdown của lượt kế, grid dùng class mới (đường, luật, đối thủ).
3. Có thông báo "Đổi sang Rally sau lượt này" và thẻ hiện trạng thái chờ.

Class không Active **không tiến triển nền** ở bản đầu (đơn giản, dễ cân bằng). Mở rộng sau: auto-sim nền xác suất ở tốc độ giảm (xem D-C1).

### 5.2. Các con số "người chơi" và "tỷ lệ" trên thẻ

Ảnh có hai số: biểu tượng người (844, 947,2, 2,7K…) và biểu tượng cỏ bốn lá (36%, 31%…). Game này offline nên **tôi diễn giải lại** thành thông tin thật tính từ dữ liệu:

- Số bên người → **Sức mạnh đề xuất** của giải class hiện tại (từ `car_base`/`driver_base` và trọng số class), so với `power()` của người chơi.
- Phần trăm → **Cơ hội thắng ước tính** của đội hiện tại ở class đó (tra từ bảng lab, làm mượt theo chênh sức mạnh).

Nếu bạn muốn nghĩa khác (ví dụ số người chơi giả cho cảm giác sống động), báo lại, chỉ là cách hiển thị.

## 6. Giao diện

Modal "Classes" toàn chiều rộng, cuộn dọc, mở từ một nút trên HUD (đề xuất cạnh bảng xếp hạng; không thêm tab, vẫn 5 tab). Đóng bằng X ở góc.

Thẻ class (trắng, bo góc, lề 12, chạm ≥ 44):

| Hàng | Nội dung |
|---|---|
| 1 | Icon class 56 trên ô xanh nhạt, tên class, **Sức mạnh đề xuất** + **Cơ hội thắng**, nút phải: **Watch** (xanh lá) hoặc chữ **Active** |
| 2 | Tên đội (chỉ đọc) |
| 3 | Giải hiện tại + liên kết **Advance** (xám khi chưa đủ điều kiện, kèm lý do) |
| 4 | Điểm mùa: Season, Score, Rank + nút **Details** (xanh dương) |
| 5 (mới) | Dải nhỏ: **Xe gợi ý** và **Chỉ số quan trọng** của class |

Trạng thái:

- **Active:** viền và nền xanh lá nhạt, chữ "Active" thay nút Watch (như ảnh thứ ba).
- **Chưa có cơ sở:** không hiện thẻ; class này chỉ xuất hiện trong popup chọn loại.
- **Chờ đổi:** thẻ đích có nhãn "Sau lượt này".
- **Sắp có:** thẻ mờ "More Coming Soon" cuối danh sách.

**Details:** bảng điểm mùa class (hạng, điểm 8 xe), lịch 5 chặng, lịch sử mùa gần nhất. Tái dùng `ui/leaderboard.gd`.

**Trong cuộc đua:** HUD hiện huy hiệu class và nhãn mặt đường/sự kiện (nếu có). `RaceView` đổi bảng màu đường theo class.

## 7. Ảnh hưởng mã (dự kiến)

| Phần | Thay đổi |
|---|---|
| `data/classes.json` (mới) | Danh sách class: `id`, `name`, `facility_price_mult` (cấp file), `tuning`, `traffic_tuning`, `style_fit`, `track_pool`, màu, icon |
| `core/data/game_data.gd` | `race_classes()`, `race_class(id)`, kiểm tra schema khi nạp |
| `game/game_state.gd` | `facilities` (class_id hoặc "" nếu chờ chọn), `facility_price()`, `buy_facility()`, `assign_facility(id)`, `class_owned` (suy ra), `active_class`, `pending_class`, `class_progress` (`{league, season, score, rank, badges}`); chọn class ở ranh giới lượt; `_make_sim()` truyền tuning của class; `race_snapshot` ghi `class_id`; `class_advance()` |
| Save | `SAVE_VERSION` 8 → 9, migration: save cũ → `facilities = ["racing"]`, `active_class = "racing"`, `class_progress.racing` lấy từ `business_tier`/mùa hiện có |
| `core/sim/traffic_sim.gd` | Hầu như không đổi (đã có `opts.tuning`); chỉ thêm hệ số `style_fit` nhân vào bonus phong cách và sự kiện §3.2 sau này |
| `ui/class_page.gd` (mới), `ui/main.gd`, `ui/race_view.gd`, `ui/hd_ui.gd` | Modal, nút mở, huy hiệu class, bảng màu đường |
| `tests/` | Golden Racing không đổi; test migration; test đổi class ở ranh giới lượt; test mua class (đủ/thiếu tiền, hoàn nguyên); lab cân bằng class |
| `Design/18_Asset_Backlog.csv` | Thêm asset §8 |

Rủi ro chính: tuning ghi đè phải áp **sau** khi cân `race_snapshot` để kết quả lượt khôi phục từ checkpoint (`_restore_checkpoint`) cho ra đúng class đã chốt. Checkpoint phải lưu `class_id`.

## 8. Asset cần thêm

| Asset | Số lượng | Ghi chú |
|---|---|---|
| Icon class trên ô xanh nhạt (ảnh thứ nhất) | 6 + 1 khung xám (chưa mua) | Cùng kích thước avatar HD, nền `#BFD9FF` |
| Huy hiệu class (HUD, ô nhỏ) | 6 | Đơn sắc theo màu class |
| Nút Watch, Details, Advance | Đã có trong `racing_ui_hd` (green/blue); Advance là liên kết chữ | Không cần mới |
| Viền Active xanh lá, thẻ chưa mua | 2 mặt phẳng | Dùng `HdUi` |
| Bảng màu đường theo class | 6 bộ màu | Dạng dữ liệu, không phải ảnh |
| Âm thanh đổi class | 1 | Tái dùng `workshop_audio.gd` nếu có |

## 9. Kiểm tra và tiêu chí chấp nhận

1. Racing giữ nguyên kết quả golden (cùng seed → cùng hạng và thời gian).
2. Với mỗi class, một build **tối ưu cho class** đạt hạng trung bình tốt hơn build chung từ **0,4 đến 0,8 hạng** (lab 200 seed).
3. Không build nào đứng nhất ở cả sáu class (không có chiến lược thống trị).
4. Hạng trung bình tay đua trung bình lệch tối đa ±0,3 so với Racing ở cùng sức mạnh (class khó hơn do rủi ro, không do thiếu thưởng).
5. Đổi class giữa lượt không mất kết quả, không đổi cuộc đua đang chạy; thoát app khi `pending_class` còn treo vẫn khôi phục đúng.
6. Mở cơ sở và chọn class: đủ tiền thì trừ đúng giá, thiếu tiền thì từ chối và save không đổi; phải chọn class cho cơ sở chờ trước khi mở thêm; không tự đổi Active; lỗi lưu thì hoàn nguyên.
7. Thẻ Chưa có cơ sở/Active/Chờ đổi hiển thị đúng ở 320 × 568 và 390 × 844.

## 10. Lộ trình

| Bước | Nội dung | Rủi ro |
|---|---|---|
| P0 | `classes.json`, nạp dữ liệu, tuning vào `TrafficSim`, test golden Racing | Thấp |
| P1 | Trạng thái + save v9 + migration, mở cơ sở + chọn class, đổi class ở ranh giới lượt | Trung bình (checkpoint) |
| P2 | Modal `class_page.gd` theo ảnh, nút HUD, huy hiệu class | Thấp |
| P3 | Thang giải riêng, Advance, mùa/điểm theo class, Huy hiệu | Trung bình (kinh tế) |
| P4 | Lab cân bằng sáu class, chỉnh bảng §3.1 | Cần thời gian chạy nền |
| P5 | Sự kiện riêng §3.2, bảng màu đường, âm thanh, asset | Thấp |
| P6 (tùy chọn) | Auto-sim nền cho class không Active | Cao |

## 11. Quyết định mở (mặc định đề xuất)

| Mã | Câu hỏi | Mặc định |
|---|---|---|
| D-C1 | Class không Active có tiến triển nền không? | **Không** ở bản đầu; xét P6 sau |
| D-C2 | Garage dùng chung hay xe/tay đua riêng từng class? | **Dùng chung** (không nhân 6 lần nội dung) |
| D-C3 | Tên đội theo class hay toàn cục? | **Toàn cục** |
| D-C4 | Thưởng tiền khác nhau theo class? | **Bằng nhau**; đa dạng bằng Huy hiệu class |
| D-C5 | Số class lúc phát hành | **6** như ảnh; có thể giảm còn 4 (Racing, Rally, Stock Car, Superbike) nếu ngân sách art hạn chế |
| D-C7 | Mở class thế nào? | **Mở cơ sở bằng tiền rồi chọn class cho cơ sở** (người dùng chốt 12/11/2026); giá theo số cơ sở, không theo class; mỗi class một cơ sở, chọn xong không đổi |
| D-C6 | Số liệu người/cỏ bốn lá trên thẻ | Sức mạnh đề xuất + cơ hội thắng thật (§5.2) |
