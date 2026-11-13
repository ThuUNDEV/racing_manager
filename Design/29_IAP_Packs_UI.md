# UI các gói ưu đãi

## Asset đã tạo — 13/11/2026

Bộ asset đợt 1 ở `assets/iap_offers/`: ba hình minh họa không chữ cho `starter_1`, `char_my`, `income_x2` (1536 × 1024); một sheet RGBA ba tư thế Linh/My; sáu AtlasTexture `.tres`; manifest nguồn và hash. Atlas nhân vật dùng ranh giới cột 0/512/990/1536 đã kiểm tra alpha, không chia đều theo 512 vì tư thế bên phải lấn trái mốc 1024.

Preview dùng ảnh mới cùng icon/nút gốc: `assets/iap_offers/preview.html`. Ảnh ghép: `Design/Previews/iap_assets_v1_overview.png`. Gói ZIP gồm asset và phụ thuộc dùng chung: `Design/AssetPacks/Racing_IAP_Illustrated_v1.zip`. Hướng dẫn: `assets/iap_offers/README.md`. Script đóng gói: `tools/package_iap_assets.py`, không sửa pixel ảnh sinh gốc.

Đã kiểm tra tính toàn vẹn PNG, kênh alpha thật, vùng cắt và đường dẫn resource, CRC của ZIP; preview trình duyệt dùng đủ ảnh và không tràn ngang ở 320/390/412 px. Chưa import/render Godot, chưa gắn vào Shop hoặc thanh toán. Các SKU còn lại chưa có hình minh họa riêng trong đợt này.

## Cập nhật hướng hình ảnh theo asset — 13/11/2026

Theo yêu cầu đối chiếu asset hiện có, concept mới nhất là `Design/Previews/iap_packs_v4_asset_reference_concept.png`. Bản HTML bên dưới vẫn là mockup V2, chưa chuyển thành bố cục minh họa V4. Ảnh V3 chỉ là hướng thử, không dùng làm chuẩn nhận diện.

Đã xem trực tiếp các sheet, icon, surface và tham chiếu của `HdUi`/`ExpansionArt`:

| Thành phần | Nguồn chuẩn | Áp dụng |
|---|---|---|
| Người dẫn | `assets/tutorial/linh_expressions.png` | Linh, tóc đuôi ngựa, headset xanh, đồng phục xanh–trắng–cam; không dùng ông quản lý mới. Linh minh họa lợi ích, không phải thưởng Starter. |
| Tay đua My | `assets/racing_ui_hd_expansion/sprites/driver_my.tres` → `sheets/driver_portraits.png` | Tóc ngắn, khuyên tai, áo cam; giữ khuôn mặt và bậc Elite. |
| Xe | `assets/racing_ui_hd_expansion/sheets/garage.png` | Dòng Pico–Zenith, thân trắng/bạc, chi tiết cam, kính xanh; không đổi sang xe F1. Xe chỉ làm bối cảnh, không nằm trong phần thưởng. |
| Garage, pack | `assets/racing_ui_hd_expansion/sheets/packs_facilities.png` | Garage mái xanh viền cam, Pro dùng pack mũ xanh, All-Star dùng pack tím; gear Standard dùng hộp xanh, Elite dùng hộp tím. |
| Tiền tệ | `assets/racing_ui_hd/icons/gem.png`, `icons/cash.png` | Gem vàng, tiền xanh. Biểu tượng diamond xanh trên hộp Elite là chi tiết của asset hộp, không thay màu tiền tệ. |
| Panel, nút | `assets/racing_ui_hd/surfaces/panel_body.png`, `button_claim.png`, `icons/close_red.svg` | Panel sáng, viền xanh, nút xanh lá bóng bo tròn, đóng đỏ; theo cách dùng trong `ui/hd_ui.gd`. |

Ảnh V4 là concept sinh từ các asset tham chiếu, có vẽ lại nhân vật/bối cảnh; chưa phải ảnh ghép giữ nguyên pixel asset, chưa phải texture phát hành. Khi dựng UI: dùng icon, nút và chữ động thật; hình minh họa riêng được duyệt và xuất tách lớp. Trạng thái đã có My cần hiển thị tổng 70 mảnh thay cho thưởng tay đua + 30 mảnh, không hiển thị cả hai như hai khoản thưởng cộng thêm. Không thay code gameplay hoặc danh mục trong bước này.

Ngày: 13/11/2026. Phiên bản 2 — thiết kế lại theo yêu cầu. Trạng thái: bản thiết kế để duyệt, chưa tích hợp Godot.

## Nguồn và bản xem

