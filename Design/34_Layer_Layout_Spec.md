# 34. Đặc tả layer và layout (bản đang chạy)

Cập nhật 27/11/2026 · Trích từ cây node thật của `ui/main.gd` bằng `tools/dump_layout.gd` (viewport logical 390×845, `RM_LANG=vi`, dữ liệu giả lập: 25 lượt đua, 12 cúp, 3 coupon gear, 2 coupon tay đua, không gating). Số đo lấy trên working tree ngày này, **gồm cả thay đổi chưa commit** (chuỗi gói IAP, popup bán hàng, Ads Break). Cây đầy đủ từng màn: `output/layout/<màn>.txt` sau khi chạy script (§8).

## 0. Quy ước

| Mục | Giá trị |
|---|---|
| Viewport thiết kế | 886 × 1920 px, `canvas_items`, scale 2.2718 |
| Đơn vị | logical px ≈ 390 × 845; mọi `x,y w×h` gốc ở góc trên trái |
| Lề nội dung | Đua/Túi/Đội/Giải: x16, rộng 358. Shop: x12, rộng 366 |
| Vùng chạm tối thiểu | 44×44 (ngoại lệ đo được ở §9) |
| Nav | Shop · Túi · Đua · Đội · Giải |

## 1. Cây gốc và z-order

```text
Main 0,0 390×845
├─ PageBackground          0,0 390×845
├─ SoftHeaderBackground    0,0 390×45
├─ ResourceHeader          0,0 390×44      mọi tab
├─ ContentArea             4,48 382×711    trang theo tab
├─ BottomNavigationSpace   4,762 382×83    giữ chỗ
├─ BottomNavigation        -10,762 410×93  tràn mép
├─ PromotionPopup · ClassPage              popup riêng, toàn màn hình
├─ Overlay                                 popup chung
├─ AdsPopup                                popup xem video
└─ TutorialOverlay         0,0 390×845     trên cùng
```

Không còn avatar/hồ sơ trên HUD, popup Quà hằng ngày, dải giải riêng hay nav riêng của Shop.

## 2. Layer dùng chung

### 2.1 HUD (`ResourceHeader`, h44)

| Node | Rect | Ghi chú |
|---|---|---|
| `HudCoins` / `Link_cash` | 8,5 155×33 | chữ số 42,5 95×33; bấm mở Shop → Đổi tiền |
| `HudGems` / `Link_gem` | 182,5 155×33 | bấm mở Shop → Gem |
| `SettingsButton` | 352,6 33×31 | |

### 2.2 Nav đáy

| Mục | Ô chạm | Icon | Nhãn `NavLabel` |
|---|---|---|---|
| Shop | 3,765 76×77 | 40×40 | 3,809 76×22 |
| Túi | 79,765 77×77 | 40×40 | 79,809 77×22 |
| Đua (giữa, nhô lên) | 156,759 77×84 | 48×48 (đang chọn) | 156,809 77×22 |
| Đội | 233,765 77×77 | 40×40 | 233,809 77×22 |
| Giải | 310,765 ~77×77 | 40×40 | y809 |

`NavPill` trượt tới ô đang chọn: 77×64 tại y767 (Đua: 77×73 tại y759), x = 3 / 80 / 157 / 233 / 310. `NavRim` cao 7 ở y762. `NavDot` 13×13 ở góc phải trên ô.

## 3. Nội dung từng tab

### 3.1 Đua

```text
y0   [💵 1,25M      ] [💎 1.240      ]            [⚙]
y58  ┌ FixedRaceCluster (RaceView) 16,58 358×287 ────┐
y63  │ [hạng] [+8/giây]                    [Class]   │
y327 │                 Kéo để xoay                   │
y345 ├ ActionStrip 16,345 358×56 ────────────────────┤
     │   [×2 ▶] [perk] [starter] [daily]   mỗi ô 64×51
y407 ├ UpgradeScroll 16,407 358×352 (cuộn) ──────────┤
     │ ▌Nâng cấp xe        358×39                    │
y454 │ 4 hàng 358×59, bước 60                        │
y701 │ ▌Thu nhập           358×39                    │
y748 │ 4 hàng 358×59, bước 60                        │
y762 └ Nav ──────────────────────────────────────────┘
```

| Node | Rect |
|---|---|
| `RaceStageRow` (nút giải) | 23,63 43×27 |
| `IncomePill` | 75,63 104×27 |
| `FacilitiesButton` | 283,63 84×27 |
| `BoostChip` | 53,347 64×51 |
| `PackPromo_perk` / `_starter` / `_daily` | x126 / 199 / 273, y347, 64×51; `Dot` 10×10 |
| `CarSectionHeader` / `RevenueSectionHeader` | y407 / y701, 358×39 |

