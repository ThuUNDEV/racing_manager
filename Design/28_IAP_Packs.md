# 28 — Hệ thống gói IAP (v1)

- Ngày: 12/11/2026 · chỉnh 13/11/2026 (hàng đợi popup §5b, gói tuần §4.9, popup Starter dời sau `U5_drivers`)
- Trạng thái: **I0–I1 đã code** (14/11/2026: `data/iap.json`, `Iap` service, mock/Horus provider, `GameState.grant_iap`, save v12, `tests/iap_test.gd`); chưa chạy test trên máy có Godot. Shop vẫn dùng gói gem giả lập (`mock_buy_gems`) cho tới bước I2.
- Thay: danh mục ở [05 §7.2](05_Economy_Monetization.md). Đi cùng: [26 Vị trí quảng cáo](26_Ads_Placements.md), [25 §7 Horus](25_Ads_Lumber_Reference.md), [14 Shop](14_Shop_Integration.md), [12 BigNumber](12_BigNumber_Economy.md).
- Kênh thanh toán: **Horus SDK** (`platform.iap.*`, xem `horus-sdk/AGENTS.md` mục 3 và `GAME-GUIDE.md` §12–13). Không thêm SDK thanh toán khác.

---

## 1. Nguyên tắc

1. **Thước đo chung là gem.** Mọi gói được định giá bằng "gem tương đương" để so với gói gem cơ bản. Giá trị gói ghi trên thẻ (`×3 giá trị`) phải tính được từ bảng §3.
2. **Tiền mềm trong gói = N phút thu nhập hiệu lực**, chốt BigNumber lúc bắt đầu giao dịch (12 §Ads/IAP), để gói có giá trị như nhau ở mọi giải.
3. **Thưởng cơ bản không bao giờ nằm sau mua hàng** (05 §1.1). Pass chỉ thêm, không bớt quà miễn phí.
4. **Không popup bán hàng sau thua, không offer ngẫu nhiên theo hành vi** (05 §1.4). Offer chỉ xuất hiện theo **mốc tiến trình** (§4.3–4.4) hoặc theo **lịch tuần cố định** (§4.9); popup tự hiện đi qua một hàng đợi chung (§5b).
5. **Một đơn = một token.** Hàng vào save và lưu xong rồi mới `finish` (Horus AGENTS mục 3).
6. Giá hiển thị: `platform.iap.price(sku)`; không có thì dùng giá dự phòng trong `data/iap.json`. Không viết cứng giá trong UI.

---

## 2. Bậc giá

Store dùng bậc giá USD; giá VNĐ dưới đây là giá dự phòng (đang dùng trong shop concept), store sẽ trả giá thật theo quốc gia.

| Bậc | USD | Dự phòng VNĐ |
|---|---:|---:|
| T1 | 0,99 | 26.000đ |
| T2 | 1,99 | 52.000đ |
| T5 | 4,99 | 131.000đ |
| T10 | 9,99 | 263.000đ |
| T20 | 19,99 | 526.000đ |
| T50 | 49,99 | 1.300.000đ |

**Giá gem cơ bản: 50 gem / 1 USD** (khớp gói 100 gem = 52.000đ đang có). Đây là mốc để tính "×N giá trị".

---

## 3. Bảng quy đổi giá trị (gem tương đương)

| Món | Gem tương đương | Căn cứ |
|---|---:|---|
| 1 coupon Pro (tay đua) / Standard (gear) | 10 | `price_x1` trong `driver_gacha.json` / `gear.json` |
| 1 coupon All-Star / Elite | 30 | như trên |
| 60 phút thu nhập hiệu lực | 10 | bằng gói TIỀN nhỏ nhất (§4.8) |
| 1 ngày "Đội tự do" | không quy đổi | quyền lợi vĩnh viễn, bán riêng |

---

## 4. Danh mục sản phẩm

Tổng: **30 SKU** (5 gem, 5 vĩnh viễn kể cả gói nâng ×2→×3, 3 starter, 3 offer, 4 gói tuần, 6 nhân vật, 2 gói ngày, 2 pass). SKU đặt theo tên gói, **không bao giờ đổi** sau khi lên store (GAME-GUIDE §2).

### 4.1. Gói gem (tiêu thụ) — mục GEM

| SKU | Giá | Gem | Thưởng thêm | Lần mua đầu |
|---|---|---:|---|---|
| `gems_pack_1` | T1 | 50 | — | ×2 (100) |
| `gems_pack_2` | T5 | 275 | +10% | ×2 (550) |
| `gems_pack_3` | T10 | 600 | +20% | ×2 (1.200) |
| `gems_pack_4` | T20 | 1.300 | +30% | ×2 (2.600) |
| `gems_pack_5` | T50 | 3.500 | +40% | ×2 (7.000) |

- Thay 5 gói giả lập hiện tại (100/255/520/1.100/2.750, gần như không có thưởng theo bậc). Thẻ đầu tiên của mục GEM vẫn là **gem miễn phí xem video** (26 §5), không phải SKU.
- "Lần mua đầu ×2" tính **riêng từng gói**, nhãn `LẦN ĐẦU ×2` trên thẻ; mua xong nhãn mất. Lưu trong `iap.first_bonus_used`.

