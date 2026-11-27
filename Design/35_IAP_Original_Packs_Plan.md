# 35 — Thêm gói theo hệ thống IAP của Race Star (kế hoạch)

- Ngày: 27/11/2026 · Trạng thái: **đợt A đã code** (xem cuối §4); các đợt B–F chờ duyệt.
- Nguồn: `References/RaceStar_APK_1.9.0/race_star_iap_design.md` (§1, §5, §6). Giá, lịch xoay và điều kiện đọc từ cấu hình APK; phần **[Chưa biết]** của tài liệu đó không được coi là đã xác minh.
- Người dùng yêu cầu bổ sung (27/11/2026): thêm Chain, Limited, Choose-One, Gem Fund, Monthly/Battle Pass, gói mùa và **tham khảo cả điều kiện kích hoạt ở Shop và màn chính**.
- Đổi luật so với [28 §1.4](28_IAP_Packs.md): cho phép offer xoay theo lịch tuần (Limited/Choose-One). Vẫn **không** popup sau thua, **không** offer theo hành vi.

## 1. Điều kiện kích hoạt: game gốc → game mình

Game gốc: mọi popup chỉ hiện ở `MainMenuPopupView`; mở khóa theo **số trận** (`MatchCount`) và **số môn** (`TeamCount`). Game mình: popup chỉ hiện ở tab Đua (`ui/main.gd` `_try_sales_popup`); mở khóa theo `business_tier`, tutorial và gói đã mua (`game/iap_service.gd` `_unlocked`). Không có "số trận" trong luồng IAP, nên quy đổi:

| Mốc game gốc | Tính năng gốc | Mốc tương đương ở game mình |
|---|---|---|
| ≥ 2 trận | Starter Pack, Gear | `U4_shop` (đã có: `starter_1`) |
| ≥ 5 trận | Shop, IncomeX2/X3, NoAds, Players | Mở Shop; thẻ `income_x2`, `no_ads` đã có thẻ ngay. Thêm popup tự hiện cho `income_x2` (xem §2) |
| ≥ 10 trận | Monthly Pass, Garage | `tier ≥ 1` (đã có `pass_month`) |
| ≥ 2 môn | Limited, Choose-One, Festive, Grand Tour | `business_tier ≥ 2` (cùng mốc `offer_combo_1`) |
| Chain Offer | không rõ mốc trong APK | `starter_3` đã mua **hoặc** `tier ≥ 2` |

## 2. Popup tự hiện (màn chính / tab Đua)

Gốc: mỗi popup có `Cooldown`, điều kiện mở, điều kiện ẩn, điểm ưu tiên, nhóm. Cooldown 24 giờ cho tiện ích (IncomeX2/X3/Offline/NoAds/xe/skin), 20 phút cho Limited/Choose-One (không bao giờ ẩn, hiện lại sau mỗi cooldown).

Mình giữ hàng đợi hiện có (`gap_sec` 1800, `per_day` 3, mỗi gói ≤ 1 lần/ngày) và thêm:
1. **`prio` (số nguyên) trong `data/iap.json`**, dùng để sắp hàng đợi thay cho thứ tự mở. Đây là phần §5c "điểm ưu tiên" còn thiếu. Giá trị lấy theo APK: NoAds 400, IncomeX2 300, MonthlyPass 300, IncomeX3 100, Starter/Offline 0.
2. **Điều kiện ẩn**: đã có (`block_reason`: once/owned/hidden). Thêm trạng thái `dropped` khi gói rời hàng đợi mà chưa mua.
3. **Popup tiện ích** (`income_x2`, `no_ads`, `offline_plus`): `auto_popup` 1 lần/ngày, tối đa 3 lần mỗi gói, đúng nhịp 24 giờ của gốc.
4. **Limited/Choose-One**: gốc hiện lại mỗi 20 phút; mình chỉ tự hiện **1 lần mỗi rotation** (phù hợp 28 §1.4), sau đó nằm trong Shop và icon dải chặng.
5. **Banner trước khi hết trận** (`OfferRotationConfig`: 30 giây trước khi hết trận, cooldown 120 giây, chọn theo ưu tiên): tương ứng dải icon gói ở tab Đua (28 §5b-2). Dải sắp theo `prio`; không thêm banner mới.

## 3. Hiển thị trong Shop

