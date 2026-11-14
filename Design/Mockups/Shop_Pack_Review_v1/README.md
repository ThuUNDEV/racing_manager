# Shop — bộ minh họa duyệt thiết kế 01

Ngày: 13/11/2026. Phạm vi: thiết kế tham chiếu, chưa ghép vào game.

Mở `index.html` trực tiếp bằng trình duyệt. File chứa sẵn hình ảnh, không cần mạng hay máy chủ. Chọn nhóm, chọn khổ 320/390/412 px, mở chi tiết từng pack. Chọn “Đồng ý thiết kế” hoặc “Cần chỉnh sửa”, nhập ghi chú và bấm “Tải kết quả duyệt”. Các ghi chú chỉ lưu trên trình duyệt đang dùng, không gửi đi đâu. Nếu trình duyệt chặn lưu khi mở file cục bộ, tải kết quả trước khi đóng trang.

## Phạm vi đủ 38 thẻ

| Bảng | Nhóm | Số mẫu |
|---|---|---:|
| 01 | Khởi đầu (3), ưu đãi (3) | 6 |
| 02 | Tay đua Lâm, My, Nhân, Phương, Quang, Sơn | 6 |
| 03 | Bỏ quảng cáo, ×2, ×3, nâng ×2→×3, Offline+ | 5 |
| 04 | Pass tháng, quỹ gem, tuần S/M/L/XL | 6 |
| 05 | Hai gói ngày, năm gói gem | 7 |
| 06 | Quà hôm nay, quà đăng nhập, ba quà video, ba đổi tiền | 8 |

`weekly_xl` có mẫu để duyệt nhưng vẫn tắt theo `weekly_xl_enabled=false`. Các gói bị khóa theo tiến trình, biến thể nâng cấp và gói đã mua được cùng đưa vào bảng đối chiếu; không có nghĩa chúng đồng thời xuất hiện trong Shop thật.

## Tài liệu và ảnh

- `boards/`: 6 bảng PNG độ phân giải 2×, có số tham chiếu và SKU.
- `cards/`: 38 ảnh thẻ riêng.
- `popups/`: 38 ảnh popup mô phỏng và một ảnh My đã sở hữu.
- `mobile/`: ảnh ở 320/390/412 px cho nhóm nổi bật, tay đua, tài nguyên và popup.
- `catalog_coverage.csv`: đối chiếu 30 SKU và 8 thẻ phụ.
- `source_snapshot.json`: danh mục IAP và quảng cáo tại thời điểm dựng.
- `verification.json`: kết quả kiểm tra bản xem bằng trình duyệt.

## Quy chuẩn triển khai sau khi duyệt

- Nền trang xanh rất nhạt `#eaf1f7`, thẻ trắng, chữ chính navy `#173455`, chữ phụ `#677f98`.
- Viền thẻ 1 px; bo 17 px; bóng nhẹ phía dưới. Viền xanh/tím/vàng/xanh ngọc theo recipe của nhóm. Không dùng khung kim loại dày.
- Padding thẻ 12–14 px. Tiêu đề 20–24 px; nội dung 12–14 px. Chữ giải thích nhỏ có thể 11 px, nhưng không dùng làm nội dung thưởng chính.
- Nút mua cao 46 px, chữ trắng đậm 20 px; nút gem hẹp dùng 16 px. Vùng chạm tương tác khi tích hợp tối thiểu 44 px, kể cả liên kết chi tiết và tỉ lệ.
- Thẻ khởi đầu/offer/tuần: tiêu đề → minh họa ngang → ô quà → ghi chú → giá → chi tiết. Hình giữ tỉ lệ, cắt trong khung, không kéo méo. Xe và người dẫn trong cảnh chỉ là minh họa nếu không có trong grant.
- Tay đua: chân dung bên trái, tên và bậc bên phải; quà tách ô phía dưới. Tay đua chắc chắn khác vé mở ngẫu nhiên. Không tự đổi mặt, màu đồng phục hoặc bậc nhân vật theo ảnh AI mới.
- Quyền lợi: chỉ rõ online/thưởng đua hoặc offline. Các hệ số thu nhập online dùng hệ số lớn hơn với boost quảng cáo, không nhân chồng; offline có quyền lợi riêng.
- Pass tháng: 150 gem ngay, 30 gem/ngày ×30 ngày, trần offline +2 giờ. Tổng tối đa 1.050 gem với điều kiện nhận đủ; ngày bỏ lỡ không cộng dồn.
- Quỹ: 100 gem ngay và đủ 5 mốc 200/300/400/500/1.000; tổng 2.500 gem. Không trình bày như thu nhập lặp vĩnh viễn.
- Gem: lưới hai cột trên mobile. Ghi riêng số cơ bản và tổng nhận lần đầu, thưởng ×2 riêng từng SKU. Bảng duyệt phóng to từng thẻ; chế độ mobile mới là tham chiếu mật độ.
- Gói ngày xếp dọc trong bản xem để giữ phần thưởng và giá dễ đọc. Thẻ miễn phí dùng nút nhận hoặc xem video theo quyền lợi thực tế.
- Nút giá trên thẻ thật gọi luồng mua hiện có. “Xem chi tiết” mở popup. Mẫu duyệt này cố ý chỉ mở popup, không mua.
- Popup có nút đóng; nội dung dài cuộn bên trong. Khi tích hợp, giữ giá và nút mua dễ tiếp cận, không để cuộn làm kích hoạt mua.
- Popup coupon có “Xem tỉ lệ mở vé”, lấy xác suất và bảo đảm từ `data/driver_gacha.json` / `data/gear.json` tại thời điểm dựng. Khi triển khai tiếp tục lấy dữ liệu động, không viết cứng theo ảnh mẫu.
- Đã sở hữu nhân vật: thay bằng 40 mảnh cộng mảnh kèm (gói nhân vật là 70 mảnh; Starter có tay đua là 40). Giữ gem/vé/tiền còn lại.
- Trạng thái giao dịch phải lấy từ service: sẵn sàng, xử lý, chờ thanh toán, mất kết nối, đã mua, hết lượt. Mẫu có trình diễn trạng thái; không thay thế quy tắc service.
- Gói một lần ẩn sau khi mua; quyền lợi giữ nhãn đã sở hữu; gói ngày/tuần hiện mốc mua lại thật. Không thêm timer hoặc nhãn giảm giá không có căn cứ.
- Giữ giá/thưởng/điều kiện/save hiện có. Giá trên mẫu là `price_fallback`; runtime dùng giá store. Không chép giá hay phần thưởng vào ảnh.
- Đổi tiền hiện vẫn “Sắp có”. Các số 4,08B / 16,3B / 32,6B và 10/30/50 gem là mẫu từ code Shop hiện tại, chưa phải cam kết cân bằng kinh tế.

## Nguồn asset

Dùng lại hình có trong `assets/iap_offers/manifest.json` (texture, vùng atlas, recipe, foreground), `assets/racing_ui_hd/` và `assets/racing_ui_hd_expansion/`. Không sửa pixel PNG hay file game. Layout/giá/thưởng là phần giao diện riêng, không nằm trong art. `source_snapshot.json` lưu hash danh mục để biết khi nào mẫu đã lệch dữ liệu mới.

Đã kiểm bản xem trên trình duyệt ở 320/390/412 px, 38 thẻ, popup và chuyển trạng thái. Đây là kiểm tra bản thiết kế HTML, chưa phải render Godot hoặc kiểm thử chạm trên điện thoại.
