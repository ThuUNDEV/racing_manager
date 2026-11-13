# Race Star – Team Manager: thiết kế gói IAP và điều kiện hiển thị (v1.9.0)

Tài liệu bổ sung cho [race_star_team_manager.md](race_star_team_manager.md). Nguồn: ScriptableObject trong `com.coolcatsgames.racestaridle.apk`.

- **[Quan sát]**: đọc trực tiếp từ file cấu hình.
- **[Suy luận]**: rút ra từ tên khóa hoặc cấu trúc.
- **[Chưa biết]**: không có bằng chứng trong gói.

Giá là **USD cấp giá của store**. Cấu hình ghi đúng giá trị này (cột `Price` của `IapCatalogConfig`). Giá thật theo quốc gia do store quyết định.

## 0. Giới hạn cần biết trước

1. **Lịch xoay (rotation) và thời điểm bắt đầu/kết thúc sự kiện do server cấp.** Mã có `ApplyServerSchedule` và các lớp `*ScheduleEvent`. Trong APK chỉ có nội dung từng rotation, không có ngày. Hạn chế này ảnh hưởng đến Limited Offer, Choose-One, Festive và Collections.
2. **Số lượng gem của gói gem chính (`GemsPackS…XXL`) không có trong cấu hình đã đọc.** Chỉ có giá (1,99 đến 49,99 USD). Gem của gói gem **Sport Breaker** và **Grand Tour** có trong cấu hình (mục 4).
3. **Điều kiện hiển thị chỉ là một nửa bức tranh.** Thứ tự và thời điểm thực tế còn phụ thuộc hàng đợi popup (`PromptQueue`), trạng thái người chơi và dữ liệu server. Tôi chưa quan sát game chạy.
4. Một số điều kiện tham chiếu dữ liệu runtime (ví dụ `UniquePlayerAvailable`, `IapCarAvailable`, `EpicSkinAvailable`). Tôi chỉ biết tên, chưa biết cách tính.

---

## 1. Danh mục sản phẩm

**[Quan sát]** `IapCatalogConfig` có **259 SKU**, kèm enum `IapProductId` gồm 33 giá trị (từ 0 đến 33, thiếu giá trị 1). Tất cả đều khai báo loại `Consumable` (kể cả quyền lợi vĩnh viễn như `NoAds`).

| Họ sản phẩm | Số SKU | Giá (USD) |
|---|---:|---|
| Gói gem chính (`GemsPackS/M/L/XL/XXL`) | 5 | 1,99 / 4,99 / 9,99 / 19,99 / 49,99 |
| Gói gem Sport Breaker | 5 | 1,99 / 4,99 / 9,99 / 19,99 / 49,99 |
| Gói gem Grand Tour | 5 | 1,99 / 4,99 / 9,99 / 19,99 / 49,99 |
| Tiện ích: `NoAds`, `IncomeX2`, `IncomeX3`, `OfflineIncomeOffer`, `StarterPack` | 5 | 9,99 / 4,99 / 9,99 / 4,99 / 2,99 |
| Battle Pass (Rookie, Champion) | 2 | 4,99 / 19,99 |
| Gem Fund (Premium, VIP × 6 giai đoạn) | 12 | 4,99 / 19,99 |
| Monthly Pass (Daily Gem, Sprint, Gem Booster) | 3 | 9,99 / 4,99 / 9,99 |
| Sport Breaker: Race Pass, Reward Lane (Rookie, Champion) | 3 | 2,99 / 4,99 / 19,99 |
| Grand Tour: Pass, Reward Lane (Rookie, Champion) | 3 | 2,99 / 4,99 / 19,99 |
| Cầu thủ unique (6 môn × 10) | 60 | 9,99 |
| Xe Epic (6 loại) | 6 | 9,99 |
| Trang phục Epic (`PlayerOutfitEpic_1..5`) | 5 | 9,99 |
| Chain Offer (4 chuỗi) | 116 | 0,99 đến 99,99 |
| Choose-One Offer (3 rotation × 4 cỡ) | 12 | 1,99 đến 29,99 |
| Limited Offer (4 rotation × 3 slot) | 12 | 2,99 đến 29,99 |
| Seasonal Halloween | 3 | 4,99 / 9,99 / 19,99 |
| Google Level Up Program | 2 | 0 (tặng gem) |