Thứ tự cuộn hiện tại giữ nguyên, thêm vào mục ƯU ĐÃI GIỚI HẠN:
1. Thẻ **Chain** (một thẻ cho mỗi chuỗi, hiện gói đang mở + dải vị trí như `starter_steps.gd`).
2. Thẻ **Limited** (3 slot) và **Choose-One** (S/M/L/All), có nhãn hết hạn theo tuần.
3. Gói bị khóa không hiện (đúng với `block_reason`), không dùng bộ đếm giả.

## 4. Giai đoạn

| Đợt | Nội dung | Ghi chú |
|---|---|---|
| A | `prio` + popup tiện ích + `dropped` | Sửa `iap_service.gd`, `data/iap.json`, test |
| B | Chain Offer (2 chuỗi, ~28 gói/chuỗi) | Sinh SKU bằng script từ bảng công thức (gem 50–55/USD, vé tăng dần). SKU không đổi sau khi lên store |
| C | Limited Offer (4 rotation × 3 slot, xoay theo tuần UTC) | Dùng `iap_week()` như `feature_rotation` |
| D | Choose-One (3 rotation × S/M/L/All) | Shard skin gốc → mảnh tay đua theo độ hiếm |
| E | Gem Fund, Monthly (Sprint/Gem Booster), Battle Pass | Hệ thống tiến độ mới, tăng phiên bản save |
| F | Gói mùa | Cần lịch sự kiện, để sau |

**Đợt A (27/11/2026, đã làm):** `data/iap.json` thêm `popup.groups` (thứ tự nhóm `high_value` → `forced` → `superior`) và các trường theo gói: `popup_group`, `prio`, `popup_unlock`, `popup_unless`, `high_priority`. `game/iap_service.gd`: hàng đợi sắp theo nhóm → `prio` giảm dần → thời điểm mở; gói rời hàng đợi vì đã mua/bị thay/đạt tối đa được đánh `dropped` (`popup_dropped()`); gói `high_priority` được hiện một lần bỏ qua `gap_sec` (cờ `high_used` trong `iap.offers`, vẫn tuân thủ `per_day`). `income_x2` (prio 300, từ bậc 1, tối đa 3 lần) và `no_ads` (nhóm superior, bỏ qua khi bundle đang bán) có popup tự hiện; `offer_noads_bundle` chuyển sang nhóm superior. Không đổi giá, quà, save version hay UI; `ui/main.gd` không sửa. Test: `tests/sales_popup_test.gd` (thêm nhóm/prio, dropped, high_priority), `GameData.validate` kiểm các trường mới. Chưa có gói nào dùng `high_priority` thật (dành cho Limited/Choose-One ở đợt C/D). **Dải icon tab Đua (27/11/2026):** `strip_prio` theo `OfferRotationConfig` (`no_ads` 400, `income_x2` 300, còn lại 0). `ui/main.gd` `_refresh_pack_promos` sắp icon theo điểm giảm dần, cùng điểm giữ thứ tự `PACK_PROMOS`, ô tăng tốc luôn đứng đầu; không đổi kích thước, art hay số ô. Test trong `tests/pack_promo_strip_test.gd`.

Mỗi đợt có concept ảnh duyệt trước khi dựng UI (AGENTS.md). Giá và quà không tự đổi; mọi con số mới lấy từ bảng APK hoặc ghi rõ là đề xuất.

## 5. Hàng đợi popup của game gốc (giải mã mã máy, 27/11/2026)

Nguồn: `Team_Manager/work/libil2cpp.so` (ARM32, bản 1.9.0), `global-metadata.dat` v31 và ScriptableObject `PromptQueueConfig`/`PromptGroupsConfig`. Địa chỉ hàm dựng lại từ `Il2CppCodeGenModule` của `Core.Prompt.Private.dll` (101 hàm); script ở `Team_Manager/tools/re_prompt/`. Đã đọc: lambda, `PromptGroup.UpdateGroupAndReturn*Queue`, `PromptService.GetHighPriorityGroups/GetScreenGroups`, `TriggerPromptQueue.MoveNext`, `PromptQueueTracker`. Chưa đọc kỹ thân `ProcessQueue.MoveNext` (mô tả bên dưới về nó là suy luận).

