# 25 — Tính năng xem quảng cáo: tham khảo lumber-tycoon và đề xuất cho racing_manager

- Ngày: 12/11/2026
- Nguồn khảo sát: `D:\Horus_Project\lumber-tycoon` (Unity, AppLovin MAX). Chỉ đọc mã, không sửa gì bên đó.
- Liên quan: [05 §7](05_Economy_Monetization.md) (quy tắc quảng cáo, D4), [07](07_Technical_Architecture.md) (`AdsService`, ID thưởng), [03](03_Release_Overview.md) (D4, M5).
- Trạng thái: **đề xuất, chưa triển khai**. Mục 5 có hai điểm cần người thiết kế chốt.

---

## 1. Lumber-tycoon có những gì

### 1.1. Hạ tầng (lớp SDK)

| Thành phần | File (lumber-tycoon) | Việc nó làm |
|---|---|---|
| Lớp trừu tượng | `_FrameWork/Scripts/Manager/Admob/BaseAdManager.cs` | API chung cho banner / interstitial / rewarded, kèm event vòng đời (loaded, displayed, rewarded, closed, show failed, paid). Chọn bản cài đặt theo define: `MAX_SDK` → AppLovin MAX, `IS_SDK` → IronSource, còn lại → `NoAdManager` (stub cho Editor). |
| Rewarded | `MaxSDK/MaxRewardAds.cs` | Tải trước theo **waterfall nhiều ad unit**; tải lỗi thì thử unit kế, hết unit thì thử lại với backoff `2^min(6, n)` giây. Dừng tải trước khi đang hiện quảng cáo. |
| Hàm gọi duy nhất cho gameplay | `TryRequestShowRewardedVideo(placement, onRewarded, onClosed) -> bool` | Thứ tự: (1) chặn khi đang có yêu cầu khác; (2) **còn vé quảng cáo thì trừ 1 vé và phát thưởng ngay**; (3) mất mạng → popup "không có mạng", trả `false`; (4) rewarded chưa sẵn → **dự phòng bằng rewarded-interstitial**; vẫn không có → popup "chưa có quảng cáo", trả `false`; (5) đăng ký callback một lần, tự gỡ khi xong, cờ `completed` và `rewardGranted` chống gọi trùng. |
| Interstitial | `MaxSDK/MaxInterstitialAds.cs` | `RequestShowInterstitial` có chặn theo khoảng cách giữa hai lần (remote config theo số lần đăng nhập) và thời gian tối thiểu sau rewarded. `RequestShowInterAdsNoCheck` hiện thẳng, bỏ qua cả gói bỏ quảng cáo. |
| Banner | `MaxSDK/MaxBannerAds.cs`, `UIBannerAdsLayer` | Có mã nhưng **đang tắt** trong gameplay (`MainMenuState.ShowBannerAds` bị comment). |
| Doanh thu | `BaseAdManager.IsTrackableAdRevenue` | Bỏ impression có doanh thu âm, NaN hoặc ≥ 1 USD trước khi gửi Firebase / Adjust / AppsFlyer / AppMetrica. |
| Thời gian chơi | `PlaytimeTracker.IsWatchingAds` | Bật khi quảng cáo hiện, tắt khi đóng, để không tính thời gian xem quảng cáo vào phiên chơi. |
| Bỏ quảng cáo | `DataManager.HadRemoveImperativeAds()` | Đúng khi có gói vĩnh viễn **hoặc** subscription còn hạn. Chỉ tắt interstitial; rewarded vẫn giữ nguyên. |
| Placement | `AdmobEnum.cs` | Mỗi vị trí một hằng chuỗi (`ad_offline_reward`, `ad_x2_income_main`…), dùng làm placement của SDK và tham số analytics. |

### 1.2. Các vị trí quảng cáo trong gameplay