Các thông tin nền:
- **Cầu thủ unique (60) khớp với 6 môn**, nên danh mục xác nhận ánh xạ tên: `Soccer…` ↔ "Stock Car Driver" (`stockcar_unique_driver_*`). Tên SKU xe: Racing, Rally, Superbike, Stock, Monster, Speedster.
- Mỗi SKU có hai mã store: mã thứ nhất (không có tiền tố, ví dụ `gems_499`) và mã thứ hai có tiền tố `rsi_` (ví dụ `rsi_gems_499`). Cột nhãn trong cấu hình là `GoogleId` và `AppleId`. Khoảng 11 SKU (chủ yếu Seasonal và Grand Tour) có mã đầu cũng mang tiền tố `rsi_`, nên quy ước này không nhất quán hoàn toàn.
- **Giá cố định ở mức giá USD nguyên, kết thúc bằng 0,99 hoặc 1,99.** Không có SKU nào ngoài các bậc này.

---

## 2. Gói tiện ích và quyền lợi

| SKU | Giá | Nội dung (suy từ tên và cấu hình) | Nhãn |
|---|---:|---|---|
| `StarterPack` | 2,99 | 255 gem, 500.000 coin, một avatar và một khung (`OfferRewardsConfig`) | Quan sát |
| `IncomeX2` | 4,99 | "Boosts your income x2" | Quan sát (mô tả) |
| `IncomeX3` | 9,99 | "Boosts your income x3" | Quan sát (mô tả) |
| `OfflineIncomeOffer` | 4,99 | "Booster triple offline income" (theo mã store `booster_triple_offline_income`) | Quan sát (mã), Suy luận (nội dung) |
| `NoAds` | 9,99 | "Get rewards without watching ads" | Quan sát (mô tả) |

- Cả năm SKU này đều là `Consumable` trong danh mục, nhưng cơ chế mua (một lần hay lặp) **[Chưa biết]**.
- Mô tả của `NoAds` cho thấy nó bỏ bước xem quảng cáo cho phần thưởng, chưa rõ có bỏ cả quảng cáo xen kẽ hay không.
- Thời hạn của `IncomeX2` và `IncomeX3` **[Chưa biết]**.

### 2.1. Monthly Pass **[Quan sát]**

| ID pass trong `MonthlyPassConfig` | SKU | Tên hiển thị | Giá | Mô tả trong danh mục | Thưởng khi mua | Thưởng hằng ngày | Bonus |
|---|---|---|---:|---|---|---|---|
| `DoubleSpeed` | `MonthlyPassDoubleSpeed` | Sprint Pass | 4,99 | "Double your game speed for 30 days" | 255 gem | không | loại 0, giá trị 1 |
| `OfflineGems` | `MonthlyPassDailyGem` | Daily Gem Pass | 9,99 | "Claim Gems every day for 30 days" | 520 gem | không (trong cấu hình) | loại 2 giá trị 1; loại 1 giá trị 600 |
| `DailyGems` | `MonthlyPassIdleGem` | Gem Booster Pass | 9,99 | "Get more Gems every day, even while away" | 255 gem | 50 gem | không |

- **Thời hạn là 30 ngày** cho các pass có mô tả ghi rõ (Sprint Pass, Daily Gem Pass). **[Quan sát]**
- **Có chỗ lệch giữa mô tả và cấu hình mà tôi không giải thích được.** SKU `MonthlyPassDailyGem` ("Claim Gems every day") ứng với pass `OfflineGems`, trong đó `DailyRewards` rỗng. SKU `MonthlyPassIdleGem` ("more Gems every day, even while away") ứng với pass `DailyGems`, trong đó có 50 gem mỗi ngày. Ánh xạ SKU → ID pass tôi lấy từ `IapProductId` trong `MonthlyPassConfig`. Có thể gem hằng ngày của "Daily Gem Pass" đến từ bonus loại 1 (600) hoặc từ nơi khác. **[Chưa biết]**
- Ý nghĩa của `BonusType` 0, 1, 2 là **[Suy luận]**: loại 0 là tăng tốc (khớp mô tả "Double your game speed"). Loại 1 (600) và loại 2 chưa xác định.

