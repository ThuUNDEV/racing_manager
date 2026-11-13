# Race Star – Team Manager: chỉ số nâng cấp của xe, gear và trường đua (v1.9.0)

Tài liệu bổ sung cho [race_star_team_manager.md](race_star_team_manager.md). Nguồn: ScriptableObject trong `com.coolcatsgames.racestaridle.apk` (Unity 6000.0.62f1).

- **[Quan sát]**: giá trị đọc trực tiếp từ file cấu hình.
- **[Suy luận]**: rút ra từ tên khóa, cấu trúc hoặc phép tính trên dữ liệu.
- **[Chưa biết]**: không có bằng chứng trong phạm vi đã phân tích.

## 0. Phạm vi và ba lưu ý bắt buộc đọc

1. **Game không có "đường đua" theo nghĩa hình học.** Cấu hình không có đoạn thẳng, cua, độ dài vòng hay độ bám. Thứ tương ứng với "trường đua" là:
   - **League** (chiến dịch chính): 10 league × 9 đội đối thủ với một số "power" cho mỗi đội.
   - **Grand Tour location** (7 địa điểm): mỗi nơi có 9 đối thủ, yêu cầu "Fame" để mở, trần trophy.
   - **Sport Breaker**: chế độ chỉ có Tennis, 10 league.
   Kết quả trận là so sánh power, không phải mô phỏng vật lý. **[Suy luận]** từ việc cấu hình chỉ có một con số power cho mỗi đội. Công thức quy đổi stat thành power nằm trong mã `MatchSimulation`, **[Chưa biết]**.
2. **Xe không có chỉ số tốc độ, bám cua hay phanh.** Mọi stat xe chỉ là hai số: `offense` và `defense` (cộng với `income`, `seat_count` từ nâng cấp). Tên "xe" và "môn" là hai lớp nhãn chồng nhau (xem mục 1).
3. **Nhãn "môn thể thao" trong dữ liệu là tên nội bộ.** Tôi dùng chúng nguyên văn vì dữ liệu dùng như vậy. Việc ghép (Basketball = Racing…) là suy luận trước đó, chưa kiểm chứng.

---

## 1. Các nhóm nâng cấp theo chế độ

Ba chế độ dùng cùng một khuôn dữ liệu (`Upgrade`: `Key`, `GroupKey`, `FeatureId`, `Levels[Cost, Effects, IsMilestone]`) nhưng khác số cấp và giá. **[Quan sát]**

| | Chiến dịch chính | Grand Tour | Sport Breaker |
|---|---|---|---|
| Số môn | 6 | 7 (thêm Tennis) | 1 (Tennis) |
| Nâng cấp Cash / môn | 8 | 8 | 8 |
| Nâng cấp Trophy / môn | 6 | 6 | 6 |
| League upgrade | 3 / môn (MaxTrophies, Income, CareerPlayerXP) | không thấy trong bảng nâng cấp | 2 (`Tennis_League_MaxTrophies`, `Tennis_League_Income`), 10 mức, nằm trong `SportBreakerUpgradesConfig` (không có CareerPlayerXP) |
| Cấp tối đa Cash | 300 (MaxSeats 100) | **100** | 300 (MaxSeats 100) |
| Cấp tối đa Trophy | 75 | **25** | **50** |
| Tiền Cash | `Coins` | `GrandTourCoins` | `BreakerCoins` |
| Tiền Trophy | `{Sport}Trophy` | `GrandTour{Sport}Trophy` | `BreakerTrophy` |
| Số nâng cấp | 102 | 98 | 16 (8 Cash + 6 Trophy + 2 League) |

### Stat hiệu ứng **[Quan sát]**
Mỗi nâng cấp cộng vào đúng một khóa stat theo mẫu `{prefix}{sport}_{stat}`:

