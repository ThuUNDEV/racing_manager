# Shop — tích hợp concept kem–cam

Ngày 2026-11-10. Màn Shop thật dùng `ui/shop_page.gd`, được ghép vào tab Shop của `ui/main.gd`.

## Bố cục

Một trang cuộn dọc: quà ngày → pass mùa/tháng/quỹ gem → combo và gói khởi động → ưu đãi đặc biệt → gói trang bị/tay đua và quà video → gem → tiền → tùy chọn âm thanh cũ. Header tài nguyên và thanh điều hướng bốn tab hiện tại luôn ở ngoài vùng cuộn. Shop ẩn avatar để header đủ chỗ trên màn nhỏ. Không khôi phục tab Garage riêng vì bản game hiện tại gộp quản lý đội trong tab Đội.

Art lấy từ `assets/workshop_gp/shop/`; banner không gắn chữ; khung/nút dùng 9-slice. Gem/tiền có ba cột ở chiều rộng thông thường, hai cột trên màn 320 px. Không dựng lại cây Shop khi tiền hoặc trạng thái game đổi, nên giữ vị trí cuộn/focus.

## Trạng thái tính năng

- Quà ngày gọi `GameState.claim_daily()`: tiền theo `Pricing.daily_gift(online_rate())`, gem đọc từ economy config. Đã nhận thì khóa nút; save bị chặn hoặc phase save_error thì chưa cho nhận. Kiểm tra ngày và giá trị thưởng cập nhật định kỳ theo UI.
- Pass, gói, gem mua, đổi tiền và quà video hiển thị “Sắp có”. Các nút mở bảng mô tả, không giao dịch/cộng tài nguyên. Không hiển thị bộ đếm giới hạn, số lượt video hoặc tiến độ pass giả.
- Giá, số lượng gói là dữ liệu trưng bày dự kiến của concept, không phải sản phẩm đã mở bán. Chưa thay luật economy, save, ads hoặc IAP.

## Xác minh

Godot 4.7.2: import và boot_test đạt. `tests/shop_ui_test.gd` kiểm tra thưởng ngày, chống nhận hai lần, khóa khi save bị chặn, mở bảng gói không đổi ví, độ rộng thẻ, số cột và giữ cuộn ở 320/390/412 px. Chạy thêm bằng renderer Vulkan Forward+ để lưu `Design/Previews/shop_*` và xem ảnh trực tiếp. Chưa thử trên điện thoại.

Các lần chạy UI và boot_test có cảnh báo tài nguyên/ObjectDB còn giữ lúc thoát; kiểm tra boot hiện có cũng tái hiện cảnh báo này. Chưa xử lý vòng đời tài nguyên chung trong phạm vi tích hợp Shop.
