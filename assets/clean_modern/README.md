# Racing Manager · F Clean Modern

Bộ artwork mới theo hướng F được người dùng chọn ngày 2026-11-13: giao diện thể thao cartoon, nền trắng xanh, xanh dương sáng làm nhận diện, xanh lá cho mua/nâng cấp, viền bạc xanh nhẹ.

## Phạm vi

`source_inventory.json` chụp lại 290 ảnh PNG/SVG có sẵn trong bảy thư mục asset trước khi tạo bộ này. `generation_plan.json` chia chúng thành 53 nhóm tạo ảnh. Bộ bao gồm skin UI, icon, control, chân dung, trang bị, xe/decal, cơ sở, hình cửa hàng/IAP/quảng cáo, tutorial, loading, cảnh đua và hiệu ứng.

Không tính font, âm thanh, shader và dữ liệu gameplay vào phạm vi vẽ lại. 40 biến thể utility icon nền tối của bộ cũ dùng chung thiết kế icon mới dành cho nền sáng; vẫn có resource ánh xạ riêng cho mỗi đường dẫn cũ.

## Nội dung

- `sheets/`: PNG do ImageGen tạo, sao chép nguyên byte từ output, không cắt/resize/tô màu bằng script.
- `icons/`: SVG bổ sung cho icon Túi/Đội trên navigation, dựng vector riêng để khớp demo; không tạo lại các sheet.
- `replacements/`: một AtlasTexture cho từng ảnh nguồn cũ. Chữ, giá, chỉ số và bản địa hóa tiếp tục thuộc UI, không bake vào skin.
- `resources/`: các AtlasTexture con của bộ cũ được ánh xạ sang ảnh mới bằng tọa độ tương đối.
- `manifest.json`: palette, nguồn tạo ảnh, checksum, kích thước, vùng cắt và ánh xạ.
- `region_overrides.json`: vùng cắt đã xem lại khi render (icon thông tin offline và skin Continue); bước package giữ các chỉnh sửa này.
- `coverage.csv`: đối chiếu từng ảnh cũ với resource mới.
- `validation.json`: kết quả kiểm tra file, checksum ảnh gốc và giới hạn region.
- `catalog.html`: xem toàn bộ sheet trong trình duyệt.

## Palette

| Vai trò | Màu |
|---|---|
| Nền | `#F1F7FC` |
| Panel | `#FFFFFF` / `#E6F2FC` |
| Nhận diện | `#087EE6` → `#0452B8` |
| Mua / nâng cấp | `#68D719` |
| Chữ chính | `#23394A` |
| Chữ phụ | `#768CA0` |
| Viền | `#ADC9DE` |

Đỏ dành cho đóng/cảnh báo, vàng cho phần thưởng. Màu rarity và nhận dạng nhân vật/vật phẩm vẫn có vai trò riêng, không đổi tất cả sang xanh.

## Trạng thái tích hợp và giới hạn

Đã bật trong game qua `ui/clean_modern_art.gd`: 290 ảnh nguồn và 177 AtlasTexture con được chuyển sang bộ F, cùng palette UI, nine-slice, scene/style và SpriteFrames liên quan. Ảnh nguồn cũ được giữ nguyên. `integration_files.json` ghi danh sách thay đổi của bước tích hợp tự động; không phải danh sách đầy đủ mọi thay đổi trong repo.

Popup chi tiết Shop có đủ ảnh. Thẻ Starter trên trang Shop được thu gọn theo demo đã duyệt; ảnh minh họa nằm trong popup Chi tiết. Các nhóm gói khác giữ ảnh trên thẻ. Khung ảnh dùng chiều cao tối thiểu ổn định (144 px trên thẻ, 180 px trong popup); TextureRect giữ tỷ lệ bên trong. Không cập nhật minimum size trong callback `resized`: cách đó gây vòng lặp bố cục, spam `Object was deleted while awaiting a callback` và crash trên Godot 4.7.2 ở 320 px. Đã bỏ thử nghiệm `_overlay_fit_pending`.

Theo phản hồi tiếp theo của người dùng, giao diện đã chỉnh gần demo hơn: khung đua với nền cỏ sáng; theo yêu cầu mới nhất của người dùng, giữ dải khán giả ba hàng dưới HUD và chiều cao khung 294 px như cũ, HUD hạng/đồng hồ vẫn có trong cuộc đua thật; navigation nền nhạt với icon Túi/Đội mới, chữ không viền dày; danh sách Tay đua đứng trước khu tuyển; Shop dùng bộ lọc sáng, quà hôm nay nền kem và Starter gọn. Chỉ số/điều kiện mở khóa lấy từ dữ liệu thật, không sao chép con số minh họa trong demo.

Sau phản hồi về nút méo và chữ phẳng: skin nút giữ tỷ lệ của ảnh mới (chỉ lấy chiều cao logic từ nguồn cũ), hai đầu bo được giữ bằng nine-slice; navigation đang chọn và nút Quà dùng skin vuông phù hợp ô hẹp. Chữ trắng dùng outline tối 2 px và shadow lệch 1 px; chữ slate dùng outline sáng 1 px và shadow nhẹ. Link/chữ nhỏ dùng viền mảnh để không bết nét. Kiểm tra bố cục có thêm kiểm tra vùng bo không chồng lấn trong các nút đang hiển thị.