**[Quan sát từ mã]**
- Tham số hàng đợi: `GlobalCooldown` 300 giây, `DisplayLimit` 2, `UpdateCountRequired` 1.
- `RegisterTrigger` (mỗi lần mở màn chính): nếu đã qua mốc `lastShown + 300s` thì tăng bộ đếm. `CanShowQueue` = bộ đếm ≥ 1 **và** `now > lastShown + 300s`. `MarkPromptShown` đặt lại mốc và bộ đếm về 0.
- Mỗi nhóm có hai hàm:
  - Hàng **ưu tiên cao**: chỉ chạy khi nhóm có `UseHighPriorityQueue`. Lấy popup đang mở khóa hoặc đã hiện, **bỏ qua cooldown của popup**, chỉ giữ cái có `HighPriorityUsed` = false, sắp theo **điểm popup giảm dần**.
  - Hàng **thường**: lấy cùng tập đó, giữ cái **không đang cooldown**, sắp theo điểm popup giảm dần.
- `TriggerPromptQueue`:
  1. `screenGroups` = nhóm của màn hình hiện tại, **giữ nguyên thứ tự cấu hình**, không sắp xếp.
  2. `highGroups` = nhóm ở màn hiện tại cộng nhóm `ShowOnAnyScreen`, **sắp theo điểm nhóm giảm dần** (`System` 9999 → `Event` 200 → `ForcedOffer` 0).
  3. Nếu có `highGroups`: ghép hàng ưu tiên cao của từng nhóm theo thứ tự đó, `ProcessQueue(giới hạn, đánh dấu HighPriorityUsed = true)`. **Không bị `CanShowQueue` chặn.**
  4. Gọi `ResetCooldowns` trên các nhóm (nhóm có `ShouldResetCooldown`).
  5. Nếu `CanShowQueue`: ghép hàng thường của `screenGroups` theo thứ tự cấu hình, `ProcessQueue(giới hạn, false)`. Mỗi popup hiện xong thì `MarkPromptShown`.
- Thứ tự nhóm trong cấu hình (`PromptGroupsConfig`): `HighValueOffer` → `ForcedOffer` → `Superior` → `Event` → `System-HighPriority-Menu`.

**Hệ quả**
- Điểm nhóm chỉ quyết định thứ tự ở hàng **ưu tiên cao**. Ở hàng thường, thứ tự là *thứ tự nhóm trong cấu hình*, rồi mới đến điểm popup trong nhóm. Đây là chỗ khác với suy đoán trước đó ("sắp nhóm theo điểm nhóm").
- Hàng thường chạy nhóm `HighValueOffer` (IncomeX2/X3, Offline, xe, skin, Lucky Draw...) trước, rồi `ForcedOffer`, rồi `Superior` (NoAds). Nên `NoAds` (ưu tiên popup 0) chỉ hiện khi `HighValueOffer` không còn gì đủ điều kiện hoặc đang cooldown.
- `ChooseOne`/`LimitedOffer`/`RateUs`/`FreeCash` (nhóm `ForcedOffer`): lần đầu đi hàng ưu tiên cao nên hiện **ngay**, không cần chờ 300 giây và không cần đến lượt; các lần sau đi hàng thường, cooldown 20 phút của chính popup.
- Mỗi lượt tối đa 2 popup (`DisplayLimit`); phần của hàng ưu tiên cao trừ vào giới hạn.

**[Suy luận]** `ProcessQueue` hiện lần lượt từng popup (chờ người chơi đóng), tăng số lần hiện và đặt mốc cooldown, dừng khi đủ giới hạn.

**Áp dụng cho game mình** (thay cho đề xuất cũ ở §2):
1. Hai hàng: *ưu tiên cao một lần* (cờ `high_used` lưu trong `iap.offers[sku]`) rồi *hàng thường*.
2. Hàng thường sắp theo **nhóm** trước (HighValue → Forced → Superior), rồi theo `prio` trong nhóm. Ánh xạ: `income_x2/x3/offline_plus`, gói tay đua, Chain → HighValue; Limited/Choose-One → Forced; `no_ads` → Superior.
3. Giữ `gap_sec` 1800, 3 lần/ngày và một popup mỗi lượt (tab Đua khác màn chính). Không dùng `DisplayLimit` 2.
4. Lần đầu của Limited/Choose-One không bị `gap_sec` chặn, nhưng vẫn tuân thủ `per_day`.

## 6. Chưa biết, cần quyết