| Stat | Ý nghĩa | Ghi chú |
|---|---|---|
| `*_offense_percentage` | Tấn công | Đơn vị hiển thị `Formating = 3` (phần trăm) |
| `*_defense_percentage` | Phòng thủ | như trên |
| `*_income` | Thu nhập cơ bản | `Formating = 9` |
| `*_income_percentage` | Thu nhập theo % (nâng cấp Trophy) | `Formating = 3` |
| `*_seat_count` | Số chỗ (sức chứa) | `Formating = 1` |
| `*_max_trophy_count` | Trần trophy của league | chiến dịch |
| `*_income_multiplier` | Hệ số nhân thu nhập league | chiến dịch |
| `*_career_player_xp` | Hệ số XP cầu thủ | chiến dịch |
| `any_sport_offense_percentage`, `any_sport_defense_percentage` | Bonus khi xe được trang bị, áp mọi môn | xe |
| Tiền tố `grandtour_` | Stat riêng của Grand Tour | Grand Tour |

`StatViewConfig` định nghĩa 121 stat để hiển thị.

---

## 2. Nâng cấp Cash

### 2.1. Chiến dịch chính **[Quan sát]**

| Nâng cấp | Hiệu ứng mỗi cấp | Giá cấp 1 | Cấp tối đa | Hiệu ứng tối đa |
|---|---:|---:|---:|---:|
| Offense_1 | +2 | 25 | 300 | +600 |
| Offense_2 | +3 | 50 | 300 | +900 |
| Defense_1 | +2 | 35 | 300 | +600 |
| Defense_2 | +3 | 70 | 300 | +900 |
| Income_1 | +0,05 (nền 0,1) | 10 | 300 | 15,1 |
| Income_2 | +0,15 | 50 | 300 | 45 |
| Income_3 | +0,25 | 150 | 300 | 75 |
| MaxSeats | +5 (nền 10) | 500 | 100 | 510 |

Giá một vài mốc của Offense_1: L5 = 185, L10 = 1.210, L25 = 1,43·10⁵, L50 = 1,97·10⁸, L100 = 1,93·10¹⁴, L300 = 3,5·10³⁷.

### 2.2. Grand Tour (môn Basketball, nền) **[Quan sát]**

| Nâng cấp | Hiệu ứng mỗi cấp | Giá L1 | L10 | L50 | L100 | Hiệu ứng L100 |
|---|---:|---:|---:|---:|---:|---:|
| Offense_1 | +3 | 200 | 4.740 | 3,12·10⁷ | 7,88·10⁹ | +300 |
| Offense_2 | +5 | 400 | 35.100 | 1,34·10⁹ | 3,58·10¹¹ | +500 |
| Defense_1 / _2 | như Offense | như Offense | | | | |
| Income_1 | +1 (nền 1) | 100 | 2.370 | 1,56·10⁷ | 3,94·10⁹ | 101 |
| Income_2 | +2 | 300 | | | 2,33·10¹⁰ | 200 |
| Income_3 | +3 | 900 | 54.700 | 4,08·10⁸ | 1,04·10¹¹ | 300 |
| MaxSeats | +5 (nền 10) | 2.500 | 4,08·10⁵ | 7,6·10¹⁰ | 7,6·10¹⁶ | 510 |

Tổng chi phí để max một môn Grand Tour (Basketball), không tính Trophy: Offense_1 7,8·10¹⁰, Offense_2 3,5·10¹², Income_1 3,9·10¹⁰, Income_2 2,3·10¹¹, Income_3 1,0·10¹², MaxSeats 3,2·10¹⁷.

### 2.3. Sport Breaker (Tennis) **[Quan sát]**

| Nâng cấp | Hiệu ứng mỗi cấp | Giá L1 | Giá L300 | Hiệu ứng L300 | Tổng chi phí tới max |
|---|---:|---:|---:|---:|---:|
| Offense_1 | +3 | 200 | 3,79·10²⁰ | +900 | 4,0·10²¹ |
| Offense_2 | +5 | 400 | 1,74·10²² | +1.500 | 1,85·10²³ |
| Defense_1 / _2 | như Offense | | | | |
| Income_1 | +1 (nền 1) | 100 | 1,89·10²⁰ | 301 | 2,0·10²¹ |
| Income_2 | +2 | 300 | 1,13·10²¹ | 600 | 1,2·10²² |
| Income_3 | +3 | 900 | 5,08·10²¹ | 900 | 5,4·10²² |
| MaxSeats (100 cấp) | +5 | 2.500 | 7,6·10¹⁶ (L100) | 510 | 3,2·10¹⁷ |

