# 34. Đặc tả layer và layout (bản đang chạy)

Ngày 17/11/2026 · **Tài liệu dựng layout, trích từ cây node thật của `ui/main.gd` khi chạy game**, không phải từ ảnh hay thiết kế đề xuất. Dùng khi dựng/đối chiếu giao diện; mọi số liệu có thể kiểm lại bằng cách chạy lại script dump (§10).

## 0. Quy ước

| Mục | Giá trị |
|---|---|
| Viewport thiết kế | 886 × 1920 px (`project.godot`), `stretch/mode=canvas_items`, `scale=2.2718` |
| **Đơn vị trong tài liệu** | **logical px = 389.99 × 845.14** (886 ÷ 2.2718). Mọi `x y w h` bên dưới theo đơn vị này, gốc (0,0) ở góc trên trái |
| Khung dọc | màn hình 9:19.5 cố định; lề ngang chuẩn **12**, khoảng cách dọc giữa khối **6–8** |
| Chạm tối thiểu | 44 × 44 (nút HUD tròn 44, nút cài đặt 48) |
| Ngôn ngữ nhãn | tiếng Anh (mặc định), có `vi/id/ms/th/ja/ko/zh_Hans` qua `I18n` |

Cây gốc của `Main`:

```text
Main (Control, full rect 390×845)
├─ ColorRect            nền toàn màn hình
├─ HeaderScenery        TextureRect 0,0 390×140   ảnh khán đài làm nền HUD (ẩn bớt ở Shop)
├─ MarginContainer (full rect, lề 12 trái/phải, 14 trên)
│  └─ VBoxContainer 12,14 365×823
│     ├─ HBox  Header HUD            y14   h48
│     ├─ VBox  RaceBlock (khung đua) y70   h494   ← chỉ Race/Bag/Team
│     ├─ Control  Content            y572  h191  (Race/Bag/Team)  |  y70 h693 (League/Shop)
│     └─ BottomNavigation            y771  h66
├─ ShopReferenceShell   chỉ tab Shop: phủ 0,64 390×781 (thay vùng Content + nav riêng)
├─ Overlay              popup chung (Settings, Offline, Info…)
├─ PlayerProfile        popup toàn màn hình
├─ ClassPage            popup toàn màn hình
├─ DailyRewardsPopup    popup phủ 0,61 390×722
└─ TutorialOverlay      phủ toàn màn hình, trên cùng
```

## 1. Hệ layer (z-order từ dưới lên)

| Layer | Nội dung | Rect | Hiện ở |
|---|---|---|---|
| **L0 Nền** | `ColorRect` + `HeaderScenery` (ảnh khán đài) | 0,0 390×845 / ảnh 0,0 390×140 | mọi tab |
| **L1 HUD** | avatar, tiền, gem, cài đặt | 12,14 365×48 | mọi tab |
| **L2 Dải giải** | chip giải, thu nhập/s, quà ngày | 12,70 365×44 | Race, Gear, Team |
| **L3 Khung đua** | thông số đội, hạng/lap, ×2 quảng cáo, khán đài, đường đua | 12,120 365×419 | Race, Gear, Team |
| **L4 Nội dung** | trang theo tab (cuộn dọc) | xem §3 | mọi tab |
| **L5 Nav đáy** | 5 tab | 12,771 365×66 | mọi tab (Shop dùng nav riêng, §3.6) |
| **L6 Popup** | overlay/profile/class/daily + scrim | §5 | khi mở |
| **L7 Tutorial** | spotlight, thoại Linh, tay chỉ | full rect | khi có hướng dẫn |

Quy tắc ẩn/hiện:

- Race/Gear/Team: L2 + L3 hiện, L4 cao 191.
- League: ẩn L2 + L3, L4 chiếm y70–763 (cao 693).
- Shop: ẩn L2 + L3; `ShopReferenceShell` thay L4 và có nav riêng (§3.6).
- Khung đua ghim cùng kích thước ở Race/Gear/Team (`RACE_HEIGHT = 400`, co lại nếu màn thấp: `min(400, w×0.9+60)` và `h−340`).

## 2. Layer dùng chung

### 2.1 L1 HUD (y14, h48)

```text
x12            x60              x194             x329 x377
┌────┐ ┌───────────────┐ ┌───────────────┐ ┌────┐
│ava │ │ 💵  1K        │ │ 💎  100       │ │ ⚙  │
└────┘ └───────────────┘ └───────────────┘ └────┘
44×44    130×46            131×46            48×48
```

| Node | Rect | Ghi chú |
|---|---|---|
| `PlayerProfileButton` | 12,14 44×44 | mở Hồ sơ (`_show_profile`); icon `PlayerAvatarIcon` 44×44 |
| `HudCoins` | 60,14 130×46 | pill 116×34 tại x74,y20 + icon cash 46×46 đè bên trái (x56); số căn giữa; `Link_cash` là nút phủ cả khối (mở Shop → Exchange Cash) |
| `HudGems` | 194,14 131×46 | pill 117×34 tại x208,y20; icon gem 46×46 tại x190; `Link_gem` mở Shop → Gem |
| `SettingsButton` | 329,14 48×48 | icon bánh răng 28×28 căn giữa |

Cách xếp: ba khối coin/gem/cài đặt cùng nằm trong HBox 365 rộng; avatar 44, hai pill tiền chia đều phần còn lại, cài đặt 48.

### 2.2 L2 Dải giải · thu nhập · quà (y70, h44)

| Node | Rect | Nội dung |
|---|---|---|
| Chip giải | 12,70 129×44 | icon cờ 22×22 (x20,y81) + nhãn giải, vd. `Apprentice` |
| `IncomePill` | 149,70 176×44 | khung xanh đậm; icon tiền 30×30 (x155,y77) + `IncomeLabel` `8/s` (cỡ 27) |
| `DailyRewardsButton` | 333,70 44×44 | icon quà 22×22; `DailyDot` chấm đỏ 14×14 tại 362,74 khi có quà |

### 2.3 L3 Khung đua (y120, h419)

```text
┌ PanelContainer 12,120 365×419 ───────────────────────────┐
│ RaceRoundedClip 20,128 349×400 (cắt bo góc)              │
│ ┌ HUD đua  (RaceView.HUD_H = 44)                        ┐│
│ │ 440.0 YOUR TEAM │  P7/8  Lap 1   │ [×2 ▶ Watch ad]    ││
│ ├ Khán đài STAND_H = 44, 3 hàng, nền #a9b8d0           ┤│
│ │ ●  ● ●● ●●●  (chấm = xe, mật độ theo Parking)         ││
│ ├ Đường đua (phần còn lại ~ 302 px)                     ┤│
│ │  sa bàn cỏ xanh, đường nhựa tối, vạch xuất phát       ││
│ │  số đếm ngược 3·2·1 ở giữa khi countdown              ││
│ └───────────────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────┘
Dòng gợi ý (Label@80) 12,545 365×19  — dòng chữ "Coming soon…" khi có gating
```