Mỗi hàng `Upgrade_<id>` 358×59 (**một cột**, không còn lưới 2×2). Toạ độ tương đối: icon +5,+5 56×48 · tên +68 rộng 82 (xuống 2 dòng được) · cấp +157,+4 95×22 · hiệu ứng +157,+27 95×26 · `Buy_<id>` +270,+12 82×34. Thứ tự: engine, tyre, chassis, gearbox; ticket, celebration, parking, grandstands.

Bảng kết quả lượt (`_result_panel`, trong khung đua): thẻ 55,101 280×201; đầu thẻ 268×59 với huy hiệu hạng 60×39; mỗi dòng thưởng cách 42.

### 3.2 Túi

| Node | Rect (cuộn từ y58, vùng 358×701) |
|---|---|
| `GearBagHeader` | 16,58 358×39 |
| Thẻ kho | 16,107 358×56; `GearPowerTotal` 267,111 100×47 |
| `ShopShortcut` | 16,173 358×56; `OpenPacksInShop` 270,181 96×40 |
| `InventoryScroll` | 16,239; lưới 3 cột ô 116×140 (x16/138/259), bước dọc 146; ảnh 100×68 |

### 3.3 Đội · Tay đua

`TeamTabs` 16,58 358×52 (hai nút 173×44) ghim; vùng cuộn 16,116 358×643.

| Node | Rect |
|---|---|
| `TeamSummary` | 16,116 358×92 |
| `ShopShortcut` | 16,220 358×42; nút Mở gói 272,223 96×34 |
| `DriverGrid` | 16,274; 2 cột, thẻ 175×286 (x16/199) |
| Trong thẻ (tương đối) | tên +9,+11 · nút `i` 30×30 góc phải · trạng thái +24,+43 · `TierChip` 61×18 · chân dung +9,+88 157×132 · SP 157×29 · `ShardBar` 157×20 |

Chi tiết tay đua (`sheet`): panel 16,86 358×673; nội dung 330 rộng; đóng 48×48 tại 312,117; `DriverRadar` 30,191 330×250; hai khối thông tin 330×59 và 330×94; nút 30,618 330×52.

### 3.4 Đội · Garage

| Khối | Tab Xe | Phụ tùng | Ngoại hình |
|---|---|---|---|
| `Showroom` | 16,116 358×170 | 16,116 358×185 | 16,116 358×185 |
| `CarTitle` + `RankBadge` | 80,292 230×32 | – | – |
| `CarStats` (4 chip) | 16,330 358×71 | – | – |
| `CarActions` (2 nút 177×48) | 16,407 358×48 | – | – |
| `GarageTabs` (3 nút 114×44) | 16,461 358×52 | 16,307 | 16,307 |
| `GarageContent` | 16,519 358×234 | 16,365 358×239 | 16,365 358×311 |

- Xe: `CarCollection` 3 cột, ô 106×104 (x28/142/256), bước dọc 112.
- Phụ tùng: `PartsGrid` 2×2, thẻ 175×112; footer 16,610 358×149: ×1/×10/Tối đa (107×44), dòng cấp, CTA 338×48.
- Ngoại hình: màu 4 cột, ô ~81×60 (swatch 42); họa tiết ở khay riêng. Chi tiết: mục Garage bên dưới.

### 3.5 Giải đấu

`TrophyPanel` 16,70 358×524 trong vùng cuộn 16,58 358×701.

| Node | Rect |
|---|---|
| `LeagueHeader` | 16,70 358×84 |
| `TrophyBanner` | 16,159 358×112; số cúp 111,188; `TrophyInfo` 280,188 30×30; ×N 320,183 48×40; thanh 22,245 346×20 |
| `Group_offense/defense/income` | y276, 116×66 (x16/136/257); `NotifyDot` 12×12 |
| Tiêu đề "Nâng cấp bằng cúp" | 16,347 358×45 |
| `Upgrade_<id>` | 358×96, bước 101 (y397, 498…); tên x120; hiệu ứng 162×25; `Buy_<id>` x289 78×47 |

### 3.6 Shop

Cuộn 4,58 382×701; nội dung 12,58 366 rộng, cao ~2410. HUD và nav dùng chung. y dưới đây là toạ độ nội dung khi chưa cuộn; khối hiện/ẩn theo điều kiện IAP nên y thay đổi theo dữ liệu.

