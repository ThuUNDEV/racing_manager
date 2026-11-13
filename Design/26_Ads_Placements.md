# 26 — Vị trí đặt quảng cáo (v1)

- Ngày: 12/11/2026
- Trạng thái: **đề xuất để duyệt, chưa triển khai UI.** Phần nền (`Ads`, provider Horus, bản Web) đã xong, xem [25](25_Ads_Lumber_Reference.md) §7.
- Liên quan: [05 §7](05_Economy_Monetization.md), [03 D4](03_Release_Overview.md), [06](06_UI_UX_Release.md), [22](22_Race_Classes.md), [23](23_Tutorial_Script.md).
- Nguồn yêu cầu (12/11/2026): người thiết kế chọn 5 tính năng: **Ads Break, tăng tốc ×2, gem miễn phí mỗi ngày, thẻ quay miễn phí (tay đua và gear), thưởng income.**

---

## 1. Quyết định đã chốt và hệ quả

| Quyết định | Hệ quả |
|---|---|
| **Thêm interstitial (Ads Break)** | Đổi D4 ("chỉ rewarded, không interstitial"). Đã ghi chú vào 03, 05, 02 (xem §10). Ads Break chỉ xuất hiện **giữa hai lượt đua**, không bao giờ trong lúc đua |
| Danh sách 5 tính năng thay danh sách 4 vị trí của 05 §7.1 | Bỏ "thêm tiền sau lượt đua": thưởng một lượt chỉ bằng khoảng **10–13 giây thu nhập** (đo ở tốc độ 8/giây, lượt dài 34,8 giây), không đáng một lần xem |
| Trần rewarded/ngày | 05 đặt 8. Danh sách mới có tối đa 2 + 3 + 5 + 1 + 1 = 12 lượt, nên **nâng trần lên 12**. Ads Break (interstitial) không tính vào trần này |
| "Bỏ quảng cáo" (đã có trong Shop, 263.000đ) | Chính là gói "Đội tự do" ở 05 §7.2: người mua **nhận thẳng** mọi thưởng rewarded và **không bao giờ gặp Ads Break**. Cờ `ad_state.free` đã có |

---

## 2. Bản đồ vị trí

```
Tab ĐUA  ┌ dải chặng ─────────── [Lịch] [Class] ┐
         │ HUD                                   │
         │ DẢI KHÁN ĐÀI  🚩→→→                   │  <- Lá cờ thưởng income (§4)
         │ đường đua, xe                         │
         ├───────────────────────────────────────┤
         │ ▶ DẢI HÀNH ĐỘNG (mới, §3)             │  <- Tăng tốc ×2
         ├───────────────────────────────────────┤
         │ lưới nâng cấp …                       │
Tab TÚI  │ thẻ gói gear: [Mở ×1] [Mở ×10]       │  <- nút "Coupon miễn phí" (§6)
Tab ĐỘI  │ thẻ gói tay đua: …                    │  <- nút "Coupon miễn phí" (§6)
Tab SHOP │ QUÀ HẰNG NGÀY                         │
         │ TRANG BỊ & TAY ĐUA: 2 thẻ miễn phí    │  <- §6 (chỗ giữ sẵn "Xem video – Sắp có")
         │ GEM: thẻ đầu "Xem video"              │  <- §5 (chỗ giữ sẵn)
Giữa lượt │ Ads Break                            │  <- §7
```

Dấu chấm đỏ trên tab **Shop** và **Túi/Đội** khi có mục miễn phí đang sẵn sàng (cùng kiểu dấu cho quà hằng ngày). Mọi vị trí **chỉ hiện sau khi tính năng chứa nó đã mở** theo tutorial (§8).

---

## 3. Tăng tốc ×2 (`income_boost`)

**Vị trí.** Dải hành động dưới khung đua, tab Đua (ô trái). Dải này **không chiếm chỗ khi không có gì để hiện**.

```
┌─────────────────────────────────────────────┐
│ [▶ ×2 THU NHẬP · 30 phút]                       │
└─────────────────────────────────────────────┘
```

