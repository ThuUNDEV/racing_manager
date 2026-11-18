# Pack Promo Popup — Soft Miniature concepts

Concept ảnh overlay trên tab Race, không phải bản UI đã triển khai. Ba ảnh dùng bản en, mục tiêu 886×1920 (logical 390×845). Sinh bằng built-in image_gen; prompt nguyên văn và vai trò ảnh tham chiếu ở `prompts.json`. Không chỉnh code/data, không commit.

Ảnh gốc image_gen trả về 916×1717. Bản bàn giao đã xuất đúng **886×1920**, giữ nguyên tỉ lệ artwork ở 886×1661 và thêm nền navy 129/130 px trên/dưới; không kéo méo nhân vật hay cắt nội dung. Ảnh thô cùng bản sao prompt lưu ở `output/imagegen/pack_promo_popup/` theo CLAUDE.md. Các dải navy là canvas xuất ảnh, không phải safe-area bắt buộc của game. Chữ hậu cảnh mờ được kế thừa từ ảnh tham chiếu; chỉ copy nội dung en của popup khi dựng runtime.

## Nội dung đã đối chiếu

| Ảnh / SKU | Giá USD | Phần thưởng | Giới hạn |
|---|---|---|---|
| `pack_promo_starter1.png` / `starter_1` | $0.99 | 150 Gem; 3 Pro ticket; 3 Standard ticket; 1 h Income | Buy once |
| `pack_promo_offer_noads.png` / `offer_noads_bundle` | $9.99 | No Ads vĩnh viễn; 300 Gem; 3 Allstar driver ticket | Buy once |
| `pack_promo_weekly_s.png` / `weekly_s` | $4.99 | 300 Gem; 6 Allstar driver ticket; 4 Elite gear ticket; 4 h Income | Limit: 1 per week |

Nguồn: `data/iap.json`, `Design/28_IAP_Packs.md` §3, §4.3, §4.4, §4.9. Badge Rookie ×4.4: (150+30+30+10)/50 = 4.4. Weekly ×2.6: (300+180+120+40)/250 = 2.56, làm tròn theo tài liệu. Đây là quy đổi theo baseline gem của tài liệu, không phải phần trăm giảm giá. No Ads chỉ dùng PERMANENT, không có định giá quyền lợi để suy ra multiplier. Không dùng BEST VALUE cho Weekly/No Ads.

Rookie giữ subtitle “Ready for your first race!”. Cả Rookie và Weekly có note: “Cash is based on the team's income at the time of purchase.” Không in số tiền cash giả. Nhân vật hero chỉ là mascot trang trí, không phải tay đua được tặng. Giá runtime phải lấy từ store, fallback theo data.

## Các lớp dựng lại

Toạ độ dưới đây là khung đề xuất logical, không phải đo từ cây node runtime. Layout ảnh sinh có thể lệch nhẹ; khi dựng dùng container/anchor theo `Design/34_Layer_Layout_Spec.md`, không đo cứng từng pixel từ ảnh.

| Lớp | Vùng / tỉ lệ dự kiến | Màu và cách dựng |
|---|---|---|
| 0. Game | Toàn 390×845; HUD trên và nav 5 tab dưới còn nhận ra | Tab Race, harbor miniature theo `01-race.png`; không đổi thành Shop |
| 1. Scrim | Toàn màn hình | Navy #102D43, opacity khoảng 65–75%; blur nền nhẹ. Chặn input nền |
| 2. Shell | x12..378, khoảng y85..773; rộng 366 | Kem #FFF4E4, viền sáng 2–3, bo 22–26; bóng nâu mềm, không glossy |
| 3. Header | Đầu shell, khoảng 12–15% chiều cao popup | Ribbon xanh #168CC2 + caro kem; title navy #12334C hoặc trắng viền tối; Close đỏ #EE6256, hit rect ≥48×48 trên phải, không bị art che |
| 4. Hero | Khoảng 25–29% chiều cao popup | Diorama mascot + gem/ticket, podium kem, ray vàng #FFD36D, sparkle thưa; tách khỏi chữ động |
| 5. Badge | Góc phải hero, tránh Close | Rookie 4.4x VALUE; Weekly 2.6x VALUE; No Ads PERMANENT. Vàng ấm #F5BD42, chữ navy |
| 6. Rewards | Khoảng 29–34% chiều cao popup, padding 12, gap 8 | Thẻ kem dày; số navy 25–30, nhãn 14–16. Ticket viền phân hạng, chữ vẫn nêu rõ loại; không chỉ dựa vào màu |
| 7. Note | Dưới rewards, 2–3 dòng với gói có cash | Navy xám #52636C, cỡ mục tiêu 13–14, không đặt lên art |
| 8. CTA | Gần đáy, rộng khoảng 326, cao 58–62 | Cam #FF831E, cạnh dưới #D5570E dày 4–5, chữ trắng giá 28–32; nút lớn nhất màn |
| 9. Footer | Dưới CTA, ít nhất 44 cao | Buy once hoặc Limit: 1 per week; View rates dạng text phụ navy 14–16, hit area ≥44 cao |

