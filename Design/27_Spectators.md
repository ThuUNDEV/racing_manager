# 27 — Khán giả xem đua (dải khán đài)

- Ngày: 12/11/2026
- Trạng thái: **P0 + P1 đã triển khai (12/11/2026)** trong `ui/race_view.gd`. Đã chốt: **mật độ theo cấp Parking (chỗ ngồi), không theo Grandstands** (`fill = log10(1 + giá trị Parking) / 3`, tối thiểu 12%), 3 hàng, chấm tròn, **không chú thích khi chạm**, phản ứng bằng **icon mặt vui/buồn** (thay cho chấm nhảy/cúi/giật ở §4). Chưa làm: hiệu ứng lên cấp, spotlight tutorial, `--reduce-motion`, màu nền theo bậc, confetti. Chỉ đụng lớp vẽ; không đổi sim, kinh tế hay save.
- Liên quan: [08 §3](08_Race_Traffic_Revision.md) (khung đua), [10](10_Continuous_Race_Loop.md), [11](11_Eight_Upgrades.md) và [12 §4](12_BigNumber_Economy.md) (Grandstands), [23](23_Tutorial_Script.md) (câu "Khán giả trả tiền mỗi giây"), [25 §7.5](25_Ads_Lumber_Reference.md) (hiệu năng bản Web), [26](26_Ads_Placements.md).
- Nguồn yêu cầu: ảnh tham chiếu có dải khoanh đỏ giữa HUD và đường đua, gồm 3 hàng chấm, đa số xanh, rải chấm màu khác.

---

## 1. Mục tiêu

1. Người chơi **nhìn thấy** doanh thu/giây đến từ ai: đã có câu "Khán giả trả tiền mỗi giây" nhưng khung đua chưa có khán giả nào.
2. Nâng cấp **Grandstands** có phản hồi thị giác ngay: lên cấp thì khán đài đông hơn.
3. Đua có **sức sống** (khán giả reo khi ta vượt, ồ lên khi xe lỗi) mà không thêm luật, không che đường, không tốn hiệu năng.

Không làm: khán giả ảnh hưởng kết quả đua; khán giả có tiền riêng; bấm vào từng khán giả để nhận thưởng. (Riêng **lá cờ thưởng income** chạy trên dải này, xem [26 §4](26_Ads_Placements.md): đó là một control riêng, không phải khán giả.)

---

## 2. Bố cục

```
┌──────────────────────────────────────────┐
│ ĐỘI CỦA BẠN        P5/10          (HUD)  │  HUD_H  = 60 px (giữ nguyên)
├──────────────────────────────────────────┤
│ ● ●● ●●● ● ●● ●●● ● ●● ●●●  ● ●●         │  hàng 1 ┐
│ ●● ● ●●●● ● ●●  ●● ●● ●  ●●● ●           │  hàng 2 ├ STAND_H = 44 px
│ ● ●●● ● ●● ●●● ●  ●●● ●● ● ●●            │  hàng 3 ┘
├──────────────────────────────────────────┤
│            đường đua                      │  _top = HUD_H + STAND_H
└──────────────────────────────────────────┘
```

- Dải khán đài rộng bằng khung, **nằm giữa HUD và đường**; nền xám-xanh nhạt `#a9b8d0` có hai vạch ngăn hàng mờ, góc dưới bo nhẹ.
- `RaceView._top` đổi từ `HUD_H` thành `HUD_H + STAND_H`. Đường đua co lại khoảng 44 px chiều cao; `_on_resized` đã tự tính lại tỉ lệ nên không đổi logic khác.
- Màn thấp (khung đua cao < 300 px): thu về **2 hàng, STAND_H = 30 px**. Không bao giờ chiếm quá 18% chiều cao khung.
- Trước khi đua (countdown) và khi `sim == null`: vẫn vẽ khán đài (đứng yên, hơi lắc nhẹ) để khung không trống.

---

## 3. Khán giả là gì

Mỗi khán giả là **một chấm tròn nhỏ** (bán kính 3 px, hàng sau 2,5 px để ra cảm giác xa), cùng ngôn ngữ chấm với xe nên không cần art mới.

**Màu.** Khoảng 70% chấm màu xanh áo đội ta `#3a78d6`. Phần còn lại lấy từ `DOT_COLORS` của đối thủ (cam dành riêng cho xe người chơi nên **không dùng cam** cho khán giả, tránh nhầm với xe ta). Màu từng chỗ ngồi **cố định theo seed** `hash(track_id, chỗ_ngồi)`, nên không nhấp nháy khi vẽ lại và mỗi track có một "đám đông" riêng.

**Mật độ theo Grandstands.** Số chấm không bằng số "sức chứa" thật vì sức chứa là BigNumber có thể rất lớn. Dùng thang lôga:

```
fill = clamp(log10(capacity / 10) / log10(CAP_FULL / 10), 0.12, 1.0)
so_cho_hien = round(TOTAL_SEATS × fill)
```

| Grandstands | Khán đài |
|---|---|
| Cấp 0 (sức chứa 10) | ~12%: thưa, nhiều chỗ trống, các cụm lẻ loi |
| Giữa | Lấp dần **từ giữa ra hai bên**, rồi lên hàng sau |
| `CAP_FULL` | Kín 3 hàng |

- `TOTAL_SEATS` ≈ `size.x / 9` chấm mỗi hàng, tức khoảng 40 chấm/hàng ở khung 360 px.
- Thứ tự lấp chỗ cố định (xáo theo seed một lần), nên **lên cấp chỉ thêm chấm, không đổi chỗ chấm cũ**.
- Lên bậc kinh doanh mới (cơ sở mới, [12](12_BigNumber_Economy.md)): Grandstands về cấp 0 nên khán đài **thưa lại**, đúng với "cơ sở mới". Đổi màu nền dải theo bậc (xem §7) để người chơi thấy đây là sân khác.

**Lên cấp có hiệu ứng.** Khi `grandstands` tăng: các chấm mới "nảy lên" (scale 0 → 1,3 → 1, 0,25 giây, so le 20 ms) và một vệt sáng chạy ngang dải. Gộp nhiều lần bấm liên tiếp: chỉ chạy một hiệu ứng.

---

## 4. Phản ứng theo diễn biến đua

Nguồn tín hiệu duy nhất: `sim.events` (đã qua `pump_events`), loại `pass` và `error` (`traffic_sim.gd:100`). Khán giả **chỉ phản ứng, không quyết định**.

| Sự kiện | Phản ứng | Thời lượng |
|---|---|---|
| Xe **ta** vượt xe khác | Các chấm **nhảy lên** (tung độ −3 px, so le), vài chấm đổi trắng như "vẫy tay"; số chấm nhảy tỉ lệ độ hưng phấn | 1,1 giây (bằng `FX_PASS`) |
| Xe **ta** bị vượt | Chấm **cúi xuống** (+1,5 px) và mờ đi 20% | 0,8 giây |
| Xe **ta** lỗi (`error`) | Cả dải **giật nhẹ ngang** 1 lần, chấm tối lại | 0,6 giây |
| Đối thủ vượt nhau / lỗi | Không phản ứng (tránh ồn; đám đông cổ vũ đội ta) | — |
| Ta lên hạng 1 | Cả dải nhảy nhịp, **confetti vàng/trắng** rơi 1 giây | 1,5 giây |
| Hết giờ, nhận thưởng | Dải rực lên một nhịp cùng chữ "HẠNG X" | 0,6 giây |

**Độ hưng phấn `h` (0–1)** là một số trượt: +0,35 mỗi lần ta vượt, +0,5 khi lên hạng 1, giảm về 0 theo hằng 0,6/giây. Khi nghỉ, `h` = 0 và khán đài chỉ có **chuyển động nền rất nhẹ** (mỗi chấm lệch ±0,6 px theo sin pha riêng, chu kỳ 1,5–2,5 giây). `h` chỉ là trạng thái vẽ, không lưu save, không đưa vào sim.

**Âm thanh (nếu có bus SFX):** một tiếng reo ngắn khi ta vượt (đã có tiếng vượt thì dùng chung, không thêm tiếng thứ hai). Không có tiếng nền liên tục ở v1.

---

## 5. Gắn với kinh tế

- **Chỉ hiển thị**, công thức doanh thu giữ nguyên ([12 §4](12_BigNumber_Economy.md)): thu nhập = (Ticket + Celebration + Parking) × sức chứa / 10.
- **Chạm vào dải khán đài** mở chú thích 3 giây: `Khán đài · sức chứa 25 · thu nhập ×2,5` (lấy từ `Pricing.revenue_value("grandstands", level)` và định dạng BigNumber có sẵn). Chạm lần nữa hoặc chạm nơi khác thì đóng. Không có nút nâng cấp trong chú thích để khỏi lặp lưới nâng cấp; chỉ có dòng nhỏ "Nâng cấp ở ô Grandstands" khi tài khoản đủ tiền mua cấp kế.
- **Ô Grandstands trong lưới nâng cấp** giữ nguyên; thêm hiệu ứng ở §3 làm phản hồi khi mua. Khi mua từ ô, dải khán đài nằm ngay phía trên nên người chơi thấy thay đổi cùng lúc.
- **Lá cờ thưởng income** ([26 §4](26_Ads_Placements.md)) chạy từ trái sang phải trên dải này. Nó là một control con riêng của `RaceView` (không vẽ trong `_draw` mỗi khung), vùng chạm của lá cờ **ưu tiên hơn** chú thích sức chứa ở trên; chạm chỗ khác trên dải vẫn mở chú thích. Lá cờ không đổi bố cục hay mật độ khán giả.