**Luật**
- Xem 1 quảng cáo → **×2 thu nhập trong 30 phút chơi**. Tối đa **3 lần/ngày**, không cộng dồn thời gian (đang chạy thì nút đổi thành đồng hồ).
- **Áp dụng:** thu nhập online (`tick_income`) và tiền thưởng đua (tính theo rate). **Không áp:** thu nhập offline (vẫn theo `saved_online_rate` gốc), quà hằng ngày.
- **Đồng hồ chỉ chạy khi đang chơi** (không ra nền, không đang xem quảng cáo), lưu trong save dưới dạng số giây còn lại. Như vậy người chơi không mất thưởng khi tắt app.
- **Không nhân với gói mua:** hệ số hiệu lực = max(boost quảng cáo, hệ số đã mua). Shop đang bán "THU NHẬP X2/X3" (131.000đ/263.000đ). Đã sở hữu ≥ ×2 thì **ẩn nút** (không mời xem quảng cáo thừa); chỉ ×2 quảng cáo không thay ×3 đã mua.
- Giá trị: nếu chơi đủ 30 phút, mỗi lần xem tương đương **+30 phút thu nhập**.

**Trạng thái nút:** sẵn sàng `▶ ×2 · 30 phút` → đang chạy `×2 · 24:10` (không bấm được) → hết lượt ngày `Mai nhận tiếp` (ẩn khỏi dải, chỉ còn ở Shop nếu sau này thêm) → chưa có quảng cáo `Đang tải…` (xám, tự thử tải lại) → mất mạng `Cần Internet`.

---

## 4. Thưởng income: lá cờ chạy trên khán đài (`flag_cash`)

> **Đã chốt 12/11/2026 (theo mô tả của người thiết kế):** sau một thời gian, một **lá cờ chạy từ trái qua phải** trên dải khán đài ([27](27_Spectators.md)). Chạm vào lá cờ mở popup: người chơi **chọn xem quảng cáo để nhận thưởng, hoặc tắt đi**. Xem xong hay tắt đi thì **lá cờ mất**. Không làm "gấp đôi offline" ở v1.

**Hình thức.** Một khán giả cầm cờ (hoặc chỉ lá cờ có sóng, tuỳ art) chạy dọc dải khán đài, từ mép trái đến mép phải trong khoảng **14 giây**, tốc độ đều. Vùng chạm lớn hơn hình vẽ (≥ 48 × 44 px, phủ hết chiều cao dải) để dễ bấm khi đang chạy. Lá cờ là **một control riêng** nằm trên dải, không vẽ trong `_draw` của `RaceView` (giữ ngân sách hiệu năng của 25 §7.5); chuyển động bằng một tween vị trí, không dùng `_process`.

**Luồng**
```
lá cờ xuất hiện ở mép trái, chạy sang phải
   ├ không chạm → ra khỏi mép phải, mất (không phạt, không tính lượt)
   └ chạm → lá cờ biến mất ngay, mở popup
        ┌──────────────────────────────┐
        │ 🚩 CỜ KHÁN GIẢ               │
        │ Khán giả tặng bạn            │
        │ 💵 +4,8K tiền                │
        │ [▶ Xem video nhận +4,8K]     │
        │ [ Tắt ]                      │
        └──────────────────────────────┘
        ├ Xem hết quảng cáo → cộng thưởng, hiệu ứng tiền bay, đóng popup
        ├ Đóng quảng cáo sớm → không thưởng, đóng popup (lá cờ đã mất)
        └ Tắt → đóng popup (lá cờ đã mất)
```