---

## 3. Battle Pass và Growth Fund

### 3.1. Battle Pass **[Quan sát]**
- 2 SKU: `BattlePassRookie` (4,99) và `BattlePassChampion` (19,99).
- 3 rotation. Số level và giảm giá hiển thị (đơn vị chưa xác định):

| Rotation | Level | `PremiumDiscount` | `PremiumPlusDiscount` |
|---:|---:|---:|---:|
| 0 | 30 | 750 | 1.000 |
| 1 | 50 | 1.000 | 1.200 |
| 2 | 50 | 1.000 | 1.200 |

- Nội dung level và phần thưởng 3 tầng: xem [race_star_team_manager.md](race_star_team_manager.md) mục 8.2. Quest ngày/tuần cấp `BattlePoints`.

### 3.2. Growth Fund (Sport Breaker và Grand Tour) **[Quan sát]**

| | Sport Breaker | Grand Tour |
|---|---|---|
| Rookie | `SportBreakerRewardLaneRookie`, 4,99 | `GrandTourRewardLaneRookie`, 4,99 |
| Champion | `SportBreakerRewardLaneChampion`, 19,99 | `GrandTourRewardLaneChampion`, 19,99 |
| Pass cơ bản | `SportBreakerSportPass`, 2,99 | `GrandTourPass`, 2,99 |
| Số level | 30 | 30 |
| Giảm giá hiển thị | 750 (Rookie), 900 (Champion) | 750, 900 |
| Level 0 | miễn phí 5 gem, Rookie 30, Champion 150 | giống |
| Level 1 (chi phí) | 2.250 | 2.000 |
| Level 29 (chi phí) | 120.000 | 105.000 |

- Ba tầng thưởng như Battle Pass: lane thường (miễn phí), Rookie, Champion. Tầng Champion thường gấp 5 lần tầng Rookie: ví dụ level 0 là 30 → 150 gem, level 1 là 1 → 5 gói gear Pro.
- **Gem Fund** (`GemFundPremium`/`GemFundVip` × 6 giai đoạn): 12 SKU, 4,99 và 19,99. **[Quan sát]** tên và giá. **[Chưa biết]** nội dung từng giai đoạn (cấu hình `GrowthFundConfig` chung không có trong các file đã đọc, chỉ có phần hiển thị `GrowthFundViewConfig` với ba lane).

---

## 4. Gói gem theo chế độ

| SKU | Giá | Gem (Sport Breaker) | Gem (Grand Tour) | Gem/USD |
|---|---:|---:|---:|---:|
| `*GemsPackS` | 1,99 | 1.000 | 1.000 | 503 |
| `*GemsPackM` | 4,99 | 2.550 | 2.550 | 511 |
| `*GemsPackL` | 9,99 | 5.200 | 5.200 | 520 |
| `*GemsPackXL` | 19,99 | 11.000 | 11.000 | 550 |
| `*GemsPackXXL` | 49,99 | 27.500 | 27.500 | 550 |

- Đây là gem của **chế độ riêng** (tên "Rush Gems" và "Grand Tour Gems"), khác gem của chiến dịch chính. Hai chế độ có bảng gem giống hệt nhau. **[Quan sát]**
- Gem/USD tăng nhẹ theo gói, từ 503 lên 550. Bonus tối đa khoảng 9 %.
- **Gói gem chính** (`GemsPackS…XXL`): giá có, số gem **[Chưa biết]**. Dự án tham khảo ghi 100/255/520/1.100/2.750 gem cho các mức tương đương (từ quan sát trên thiết bị, không phải từ APK này). Tôi không dùng số đó làm dữ liệu ở đây.
- Mỗi chế độ có thêm: tặng 100 gem khi xem quảng cáo (`_freeAdGemsAmount`), trần gem mỗi ngày 6.000 (`DailyGemCap`) và 10 gem mỗi trận (`_matchGemReward`). **[Quan sát]**