| Thành phần | Rect | Ghi chú |
|---|---|---|
| `AdsRaceControls` | 20,128 349×400 | phủ lên khung đua |
| `BoostChip` | 253,132 104×36 | icon 27×20 + `×2` (cỡ 24) + dòng `Watch ad` (cỡ 14) ở y153; mở popup xem video |
| Ba cột HUD đua | trong 44 px đầu | trái: sức mạnh đội + nhãn `YOUR TEAM`; giữa: `P7/8` + `Lap 1`; phải: chip ×2 |
| Bảng kết quả lượt | thẻ 280 rộng, căn giữa, phủ lên **chỉ khung đua** (`_result_panel`), không phải popup toàn màn hình | §5.3 |

### 2.4 L5 Nav đáy (y771, h66)

`BottomNavigation` 12,771 365×66, vùng trong `Control` 15,774 359×60. Năm mục theo thứ tự cố định:

| # | Tab | Nhãn | Icon | Khi chọn |
|---|---|---|---|---|
| 0 | Race | `Race` | flag | pill xanh 115×60, icon 42×42, hiện chữ (x15) |
| 1 | Bag | `Gear` | tools/briefcase | icon 32×32 |
| 2 | Team | `Team` | staff | icon 32×32 |
| 3 | League | `Leagues` | trophy | icon 32×32 |
| 4 | Shop | `Shop` | shop | icon 32×32 |

- `NavPill` là một `Panel` 115×60 **trượt** giữa các tab (x = 15 / 75 / 136 / 197 / 258). Tab chọn rộng 115, bốn tab còn lại chia đều ~61 và chỉ hiện icon; nhãn `NavLabel` 22 cao ở y809.
- Chấm báo `NavDot` 18×18 ở góc phải trên của ô (vd. Shop tại 353,774) khi có thứ mới; ổ khóa `NavLock` khi tab chưa mở (gating).
- Thứ tự mở khóa: Gear `U3_bag`, Team `U5_drivers`, Leagues `U2_league`, Shop `U4_shop`; Race luôn mở.

## 3. Layer nội dung từng tab (L4)

Mỗi tab là một `ScrollContainer` dọc; ô nội dung cách lề 12 (rộng 357 trong 365).

### 3.1 Race — y572 h191

```text
CarSectionHeader   12,572 357×26   icon xe 28×20 + "RACE CAR"
CarUpgradeGrid     12,606 357×224  2 cột × 2 hàng, ô ~173×108
RevenueSectionHeader 12,838 357×26 "REVENUE"
RevenueUpgradeGrid 12,872 357×224  2 cột × 2 hàng
```

Mỗi thẻ nâng cấp (vd. Engine, 12–185 × 606–714):

| Phần tử | Vị trí tương đối | Ghi chú |
|---|---|---|
| Icon `Art_<id>` | +10, +7, 32×32 | engine · tyre · chassis · gearbox · ticket · celebration · parking · grandstands |
| Tên | +48, +4, 117×21 | `Engine`, `Tyres`, `Chassis`, `Gearbox`; doanh thu: `Ticket Marketing`, `Victory Celebrations`, `Parking`, `Grandstands` |
| `Level 0` | +48, +25, 117×17 | |
| Hiệu ứng xe | +38, +44 | `46.0 → 47.2` (số mới màu xanh) |
| Hiệu ứng doanh thu | +41, +50 | `+0.252/sec` |
| Nút mua | +89, +72, ~38×30 | icon tiền + giá (`39`, `20`, `32`, `27`; doanh thu `37`, `73`, `122`, `195`) |

Cột trái x=12 (thẻ 1·3), cột phải x≈195 (thẻ 2·4); hàng 1 y606, hàng 2 y722 (xe) / 872–988 (doanh thu).

### 3.2 Gear (Bag) — y572 h191

```text
Header "GEAR BAG"            12,572 357×23
ShopShortcut (PanelContainer) 12,605 357×56
   Art_standard_gear_pack 40×40 @20,613 | "Gear packs · Coupons: 0" @68,624 | [Open packs] 265,613 96×40
"GEAR STORAGE"  12,671 275×21        "Owned 0 / 30"  291,672 78×18
InventoryScroll 12,702 357×(cuộn)
   Lưới 3 cột, ô 64×64 icon + nhãn 99×17 ("Not owned")
   Cột x: 37 / 158 / 279 (tâm cách nhau 121); hàng cách nhau 140 (icon y710, 850, 990…)
   30 ô = 10 hàng
```

### 3.3 Team · Tay đua — y572 h191

```text
TeamTabs (PanelContainer) 12,572 357×52   [Drivers 16,576 172×44] [Garage 192,576 173×44]  (segmented)
ShopShortcut 12,634 357×56    Art_standard_driver_pack | "Driver packs · Coupons: N" | [Open packs]
Section "OWNED / IN USE" → thẻ tay đua  (cao 100, cách nhau 100)
   Art_driver_<id> 44×52 @24 | tên (cỡ 23) | nhãn độ hiếm (Rookie/Pro/Elite/Legend) | kiểu đua |
   dòng chỉ số "Launch 40 · Pace 40" | nút phải 82×44 @279: "In use" / "Locked" / "Use"
"LOCKED (11)" 12,802 357×18 → các thẻ khóa; dòng điều kiện "Finish 5 races", "Unlock league Semi-Pro"…
```

12 tay đua: Ashford (đang dùng), Varga, Delacroix, Halvorsen, Marchetti, Quinlan, Ferreira, Zielinski, Calloway, Ibarra, …

### 3.4 Team · Garage

```text
TeamTabs (như 3.3, Garage được chọn)
Tiêu đề "Garage" 12,634 261×30   "Pico Lightning · Tier 1" 12,664 261×19    [Change car] 277,634 92×49
Khu trưng bày xe 12,~690 357×~200 (preview xe, nền sàn xưởng)
"✓ In use" 12,899 357×18
Segmented 3 mục y927 h44: [Cars 12 113×44] [Parts 133 114×44] [Appearance 255 114×44]
Thẻ chỉ số 2×2 (y989 và y1072):  Pace 46 | Grip 38 / Stability 38 | Acceleration 38  — nhãn cỡ 19, số cỡ 30
Ghi chú "Part levels are kept separately…" 12,1149 357×17
Nút chính "In use" 12,1176 357×48
```

### 3.5 Leagues — y70 h693 (không có L2/L3)

`TrophyPanel` 12,82 357×685 (cuộn):

| Node | Rect | Nội dung |
|---|---|---|
| `LeagueHeader` | 12,82 357×69 | nhãn nhỏ `LEAGUES`, tên `League Apprentice` (cỡ 28); chip phải `TROPHIES ×1` 62×14 tại 288,109 |
| `TrophyBanner` | 12,156 357×169 | cúp lớn trái; `Trophies owned` (112,167); số `TrophyCount` cỡ 46; nút `TrophyInfo` 36×36 @322,167; hàng `Total earned` + `0 / 100`; thanh `TrophyCapProgress` 335×7 @23,253; `Top 3 reward` + 3 ô `P1 +3`, `P2 +2`, `P3 +1` (x51/164/277, y289) |
| Tiêu đề nhóm | 12,330 232×19 `Upgrade with trophies`; phải: `Applies from the next race` |
| Segmented 3 nút y354 h44 | `Attack` (12–128), `Defense` (132–248), `Income` (252–369) |
| `Upgrade_speed_tune` | 12,403 357×127 | icon 80 vuông trái; tên `Racing engine` (104,415); `Level 0 / 10` + `LevelSegments` 10 vạch 188×6; mô tả; dòng `Pace +0 → +1`; nút mua 76×40 @281,478 (icon cúp + giá) |
| `Upgrade_launch_boost` | 12,535 357×127 | `Fast start`, `Acceleration +0 → +1` |
| `Upgrade_overtake_kit` | 12,667 357×100 | `Overtaking momentum`, `Level 0 / 6`, dòng khóa `Unlocks in league Professional` thay cho nút mua |