| # | Tính năng | Placement | Cơ chế và thông số mặc định | File chính |
|---|---|---|---|---|
| 1 | **x2 thu nhập** | `ad_x2_income_main` | Nút trên HUD; xem → ×2 lợi nhuận trong 300 giây, sau khi hết boost có cooldown 120 giây. Cấu hình theo map. Bị chặn khi đã mua gói x2 vĩnh viễn hoặc boost đang chạy (có thông báo lý do). | `RewardAdsIncomeControl.cs`, `IncomeRewardAdsMapConfigSO` |
| 2 | **Trực thăng nhà đầu tư** | `ad_investor_main` | Sự kiện xuất hiện trên bản đồ: mở khi một công trình đạt cấp 15; lần đầu sau 60 giây của phiên; đậu chờ 60 giây; sau đó cooldown 120 giây; tối đa 10 lần/ngày. Thưởng = 10 × lợi nhuận mỗi phút. Có remote override từng trường. | `HelicopterController.cs`, `HelicopterRewardAdsMapConfigSO`, `UIPopupHelicopterAdsLayer` |
| 3 | **x2 thu nhập offline** | `ad_offline_reward` | Popup khi quay lại: "Nhận" (cơ bản) hoặc "Xem quảng cáo" (gấp đôi). Trần offline 4 giờ, tối thiểu 5 phút mới hiện. Hủy quảng cáo thì bật lại nút, người chơi vẫn nhận được phần cơ bản. | `UIEarnOfflineLayer.cs`, `EarnOfflineConfigSO` |
| 4 | **Thưởng lên cấp / mở công trình** | `ad_unlock_building_main` | Popup có thưởng cơ bản (đóng là nhận) và thưởng lớn hơn qua quảng cáo. | `UIPopupLevelUpRewardLayer.cs` |
| 5 | **Quà ngày x2** | `day_gift_x2` | Nhận quà ngày rồi có thể xem quảng cáo để nhân đôi. | `UIPopupDailyGift.cs` |
| 6 | **Tiền miễn phí trong shop** | `ad_free_gold` | Có lượt miễn phí sau mỗi 1440 phút, cộng 100 tiền/quảng cáo, tối đa 5 quảng cáo/ngày. | `ShopFreeGoldPack.cs`, `FreeGoldConfigSO` |
| 7 | **Gem miễn phí trong shop** | `ad_gem_shop` | 10 gem, cooldown 720 phút. | `ShopFreeGemPack.cs`, `FreeGemConfigSO` |
| 8 | **Rương miễn phí** | `ad_common_chest_shop` | Mở rương thường bằng quảng cáo (shop và popup thông tin rương). | `ShopChestItemAds.cs`, `ShopChestItemFree.cs`, `UIChestInfoLayer.cs` |
| 9 | **Ads Break** (interstitial bắt buộc) | `ad_inter_main` | Sau khi nhận nhiệm vụ thưởng tiền: popup "ad break" → 1 giây sau tự chạy interstitial → đóng thì cộng 2 × tiền nhiệm vụ. Điều kiện: đã qua 30 giây đầu phiên; đã nhận ít nhất 3 nhiệm vụ từ lần trước; đã qua 60 giây từ rewarded gần nhất; đã qua 60 giây từ break trước; quảng cáo đã tải sẵn; người chơi chưa mua bỏ quảng cáo; công trình mở khóa của map đã đủ cấp. Có timeout an toàn để popup không bị treo. | `AdBreakController.cs`, `AdsBreakConfigSO`, tài liệu `AI/AdsBreak/ads-break-v1.md` |
| 10 | **Vé quảng cáo** | (không có placement) | Đơn vị tiêu hao thay cho một lần xem; nhận từ nhiệm vụ, IAP, shop. Còn vé thì `TryRequestShowRewardedVideo` trừ vé và phát thưởng luôn, không mở quảng cáo. | `DataManager.ChangeAdsTicket`, `AdsTicketShopConfigSO` |
| 11 | **Gói bỏ quảng cáo / subscription** | — | Tắt interstitial (kể cả Ads Break); rewarded vẫn phải xem (hoặc dùng vé). | `SubscriptionManager`, `AdFreeStarterPack` |

### 1.3. Bài học rút ra

1. **Một hàm gọi duy nhất cho gameplay**: gameplay không chạm SDK, chỉ gọi `try_show_rewarded(placement, ...)`. Vé, mất mạng, dự phòng và popup lỗi đều nằm sau hàm này.
2. **Callback dùng một lần và tự gỡ**: có cờ đã xong và cờ đã thưởng để thưởng không bị phát hai lần dù SDK bắn `rewarded` rồi `closed`, hay bắn `closed` hai lần.
3. **Lỗi hợp đồng cần tránh**: khi trả `false`, lumber **không gọi** `onClosed`. Mỗi màn hình phải tự gọi lại (`if (!requested) OnVideoClosed();`), và chỗ nào quên là nút bị kẹt ở trạng thái chờ. Bản của mình nên luôn kết thúc bằng đúng một callback `on_finished(result)`.
4. **Cấu hình tách khỏi mã**: mỗi tính năng có file cấu hình riêng (thời lượng, cooldown, giới hạn ngày, hệ số thưởng), có remote override. Thưởng tính theo **lợi nhuận mỗi phút** nên tự co giãn theo tiến trình.
5. **Thời gian xem quảng cáo không tính vào game**: bật cờ đang xem quảng cáo để dừng đồng hồ phiên.
6. **Cổng mở khóa**: không hiện quảng cáo ngay khi người chơi mới vào (mở khi công trình đạt cấp, và chờ một khoảng đầu phiên).
7. **Stub cho Editor** (`NoAdManager`) để chạy và test mà không cần SDK.

---

## 2. Ràng buộc hiện có của racing_manager

- **D4** ([03](03_Release_Overview.md), [05 §7.1](05_Economy_Monetization.md)): chỉ rewarded, luôn tự nguyện, **không interstitial, không banner**. Phần thưởng cơ bản không bao giờ khóa sau quảng cáo. Trần mềm 8 rewarded/ngày.
- **"Đội tự do" (No Ads)**: quảng cáo thưởng được **nhận thẳng, không cần xem**. Điểm này khác lumber (bên đó gói bỏ quảng cáo vẫn bắt xem rewarded).
- **Chống nhận trùng**: `GameState.processed_rewards` với ID dạng `ad/<transaction>` ([07 §3](07_Technical_Architecture.md)).
- **Giao diện dịch vụ** đã phác: `AdsService.is_ready(placement)`, `show_rewarded(placement) -> {ok, transaction_id}` ([07](07_Technical_Architecture.md) mục dịch vụ).
- **Rủi ro kỹ thuật riêng của Godot**: `GameState.set_suspended(true/false)` chạy khi app ra/vào nền và gọi `settle_offline()`. Quảng cáo toàn màn hình trên di động thường đưa app ra nền, nên nếu không chặn thì (a) thời gian xem quảng cáo bị tính thành **thu nhập offline**, (b) có thể bật panel offline ngay sau quảng cáo, (c) lượt đua bị dừng và chạy tiếp. Cần một cờ `ad_showing` tương tự `PlaytimeTracker.IsWatchingAds`.
- Plugin quảng cáo cho Godot 4.7 **chưa được xác minh** ([07](07_Technical_Architecture.md), rủi ro M5).