**Luật**
- **Chỉ có hai kết cục**: nhận thưởng hoặc mất. Không có lần thứ hai cho cùng một lá cờ.
- **Lịch xuất hiện:** lần đầu sau **60 giây** chơi; sau khi lá cờ mất (chạm hay ra mép) thì **chờ 120 giây** mới có lá kế. Tối đa **5 lần nhận/ngày**. Bỏ lỡ liên tiếp: từ lá thứ 3 trở đi khoảng chờ nhân đôi mỗi lá (lá 3 chờ 240 giây, lá 4 trở đi chờ 480 giây là trần), về 120 giây ngay khi người chơi chạm lại.
- **Thưởng = 10 phút thu nhập hiệu lực** (cùng thang với quà hằng ngày 600 giây): `+4,8K` ở 8 tiền/giây, tự lớn theo tiến trình. **Không nhân ×2 khi boost đang chạy**: đây là một lượng cash cố định tính theo thu nhập gốc. Số tiền hiện sẵn trên popup.
- **Chỉ tạo lá cờ khi quảng cáo dùng được** (đã tải sẵn, hoặc người chơi có "Đội tự do"), để không bao giờ mời người chơi vào một popup không có quảng cáo.
- **Không tạo khi:** tính năng chưa mở (`U4_shop`), đã đủ 5 lần hôm nay, đang hiện bảng kết quả/offline/popup khác, tutorial đang giữ màn hình, đang Ads Break, app `suspended`.
- **Trường hợp lỗi (popup đang mở, lá cờ chưa tính là đã dùng cho tới khi có kết cục):**
  - Chưa có quảng cáo / mất mạng: popup hiện `Chưa có quảng cáo` hoặc `Cần Internet`; người chơi bấm Tắt thì lá cờ mất, không tính lượt.
  - Xem xong nhưng **lưu lỗi** (`failed`): giữ popup, nút đổi thành `Thử nhận lại`; bấm thì nhận lại thưởng **không phải xem lại quảng cáo** (AdsService giữ "thưởng chờ nhận" trong bộ nhớ tới khi popup đóng).
- **Đội tự do:** nút đổi thành `Nhận +4,8K`, không mở quảng cáo, vẫn tính 5 lần/ngày.
- **Tương tác với dải khán đài:** chạm đúng vùng lá cờ thì lá cờ ăn chạm; chạm chỗ khác trên dải vẫn là chú thích sức chứa ([27 §5](27_Spectators.md)). Phản ứng mặt vui/buồn của khán giả vẫn vẽ bình thường bên dưới.
- **Màn thấp (dải 2 hàng):** lá cờ giữ nguyên, vùng chạm cao tối đa bằng dải cộng 8 px để không đè lên đường đua.
- **`--reduce-motion`:** lá cờ không chạy; hiện **đứng yên giữa dải trong 8 giây** (chớp nhẹ) rồi mất.
- **Lần đầu xuất hiện:** một dòng gợi ý nhỏ `Chạm vào cờ để nhận thưởng` (một lần duy nhất, lưu cờ trong save).

---

## 5. Gem miễn phí mỗi ngày (`free_gems`)

**Vị trí.** Shop, mục GEM, **thẻ đầu tiên** (hiện đã có chỗ giữ "10 gem — Xem video"; đổi lại số liệu theo bảng dưới).

**Luật**
- **5 gem/lần xem, tối đa 2 lần/ngày, cách nhau 12 giờ** (đã khai báo trong `data/ads.json`). Thay con số 10 của chỗ giữ cũ.
- Hết lượt hiện `Mai nhận tiếp`, đang chờ hiện `Còn 11:59:03` (đếm ngược).
- Cộng gem qua `GameState` trong một giao dịch save (đã có, `AdsService._claim`).

**Giá trị và rủi ro cần xem lại sau soft launch.** 1 coupon quay = 10 gem. Gem bán 100 gem = 52.000đ (≈ 520đ/gem), tức 5 gem ≈ 2.600đ, trong khi một lượt xem rewarded ở Việt Nam thường chỉ mang về vài trăm đồng. Tức mỗi gem free "rẻ" hơn gem mua nhiều lần. Lượng gem free/ngày là:

| Nguồn | Gem tương đương/ngày |
|---|---|
| Quà hằng ngày (đã có) | 5 |
| Gem miễn phí (2 × 5) | 10 |
| Coupon tay đua miễn phí (1 coupon) | 10 |
| Coupon gear miễn phí (1 coupon) | 10 |
| **Tổng** | **≈ 35 gem ≈ 3,5 lượt quay/ngày** |

Nếu doanh thu IAP gem thấp hơn kỳ vọng thì chỉnh theo thứ tự: giảm `amount` gem, tăng `cooldown`, giảm số coupon. Tất cả nằm trong `data/ads.json` nên đổi được bằng Remote Config không cần phát hành lại.

---

## 6. Thẻ quay miễn phí: tay đua và gear (`free_driver_coupon`, `free_gear_coupon`)