- Thân `ProcessQueue.MoveNext` chưa đọc (chỉ ảnh hưởng chi tiết hiện lần lượt).
- Chuỗi Chain nào đang chạy ở game gốc; đề xuất mở cả hai (Tay đua, Gear).
- Số gem của gói gem chính không có trong APK; giữ 50/275/600/1300/3500.

**Bước 0 (27/11/2026, đã làm):** thêm `income_x3` ($9,99, ẩn khi đã có ×2), `income_x3_up` ($4,99, cần ×2) và `offline_plus` ($4,99) vào `data/iap.json`, `horus-game.json` (SKU đã có sẵn trong `web/shell.html` và code `GameState`). Điều kiện mở popup lấy theo gốc: từ trận thứ 5 (khóa mới `popup_unlock.races` = `completed_races`), nhóm `high_value`, `prio` 100/100/0, tối đa 3 lần. Mua ×2 thì popup ×3 chuyển thành `income_x3_up`. Dải icon: một ô `perk` lần lượt hiện `income_x2` → `income_x3_up` → `no_ads` → `offline_plus` (no_ads nhường bundle khi bundle đang bán). Shop mục ƯU ĐÃI ĐẶC BIỆT thêm ba thẻ, thẻ nào chưa đủ điều kiện thì ẩn. Test: `sales_popup_test`, `pack_promo_strip_test`, `iap_test` (30 SKU).

**Đợt B, concept (27/11/2026, chờ duyệt):** `Design/Concepts/IAP_Chain_Offer_v1/chain_offer_shop_v1.png` (+ `prompts.json`): mục "CHUỖI ƯU ĐÃI" gồm hai thẻ Chuỗi tay đua (bước 4/28, $4,99, 255 gem, 10 phiếu tay đua Pro) và Chuỗi gear (bước 1/28, $0,99, 50 gem, 5 phiếu gear Tiêu chuẩn), dải bước có tích xanh / bước hiện tại / ổ khóa. Số liệu minh họa lấy từ bảng gói 1 và 4 của `player_chain` gốc; tên loại phiếu Pro/Tiêu chuẩn là ánh xạ đề xuất sang coupon của game này.

**Đợt B, Chain Offer (27/11/2026, đã làm theo concept đã duyệt):** `tools/gen_chain_offers.py` sinh 56 SKU `chain_driver_01..28` và `chain_gear_01..28` (kind `chain`, `chain_id`, `chain_step`, `once`) từ `ChainOffersConfig` và `iap_catalog.json` đã giải mã (`player_chain`, `gear_chain` 28 bước, giá $0,99 → $99,99, gem và vé đúng APK). Mở bước 1 khi đã mua `starter_3` hoặc bậc ≥ 2; mỗi bước sau mở khi đã mua bước trước (`unlock.bought`). Ánh xạ vé (đề xuất, chờ chốt): vé Player → `driver_coupon.pro`, vé Gear → `gear_coupon.standard`, cho mọi bước (Starter/Pro của gốc không tách bậc). `Iap.chain_skus()` / `Iap.chain_state()` trả bước đang bán; `GameData.validate` kiểm chuỗi liên tục. Shop: mục "CHUỖI ƯU ĐÃI" với hai thẻ `ui/shop_chain_card.gd` (dải bước, thưởng, giá, gói kế tiếp), art cắt từ concept vào `assets/iap_chain_v1/`; chuỗi chưa mở hoặc đã mua hết thì thẻ ẩn. Chưa có popup tự hiện hay icon ở dải tab Đua cho Chain (APK không cho biết mốc kích hoạt). Cập nhật `horus-game.json` và `web/shell.html` (86 SKU), i18n 8 ngôn ngữ (`shop.chain_*`). Test: `tests/chain_offer_test.gd` (dữ liệu, mở khóa, mua tuần tự, thẻ ở 320/390/412); ảnh kiểm `Design/Previews/chain_offer_shop_390.png`. Bỏ qua chuỗi `_01` (30 bước, không rõ có chạy).