### 4.2. Quyền lợi vĩnh viễn (một lần, `consumable: false`) — mục ƯU ĐÃI ĐẶC BIỆT

| SKU | Giá | Nội dung |
|---|---|---|
| `no_ads` "Đội tự do" | T10 | Không bao giờ gặp Ads Break; mọi rewarded ở 26 **nhận thẳng** (vẫn theo trần/lượt ngày); +100 gem một lần. Đặt `ad_state.free = true` |
| `income_x2` | T5 | Thu nhập online và thưởng đua ×2 vĩnh viễn |
| `income_x3` | T10 | ×3 vĩnh viễn. Chỉ hiện khi **chưa** có `income_x2` |
| `income_x3_up` | T5 | Nâng ×2 → ×3. Chỉ hiện khi **đã** có `income_x2`. Tổng tiền hai bước = mua thẳng ×3 |
| `offline_plus` | T5 | Thu nhập offline ×3 và trần offline 24 giờ (thay 2 giờ) |

**Luật hệ số thu nhập**
- `purchased_mult` = 1 / 2 / 3. Hệ số hiệu lực = `max(purchased_mult, boost quảng cáo đang chạy)` (26 §3 đã chốt, không nhân chồng).
- Có `purchased_mult ≥ 2` thì **ẩn nút tăng tốc ×2** trên tab Đua (26 §3).
- Áp: `tick_income`, thưởng đua (chốt lúc xuất phát như boost). **Không áp offline** (offline có SKU riêng). Không áp quà ngày, lá cờ khán đài vẫn tính theo rate hiệu lực (đã nhân).
- `offline_plus`: hệ số offline 0,5 → 1,5 của `saved_online_rate` gốc (không nhân `purchased_mult`), trần 7.200 → 86.400 giây. Mở rộng trần bằng gem ở 05 §4 bị **ẩn** khi đã có.

> **Rủi ro kinh tế (cần bạn chốt, §10 điểm 1):** ×3 vĩnh viễn rút nhịp 3–4 tuần của 05 §5 xuống còn khoảng 1–1,5 tuần cho người mua. Đề xuất giữ ×2/×3 nhưng **giá nâng cấp không đổi**, nên người mua đi nhanh hơn và hết nội dung sớm hơn. Phải chạy lại lab nhịp tiến trình với `purchased_mult` = 2 và 3 trước soft launch.

### 4.3. Chuỗi gói khởi đầu (Starter, một lần mỗi gói) — mục ƯU ĐÃI GIỚI HẠN

Ba gói nối tiếp, giá tăng dần, giá trị cao nhất game ở gói đầu để biến người chơi miễn phí thành người mua lần đầu. Gói sau **mở khi gói trước đã mua, hoặc khi đạt mốc của nó** (điều nào đến trước), nên người không mua gói 1 vẫn thấy gói 2, 3 đúng lúc.

| SKU | Giá | Mở khi | Nội dung | Gem tương đương | Giá trị |
|---|---|---|---|---:|---|
| `starter_1` "Gói Tân binh" | T1 | Mở Shop (`U4_shop`) | 150 gem, 3 coupon Pro, 3 coupon Standard gear, 60 phút thu nhập | 220 | ×4,4 |
| `starter_2` "Gói Khởi động" | T5 | Mua `starter_1` hoặc xong tutorial (`U5_drivers`) | **Tay đua Hà** (Pro, Sprint), 500 gem, 5 coupon All-Star, 5 coupon Elite gear, 120 phút thu nhập | ≈ 910 | ×3,6 |
| `starter_3` "Gói Chuyên nghiệp" | T10 | Mua `starter_2` hoặc lên `business_tier` 1 | **Tay đua My** (Elite, Straight line), 800 gem, 10 coupon All-Star, 8 coupon Elite gear, 240 phút thu nhập | ≈ 1.620 | ×3,2 |

- `starter_2` thay `offer_starter` của bản trước (05 §7.2 "Gói khởi động").
- Gem tương đương của tay đua tính theo **số lượt quay kỳ vọng** để ra đúng người đó: Hà ≈ 9 lượt Pro (90 gem), My ≈ 8 lượt All-Star (240 gem).
- Tay đua trong gói theo luật nhận tay đua ở §4.5 (đã có thì đổi thành mảnh).
- Cả chuỗi nằm trong một thẻ ở đầu mục ƯU ĐÃI GIỚI HẠN, hiện gói đang mở kèm dải `1 · 2 · 3` cho biết vị trí trong chuỗi. Mua hết thì thẻ biến mất.
- **Thẻ và popup tách nhau.** Thẻ `starter_1` hiện trong Shop ngay khi Shop mở (`U4_shop`, lượt 4) kèm chấm đỏ; `starter_2`, `starter_3` hiện thẻ ngay khi đủ điều kiện ở cột *Mở khi*. **Popup tự hiện** đi theo hàng đợi §5b: `starter_1` ở bảng kết quả đầu tiên sau khi `U5_drivers` hoàn tất (khoảng lượt 6), không chen vào các bước tutorial lượt 4 và 5; `starter_2` và `starter_3` chỉ tự hiện ở **phiên kế tiếp** và cách popup trước ≥ 24 giờ. Mỗi gói tối đa 1 popup.

### 4.4. Offer theo mốc (một lần mỗi offer) — mục ƯU ĐÃI GIỚI HẠN

