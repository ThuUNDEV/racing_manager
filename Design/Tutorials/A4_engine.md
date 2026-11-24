# A4_engine — Nâng Power đầu tiên

**Mục đích:** Hiểu Power, nâng Động cơ, xem Power trên HUD tăng ngay và hiểu hiệu quả đua áp dụng từ lượt sau.

**Bắt đầu:** Sau tutorial `A2_car`. Chờ điều kiện `engine_affordable`.

**Hoàn thành:** Động cơ đạt ít nhất cấp 1, rồi đọc và xác nhận câu sau nâng cấp.

**Nguồn chạy thật:** [data/tutorials/onboarding/engine_upgrade.json](../../data/tutorials/onboarding/engine_upgrade.json).

## Kịch bản

Luồng mới: stage 4 (giải thích Power) → stage 0 (mua Động cơ thật) → stage 3 (chỉ thanh thông báo Power tăng, so sánh trước–sau và mức tăng màu xanh) → stage 1 (hiệu quả từ lượt sau). Thanh Power được giữ đến khi bấm Tiếp. Stage 2 chỉ nhắc khi thiếu tiền. Sau đó chuyển sang Doanh thu; giữ số stage cũ để tương thích save.

### Stage 0

**Nhịp 1:**

> Tôi muốn thử cho xe thêm sức ở những đoạn tăng tốc. Mình bắt đầu từ Động cơ nhé?

**Nhịp 2:**

> Cần %s tiền cho lần nâng này. Sếp bấm ở đây, tôi chuẩn bị đồ!

Khóa lời thoại: `tutorial.upgrade_engine_make_car_faster`.

### Stage 1

**Nhịp 1:**

> Xong phần chuẩn bị rồi! Xe đang đua nên chưa lắp ngay được. Đợi nó về gara, lượt sau mình thử động cơ mới.

Khóa lời thoại: `tutorial.car_already_racing_so_upgrade`.

### Stage 2

**Nhịp 1:**

> Còn thiếu chút tiền thôi. Cứ để doanh thu tích thêm nhé, tôi kiểm tra xe trong lúc chờ.

Khóa lời thoại: `tutorial.need_more_cash_wait_moment`.

### Stage 3

**Nhịp 1:**

> Sếp nhìn thanh Power này: %s → %s rồi! Phần màu xanh bên phải là sức mạnh vừa tăng từ lần nâng Động cơ đấy.

Khóa lời thoại: `tutorial.power.increased`.

### Stage 4

**Nhịp 1:**

> Sếp nhìn ô Power này nhé. Đây là sức mạnh tổng hợp của đội; xe, tay đua và phụ kiện đều góp phần vào đó.

**Nhịp 2:**

> Mình thử nâng Động cơ trước, rồi quay lại đây xem chỉ số thay đổi thế nào nhé!

Khóa lời thoại: `tutorial.power_explained`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A4_engine`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