---

## 3. Ánh xạ sang racing_manager

| Lumber | Racing_manager | Thưởng đề xuất | Giới hạn | Ghi chú |
|---|---|---|---|---|
| x2 offline (#3) | **Quay lại: nhận gấp đôi** | + đúng phần offline vừa nhận | 1 lần/lần quay lại | Đã có trong 05 §7.1. Phần cơ bản đã ghi save trước khi hỏi (khác lumber: bên đó phải bấm "Nhận"). |
| Thưởng lên cấp (#4) | **Sau lượt đua: thêm tiền** | + đúng `money` cơ bản của lượt | 1 lần/lượt | Đã có trong 05 §7.1. Đua liên tục nên không có panel chặn: hiện nút phụ không chặn trên dải kết quả, hết hạn khi countdown lượt sau bắt đầu. |
| x2 thu nhập (#1) | **Tăng tốc thu nhập ×2** | ×2 `online_rate` | 30 phút, 3 lần/ngày, không cộng dồn | 05 §7.1 đã chốt 30 phút; lumber dùng 5 phút + cooldown. Cần áp vào cả `tick_income` lẫn tiền thưởng đua (tính theo rate). |
| Trực thăng (#2) | **Khách VIP ghé pit** (sự kiện mới) | 10 × thu nhập/phút | Lần đầu sau 60 giây của phiên, chờ 60 giây, cooldown 120 giây, 5 lần/ngày | Hợp hướng idle tycoon: một sự kiện bấm được trên màn đua. Không dùng tên "Nhà tài trợ" vì đã là nâng cấp cúp. Mở khóa sau tutorial Phần A. |
| Quà ngày x2 (#5) | **Quà ngày ×2** | + đúng `daily_gift_amount()` | 1 lần/ngày | Nhận cơ bản trước, xem quảng cáo để cộng thêm. |
| Gem miễn phí (#7) | **Gem miễn phí (shop)** | 5–10 gem | Cooldown 12 giờ | Cân với 05 §6 (tổng gem kiếm được). |
| Rương (#8) | **Gói tay đua/trang bị miễn phí** | 1 lượt mở gói thường (Pro/Standard) | 1 lần/ngày | Dùng `grant_driver_coupons` / `grant_gear_coupons`. Tính vào tỷ lệ ra hàng hiếm của gói thường. |
| Tiền miễn phí (#6) | Bỏ | — | — | Trùng với Khách VIP và tăng tốc; nhiều nguồn tiền qua quảng cáo làm loãng giá trị. |
| Vé quảng cáo (#10) | **Vé bỏ qua** (tùy chọn) | — | — | Nhận từ nhiệm vụ/thành tích. Gói "Đội tự do" tương đương vé không giới hạn. |
| Ads Break (#9) | **Không làm ở v1** | — | — | Trái D4. Xem mục 5. |
| Banner | Không làm | — | — | Trái D4; lumber cũng đang tắt. |

Trần chung: 8 rewarded/ngày cho mọi vị trí cộng lại (05 §7.1). Vị trí đã hết lượt thì ẩn nút, không hiện nút xám.

---

## 4. Kiến trúc đề xuất (Godot)

```
core/ads/ad_placements.gd      hằng placement + cấu hình mặc định (đọc từ data/ads.json)
game/ads_service.gd            autoload: điểm gọi duy nhất cho gameplay
game/ads/providers/
    mock_provider.gd           desktop/editor/test: giả lập sẵn sàng, xem xong, hủy, lỗi, độ trễ
    horus_provider.gd          bản Web: gọi Horus SDK qua JavaScriptBridge (xem mục 7)
data/ads.json                  thông số từng placement (thưởng, cooldown, giới hạn ngày, mở khóa)
```

Chọn provider lúc khởi động: `OS.has_feature("web")` và có `window.HorusSDK` thì dùng `horus_provider`, còn lại dùng `mock_provider`.

**API cho gameplay** (rút từ bài học 1–3):

```gdscript
# Luôn gọi on_finished đúng một lần với kết quả:
#   {"status": "rewarded" | "skipped_entitled" | "cancelled" | "unavailable" | "no_network" | "capped",
#    "reward_id": "ad/<placement>/<transaction>"}
func try_show_rewarded(placement: String, on_finished: Callable) -> void
func can_offer(placement: String) -> bool        # đủ điều kiện, chưa hết lượt, quảng cáo sẵn (hoặc có quyền nhận thẳng)
func remaining_today(placement: String) -> int
var ad_showing: bool                             # GameState đọc để bỏ qua set_suspended/settle_offline
```

**Thứ tự trong `try_show_rewarded`**:

1. Đang có yêu cầu khác → `unavailable`.
2. Vượt trần ngày hoặc cooldown → `capped`.
3. Có "Đội tự do" hoặc vé → `skipped_entitled` (trừ vé nếu dùng vé), không mở SDK.
4. Mất mạng → `no_network`; chưa tải xong → `unavailable` và kích hoạt tải lại.
5. Bật `ad_showing`, gọi provider. Cờ `done` chống bắn trùng. Thưởng chỉ khi provider báo reward, sau đó `closed`.
6. Tắt `ad_showing`, ghi lượt dùng (ngày theo UTC như `last_daily_day`), gọi `on_finished`.

**Phát thưởng nằm ở GameState, không ở UI**: ví dụ `GameState.claim_ad_reward(placement, context, reward_id)`. Hàm này kiểm tra `processed_rewards[reward_id]`, cộng thưởng theo `data/ads.json`, lưu save trong cùng một transaction như `claim_daily`. UI chỉ gọi dịch vụ và hiện hiệu ứng.

**Chặn tác dụng phụ khi ra nền**: trong `set_suspended`, nếu `AdsService.ad_showing` thì không cộng offline và không bật `offline_report`; khi quay lại thì tiếp tục lượt đua như hiện tại.

**Analytics**: `ad_offered` (khi nút hiện), `ad_started`, `ad_completed`, `ad_failed` với tham số `placement` và `status`. Lọc doanh thu bất thường như lumber nếu SDK báo doanh thu.

**Test headless** (`tests/ads_test.gd` với mock provider): thưởng một lần dù callback lặp; hủy thì không thưởng và vẫn gọi `on_finished`; trần ngày và reset theo ngày UTC; "Đội tự do" nhận thẳng; `ad_showing` chặn offline; ID trùng sau khi tải lại save không phát thưởng lần hai.

---

## 5. Điểm cần chốt

1. **Ads Break (interstitial)**: lumber dùng để tăng doanh thu, có thưởng bù. Racing đã chốt D4 là không interstitial. Đề xuất giữ D4 cho v1. Nếu muốn thử, có thể đặt sau công tắc remote, chỉ hiện sau lượt đua, cùng các chặn như lumber (30 giây đầu phiên, mỗi 3 lượt, 60 giây sau rewarded, không áp cho người mua) và thưởng bù tiền. Thay đổi này phải ghi vào bảng quyết định ở 03.
2. **Thời lượng tăng tốc ×2**: 30 phút, 3 lần/ngày (05) hay 5 phút với cooldown ngắn, xem nhiều lần (lumber)? Đề xuất giữ 30 phút vì hợp nhịp idle và trần 8 quảng cáo/ngày.

## 6. Thứ tự triển khai đề xuất

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| P1 | `AdsService` + mock provider + `data/ads.json` + `claim_ad_reward` + chặn `set_suspended` + test | Không |
| P2 | Quay lại ×2 và thêm tiền sau lượt đua (UI) | P1 |
| P3 | Tăng tốc ×2 + quà ngày ×2 | P1 |
| P4 | Khách VIP ghé pit (sự kiện + art) | P1, asset |
| P5 | Shop: gem miễn phí, gói miễn phí; "Đội tự do" nhận thẳng | P1, IAP |
| P0 | Thử export Web: Compatibility renderer, một luồng, chạy trong trình duyệt điện thoại, đo fps | Không (làm trước, vì có thể đổi hướng) |
| P6 | `horus_provider` + HTML shell + mirror save + build APK thử bằng `horus-build.mjs` | P0, P1 |

---

## 7. Horus SDK (thêm 12/11/2026)

Thư mục `horus-sdk/` (bản 0.21.1) là SDK của Horus, **dành cho game HTML5**. Horus bọc bản build web thành app Android/iOS và tự gắn AppLovin MAX, Firebase, Adjust, store. Vì vậy không cần plugin quảng cáo Godot nữa, nhưng game **phải chạy được dưới dạng bản export Web của Godot**. Quy tắc dùng SDK nằm ở `horus-sdk/AGENTS.md`.

### 7.1. API quảng cáo Horus so với thiết kế ở mục 4

| Nhu cầu | Horus SDK |
|---|---|
| Khởi động | `await HorusSDK.start({ skus })` trước khung hình đầu, `platform.ready()` khi màn đầu đã vẽ |
| Xem rewarded | `await platform.ads.rewarded('<placement>')` → `{ ok, reason: '' \| 'closed' \| 'not_ready' \| 'error' }`. Chỉ thưởng khi `ok` |
| Nút sáng/tối | `platform.ads.ready().rv`; sự kiện `platform.on('ads', s => …)`; `platform.ads.load('rv')` khi sắp mời xem |
| Tạm dừng | `platform.on('pause', e)` với `e.reason` là `'ad'` hoặc `'bg'`; sau đó `resume` |
| Doanh thu | Sự kiện `adpaid` (app đã tự gửi Firebase/Adjust; game chỉ dùng cho logic riêng) |
| Thử trên trình duyệt | `platform.ads.simulate(fn, { loadMs })`: game tự vẽ quảng cáo giả |
| Placement | Chữ thường, không dấu, khai báo trong `horus-game.json` (`ads.rewarded`) |
| Analytics | `rv_offer` khi nút hiện, `rv_start`, `rv_done`; tiền: `platform.an.earn` / `spend` |
| Interstitial | `platform.ads.inter()` và luật `monetize.interDue`. **Không dùng** vì D4 |

`ads_service.gd` giữ nguyên hợp đồng ở mục 4. `horus_provider` chuyển `reason` của Horus thành `status`: `closed` → `cancelled`, `not_ready` → `unavailable`, `error` → `unavailable`. Horus không trả `transaction_id`, nên `reward_id` do game tự sinh: `ad/<placement>/<ad_counter>`, với `ad_counter` tăng và lưu trong save **trước khi** mở quảng cáo.

Placement đề xuất: `offline_double`, `race_bonus`, `income_boost`, `daily_double`, `vip_pit`, `free_gems`, `free_pack`.

### 7.2. Những thay đổi bắt buộc trong dự án

1. **Renderer**: `project.godot` đang dùng `Forward Plus`, mà bản Web của Godot 4 chỉ chạy với **Compatibility** (cần xác nhận lại với Godot 4.7). Phải đổi sang Compatibility và kiểm tra lại shader (`ui/car_paint.gdshader`), ánh sáng và hiệu ứng.
2. **Export Web**: chưa có `export_presets.cfg`. Cần preset Web, nên chọn **bản một luồng** (không cần SharedArrayBuffer/COOP-COEP, an toàn hơn trong WebView). Việc WebView của Horus có hỗ trợ bản nhiều luồng hay không **chưa xác minh**. Đầu ra là thư mục `web` trong `horus-game.json` (ví dụ `export/web`).
3. **HTML shell riêng**: nạp `horus-sdk.js` trước engine, gọi `HorusSDK.start()` rồi mới khởi động Godot. Thêm một lớp JS nhỏ (ví dụ `window.rmHorus`) để GDScript gọi bằng `JavaScriptBridge.get_interface()` và nhận kết quả qua `JavaScriptBridge.create_callback()` (giữ tham chiếu callback cho tới khi có kết quả). Không sửa hay bọc lại file trong `horus-sdk/`.
4. **Vòng đời**: trên Web, `NOTIFICATION_APPLICATION_PAUSED` không thay được sự kiện của app. Đổi sang `pause`/`resume` của Horus. `reason: 'ad'` thì chỉ dừng đồng hồ và âm thanh, **không** gọi `settle_offline()` (đây chính là rủi ro `ad_showing` ở mục 2). `reason: 'bg'` thì dùng luồng `set_suspended` hiện có.
5. **Lưu game**: `user://` trên Web nằm trong IndexedDB của WebView, cài lại app là mất. Mỗi lần `save_game()` thành công thì gọi `platform.save.mirror(json)`. Lúc khởi động, nếu không có save thì nạp từ `platform.save.backup`. Cloud save có sẵn (`start({ cloud })`) nhưng có bước xử lý xung đột, nên để sau.
6. **`horus-game.json` ở gốc repo** (bản trong `horus-sdk/` chỉ là mẫu): tên, `appId`, `web`, `build`, icon, `orientation: "portrait"`, placement, SKU (gói "Đội tự do" `consumable: false`, kèm nút Restore), khóa Remote Config, sự kiện.
7. **Không thêm SDK quảng cáo/analytics khác**; không tải gì từ Internet khi chạy (font, ảnh đều nằm trong bản build).
8. `.gitignore`: thêm `build-online/` và `horus-sdk/.old/`. Mã build (`HORUS_BUILD_KEY`) không bao giờ ghi vào repo.

### 7.3. Rủi ro

| Rủi ro | Cách xử lý |
|---|---|
| Hiệu năng Compatibility + WebView trên máy yếu (bản đồ đua, nhiều xe) | Làm P0 trước: đo fps trên máy Android tầm trung và chế độ CPU chậm 4 lần của Chrome |
| Kích thước bản Web (wasm của Godot khoảng vài chục MB) làm app mở chậm | Bỏ module không dùng khi export, nén asset |
| Headless test không chạy được JavaScriptBridge | Test dùng `mock_provider`; `horus_provider` chỉ kiểm tra bằng tay trên trình duyệt với `simulate` |
| Có thể phải đổi hướng nếu bản Web không đạt | Hỏi Horus có hỗ trợ build Godot dạng native không; nếu không, quay về plugin quảng cáo Godot (mục 4 không đổi) |

### 7.4. Kết quả P0 (12/11/2026)

**Thiết lập**
- Đã cài template Web của Godot 4.7.2, chỉ giữ các file `web_*.zip`.
- Đã thêm `export_presets.cfg` với preset "Web": một luồng, không GDExtension, xuất ra `export/web/` (thư mục này đã nằm trong `.gitignore`), không đóng gói `horus-sdk/`, `Design/`, `docs/`, `tests/`, `tools/`.
- Dự án không có mục `[rendering]`, nên bản Web **tự dùng Compatibility** (`rendering_method.web` mặc định) mà không phải đổi renderer của bản desktop. Mục 7.2 bước 1 vì vậy không bắt buộc. Nếu muốn bản desktop trông giống hệt bản Web thì mới đổi.

**Chức năng: đạt.**
- Bản Web khởi động: màn loading, tutorial, lượt đua chạy liên tục, tab và các thẻ nâng cấp đều hiển thị đúng.
- Console không có lỗi. Chỉ có cảnh báo "framebuffer zero size" lúc bảng trình duyệt bị ẩn.
- Thông tin engine: WebGL 2, Emscripten 4.0.20, một luồng.

**Kích thước: cần giảm.**
- Tổng 82 MB: `index.wasm` 39,5 MB, `index.pck` 46 MB.
- Phần lớn `.pck` là ảnh trong `assets/workshop_gp` (42 MB nguồn) do preset đang xuất mọi tài nguyên (`all_resources`).

**Hiệu năng: rủi ro chính.**

| Cách đo (máy dev 16 nhân) | Thời gian mỗi khung hình |
|---|---|
| Web, trong bảng Browser, CPU của Godot mỗi khung | trung bình 27,8 ms, p50 26 ms, p95 41,6 ms |
| Desktop native, Compatibility, tắt vsync | 9–10 ms (≈ 110 fps) |
| Desktop native, Forward Plus, tắt vsync | 9–9,5 ms |
| Headless (không vẽ) | 7–8 ms (**đo sai**: scene rỗng headless cũng 6,9 ms, xem §7.5) |
| Từng hàm logic gọi mỗi khung (`tick_income`, `team_power`, `player_stats`, `race_cosmetics`…) | tổng dưới 0,2 ms |
| `save_game` (10 giây một lần) | 14,5 ms |

Nhận xét:
- Bảng Browser trong app tự hãm khung hình (trang chỉ có ảnh tĩnh cũng chỉ đạt 20 fps), nên dùng thời gian CPU mỗi khung chứ không dùng fps.
- ~~Chi phí không nằm ở renderer, mà ở phần cập nhật UI mỗi khung.~~ Kết luận này sai, vì số đo headless chỉ là nhịp chờ của engine. Nguyên nhân thật nằm ở §7.5.
- Bản wasm chậm hơn native khoảng 3 lần. Máy Android tầm trung chậm hơn máy dev nhiều lần, nên nếu giữ nguyên thì gần như chắc chắn **dưới 30 fps**.
- `save_game` 14,5 ms sẽ gây giật mỗi 10 giây trên máy yếu.

**Kết luận P0:** đường Web + Horus khả thi về chức năng, nhưng phải tối ưu UI trước khi đưa lên máy thật.

**Việc tiếp theo, đề xuất P0b:**
1. Dùng profiler của editor để tìm chính xác phần UI tốn thời gian. Hướng xử lý: chỉ cập nhật text/thẻ khi giá trị đổi; giảm tần suất `_refresh_light`; tách phần vẽ tĩnh của track ra khỏi `_draw` mỗi khung.
2. Mục tiêu: dưới 4 ms mỗi khung ở bản native, tức khoảng 12 ms ở bản Web trên máy dev.
3. Làm `save_game` nhẹ hơn (không tạo bản sao lưu mỗi lần) hoặc tách ra khung khác.
4. Đổi `export_filter` sang chỉ đóng gói tài nguyên đang dùng, và bỏ ảnh xem trước/gallery khỏi bản build.
5. Thử trên điện thoại thật: chạy server tĩnh trong mạng LAN rồi mở bằng Chrome Android. Hoặc build APK thử bằng `horus-build.mjs` (cần mã build từ Horus).

### 7.5. Kết quả P0b: tối ưu hiệu năng (12/11/2026)

**Cách đo.** Chạy game thật ở desktop (Compatibility, tắt vsync) qua script đo. Lần lượt tắt từng phần (gọi `_process` bằng tay để đo riêng, ẩn khung đua, ẩn cả khối đua) rồi so thời gian khung hình và `RenderingServer.viewport_get_measured_render_time_*`. Số đo headless không dùng được vì scene rỗng chạy headless cũng mất đúng 6,9 ms mỗi khung.

**Nguyên nhân tìm được**

| Chỗ | Trước | Sau | Sửa |
|---|---|---|---|
| `race_view._draw()` vẽ lại cả đường đua tĩnh mỗi khung: mỗi đoạn mẫu một `draw_colored_polygon` (phải tách tam giác) và 4–5 `draw_line`, tức hàng nghìn lệnh từ GDScript | ≈ 7 ms/khung, 668 draw call | gộp chung với dòng dưới | Nền và mặt đường chuyển sang lớp con `TrackLayer` (`show_behind_parent`), chỉ vẽ lại khi đổi kích thước hoặc track. Toàn bộ hình tĩnh được dựng một lần thành một mảng tam giác và vẽ bằng một lệnh `canvas_item_add_triangle_array`. HUD dùng lại một `StyleBoxFlat` thay vì tạo mới mỗi khung |
| `_refresh_rows()` (5 lần/giây) | 25–27 ms/lần | 0,9–1,6 ms/lần | `Pricing.revenue_rate`/`revenue_gain` có cache (xoá cùng `_cost_cache` khi nạp lại dữ liệu). Bỏ đoạn dựng chuỗi tooltip vốn tính xong rồi không dùng, bỏ hàm `_row_text`. Chỉ gọi `add_theme_color_override` khi màu thật sự đổi (mỗi lần gọi tốn khoảng 0,1–0,25 ms) |
| Toàn bộ `_process` (main, GameState, tutorial, banner, touch scroll) | ≈ 0,4 ms | không đổi | Không phải điểm nóng |
| `save_game` (10 giây/lần) | ≈ 14 ms trên Windows | không đổi | Phần tính toán dưới 1 ms; phần còn lại là ghi/đổi tên file. Giữ nguyên cách ghi an toàn. Trên Web, `user://` nằm trong bộ nhớ rồi đồng bộ IndexedDB, nên cần đo trên máy thật |

**Kết quả**

| Cách đo | Trước | Sau |
|---|---|---|
| Desktop native, mỗi khung | 8,0 ms (render CPU 2,2, GPU 1,2) | **1,75 ms** (render CPU 0,58, GPU 0,20) |
| Draw call mỗi khung | 668 | **173** |
| Web, CPU của Godot mỗi khung | trung bình 27,8 / p95 41,6 ms | **trung bình 6,8 / p95 9,0 / tối đa 13,7 ms** |

Đạt mục tiêu dưới 12 ms ở bản Web trên máy dev. Hình đường đua kiểm tra bằng mắt trên bản Web: mặt đường, lề, vùng thoát, vạch xuất phát và xe hiện như trước. Vùng thoát mất phần khử răng cưa ở mép, nhưng nằm trên nền cùng tông xanh nên khó thấy. 18 bộ test headless đạt.

**Chưa làm**
- **Kích thước bản build** (82 MB): âm thanh đã nén QOA (2,7 MB sau import). `.pck` 47 MB gần như toàn là ảnh nhập lossless. Muốn giảm mạnh phải chuyển ảnh lớn sang lossy WebP khi import, việc này đổi chất lượng hình cả bản desktop nên cần quyết định riêng. Không loại thư mục khỏi bản build theo kết quả grep, vì code ghép đường dẫn bằng chuỗi (`ROOT + "vfx/..."`).
- **Máy thật**: chưa thử. Bước kế: mở bản Web bằng Chrome Android qua mạng LAN, hoặc APK thử của Horus.

> **Cập nhật 12/11/2026:** danh sách vị trí quảng cáo của v1 đã được thay bằng [26 — Vị trí đặt quảng cáo](26_Ads_Placements.md). Các bảng ánh xạ ở §3 chỉ còn là tham khảo.

### 7.6. P1 đã làm (12/11/2026)

| File | Nội dung |
|---|---|
| `data/ads.json` (+ `GameData.ads()`) | `daily_cap` 8 và 7 placement: `offline_double`, `race_bonus`, `daily_double`, `free_gems` (5 gem, cooldown 12 giờ, 2 lần/ngày) đã có thưởng. `income_boost`, `vip_pit`, `free_pack` để `reward` rỗng nên chưa bao giờ mời (P3–P5) |
| `game/ads/ads_provider.gd` | Hợp đồng provider: `is_online`, `is_ready`, `load_rewarded`, `show_rewarded(placement, done)` |
| `game/ads/mock_ads_provider.gd` | Mock cho desktop/test: `online`, `ready`, `outcome`, `delay_sec`, `double_fire` |
| `game/ads_service.gd` (autoload `Ads`) | `can_offer`, `block_reason`, `offer_amount`, `remaining_today`, `cooldown_left`, `note_offer`, `try_show_rewarded(placement, on_finished)`; tín hiệu `ad_event` (`rv_offer` / `rv_start` / `rv_done` / `rv_fail`) và `changed` |
| `game/game_state.gd` | Thêm `ad_state` (lưu trong save), `ad_pause`. Khi `ad_pause` thì `_process` dừng đồng hồ đua/thu nhập, `set_suspended` bỏ qua (ra/vào nền vì quảng cáo không chạy `settle_offline`) |
| `tests/ads_test.gd` | 47 kiểm tra; đã thêm vào `tools/run_tests.*` |

Quy tắc đã cài:
- **Dịp thưởng:** mỗi dịp có ID `ad/<placement>/<dịp>` ghi vào `processed_rewards`, nên mỗi dịp chỉ nhận một lần, kể cả sau khi nạp lại save.
  - Thưởng đua: `n<lượt vừa xong>`, còn hiệu lực trong lúc hiện bảng kết quả và đếm ngược, hết khi lượt kế xuất phát (`phase == "racing"`). Lưu ý `retry_save()` tạo countdown lượt kế ngay sau khi lưu nên `race_counter` đã tăng 1: dịp là `race_counter - 1` (bản đầu ghi nhầm `race_counter`, lỗi tìm ra khi thử trên trình duyệt, xem 7.7).
  - Offline: `off/r<save_revision>`.
  - Quà ngày: `d<ngày UTC>`, chỉ mời sau khi đã nhận phần cơ bản.
  - Gem: `g<seq>`.
- **Phát thưởng:** trong một giao dịch save. Lưu lỗi thì khôi phục như cũ, trả `failed`, và không trừ lượt.
- **Kết quả:** `on_finished` luôn được gọi đúng một lần, kể cả khi provider báo kết quả hai lần hoặc yêu cầu bị chặn ngay từ đầu. Lumber bị lỗi ở chỗ này (§1.3).
- **"Đội tự do":** bật bằng `ad_state.free = true` thì nhận thẳng (`skipped_entitled`), không mở quảng cáo nhưng vẫn tính trần ngày. Chưa có IAP để bật cờ này.

Giới hạn còn lại:
- Nếu người chơi thật sự rời app trong lúc đang xem quảng cáo, khoảng thời gian đó không được tính là offline.
- `AdsService` gọi `_save_data` / `_restore_transaction` của GameState trực tiếp (hàm nội bộ), vì GameState chưa có API giao dịch công khai.
- Chưa có UI (P2) và chưa có `horus_provider` (P6).


### 7.7. Base nối Horus SDK đã làm (12/11/2026)

**File mới / sửa**

| File | Nội dung |
|---|---|
| `web/shell.html` | HTML shell của bản Web, dựng từ shell mặc định Godot 4.7.2. Nạp `horus-sdk.js`, định nghĩa `window.rmHorus` (cầu nối), gọi `HorusSDK.start({cloud:false, skus:[]})` **trước** khi khởi động engine. `boot()` không bao giờ ném lỗi: SDK hỏng thì game vẫn chạy nhưng không có quảng cáo. Trên trình duyệt có lớp phủ quảng cáo giả "Xem hết / Đóng sớm" (trong app Horus dòng này không làm gì) |
| `game/ads/horus_ads_provider.gd` | `AdsProvider` thật: `is_ready` đọc `rmHorus.rv`, `show_rewarded` gọi `rmHorus.showRewarded` qua `JavaScriptBridge.create_callback`. Chuỗi lạ hay thiếu đều thành `error`, không bao giờ thưởng |
| `game/horus_platform.gd` (autoload `Horus`, class `HorusPlatform`) | Chỉ chạy khi `OS.has_feature("web")`. (1) Khôi phục save từ `platform.save.backup` khi chưa có `save.json`/`save.bak`. (2) Cài `HorusAdsProvider` cho `Ads`; **không có SDK thì cài provider trống, không bao giờ dùng mock trên Web** (mock phát thưởng miễn phí). (3) Mỗi lần `GameState.saved` thì `platform.save.mirror`. (4) `pause`/`resume` của app: tắt/bật tiếng master; `pause` lý do `ad` không suspend, `bg` dùng `set_suspended`. (5) `ad_event` -> `platform.an.log`. (6) `platform.ready()` sau 3 khung hình |
| `game/game_state.gd` | Thêm `signal saved` (phát sau khi ghi `save.json` xong) |
| `horus-game.json` (gốc repo) | Tên, `web: export/web`, `build`, placement rewarded (4 cái đã có thưởng), `inter: []` (D4), sự kiện `rv_offer/rv_start/rv_done/rv_fail`, `products: []` |
| `export_presets.cfg` | Dùng shell tuỳ chỉnh, không đóng gói `web/*`, `export/*` |
| `tools/build_web.ps1` | Export Web rồi chép `horus-sdk.js` vào `export/web`. `horus-build.mjs` gọi script này qua trường `build` |
| `tests/horus_test.gd` | Ánh xạ kết quả, vòng đời, khôi phục save; thêm vào `tools/run_tests.*` |
| `.gitignore` | Thêm `build-online/`, `horus-sdk/.old/` |

**Kiểm chứng**
- Headless: 23 bộ test đạt, trong đó `ads_test` có thêm phần chạy một lượt đua thật (không tự dựng `last_result`).
- Trình duyệt (bản debug + móc `?adtest=<placement>`, chỉ chạy khi `OS.is_debug_build()`): SDK 0.21.1 khởi động, `rmHorus.ok = true`; quảng cáo giả hiện ngay sau lượt đua thật và countdown đứng yên trong lúc xem; "Xem hết" cộng đúng tiền cơ bản (23K → 23,1K, ID `ad/race_bonus/n21`), lần thử lại cùng lượt bị chặn (`claimed`); để quảng cáo hiện 40 giây vẫn nhận thưởng; "Đóng sớm" không thưởng và `on_finished` vẫn gọi đúng một lần; `platform.save.mirror` nhận bản save sau mỗi lần lưu; `platform.an.log` nhận `rv_start`, `rv_done`/`rv_fail`; bốn sự kiện `pause/resume` giả lập tới đúng handler.
- `horus-build.mjs --dry-run`: đóng gói 13 file (53 MB), chỉ còn cảnh báo thiếu `icon.png`.

**Lỗi tìm ra nhờ thử trên trình duyệt**
- Điều kiện dịp thưởng đua của P1 sai (xem 7.6), test headless không bắt được vì tự gán `last_result` đúng như điều kiện sai. Đã sửa và thêm test đua thật.

**Chưa giải thích được / chưa kiểm chứng**
- Một lần thử "Xem hết" trên trình duyệt trả `failed` (nhận thưởng thất bại) mà log lúc đó chưa đủ; ba lần thử sau với cùng luồng đều thành công. Đã thêm log chẩn đoán `[Ads] claim ...` (chỉ in ở bản debug) vào mọi nhánh từ chối của `_claim`. Nếu gặp lại, log sẽ cho biết do dịp hết hiệu lực hay `save_game` lỗi trên Web.
- Màn loading trong trình duyệt của môi trường thử đôi lúc mất 15–80 giây ở mức 5–7%, không đều giữa các lần. Chưa rõ do trình duyệt bị hãm khi bảng Browser ẩn hay do game; cần đo trên máy thật.
- Chưa thử trong app Horus thật (cần `appId` và mã build của Horus): MAX thật, `pause` lý do `ad`, backup save khi cài lại.
- `HorusPlatform._on_lifecycle` tắt tiếng bằng bus Master. Nếu sau này game có nút tắt tiếng riêng dùng bus Master thì sẽ đè nhau.

**Việc còn lại để base hoàn chỉnh (không thuộc phần quảng cáo)**
1. `icon.png` 1024×1024 ở gốc repo và `appId` do Horus cấp trong `horus-game.json`.
2. Nút Back Android: `platform.onBack` chưa nối (đóng popup rồi mới thoát).
3. Cloud save đang tắt (`cloud: false`), cần luật xử lý xung đột (README mục 8) rồi mới bật.
4. IAP: khai báo sản phẩm "Đội tự do" (`consumable: false`), `platform.iap.pending()`, nút Restore, và đặt `ad_state.free`.
5. `platform.an.earn/spend` cho tiền tệ (số tiền là BigNumber nên cần quy ước làm tròn/giới hạn trước).