| SKU | Giá | Mở khi | Nội dung | Gem tương đương | Giá trị |
|---|---|---|---|---:|---|
| `offer_combo_1` "Combo bứt phá I" | T5 | Lên `business_tier` 2 | 500 gem, 6 coupon All-Star, 4 coupon Elite, 240 phút thu nhập | 840 | ×3,4 |
| `offer_combo_2` "Combo bứt phá II" | T10 | Lên `business_tier` 4 | 1.000 gem, 12 coupon All-Star, 8 coupon Elite, 480 phút thu nhập | 1.680 | ×3,4 |
| `offer_noads_bundle` "Đội tự do + quà" | T10 | Sau Ads Break thứ 3 trong ngày, **chỉ khi chưa có `no_ads`** | `no_ads` + 300 gem + 3 coupon All-Star | — | |

- Combo dời lên bậc 2 và 4 để không trùng mốc bậc 1 của `starter_3`.
- Offer **không có đồng hồ ép** (05 §1.4): một khi mở thì nằm trong Shop **cho tới khi mua**. Tối đa 2 offer đang mở cùng lúc (thẻ chuỗi Starter và gói tuần không tính); offer mới hơn xếp trên. Luật tự hiện popup dưới đây và hàng đợi §5b áp dụng cho cả `starter_1..3`.
- Mỗi offer **được phép một lần tự hiện** popup, ở bảng kết quả đủ điều kiện đầu tiên sau khi đạt mốc (sau bảng kết quả, trước countdown, cùng cơ chế `result_hold`, theo hàng đợi §5b); không tự hiện sau lượt người chơi về P5 trở xuống. Lần sau chỉ còn banner trong Shop + chấm đỏ ở tab Shop một lần.
- `offer_noads_bundle` thay cho thẻ `no_ads` đơn lẻ khi đang mở (cùng quyền lợi, nhiều quà hơn, cùng giá), để không bán hai thứ trùng nhau. Mua một trong hai thì cả hai biến mất. Tự hiện tối đa 1 lần/ngày, 3 lần tổng; sau đó chỉ còn trong Shop.
- Phần "N phút thu nhập": `total_online_rate()` × 60 × N, **không** nhân hệ số boost hay `purchased_mult`, chốt khi bấm mua (lưu trong ngữ cảnh đơn chờ, §7.3).

### 4.5. Gói nhân vật (một lần mỗi tay đua) — mục TAY ĐUA NỔI BẬT và tab Đội

Bán **đích danh một tay đua** bậc Elite hoặc Legend, kèm mảnh của chính người đó để lên cấp ngay. Bậc Rookie/Pro không bán (đã có qua tuyển SP, gói Pro và `starter_2`).

| SKU | Tay đua | Bậc · lối đua | Giá | Nội dung kèm |
|---|---|---|---|---|
| `char_lam` | Lâm | Elite · Defender | T5 | 30 mảnh Lâm, 100 gem, 3 coupon Elite gear |
| `char_my` | My | Elite · Straight line | T5 | như trên |
| `char_nhan` | Nhân | Elite · Steady | T5 | như trên |
| `char_phuong` | Phương | Legend · Recovery | T10 | 30 mảnh, 200 gem, 5 coupon Elite gear |
| `char_quang` | Quang | Legend · Golden | T10 | như trên |
| `char_son` | Sơn | Legend · Discipline | T10 | như trên |

**Giá trị.** Một tay đua Elite đích danh ≈ 8 lượt All-Star (240 gem); Legend đích danh ≈ 25 lượt All-Star dù có bảo đảm 10 lượt (≈ 750 gem), vì bảo đảm chỉ ra *một* Legend bất kỳ trong ba người. 30 mảnh = lên thẳng cấp 2 (10 + 20). Tổng: Elite ≈ ×1,9, Legend ≈ ×2,4. Thấp hơn starter để chuỗi khởi đầu vẫn là gói đáng mua nhất.

**Luật nhận tay đua (dùng chung cho §4.3 và §4.5)**
- Chưa có: thêm vào đội (cấp 0) rồi cộng mảnh. Tính vào `driver_pack_new` như tay đua từ gói quay, nên **không** đẩy giá tuyển SP lên (`recruit_index()`).
- Đã có (từ gói quay hoặc tuyển): **đổi tay đua thành 40 mảnh** của người đó (gấp 8 lần mảnh trùng thường là 5), cộng với mảnh kèm theo. Thẻ ghi rõ trước khi mua: `Đã có Quang · nhận 70 mảnh`.
- Đã đạt cấp tối đa (5): **ẩn** gói của người đó; không bán thứ người chơi không dùng được.
- Gói nhân vật là `consumable: true` + `once` (§6): mua một lần cho mỗi tay đua.

**Khi nào hiện (chống mua sức mạnh quá sớm).** Mỗi tay đua có điều kiện mở `unlock.league` trong `drivers.json` (so với `business_tier`). Gói chỉ hiện khi `business_tier ≥ unlock.league − 1`: Elite (mở ở bậc 3) bán từ bậc 2, Legend (mở ở bậc 4) bán từ bậc 3. Trước đó thẻ tay đua ở tab Đội chỉ hiện điều kiện mở như bây giờ. Riêng `starter_3` tặng My sớm hơn (bậc 1) là có chủ ý: đó là phần thưởng của chuỗi khởi đầu, chỉ một người.