### 2.4. Đường chi phí theo cấp **[Quan sát, tính từ dữ liệu]**

Hệ số tăng chi phí `cost[L+1]/cost[L]` giảm dần theo cấp:

| Nâng cấp | L1→2 | L10→11 | L25→26 | L50→51 | L99→100 |
|---|---:|---:|---:|---:|---:|
| Chiến dịch Offense_1 | ×1,80 | ×1,42 | | ×1,33 | ×1,32 |
| Grand Tour Offense_1 | ×1,68 | ×1,31 | ×1,24 | ×1,22 | ×1,11 |
| Sport Breaker Offense_1 | ×1,68 | ×1,31 | ×1,24 | ×1,22 | ×1,16 |

- Giá Grand Tour (Basketball) và Sport Breaker (Tennis) **trùng nhau từ L0 đến L51** rồi tách từ **L52** (Offense_1 và Income_1; MaxSeats trùng toàn bộ 100 cấp). Sau đó Sport Breaker đắt hơn dần so với Grand Tour: ×1,5 ở L60, ×3,6 ở L80, ×8,8 ở L100. **[Quan sát]** Hệ số L99→L100 là ×1,11 (Grand Tour) và ×1,16 (Sport Breaker). **[Suy luận]** Hai bảng chung công thức cho 51 cấp đầu; Grand Tour dừng ở L100 nên có thể được cắt hoặc làm phẳng đoạn cuối. Chưa tìm được công thức.
- Hiệu ứng luôn tuyến tính theo cấp (không có mốc nhảy; cờ `IsMilestone` đều `false` trong các nâng cấp đã đọc).
- Giá L1 → L100 của Grand Tour Offense_1 tăng ×3,94·10⁷.

### 2.5. Đặc điểm của Grand Tour: mỗi môn đắt hơn nhiều **[Quan sát]**

Cùng một nâng cấp, giá L1 theo môn (theo thứ tự `RouteOrder`):

| RouteOrder | Môn | Giá L1 (Offense_1) | Hệ số L1 so với môn trước |
|---:|---|---:|---:|
| 1 | Basketball | 200 | — |
| 2 | Soccer | 2,4·10⁶ | ×12.000 |
| 3 | Hockey | 4,4·10⁸ | ×183 |
| 4 | Football | 9,4·10¹⁰ | ×214 |
| 5 | Volleyball | 4,2·10¹³ | ×447 |
| 6 | Baseball | 2,6·10¹⁶ | ×619 |
| 7 | Tennis | 4,4·10¹⁹ | ×1.692 |

- Hiệu ứng mỗi cấp giống hệt ở mọi môn (+3 cho Offense_1, v.v.), chỉ có **giá** thay đổi.
- Hai nhóm hình dạng khác nhau: Basketball, Soccer, Hockey có `L100/L1 ≈ 3,9·10⁷`; Football, Volleyball, Baseball, Tennis có `L100/L1 ≈ 4,7·10⁶` và đường cong phẳng hơn (×1,25 tại L10→11 thay vì ×1,31). **[Suy luận]** Có hai họ công thức giá, đổi họ giữa Hockey và Football.
- **Lưu ý khi đọc:** `GrandTourLocationsConfig` ghi Location 5 là `Sport=4` với `CashGroup = GrandTour_Volleyball_Cash`, location 6 là `Sport=5` với `GrandTour_Baseball_Cash`. Chỉ số `Sport` là enum nội bộ, mà thứ tự tên của nó khác với các bảng chiến dịch. Tôi dùng tên khóa trong chuỗi (Volleyball ở route 5, Baseball ở route 6). Bảng ở trên theo `RouteOrder` và tên khóa.

---

