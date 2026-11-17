# A4_engine — Nâng Động cơ đầu tiên

**Mục đích:** Mua một cấp Động cơ và hiểu nâng cấp áp dụng từ lượt sau.

**Bắt đầu:** Sau tutorial `A3_income`. Chờ điều kiện `engine_affordable`.

**Hoàn thành:** Động cơ đạt ít nhất cấp 1, rồi đọc và xác nhận câu sau nâng cấp.

**Nguồn chạy thật:** [data/tutorials/onboarding/engine_upgrade.json](../../data/tutorials/onboarding/engine_upgrade.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Tôi muốn chiếc xe có thêm tốc độ để bám đuổi đối thủ. Nâng Động cơ là bước đầu tiên mình có thể làm cho nó.

**Nhịp 2:**

> Sếp bấm nút %s tiền ở đây nhé. Để tôi chuẩn bị Động cơ mới!

Khóa lời thoại: `tutorial.upgrade_engine_make_car_faster`.

### Stage 1

**Nhịp 1:**

> Xong rồi! Tôi cũng nóng lòng xem chiếc xe chạy thế nào. Động cơ mới sẽ được lắp từ lượt sau, mình chờ xe về nhé.

Khóa lời thoại: `tutorial.car_already_racing_so_upgrade`.

### Stage 2

**Nhịp 1:**

> Mình còn thiếu chút tiền rồi, Sếp. Cứ để doanh thu tích thêm, tôi chờ được.

Khóa lời thoại: `tutorial.need_more_cash_wait_moment`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A4_engine`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