---

## 5. Offer xoay vòng

### 5.1. Chain Offer **[Quan sát]**
Bốn chuỗi, mỗi chuỗi mua tuần tự (mua gói 1 mới đến gói 2):

| Chuỗi | Số gói | Giá (USD) | Gem mỗi USD | Vé trong gói |
|---|---:|---|---:|---|
| `player_chain` | 28 | 0,99 → 99,99 | 50,5 → 55,0 | `Key_Player_StarterPack` (đầu), sau đó `Key_Player_ProPack` |
| `gear_chain` | 28 | như trên | như trên | `Key_Gear_*` |
| `player_chain_01` | 30 | 0,99 → 29,99 | 50,5 → 55,0 | `Key_Player_ProPack` |
| `gear_chain_01` | 30 | như trên | như trên | `Key_Gear_ProPack` |

Ví dụ `player_chain` (28 gói):

| Gói | Giá | Gem | Vé |
|---:|---:|---:|---|
| 1 | 0,99 | 50 | 5 Player Starter |
| 2 | 1,99 | 100 | 10 Player Starter |
| 3 | 2,99 | 150 | 15 Player Starter |
| 4 | 4,99 | 255 | 10 Player Pro |
| 5 | 9,99 | 520 | 18 Player Pro |
| 6 | 14,99 | 780 | 26 Player Pro |
| 10 | 34,99 | 1.925 | 58 Player Pro |
| 20 | 84,99 | 4.675 | 140 Player Pro |
| 26 đến 28 | 99,99 | 5.500 | 165 Player Pro |

- `player_chain` và `gear_chain` (28 gói): giá tăng 1 USD mỗi gói (2 lần), 2 USD (1 lần), 5 USD (19 lần) và 5 lần giá giữ nguyên. Gói 26 đến 28 cùng giá và nội dung (99,99; 5.500 gem; 165 vé). Hai chuỗi `_01` (30 gói) tăng đều 1 USD mỗi gói (0,99 đến 29,99).
- `Discount` là 400 ở hầu hết gói, 410 đến 440 ở các gói giữa chuỗi `_01`. Giá trị hiển thị, đơn vị chưa xác định.
- Hai chuỗi `_01` bắt đầu cao hơn về vé Pro (2 vé Pro ở gói 1) và dừng ở 29,99.
- **[Chưa biết]** Chuỗi nào đang hiển thị, hay chuỗi 28 gói và 30 gói có phải là hai phiên bản A/B hay hai giai đoạn. Cấu hình `_01` gợi ý một phiên bản sau, nhưng không có bằng chứng.

### 5.2. Limited Offer **[Quan sát]**
4 rotation × 3 slot. `DiscountPercent` luôn 600. Giới hạn mua: 1 lần mỗi slot ở rotation 1 đến 3, 5 lần ở rotation 4.

| Rotation | Slot | Giá | Nội dung |
|---:|---:|---:|---|
| 1 | 3 | 2,99 | 100 gem, 2 Player Pro, 2 Gear Pro, 5 Player Starter, 5 Gear Starter |
| 1 | 2 | 4,99 | 255 gem, 1 Choice Player Epic, 5 Pro/Gear Pro, 8 Starter |
| 1 | 1 | 9,99 | 520 gem, 1 Choice Player Legendary, 8 Pro, 12 Starter |
| 2 | 3 / 2 / 1 | 4,99 / 9,99 / 19,99 | 255 / 520 / 1.100 gem, Choice Epic / Legendary / Mythic |
| 3 | 3 / 2 / 1 | 9,99 / 19,99 / 29,99 | 520 / 1.100 / 1.650 gem, Choice Legendary / Mythic / Unique |
| 4 | 3 / 2 / 1 | 4,99 / 9,99 / 19,99 | 255 / 520 / 1.100 gem, Collection Pack (Rare, Epic, Legendary), 3 / 6 / 10 Pro |