**Vị trí**
1. **Shop → TAY ĐUA NỔI BẬT** (mục mới, nằm giữa PASS và ƯU ĐÃI ĐẶC BIỆT): **2 thẻ**, một Elite và một Legend, đổi theo tuần (thứ Hai 00:00 UTC, xoay vòng theo số tuần, bỏ qua người đã mua/đã max/chưa đủ bậc). Thẻ to: chân dung, lối đua, 3 chỉ số nổi bật, nội dung gói, giá. Không còn người nào đủ điều kiện thì ẩn mục.
2. **Tab Đội → thẻ tay đua**: tay đua chưa có và gói đang bán được thì có nút `Chiêu mộ ngay · <giá>` cạnh điều kiện tuyển SP. Đây là lối mua **mọi** gói nhân vật đang đủ điều kiện, không phụ thuộc lịch xoay tuần.
3. Không có popup tự bật cho gói nhân vật.

### 4.6. Gói ngày (tiêu thụ, giới hạn) — mục TRANG BỊ & TAY ĐUA

| SKU | Giá | Nội dung | Gem tương đương | Giới hạn |
|---|---|---|---:|---|
| `daily_gear` "Gói trang bị" | T1 | 2 coupon Elite + 50 gem | 110 | 1 lần/ngày UTC |
| `daily_driver` "Gói tay đua" | T1 | 2 coupon All-Star + 50 gem | 110 | 1 lần/ngày UTC |

- Đúng hai thẻ đã có trong shop concept (`x2` + `x50`, 26.000đ). Giá trị ×2,2, thấp hơn offer để offer vẫn đáng mua.
- Hết lượt: nút `Mai mở lại`. Mở khóa theo tính năng chứa nó: gear sau `U3_bag`, tay đua sau `U5_drivers`.
- Hai thẻ miễn phí xem video (26 §6) nằm **ngay dưới** hai gói này, giữ nguyên.

### 4.7. Pass — mục PASS

**Pass tháng** `pass_month` (T5, tiêu thụ)

Horus SDK không có subscription (`platform.iap` chỉ có `buy/pending/finish/restore`), nên pass tháng là **gói tiêu thụ cộng 30 ngày**.

- Mua: nhận ngay **150 gem**; sau đó **30 gem mỗi ngày UTC trong 30 ngày** (tổng 1.050 gem ≈ ×4,2), thêm **+2 giờ trần offline** khi pass còn hạn.
- Gem ngày phải **bấm nhận** (cùng thẻ quà hằng ngày, dòng thứ hai). Ngày bỏ lỡ **không cộng dồn** — đây là điểm giữ chân; ghi rõ trên thẻ "nhận mỗi ngày".
- Mua lại khi còn ≤ 5 ngày: cộng tiếp 30 ngày, trần 60 ngày còn lại. Còn > 5 ngày thì nút `Còn N ngày`, không bán.
- Ngày dựa theo giờ server khi có mạng (05 §9), không có mạng thì theo giờ thiết bị, chống lùi giờ như offline.

**Quỹ gem** `pass_growth` (T5, một lần, `consumable: false`)

Mua một lần, nhận gem theo mốc tiến trình. Mốc đạt trước khi mua vẫn nhận được (nhận bù khi mua).

| Mốc | Gem |
|---|---:|
| Mua ngay | 100 |
| `business_tier` 1 | 200 |
| `business_tier` 2 | 300 |
| `business_tier` 3 | 400 |
| `business_tier` 4 | 500 |
| `business_tier` 5 | 1.000 |
| **Tổng** | **2.500 (×10)** |

- Từng mốc bấm nhận trên thẻ (danh sách 6 dòng: đã nhận / nhận được / khóa). Chấm đỏ tab Shop khi có mốc nhận được.
- Rủi ro thấp vì gem bị giới hạn bởi tiến trình chứ không theo thời gian.

**Pass mùa giải** — giữ "Sắp có", **không làm ở v1** (05 §7.2: pass mùa cần vòng cân bằng riêng và hệ điểm pass chưa có). Sẽ thiết kế ở tài liệu riêng sau soft launch.

### 4.8. Gói TIỀN (mua bằng gem, không phải IAP)

Đã có 3 thẻ trong shop concept (con số 4.08B/16.3B/32.6B là giả). Định nghĩa lại theo phút thu nhập:

| Giá | Tiền nhận |
|---|---|
| 10 gem | 60 phút thu nhập hiệu lực |
| 30 gem | 240 phút (×1,33) |
| 50 gem | 480 phút (×1,6) |

Hiển thị số tiền thật tính tại lúc mở Shop (`total_online_rate()` × giây, đã nhân `purchased_mult`). Có xác nhận trước khi trừ gem (05 §1.3).

### 4.9. Gói tuần (tiêu thụ, giới hạn theo tuần) — mục ƯU ĐÃI GIỚI HẠN

Bốn slot lặp lại mỗi tuần cho giai đoạn sau các offer một lần (`offer_combo_2` đóng ở `business_tier` 4). Giá trị đặt giữa gói ngày (×2,2) và offer theo mốc (×3,4) để offer một lần vẫn đáng mua hơn.