- Nội dung, giá dự phòng, giới hạn và SKU: `data/iap.json` (30 SKU).
- Luật hiển thị và popup: `Design/28_IAP_Packs.md`.
- Chân dung, chỉ số và lối đua: `data/drivers.json`; hình dùng atlas hiện có.
- Mở `Design/Mockups/iap_packs.html` bằng trình duyệt. Chọn gói ở cột phải, chọn tình huống Shop và trạng thái giao dịch ở thanh trên. Trên điện thoại, bấm “Xem chi tiết gói” để mở popup.
- Chạy `python Design/Mockups/build_iap_mockup.py` để cập nhật dữ liệu sau khi sửa JSON. Chỉnh bố cục tại `iap_packs.template.html` rồi chạy lại lệnh trên.

Mockup chỉ mô phỏng UI, không gọi IAP và không ghi save. Giá đang dùng `price_fallback`; khi tích hợp phải lấy `Iap.price(sku)`.

## Hướng hình ảnh

Banner xanh đậm với hình phần thưởng lớn, tiêu đề nêu lợi ích, vùng nội dung trắng và nút mua xanh lá nổi khối. Gói tay đua Elite dùng tím, Legend dùng vàng nâu, tuần dùng xanh ngọc. Chân dung và icon lấy từ asset hiện tại. Vé Pro/All-Star, gear Standard/Elite phải dùng đúng hình tương ứng phần thưởng. Nút đóng nền trong suốt ở góc phải. Thanh Shop có lối tắt Nổi bật / Pass / Tay đua / Gem.

Mỗi thẻ có lời dẫn nêu lợi ích, tên gói, hình minh họa lớn, nhãn giá trị/giới hạn, toàn bộ phần thưởng, giá, liên kết chi tiết và “Xem tỉ lệ” nếu có coupon. Nhãn ×N bấm được để xem cách tính; không gọi nó là mức giảm giá. Không hiển thị giá cũ gạch ngang hoặc phần trăm giảm khi cấu hình chưa có cơ sở so sánh.

Mốc thiết kế: màn hình 390 px, khoảng lề 12 px, khoảng cách 8–12 px, bo thẻ 17 px. Nút mua ít nhất 44 px; popup có nút mua 50 px. Ở 320 px, nội dung cuộn dọc và không tràn ngang. Popup cao tối đa vùng màn hình, cuộn nội dung khi nhiều phần thưởng; không thu nhỏ chữ để ép tất cả vào một màn hình.

## Bộ mẫu

| Nhóm | Cách trình bày |
|---|---|
| Starter 1–3 | Một thẻ đang mở, dải bước 1 · 2 · 3. Gói 2/3 có chân dung Hà/My; gem, vé và thu nhập ở hàng dưới. Nhãn giá trị theo Design/28. |
| Combo và Đội tự do + quà | Banner xanh đầy chiều ngang, thưởng cụ thể; gói bỏ quảng cáo ghi cả quyền lợi vĩnh viễn và quà một lần. |
| Tuần S/M/L/XL | Banner xanh ngọc cùng khung thẻ combo, tên kích cỡ rõ ràng, giới hạn 1 lần/tuần. XL chỉ có trong danh mục duyệt, không có trên Shop mẫu vì cờ đang tắt. |
| Tay đua | Chân dung lớn, bậc, tên, lối đua, tốc độ/kỹ thuật/thể lực từ dữ liệu. Hiển thị mảnh, gem và vé gear kèm theo. |
| Vĩnh viễn | Tên quyền lợi rõ, phạm vi áp dụng và quà đi kèm. Biến thể nâng ×2 → ×3 dùng SKU riêng. |
| Ngày | Hai thẻ song song, phân biệt vé gear Elite và vé tay đua All-Star. Mỗi gói 50 gem + 2 vé, giới hạn riêng. |
| Gem | Lưới hai cột để giá dài vẫn đọc được. Số gem gốc và tổng gem lần mua đầu hiển thị riêng. |
| Pass / Quỹ | Pass ghi 150 ngay + 30/ngày trong 30 ngày, trần offline +2 giờ, quà không cộng dồn. Quỹ liệt kê đủ 5 mốc và 100 gem ngay. |

Thứ tự Shop khi tích hợp theo Design/28 §5: quà ngày → ưu đãi → pass → tay đua → quyền lợi → gói ngày → gem → tiền. Bản mẫu tập trung các gói IAP; thẻ quảng cáo, đổi tiền bằng gem, pass mùa và các trang điều khoản không nằm trong phần thiết kế lần này.

## Popup và tương tác

Popup dùng chung: đầu màu theo nhóm với tiêu đề lợi ích + tên gói + nhãn; vùng hình minh họa lớn; danh sách thưởng từng dòng; giới hạn + tỉ lệ; ghi chú về thu nhập hoặc pass; nút giá; “Để sau”. Đóng bằng dấu ×, Để sau hoặc Escape.

Từ thẻ, bấm giá gọi thanh toán trực tiếp khi tích hợp; “Xem chi tiết” mở popup theo nhu cầu. Popup tự hiện chỉ dành cho Starter/offer theo hàng đợi sẵn có. Không thêm hộp xác nhận IAP sau nút giá.