**Vị trí (3 chỗ cho mỗi loại, cùng một lượt/ngày):**
1. **Shop → TRANG BỊ & TAY ĐUA:** hai thẻ `TRANG BỊ MIỄN PHÍ`, `TAY ĐUA MIỄN PHÍ` (chỗ giữ sẵn "Xem video — Sắp có").
2. **Tab Túi:** trên thẻ gói **STANDARD GEAR**, nút phụ `Coupon miễn phí · Xem video` (cạnh số "Coupon: n").
3. **Tab Đội, mục gói tay đua:** trên thẻ **PRO PACK**, nút phụ tương tự.

Cùng một lượt/ngày cho cả ba nơi của mỗi loại (xem ở đâu cũng được, dùng một lần).

**Luật**
- **1 coupon `standard` (gear)** và **1 coupon `pro` (tay đua)** mỗi loại **1 lần/ngày**. Coupon được cộng vào kho (`gear_coupons`, `driver_coupons`, qua `grant_*_coupons` đã có), người chơi tự bấm "Mở ×1" như coupon thường.
- Coupon free **không** có gói Elite/All-Star: chỉ gói thường, để gói cao vẫn có giá trị mua.
- Coupon free tính vào **bộ đếm bảo đảm** như mọi lượt mở khác (không phân biệt cách trả).
- Hiện toast `+1 Coupon Pro` sau khi nhận, và dấu chấm đỏ tắt.
- Mở khóa cùng tính năng chứa nó: Gear sau mốc `U3_bag`, tay đua sau `U5_drivers` (nút phụ ở Túi/Đội không hiện trước đó; thẻ ở Shop ẩn hoặc khóa theo tutorial).

---

## 7. Ads Break (interstitial xen giữa các lượt)

**Mục tiêu:** một quảng cáo toàn màn hình có đền bù, chỉ ở **khoảng nghỉ tự nhiên giữa hai lượt**, không bao giờ làm gián đoạn lượt đang đua.

**Luồng**
```
lượt đua kết thúc → lưu → bảng kết quả (2 giây)
   → [Ads Break đủ điều kiện?]
        không → countdown lượt kế như cũ
        có   → thẻ "Tạm nghỉ quảng cáo · +720 sau khi xem" (1,5 giây, không bấm được)
             → phát interstitial
             → đóng xong: cộng thưởng + hiệu ứng tiền bay → countdown lượt kế
```
Countdown lượt kế đứng yên trong lúc này (dùng cơ chế `result_hold` và `ad_pause` đã có).

**Điều kiện (tên và ý nghĩa theo `monetize.interDue` của Horus SDK, để dùng chung khoá Remote Config `ads_*`):**

| Khoá | Giá trị | Ý nghĩa |
|---|---|---|
| `interFromRun` | 8 | Chỉ sau khi người chơi đã hoàn tất ≥ 8 lượt **và** xong tutorial |
| `sessionWarmup` | 120 giây | Không trong 2 phút đầu phiên; cũng không trong 2 phút sau khi mở lại từ nền |
| `interEvery` | 8 | Cách tối thiểu 8 lượt kể từ Ads Break trước (≈ 5,3 phút chơi) |
| `interCooldown` | 420 giây | Cách tối thiểu 7 phút giữa hai Ads Break |
| `rewardedGrace` | 60 giây | Không ngay sau khi người chơi vừa xem một rewarded |
| `maxPerHour` (mới) | 6 | Trần cứng mỗi giờ |
| `firstPlayMin` (mới) | 15 phút | Không trong 15 phút chơi đầu đời |
| `bonusIncomeSec` (mới) | 90 giây | Đền bù = 90 giây thu nhập hiệu lực (≈ 7 lượt đua ở tốc độ 8/giây), hiện số tiền trước khi phát |

**Chặn tuyệt đối (không bao giờ hiện):** đã mua "Bỏ quảng cáo" (`ad_state.free`); tutorial đang chạy; có popup/overlay/bảng offline/trang hồ sơ đang mở; `save_error`; app đang `suspended`; không có mạng; chưa có interstitial tải sẵn (`platform.ads.ready().inter`); người chơi **vừa chạm màn hình trong 1,2 giây gần nhất** (chờ tối đa 3 giây, quá thì bỏ qua lượt này) để tránh bấm nhầm vào quảng cáo.