| Khối | y | cao |
|---|---:|---:|
| ▌Quà miễn phí | 58 | 34 |
| `FreeGrid`: gem (84) + 2 hàng vé (54) | 98 | 208 |
| ▌Gói đặc biệt | 312 | 34 |
| `Offer_starter_1` | 352 | 148 |
| `Offer_income_x2` | 506 | 119 |
| `Offer_income_x3` | 631 | 119 |
| `Offer_offline_plus` | 756 | 148 |
| `Offer_no_ads` | 910 | 117 |
| ▌Gói Khởi động + `Offer_starter_2` | 1033 / 1073 | 34 / 125 |
| ▌Gói ngày | 1204 | 34 |
| ▌Mở gói + `OpenPacks` (2×2, thẻ 179×132) | 1490 / 1530 | 34 / 272 |
| ▌Gem + `GemGrid` (3 cột, thẻ 118×167) | 1808 / 1848 | 34 / 340 |
| ▌Đổi tiền + `CashGrid` | 2194 / 2234 | 34 / 184 |
| `RestorePurchases` | 2424 | 44 |

Nút mua trong thẻ gói 112×44; nút mở gói 82×44, nút `i` 44×44.

## 4. Popup

### 4.1 Overlay chung

`_begin_overlay()`: panel căn giữa, rộng 348 (x21), nội dung 316 (x37), nút đóng 48×48 tại x305; cao theo nội dung, cuộn khi dài.

| Popup | Panel | Thành phần chính |
|---|---|---|
| Cài đặt | 21,239 348×366 | 3 hàng 316×68; toggle 55×49; `LanguageButton` 140×44 |
| Ngôn ngữ | 21,260 348×324 | lưới 2 cột (157 / 149) × 52, bước 62 |
| Luật cúp | 21,314 348×216 | 3 ô thưởng 102×34; `TrophyCapInfo` 316×60 |
| Tỉ lệ gói | 21,330 348×185 | dòng bậc bước 30, ghi chú |
| Thông báo / khóa | 21,323 348×199 | tiêu đề, thân, nút Xong 316×48 |
| Thu nhập vắng mặt | 16,170 358×505 | header 314×54; ảnh 330×194; số tiền 330×99; thanh 330×36; nút 278×48 |
| Chi tiết gói IAP (`starter_1`) | 16,125 358×594 | header 326×48 ghim trên; `StarterSteps` 3 bước 64×44; `PromoPrimary` 326×142; `PromoRewards` 326×183; mua 326×53; chân 152×44 |

### 4.2 Popup riêng

| Popup | Rect | Thành phần chính |
|---|---|---|
| `PromotionPopup` | 16,206 358×433 | ribbon trên mép; giải 332×142; 3 điều kiện cao 105; thưởng 332×58; nút 332×52 |
| `ClassPage` | 12,110 366×626 | header cao 71, đóng 48×48; `ClassCard_<id>` 346×321; `FacilityPanel` 346×163 |
| `AdsPopup` ×2 thu nhập | 16,167 358×510 | đóng 48×48 tại 310,160; art 308×264; nút xem 308×55; Để sau 301×40 |

## 5. Hiển thị và chuyển cảnh

- Đổi tab: nội dung `ContentArea` đổi tại chỗ, `NavPill` trượt. Khung đua chỉ có ở tab Đua.
- Popup: `PopupAnim` mở/đóng, nền tối phủ toàn màn.
- Chưa dump: Toast, `PowerIncreaseBanner`, `RewardBurst`, thẻ Ads Break (`ui/ads_break_card.gd`), popup bán hàng tự động, `TutorialOverlay` từng bước, popup cờ thưởng, đổi tên đội, chọn cơ sở, kết quả mở gói, Splash/Loading.

## 6. Màn nhỏ

Chuẩn kiểm ở 320 / 390 / 412 (`tools/capture_all_screens.gd`). Bảng trong tài liệu này chỉ đo ở 390×845; số 320/412 của Garage ở mục review v3 bên dưới.

## 7. Tài liệu liên quan

[15](15_Advanced_Garage.md) Garage · [22](22_Race_Classes.md) Classes · [28](28_IAP_Packs.md), [29](29_IAP_Packs_UI.md) Shop/IAP. [01](01_UI_Design.md), [06](06_UI_UX_Release.md), [17](17_Layout_Asset_Redesign.md) có chỗ lỗi thời so với bản này.

## 8. Cách tạo lại số liệu

```bash
XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --headless --path . -s res://tools/dump_layout.gd
```