- Lượng gem trong gói Limited tăng theo giá: 255 gem cho 4,99; 1.100 gem cho 19,99; 1.650 gem cho 29,99 (khoảng 51 đến 55 gem mỗi USD), chưa tính vé và các phần thưởng kèm theo.
- Rotation 4 chuyển sang Collection Pack (gói sưu tập), cho phép mua lại 5 lần.

### 5.3. Choose-One Offer **[Quan sát]**
3 rotation × 4 slot (S, M, L, All). Người chơi chọn một trong ba hướng (Rare, Epic, Legendary), hoặc mua gói "All" gồm cả ba.

| Rotation | S | M | L | All |
|---:|---|---|---|---|
| 1 | 1,99: 50 gem, Shard Rare ×10, 5 Player Starter | 4,99: 150 gem, Shard Epic ×10, 8 Player Pro | 7,99: 320 gem, Shard Legendary ×10, 8 Player Pro + 5 Starter | 9,99 |
| 2 | 4,99: 120 gem, Shard Rare ×25 | 9,99: 320 gem, Shard Epic ×25 | 14,99: 700 gem, Shard Legendary ×25 | 19,99 |
| 3 | 7,99: 200 gem, Shard Rare ×50 | 14,99: 500 gem, Shard Epic ×50 | 22,99: 950 gem, Shard Legendary ×50 | 29,99 |

- Giảm giá hiển thị: S = 300, M = 350 đến 375, L = 450 đến 500, All = 600.
- Gói "All" chứa đúng tổng ba gói S+M+L nhưng giá thấp hơn tổng các gói lẻ. Ví dụ rotation 1: 1,99 + 4,99 + 7,99 = 14,97 USD so với 9,99 USD. **[Quan sát]**
- "ShardBundle_*" liên quan đến shard skin (xem chủ đề `Skins` của Lucky Draw).

### 5.3b. Festive (Halloween) **[Quan sát]**

| SKU | Giá | Nội dung chính | Nội dung phụ | `ValuePercent` |
|---|---:|---|---|---:|
| `SeasonalOfferHalloween` | 4,99 | 255 gem, Choice Player Legendary | 5 + 5 Pro, 5 + 5 Starter (Player/Gear) | 750 |
| `SeasonalOfferHalloween2` | 9,99 | 520 gem, Choice Player Mythic | 7 mỗi loại | 800 |
| `SeasonalOfferHalloween3` | 19,99 | 1.100 gem, Choice Player Unique | 25 Pro, 15 Starter (Player/Gear) | 850 |

### 5.4. Unique Player, Xe Epic, Trang phục Epic **[Quan sát]**
- Cầu thủ unique: 6 môn × 10 người, **9,99 mỗi người**, mua tuần tự theo chuỗi (`ChainIndex` 0 đến 9).
- Xe Epic: 6 loại, 9,99.
- Trang phục Epic: 5 loại, 9,99.
- `OfferUniquePlayerViewConfig` chỉ chứa hình và mô tả (khóa `OFFER_UNIQUE_PLAYER_*`).

---

## 6. Điều kiện hiển thị (prompt)

### 6.1. Cơ chế **[Quan sát]**
Mỗi offer popup là một `PromptConfig` với các thành phần:

| Thành phần | Ý nghĩa |
|---|---|
| `GroupId` | Nhóm quyết định cách xếp hàng và ưu tiên |
| `CooldownInSeconds` | Khoảng nghỉ giữa hai lần hiện |
| `UnlockConditionData` | Điều kiện để popup đủ điều kiện hiện |
| `DismissConditionData` | Điều kiện làm popup biến mất |
| `PriorityCalculatorData` | Điểm ưu tiên (số nguyên) |
| `UpdaterSubscriptions` | Quy tắc ép đổi trạng thái (`ForceChangeState`) |