**Khi không phát được:** nếu interstitial báo không hiện (`shown: false`) hoặc quá **90 giây** không có kết quả thì **không cộng thưởng, không tính cooldown**, tiếp tục countdown. Thưởng chỉ phát sau khi quảng cáo đóng, ID `ad/break/n<lượt>` chống nhận trùng.

**Tần suất ước tính:** 1 lần mỗi khoảng 7 phút chơi liên tục, tối đa 6 lần/giờ. Vì đây là game idle (người chơi để máy chạy), nên đặt thưa hơn mặc định của SDK (cooldown 120 giây). Đo `D1`, `D7`, số phiên/ngày và tỷ lệ gỡ cài đặt theo từng nhóm để chỉnh qua Remote Config.

**Rủi ro chính sách:** Google Play không cho quảng cáo xuất hiện bất ngờ khi người chơi đang thao tác hoặc ngay khi mở app. Các điều kiện trên (khoảng nghỉ giữa lượt, 2 phút đầu phiên, chờ không chạm, thẻ báo trước) nhằm giữ đúng điều đó. Cần đọc lại chính sách hiện hành trước khi phát hành (05 §8), và D10 vẫn là 12+, không nhắm trẻ em.

**Cần xác minh trong app thật:** `platform.ads.inter()` có trả kết quả **sau khi quảng cáo đóng** hay ngay khi hiện. Nếu là ngay khi hiện thì dùng cặp `pause`(`ad`)/`resume` làm tín hiệu đóng. Trên bản Web giả lập, lớp phủ quảng cáo phải có một nút "Đóng".

---

## 8. Mở khóa theo tutorial

| Vị trí | Mở khi | Id trong `data/tutorial.json` |
|---|---|---|
| Tăng tốc ×2, lá cờ khán đài | sau khi mở Shop | `U4_shop` |
| Gem miễn phí | sau khi mở Shop | `U4_shop` |
| Coupon gear miễn phí | sau khi mở Túi | `U3_bag` |
| Coupon tay đua miễn phí | sau khi mở Đội/tay đua | `U5_drivers` |
| Ads Break | xong tutorial **và** ≥ 8 lượt | (`tutorial.state == "done"`) |

Không vị trí nào xuất hiện trong lúc một bước tutorial đang giữ màn hình.

---

## 9. Quy tắc hiển thị chung

- **Nút nêu rõ phần thưởng**: `▶ ×2 thu nhập · 30 phút`, `+5 gem`, `+4,8K tiền`, `+1 Coupon Pro`. Không có nút "Xem video" mơ hồ.
- **Trạng thái:** sẵn sàng / đang tải (xám, tự tải lại) / cần Internet / đang chờ (đếm ngược) / hết lượt hôm nay / **nhận thất bại** (`Không nhận được, thử lại`: xem xong mà lưu lỗi, thử lại **không** mất lượt).
- **Dải hành động và chip trên tab Đua: ẩn khi không khả dụng.** **Thẻ trong Shop: luôn hiện, kèm trạng thái.**
- **Đội tự do**: nút bỏ biểu tượng video, chữ `Nhận`, vẫn tính trần ngày.
- **Không popup quảng cáo tự bật** ngoài Ads Break; mọi quảng cáo rewarded do người chơi bấm. Popup *bán hàng* (IAP) tự hiện theo hàng đợi chung ở [28 §5b](28_IAP_Packs.md): ưu tiên cao hơn lá cờ khán đài và Ads Break, nên lá cờ không tạo và Ads Break không hiện khi có popup bán hàng đang mở (đã nằm trong các điều kiện chặn "popup khác" ở trên).
- **Analytics** (qua `Ads.ad_event`): `rv_offer` (chip/thẻ hiện, không quá 1 lần/phút mỗi placement), `rv_start`, `rv_done`, `rv_fail` (+ `reason`), `inter_show` (placement `ad_break`), `inter_skip` (+ `why` theo `InterWhy`: `warmup`, `cooldown`, `every`, `early`, `rewarded`, `blocked`, `no_ads`), `boost_start`, `boost_end`.
- **Đặt tên placement** (chữ thường, không dấu; khai báo ở `horus-game.json`): `income_boost`, `flag_cash`, `free_gems`, `free_driver_coupon`, `free_gear_coupon`, và interstitial `ad_break`.

