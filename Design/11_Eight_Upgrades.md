# Hệ tám nâng cấp

> **Economy v2 — 10/11/2026:** [12 — BigNumber Economy](12_BigNumber_Economy.md) giữ tám mục và hiệu ứng nền dưới đây, thay giá, thang tiền, phần thưởng và thêm cơ sở theo từng bậc kinh doanh. Giới hạn 20 cấp áp dụng tại từng cơ sở; save v4/BigNumber nối tiếp migration v3 ở tài liệu này. Phần mô tả giá ×1,2 và thưởng cũ bên dưới là tham chiếu trước v2.

Thay thế phần nâng cấp Cơ sở và Huấn luyện trong thiết kế cũ. Garage gom đúng tám mục.

## Xe (bốn mục)

Động cơ / Speed, Lốp / Handling, Khung gầm / Stability, Hộp số / Acceleration.
Giữ công thức nền xe + 2 × cấp, giá và giới hạn cấp hiện có. Mua trong lúc đua áp dụng từ lượt sau.
Tay đua giữ kỹ năng nền cố định, không còn mua cấp huấn luyện. Mô phỏng vẫn dùng kỹ năng nền của tay đua.

## Doanh thu (bốn mục theo ảnh người dùng)

| Mục | Hiệu ứng |
| --- | --- |
| Ticket Marketing | Tiền vé/giây: 8 + 2,5 × cấp |
| Victory Celebrations | Tiền ăn mừng/giây: 7,5 × cấp |
| Parking | Tiền đỗ xe/giây: 12,5 × cấp |
| Grandstands | Sức chứa: 10 + 5 × cấp |

Ảnh xác định bốn loại và bước tăng. Công thức liên kết sức chứa là lựa chọn triển khai ban đầu: thu nhập/giây = (Ticket Marketing + Victory Celebrations + Parking) × (sức chứa / 10). Giữ mức khởi đầu 8/giây của prototype; không lấy cấp và giá cao trong ảnh làm mức khởi đầu.
Victory Celebrations là nguồn tiền mỗi giây theo ảnh, không phải thưởng thắng chặng.

Tất cả áp dụng ngay, kể cả đang đua. Offline dùng tổng doanh thu đã lưu × hệ số offline hiện có; thưởng chặng, thưởng mùa và quà ngày giữ nguyên.
Cấu hình trong data/economy.json: revenue_upgrades. Giá khởi đầu lần lượt 150 / 300 / 500 / 800, mỗi cấp ×1,2; tối đa 20 cấp như xe. Đây là cân bằng ban đầu, chưa hiệu chỉnh bằng playtest.

## Save v3

Giữ cấp bốn bộ phận xe. Cấp Cơ sở cũ chuyển sang Ticket Marketing; ba mục mới bắt đầu cấp 0. Hoàn tiền từng cấp huấn luyện đã mua theo giá cũ, bỏ cấp huấn luyện khỏi save mới. Sau khi ghi save v3, không hoàn lại lần nữa. Checkpoint cuộc đua đang dở giữ snapshot cũ đến khi kết thúc lượt đó.