Trạng thái popup: `Available` (0), `Unlocked` (1), `Displayed` (2), `Dismissed` (3). **[Quan sát]**

### 6.2. Nhóm popup (`PromptGroupsConfig`) **[Quan sát]**
Tất cả nhóm chỉ kích hoạt tại `MainMenuPopupView` (màn hình chính).

| Nhóm | Ưu tiên | Hàng đợi ưu tiên cao | Reset cooldown | Hiện trên màn bất kỳ |
|---|---:|---|---|---|
| `System-HighPriority-Menu` | 9.999 | Có | Không | Có |
| `Superior` | 200 | Không | Có | Không |
| `Event` | 200 | Có | Có | Không |
| `HighValueOffer` | 100 | Không | Có | Không |
| `ForcedOffer` | 0 | Có | Có | Không |

- Thứ tự thực tế giữa `Priority` của nhóm và `Priority` của từng prompt **[Chưa biết]**.
- Chỉ có một nhóm hiện trên mọi màn hình (`System-HighPriority-Menu`). **[Quan sát]**

### 6.3. Điều kiện từng popup **[Quan sát]**
`MatchCount` là tổng số trận đã chơi ở bất kỳ môn nào (`OnAnySportMatchCount`).

| Popup | Nhóm | Cooldown | Điều kiện mở | Điều kiện ẩn / dừng | Ưu tiên |
|---|---|---:|---|---|---:|
| `2xOffer` (IncomeX2) | HighValue | 24 giờ | ≥ 5 trận | Đã mua `IncomeX2` | 300 |
| `3xOffer` (IncomeX3) | HighValue | 24 giờ | ≥ 5 trận | Đã mua `IncomeX3` | 100 |
| `3xOfflineOffer` | HighValue | 24 giờ | ≥ 5 trận | Đã mua `OfflineIncomeOffer` | 0 |
| `NoAdsOffer` | Superior | 24 giờ | ≥ 5 trận | Đã mua `NoAds` | 0 |
| `UniquePlayerOffer` | HighValue | 24 giờ | `PlayersUnlockConfig` (≥ 5 trận) **và** có cầu thủ unique khả dụng | (điều kiện không đọc được, xem 6.5) | chưa đọc được |
| `CarOffer` | HighValue | 24 giờ | `GarageContentUnlockConfig` (≥ 10 trận) **và** có xe IAP khả dụng | Không còn xe IAP khả dụng | 0 |
| `SkinsOffer` | HighValue | 24 giờ | Có skin Epic khả dụng và một điều kiện nữa (xem 6.5) | Không còn skin Epic khả dụng | chưa đọc được |
| `FreeCash` | ForcedOffer | 24 giờ | ≥ 2 trận **và** Almedia trạng thái Eligible **và** remote config bật | Đã liên kết Almedia | 0 |
| `LuckyDraw` | HighValue | 20 phút | Luôn đủ điều kiện | Sau 1 lần hiện | 300 |
| `GrandTour` | HighValue | 20 phút | Luôn đủ điều kiện | Sau 1 lần hiện | 300 |
| `SportBreaker` | HighValue | 20 phút | Luôn đủ điều kiện | Sau 1 lần hiện | 300 |
| `Festive` | HighValue | 20 phút | (không có điều kiện mở) | Sau 1 lần hiện | 110 |
| `ChooseOne` | ForcedOffer | 20 phút | Luôn đủ điều kiện | Không bao giờ | 300 |
| `LimitedOffer` | ForcedOffer | 20 phút | Luôn đủ điều kiện | Không bao giờ | 300 |
| `RateUs` | ForcedOffer | 5 ngày | Đã nhận gear đầu tiên **và** sau 15 giây | Đã yêu cầu rate **hoặc** đã hiện 1 lần | chưa đọc được |