Cách nhau giữa các thẻ nâng cấp: 5 (cạnh dưới → cạnh trên).

### 3.6 Shop — `ShopReferenceShell` 0,64 390×781

Shop **không dùng** L4 chuẩn: nó đặt một shell riêng phủ từ y64 xuống tận đáy, kèm nav riêng (`ShopNav_0..4`, 70×52 mỗi nút, y781, nền `Panel` 9,779 373×57).

| Node | Rect | Ghi chú |
|---|---|---|
| `ShopChrome` | 0,64 390×39 | tiêu đề `CỬA HÀNG` có cờ caro, ghim khi cuộn; ảnh 262×39 tại x70 |
| `@ScrollContainer` | 18,111 355×662 | nội dung cuộn, tổng cao ~2069 |
| Lề trái/phải | 18 / 17 | |

Thứ tự cố định trong cuộn (y theo nội dung, gốc cuộn = 111):

| # | Khối | Rect | Cao |
|---|---|---|---|
| 1 | `Section_SPECIAL PACKS` (nhãn) | 18,111 355×31 | 31 |
| 2 | `Offer_starter_1` Rookie Pack | 18,151 355×122 | 122 |
| 3 | `Offer_income_x2` | 18,281 355×90 | 90 |
| 4 | `Offer_no_ads` | 18,379 355×76 | 76 |
| 5 | `DailyGiftBanner` | 18,463 355×61 | 61 |
| 6 | `FreeGemBanner` | 18,532 355×71 | 71 |
| 7 | `Section_DAILY PACKS` | 18,611 355×31 | 31 |
| 8 | `Offer_daily_gear` · `Offer_daily_driver` | 18,651 174×93 · 200,651 173×93 | 93 |
| 9 | `Section_GEM` + `GemGrid` | 18,752 → 792 355×208 | 208 (3 cột) |
| 10 | `Section_EXCHANGE CASH` + `CashGrid` | 18,1008 → 1048 355×109 | 109 (3 ô: 10/30/50 gem) |
| 11 | `OpenPacksHeading` + `OpenPacks` | 18,1165 → 1203 355×374 | 374 (Pro Pack, All-Star Pack, hạng ×1/×10) |
| 12 | `Section_FREE TICKETS` | 18,1585 | — |
| 13 | `Section_MORE PERKS`: `Offer_income_x3` 129, `Offer_offline_plus` 110 | 18,1789 → 1829 / 1966 | — |
| 14 | `RestorePurchases` | 18,2084 355×44 | 44 |
| 15 | `OpenDailyRewards` ("Claim reward") | 197,2136 176×44 | 44 |

Mệnh giá gem trong thiết kế: 50 / 275 / 600 / 1300 / 3500 (xem Design/28).

## 4. Trạng thái và chuyển cảnh

| Chuyển | Hiệu ứng |
|---|---|
| Đổi tab | `_select_tab`: ẩn/hiện L2+L3, `NavPill` trượt (`_animate_nav`), nội dung đổi tại chỗ |
| Mở popup | `PopupAnim.open` (scale/fade), scrim tối phủ toàn màn hình |
| Race ↔ khác | khung đua tiếp tục chạy ngầm; ×2 chip ẩn khi không ở tab Race |

## 5. Layer popup (L6)

### 5.1 Overlay chung (`Overlay`)

Các popup dùng `_begin_overlay()` chia sẻ một khuôn: `PanelContainer` căn giữa + `ScrollContainer` bên trong.

| Thuộc tính | Giá trị mặc định | Ghi chú |
|---|---|---|
| Chiều rộng nội dung | **316** (`preferred_width`), `min(316, w − 32 − padding)` | |
| Lề màn hình | 16 trái/phải (`margin_left/right`) | |
| Chiều cao tối đa | `h − 120` (`vertical_gutter`), tối thiểu 200 | cuộn khi dài |
| Căn dọc | giữa màn hình | |
| Khung | `HdUi.panel(6.0)` (panel trắng-xanh, bo góc) | |
| Khoảng cách dọc giữa phần tử | 8 (một số popup 12) | |
| Nội dung | x36→352 (316 rộng) | |

Các popup dùng khuôn này, tất cả có tiêu đề + nút đóng 48×48 ở góc phải (x304):

| Popup | Hàm | Vị trí/nội dung |
|---|---|---|
| **Settings** | `_show_settings` | `SettingsContent` 36,244 316×353: tiêu đề `Settings` (cỡ 26) + icon bánh răng 36 + `SettingsClose`; nhãn `AUDIO`; hàng `Music` + `MusicToggle` (CheckButton 55×57, x286); hàng `Sound effects` + `SfxToggle`; `LanguageRow` 36,529 316×68: `Language` + `LanguageButton` 140×44 (@201) |
| **Language picker** | `_show_language_picker` | `PopupHeader` 36,273 316×48; `LanguagePicker` lưới 2 cột 153×52, khoảng cách 10 (x36/199; y329, 391, 453, 515); 8 ngôn ngữ: English, Tiếng Việt, Bahasa Indonesia, Bahasa Melayu, ไทย, 日本語, 한국어, 简体中文; mục đang chọn có `✓` |
| **Offline income** | `_show_offline` | tiêu đề `OFFLINE INCOME` + icon tiền 36 @36,224; ảnh minh hoạ (xưởng + đồng hồ + xe); ô số tiền cam nhạt `+28.5K` (cỡ 36 vàng); `OfflineProgress` 316×28 (thanh vàng, chữ `115/120 min` hoặc `Full · 120/120 min`); `OfflineContinue` 316×52 xanh lá |
| **Gear/Driver pack info** | `_show_gear_info`, `_show_driver_info` | header (cỡ 24) + nút đóng; dòng tỉ lệ cách nhau 29 (`Rare: 85.0%`, `Epic: 15.0%` / `Rookie 60%`, `Pro 33%`, `Elite 7%`); đoạn ghi chú bảo hiểm/trùng lặp |
| **IAP detail** | `_show_iap_detail` | rộng 333 (lề 28): header tên gói + nút đóng; mô tả 317×19; ảnh gói 333×218 @28,242; lưới phần thưởng 4 cột (150 Gem, ×3 Pro ticket, ×3 Standard ticket, 1 h Income) ở y~480–550; ghi chú; nút mua `$0.99` 333×48 @28,597; hàng cuối `Buy once` + `View rates` 165×44 |
| **Feedback/khóa tính năng** | `_show_feedback` | tiêu đề 27, thân 19, nút `Done` 316×48 |

### 5.2 Daily Gift (`DailyRewardsPopup`)

Phủ 0,61 390×722, không dùng khuôn chung (`preferred_width` 430, `horizontal_gutter` 0, `margin` 0):

