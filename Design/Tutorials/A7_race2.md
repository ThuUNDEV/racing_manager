# A7_race2 — Sếp tiếp quản

**Mục đích:** Kết thúc làm quen bằng lời dẫn theo thành tích; không lặp hướng dẫn nâng Power.

**Bắt đầu:** Sau tutorial `A6_result`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/onboarding/team_power.json](../../data/tutorials/onboarding/team_power.json).

## Kịch bản

Luồng hiện hành vào thẳng stage 2, chỉ lời kết. Stage 0/1 không chạy, kể cả khi tiếp tục save cũ, để không lặp hướng dẫn nâng Power. Không chờ lượt đua tiếp theo.

### Stage 0

**Nhịp 1:**

> Động cơ mới đã lắp xong! Power đội từ %s → %s. Tôi cũng nóng lòng xem lượt này lắm.

Khóa lời thoại: `tutorial.new_engine_car_team_power`.

### Stage 1

**Nhịp 1:**

> Sếp nhìn ô Power này nhé. Đây là sức mạnh tổng hợp của đội; xe, tay đua và phụ kiện đều góp phần vào đó.

**Nhịp 2:**

> Mình thử nâng Động cơ trước, rồi quay lại đây xem chỉ số thay đổi thế nào nhé!

Khóa lời thoại: `tutorial.power_explained`.

### Stage 2 — earned

**Nhịp 1:**

> Có cúp đầu tiên rồi, giờ tôi lại muốn có thêm chiếc nữa. Sếp chọn hướng đầu tư tiếp nhé!

**Nhịp 2:**

> Tôi lo chuẩn bị xe. Có thêm lựa chọn mới, tôi sẽ báo Sếp ngay!

Khóa lời thoại: `tutorial.story.already_has_trophy`.

### Stage 2 — other

**Nhịp 1:**

> Giờ Sếp thử chọn hướng đầu tư tiếp nhé. Tôi vẫn đang để trống một chỗ trong gara cho chiếc cúp đầu tiên đấy.

**Nhịp 2:**

> Tôi lo chuẩn bị xe. Có thêm lựa chọn mới, tôi sẽ báo Sếp ngay!

Khóa lời thoại: `tutorial.from_now_you_run_things`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A7_race2`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
