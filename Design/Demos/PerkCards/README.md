# Perk cards — Soft Miniature concept

Hai ảnh concept dùng built-in `image_gen.imagegen`, không phải UI runtime hay sprite atlas. Prompt nguyên văn và ảnh tham chiếu nằm trong `prompts.json`; bản thô lưu tại `output/imagegen/perk_cards/`. Không sửa code/data/asset cũ, không commit.

**Xuất ảnh:** image_gen trả916×1717 cho cả hai ảnh. Bàn giao đúng886×1920: thu đồng tỉ lệ artwork xuống850×1593 rồi đặt giữa canvas kem, lề18px hai bên và163/164px trên/dưới. Không kéo méo/cắt art hay sửa chữ. Với ảnh section, mép thẻ nằm khoảng12logical từ cạnh canvas; phần đệm trên/dưới chỉ là canvas bàn giao, không là safe area bắt buộc. Manifest xuất ảnh ở `output/imagegen/perk_cards/export_manifest.json`.

- `perk_cards_section.png`: đoạn cuộn **More perks**, 4 thẻ một cột theo thứ tự yêu cầu: income_x2 → income_x3 → income_x3_up → offline_plus. Đây là bảng duyệt các trạng thái SKU, không có nghĩa cả 4 cùng bán trong game. Không thay thứ tự section hiện hành của Shop.
- `perk_card_income_x2_variants.png`: A hero bên trái; B hero phía trên, cùng nội dung và giá. Đề xuất A cho danh sách perk; B ưu tiên diện tích art, cần thẻ cao hơn.

## Nội dung thật

Nguồn: `Design/28_IAP_Packs.md` §4.2; `data/iap.json`. Giá USD trong concept là fallback; runtime dùng giá store.

| SKU | Title / CTA | Benefit en | Điều kiện |
|---|---|---|---|
| income_x2 | Income ×2 / $4.99 | Online income & race rewards ×2, forever | Ẩn khi có income_x3; đã sở hữu thì không mua lại |
| income_x3 | Income ×3 / $9.99 | Online income & race rewards ×3, forever | Chỉ khi chưa có income_x2 và income_x3 |
| income_x3_up | Upgrade to ×3 / $4.99 | Online income & race rewards ×3, forever | Cần income_x2; ẩn khi có income_x3; hero ×2 → ×3 |
| offline_plus | Offline+ / $4.99 | Offline income ×3, up to 24h | Vĩnh viễn, không mua lại; chip 2h → 24h |

Mỗi thẻ có **Permanent**. Online multiplier không áp offline và không nhân chồng boost quảng cáo: hiệu lực lấy max. Offline+ đổi hệ số 0.5 → 1.5 của saved_online_rate gốc và trần 2h → 24h. Không hứa thu nhập 24h khi người chơi chỉ vắng ít hơn. Không thêm badge “×N value” vì tài liệu không định giá perk theo gem. **Lưu ý dữ liệu nguồn:** tài liệu nói tổng hai bước bằng mua thẳng, nhưng fallback hiện là $4.99 + $4.99 = $9.98, khác $9.99 một cent; concept chỉ ghi giá SKU, không khẳng định hai tổng bằng nhau hay mức tiết kiệm.

## Layer để dev dựng

Đơn vị sau là logical px, khung mục tiêu 390×845, xuất 886×1920 (~2.272×). Đây là kích thước đề xuất cho concept, không phải đo từ node Godot. Ảnh chỉ lấy đoạn nội dung cuộn; HUD/ShopChrome/nav vẫn dùng shell hiện hành theo Design/34, không bỏ chúng trong game.