**Đợt C+D, Gói Giới hạn và Gói Chọn Một (27/11/2026, đã làm theo concept đã duyệt `Design/Concepts/IAP_Limited_ChooseOne_v1/limited_chooseone_shop_v1.png`):** `tools/gen_timed_offers.py` sinh 24 SKU từ `LimitedOfferConfig`, `ChooseOneOfferConfig` và `iap_catalog.json`: `limited_{vòng}_{ô}` (4 vòng x 3 ô, ô 1 rẻ nhất; vòng 1–3 giới hạn 1 lần, vòng 4 tối đa 5 lần) và `chooseone_{s|m|l|all}_{vòng}` (3 vòng x S/M/L/Tất cả, giá và gem đúng gốc; Tất cả $9,99 so với $14,97 của S+M+L). SKU không được đổi sau khi lên store.
- **Vòng xoay:** theo tuần UTC của `GameState.iap_week()`, vòng hiện tại = `tuần % số vòng + 1` (`GameData.IAP_ROTATIONS`, `Iap.rotation_of`). Ô của vòng khác trả `block_reason` "rotation". Đếm ngược tới thứ Hai 00:00 UTC kế tiếp (`Iap.rotation_ends_in`).
- **Giới hạn tuần:** khóa mới `week_cap` đếm đơn trong tuần từ `iap.buys` (`Iap.bought_this_week`, không đổi cấu trúc save); `week_conflict` loại trừ lẫn nhau: đã mua S, M hoặc L thì khóa Tất cả và ngược lại.
- **Mở khóa và popup:** `unlock.tier ≥ 2`. Nhóm `forced`; chỉ ô giữa của Gói Giới hạn (`high_priority`, bỏ qua `gap_sec` lần đầu nhưng vẫn tuân `per_day`) và gói M của Chọn Một (theo `gap_sec`) tự hiện, mỗi SKU một lần. Sau đó nằm trong Shop và dải tab Đua (một icon chung "timed": Gói Giới hạn rồi Gói Chọn Một).
- **Ngoại lệ với Design/28 §1.4:** hai gói này **có đồng hồ làm mới theo tuần** (không phải hạn riêng từng người), giống game gốc. Gói thường vẫn không đếm ngược.
- **Ánh xạ phần thưởng (đề xuất, chờ chốt):** Key Player Pro + Starter → `driver_coupon.pro`; Key Gear Pro + Starter → `gear_coupon.standard`; "Chọn 1 tay đua" (Epic/Legendary/Mythic/Ultimate) → `driver_coupon.allstar` 2/3/5/8; Collection Rare/Epic/Legendary (vòng 4) → allstar 1/2/3; mảnh skin Rare/Epic/Legendary → mảnh tay đua bậc `pro`/`elite`/`legend` (`grant.driver_shards_tier`). `GameState._iap_tier_shards` dồn mảnh vào tay đua đang sở hữu cùng bậc, chưa tối đa và level cao nhất; chưa có ai thì đổi mỗi 10 mảnh (tối thiểu 1) thành vé Pro (bậc pro) hoặc All-Star (bậc elite/legend). Gói thật sự "Chọn 1 tay đua" và outfit/xe thuộc đợt sau (garage nâng cao).
- **Shop:** hai mục ƯU ĐÃI GIỚI HẠN / CHỌN MỘT, thẻ `ui/shop_timed_card.gd` (3 ô có nhãn GIÁ TRỊ NHẤT, tab S/M/L/Tất cả có nhãn tiết kiệm), art cắt từ concept vào `assets/iap_timed_v1/`. Popup chi tiết (`PackUi.title`) có tiêu đề riêng. Ảnh kiểm: `Design/Previews/limited_chooseone_shop_390.png` và `_b.png`. Ô giữa/đắt của Gói Giới hạn có thêm dòng vé All-Star (concept chưa có dòng này).
- **Kèm theo:** `horus-game.json`, `web/shell.html`, `tests/iap_test.gd` (110 SKU), i18n 8 ngôn ngữ (`shop.limited_*`, `shop.choose_*`, `shop.timed_*`, `shop.tier_shards_*`). Test: `tests/timed_offer_test.gd` (dữ liệu, vòng xoay, giới hạn tuần, loại trừ, quà, thẻ ở 320/390/412, popup chi tiết); `sales_popup_test` và `pack_promo_strip_test` cập nhật (bảy icon pack; thêm khối popup forced).