---

## 6. Hướng dẫn (tutorial)

[23](23_Tutorial_Script.md) có câu "Khán giả trả %s tiền mỗi giây". Đề xuất:

- Bước đó **spotlight dải khán đài** (như spotlight xe ở `player_marker()`), thêm `RaceView.stand_rect()` trả hình chữ nhật dải (tọa độ cục bộ) cho `tutorial_overlay`.
- Không thêm bước mới. Chỉ đổi đích spotlight của bước hiện có.

---

## 7. Phong cách và art

- Phong cách cartoon xanh/cam/vàng đã chốt: chấm phẳng, viền tối 1 px ở hàng trước, **không bóng đổ phức tạp**.
- Nền dải theo bậc kinh doanh `b`: b0 xám-xanh `#a9b8d0`; các bậc sau dùng sắc khác nhau, bảng màu đề xuất (duyệt cùng art): b1 `#b8c9a6`, b2 `#d3c2a2`, b3 `#c4b0d6`, b4 `#a6d0cf`, b5 `#e2c36b`.
- **Phản ứng khán giả đã dùng icon ảnh (12/11/2026), người dùng chọn phương án B:** bong bóng cảm xúc có đuôi hướng xuống, mắt chấm và nét miệng tối giản. Bốn PNG RGBA 128×128 tại `assets/racing_ui_hd/icons/reactions/`, đăng ký trong `assets/racing_ui_hd/manifest.json`. `face_happy.png` dùng khi xe ta vượt; `face_sad.png` dùng khi xe ta bị vượt hoặc lỗi. `face_angry.png` và `face_wow.png` là art dự phòng, chưa gắn sự kiện.
- `RaceView` cache texture vui/buồn một lần, vẽ bằng `draw_texture_rect`; nếu thiếu một texture thì riêng biểu cảm đó quay về cách vẽ bằng code. Giữ vị trí ngẫu nhiên trong dải, scale pop, bay lên 5 px, mờ dần, `FACE_LIFE = 1.2`, `FACE_MAX = 10`; kích thước nền `2 × FACE_R = 20 px` gồm cả đuôi, phần mặt khoảng 16 px. Các chấm khán giả và nền khán đài vẫn vẽ bằng code; không đổi sim, kinh tế hay save.

---

## 8. Kỹ thuật

**Hiệu năng (bản Web, theo [25 §7.5](25_Ads_Lumber_Reference.md)).** Vẽ 120 chấm bằng `draw_circle` mỗi khung là quá đắt trong GDScript. Cách làm:

1. Dựng **một lần** (khi đổi kích thước/track/cấp Grandstands) mảng vị trí `PackedVector2Array` và màu `PackedColorArray` của mọi chỗ ngồi.
2. Phần **tĩnh** (nền dải, chấm khi `h = 0`) đưa vào **`TrackLayer`** cùng mesh tĩnh hiện có, một lệnh vẽ.
3. Phần **động** chỉ vẽ khi `h > 0` hoặc đang có hiệu ứng: dùng một `MultiMeshInstance2D` cho chấm (cập nhật `transform` từng thể hiện) hoặc `draw_multimesh`. Giới hạn **tối đa 160 chấm động** mỗi khung. Khi nghỉ, nhịp "thở" nền dùng **một** shader nhỏ lệch pha theo `INSTANCE_ID` thay vì cập nhật từ GDScript.
4. Ngân sách: thêm ≤ 0,3 ms/khung trên máy yếu; nếu `Engine.get_frames_per_second() < 30`, tắt chuyển động nền và chỉ giữ nhảy khi vượt.

**API đề xuất trong `RaceView`:**

```gdscript
const STAND_H := 44.0
var grandstand_fill: float = 0.12     # 0..1, do main.gd cập nhật khi đổi cấp
var crowd_mood: float = 0.0           # độ hưng phấn h, chỉ để vẽ
func set_grandstands(capacity: BigNumber) -> void   # tính fill, dựng lại chỗ ngồi
func stand_rect() -> Rect2                           # cho tutorial/chú thích
```

`pump_events()` đã trả các sự kiện mới: dùng chính nó để cộng `crowd_mood`, không thêm vòng đọc `sim.events` thứ hai.

**Dữ liệu.** Để `const` đầu `race_view.gd` như các hằng số hiện có (`HUD_H`, `FX_PASS`…): `STAND_H`, `CAP_FULL`, `BLUE_SHARE`, `SEED_SALT`; chưa cần file JSON mới. Không đưa vào `economy.json` vì không phải số kinh tế.