Mỗi màn ra một tệp trong `output/layout/`. Lưới và danh sách dài chỉ in vài phần tử đầu (nên nút Giải trong nav không có trong tệp; số của nó suy từ `NavPill`).

## 9. Vùng chạm dưới 44×44 đo được

`SettingsButton` 33×31 · `HudCoins`/`HudGems` cao 33 · `RaceStageRow` 43×27 · `FacilitiesButton` 84×27 · nút mua nâng cấp 82×34 · `OpenPacksInShop` cao 34 (Đội) / 40 (Túi) · `DriverDetails` và `TrophyInfo` 30×30 · `AdsLater` cao 40. Chưa kiểm vùng bắt chạm thực có rộng hơn khung node hay không.

## 10. Skin và màu

Chuẩn: Soft Miniature (`Demos/SoftMiniature/approved/`, `assets/soft_miniature_ui_v1/` + `ui/soft_miniature.gd`, `ui/hd_ui.gd`, `ui/button_skin.gd`). Màu lấy từ các helper đó, không chép vào đây. Shop dùng `shop_demo_theme.gd` (mục Shop v9).

Các mục dưới là ghi chép theo đợt triển khai; nếu số đo khác §1–§4 thì §1–§4 mới hơn.

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

## Garage — usability pass (27/11/2026)

Yêu cầu mới theo review ba ảnh runtime trong chat thay thế bố cục Garage v2/v3 phía trên. `ui/garage_page.gd` giữ showroom và thanh Xe/Phụ tùng/Ngoại hình cùng vị trí giữa ba mục: showroom cao104 ở320 và170 ở390/412; tabs lần lượt y218/h44, y292/h52 và y294/h52. Tên/hạng xe, stats và hành động Xe chuyển xuống dưới tabs, cuộn cùng bộ sưu tập bằng một `GarageContent` duy nhất. Trạng thái đang dùng là nhãn, không còn nút disabled lớn. Footer Phụ tùng/Ngoại hình vẫn ghim đáy.

Chọn mục/thẻ/màu/họa tiết dùng xanh dịu; cam dành cho CTA giao dịch. Bỏ bóng xếp lớp và khay collection xanh; tăng cỡ nhãn phụ, dùng Nunito weight750 cho chữ≤14. PartPurchase có dòng chỉ số trước/sau bên cạnh ngữ cảnh cấp/giá thật. Ngoại hình giữ preview tức thì, bản nháp và guard lưu/hủy hiện có. Bằng chứng mới và số đo: `Design/Previews/Garage_Usability_v1/`.

Garage selection preview fix: showroom và thumbnail dùng chung `_preview_cosmetics()`. Xe chưa sở hữu dùng palette xem trước theo family/variant, không còn ép tất cả về cam hoặc làm mờ showroom. Xe sở hữu dùng cosmetics đã lưu/mặc định thật. Không ghi cosmetics khi chỉ xem xe. Bằng chứng: `Design/Previews/Garage_Selection_Fix/`.

## Garage — thử sân khấu 3D (27/11/2026)

Theo yêu cầu thử mới, Garage bật `CarPreview.showroom_3d`: thay bục/sàn vẽ trong ảnh bằng geometry 3D của `ui/garage_showroom_stage.gd`. Phần trên53,5% ảnh showroom hiện hành làm tường sau; không render bục cũ trong texture. Bục tròn xanh, mép bo/checker xanh-kem, sàn gạch màu đào và xe dùng cùng camera/ánh sáng, có directional shadow. Mặt bục y0 cùng cao độ tiếp đất xe; chỉ xe xoay khi kéo. Thumbnail và preview ngoài Garage không bật chế độ này. Giữ nguyên rect showroom/tabs của usability pass. Bằng chứng 320/390/412 × góc90/145/210 tại `Design/Previews/Garage_3D_Stage_v1/`; harness `tests/garage_stage_preview.gd`. Đây là lượt thử mỹ thuật đầu tiên, chưa đo hiệu năng GPU mobile.

Garage scroll fix: khi dựng lại cùng mục, giữ offset của `GarageContent`; ở tab Xe bù thay đổi vị trí đầu lưới `CarCollection` do summary/CTA đổi chiều cao, để hàng xe không nhảy khi chọn. Khôi phục sau layout và bỏ qua callback thuộc scroll cũ. Đổi sang mục khác bắt đầu ở đầu nội dung. Regression: `tests/garage_scroll_ui_test.gd` kiểm ba độ rộng, chọn xe ở giữa/cuối danh sách và refresh, có chế độ `--click-input` cho input chuột thật trong viewport.