| Node | Rect |
|---|---|
| Tiêu đề `DAILY GIFT` | 81,118 231×38 (ruy-băng xanh có cờ, hộp quà trên đầu) |
| Mô tả | 67,165 255×16; `Claimed: 0 days` 140,183 109×16 |
| `PopupClose` | 333,97 52×52 (nút đỏ) |
| Hàng 1: `DailyCell1/2/3` | y209 cao 109: x25 (115), x145 (106), x256 (108) |
| Hàng 2: `DailyCell4/5/6` | y324 cao 96: cùng x |
| `DailyCell7` (Day 7) | 22,426 345×120, rương + `30 gem` + `2× All-Star ticket`, dòng `Complete 7 days to claim` y523 |
| `DailyMilestones` | 23,554 344×137: `MILESTONE GIFT` + `0 / 10 days`; 4 mốc Day 10/20/30/40 (x32/115/199/283, 79×62), chú thích y673 |
| `ClaimDailyReward` | 51,697 287×43 xanh lá, chữ `CLAIM GIFT` cỡ 29 |

Phần thưởng: D1 2× Pro ticket · D2 2× Standard ticket · D3 15 gem · D4 1× All-Star ticket · D5 1× Elite ticket · D6 20 gem · D7 30 gem + 2× All-Star ticket; mốc 10/20/30/40: 40 gem / 2× All-Star ticket / 80 + 2× / 40 gem.

### 5.3 Bảng kết quả đua (`_result_panel`)

Không phải overlay: `Control` full rect **bên trong `RaceView`**, có `CenterContainer` căn giữa một thẻ **rộng tối thiểu 280**, lề trong 6/6/6/8.

```text
┌ thẻ 280× ───────────────────────────┐
│ [ Victory | Podium | Finished ]  P2 │  header màu (xanh lá nếu top 3, xám nếu không), bo góc trên 14, lề 10
│ Cash          +100                  │  mỗi hàng: lề 16/8, nhãn #5d6b80 cỡ 15, giá trị màu
│ Trophies      +2 (có N)             │  chỉ hiện khi có cúp
│ Recruit pts   +8                    │
│ Unlocked      <tên>                 │  nếu có mở khóa
│ Gift          <quà>                 │  nếu có quà
│            [ Continue ]             │
└─────────────────────────────────────┘
```

Khi bảng hiện, đua tạm dừng (`result_hold`) đến khi bấm Continue; thu nhập vẫn chạy.

### 5.4 Hồ sơ người chơi (`PlayerProfile`, toàn màn hình)

`ProfilePopup` 16,62 357×720. Header: `ProfileTitle` `Player profile` (30,86 271×27), `ProfileBack` 311,76 48×48. `ProfileScroll` 16,138 357×564, các khối theo thứ tự:

1. Thẻ danh tính: nhãn `WORKSHOP GP`, `ProfileTeamName`, chip giải `◆ Apprentice`, hàng `Your profile` + `Edit team name` 123×44.
2. Hàng Class: `Class` + `ClassButton` 59×44; `ClassSwitcher` (hàng `Racing` · `● Racing` · `✓ Managing` 86×44).
3. `Racing journey` / `Accumulated`: hai ô số lớn (cỡ 32) `Races completed`, `Facilities opened`.
4. `Collection` / `Owned`: ba hàng `Race car 1/15`, `Drivers 1/12`, `Gear 0/30` kèm thanh tiến độ (hàng cách 54).
5. `Current lineup`: hai thẻ `Drivers` và `Race car` (tên tay đua, `Pico Lightning`).
6. `ProfileStorageStatus` `Data on this device`.

Footer cố định `ProfileClose` 309,718 48×48. Dialog sửa tên (`_build_edit_dialog`) phủ lên trên.

### 5.5 Classes (`ClassPage`)

`ClassBackdrop` full rect (scrim), `ClassPopup` 12,115 365×615. Header: `Classes` (22,125, cỡ 34) + phụ đề `Manage race facilities`; chip tiền 283,138; `ClassClose` 319,125 48×48. `ClassScroll` 12,184 365×546:

| Khối | Rect |
|---|---|
| `YOUR FACILITIES` `1 / 6` | 22,196 |
| `ClassCard_racing` | 22,228 345×317: biểu tượng class + tên `Racing` + chip `● Racing`, mô tả `Balanced, the original`; `TEAM NAME` `Your Team`; hai ô `CURRENT LEAGUE` / `INCOME` (`+8/sec`); `Suggested car: Lightning`; `S · H · B · A even` |
| `FacilityPanel` | 22,557 345×159: `Open a new facility`, mô tả, `FacilityNote` (`1.27M short`), nút `FacilityBuy` 317×48 (`Open facility · 1.27M`) |

### 5.6 Các layer động khác

| Layer | Nguồn | Mô tả |
|---|---|---|
| Toast | `_show_toast` | dải nổi trên nav, tự biến mất |
| `PowerIncreaseBanner` | `ui/power_increase_banner.gd` | banner “+Power” khi sức mạnh đội tăng (Design/21) |
| `AdsRaceControls` popup | `_build_popup` | popup xem video ×2 thu nhập, phủ trong khung đua |
| `RewardBurst` | `ui/reward_burst.gd` | hiệu ứng nổ phần thưởng |
| Shop: popup mở gói | `_show_gear_result` | “Pack results”, lưới món vừa mở |
| Loading / Splash | `scenes/loading.tscn`, `splash.tscn` | trước khi vào Main (Design/09) |

## 6. Tutorial (L7, `TutorialOverlay`)

Phủ toàn màn hình, nằm trên mọi popup. Thành phần: scrim có **lỗ spotlight** quanh mục tiêu; tay chỉ (con trỏ); hộp thoại trắng ở **đáy** (cao ~ 120, rộng gần hết màn hình, lề 12) gồm chân dung `Linh` (nhân vật Chief Engineer) trái, tên + vai trò, nhãn trạng thái (`UNLOCKED`), thân thoại. Ba nhóm: Onboarding (A), Feature intro (B), Tips (C) — xem Design/23 và `data/tutorials/`.

## 7. Kích thước tham chiếu nhanh

| Thành phần | w × h |
|---|---|
| Nút HUD (avatar) | 44 × 44 |
| Pill tiền | 130 × 46 |
| Cài đặt | 48 × 48 |
| Dải giải | 365 × 44 |
| Khung đua | 365 × 419 (bên trong 349 × 400) |
| Thẻ nâng cấp xe/doanh thu | ~173 × 108 |
| Nav đáy | 365 × 66 (pill chọn 115 × 60) |
| Nút nhỏ trong thẻ (mua, Open packs) | 76–96 × 40 |
| Nút chính popup | 316 × 48–52 |
| Nút đóng popup | 48 × 48 |

## 8. Màn nhỏ / thích ứng

- Co khung đua: `min(400, w×0.9+60)` và không quá `h − 340` (tối thiểu 250); phần còn lại dành cho L4.
- Popup co theo `size.x − gutter − padding`; chiều cao `h − gutter` (mặc định 120, Daily 80).
- Shop dùng shell riêng, không phụ thuộc chiều cao L4.
- Các màn Preview chuẩn dùng 320 / 390 / 412 (xem `Design/Previews`).