Không thêm timer cho Starter/offer. Gói tuần chưa mua chỉ ghi lịch làm mới; đã mua mới hiện lịch mở lại. Lịch tuần thứ Hai 00:00 UTC tương ứng 07:00 ở Việt Nam/Thái Lan; bản chạy thật định dạng theo múi giờ người chơi.

“Xem tỉ lệ” mở bảng các gói coupon thực sự có trong SKU, lấy từ `driver_gacha.json` và `gear.json`. Tay đua bán đích danh phải phân biệt với coupon quay ngẫu nhiên.

## Trạng thái và ràng buộc tích hợp

| Trạng thái | Hiển thị / xử lý |
|---|---|
| Sẵn sàng | Giá do store trả về; dùng giá dự phòng nếu chưa có. |
| Đang xử lý | Khóa mọi nút IAP, giữ vị trí và kích thước nút. |
| Chờ thanh toán | Nhãn chờ, chưa báo đã nhận; phục hồi theo trạng thái đơn từ service. |
| Mất kết nối | Khóa nút mua, báo “Không có kết nối”; giữ nội dung gói. |
| Đã mua | Starter/offer/nhân vật một lần ẩn; quyền lợi ghi “Đã sở hữu”; gói ngày/tuần ghi thời điểm mở lại. |
| Pass còn hạn | Hiện số ngày còn lại; chỉ cho mua nối khi service cho phép. Quỹ đã mua chuyển sang nhận mốc. |
| Đã có tay đua | 40 mảnh thay tay đua + mảnh kèm theo: gói nhân vật là 70 mảnh, Starter là 40. Ghi rõ trước khi mua. Đạt cấp tối đa thì ẩn. |

UI Godot phải dựa trên trạng thái service và save hiện tại. Mockup là bảng duyệt riêng từng trạng thái, không mô phỏng toàn bộ bộ lọc điều kiện: tình huống “bậc 4” minh họa các họ thẻ, không đại diện một tài khoản có thật. Các ví dụ ngày còn lại và trạng thái đã mua là dữ liệu minh họa.

Ẩn `income_x2`/`income_x3` và chọn `income_x3_up` đúng quyền sở hữu. Khi `offer_noads_bundle` khả dụng, dùng nó thay thẻ `no_ads`. Chỉ hiện 1 Elite + 1 Legend theo rotation đủ điều kiện; kiểm tra cờ tuần XL. Khôi phục chỉ hiện nếu provider hỗ trợ.

## Điểm dữ liệu cần lưu ý

Lối đua trong `drivers.json` hiện khác tên lối đua trong bảng Design/28 (ví dụ My là `sweeper`, Quang là `inside`). Bản UI dùng dữ liệu hiện tại và dịch thành “Ôm cua rộng”, “Bám cua trong”; không tự sửa cân bằng hoặc danh mục.

## Kiểm tra bản thiết kế

Đã render toàn bộ 30 popup bằng Edge/Playwright; kiểm tra ảnh không thiếu, không lỗi JavaScript, trạng thái pending và đổi mảnh, bảng tỉ lệ, bố cục 320 px. Các ảnh xem trước nằm tại `Design/Previews/iap_packs_*.png`. Đây là kiểm tra mockup trình duyệt; chưa kiểm tra UI Godot hay giao dịch store.


## Mục tiêu thu hút của bản 2

- Tạo chú ý bằng tương phản, chân dung và phần thưởng lớn; tách 4 giây đọc đầu thành lợi ích → hình → phần thưởng → giá.
- Starter đầu giá thấp, tổng 150 gem + 6 vé hiện ngay trong banner; không dùng các lời hứa thắng chắc hoặc số sức mạnh tự tính.
- Nhân vật nhấn “Nhận tay đua chắc chắn”, đồng thời nêu rõ trường hợp đổi mảnh.
- Một nút mua chứa cả hành động và giá, luôn có lối đóng/để sau.
- Tiếp cận theo nhu cầu: gói khởi đầu ở đầu Shop, tay đua cạnh đội hình khi đủ điều kiện; không tăng tần suất popup ngoài luật hiện tại.

Đây là giả thuyết thiết kế, chưa có dữ liệu chứng minh tăng mua. Khi tích hợp, đo số người nhìn thấy thẻ → mở chi tiết → bấm mua → giao dịch thành công, cùng tỷ lệ đóng popup và lỗi thanh toán. So sánh A/B theo nhóm tiến trình với cùng nội dung pack và giá. Không kết luận chỉ từ lượt bấm mua.

CSS bản 2: `Design/Mockups/iap_packs_redesign.css`. Ảnh bản 2 dùng tiền tố `Design/Previews/iap_packs_v2_`; các ảnh không có `v2` là bản 1 để đối chiếu.