| SKU | Giá | Nội dung | Gem tương đương | Giá trị |
|---|---|---|---:|---|
| `weekly_s` | T5 | 300 gem, 6 coupon All-Star, 4 coupon Elite gear, 240 phút thu nhập | 640 | ×2,6 |
| `weekly_m` | T10 | 650 gem, 12 coupon All-Star, 8 coupon Elite gear, 480 phút thu nhập | 1.330 | ×2,7 |
| `weekly_l` | T20 | 1.300 gem, 25 coupon All-Star, 15 coupon Elite gear, 960 phút thu nhập | 2.660 | ×2,7 |
| `weekly_xl` | T50 | 3.500 gem, 60 coupon All-Star, 40 coupon Elite gear, 2.400 phút thu nhập | 6.900 | ×2,8 |

- Gem tương đương tính theo bảng §3 với gốc 50 gem/USD (T5 = 250, T10 = 500, T20 = 1.000, T50 = 2.500).
- Mở khi `business_tier ≥ 3`. Giới hạn **1 lần mỗi slot mỗi tuần** (tuần đổi thứ Hai 00:00 UTC, cùng lịch với tay đua nổi bật §4.5). Mua xong nút thành `Mở lại sau N ngày`; slot chưa mua **không có đồng hồ** (không đếm ngược, 05 §1.4).
- **Không popup tự hiện.** Chỉ có thẻ trong ƯU ĐÃI GIỚI HẠN và chấm đỏ tab Shop một lần khi sang tuần mới mà còn slot chưa mua.
- "N phút thu nhập": như §4.4 (chốt khi bấm mua, không nhân boost hay `purchased_mult`). Gói chứa coupon có `Xem tỉ lệ` (§5, §8).
- **`weekly_xl` là rủi ro lạm phát coupon** (60 All-Star + 40 Elite mỗi tuần cho một người mua). Bật qua cờ Remote Config `weekly_xl_enabled`, **mặc định tắt** cho tới khi lab nhịp tiến trình (§4.2) chạy xong với người mua đều đặn. Ba slot nhỏ hơn cũng nằm trong lab đó.

---

## 5. Bố cục Shop (thứ tự mục)

```
QUÀ HẰNG NGÀY          quà free + dòng "Pass tháng: nhận 30 gem" nếu còn hạn
ƯU ĐÃI GIỚI HẠN        thẻ chuỗi Starter (§4.3) + 0–2 offer đang mở (§4.4) + 4 gói tuần từ tier 3 (§4.9); trống thì ẩn mục
PASS                   Pass tháng · Quỹ gem · Pass mùa (Sắp có)
TAY ĐUA NỔI BẬT        1 Elite + 1 Legend xoay theo tuần (§4.5)
ƯU ĐÃI ĐẶC BIỆT        Đội tự do · Thu nhập ×2 / ×3 (hoặc ×2→×3) · Offline+
TRANG BỊ & TAY ĐUA     2 gói ngày (§4.6) + 2 thẻ xem video (26 §6)
GEM                    thẻ xem video (26 §5) + 5 gói gem
TIỀN                   3 gói đổi gem (§4.8)
──────────────────────
[Khôi phục giao dịch]  chỉ hiện khi platform.iap.restorable
Tỉ lệ gói · Điều khoản · Chính sách riêng tư
```

**Trạng thái mỗi nút IAP:** giá (sẵn sàng) → `Đang xử lý…` (đã gọi `buy`, khóa mọi nút IAP khác) → `Đã sở hữu` (vĩnh viễn) / `Mai mở lại` (gói ngày) / `Còn N ngày` (pass) / `Chờ thanh toán` (đơn `pending`) / `Không có kết nối` (mất mạng, xám).

**Xác nhận:** store đã hiện hộp thoại thanh toán riêng, game **không** thêm hộp xác nhận thứ hai cho IAP. Mua bằng gem (gói TIỀN, mở gói) vẫn xác nhận như hiện tại.

**Thẻ phải ghi:** nội dung đầy đủ (từng dòng thưởng), giá trị `×N`, giới hạn (`1 lần`, `1 lần/ngày`, `30 ngày`). Gói chứa coupon phải có liên kết **Xem tỉ lệ** tới bảng tỉ lệ của gói Pro/All-Star/Standard/Elite (§8).

**Mở khóa:** cả trang Shop mở ở `U4_shop`. Trước đó không gọi `platform.iap.buy` ở bất kỳ đâu.

---

## 5b. Hàng đợi popup bán hàng

Áp cho mọi popup bán hàng **tự hiện**: `starter_1..3`, `offer_combo_*`, `offer_noads_bundle`. Gói nhân vật, gói tuần, pass và gói ngày **không** tự hiện popup. Hàng đợi này dùng chung với Ads Break và lá cờ khán đài ([26](26_Ads_Placements.md)).

