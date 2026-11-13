# UI các gói ưu đãi

Ngày: 13/11/2026. Trạng thái: bản thiết kế để duyệt, chưa tích hợp Godot.

## Nguồn và bản xem

- Nội dung, giá dự phòng, giới hạn và SKU: `data/iap.json` (30 SKU).
- Luật hiển thị và popup: `Design/28_IAP_Packs.md`.
- Chân dung, chỉ số và lối đua: `data/drivers.json`; hình dùng atlas hiện có.
- Mở `Design/Mockups/iap_packs.html` bằng trình duyệt. Chọn gói ở cột phải, chọn tình huống Shop và trạng thái giao dịch ở thanh trên. Trên điện thoại, bấm “Xem chi tiết gói” để mở popup.
- Chạy `python Design/Mockups/build_iap_mockup.py` để cập nhật dữ liệu sau khi sửa JSON. Chỉnh bố cục tại `iap_packs.template.html` rồi chạy lại lệnh trên.

Mockup chỉ mô phỏng UI, không gọi IAP và không ghi save. Giá đang dùng `price_fallback`; khi tích hợp phải lấy `Iap.price(sku)`.

## Hướng hình ảnh

Giữ ngôn ngữ Workshop GP: tiêu đề xanh dương, chữ xanh đậm, thẻ kem viền cam, nút mua xanh lá nổi khối, nút đóng đỏ tròn. Tay đua dùng thẻ tím; quyền lợi và pass dùng nền xanh nhạt. Giữ chân dung và icon đã có để đồng bộ với Đội, Túi và Shop.

Mỗi thẻ có tên gói, nhãn giá trị/giới hạn, toàn bộ phần thưởng, giá, liên kết chi tiết và “Xem tỉ lệ” nếu có coupon. Không hiển thị giá cũ gạch ngang hoặc phần trăm giảm khi cấu hình chưa có cơ sở so sánh.

Mốc thiết kế: màn hình 390 px, khoảng lề 12 px, khoảng cách 8–12 px, bo thẻ 17 px. Nút mua ít nhất 44 px; popup có nút mua 50 px. Ở 320 px, nội dung cuộn dọc và không tràn ngang. Popup cao tối đa vùng màn hình, cuộn nội dung khi nhiều phần thưởng; không thu nhỏ chữ để ép tất cả vào một màn hình.

## Bộ mẫu

| Nhóm | Cách trình bày |
|---|---|
| Starter 1–3 | Một thẻ đang mở, dải bước 1 · 2 · 3. Gói 2/3 có chân dung Hà/My; gem, vé và thu nhập ở hàng dưới. Nhãn giá trị theo Design/28. |
| Combo và Đội tự do + quà | Thẻ cam đầy chiều ngang, thưởng cụ thể; gói bỏ quảng cáo ghi cả quyền lợi vĩnh viễn và quà một lần. |
| Tuần S/M/L/XL | Cùng khung thẻ combo, tên kích cỡ rõ ràng, giới hạn 1 lần/tuần. XL chỉ có trong danh mục duyệt, không có trên Shop mẫu vì cờ đang tắt. |
| Tay đua | Chân dung lớn, bậc, tên, lối đua, tốc độ/kỹ thuật/thể lực từ dữ liệu. Hiển thị mảnh, gem và vé gear kèm theo. |
| Vĩnh viễn | Tên quyền lợi rõ, phạm vi áp dụng và quà đi kèm. Biến thể nâng ×2 → ×3 dùng SKU riêng. |
| Ngày | Hai thẻ song song, phân biệt vé gear Elite và vé tay đua All-Star. Mỗi gói 50 gem + 2 vé, giới hạn riêng. |
| Gem | Lưới hai cột để giá dài vẫn đọc được. Số gem gốc và tổng gem lần mua đầu hiển thị riêng. |
| Pass / Quỹ | Pass ghi 150 ngay + 30/ngày trong 30 ngày, trần offline +2 giờ, quà không cộng dồn. Quỹ liệt kê đủ 5 mốc và 100 gem ngay. |

Thứ tự Shop khi tích hợp theo Design/28 §5: quà ngày → ưu đãi → pass → tay đua → quyền lợi → gói ngày → gem → tiền. Bản mẫu tập trung các gói IAP; thẻ quảng cáo, đổi tiền bằng gem, pass mùa và các trang điều khoản không nằm trong phần thiết kế lần này.

## Popup và tương tác

Popup dùng chung: đầu xanh có tên + nhãn gói; vùng hình minh họa; danh sách thưởng từng dòng; giới hạn + tỉ lệ; ghi chú về thu nhập hoặc pass; nút giá; “Để sau”. Đóng bằng dấu ×, Để sau hoặc Escape.

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