## 9. Đối chiếu tài liệu liên quan

| Tài liệu | Quan hệ |
|---|---|
| [17_Layout_Asset_Redesign](17_Layout_Asset_Redesign.md) | đề xuất layout/asset; tài liệu này là **hiện trạng thực tế** để đối chiếu |
| [06_UI_UX_Release](06_UI_UX_Release.md), [01_UI_Design](01_UI_Design.md) | tài liệu cũ, có chỗ lỗi thời (4 tab…) |
| [15_Advanced_Garage](15_Advanced_Garage.md) | chi tiết Garage (Xe · Phụ tùng · Ngoại hình) |
| [20_Player_Profile_Layout](20_Player_Profile_Layout.md) | Hồ sơ |
| [22_Race_Classes](22_Race_Classes.md) | Classes |
| [29_IAP_Packs_UI](29_IAP_Packs_UI.md), [28_IAP_Packs](28_IAP_Packs.md) | Shop/IAP |
| [30_Daily_Rewards](30_Daily_Rewards.md) | Daily Gift |

## 10. Cách tạo lại số liệu

Số liệu lấy bằng script SceneTree: dựng `Main`, gọi `_select_tab(i)`, `_show_settings()`, `_show_daily_rewards()`… rồi duyệt cây `Control` in `get_global_rect()` của mọi node đang hiển thị. Chạy ở chế độ không cửa sổ để không tạo cửa sổ/âm thanh:

```bash
XDG_DATA_HOME=<thư mục tạm> godot --headless --audio-driver Dummy --path . -s <script>.gd
```

Dùng `XDG_DATA_HOME` riêng để không ghi đè `save.json` thật.

## 11. Chưa có trong bản này

- Bên trong khung đua (khán đài, đường đua) chỉ nêu khối lớn; chi tiết vẽ ở `ui/race_view.gd`/`race_diorama.gd`.
- Chưa dump: Garage tab con **Parts / Appearance**, popup Edit team name, `_show_gear_result`, popup ads video, Loading/Splash, từng bước Tutorial.
- Vị trí các node dạng `@Label@N` (không đặt tên) chỉ lấy khi cần; nên đặt tên node nếu muốn tự động đối chiếu về sau.

## 12. Ảnh tham chiếu (cùng thư mục `Design/Previews/Layout_Ref/`)

Ảnh chụp từ chính bản đang chạy, 871 × 1888 px (≈ 2× logical, tỉ lệ khớp 390 × 845). Dùng để nhìn **phong cách và độ nặng thị giác**; toạ độ và kích thước lấy từ các bảng ở trên. Ảnh thuộc phiên bản tại ngày 17/11/2026, nếu giao diện đổi thì chụp lại.

| Ảnh | Màn | Mục |
|---|---|---|
| `01_race.png` | Tab Đua | §2, §3.1 |
| `02_gear.png` | Tab Gear | §3.2 |
| `03_team_drivers.png` | Team · Tay đua | §3.3 |
| `04_team_garage.png` | Team · Garage | §3.4 |
| `05_leagues.png` | Tab Giải | §3.5 |
| `06_shop.png` | Tab Shop | §3.6 |
| `07_popup_daily_gift.png` | Popup Quà hằng ngày (nền tối) | §5.2 |

## 13. Sơ đồ bố cục (ASCII)

Tỉ lệ ngang: 1 ký tự ≈ 8 logical px; dọc không theo tỉ lệ. Số bên trái là y logical.

### 13.1 Khung chung (Race / Gear / Team)

```text
y0   ┌──────────────────────────────────────────────┐ L0 nền + HeaderScenery (0–140)
y14  │ (ava) [💵 1K    ] [💎 100   ]          (⚙)  │ L1 HUD        h48
y70  │ [🏁 Apprentice ] [💵 8/s       ]    (🎁●)  │ L2 dải giải   h44
y120 │ ┌──────────────────────────────────────────┐ │
     │ │ 440.0 YOUR TEAM │ P7/8 Lap 1 │ [×2 ▶ Ad] │ │ L3 khung đua  h419
     │ │ ░░░░ khán đài 3 hàng (h44) ░░░░░░░░░░░░ │ │   HUD đua h44
     │ │ ┌──────────────────────────────────────┐ │ │   khán đài h44
     │ │ │      đường đua cỏ xanh, số "3"       │ │ │   đường đua ~302
     │ │ └──────────────────────────────────────┘ │ │
y545 │ └──────────────────────────────────────────┘ │ dòng gợi ý (19)
y572 │ ┌ Content (cuộn dọc) 365×191 ───────────────┐ │ L4
y763 │ └───────────────────────────────────────────┘ │
y771 │ [▌ Race ▐] ( Gear ) ( Team ) ( Leagues ) (Shop●) │ L5 nav h66
y837 └──────────────────────────────────────────────┘
```

### 13.2 Race content

```text
y572 ▌🚗 RACE CAR ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  (header 357×26)
y606 ┌───────────────────┐ ┌───────────────────┐
     │ ⚙ Engine   Lv 0   │ │ ◎ Tyres    Lv 0   │
     │ 46.0 → 47.2       │ │ 38.0 → 38.7       │
     │      [💵 39]      │ │      [💵 20]      │
     └───────────────────┘ └───────────────────┘
     (Chassis / Gearbox: hàng 2 tại y722)
y838 ▌ REVENUE ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
y872 ┌ Ticket Marketing ┐ ┌ Victory Celebrations ┐   thẻ 2×2, hiệu ứng "+0.252/sec"
     └ Parking          ┘ └ Grandstands          ┘
```

### 13.3 Gear

```text
y572 ▌ GEAR BAG
y605 ┌─────────────────────────────────────────────┐
     │ [📦40] Gear packs · Coupons: 0 [Open packs] │ 357×56
     └─────────────────────────────────────────────┘
y671 GEAR STORAGE                          Owned 0 / 30
y702 ┌────────┐ ┌────────┐ ┌────────┐   ô icon 64×64 + "Not owned" (99×17)
     │  ◌     │ │  ◌     │ │  ◌     │   3 cột, hàng cách 140, 10 hàng
     └────────┘ └────────┘ └────────┘
```

### 13.4 Team · Tay đua

```text
y572 ┌───────── Drivers ─────────┬──── Garage ────┐ segmented 357×52
y634 │ [📦] Driver packs · Coupons: N [Open packs] │ 357×56
y700 ┌─ OWNED ─────────────────────────────────────┐
     │ [ảnh 44×52] Button   Rookie                 │ thẻ cao 100
     │             Counterpuncher       [ In use ] │ nút 82×44
     │             Launch 40 · Pace 40             │
y802 LOCKED (11)
     │ [ảnh] Varga      Rookie           [ Locked ]│
     │       Finish 5 races                        │
```

### 13.5 Team · Garage

```text
y572 [ Drivers ][■■ Garage ■■]
y634 Garage                               [Change car]
y664 Pico Lightning · Tier 1               92×49
y690 ┌─────────────────────────────────────────────┐
     │          xe 2D trên sàn xưởng               │ ~200 cao
y899 └─────────────────────────────────────────────┘
     ✓ In use
y927 [ Cars ] [ Parts ] [ Appearance ]   44 cao
y989 ┌ Pace 46     ┐ ┌ Grip 38        ┐
y1072└ Stability 38┘ └ Acceleration 38┘
y1149 Part levels are kept separately…
y1176 [            In use            ]   357×48
```