### Bố cục từng concept

- **Rookie:** mascot giơ tay, gem/ticket trên podium; badge ×4.4. Lưới 2×2: Gem / Pro ở hàng trên, Standard / Income ở hàng dưới. Dải note tách riêng khỏi CTA.
- **No Ads:** TV gạch quảng cáo là tâm điểm hero; PERMANENT gắn quyền lợi. Một thẻ No Ads rộng toàn hàng, tiếp theo hai thẻ Gem / Allstar; không thêm cash hoặc +100 Gem của SKU no_ads đơn lẻ.
- **Weekly:** hero quà theo tuần, badge ×2.6; lưới 2×2 Gem / Allstar / Elite gear / Income. Footer nêu giới hạn 1 lần/tuần, không dùng Buy once hay countdown giả.

## Đọc ở 320 và dịch thuật

Giữ lề ngoài 12, giảm chiều rộng shell theo viewport, vẫn 2 cột rewards. Không scale toàn bộ ảnh thành UI runtime. Chừa title tối đa 2 dòng, nhãn món tối đa 2–3 dòng; tăng chiều cao card theo bản dịch thay vì ép font nhỏ. Vùng hero có thể co trước khi co chữ, CTA/footer luôn đủ chạm. Khi thiếu chiều cao cho bản vi/id, nội dung giữa được cuộn, header/CTA giữ cố định. Ảnh concept chưa thay thế kiểm tra UI thật 320/390/412 trong Godot.

Chữ và giá phải là Label/Button riêng qua I18n; không dùng nguyên ảnh concept có chữ làm popup. Asset tách mới phải không có chữ để dịch. Các màu trong bảng là token đề xuất; viền tier cần map lại đúng token rarity runtime.

## Asset có sẵn và phần cần bổ sung

Đã thấy asset có thể tái dùng: `assets/daily_gift_v3/icons/coupon_driver_pro.png`, `coupon_driver_allstar.png`, `coupon_gear_standard.png`, `coupon_gear_elite.png`, `gem.png`, `glow_soft.png`; cash/gift/trophy và icon pack tại `assets/soft_miniature_race_ui_v3/icons/`; `assets/soft_miniature_ui_v1/runtime_flare/shop_no_ads.png` là minh hoạ phẳng sẵn có, không phải cutout của hero mới. Daily Gift v3 cũng có `skins/panel_cream.png`, `header_cyan.png`, `button_close.png`, `button_claim_orange.png` để đánh giá tái dùng. Không coi những món này là asset thiếu.

**Chưa có sprite tách riêng khớp chính xác concept mới:** 3 diorama hero trong suốt (mascot + gem/ticket; mascot + TV no-ads; weekly reward podium), ribbon uốn có đuôi/caro và huy hiệu giá trị không chữ, cash+clock kết hợp. Có thể ghép cash với clock vẽ code thay vì sinh sprite mới. Các ảnh PNG bàn giao là toàn màn hình, chưa phải sprite atlas hay 9-slice skin.

**Khó dựng thuần code Godot:** silhouette mascot, xếp chồng gem/ticket có bóng tiếp xúc, ánh sáng vật liệu clay, ribbon cong và mép podium có phối cảnh. Dùng sprite tách nền cho các phần này; Panel/Container dựng shell/cards/CTA/chữ. Glow/rays/sparkle có thể dùng texture alpha/particle nhẹ; không cần mô phỏng 3D toàn bộ hero. Bóng/viền card và CTA nên 9-slice hoặc StyleBox, tránh scale bitmap chứa chữ. Chỉ tách sprite sau khi concept được duyệt.

## Kiểm tra bàn giao

Đã kiểm tra trực quan cả 3 ảnh sinh: đúng title, reward count, giá, nhãn mua, badge và note cash; No Ads không có phần thưởng cash. PNG xuất đủ 886×1920, đọc lại được; `prompts.json` parse hợp lệ. Coupon trong concept là biến thể minh hoạ, không thay thế icon coupon runtime đã tồn tại. Vùng hit của X không thể xác nhận bằng bitmap: dev phải dùng Button 48×48 logical dù sprite trông nhỏ hơn. Chưa triển khai hay chạy test UI Godot; kiểm tra bản dịch và hit target là bước sau khi duyệt concept.