## 3. Nâng cấp Trophy

### 3.1. Luật chung **[Quan sát]**
Cấp N tốn đúng N trophy. Hiệu ứng tuyến tính.

| Chế độ | Cấp tối đa | Offense/Defense mỗi cấp | Income % mỗi cấp | Tổng trophy để max 1 nâng cấp | Tổng 6 nâng cấp/môn |
|---|---:|---:|---:|---:|---:|
| Chiến dịch | 75 | +10 | +20 | 2.850 | 17.100 |
| Sport Breaker | 50 | +10 | +20 | 1.275 | 7.650 |
| Grand Tour | 25 | +10 | +20 | 325 | 1.950 |

Hiệu ứng tối đa: Grand Tour 250 (Off/Def) và 500 (Income); Sport Breaker 500 và 1.000; chiến dịch 750 và 1.500.

### 3.2. Trần trophy **[Quan sát]**

| Chế độ | Trần theo league (0→9) |
|---|---|
| Chiến dịch | 100, 300, 600, 1.000, 1.500, 2.100, 2.800, 3.600, 4.500, 5.500 |
| Sport Breaker (`Tennis_League_MaxTrophies`) | 50, 225, 500, 850, 1.300, 1.850, 2.450, 3.200, 4.000, 4.000 |
| Grand Tour (`TrophyCap` mỗi location) | 1.000 cố định cho cả 7 địa điểm |

- Sport Breaker: league 8 và 9 cùng trần 4.000, tức league 9 không tăng thêm. **[Suy luận]** Có thể là lỗi dữ liệu hoặc ý đồ; không có bằng chứng nào.
- Trần Grand Tour (1.000) lớn hơn tổng để max 6 nâng cấp (1.950)? Không: 1.950 > 1.000, nên một địa điểm không thể max toàn bộ nâng cấp Trophy chỉ bằng trần của chính nó. **[Suy luận]** Trophy của Grand Tour là tiền riêng cho từng môn (`GrandTour{Sport}Trophy`), không cộng dồn giữa các địa điểm.

### 3.3. Hệ số league **[Quan sát]**

| League | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Chiến dịch: Income × | 1 | 10 | 50 | 200 | 500 | 1.000 | 2.000 | 4.000 | 8.000 | 16.000 |
| Sport Breaker: Income × | 1 | 10 | 100 | 1.000 | 5.000 | 25.000 | 125.000 | 500.000 | 2.000.000 | 8.000.000 |

Sport Breaker có hệ số league lớn hơn chiến dịch **500 lần** ở league 9 (8.000.000 so với 16.000). (`SportBreakerLeaguesConfig.AdvanceBonusesByLeague` chỉ chứa chỉ số league 0 đến 9, không phải hệ số.)

---

## 4. Xe (Garage)

### 4.1. Cấu trúc **[Quan sát]**
- 24 xe = 6 môn × 4 rarity (0, 2000, 3000, 4000). Rarity 0 là xe khởi đầu, không có hiệu ứng.
- Mỗi xe rarity > 0 có 11 mức (L0–L10).
- **Cả sáu môn dùng cùng một bảng xe**: so sánh từng rarity, mọi mức `Cost`, `OwnedEffects` và `DuplicateShardBundle` của 5 môn còn lại trùng khớp với Basketball.

### 4.2. Bảng stat và chi phí theo rarity **[Quan sát]**

| Rarity | Tên (suy luận) | Stat khi sở hữu L0 | Mỗi cấp | Stat L10 | Chi phí L0 | Chi phí mỗi cấp | Tổng L0–L10 | Bonus khi trang bị (mọi môn) | `DuplicateShardBundle` |
|---:|---|---:|---:|---:|---:|---:|---:|---|---:|
| 2000 | Rare | 20 | +10 | 120 | 50 | +75 | 4.175 | Off/Def +10 | 343 |
| 3000 | Epic | 50 | +20 | 250 | 50 | +35 | 1.975 | Off/Def +20 | 353 |
| 4000 | Legendary | 100 | +30 | 400 | 50 | +10 | 600 | Off/Def +50 | 363 |

