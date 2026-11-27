# Demo popup pack đồng bộ

Mở `index.html` bằng trình duyệt; HTML đã nhúng hình và font, không cần mạng hoặc server. Chỉ là demo thiết kế, chưa tích hợp Godot.

6 SKU trong ảnh tham chiếu: starter_1, weekly_s, offer_noads_bundle, income_x2, no_ads, char_my.

Bố cục chung: header xanh → minh họa → khối quyền lợi xanh nhạt → ô quà nền trắng → ghi chú → khu vực mua. Các popup có cùng chiều cao trên bảng đối chiếu, nút mua thẳng hàng. Bỏ ribbon nổi để tiêu đề có nhiều chỗ hơn; giữ màu kem, xanh, cam và artwork hiện có. Quyền lợi vĩnh viễn và nhân vật chắc chắn nhận được tách khỏi quà tặng. Gói ít quà dùng hàng rộng, không thêm ô giả.

Chức năng: so sánh 6 gói, chọn từng gói, khổ 320/390/412, hiện đường chia khối, mô phỏng chọn mua, đóng chế độ xem riêng và hộp thông tin tỉ lệ. Hộp tỉ lệ chỉ đánh dấu nơi tích hợp cấu hình thật; không đưa xác suất giả.

Giá, số lượng gem, vé, mảnh và giờ thu nhập được lấy từ data/iap.json khi build. Artwork trang trí không phải phần thưởng. Giữ tên gói My và tên tay đua Zielinski theo dữ liệu hiện tại. Nhân vật đã sở hữu đổi thành tổng 70 mảnh. Giá thật khi tích hợp lấy từ store.

Build lại: `python3 Design/Demos/PackPopupUnified/build_demo.py` từ thư mục gốc. template.html là nguồn giao diện, index.html là bản bàn giao tự chứa. Dùng lại asset trong assets/pack_promo_v1, assets/daily_gift_v3, assets/soft_miniature_ui_v1 và assets/reward_icons; không sinh hay sửa ảnh nguồn.

Đã kiểm bằng Chrome headless: đủ 6 popup, hình tải đủ, cùng chiều cao 723px trên bảng 1440px; không tràn ngang ở viewport 320/390/412. Đã kiểm nút mua mô phỏng, mở/đóng hộp thông tin, hiện khối và trở lại bảng so sánh. Chưa kiểm native Godot hoặc giao dịch store.

overview.png là bảng tổng quan; mobile_320.png, mobile_390.png, mobile_412.png là ảnh kiểm kích thước. Khổ chọn trong demo là chiều rộng màn hình tham chiếu; popup chừa lề 12px mỗi bên.