**Đợt E1, Xe Epic và Bộ sơn Epic (27/11/2026, concept đã duyệt `Design/Concepts/IAP_Epic_Garage_v1/`):** `tools/gen_epic_garage.py` sinh `data/epic_cars.json` (5 xe), 6 màu Epic trong `data/garage_cosmetics.json` và 10 SKU 9,99 USD (`epic_car_{pico|nova|apex|titan|zenith}`, `epic_paint_{aurora|solar|midnight|sakura|neon}`), `once`, `consumable: false` (khôi phục được). Game gốc có 6 xe Epic (6 môn) và 5 trang phục Epic; game này có 5 hạng xe và chưa có trang phục tay đua nên ánh xạ thành 5 xe + 5 bộ sơn. **Cập nhật UI (27/11/2026):** mỗi xe Epic có sơn riêng (`epic_sapphire|jade|ruby|aurum|amethyst`, chỉ mở khi sở hữu đúng xe; 5 sơn của bộ sơn vẫn mở theo SKU), tổng 10 màu Epic. Thẻ Shop dựng lại theo concept: nền tím có quầng sáng và sao, bục xoay ô caro (`CarPreview.pedestal_only`), cờ EPIC, thanh chỉ số 5 đoạn kèm biểu tượng, chấm trang, nút mua 44px, cuộn ngang có snap. Ảnh đối chiếu ở `Design/Previews/epic_review/`. Chưa làm: popup hero (concept `epic_car_popup_v1.png`), biểu tượng dải khuyến mãi riêng, hiệu ứng tia sáng nền thẻ.
- **Xe Epic:** thêm xe thứ 4 cho mỗi hạng, chỉ bán bằng IAP (`iap_only`, không nằm trong `GameData.cars()` nên vẫn 15 xe mua bằng tiền; tra cứu qua `GameData.car()` và `epic_cars()`). Chỉ số mỗi dòng = chỉ số cao nhất của hạng x 1,09 (cân bằng, đề xuất, chờ chốt). `buy_car` từ chối xe `iap_only`; `grant.car` đưa xe vào `owned_cars`; dùng sơn Amethyst làm mặc định. Xe Epic dùng chung mô hình 3D của hạng (chưa có mô hình riêng).
- **Bộ sơn Epic:** `grant.paint`; quyền dùng tính từ đơn đã mua (`GameState.paint_owned`), không thêm trường save nên không nâng `SAVE_VERSION`. Sơn Epic có `ink` (màu decal riêng) và `finish: pearl` (kim loại nhẹ trong `CarPreview`). Ngoại lệ so với `Design/15` §6 ("mọi sơn và decal miễn phí"): sơn Epic là hàng IAP; sơn thường và decal vẫn miễn phí. Concept có decal riêng đi kèm từng bộ sơn (sóng, lửa); bản code chưa có, mỗi bộ sơn dùng bốn decal sẵn có.
- **Điều kiện (theo `CarOffer`/`SkinsOffer`):** mua được từ trận 7 (garage). Popup nhóm `high_value`: xe hạng N hiện sau 10 trận và `business_tier >= N-1`, tối đa 2 lần, mỗi lần cách nhau 1 ngày (xấp xỉ cooldown 24 giờ); bộ sơn hiện sau 20 trận và tier 1/1/2/2/3, tối đa 1 lần; mua xong rời hàng chờ (tương ứng "dừng khi không còn xe khả dụng"). Điều kiện mở thứ hai của `SkinsOffer` trong gốc không giải mã được nên ngưỡng này do ta đặt.
- **UI:** Shop có mục XE EPIC và BỘ SƠN EPIC (`ui/shop_epic_card.gd`, hàng thẻ cuộn ngang, xe 3D render một lần qua `CarPreview`). Garage: bộ sưu tập thêm khối "Xe Epic" (xe chưa mua có nút "Xem trong cửa hàng", chuyển sang tab Shop), lưới màu sơn có icon khóa cho sơn Epic chưa mua. Dải chặng thêm một icon `epic` (icon tạm `pack_offer`). Popup tự hiện dùng thẻ chi tiết chung (`PackUi`), chưa có popup hero riêng như concept ảnh 2. Ảnh kiểm: `Design/Previews/epic_shop_390.png`.
- **Kèm theo:** `horus-game.json`, `web/shell.html`, `tests/iap_test.gd` (120 SKU), i18n 8 ngôn ngữ (`shop.epic_*`, `garage.epic_*`, `data.cars.*_epic`, `data.garage_cosmetics.epic_*`). Test mới `tests/epic_garage_test.gd`; cập nhật `garage_test`, `garage_redesign_ui_test`, `pack_promo_strip_test` (tám icon).