- "Stat khi sở hữu" cộng vào đúng **một môn**: ví dụ `basketball_offense` và `basketball_defense` cùng giá trị.
- "Bonus khi trang bị" chỉ có ở L0 và áp cho **mọi môn** (`any_sport_*`). **[Suy luận]** Chỉ một xe được trang bị tại một thời điểm.
- **Chi phí L0 là 50 ở cả ba rarity, nhưng L1 của Epic là 35 và Legendary là 10.** Phần chi phí L0 có vẻ là giá mua, các mức sau là giá nâng cấp. **[Suy luận]**, đơn vị chưa xác định (có thể là shard).
- Rarity cao nâng cấp **rẻ hơn**: tổng 600 so với 4.175. Hiệu ứng mỗi cấp cũng cao hơn, nên rarity cao tăng sức mạnh nhanh hơn và rẻ hơn. Đổi lại việc nhận được xe khó hơn.

### 4.3. Hiệu quả chi phí **[tính từ dữ liệu]**

| Rarity | Stat tăng L0→L10 | Chi phí L1–L10 | Chi phí cho mỗi điểm stat |
|---:|---:|---:|---:|
| Rare | 100 | 4.125 | 41,3 |
| Epic | 200 | 1.925 | 9,6 |
| Legendary | 300 | 550 | 1,8 |

### 4.4. Mở khóa xe (`CarUnlockConfig`) **[Quan sát]**
Mỗi môn có 4 xe với 4 kiểu mở khóa (`Type` 0 đến 3):
- `Type 0` (r0): mặc định.
- `Type 1` (r2): giá trị `500`. Đơn vị chưa rõ (chưa xác định đó là coin, gem hay shard).
- `Type 2` (r3): gắn với một xe được đặt tên (ví dụ `CarRacingEpic_01`, `CarStockEpic_01`, `CarRallyEpic_01`, `CarSuperbikeEpic_01`, `CarMonsterEpic_01`, `CarSpeedsterEpic_01`). Đây là tên asset xe theo loại, khớp 6 môn. **[Suy luận]** Đây là bằng chứng gián tiếp cho phép ghép môn với loại xe.
- `Type 3` (r4): loại riêng, không có giá trị.

---

## 5. Gear

### 5.1. Chiến dịch (`GarageConfig._gearData`) **[Quan sát]**
- 48 gear = 6 môn × 8.
- Mỗi gear 25 mức; stat tăng đều **+20** mỗi mức (L0 = 20, L24 = 500).
- 4 gear đầu của mỗi môn cộng `offense`, 4 gear sau cộng `defense`.
- Sáu môn dùng cùng giá trị.
- Giá nâng cấp gear không có trong bảng này. **[Chưa biết]** (nhiều khả năng dùng shard).
- Giá gear pack: 10 gem cho 1 gói.

### 5.2. Grand Tour (`GrandTourGearConfig`) **[Quan sát]**
- 63 gear = 7 môn × 9, mỗi gear 11 mức (L0–L10).
- Có **chi phí thật**: mỗi mức tốn `(L+1) × k` với k = 100 (Rare), 200 (Epic), 300 (Legendary).
- Phân bố 9 gear/môn: 3 Rare, 3 Epic, 3 Legendary. Trong mỗi nhóm có 1 gear cộng cả offense lẫn defense, 1 chỉ offense, 1 chỉ defense.

| Gear | Stat L0 | Mỗi cấp | Stat L10 | Chi phí L0 | Chi phí mỗi cấp | Tổng L0–L10 |
|---|---:|---:|---:|---:|---:|---:|
| Rare, kép (Off+Def mỗi cái) | 20 | +5 | 70 | 100 | +100 | 6.600 |
| Rare, đơn | 40 | +10 | 140 | 100 | +100 | 6.600 |
| Epic, kép | 40 | +10 | 140 | 200 | +200 | 13.200 |
| Epic, đơn | 80 | +20 | 280 | 200 | +200 | 13.200 |
| Legendary, kép | 80 | +20 | 280 | 300 | +300 | 19.800 |
| Legendary, đơn | 160 | +40 | 560 | 300 | +300 | 19.800 |