### 13.5b Leagues

```text
y82  ┌ LEAGUES                          [TROPHIES ×1] ┐ banner xanh đậm 357×69
     └ League Apprentice                              ┘
y156 ┌────────────────────────────────────────────────┐
     │ 🏆   Trophies owned                       (i) │ 357×169, nền kem
     │      0 trophies                                │
     │ Total earned                            0/100  │
     │ ▔▔▔▔▔▔▔▔▔ thanh tiến độ ▔▔▔▔▔                  │
     │ Top 3 reward  [P1 +3] [P2 +2] [P3 +1]          │
y330 └────────────────────────────────────────────────┘
     Upgrade with trophies            Applies from the next race
y354 [■ Attack ■][ Defense ][ Income ]    44 cao
y403 ┌ [icon] Racing engine   Level 0/10 ▏▏▏▏▏▏▏▏▏▏  ┐ 127 cao
     │        mô tả · Pace +0 → +1          [🏆 1]    │
y535 ├ Fast start …                                   ┤ 127
y667 └ Overtaking momentum  🔒 Unlocks in league Professional ┘ 100
```

### 13.6 Shop

```text
y64  ▒▒ CỬA HÀNG ▒▒  (ShopChrome, ghim)           39
y111 ▌ SPECIAL PACKS ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  (31)
y151 ┌ Rookie Pack  [150💎 ×3 ×3 1h]   [$0.99] ┐ 122
y281 ├ Income ×2                       [$4.99] ┤  90
y379 ├ Ad-Free                         [$9.99] ┤  76
y463 ├ TODAY'S GIFT                    [Claim] ┤  61
y532 └ Free gems                 [▶ Watch video]┘  71
y611 ▌ DAILY PACKS ▔▔▔
y651 ┌ Gear 50💎 $0.99 ┐ ┌ Drivers 50💎 $0.99 ┐  93
y752 ▌ GEM ▔▔▔   GemGrid 3 cột, cao 208
y1008▌ EXCHANGE CASH ▔▔▔  3 ô (10 / 30 / 50 💎), cao 109
y1165▌ OPEN PACKS ▔▔▔  Pro Pack · All-Star Pack (×1, ×10), cao 374
y1585▌ FREE TICKETS   y1789 ▌ MORE PERKS   y2084 [Restore purchases]
y779 [Race][Gear][Team][Leagues][■Shop■]  nav riêng 70×52
```

### 13.7 Popup chung (316 rộng, giữa màn hình)

```text
     ░░░░░░░░ scrim tối phủ toàn màn hình ░░░░░░░░
        ┌──────────────────────────────────┐
  x36   │ ⚙ Settings                  (✕)  │ header cỡ 26 + nút 48×48
        │ AUDIO                            │
        │ ♪ Music                  [  ●─ ] │ toggle 55×57
        │ 🔊 Sound effects          [  ●─ ] │
        │ Language            [English  ▾] │ 140×44
        └──────────────────────────────────┘
          x36 ────────── 316 ───────── x352
```

### 13.8 Daily Gift

```text
y97   ╔═ 🎁 DAILY GIFT ═╗                         (✕ 52×52 @333,97)
y165  Log in every day and get great racing rewards!
y183  [Claimed: 0 days]
y209  [Day1 2×Pro ][Day2 2×Std][Day3 15💎]   ô 115/106/108 × 109
y324  [Day4 1×AllS][Day5 1×Elite][Day6 20💎]  ô × 96
y426  ┌ DAY 7 · SPECIAL REWARD   🧰  30💎  2×All-Star ┐ 345×120
y554  ┌ MILESTONE GIFT                   0 / 10 days ┐ 344×137
      │ ●───○───○───○   Day10 Day20 Day30 Day40       │
y697  [        🎁 CLAIM GIFT        ] 287×43 xanh lá
```

### 13.9 Bảng kết quả đua (trong khung đua)

```text
          ┌────────────────────────────┐ 280 rộng, căn giữa khung đua
          │▓▓ Podium            (P2) ▓▓│ header xanh lá / xám
          │ Cash            +100       │
          │ Trophies        +2         │
          │ Recruit pts     +8         │
          │       [  Continue  ]       │
          └────────────────────────────┘
```

## 14. Skin, màu và asset

Nguồn: `ui/hd_ui.gd` (`ROOT = res://assets/racing_ui_hd/`), `ui/main.gd`, art thay thế trong `assets/clean_modern/`. Tên màu theo mã hex trong code.

| Phần tử | Skin / asset | Màu chính |
|---|---|---|
| Nền trang | `ColorRect` | `#f1f7fc` (Shop: `#eff8ff`) |
| Nền HUD | `HeaderScenery` (ảnh khán đài) | trang trí, 0–140 |
| Pill tiền/gem | `surfaces/hud_bar.png` (9-slice) | xanh đậm, chữ trắng; icon `icons/cash.png`, `icons/gem.png` đè trái |
| Avatar | `icons/avatar.png` | |
| Nút cài đặt | `icons/gear.png`, `Button` xanh | |
| Chip giải | `StyleBoxFlat` `#0864bc`, bo 9, viền `#8ed5ff` | chữ trắng; icon `icons/flag.png` |
| Pill thu nhập | `#087ee6`, bo 12, viền `#5bb8ff` | chữ trắng |
| Nút quà | `icons/gift.png`; chấm báo `#ef4444` | |
| Panel/khung | `surfaces/panel_body.png` (9-slice 0.34, lề 15/14/15/17) | trắng-xanh nhạt |
| Thẻ gọn (coupon) | `panel_body.png` (9-slice 0.20) | |
| Nút nâng cấp | `surfaces/button_upgrade.png` | xanh lá, giá trắng viền `#28550c` |
| Nút nhận (Claim) | `surfaces/button_claim.png` | xanh lá |
| Nút hành động chính | `surfaces/button_race.png` / `clean_modern/icons/button_raised_blue.svg` | xanh dương |
| Nút phụ/hủy | `surfaces/button_cancel.png`; kiểu code `#e8f3fd`/viền `#adc9de`, bo 12 | |
| Nút vàng cam | `surfaces/button_amber.png` | cam/vàng |
| Nút menu/nav | `surfaces/button_menu.png`, `button_nav.png` | |
| Nav đáy | nền `#e6f2fc`, bo 16, viền `#adc9de` | |
| Tab Nav đang chọn | `NavPill` `Panel`, `HdUi.button("tab_on")` | xanh dương |
| Segmented (Drivers/Garage, Attack…) | track `#e2edf6` viền `#cbdde9`; chọn `#1675dc` chữ trắng; không chọn `#e2edf6` chữ `#47627b` | focus `#69b9ff` |
| Toggle | `controls/toggle_on.png`, `toggle_off.png` | |
| Checkbox | `controls/checkbox_on.png`, `checkbox_off.png` | |
| Đường đua | `backgrounds/racetrack_background.png` + `ui/race_diorama.gd` | cỏ xanh, đường nhựa tối |
| Khán đài | vẽ trong `race_view.gd` | nền `#a9b8d0`, vạch `#8fa0bb` |
| Icon tab | `icons/flag.png`, `tools.png`, `staff.png`, `trophy.png`, `shop.png` (đã có bản thay trong `clean_modern/`) | |
| Daily Gift | `assets/daily_rewards/` (`art.png`, `skin.png`, `today.png`, `crops/`) | xanh dương + ruy-băng, nút `button_free_skin.gdshader` |
| Shop | `assets/shop_blue_white/` (`sprites/`, `crops/`), `assets/iap_offers/` | trắng-xanh |
| Offline popup | `rewards/offline_garage.png` | số tiền màu vàng `C_GOLD` |
| Thẻ kết quả | header `#22c55e` (top 3) / `#64748b`; nhãn `#5d6b80` | |
| Tutorial | `assets/tutorial/portraits/linh_*.tres` | |
| Chữ | font trong `assets/clean_modern/fonts/`; chữ có viền sáng `#ffffffd9` hoặc tối `#173b59dd`, bóng 1 px | chữ chính `#102d60` |