Nút ×2 trên khung đua giữ nguyên vùng bấm. Khi chưa mở Shop/hết lượt/ngăn bởi lỗi lưu, nút vẫn hiện với lý do thay vì biến mất. Khi đủ điều kiện, xem quảng cáo vẫn nhận boost theo config; không bỏ qua giới hạn, lưu giao dịch hay điều kiện mở khóa. `tests/clean_modern_demo_test.gd` kiểm tra bằng pointer input tại 320/390/412 và lưu ảnh `clean_modern_demo_*.png`.

Popup offline đã giới hạn icon thông tin trong nút 36×44 px và dùng skin xanh lá chung cho Continue, tránh kéo giãn icon dạng vuông bằng nine-slice. Đã sửa vùng atlas để bỏ mảnh ảnh thừa phía trên icon. Splash engine cũng trỏ trực tiếp tới sheet Clean Modern.

Đã xem render thật trên desktop tại 320/390/412 px. Kiểm tra cả 30 SKU, mở/đóng hai lần mỗi chiều rộng (180 lượt), cùng thay popup liên tiếp. Các tab, garage, settings và popup thông tin được kiểm tra bố cục; ảnh tổng hợp nằm ở `Design/Previews/clean_modern_review_*.png`. Ảnh chi tiết Shop mới: `clean_modern_starter_1_*.png`, `clean_modern_char_lam_*.png`, `clean_modern_pass_growth_*.png`.

Đường đua chính tiếp tục vẽ từ hình học mô phỏng; không thay hình học bằng đường chạy vẽ trong ảnh AI. Màu tiền, gem, rarity, nhân vật và chấm xe giữ vai trò riêng. Chưa kiểm tra trên điện thoại thật hoặc trình duyệt Web. Một số bài UI vẫn báo RID/ObjectDB còn giữ khi thoát; đây là giới hạn kiểm thử còn ghi nhận, không coi là đã xử lý hết resource leak.

## Đóng gói và kiểm tra

Đủ 53 sheet, 290/290 ảnh nguồn và 177 AtlasTexture con. `validation.json` kiểm tra tính toàn vẹn asset: checksum ảnh gốc, resource thiếu và giới hạn region. Kết quả runtime/export nằm trong `runtime_verification.json`.

Preset Web dùng `all_resources` để bao gồm resource tải động; `include_filter` bổ sung JSON gameplay, manifest Clean Modern/IAP, layout đường đua và catalog audio. Đã xuất PCK bằng preset thật rồi chạy `tests/clean_modern_export_test.gd` từ thư mục trống với `--main-pack`: tải đủ 467 texture, 30 scene gói, audio và ba layout. Đây là xác minh nội dung PCK; chưa phải bản Web chạy trong trình duyệt hay APK trên thiết bị.

Các bài cần `RenderingServer.frame_post_draw` phải chạy có render. Mọi bài `tests/*.gd` dùng save riêng. Không commit/push trong đợt hoàn thiện này.

Từ gốc project:

```powershell
python tools/build_clean_modern_assets.py package
python tools/build_clean_modern_assets.py validate
```

`generation_receipts.json` và `receipts/*.json` lưu output gốc theo từng job; receipt riêng được ưu tiên khi có bản gen sửa lại. Không chạy lại bước inventory sau khi asset gốc thay đổi nếu cần kiểm chứng chúng được giữ nguyên trong đợt này.

### Typography follow-up

UI now uses bundled Roboto Bold instead of artificially emboldened Godot fallback. Vietnamese glyphs are checked; Shop filters, daily claim and pack titles were sized closer to the approved raster reference. The exact typeface of that image is unknown. Screenshots: `Design/Previews/clean_modern_demo_*`. Font source and license: `fonts/README.md`.

Shop pack follow-up: pale panels, navy headings, white reward tiles with larger values/captions, blank green purchase skin (`icons/shop_buy.svg`), and separated detail/odds links follow the approved Starter card. Illustrations remain available in details and other existing offer cards. Added viewport-bounds regression check at 320/390/412.

### V5 popup integration — 13 November 2026

Approved V5 layout integrated into pack details: white/ice-blue rounded frame, navy heading, subtitle strip, larger hero, white reward tiles, green dynamic store price, limit/odds footer. All 30 offer popups use the shared layout. The three V5 sample heroes reuse the original illustrated Starter/My/income art rather than their automatic recolor, preserving My orange uniform. Other recipes retain their existing artwork; no original PNG was edited. Actual grants remain data-driven (including the additional character shards); the concept image is not used as a baked UI texture.

Rendered preview: `Design/Previews/iap_v5_runtime_390.png`. Modal test passed 180 open/close cycles at 320/390/412; shop redesign, popup close and synthetic touch scrolling passed. Exported resources checked from an isolated PCK. Native Windows renderer verified, mobile-device testing remains outstanding.