- Một gear kép có tổng hai stat bằng gear đơn (ví dụ 20 + 20 = 40). **[Suy luận]** Gear kép không cho thêm giá trị, chỉ chia đều.
- Đường cong gear **giống nhau cho cả 7 môn** (không khác theo môn, đã kiểm tra).
- Hiệu quả: Rare 6.600 chi phí cho +50 (đơn: +100). Legendary đơn: 19.800 cho +400. Chi phí trên mỗi điểm stat tăng thêm: Rare đơn 66, Epic đơn 66, Legendary đơn 49,5.

### 5.3. Sport Breaker
`SportBreakerGearConfig` (9.244 byte) liệt kê gear Tennis (`Tennis_Gear1_Rare`…). **[Chưa biết]** Giá trị chi tiết chưa đọc (bố cục khác Grand Tour).

---

## 6. Đối thủ và "trường đua"

### 6.1. League (chiến dịch) — `SportLeaguesConfig` **[Quan sát]**
- 10 league × 9 đội mỗi league. Mỗi đội có một số `PlayerPower`.
- Ở `unlockOrder` 0:

| League | Team 0 | Team 4 | Team 8 | Tỉ lệ T8/T0 |
|---:|---:|---:|---:|---:|
| 0 | 40 | 80 | 200 | ×5,0 |
| 1 | 140 | 217 | 450 | ×3,2 |
| 2 | 315 | 536 | 1.200 | ×3,8 |
| 3 | 840 | 1.305 | 2.700 | ×3,2 |
| 4 | 1.890 | 2.842 | 5.700 | ×3,0 |
| 5 | 3.990 | 5.917 | 11.700 | ×2,9 |
| 6 | 8.190 | 12.067 | 23.700 | ×2,9 |
| 7 | 16.590 | 24.367 | 47.700 | ×2,9 |
| 8 | 33.390 | 42.967 | 71.700 | ×2,2 |
| 9 | 50.190 | 61.567 | 95.700 | ×1,9 |

- Đội mạnh nhất league n (T8) nhân **0,7 lần** đội yếu nhất league n+1 (T0) đối với cả 9 cặp. Nghĩa là mỗi league mở đầu thấp hơn 30 % so với đỉnh league trước. **[Quan sát]**
- Mức tăng power giữa T0 của hai league liên tiếp giảm dần: ×3,5, ×2,25, ×2,67, ×2,25, ×2,11, ×2,05, ×2,03, ×2,01, ×1,50.

**Độ khó theo thứ tự mở môn (`unlockOrder` 0 → 5):** nhân đều toàn bộ power của mọi đội.

| unlockOrder | Hệ số nhân (min–max) | Trung bình |
|---:|---|---:|
| 0 | 1,0000 | 1,0000 |
| 1 | 1,0200–1,0323 | 1,0294 |
| 2 | 1,0400–1,0625 | 1,0590 |
| 3 | 1,0600–1,0915 | 1,0886 |
| 4 | 1,0952–1,1207 | 1,1185 |
| 5 | 1,1400–1,1530 | 1,1496 |

Hệ số của đội đầu mỗi league (`team_0`) theo league: ở `unlockOrder` 3 từ 1,075 (league 0) lên khoảng 1,09 (league 4 trở đi); ở `unlockOrder` 5 gần như phẳng 1,15. **[Quan sát]** Hệ số hơi khác nhau giữa các đội, nên không phải một phép nhân đơn thuần; chưa rõ công thức. Số `unlockOrder` ở đây là thứ tự mở môn của người chơi, theo luật từ cấu hình.

### 6.2. Grand Tour — `GrandTourLocationsConfig` **[Quan sát]**
7 địa điểm, mỗi địa điểm 9 đối thủ có tên riêng. Hệ thống tên giống nhau ở mọi địa điểm: Turbo Karts, Apex Racers, Drift Wheels, Nitro Engines, Slick Drivers, Redline Rockets, Grip Pistons, Boost Chargers, Vortex Hornets.