---

## 10. Thay đổi tài liệu cũ

| Tài liệu | Sửa |
|---|---|
| [03 §D4](03_Release_Overview.md) | Đổi thành "Rewarded tự nguyện + Ads Break xen kẽ giữa các lượt đua, không banner; người mua 'Bỏ quảng cáo' không thấy" |
| [05 §7.1](05_Economy_Monetization.md) | Thêm ghi chú: bảng vị trí và trần 8/ngày thay bằng 26 (trần 12, thêm Ads Break) |
| [02 §thương mại hoá](02_Gameplay_Design.md) | Câu "Không ép quảng cáo giữa các chặng" không còn đúng: sửa theo §7 |
| [06](06_UI_UX_Release.md) | Bỏ dòng "nút quảng cáo phụ sau lượt đua" |
| [25 §3](25_Ads_Lumber_Reference.md) | Bảng ánh xạ cũ (7 vị trí) thay bằng 26; `data/ads.json` cập nhật theo §11 |

---

## 11. Thay đổi dữ liệu và code khi triển khai

**`data/ads.json`:** `daily_cap` 12; placement mới `free_driver_coupon` (`reward: driver_coupon`, `kind: pro`, 1/ngày, mở `U5_drivers`), `free_gear_coupon` (`gear_coupon`, `standard`, 1/ngày, `U3_bag`), `flag_cash` (đổi tên từ `vip_pit`; `income_seconds: 600`, 5/ngày, `first_after_sec` 60, `gap_sec` 120, `cross_sec` 14), `income_boost` (`boost`, `multiplier` 2, `duration_sec` 1800, 3/ngày), cụm `break` với các khoá ở §7. Bỏ `race_bonus`, `daily_double`, `offline_double` khỏi v1 (đã chốt, §13 điểm 1).

**`AdsService`:** thêm kiểu thưởng `income_seconds`, `driver_coupon`, `gear_coupon`, `boost`; trạng thái lá cờ (hẹn giờ xuất hiện, số lần bỏ lỡ, "thưởng chờ nhận" để thử lại không phải xem lại); bộ đếm Ads Break (`inter`, `interRun`, `lastInter`, `lastRewarded` như `PacingState` của SDK); API `try_show_interstitial`.

**`GameState`:** `income_boost_left` (giây, lưu), `income_multiplier()` áp ở `tick_income` và tiền thưởng đua, không áp ở offline.

**Provider/bridge:** `rmHorus.showInter` -> `platform.ads.inter`, `rmHorus.interReady`; `AdsProvider.show_interstitial`, `is_inter_ready`; lớp phủ giả lập có chế độ interstitial.

**UI:** dải hành động ở `main.gd` (chỉ thêm một hàm dựng và gọi); thẻ trong `shop_page.gd`; nút phụ trong `gear_page.gd`, `driver_roster_page.gd`; thẻ báo trước Ads Break; dấu chấm đỏ.

**Test:** mỗi vị trí có test headless với mock provider; luồng Ads Break có test điều kiện chặn (không hiện trong tutorial, khi popup mở, khi đã mua gói, khi chưa đủ lượt/cooldown); kiểm tra bằng trình duyệt như đã làm ở 25 §7.7.

---

## 12. Thứ tự triển khai đề xuất

| Bước | Nội dung | Vì sao thứ tự này |
|---|---|---|
| P2a | `data/ads.json`, kiểu thưởng mới, `income_boost_left` + `income_multiplier` | **Đã xong 12/11/2026** (§14). Lõi, không cần UI, test headless đầy đủ |
| P2b | Shop: gem free, coupon gear/tay đua free (chỗ giữ sẵn); dấu chấm đỏ | Chỗ đặt sẵn, ít rủi ro nhất, có thể kiểm chứng ngay |
| P2c | Dải hành động (tăng tốc ×2) và lá cờ khán đài + popup | Cần dựng UI mới trên tab Đua; lá cờ phụ thuộc dải khán đài đã có |
| P2d | Nút phụ ở Túi và Đội | Phụ thuộc P2b |
| P2e | Ads Break: bridge/provider interstitial, luật, thẻ báo trước | Nhạy cảm với doanh thu và giữ chân, làm sau khi các rewarded chạy ổn |
| P3 | Art lá cờ (cờ có sóng, khán giả cầm cờ), icon coupon free | Song song |