**Save.** Không thêm trường. Mọi thứ suy ra từ `levels["grandstands"]`, `tier` và `track_id`.

**Giảm chuyển động.** Dùng cờ `--reduce-motion` như `ui/loading.gd`: khán giả đứng yên, chỉ đổi mật độ và màu; phản ứng sự kiện thay bằng **đổi màu sáng/tối** một nhịp, không nhảy, không confetti, không giật.

---

## 9. Kiểm thử

Sau khi chọn B: đã import lại bộ bong bóng, chạy chụp game và xem `Design/Previews/reactions/b_2_racing.png`; preview kích thước nhỏ và fallback tiếp tục đạt (`b_preview.log`). Hash manifest đã cập nhật cho cả bốn PNG.

Kiểm tra icon ảnh ngày 12/11/2026 bằng Godot 4.7.2: `tests/traffic_test.gd` và `tests/state_test.gd` headless đều **0 lỗi**. Đã chạy `--shot=.../sp --auto-race --fast` và xem `Design/Previews/reactions/sp_2_racing.png`; mặt vui hiện rõ trong dải khán đài. Preview riêng `size_check.png` kiểm tra đủ bốn icon ở 16/20 px, mặt vui/buồn, mờ dần và hết hạn; `fallback_check.png` kiểm tra vẽ bằng code khi cache không có texture. Bốn PNG được kiểm tra RGBA 128×128, có nền trong suốt và SHA-256 khớp manifest. Lần chụp game thoát mã 0 nhưng có cảnh báo rò RID/ObjectDB khi thoát; chưa xác định nguyên nhân. Các lần chạy dùng thư mục dữ liệu riêng.

| Kiểm thử | Mong đợi |
|---|---|
| `fill` cấp 0, cấp trung bình, `CAP_FULL`, vượt `CAP_FULL` | 0,12 / đơn điệu tăng / 1,0 / vẫn 1,0, không lỗi với BigNumber rất lớn |
| Tăng cấp rồi dựng lại chỗ ngồi | Chấm cũ giữ nguyên vị trí và màu; chỉ thêm chấm mới |
| Cùng `track_id` mở lại | Cùng đám đông (seed ổn định) |
| Xe ta vượt 3 lần liên tiếp | `crowd_mood` ≤ 1, giảm về 0 sau ~2 giây, không phình bộ nhớ |
| Đối thủ vượt nhau | Khán đài không phản ứng |
| Đổi kích thước / xoay màn | Không lỗi, số chấm/hàng tính lại, `_top` đúng, đường không bị che |
| `--reduce-motion` | Không chuyển động; mật độ và màu vẫn đúng |
| Khung đua thấp (< 300 px) | Dải 2 hàng 30 px; không vượt 18% chiều cao |
| Đo khung hình bản Web | ≤ 0,3 ms thêm; không tụt dưới ngân sách [25 §7.5](25_Ads_Lumber_Reference.md) |

---

## 10. Phân kỳ triển khai

| Giai đoạn | Nội dung | Ước lượng |
|---|---|---|
| **P0** | Dải tĩnh: `STAND_H`, `_top`, chỗ ngồi theo seed, mật độ theo Grandstands, vẽ trong `TrackLayer` | Nhỏ |
| **P1** | Phản ứng: `crowd_mood`, nhảy khi vượt, cúi khi bị vượt, giật khi lỗi, nhịp lên hạng 1 | Nhỏ–vừa |
| **P2** | Hiệu ứng lên cấp, chú thích khi chạm, spotlight tutorial, `--reduce-motion` | Nhỏ |
| **P3** | Màu nền theo bậc, confetti, tiếng reo, (tùy chọn) chấm VIP | Song song với art |

---

## 11. Câu hỏi cần chốt

1. **Chiều cao dải**: 44 px (3 hàng) như ảnh tham chiếu, hay gọn hơn 30 px (2 hàng) để nhường chỗ cho đường?
2. **Phản ứng khi bị vượt/lỗi**: giữ (tạo cảm xúc) hay chỉ reo khi thắng (đơn giản, tích cực)?
3. **Chạm vào khán đài** hiện chú thích sức chứa: đồng ý, hay chỉ trang trí?
4. **Khán đài thưa lại khi mở bậc mới** (theo `Grandstands` về cấp 0): đồng ý, hay giữ đám đông đông và chỉ đổi màu nền?
5. Dùng **chấm tròn** (đồng bộ chấm xe) hay **hình người đơn giản** (đầu + vai như `_draw_team_icon`) cho khán giả? Đề xuất chấm tròn ở v1 vì nhẹ và đồng bộ.