- Cooldown 86.400 giây = 24 giờ. 1.200 giây = 20 phút. 432.000 giây = 5 ngày.
- `LuckyDraw`, `GrandTour`, `SportBreaker` chỉ mở popup khi sự kiện bật. Điều kiện "luôn đủ" ở đây chỉ là điều kiện cấu hình; việc sự kiện đang diễn ra do server quyết định. **[Suy luận]**
- `ChooseOne` và `LimitedOffer` có điều kiện "không bao giờ dừng" (`Never`), nên chúng tiếp tục hiện sau mỗi cooldown nếu còn đủ điều kiện. **[Suy luận]**

### 6.4. Cổng mở khóa tính năng (`UnlockConfig`) **[Quan sát]**

24 cổng, **số trận** (`MatchCount`) hoặc **số đội** (`TeamCount`, tức số môn đã mở):

| Điều kiện | Tính năng |
|---|---|
| Luôn mở | Đăng nhập (`Auth`) |
| ≥ 2 trận | Free Cash, Gear, Growth Fund, Starter Pack, Instant Cash Ad |
| ≥ 5 trận | Players, Shop Content, Gift Codes |
| ≥ 10 trận | Garage Content, Monthly Pass |
| ≥ 1 trận thắng | Trophy Upgrades |
| ≥ 2 đội | Career Player, Choose-One Offer, Festive Offer, Grand Tour, Guilds, Limited Offer, Lucky Draw, Sport Breaker |
| ≥ 3 đội | Arena, Guild Conquest |
| Theo `ShopContentUnlockConfig` (≥ 5 trận) | Battle Pass, Collections |

- **Shop mở sau 5 trận.** Battle Pass và Collections mở cùng lúc với Shop (tham chiếu đến cùng cổng). **[Quan sát]**
- **Starter Pack** mở sau 2 trận, trước cả Shop. **[Quan sát]**
- **Monthly Pass** mở muộn hơn Shop (10 trận). **[Quan sát]**
- Các offer xoay vòng (Choose-One, Limited, Festive) và các chế độ (Grand Tour, Sport Breaker, Lucky Draw) cần **hai môn trở lên**. Nghĩa là chúng gắn với việc người chơi đã mua môn thứ hai (giá 1M coin). **[Suy luận]**

### 6.5. Điều kiện chưa đọc hết
- `UniquePlayerOffer` có điều kiện dismiss và `SkinsOffer` có một điều kiện mở tham chiếu tới nút điều kiện không giải mã được (`<rid …?>`). **[Chưa biết]**
- `SkinsOffer` có `OnTeamCount` trong danh sách kiểu điều kiện, nhưng ngưỡng và vị trí chưa xác định.
- `TrophyUpgradesUnlockConfig` đã đọc: chỉ cần 1 trận thắng (`OnAnySportWinCount`).

### 6.6. Offer xoay vòng trên màn hình chính (`OfferRotationConfig`) **[Quan sát]**
Khi trận sắp kết thúc, game chọn một offer theo ưu tiên:
- Tham số `SecondsBeforeMatchEnd = 30` và `CooldownSeconds = 120`. Ý nghĩa chính xác (hiện ngay trước khi trận kết thúc 30 giây) là **[Suy luận]** từ tên trường.

| Offer | Ưu tiên |
|---|---:|
| `UniquePlayerOffer` | 9.999 |
| `NoAds` | 400 |
| `IncomeX2` | 300 |
| `MonthlyPass` | 300 |
| `IncomeX3` | 100 |
| `StarterPack` | 0 |
| `OfflineIncomeOffer` | 0 |

- Các banner tương ứng nằm trong `IapShopBannerView` (31 phiên bản). Banner shop dùng nhiều SKU khác nhau, ví dụ banner `NoAds`, banner `GemsPackXXL`, banner gói gem Sport Breaker.
- Ưu tiên banner ở trên khác với `Priority` của từng popup (mục 6.3). Ví dụ `IncomeX2` là 300 ở cả hai nơi, nhưng `NoAds` là 400 ở banner và 0 ở popup. **[Quan sát]** Hệ thống nào có quyền hơn khi cùng lúc có hai nguồn **[Chưa biết]**.
- Ba popup `RateUs`, `SkinsOffer`, `UniquePlayerOffer` có điểm ưu tiên được tính bằng cách khác nên cột "Ưu tiên" của chúng ghi "chưa đọc được". Con số nhìn thấy khi giải mã là mã nội bộ, không phải điểm.