**Xong khi (mỗi vị trí):** nút hiện đúng điều kiện và đúng số thưởng; xem hết thì nhận một lần; đóng sớm không nhận; hết lượt/đang chờ thì đúng trạng thái; mất mạng thì báo cần Internet; "Đội tự do" nhận thẳng; thưởng không nhận lại sau khi nạp save; sự kiện analytics gửi đủ.


---

## 13. Điểm cần bạn chốt

1. ~~"Thưởng income" là gì?~~ **Đã chốt:** chỉ lá cờ khán đài (§4). `offline_double`, `race_bonus`, `daily_double` bị bỏ khỏi v1 (lõi vẫn còn trong code, chỉ không khai báo placement và không có nút).
2. **Con số thưởng free (§5, §6)** đang là khởi điểm; rủi ro lớn nhất là làm gem free rẻ hơn gem mua. Bạn muốn giữ 5 gem × 2/ngày và 1 coupon mỗi loại, hay thấp hơn?
3. **Tần suất Ads Break (§7):** 1 lần/7 phút, tối đa 6 lần/giờ, đền bù 90 giây thu nhập. Đây là mức thận trọng cho game idle; muốn dày hơn thì giảm `interCooldown`/`interEvery`.
4. **Trần 12 rewarded/ngày (§1)** thay cho 8 của 05.
5. **Boost ×2 không áp cho offline (§3):** chấp nhận hay muốn áp cả offline?


---

## 14. P2a đã làm (12/11/2026)

**Dữ liệu.** `data/ads.json` (schema 1): `daily_cap` 12; 5 placement v1 (`income_boost`, `flag_cash`, `free_gems`, `free_driver_coupon`, `free_gear_coupon`); cụm `break` (chưa dùng, P2e). `GameData.validate()` kiểm tra thêm ads.json: loại thưởng hợp lệ, số dương, `multiplier` nguyên ≥ 2, loại coupon phải có trong `gear.json`/`driver_gacha.json`, `unlock` phải có trong `tutorial.json`, `miss_gap_max_sec` ≥ `gap_sec`. Các kiểu thưởng cũ (`offline_double`, `race_bonus`, `daily_double`) không còn placement nhưng lõi giữ lại và vẫn có test (`tests/ads_test.gd` dùng cấu hình riêng).

**GameState.** `income_boost_left` (giây, lưu trong save, chặn 0..86400, NaN về 0); `income_multiplier()` (1 hoặc hệ số boost). `tick_income` tính phần thời gian còn boost ×hệ số và phần sau ×1 nên không mất thưởng ở ranh giới; boost chỉ giảm khi `tick_income` chạy (đang chơi, không ra nền, không xem quảng cáo). `reward_rate` của lượt đua được chốt lúc xuất phát đã nhân hệ số, nên thưởng hạng, thưởng tham gia và nhà tài trợ cùng nhân. Thu nhập offline dùng `saved_online_rate` gốc nên không bị nhân.

**AdsService.**
- Kiểu thưởng `boost`, `income_seconds` (= N giây của `total_online_rate()` gốc, không nhân hệ số boost), `driver_coupon`, `gear_coupon` (cộng thẳng vào `driver_coupons`/`gear_coupons` trong cùng giao dịch save, không đụng bộ đếm bảo đảm).
- Boost không cộng dồn (đang chạy thì không mời); analytics `boost_start`, `boost_end`.
- Thưởng chờ nhận: xem xong mà lưu lỗi thì `has_pending`/`retry_pending` nhận lại không phải xem lại quảng cáo; `clear_pending` khi đóng popup.
- Lịch lá cờ: `flag_wait_left`, `flag_due(ui_blocked)`, `flag_begin`, `flag_end(tapped)`, `flag_intro_seen`/`flag_mark_intro_seen`. Đồng hồ chỉ chạy khi đang chơi; cờ chỉ tạo khi quảng cáo dùng được hoặc có "Đội tự do".