Quy tắc phong cách: Soft Miniature (nền kem, thẻ bo tròn kiểu đất sét, nút cam cho hành động, thanh tiêu đề xanh có cờ caro); chuẩn tham chiếu là `Demos/SoftMiniature/approved/` và `Demos/SoftMiniature/layout-review.html`. Mục này viết theo style glossy cũ nên phần màu bên dưới cần rà lại.


## Popup pack: quyền lợi chính + quà kèm (sửa theo review 26/11/2026)

Chuẩn: `Design/Demos/SoftMiniature/approved/pack_popup_benefit_gifts_v1/01_benefit_gifts.png`. Code: `ui/pack_benefit_ui.gd`; asset: `assets/pack_benefit_v2/`. Giá, grant và điều kiện vẫn do IAP service quản lý.

```text
Overlay / PanelContainer (padding trái/phải 16, trên 70, dưới 12)
├─ ScrollContainer / VBoxContainer / build_detail
│  ├─ PromoPrimary: sprite + quyền lợi chính + gem/badge/chip
│  ├─ PromoRewards: heading chồng lên khay, các hàng thưởng
│  ├─ PromoNote: ẩn nếu rỗng, cao theo nội dung
│  ├─ PromoActionSpace: giãn phần trống ngoài khay
│  ├─ DetailBuy_<sku>: IAP CTA, chạm tối thiểu 44
│  ├─ trạng thái IAP (ẩn nếu rỗng)
│  └─ Footer: giới hạn mua + nút Xem tỉ lệ 44 px
└─ PromoHeaderHolder / PromoHeader: tiêu đề + PromoClose 48×48
```

Header cao 48 được ghim trong padding trên, offset y −56..−8 so với gốc content của panel; vùng cuộn bắt đầu bên dưới header, nên cuộn không che nút X. `vertical_gutter` của modal tính cả padding và lề màn hình.

Tỷ lệ tham chiếu thẻ khoảng 390×588: sáu pack chuẩn dùng chiều cao nội dung tối thiểu theo tỷ lệ này. Primary cao 142 (income 156), scale theo bề rộng popup. Khay thưởng co theo số hàng, không ép khay một quà bằng khay ba quà. Khoảng cách nội dung 4, hàng thưởng tối thiểu 48×scale (một quà 84×scale). Nhãn tiêu đề fit font 34×scale, số gem 64×scale, hàng thưởng 24×scale, giá 38×scale. Text dài được xuống dòng/cuộn, không co méo popup.

Số đo live tại 390×845 (logical px):

| SKU | x | y | w | h |
|---|---:|---:|---:|---:|
| starter_1 | 16.0 | 151.0 | 358.0 | 542.0 |
| weekly_s | 16.0 | 151.0 | 358.0 | 542.0 |
| offer_noads_bundle | 16.0 | 152.0 | 358.0 | 540.0 |
| income_x2 | 16.0 | 152.0 | 358.0 | 540.0 |
| no_ads | 16.0 | 152.0 | 358.0 | 540.0 |
| char_my | 16.0 | 152.0 | 358.0 | 540.0 |

Bằng chứng: `Design/Previews/pack_benefit_fix_v2/`. Kiểm tra native 886×1920 với content_scale_factor 2.2718; ảnh giữ pixel vật lý, các JSON dùng tọa độ logical.


## Shop — approved v9 implementation (26/11/2026)

Chuẩn mới do người dùng chọn: `Design/Demos/SoftMiniature/approved/shop_v9/shop.png` (ảnh 3 vị trí cuộn). Phần này thay chuẩn Shop cũ ở §3.6; không thay các trang khác.

Shop dùng `ui/shop_page.gd`, thẻ native `shop_demo_offer_card.gd`, `shop_demo_currency_card.gd` và helper màu `shop_demo_theme.gd`; không phủ ảnh concept lên UI. Toàn bộ tên, giá, số lượng và trạng thái là Label/Button thật. Header/nav chung được giữ, thứ tự nav Shop/Túi/Đua/Đội/Giải. Chỉ Shop đổi màu nền và lề ContentArea.

- Nền `#ded7ca`, mặt thẻ `#eee6d9`, chữ `#102857`; viền special vàng bo liên tục 16px, tia sáng nhẹ.
- FREE xanh lá; mua USD/tiêu gem xanh azure, video xanh nhạt; khôi phục nút viền.
- Section ribbon compact 34px; lề thực của thẻ 12px tại 390px, khoảng cách khối 6px; nội dung rộng 366px.
- Gói Tân binh, Thu nhập, Đội tự do: artwork + badge riêng; starter2/3 có section Gói Khởi động; điều kiện hiện/ẩn lấy từ IAP như trước.
- Gói ngày full-width; mở gói 2 cột; gem và tiền 3 cột. Nút native tối thiểu 44px; thẻ có thể cao hơn ảnh concept để giữ vùng chạm và nhãn dịch.
- Đổi tiền chỉ trưng bày 60/240/480 phút theo Design/28 §4.8, cấu hình UI ở `data/shop_display.json`. Bấm vẫn mở thông báo Sắp có; không bổ sung giao dịch hay thay balance/save.

Số đo 390×845 trích từ SceneTree fixture trong `tests/shop_demo_v9_ui_test.gd`, lưu đầy đủ ở `Design/Previews/Shop_Demo_v9/geometry.json`. y dưới đây tương đối với đầu nội dung cuộn và phụ thuộc các SKU đủ điều kiện trong fixture:

| Node | x, y, w, h logical |
|---|---|
| Offer_starter_1 | 0.0, 294.0, 366.0, 148.0 |
| Offer_income_x2 | 0.0, 448.0, 366.0, 119.0 |
| Offer_no_ads | 0.0, 573.0, 366.0, 117.0 |
| Offer_starter_2 | 0.0, 736.0, 366.0, 125.0 |
| Offer_daily_gear | 0.0, 907.0, 366.0, 117.0 |
| Offer_daily_driver | 0.0, 1030.0, 366.0, 117.0 |
| OpenPacks | 0.0, 1193.0, 366.0, 272.0 |
| GemGrid | 0.0, 1511.0, 366.0, 340.0 |
| CashGrid | 0.0, 1897.0, 366.0, 184.0 |