| Layer | Vùng / tỉ lệ | Màu / dựng |
|---|---|---|
| 0. Nền Shop | Toàn đoạn cuộn | Kem ấm #F4E7D8, không panel xanh-trắng cũ |
| 1. Section | x12, rộng366; cao46–50 | Ribbon cyan #168CC2, caro kem, title trắng/navy; hình và Label tách nhau |
| 2. Card shell | x12, rộng366; cao150–190; gap8–10 | Kem #FFF4E4, viền #E8D5BC dày2–3, bo18–22; bóng nâu mềm lệch xuống3–5 |
| 3. Hero | Ảnh sinh chiếm khoảng45–48% rộng; dựng runtime nên co về35–40%, khung125×125; padding10–12 | Diorama xưởng + cash/coin, nền sage nhạt #EAF0D6; shadow/rays dưới art, tránh vùng chữ |
| 4. Badge | Trong hero, tránh title | ×2 cobalt #237FC0; ×3 vàng #F5C34A; chữ navy #102D50; số là Label riêng |
| 5. Copy | Phần phải còn lại, padding12; title cao28–52; benefit cao48–60 | Title Nunito đậm23; benefit15–16, navy/xám #465A60. Một câu lợi ích có thể xuống2–3 dòng |
| 6. Permanent | Dưới hero, cao22–26; rộng theo chữ | Chip mint #D8EBCB, chữ #365C42 cỡ13–14; không là nút mua |
| 7. CTA | Phải dưới; mục tiêu144×48, tối thiểu44×44 | Cam #FF831E; cạnh dưới #CB520F cao4; giá trắng25–28, nổi nhất trong các nút |

Khác biệt hero: **×2** xưởng mái đỏ + tiền + mũi tên tăng + medallion xanh; **×3** tiền nhiều hơn về mặt minh hoạ, medallion vàng (không phải lượng thưởng cash cụ thể); **upgrade** ×2 nhỏ → ×3 lớn, không vẽ thành ×6; **Offline+** xưởng mái xanh + đồng hồ + tiền, chip 2h → 24h. Ánh sáng/vật liệu phải cùng bộ Soft Miniature, không làm glow che copy.

Biến thể B: cùng rộng366, cao228; hero nằm trên khoảng100, copy/CTA trong128 dưới. A khoảng190 cao, hero trái35%. Ảnh phụ phóng cận cảnh để so sánh, không dùng kích thước pixel trên board làm kích thước runtime.

Ảnh phụ do model dựng B cao hơn tỷ lệ228 mong muốn để phóng art; khi triển khai cần compact hero theo thông số trên. Ảnh section giữ bốn thẻ ngang khoảng150logical cao, CTA khoảng44cao trở lên. Chữ/spacing trong bitmap không phải bằng chứng UI đã đạt kiểm320px; dev ưu tiên font và wrapping ở trên hơn tỷ lệ art trong ảnh.

Ở 320px giữ lề12 → card296: co hero trước (~92–100 rộng), giữ chữ15–16 và CTA ≥112×48, title tối đa2 dòng và benefit tối đa3 dòng. Cho card tăng cao tới228; nếu vẫn thiếu chỗ, chuyển benefit thành hàng ngang rộng toàn thẻ phía trên CTA. Không ép font nhỏ hoặc scale cả ảnh. Nhãn vi/id dùng I18n và container tự tính cao; bỏ chip so sánh phụ trước khi thu hẹp copy. Chưa xác minh tràn chữ/hit target trong Godot vì phạm vi chỉ concept ảnh.

## Asset và điểm khó

Đã kiểm có thể tái dùng: `assets/soft_miniature_race_ui_v3/icons/facility.png`, `cash.png`, `coin.png`; `assets/soft_miniature_ui_v1/runtime_flare/shop_income_x2.png` (tranh rocket/cash có ×2, không phải garage hero mới); `custom/offline_income_art.png` (garage/car/clock có sẵn); `runtime_flare/button_orange.png`, `badge_blue.png`, `badge_mint.png`; `assets/daily_gift_v3/icons/glow_soft.png`. Không coi các icon này là thiếu.

Chưa có sprite tách nền khớp **chính xác hero mới** trong các pack đã kiểm: garage+cash ×2/×3, cụm upgrade, bản offline có bố cục gọn như concept. Có thể ghép từ facility/cash/offline art có sẵn trước khi quyết định sinh sprite mới. Badge/chip không chữ và mũi tên có thể dựng code; không bắt buộc thêm sprite cho chúng. PNG concept có chữ bake-in, không dùng nguyên ảnh làm thẻ runtime.

Khó dựng thuần Godot: phối cảnh miniature, cash chồng có bóng tiếp xúc, mép clay của garage/coin, tia sáng khuất sau vật thể và ribbon cong. Dùng TextureRect cutout cho hero, glow alpha riêng; shell/CTA/chip dùng StyleBox hoặc9-slice và Label/Button động. Chỉ tách sprite sau duyệt concept; lần này chưa tạo atlas hay skin production.