| Địa điểm | Môn | Fame cần để mở | Trần trophy | Power T0 | Power T8 | Hệ số hình học `r` |
|---:|---|---:|---:|---:|---:|---:|
| 1 | Basketball | 0 | 1.000 | 900 | 10.000 | 1,351 |
| 2 | Soccer | 3.900 | 1.000 | 900 | 12.000 | 1,382 |
| 3 | Hockey | 9.700 | 1.000 | 900 | 14.000 | 1,409 |
| 4 | Football | 19.000 | 1.000 | 900 | 16.000 | 1,433 |
| 5 | Volleyball | 33.000 | 1.000 | 900 | 18.000 | 1,454 |
| 6 | Baseball | 55.000 | 1.000 | 900 | 20.000 | 1,474 |
| 7 | Tennis | 79.000 | 1.000 | 900 | 22.000 | 1,491 |

- T0 luôn là 900; T8 tăng +2.000 mỗi địa điểm (10.000, 12.000, …, 22.000).
- Dãy power trong một địa điểm là cấp số nhân gần đúng (lệch tối đa 0,33 % so với hình học thuần), tỉ số `r` từ 1,35 đến 1,49.
- Fame cần để mở: 0, 3.900, 9.700, 19.000, 33.000, 55.000, 79.000. Khoảng cách tăng dần (3.900, 5.800, 9.300, 14.000, 22.000, 24.000).
- Giá nâng cấp Cash tăng mạnh theo địa điểm (mục 2.5), trong khi sức mạnh đối thủ chỉ tăng ×2,2 từ địa điểm đầu đến địa điểm cuối.

### 6.3. Tham số chung của Grand Tour và Sport Breaker (`GrandTourConfig`) **[Quan sát một phần]**
Đọc từ `GrandTourConfig` (dữ liệu nhị phân, đã đối chiếu vị trí trường với tên trường trong DLL):

| Tham số | Giá trị |
|---|---:|
| `_fixedDriverOffense` / `_fixedDriverDefense` | 500 / 500 |
| `DailyGemCap` | 6.000 |
| `_matchGemReward` | 10 |
| `OfflineMaxSeconds` | 7.200 (2 giờ) |
| `OfflineMinSeconds` | 300 (5 phút) |
| `OfflineMatchCycleSeconds` | 60 |
| `OfflineIdleEfficiency` | 0,25 |
| `_gemPacks` (5 gói: mã sản phẩm / gem) | 24/1.000, 25/2.550, 26/5.200, 27/11.000, 28/27.500 |
| `_freeAdGemsAmount` | 100 |

- **Tay đua cố định 500/500** (`_fixedDriverOffense/Defense`). **[Suy luận]** Trong Grand Tour, stat của tay đua không do người chơi điều chỉnh mà cố định 500; sức mạnh đến từ xe, gear và nâng cấp.
- Hiệu suất offline chỉ 0,25 và chu kỳ trận giả lập 60 giây. **[Suy luận]** Thu nhập offline được tính bằng cách giả lập các trận 60 giây trong tối đa 2 giờ.
- Các trường sau `_gemPacks` (`_cashTiers`, `_ad*`, `_pass*`) **chưa đọc được đáng tin cậy** (tôi thử đọc nhưng bố cục sai). **[Chưa biết]**

---

## 7. Cách các stat kết hợp thành sức mạnh

**Phần này là suy luận, chưa kiểm chứng bằng mã nguồn `MatchSimulation`.**

| Nguồn | Stat đóng góp | Phạm vi |
|---|---|---|
| Nâng cấp Cash (Offense/Defense) | `{sport}_offense_percentage`, `_defense_percentage` | theo môn |
| Nâng cấp Trophy | như trên | theo môn |
| Xe sở hữu (OwnedEffects) | `{sport}_offense`, `_defense` | theo môn |
| Xe trang bị (EquippedEffects) | `any_sport_*_percentage` | mọi môn |
| Gear | `{sport}_offense`, `_defense` | theo môn |
| Skill tree nhân vật | `{sport}_career_player_offense/defense` | theo môn |
| Tay đua cố định (Grand Tour) | 500 / 500 | Grand Tour |