- **Thứ tự ưu tiên** khi cùng có mặt (cao → thấp): tutorial đang giữ màn hình > panel offline > bảng kết quả > popup bán hàng > lá cờ khán đài > Ads Break. Popup bán hàng chỉ hiện trong khoảng sau bảng kết quả, trước countdown (`result_hold`).
- **Chặn hoàn toàn:** tutorial đang giữ màn hình (kể cả lượt có bước tutorial vừa hoàn tất), overlay hoặc panel hoặc trang hồ sơ đang mở, `save_error`, app `suspended`, đang Ads Break, người chơi vừa về P5 trở xuống (§4.4).
- **Giới hạn chung:** cách nhau ≥ `popup.gap_sec` giữa hai popup bán hàng bất kỳ; tối đa `popup.per_day` mỗi ngày UTC. Giá trị khởi điểm: **1.800 giây và 3 lần**, cân lại sau soft launch.
- **Popup bị chặn không mất:** xếp hàng và thử lại ở bảng kết quả đủ điều kiện kế tiếp, mốc đạt trước hiện trước. Quá giới hạn trong ngày thì sang ngày sau. Popup chưa hiện vẫn luôn có thẻ trong Shop.
- Lá cờ khán đài không tạo khi có popup bán hàng đang mở (26 đã chặn "popup khác"); Ads Break không hiện khi có popup đang mở (26 §7).
- Analytics: `popup_skip` ghi lý do chặn (§7.4).

---

## 6. Dữ liệu: `data/iap.json`

```json
{
  "schema_version": 1,
  "_doc": "Danh mục IAP (Design/28). price_fallback chỉ dùng khi store không trả giá. income_min = phút thu nhập chốt lúc mua.",
  "popup": {"gap_sec": 1800, "per_day": 3, "first_after_tutorial": "U5_drivers", "next_gap_hours": 24},
  "flags": {"weekly_xl_enabled": false},
  "products": [
    {"sku": "gems_pack_1", "kind": "gems", "usd": 0.99, "price_fallback": "26.000đ",
     "consumable": true, "grant": {"gems": 50}, "first_bonus": 2},
    {"sku": "no_ads", "kind": "perk", "usd": 9.99, "price_fallback": "263.000đ",
     "consumable": false, "grant": {"perk": "no_ads", "gems": 100}},
    {"sku": "income_x3_up", "kind": "perk", "usd": 4.99, "consumable": false,
     "grant": {"perk": "income_x3"}, "requires": ["income_x2"]},
    {"sku": "starter_2", "kind": "starter", "usd": 4.99, "consumable": true, "once": true,
     "chain": 2, "unlock": {"any": [{"bought": "starter_1"}, {"tutorial": "U5_drivers"}]},
     "auto_popup": {"max": 1, "next_session": true, "after_hours": 24},
     "grant": {"driver": "driver_ha", "gems": 500, "driver_coupon": {"allstar": 5},
               "gear_coupon": {"elite": 5}, "income_min": 120}},
    {"sku": "char_quang", "kind": "character", "usd": 9.99, "consumable": true, "once": true,
     "unlock": {"tier_before_driver": 1},
     "grant": {"driver": "driver_quang", "driver_shards": 30, "gems": 200, "gear_coupon": {"elite": 5}}},
    {"sku": "daily_gear", "kind": "daily", "usd": 0.99, "consumable": true, "daily_limit": 1,
     "unlock": {"tutorial": "U3_bag"}, "grant": {"gems": 50, "gear_coupon": {"elite": 2}}},
    {"sku": "pass_month", "kind": "pass_month", "usd": 4.99, "consumable": true,
     "grant": {"gems": 150}, "days": 30, "daily_gems": 30, "offline_bonus_sec": 7200,
     "rebuy_when_left_days": 5, "max_days": 60},
    {"sku": "pass_growth", "kind": "pass_growth", "usd": 4.99, "consumable": false,
     "grant": {"gems": 100}, "milestones": [[1, 200], [2, 300], [3, 400], [4, 500], [5, 1000]]},
    {"sku": "weekly_s", "kind": "weekly", "usd": 4.99, "consumable": true, "weekly_limit": 1,
     "unlock": {"tier": 3},
     "grant": {"gems": 300, "driver_coupon": {"allstar": 6}, "gear_coupon": {"elite": 4}, "income_min": 240}}
  ]
}
```

(Ví dụ rút gọn; bản thật khai đủ 30 SKU ở §4. `weekly_xl` thêm `"flag": "weekly_xl_enabled"` để chỉ hiện khi cờ bật.)

- `grant.driver`: theo luật nhận tay đua §4.5; đổi tay đua đã có thành `owned_driver_shards` (mặc định 40, khai ở đầu file). `unlock.tier_before_driver: 1` nghĩa là `business_tier ≥ unlock.league − 1` của tay đua đó. `feature_rotation` (khai ở đầu file): danh sách SKU nhân vật theo thứ tự xoay tuần.

- **Offer "một lần" nhưng `consumable: true`**: Play/App Store cho mua lại món consumable, nên game tự chặn bằng `once` (đã có token trong `iap.buys` thì ẩn). Chỉ quyền lợi cần **khôi phục** khi cài lại (`no_ads`, `income_*`, `offline_plus`, `pass_growth`) mới là `consumable: false`.
- `GameData.validate()` kiểm tra: SKU không trùng; `kind` hợp lệ; loại coupon có trong `gear.json`/`driver_gacha.json`; `unlock.tutorial` có trong `tutorial.json`; `requires` trỏ tới SKU/perk có thật; mốc `pass_growth` tăng dần và ≤ 5; `kind: weekly` phải có `weekly_limit` ≥ 1 và `unlock.tier`; `popup.gap_sec` > 0 và `popup.per_day` ≥ 1; `flag` trỏ tới khóa có trong `flags`; mọi SKU có trong `horus-game.json → products` với cùng `usd` và `consumable`.
- Mọi con số ghi đè được bằng Remote Config theo whitelist của 07 §Remote config; **SKU, `consumable` thì không**.