Ảnh runtime và bảng so sánh: `Design/Previews/Shop_Demo_v9/`. Khác biệt dữ liệu hợp lệ: tay đua trong starter2 mang tên Marchetti theo catalog hiện tại, không hardcode Hà từ ảnh. Coupon giữ đúng icon tier của game thay vì đổi tier theo màu vé AI.

## Garage — concept v2 implementation (27/11/2026)

Chuẩn: `Design/Concepts/Garage_Redesign_v2/01-car.png`, `02-parts.png`, `03-look.png`. Bằng chứng v1: `Design/Previews/Garage_Impl_v1/`; polish v2: `Design/Previews/Garage_Impl_v2/`.

Đội dùng shell cố định bên dưới HUD và trên nav chung (không đổi thứ tự nav). TeamTabs ghim trên cùng; Tay đua có ScrollContainer riêng. Garage dựng bằng `ui/garage_page.gd`:

- Showroom polish v2: CarPreview 3D hiện hành trên nền phòng không xe mới `assets/garage_soft_miniature_v2/showroom.png`, góc 3/4; cao 170 logical ở tab Xe, 185 ở hai tab còn lại, 92 khi viewport hẹp hơn 340. Camera nền mới có span_y 3.3, target.y 0.40 để bánh xe nằm trên bục; preview ngoài Garage giữ camera/nền cũ.
- Segmented Xe/Phụ tùng/Ngoại hình cao tối thiểu 52. GarageContent cuộn độc lập trong phần còn lại.
- Xe: showroom → tên + huy hiệu hạng → bốn stat chip (icon 30) → hàng Nâng cấp xanh lá/chọn hoặc mua xe → segmented → bộ sưu tập nền xanh 3 cột cuộn tại chỗ. Xe chưa sở hữu vẫn xem được; mua không tự trang bị. Màn collection cũ đã gộp vào đây; CLI `collection` tương thích bằng cách hiện tab Xe.
- Phụ tùng: showroom → segmented → lưới 2×2, icon đất sét 62×76 (46×76 ở 320), cao tối thiểu 112/thẻ (96 ở 320); footer PartPurchase ghim đáy, gồm ×1/×10/Tối đa, cấp trước/sau, CTA dùng Pricing/GameState.
- Ngoại hình: 8 màu lưới 4 cột, 4 decal một hàng; Hủy/Lưu và trạng thái ghim đáy. Bản nháp qua guard khi đổi mục hoặc xe, chỉ ghi save khi Lưu.
- Nội dung dài cuộn, CTA được wrap, giữ tối thiểu 44 logical. 320 thấy đầy đủ hàng xe đầu; cuộn để xem các hàng sau. Màu thẻ ưu tiên cosmetics đã lưu, còn lại map theo family/archetype, giữ màu thật cho active; không ghi map vào save. Xe khóa có icon khóa riêng và nhãn trạng thái.
- Cấp fixture 40/30/20/10. Chỉ số/giá tính từ dữ liệu thực hiện hành; không sao chép số illustrative trong ảnh.


## Garage — review v3 (27/11/2026)

Chuẩn vẫn là Garage_Redesign_v2 (01-car/02-parts/03-look). Bằng chứng và sai lệch còn lại: `Design/Previews/Garage_Review_v3/REVIEW.md`. Các số dưới theo logical px, fixture vi/Pico active, engine40/tyre30/chassis20/gearbox10.

- Thẻ stat chuyển icon trái, nhãn/số phải, padding4, bo14; thẻ chọn bo18 có bóng nhẹ, selected viền cam.
- RankBadge 90×32: sprite crown/laurel + nhãn I18n native, nguồn và prompt trong pack.
- Màu/họa tiết nằm trong hai khay riêng, header xanh giữa vạch. Có dấu chọn native; đủ 8/4 thấy trọn ở 320, 390, 412. Nút chạm ≥44.
- Showroom dùng uniform cover, crop phía trên giữ bục; không kéo dẹt texture. Do tỷ lệ background khác viewport, phần cờ/đồ trang trí có thể bị crop.
- Tên xe nằm trong khay kem bo16; cấp phụ tùng có pill xám, progress gradient vàng/cam bo4; CTA nâng cấp có mũi tên native.
- Ghi chú miễn phí/không tăng stat ở tooltip footer; Hủy xám, Lưu cam; trạng thái có glyph info và căn giữa. Hai key vi: Không/Caro. Giá và chỉ số không đổi.

| Width | Tab | Showroom x,y,w,h | GarageTabs x,y,w,h | GarageContent x,y,w,h |
|---:|---|---|---|---|
| 320 | Xe | [P: (4.0, 108.0), S: (312.0, 120.0)] | [P: (4.0, 397.0), S: (312.0, 52.0)] | [P: (4.0, 455.0), S: (312.0, 146.0)] |
| 320 | Phụ tùng | [P: (4.0, 108.0), S: (312.0, 104.0)] | [P: (4.0, 218.0), S: (312.0, 52.0)] | [P: (4.0, 276.0), S: (312.0, 184.0)] |
| 320 | Ngoại hình | [P: (4.0, 108.0), S: (312.0, 108.0)] | [P: (4.0, 222.0), S: (312.0, 52.0)] | [P: (4.0, 280.0), S: (312.0, 251.0)] |
| 390 | Xe | [P: (16.0, 116.0), S: (358.0, 170.0)] | [P: (16.0, 461.0), S: (358.0, 52.0)] | [P: (16.0, 519.0), S: (358.0, 234.0)] |
| 390 | Phụ tùng | [P: (16.0, 116.0), S: (358.0, 185.0)] | [P: (16.0, 307.0), S: (358.0, 52.0)] | [P: (16.0, 365.0), S: (358.0, 239.0)] |
| 390 | Ngoại hình | [P: (16.0, 116.0), S: (358.0, 185.0)] | [P: (16.0, 307.0), S: (358.0, 52.0)] | [P: (16.0, 365.0), S: (358.0, 318.0)] |
| 412 | Xe | [P: (16.0, 118.0), S: (380.0, 170.0)] | [P: (16.0, 463.0), S: (380.0, 52.0)] | [P: (16.0, 521.0), S: (380.0, 280.0)] |
| 412 | Phụ tùng | [P: (16.0, 118.0), S: (380.0, 185.0)] | [P: (16.0, 309.0), S: (380.0, 52.0)] | [P: (16.0, 367.0), S: (380.0, 285.0)] |
| 412 | Ngoại hình | [P: (16.0, 118.0), S: (380.0, 185.0)] | [P: (16.0, 309.0), S: (380.0, 52.0)] | [P: (16.0, 367.0), S: (380.0, 364.0)] |

320: stat h65, part card h88 / icon46×60, paint hit48 / swatch control30, decal hit56 / glyph34. 390/412: stat h71, part card h112 / icon62×76, paint hit60 / swatch42, decal hit74 / glyph40×42. Geometry chi tiết trong 9 JSON của thư mục review. Khác biệt tỷ lệ 2:3 của concept và 390:845 của game vẫn được giữ, không ép méo ảnh so sánh.