- Hậu tố `_percentage` ở nâng cấp và xe, so với không hậu tố ở stat của xe/gear, cho thấy hai kiểu cộng: **cộng phẳng** (xe, gear, tay đua) và **cộng theo phần trăm** (nâng cấp, bonus trang bị). Không có bằng chứng về thứ tự áp dụng hay công thức nhân.
- **Thang giá trị:** ví dụ campaign: một gear L24 cho +500 phẳng, một xe Legendary L10 cho +400, trong khi Offense_1 L300 cho +600 %. **[Suy luận]** Với các `_percentage` khoảng vài trăm, giá trị phần trăm có thể lớn hơn nhiều so với 100 %, tức là hệ số nhân tới 7 lần. Chưa thể xác nhận nếu không có công thức.

---

## 8. Điểm cân bằng nổi bật

1. **Gear Grand Tour rẻ hơn nhiều so với nâng cấp Cash.** Tổng gear 19.800 cho một gear Legendary so với 10¹⁰–10¹⁷ coin cho nâng cấp Cash; hai loại dùng tiền khác nhau nên không so trực tiếp được. **[Chưa biết]** đơn vị tiền của gear.
2. **Xe rarity cao rẻ hơn** (4.3). Điều này đảo ngược chiều thông thường của tiến trình.
3. **Hiệu ứng nâng cấp tuyến tính, giá giảm tốc độ tăng.** Nâng cấp Cash sau L50 có hệ số giá ×1,11–1,32 mỗi cấp; nâng cấp đầu có ×1,6–2,5.
4. **Grand Tour tách biệt kinh tế theo môn:** giá L1 tăng ×183 đến ×12.000 giữa hai địa điểm liên tiếp, nhưng sức mạnh đối thủ chỉ tăng +2.000.
5. **Tennis ở Sport Breaker có hệ số league lớn nhất (8.000.000)** nhưng trần trophy thấp hơn chiến dịch ở nhiều league.
6. **Một số giá trị có thể là sai sót dữ liệu:** trần trophy Sport Breaker league 9 trùng league 8 (4.000); `Sport` enum và tên khóa lệch nhau ở Grand Tour location 5-6.

---

## 9. Chưa biết / chưa xác minh

| Câu hỏi | Lý do |
|---|---|
| Công thức quy đổi stat thành power, kết quả trận | Nằm trong mã `MatchSimulation` (IL2CPP, không giải mã được) |
| Giá nâng cấp gear chiến dịch | Không có trong `GarageConfig` |
| Đơn vị tiền của gear và xe | Cấu hình không ghi loại |
| `_cashTiers`, `_ad*`, `_pass*` của Grand Tour/Sport Breaker | Đọc sai bố cục |
| Gear của Sport Breaker | Chưa parse |
| `Fame` được tính thế nào | Không có công thức |
| Giá trị chính xác của "Formating" 1, 3, 9 | Chỉ biết là mã định dạng hiển thị |
| Bản gốc và giá server | APK này đã được đóng gói lại và có thể bị server ghi đè |

### Phương pháp
- Giải mã ScriptableObject: parser Odin tự viết cho chiến dịch và Garage; đọc tuần tự các trường nhị phân cho Grand Tour/Sport Breaker, kiểm chứng bằng kết thúc chính xác tại cuối dữ liệu (98 nâng cấp Grand Tour tới byte 626.272/626.272; 16 nâng cấp Sport Breaker tới byte 172.732/172.732; 63 gear tới byte 50.880/54.100 trước các bảng phụ).
- Tên trường lấy từ DLL giả do Cpp2IL tạo, còn thứ tự và kiểu đọc bằng thử và sai. Các phép tính phụ (tỉ lệ, tổng) tôi chạy bằng script riêng.