**Test.** `tests/ads_v1_test.gd` (cấu hình thật): 78 kiểm tra. Đã thử đột biến 4 lần (boost không nhân, thưởng đua không nhân, boost cộng dồn, khoảng chờ cờ không nhân đôi), cả 4 đều bị test bắt. `horus-game.json` khai báo 5 placement mới.

**Chưa có (các bước sau):** UI (P2b–P2d), Ads Break và bridge/provider interstitial (P2e), `boost_start/boost_end` chưa nối vào shop/HUD.

## 15. P2c: chip ×2 và lá cờ (đã code, UI thô)

**Vị trí chốt:** chip ×2 nằm góc phải trên của HUD trong khung đua (thay cho "dải hành động" ở §2/§3, không tốn thêm chiều cao). Lá cờ chạy trên dải khán đài ngay dưới HUD. Giao diện còn thô, sẽ chỉnh sau.

**Code.** `ui/ads_race_controls.gd` (`AdsRaceControls`) là con của `RaceView`, được `main.gd` dựng một lần và gán `blocked` mỗi khung (có popup/bảng kết quả/tutorial/tab khác/không phải lúc đang đua thì cờ không xuất hiện và đứng yên).
- Chip: sẵn sàng `×2 ▶ · 30 phút` (bấm mở popup); đang boost `×2 · mm:ss` (không bấm được); quảng cáo chưa tải "Đang tải…" (xám); ẩn khi khóa, hết lượt, hoặc không có dịp.
- Lá cờ: dùng `flag_due/flag_begin/flag_end`, chạy `cross_sec` giây từ trái sang phải; chạm thì dừng và mở popup; xem xong hoặc bấm Đóng thì cờ mất (`flag_end(true)`); ra mép phải thì `flag_end(false)`.
- Popup: Xem video / Để sau (boost) hoặc Đóng (cờ). Xem dở/mất mạng/chưa có video thì giữ popup và báo lý do; lưu lỗi thì nút thành "Thử nhận lại".

**Test.** `tests/ads_ui_test.gd` (32 kiểm tra: các trạng thái chip, cờ chạy/đứng yên/mất, nhận thưởng, thất bại). Chưa xem bằng mắt trong bản chạy thật vì ván mới còn khóa Shop.

## 16. P2b: thẻ miễn phí trong Shop (đã code, UI thô)

- **Thẻ:** đầu mục GEM có thẻ "MIỄN PHÍ" (`free_gems`, 5 gem); hai thẻ `TRANG BỊ MIỄN PHÍ` và `TAY ĐUA MIỄN PHÍ` (`free_gear_coupon`, `free_driver_coupon`) thay cho chỗ giữ "Sắp có". Thẻ luôn hiện, nút ghi rõ thưởng: `▶ +5 gem`, `▶ +1 Coupon Pro`, `▶ +1 Coupon Gear` (chữ đọc từ `data/ads.json`).
- **Trạng thái nút** (`Ads.card_state`): sẵn sàng; Đang tải…; Cần Internet; Đang xem…; `Còn hh:mm:ss` (đếm ngược 12 giờ của gem); Mai nhận tiếp (hết lượt); Thử nhận lại (xem xong nhưng lưu lỗi, không phải xem lại); Chưa mở; Chờ lưu lại. "Đội tự do" ghi `Nhận ...`, không có biểu tượng video.
- **Chấm đỏ** trên tab Shop khi có thẻ nhận được ngay hoặc thưởng chờ nhận (`Ads.shop_ready`, dùng lại `NavDot`).
- **Toast** sau khi nhận (`+5 gem`, `+1 Coupon Pro`) hoặc lý do không nhận được.
- **Code:** `ui/shop_page.gd` (signal `ad_requested`, `update_ads`), `ui/main.gd` (`_ads_view`, `_watch_shop_ad`), `game/ads_service.gd` (`card_state`, `shop_ready`, `status_text`). **Test:** `tests/ads_shop_test.gd`.
- **Chưa làm:** dấu chấm đỏ trên chính thẻ, nút phụ ở tab Túi và Đội (P2d). Chưa xem trong game thật.