---

## 7. Kỹ thuật

### 7.1. Thành phần

| Thành phần | Việc |
|---|---|
| `game/iap_service.gd` (autoload `Iap`) | Danh mục, `price(sku)`, `can_buy(sku) -> {ok, why}`, `buy(sku)`, `restore()`, xử lý `pending()` lúc khởi động, analytics |
| `IapProvider` (mock) / `HorusIapProvider` | Mock: trả `ok` ngay, có chế độ `pending`, `cancel`, `invalid`, lỗi, tải lại giữa chừng (để test). Horus: qua `window.rmHorus` → `platform.iap.*` như cách đã làm với ads (25 §7.7) |
| `web/shell.html` | `rmHorus.iapBuy/iapPending/iapFinish/iapRestore/iapPrice/iapRestorable`; `start({ skus: [...] })` để store trả giá |
| `GameState` | Trường save §7.2, `grant_iap(sku, token, context) -> bool` trong **một giao dịch save** |
| `ui/shop_page.gd` | Dựng thẻ từ `data/iap.json`, thay các `_coming_button` và `mock_gem_packs` |

### 7.2. Save (tăng schema)

```
iap: {
  buys: [{sku, token, order, t}],      # chống giao trùng; giữ hết đơn non-consumable, đơn khác giữ 200 gần nhất
  owned: ["no_ads", "income_x2", ...], # quyền lợi vĩnh viễn
  first_bonus_used: ["gems_pack_1"],
  daily: {sku: day_utc},               # lần mua gói ngày gần nhất
  offers: {sku: {open_t, popup_count, last_popup_day}},   # gồm cả starter_1..3
  weekly: {sku: week_index},           # tuần UTC của lần mua gần nhất (slot gói tuần)
  popup: {last_t, day_utc, count_today, queued},          # hàng đợi popup bán hàng (§5b)
  pass_month: {left_days, last_claim_day},
  growth_claimed: [1, 2],
  pending_ctx: {token_or_sku: {income_value: "<BigNumber>"}}  # chốt phút thu nhập lúc bấm mua
}
```
`purchased_mult` và `ad_state.free` **suy ra** từ `owned` khi nạp save, không lưu riêng, để không lệch nhau.

### 7.3. Luồng mua

```
bấm giá → can_buy? → khóa nút IAP, chốt pending_ctx (income) và LƯU
       → platform.iap.buy(sku)
           ok       → grant_iap(sku, token): đã có token? → bỏ qua phát thưởng
                                              chưa có   → cộng hàng + ghi buys → LƯU
                      lưu thành công → platform.iap.finish({consumable, usd}) → toast + hiệu ứng
                      lưu lỗi        → KHÔNG finish; lần mở game sau pending() giao lại
           pending  → "Chờ thanh toán", không thưởng
           cancel   → mở khóa nút, không thông báo lỗi
           invalid  → không thưởng, ghi analytics, toast "Giao dịch không hợp lệ"
           error    → toast "Chưa mua được, thử lại sau"
```
- **Khởi động:** sau khi nạp save, trước khi bắt đầu lượt đua: `for p in pending(): grant_iap(p)`. Cũng gọi khi app `resume` (đơn pending vừa thanh toán xong).
- **Không có `pending_ctx`** (ví dụ đơn giao lại sau khi cài lại): phút thu nhập tính theo rate hiện tại.
- **Khôi phục:** nút Restore → `restore()` → `pending()` → giao lại, chỉ có tác dụng với `consumable: false`. Dùng `save.mergePurchases(..., flags: ["noAds"])` của SDK khi gộp bản cloud.
- **Hoàn tiền:** Horus không báo hoàn tiền về game. Quyền vĩnh viễn được kiểm tra lại khi Restore (05 §8): không còn trong `pending()` thì **không** tự gỡ ở v1 (tránh gỡ nhầm khi mất mạng); ghi analytics `iap_owned_mismatch` để xem số liệu.
- **Đơn `test`** (`Purchase.test`): vẫn giao hàng, gửi analytics với cờ test, không gửi `usd`.

### 7.4. Analytics

`iap_view` (mở Shop, một lần/phiên), `offer_show` (+`why`: `milestone`/`shop`/`weekly`), `popup_skip` (+`why`: `tutorial`/`overlay`/`gap`/`day_cap`/`session`), `iap_started`, `iap_completed` (+`usd`, `first`), `iap_pending`, `iap_cancel`, `iap_fail` (+`reason`), `iap_restore`, `pass_claim`, `growth_claim`. Dùng `platform.an.earn('gem', n, 'iap')` cho gem từ IAP để số dư gem trong báo cáo khớp.

---

## 8. Tuân thủ (kiểm tra lại trước M5)

