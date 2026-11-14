# 23. Kịch bản Tutorial và mở khóa tính năng dần

Ngày 12/11/2026. Trạng thái: **đề xuất để duyệt, chưa triển khai.** Thay [06 §9](06_UI_UX_Release.md#9-hướng-dẫn-đầu-game-ui-19) và [01 §5](01_UI_Design.md#5-onboarding-liên-kết-gameplay) — hai bản cũ viết cho luồng "bấm Đua", giá Động cơ 120 và tab Cơ sở, không còn khớp game hiện tại (đua liên tục [10](10_Continuous_Race_Loop.md), 8 nâng cấp [11](11_Eight_Upgrades.md)/[12](12_BigNumber_Economy.md), gói phụ kiện và tay đua, Class [22](22_Race_Classes.md), mở cơ sở mới).

Mọi số liệu trong tài liệu (giá, tiền, thưởng) là **ví dụ đọc từ `data/` ngày 12/11/2026**. Lời thoại khi triển khai phải chèn số thật từ `GameState`/`Pricing`, không viết cứng.

**Cập nhật 12/11/2026 (theo yêu cầu):** tính năng không mở hết từ đầu mà **mở khóa dần theo tiến trình** (§5). Mỗi lần mở khóa đi kèm một đoạn hướng dẫn ngắn của tính năng đó, thay cho "gợi ý một lần" ở bản trước.

## 1. Mục tiêu và nguyên tắc

| Mục tiêu | Chỉ tiêu |
|---|---|
| Hoàn tất phần bắt buộc (Phần A) | ≥ 85% người chơi mới, trung vị ≤ 3 phút |
| Hiểu 2 nguồn tiền | Tiền/giây (doanh thu) khác tiền thưởng lượt đua |
| Hiểu "áp dụng lượt sau" | Nâng xe giữa lượt không đổi tốc độ ngay |
| Mở khóa đều tay | Phiên 1 (~10 phút) mở hết U1–U7 hoặc gần hết; không có lượt nào mở 2 tính năng |
| Dùng tính năng vừa mở | ≥ 60% mở gói phụ kiện và gói tay đua đầu tiên ngay khi được mở |

Nguyên tắc:

1. **Không dừng vòng đua.** Cuộc đua tự chạy từ lúc loading bàn giao; tutorial chạy song song, không thêm modal chặn lượt. Ngoại lệ duy nhất là bảng kết quả hiện có (`result_hold`) — tutorial dùng lại nó, không thêm lớp giữ thứ hai.
2. **Học bằng làm.** Mỗi bước kết thúc bằng một thao tác thật (mua, mở gói, đóng bảng), không chỉ bấm "Tiếp".
3. **Một tiêu điểm.** Tối đa một spotlight + một callout 2 dòng tại một thời điểm ([17 L12](17_Layout_Asset_Redesign.md)). Callout đặt cạnh hành động, không che khung đua quá 30% chiều cao.
4. **Mở khóa theo số lượt đua/lần thăng giải, không theo tiền.** Người chơi đoán được lúc nào có gì mới; tiến trình không phụ thuộc may rủi kinh tế. Ngoại lệ là các mốc vốn đã có điều kiện riêng (mở cơ sở mới).
5. **Khóa nhưng vẫn thấy.** Tính năng chưa mở vẫn hiện (xám + ổ khóa) và nói rõ khi nào mở, để tạo tò mò. Không ẩn hoàn toàn.
6. **Không lặp, bỏ qua được.** Bước đã đạt điều kiện thì tự qua. Luôn có "Bỏ qua" lời dẫn.
7. **Không dựng sẵn kết quả, không tiêu gem trong tutorial.** Quà là coupon (đã có `grant_gear_coupons`/`grant_driver_coupons`).

## 2. Nhân vật dẫn dắt

**Linh — trưởng kỹ thuật của đội.** Xuất hiện dạng avatar tròn 56 px ở mép callout, xưng "tôi", gọi người chơi là "Sếp". Giọng ngắn gọn, vui, không quá 2 dòng/câu (≤ 90 ký tự). Art: chân dung cartoon cùng style [08 §0](08_Asset_Concept_LumberStyle.md), 3 biểu cảm (cười, chỉ tay, hào hứng). Nếu chưa có art, dùng icon `staff` HD trong ô xanh.

## 3. Cấu trúc tổng

```text
Lượt 1–2   [Phần A — FTUE]  chỉ có tab Đua: khung đua + nâng cấp
           A1 Chào ─► A2 Xe ─► A3 Tiền/giây ─► A4 Động cơ ─► A5 Ticket ─► A6 Kết quả ─► A7 Lượt 2
Lượt 1→…   [Phần B — Mở khóa dần]  mỗi mốc mở 1 tính năng + hướng dẫn ngắn của nó
           U1 đủ 8 nâng cấp · U2 Giải + Hồ sơ · U3 Túi · U4 Shop · U5 Tay đua
           U6 Garage · U7 Class · U8 Mở cơ sở mới
Mọi lúc    [Phần C — Mẹo theo tình huống]  offline, mốc sao, thăng/rớt giải
```

## 4. Phần A — FTUE

Điều kiện bắt đầu: save mới (`completed_races == 0`, `tutorial.ftue_state == "new"`), sau khi loading bàn giao và sau mọi panel bắt buộc ([09 §5](09_Startup_Loading_Design.md)). Lượt 1 bắt đầu countdown đồng thời với A1.

Màn hình lúc đầu: chỉ tab **Đua** mở. Bốn tab còn lại hiện ổ khóa (§5.2). Trên tab Đua chỉ có khung đua và hai ô nâng cấp **Động cơ** và **Ticket Marketing**; sáu ô còn lại hiện ổ khóa "Mở sau lượt 1". Nút `Lịch` và `Class` trên dải chặng ẩn tới khi mở.

### A1 — Chào mừng
- **Khi:** ngay lúc vào gameplay (đang countdown 3-2-1 lượt 1).
- **UI:** callout giữa nửa dưới màn, nền mờ nhẹ 20% chỉ vùng dưới khung đua; khung đua vẫn sáng.
- **Linh:** "Chào Sếp! Đội mình có một chiếc xe, một tay đua và 1.000 tiền." / "Xe tự đua — việc của Sếp là nâng cấp và kiếm tiền."
- **Nút:** `Bắt đầu` (chính, cam) · `Bỏ qua hướng dẫn` (chữ, xám).
- **Xong:** bấm `Bắt đầu`. Bấm `Bỏ qua` → §7.

### A2 — Xe của bạn
- **UI:** spotlight vòng tròn bám chấm xe người chơi, mũi tên phụ chỉ ô `P?/8` và đồng hồ trên HUD.
- **Linh:** "Chấm sáng này là xe mình. Góc trên là hạng và thời gian còn lại."
- **Xong:** chạm bất kỳ hoặc tự qua sau 4 giây.

### A3 — Tiền theo giây
- **UI:** spotlight thanh tiền ở header; số `+8/giây` bay lên 2 lần.
- **Linh:** "Khán giả trả tiền mỗi giây, kể cả khi không đua. Đó là doanh thu."
- **Xong:** chạm hoặc tự qua sau 3 giây.

### A4 — Nâng Động cơ
- **UI:** spotlight ô **Động cơ** + bàn tay (`tutorial hand`) trên nút mua.
- **Linh:** "Nâng Động cơ để xe nhanh hơn. Bấm vào đây!" (giá hiện tại: 160).
- **Xong:** `levels.engine` tăng ≥ 1. Banner Power ([21](21_Power_Increase_Toast.md)) tự hiện.
- **Ngay sau khi mua, callout đổi chữ:** "Xe đang chạy rồi nên nâng cấp vào xe từ **lượt sau**." — trỏ vào nhãn "Áp dụng lượt sau".
- **Dự phòng:** đã nâng trước khi tới A4 → bỏ qua A4, vẫn hiện câu "lượt sau" 3 giây.

### A5 — Nâng Ticket Marketing
- **UI:** spotlight ô **Ticket Marketing**.
- **Linh:** "Nâng doanh thu thì tiền vào nhiều hơn — cái này có hiệu lực **ngay**."
- **Xong:** `levels.ticket` ≥ 1. Số tiền/giây ở header nảy và đổi giá trị (8 → 8,25; nếu mức tăng nhỏ khó thấy, hiện `+3%` cạnh số).
- Tiền còn lại ví dụ: 1.000 − 160 − 150 = 690.

### A6 — Kết quả lượt 1
- **Khi:** lượt 1 hết giờ, bảng kết quả hiện có bật lên. A4/A5 chưa xong thì nối lại sau khi đóng bảng.
- **Linh (1):** "Về P3! Thưởng đua cộng thẳng vào ví." (hạng/tiền thật). Về cuối: "Lượt đầu ai cũng hồi hộp. Có nâng cấp rồi, lượt sau sẽ khác!"
- **Linh (2):** "Điểm mỗi lượt cộng dồn vào thanh thăng giải. Đầy 36 điểm là lên giải mạnh hơn." — spotlight dòng "Điểm thăng giải +x · y/36".
- **Xong:** đóng bảng → **mở khóa U1** (§5) ngay trước countdown lượt 2.

### A7 — Lượt 2 với xe mới
- **UI:** callout nhỏ trên khung đua 3 giây: "Động cơ mới đã lắp. Power 4xx → 4xx."
- Hết lượt 2 → mở khóa **U2**, Phần A hoàn tất (`ftue_state = "done"`).
- **Linh (kết):** "Từ giờ Sếp tự quản lý nhé. Có gì mới tôi sẽ báo!"

Ngân sách thời gian: A1–A5 trong lượt 1 (~38 giây; nếu chưa xong thì nối sang lượt 2), A6 ~15 giây, A7 ~10 giây → ~1,5–2 phút.

## 5. Phần B — Lịch mở khóa tính năng

### 5.1. Lịch

**Lượt** = một cuộc đua/chặng có trao thưởng ([10 §1](10_Continuous_Race_Loop.md)): đếm ngược 3 giây → đua → bảng kết quả (người chơi đóng) → lượt kế. Không còn mùa (§13). Đo ngày 12/11/2026: `Balance.race_duration("track_circuit_b")` = **34,8 giây** (thời gian xe chuẩn giải 0 chạy đủ 3 vòng), nên một lượt ≈ 38 giây + thời gian đọc bảng kết quả (~5 giây) ≈ **43 giây**; 5 lượt ≈ **3,5–4 phút**. Mốc mở khóa tính theo số lượt nên tự co giãn nếu thời lượng đua đổi.

| # | Tính năng mở | Điều kiện | Thời điểm ước tính | Quà khi mở | Hướng dẫn ngắn (Linh) | Thao tác dẫn |
|---|---|---|---|---|---|---|
| — | Tab Đua: khung đua, Động cơ, Ticket Marketing | Có sẵn | 0:00 | — | Phần A | A4, A5 |
| U1 | 6 nâng cấp còn lại (Lốp, Khung gầm, Hộp số, Victory Celebrations, Parking, Grandstands) | Hết lượt 1 | ~0:45 | — | "Thêm 3 bộ phận xe và 3 nguồn doanh thu. Grandstands nhân toàn bộ doanh thu!" | Spotlight nhóm doanh thu, không bắt mua |
| U2 | Tab **Giải** + nút `Lịch` + **Hồ sơ đội** (avatar) | Hết lượt 2 | ~1:30 | — | "Về top 3 sẽ nhận cúp. Dùng cúp nâng cấp ở tab Giải. Chạm avatar góc trên để đặt tên đội." | Mở tab Giải |
| U3 | Tab **Túi** (phụ kiện) | Hết lượt 3 | ~2:10 | 1 coupon Standard Gear | "Phụ kiện cộng thêm Power cho cả đội. Bấm nút đang sáng để mở gói miễn phí nhé!" · sau khi mở: "Tuyệt! Phụ kiện đã cộng +X Power cho cả đội." (X = `gear_power_bonus()`; chuyện mảnh/nâng sao để mẹo C5). Phụ kiện = Power cộng đều 11 chỉ số: (kiếm+khiên) × `power_per_point` (0,025 trong `data/gear.json`, placeholder; Rare level 0 = +1,0) | Mở 1 gói Standard |
| U4 | Tab **Shop** (quà ngày, gói) | Hết lượt 4 | ~2:55 | Quà ngày đầu (sẵn có) | "Mỗi ngày có quà miễn phí ở Shop. Nhận ngay hôm nay!" | Nhận quà ngày |
| U5 | Tab **Đội → Tay đua** (Pro/All-Star Pack, tuyển) | Hết lượt 5 | ~3:35 | 1 coupon Pro Pack | "Mỗi tay đua có kỹ năng riêng. Mở Pro Pack để chiêu mộ!" · có tay đua mới: "Chọn tay đua này cho lượt sau nếu Power cao hơn." | Mở 1 gói Pro, rồi chọn tay đua |
| U6 | **Đội → Garage** (mua xe, sơn, decal) | Hết lượt 7 | ~5:00 | — | "Xe mới có chỉ số nền cao hơn, mỗi xe nâng cấp riêng. Có thể đổi sơn ở đây." | Mở Garage, spotlight xe rẻ nhất chưa có |
| U7 | Nút **Class** (bộ môn, cơ sở) | Hết lượt 10 | ~7:00 | — | "Mỗi bộ môn ưu tiên chỉ số khác nhau. Rally cần Lốp và Khung gầm tốt." | Chỉ nút Class; bấm Đã hiểu |
| U8 | ~~Khối Mở cơ sở mới trong tab Giải~~ | **Bỏ khỏi lịch** (12/11/2026): thẻ "Mở cơ sở" đã bị gỡ khỏi tab Giải; quay lại cùng thiết kế "Thăng giải" ở [26 §6](26_Independent_Facilities.md) | — | — | — | — |

Ràng buộc đã kiểm tra:
- **Garage mở trước Class.** Xe hạng cao và cơ sở mới đều tốn tiền lớn; U6 (lượt 7) đến trước U7 (lượt 10) để người chơi đã quen mua xe trước khi gặp bộ môn.
- **U1 mở sau lượt 1** chỉ trễ ba nguồn doanh thu ~60 giây; ảnh hưởng kinh tế không đáng kể, nhưng lab nhịp ([12](12_BigNumber_Economy.md)) cần chạy lại với lịch này.
- **Không bao giờ 2 mở khóa trong cùng một lượt.** Mốc lượt là 1/2/3/4/5/7/10, không trùng; `Tutorial.validate()` từ chối dữ liệu có hai tính năng cùng lượt, nên không cần hàng đợi "dời sang lượt sau".
- Không khóa: thu nhập offline, cài đặt, bảng kết quả, hộp lỗi lưu.

### 5.2. Hiển thị khi đang khóa

- **Tab khóa:** icon xám, ổ khóa nhỏ góc trên phải, nhãn tab vẫn đọc được. Chạm → toast 1 dòng: "Mở sau lượt 3 · còn 1 lượt" / "Mở sau lượt 5 · còn 2 lượt" / "Mở khi thăng giải lần đầu".
- **Ô/nút khóa trong trang** (6 ô nâng cấp, Garage, Class): cùng kiểu xám + ổ khóa + điều kiện, không bấm được mua.
- **Lịch sắp mở:** dưới HUD chặng có dòng nhỏ "Sắp mở: Túi phụ kiện · 1 lượt nữa" — chỉ hiện mục gần nhất, ẩn khi đã mở hết U1–U7.
- Trợ năng: `accessibility_name` của tab khóa đọc "Túi, đã khóa, mở sau lượt 3".

### 5.3. Khoảnh khắc mở khóa

1. Đủ điều kiện khi lượt chốt kết quả → ghi `unlocked` trong **cùng giao dịch lưu** với thưởng lượt (đúng một lần, kể cả khi thử lưu lại).
2. Trong bảng kết quả hiện thêm một dòng cuối: icon tính năng + "**Mở khóa: Túi phụ kiện**" (+ quà nếu có). Không thêm popup thứ hai.
3. Đóng bảng → ổ khóa trên tab vỡ ra (scale + fade 300 ms, giảm chuyển động: chỉ fade), tab có chấm đỏ.
4. Người chơi chạm tab đó lần đầu → chạy hướng dẫn ngắn của tính năng (cột "Hướng dẫn ngắn"), một callout, dẫn đúng một thao tác. Không tự chuyển tab.
5. Quà khi mở (coupon) phát cùng giao dịch ở bước 1, nên kể cả khi người chơi không vào tab vẫn không mất quà.

## 6. Phần C — Mẹo theo tình huống

Không khóa gì; mỗi mẹo hiện một lần, tối đa 1 mẹo mới mỗi lượt, không đè bảng kết quả/offline/modal. Nút `Tắt mẹo` trên callout và công tắc "Mẹo từ Linh" trong Cài đặt đều tắt được.

| # | Mẹo | Khi | Nơi | Linh |
|---|---|---|---|---|
| C1 | Thu nhập offline | Panel offline đã hiện, sau khi người chơi đóng panel | Mọi tab | "Lúc Sếp vắng, đội vẫn thu 50% doanh thu, tối đa 2 giờ. Nhớ quay lại nhận nhé!" (số lấy từ `economy.json`) |
| C2 | Đủ cúp nâng cấp | Có cúp đủ mua một nâng cấp cúp đã mở (thay "Thăng giải", đã bỏ) | Mọi tab | "Sếp có N cúp — đủ nâng cấp ở tab Giải rồi! Cúp chỉ nhận khi về top 3." |
| C3 | ~~Thanh thăng giải chậm~~ | **Bỏ** cùng thanh thăng giải | — | — |
| C4 | Mốc sao doanh thu | Một mục doanh thu (cấp ≥ 1) còn 1–3 cấp tới mốc sao kế (25/50/100/150) | Tab Đua, spotlight ô đó | "<Mục> còn N cấp nữa là tới cấp 25: được sao, doanh thu mục này ×1,1!" |
| C5 | Phụ kiện đủ mảnh | Một món sở hữu đủ mảnh lên level kế | Tab Túi, spotlight nút nâng món đó | "<Món> đã đủ mảnh để nâng cấp!" |
| C6 | Tay đua mạnh hơn | Có tay đua sở hữu mạnh hơn tay đua đang dùng (tổng 7 chỉ số + thưởng level; xe không xét) | Đội → Tay đua | "<Tên> mạnh hơn tay đua đang dùng. Chọn lại cho lượt sau nếu Sếp muốn nhé!" |

## 7. Lượt đua đầu tiên (tùy chọn)

- Lượt 1 và 2 của save mới dùng `tutorial_grid`: đối thủ Power ×0,94 so với giải 0 (cấu hình trong `data/tutorial.json`).
- Mục tiêu đo bằng lab (≥ 500 seed): không nâng gì vẫn đạt P1–P4 ≥ 70%, P1 ≤ 35%. Không sửa kết quả sau mô phỏng.
- Từ lượt 3 dùng grid bình thường. Hai lượt này tính điểm thăng giải như thường.

## 8. Bỏ qua, gián đoạn, save cũ

- **Bỏ qua ở Phần A:** hộp xác nhận "Bỏ qua hướng dẫn? Có thể xem lại trong Cài đặt." → `ftue_state = "skipped"`. Chỉ tắt lời dẫn Phần A; **lịch mở khóa §5 vẫn giữ nguyên** để giữ nhịp game, quà khi mở khóa vẫn phát. Hướng dẫn ngắn khi mở từng tính năng vẫn hiện (có `✕`).
- **Thoát app giữa Phần A:** lưu `ftue_step`; mở lại tiếp đúng bước, không lặp A1 ("Mình tiếp tục nhé!").
- **Save trước khi có tutorial (v9):** migration — `completed_races > 0` → `ftue_state = "done"`, **mở hết U1–U7**, U8 theo điều kiện thật, không phát quà mở khóa, đánh dấu đã xem hướng dẫn ngắn của tính năng đã dùng (`gear_open_count > 0` → U3, `driver_open_count > 0` → U5, `class_owned.size() > 1` → U7, `business_tier > 0` → U8). Không bao giờ khóa lại tính năng người chơi đã dùng.
- **Lỗi lưu (`save_error`):** tạm ẩn tutorial; lỗi lưu ưu tiên tuyệt đối. Mở khóa chỉ hiện sau khi giao dịch lưu thành công.
- **Xem lại:** Cài đặt → "Xem lại hướng dẫn" chạy lại A1–A6 ở chế độ chỉ đọc (không yêu cầu mua, không khóa lại gì, không phát quà).
- **Debug:** cờ CLI `--unlock-all` (cùng nhóm `--reset`, `--shot`) để chụp ảnh/test UI không phải đua qua lịch.

## 9. Dữ liệu và save

`data/tutorial.json` (mới):

```json
{
  "schema_version": 1,
  "ftue": ["A1_welcome", "A2_car", "A3_income", "A4_engine", "A5_ticket", "A6_result", "A7_race2"],
  "start_upgrades": ["engine", "ticket"],
  "unlocks": [
    {"id": "U1_upgrades", "when": {"races": 1}, "targets": ["tyre", "chassis", "gearbox", "celebration", "parking", "grandstands"]},
    {"id": "U2_league",   "when": {"races": 2}, "targets": ["tab_league", "profile"]},
    {"id": "U3_bag",      "when": {"races": 3}, "targets": ["tab_bag"], "gift": {"gear_coupon": {"standard": 1}}},
    {"id": "U4_shop",     "when": {"races": 4}, "targets": ["tab_shop"]},
    {"id": "U5_drivers",  "when": {"races": 5}, "targets": ["tab_team", "team_drivers"], "gift": {"driver_coupon": {"pro": 1}}},
    {"id": "U6_garage",   "when": {"races": 7}, "targets": ["team_garage"]},
    {"id": "U7_class",    "when": {"any": [{"promoted": 1}, {"races": 15}]}, "targets": ["class_button"]},
    {"id": "U8_expansion","when": {"expansion_ok": true}, "targets": ["expansion"]}
  ],
  "tutorial_grid": {"races": 2, "opponent_power_mult": 0.94},
  "max_new_tips_per_race": 1
}
```

`GameData.validate()` kiểm tra: id không trùng, `targets` thuộc danh sách đã biết, mỗi tính năng chỉ thuộc một mốc, `races` tăng dần.

Lời thoại ở bảng chuỗi bản địa hóa (vi/en), khóa `tut.A4.line1`, `unlock.U3.line1`…, placeholder `{price}`, `{rank}`, `{coins}`, `{left}`.

Save (`SAVE_VERSION` 9 → 10):

```text
tutorial = {
  ftue_state: "new" | "active" | "done" | "skipped",
  ftue_step: "A4_engine",
  unlocked: ["U1_upgrades", "U2_league", ...],
  unlock_pending: ["U8_expansion"],   # đủ điều kiện nhưng dời sang lượt sau (§5.1)
  intro_seen: ["U3_bag", ...],        # đã xem hướng dẫn ngắn khi mở
  tips_seen: ["C1_offline", ...],
  tips_off: bool
}
```

## 10. Kiến trúc triển khai

- `game/tutorial.gd` (`class_name Tutorial`, thuộc `GameState`): máy trạng thái FTUE, đánh giá điều kiện mở khóa **trong `_resolve()`** cùng giao dịch thưởng, phát quà qua `grant_*_coupons`. API: `feature_unlocked(target) -> bool`, `unlock_hint(target) -> String` (chuỗi điều kiện cho toast), `next_unlock() -> Dictionary`.
- **Chặn ở tầng game, không chỉ UI:** `buy`/`buy_many` (ô chưa mở), `open_gear_pack`, `open_driver_pack`, `recruit_driver`, `buy_car`, `buy_class`, `request_expansion` trả `false` khi tính năng chưa mở. UI chỉ đọc `feature_unlocked()`.
- `ui/tutorial_overlay.gd`: Control phủ toàn màn, `mouse_filter = IGNORE` trừ vùng callout; spotlight bằng shader hoặc 4 ColorRect quanh rect mục tiêu; bàn tay dùng asset `tutorial hand` có sẵn.
- `ui/main.gd`: nav và ô nâng cấp có trạng thái khóa (style `cancel` của HdUi + icon `lock`), dòng "Sắp mở", dòng mở khóa trong bảng kết quả. Neo mục tiêu bằng tên node cố định: `Upgrade_engine`, `HudCoins`, `Nav_bag`, `ClassButton`, `Pack_standard`, `Pack_pro`…; overlay tự cuộn `ScrollContainer` cha tới mục tiêu.
- `RaceView.player_screen_pos()` cho spotlight A2.
- Analytics ([07](07_Technical_Architecture.md)): `tutorial_step {id, ms_since_start}`, `tutorial_skip {step}`, `feature_unlock {id, races, seconds_played}`, `feature_first_use {id, seconds_after_unlock}`, `locked_tap {target}` (đo mức tò mò), `tip {id, action}`.

## 11. Kiểm chứng

1. Save mới: hoàn tất A1–A7 chỉ bằng các thao tác được chỉ; vòng đua không dừng ngoài bảng kết quả hiện có.
2. Đua liên tục 10 lượt không chạm UI ngoài đóng bảng kết quả: U1–U6 mở đúng lượt 1/2/3/4/5/7, mỗi lượt tối đa một mở khóa, quà coupon nhận đúng một lần mỗi mốc.
3. Thử lưu lại sau lỗi ghi ở lượt có mở khóa: không mở hai lần, không cộng quà hai lần.
4. Gọi trực tiếp `open_gear_pack`, `buy_car`, `buy_class`, `buy("parking")` khi chưa mở → `false`, tiền/gem không đổi.
5. Mua Động cơ trước A4 → A4 tự qua. Đổi tab/thoát app giữa Phần A → tiếp tục đúng bước.
6. Bỏ qua tại A1: lịch mở khóa vẫn chạy đúng, quà vẫn phát.
7. Save v9 có `completed_races > 0`: mở hết U1–U7, không thấy Phần A, không nhận quà; tính năng đã dùng không bị khóa.
8. U7 trùng mốc với U6 (giả lập thăng giải ở lượt 7): U7 dời sang hết lượt 8.
9. Màn 320/390/412: tab khóa, toast, callout không tràn; spotlight trùng mục tiêu sau khi cuộn.
10. Lab nhịp kinh tế với lịch U1 và lab `tutorial_grid` đạt mục tiêu §7.
11. Test headless dùng save riêng (`tutorial_test.*`), không gọi `reset_progress()`.

## 12. Quyết định cần duyệt

| # | Câu hỏi | Mặc định đề xuất |
|---|---|---|
| T-D1 | Có nhân vật dẫn dắt (Linh) không? | Có; cần 3 chân dung |
| T-D2 | Lượt 1–2 dùng grid nhẹ hơn? | Có, ×0,94, chỉnh bằng lab |
| T-D3 | Quà khi mở khóa | Coupon Standard Gear ở U3, coupon Pro Pack ở U5 |
| T-D4 | Tính năng khóa: hiện xám hay ẩn hẳn? | Hiện xám + ổ khóa + điều kiện |
| T-D5 | Bỏ qua hướng dẫn có mở hết tính năng không? | Không — chỉ tắt lời dẫn, lịch mở khóa giữ nguyên |
| T-D6 | Lịch U1–U7 (lượt 1/2/3/4/5/7, thăng giải đầu/lượt 15) | Như §5.1, chỉnh sau playtest |

## 13. Bỏ tính năng mùa (đã triển khai 12/11/2026)

Theo yêu cầu, game không còn **mùa / 5 chặng**. Thay bằng **thanh điểm thăng giải tích lũy**:

| Trước (mùa) | Sau |
|---|---|
| 5 chặng/mùa, tổng ≥ 36 điểm thì mở quyền vào giải kế; thiếu điểm thì mất trắng khi sang mùa mới | Mỗi lượt cộng điểm theo hạng vào `promo_points` (không reset); đủ `promote_points` (36) thì `unlocked_tier` = giải kế, ngay trong lượt đó |
| Thưởng hoàn tất mùa = 10% exposure của 5 chặng | **Thưởng tham gia** mỗi lượt = 10% exposure lượt đó (`rewards.participation_ratio`), cộng vào tiền lượt → tổng tiền không đổi |
| 20 gem khi hết mùa đầu ở mỗi giải | 20 gem khi lần đầu đầy thanh ở mỗi giải (`first_promotion_gems`, giữ reward id `first_season/<tier>` để không phát lại cho save cũ) |
| Tay đua Bình mở sau 1 mùa | Mở sau **5 lượt đua** (`unlock.type = "races"`) |
| Tab Giải: thẻ mùa, 5 thẻ chặng, tổng kết mùa | Thẻ "Thăng giải x/36", lượt đang chạy, 5 lượt gần nhất (`recent_results`) |
| Dải trên khung đua "Giải · Mùa n · Chặng x/5" | "Giải · Thăng giải x/36" / "Đủ điểm thăng giải" / "Giải cao nhất" |
| Hồ sơ: "Mùa hoàn tất" | "Lần thăng giải" (`unlocked_tier`) |

- Sau khi đầy thanh, điểm ngừng cộng cho tới khi mở cơ sở mới; mở cơ sở đưa thanh về 0 ở giải mới.
- Reward id lượt đổi từ `race/s<mùa>/st<chặng>` sang `race/n<race_counter>`; seed lượt = `hash("race_<race_counter>")`.
- `data/economy.json` bỏ `stages`, `max_season_points`; `leagues.schedule` chỉ còn là danh sách track (không bắt buộc đủ 5).
- Save v10. Save ≤ v9: điểm của mùa đang dở chuyển thành `promo_points`; đã đủ điều kiện thăng (`unlocked_tier > business_tier`) thì thanh đầy; thưởng hoàn tất của mùa dở **không** phát. Không còn ghi `season_number`, `stage_index`, `season_results`, `last_season`, `completed_seasons`, `season_history`.
- Hệ quả cân bằng: người chơi đua kém vẫn thăng giải (chậm hơn) thay vì kẹt. Ngưỡng 36 điểm và hai lab `tests/lab/promotion_lab.gd`, `traffic_promo.gd` (vẫn mô phỏng theo mùa) cần xem lại khi playtest.
- Các tài liệu 02/04/05/10 còn mô tả mùa; mục này là nguồn đúng khi mâu thuẫn.

## 14. Trạng thái triển khai Phần A (12/11/2026)

Đã làm A1–A7 trong Godot:

- `game/tutorial.gd` (`class_name Tutorial`): thứ tự bước, điều kiện tự qua (A4: `level_of("engine") ≥ 1`, A5: `level_of("ticket") ≥ 1`), thời gian tự qua (A2 4 giây, A3 3 giây, câu phụ 3 giây), lời thoại có chèn số thật.
- `ui/tutorial_overlay.gd` (`TutorialOverlay`): callout của Linh (icon `staff` thay chân dung), spotlight (vòng tròn quanh xe; khung + làm tối xung quanh cho ô nâng cấp/thanh tiền/bảng kết quả/Power), bàn tay `tutorial_hand.svg` ở nút mua, nút Bỏ qua có xác nhận. Lớp gốc không nhận chạm.
- `ui/main.gd`: bật sau panel offline; tạm ẩn khi rời tab Đua hoặc có modal/hồ sơ/trang Class (thời gian tự qua cũng dừng); A4/A5 tự cuộn tới ô; A6 giữ bảng kết quả hiện có (tắt đếm ngược 2 giây) tới khi đọc xong hai câu. `RaceView.player_marker()`/`hud_rank_rect()` cấp vị trí.
- Save: `GameState.tutorial = {state, step, power_before}`, lưu mỗi lần đổi bước, kiểm tra hợp lệ khi đọc. Save không có trường này: đã đua → `done`, chưa đua → `new`. Không tăng `SAVE_VERSION` (trường tùy chọn của v10).
- Debug: `--tutorial` (bật khi chụp ảnh/auto-race), `--tutorial-step=A4_engine` (nhảy tới bước).
- Test: `tests/tutorial_test.gd` (trong `run_tests.sh/.ps1`), save riêng.

Chưa làm (khác §4 hoặc thuộc phần sau):
- Khóa tab/ô nâng cấp lúc đầu và mọi mốc U1–U8 (Phần B), mẹo Phần C. Hiện mọi tính năng vẫn mở; A4 chỉ làm tối các ô khác, không khóa.
- Chấm cam trên tab Đua khi tutorial tạm ẩn; "Xem lại hướng dẫn" trong Cài đặt.
- Grid đối thủ nhẹ hơn cho lượt 1–2 (§7), analytics (dự án chưa có hệ analytics), `data/tutorial.json` và bảng chuỗi bản địa hóa — lời thoại đang nằm trong `game/tutorial.gd`.
- Hiệu ứng số `+x/giây` bay lên ở A3.
- Nếu lượt 1 hết khi còn ở A4/A5, bảng kết quả hiện bình thường 2 giây và A6 dùng lượt kế tiếp.
- Chưa thử trên thiết bị thật; đã xem ảnh chụp A1–A4 ở 390 px.

### Bổ sung art Linh (12/11/2026)

- Đã tạo chân dung Linh cùng 3 biểu cảm cười / chỉ tay / hào hứng: `assets/tutorial/linh_expressions.png`, 3 AtlasTexture trong `assets/tutorial/portraits/`, nguồn và tọa độ trong `manifest.json`.
- Callout đã thay icon `staff` dự phòng bằng avatar tròn 56 px: cười khi chào/xác nhận bỏ qua; chỉ tay khi chỉ mục tiêu; hào hứng sau nâng cấp và ở A7. Bàn tay hướng dẫn và spotlight hiện có tiếp tục dùng.
- Import Godot 4.7.2 thành công; `tutorial_test.gd` đạt 0 failures; render native 3 biểu cảm ở 320/390/412 px (`Design/Previews/tutorial_linh_*.png`). Đã xem ảnh 320 px chỉ tay và 390 px hào hứng. Runner còn cảnh báo resource/RID khi thoát; chưa thử điện thoại thật. Mục này chỉ cập nhật art, không thay trạng thái triển khai Phần B/C.

## 15. Trạng thái triển khai Phần B — mở khóa dần (12/11/2026)

Đã làm U1–U7. **Khác thiết kế ban đầu:**

- **Mở khóa tính theo `completed_races`, không lưu danh sách đã mở** (bỏ `unlocked`, `unlock_pending`). Lịch không có hai mốc cùng lượt nên không cần hàng đợi; save, thử lưu lại và khôi phục luôn cho cùng kết quả. Chỉ `tutorial.gated` và `tutorial.intro_seen` được lưu. Không đổi `SAVE_VERSION`.
- **Chỉ save mới bị khóa:** `gated = true` được đặt khi hướng dẫn bắt đầu cho save chưa đua (`TutorialOverlay.start()`). Save cũ, test và chế độ chụp ảnh mặc định mở hết, nên người chơi cũ không bao giờ bị khóa lại. Bỏ qua Phần A không tắt lịch (T-D5).
- **Bỏ U8 (mở cơ sở):** thẻ này đã bị gỡ khỏi tab Giải; **U2 đổi nội dung** từ "thanh thăng giải" sang cúp; **U7 đổi điều kiện** thành "hết lượt 10" (không còn thanh thăng giải). Giá Class/cơ sở rất lớn so với ví lượt 10 nên U7 chỉ giới thiệu.
- Dữ liệu ở `data/tutorial.json` (đọc bằng `Tutorial.features()`, kiểm bằng `Tutorial.validate()`), không đi qua `GameData`.

**Hành vi:**

| Phần | Làm gì |
|---|---|
| Chặn tầng game | `upgrade_state` → `"locked"`; `buy_many_for`, `buy_car`, `select_car`, `set_cosmetics`, `recruit_driver`, `upgrade_driver`, `gear/driver_can_afford` (→ `open_*_pack`), `upgrade_gear`, `buy_facility`, `assign_facility`, `select_class`, `buy_trophy_upgrade`, `claim_daily`, `set_player_team_name` trả `false` khi chưa mở |
| Mở khóa trong `_resolve` | `_compute_result` đánh giá `Tutorial.unlocked_at(completed_races)` cùng giao dịch thưởng, phát coupon (reward id `unlock/<id>`) đúng một lần, trả `res["unlocked"]` |
| Hiển thị khóa | Tab Túi/Đội/Giải/Shop: xám + ổ khóa, bấm → toast "<Tên> · Mở sau lượt N · còn M lượt"; nút Lịch/Class xám; avatar mờ; nút Garage có ổ khóa; 6 ô nâng cấp: xám, "Mở sau lượt 1", nút "Khóa"; dòng "Sắp mở: … · N lượt nữa" dưới trạng thái đua |
| Khoảnh khắc mở | Bảng kết quả thêm dòng "Mở khóa: <tên>" (+ "Quà: …"); tab mới mở có chấm đỏ tới khi xem hướng dẫn |
| Hướng dẫn ngắn | `TutorialOverlay.show_intro(id)`: một callout của Linh khi người chơi đứng đúng tab và không có modal/kết quả; U1/U3/U4/U5/U7 có spotlight; U3/U4/U5 có bàn tay chỉ nút và câu thứ hai sau khi làm xong (tự đóng sau 3 giây); rời tab thì chờ, không hủy; không chen vào Phần A đang chạy |

**Debug:** `--gated` (bật lịch mở khóa khi chụp ảnh), `--races=N` (đặt số lượt đã đua). Ví dụ: `-- --shot=x --tab=0 --reset --gated --races=3`.

**Test:** `tests/tutorial_unlock_test.gd` (70 kiểm tra: dữ liệu, chặn tầng game, 10 lượt liên tục, quà đúng một lần kể cả khi lưu lỗi rồi thử lại, save cũ, UI khóa, hướng dẫn ngắn, bảng kết quả ở 320/412 px) trong `run_tests.sh/.ps1`.

**Chưa làm:** Phần C (mẹo theo tình huống), "Xem lại hướng dẫn" trong Cài đặt, hiệu ứng vỡ khóa khi mở, grid đối thủ nhẹ ở lượt 1–2, lab nhịp kinh tế với lịch U1, chưa thử trên điện thoại.

## 16. Trạng thái triển khai Phần C — mẹo theo tình huống (12/11/2026)

Đã làm C1, C2, C4, C5, C6 (C3 bỏ cùng thanh thăng giải; C2 đổi sang cúp):

- Danh sách và tab ở `data/tutorial.json` (`tips`); điều kiện và lời thoại tính từ trạng thái thật trong `Tutorial.tip_info(id, gs)` (trả `{}` khi tình huống không còn đúng); `Tutorial.next_tip(gs, tab)` chọn mẹo đầu tiên đủ điều kiện theo thứ tự C1, C2, C6, C5, C4.
- Quy tắc hiện (`Tutorial.tips_allowed`): công tắc bật, Phần A đã xong hoặc đã bỏ qua (save cũ cũng nhận mẹo), mỗi lượt đã hoàn tất tối đa một mẹo mới (`tips_last`), mỗi mẹo một lần (`tips_seen`). Hướng dẫn mở khóa (Phần B) luôn được ưu tiên trước mẹo.
- Hiển thị: dùng chung callout của Linh (`TutorialOverlay.show_tip`), nút `Đã hiểu` và `Tắt mẹo`; C4/C5 có spotlight ô/nút liên quan; ẩn khi có modal/kết quả hoặc sai tab (không bị hủy); **tự đóng và tính là đã xem** nếu tình huống hết đúng (đã nâng qua mốc, đã đổi tay đua...).
- C1 dựa trên cờ `offline_shown` do `_show_offline()` ghi, nên mẹo hiện **sau** khi đóng panel, không sửa bố cục panel.
- Save: `tutorial.tips_seen`, `tips_off`, `tips_last`, `offline_shown` (không đổi `SAVE_VERSION`); id lạ bị làm sạch, sai kiểu bị từ chối khi ghi; save cũ mặc định mẹo bật.
- Cài đặt: mục "HƯỚNG DẪN" với công tắc "Mẹo từ Linh" (`TipsToggle`).
- Debug: `--tutorial-done`, `--levels=ticket:23,parking:48` (kết hợp `--races=N`).
- Test: `tests/tutorial_tips_test.gd` (44 kiểm tra) trong `run_tests.sh/.ps1`.

Chưa làm: "Xem lại hướng dẫn" trong Cài đặt, mẹo C6 cho xe (chỉ xét tay đua), tách lời thoại ra bảng chuỗi bản địa hóa, chưa thử trên điện thoại.

## 17. Bỏ khóa ô nâng cấp (2026-11-12)
Đã gỡ U1: cả 8 ô nâng cấp mua được ngay từ đầu. Xóa `kind_unlocked`, `feature_of_kind`, trạng thái `upgrade_state == "locked"`, ô xám "Mở sau lượt 1" và hướng dẫn U1. Lịch mở khóa còn U2–U7 (lượt 2/3/4/5/7/10); các mục nói về U1 ở trên là lịch sử.