---

## 7. Thiết kế tổng thể (tóm tắt rút ra)

**[Suy luận]** từ các số liệu trên:

1. **Phễu theo số trận.** Trận 2: Starter Pack (2,99). Trận 5: các tiện ích (IncomeX2/X3, NoAds, Offline) và Shop. Trận 10: Monthly Pass, Garage content. Khi có môn thứ hai: Limited, Choose-One, Festive, Grand Tour, Sport Breaker, Lucky Draw.
2. **Hai tầng thang giá.** Tầng thường: 1,99 đến 49,99 (gem). Tầng chuỗi: 0,99 đến 99,99, mỗi gói có thêm vé gacha.
3. **Đặt tiện ích rất sớm** (IncomeX2 sau 5 trận), nhưng chỉ mỗi 24 giờ, không dồn dập.
4. **Giảm giá được hiển thị bằng nhãn** (`Discount`, `ValuePercent`, `DiscountPercent`). Giá trị 300 đến 1.000 có thể là phần trăm nhân 100 hoặc nhãn "giá trị gấp N lần" (ví dụ `ValuePercent = 850` ↔ "giá trị 8,5 lần"). Ghi như vậy là phỏng đoán.
5. **Phần lớn doanh thu theo thiết kế đến từ gacha vé và gem.** Hầu hết gói có vé `Key_*` và gem; chỉ một số ít gói bán trực tiếp nội dung cố định (xe, trang phục, cầu thủ unique ở 9,99).

---

## 8. Chưa biết (tổng hợp)

| Câu hỏi | Lý do |
|---|---|
| Số gem của `GemsPackS…XXL` (gói gem chính) | Không có trong cấu hình đã đọc |
| Ngày bắt đầu/kết thúc rotation, lịch sự kiện | Do server cấp |
| Thứ tự ưu tiên giữa nhóm và từng prompt, tương tác với `OfferRotation` | Nằm trong mã |
| Thời hạn của IncomeX2/X3, cách tính bonus của Monthly Pass | Không có trong cấu hình (Monthly Pass đã biết là 30 ngày) |
| Gem hằng ngày của "Daily Gem Pass" nằm ở đâu | `DailyRewards` của pass `OfflineGems` rỗng, mô tả lại ghi nhận gem mỗi ngày |
| Nội dung từng giai đoạn Gem Fund | Không đọc được cấu hình |
| Đơn vị của `Discount`, `ValuePercent` | Chỉ biết là số nguyên hiển thị |
| Điều kiện của `UniquePlayerAvailable`, `IapCarAvailable`, `EpicSkinAvailable` | Nằm trong mã |
| Chuỗi nào trong 4 chuỗi Chain Offer đang chạy | Không có bằng chứng |
| Mức độ giá server có ghi đè | APK chỉ là cấu hình gốc |

### Phương pháp
- Giải mã `IapCatalogConfig` (259 bản ghi, đến đúng byte cuối 45.760/45.760).
- Giải mã đồ thị điều kiện của 16 `PromptConfig` và 24 `UnlockConfig` theo cấu trúc `managed reference` của Unity, đối chiếu kiểu với DLL giả của Cpp2IL. Phần lớn đọc đến đúng byte cuối; `FestiveOfferPromptConfig` chỉ đọc 396/536 byte, một số điều kiện (6.5) không giải mã được và được ghi là chưa biết.
- Enum `IapProductId`, `State`, `AlmediaLinkStatus` lấy từ DLL giả.
- Nội dung offer lấy từ ScriptableObject Odin (parser tự viết, đã dùng ở các tài liệu trước).