- **Gói chứa coupon quay ngẫu nhiên** (gacha đã có, xem gói Pro/All-Star): App Store và Google Play yêu cầu **công bố tỉ lệ** trước khi mua cho cơ chế ngẫu nhiên mua được bằng tiền thật. Mỗi thẻ gói có liên kết `Xem tỉ lệ`; thẻ gói quay ở Túi/Đội cũng phải có. Điều này đi ngược câu "không có gacha" trong 05 §7.2 và D1, nên phải sửa 05 và mục khai báo độ tuổi (05 §8) cho khớp.
- Một số thị trường hạn chế hoặc cấm bán hộp ngẫu nhiên bằng tiền thật (ví dụ Bỉ). Cần tư vấn pháp lý trước khi chọn thị trường soft launch; phương án dự phòng là cờ Remote Config ẩn các gói có coupon theo quốc gia.
- iOS: nút Khôi phục bắt buộc khi có món non-consumable.
- Không dùng chữ "No Ads" nếu người mua vẫn phải xem quảng cáo: "Đội tự do" nhận thẳng rewarded và tắt Ads Break nên được phép gọi là bỏ quảng cáo.
- Giá luôn lấy từ store; nhãn `×N giá trị` chỉ so với gói gem của chính game.

---

## 9. Thứ tự triển khai

| Bước | Nội dung | Ghi chú |
|---|---|---|
| I0 | `data/iap.json`, validate, `horus-game.json → products` | Không UI |
| I1 | `IapService` + mock provider, `GameState.grant_iap`, save schema, test headless (giao một lần, tải lại giữa chừng, pending, invalid, lưu lỗi không finish) | Lõi, rủi ro trùng thưởng nằm ở đây |
| I2 | Shop: gói gem thật thay `mock_gem_packs`, nút Khôi phục, trạng thái nút | Bỏ `mock_buy_gems` sau bước này |
| I3 | Quyền lợi vĩnh viễn: `no_ads` (nối `ad_state.free`), `income_*`, `offline_plus` | Cần lab nhịp tiến trình (§4.2) |
| I4 | Hàng đợi popup bán hàng (§5b), chuỗi Starter, gói ngày, offer theo mốc + popup một lần | Hàng đợi dùng chung với Ads Break và lá cờ (26): làm trước popup đầu tiên |
| I4b | Gói nhân vật: `GameState.grant_driver(id, shards)` (luật đổi mảnh khi đã có), mục TAY ĐUA NỔI BẬT xoay tuần, nút `Chiêu mộ ngay` ở tab Đội | Cần chân dung tay đua cỡ lớn cho thẻ |
| I4c | Gói tuần (§4.9): `kind: weekly`, reset thứ Hai 00:00 UTC, chấm đỏ, cờ `weekly_xl_enabled` | Lab coupon và nhịp tiến trình trước khi bật XL |
| I5 | Pass tháng, Quỹ gem | |
| I6 | Bridge Horus thật, thử trên bản Web + tài khoản thử Play | Theo 25 §7.7 |
| — | Pass mùa giải | Sau soft launch, tài liệu riêng |

**Xong khi (mỗi SKU):** mua giả lập thì hàng vào đúng một lần; tắt app trước `finish` thì mở lại giao đúng một lần; `pending` không thưởng tới khi thanh toán xong; `invalid` không thưởng; lưu lỗi thì không `finish`; non-consumable khôi phục được sau khi xoá save; nút đúng trạng thái; analytics đủ.

---

## 10. Điểm cần bạn chốt

1. **Thu nhập ×2/×3 vĩnh viễn** (§4.2): giữ như shop concept (rút nhịp tiến trình cho người mua), hay đổi thành ×2 tối đa / chỉ áp cho thưởng đua?
2. **Giá trị chuỗi Starter ×4,4 / ×3,6 / ×3,2, offer ×3,4, gói ngày ×2,2** (§4.3–4.6): ổn, hay muốn mạnh tay hơn cho `starter_1` (thường ×5–10 ở game idle)?
3. **Starter và offer không đếm ngược, nằm trong Shop tới khi mua** (§4.3–4.4): giữ đúng 05 §1.4, hay cho phép offer có hạn 48–72 giờ như Crash Ramp trong GAME-GUIDE §13?
4. **Pass tháng 150 + 30/ngày** (§4.7): bỏ lỡ ngày thì mất — giữ hay cho nhận bù?
5. **Pass mùa giải** để sau soft launch (§4.7): đồng ý?
6. **Công bố tỉ lệ và cờ ẩn gói theo quốc gia** (§8): đồng ý sửa 05/D1 để ghi nhận gacha đã có?
7. **Gói nhân vật** (§4.5): bán đích danh 6 tay đua Elite/Legend, mở sớm hơn 1 bậc so với điều kiện tuyển, đã có thì đổi thành 40 mảnh. Muốn bán cả Rookie/Pro, hay cho mua lặp lại để lấy mảnh tới cấp tối đa?
8. **Tay đua tặng trong Starter** (§4.3): Hà ở `starter_2`, My ở `starter_3` — giữ hay chọn người khác?

**Đã chốt 13/11/2026**
9. Popup `starter_1` dời sang sau `U5_drivers` (khoảng lượt 6); `starter_2/3` tự hiện ở phiên kế tiếp, cách ≥ 24 giờ (§4.3, §5b).
10. Gói tuần chỉ có chấm đỏ, không popup tự hiện (§4.9).
11. Giữ `weekly_xl` (T50), bật bằng cờ Remote Config, mặc định tắt đến khi lab xong (§4.9).
