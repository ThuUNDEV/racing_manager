# A7_race2 — Sức mạnh đội

**Mục đích:** Nhìn thấy nâng cấp được áp dụng và hiểu ý nghĩa Power.

**Bắt đầu:** Sau tutorial `A6_result`. Chờ điều kiện `race_start`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/onboarding/team_power.json](../../data/tutorials/onboarding/team_power.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Động cơ mới đã lắp xong! Power đội: %s → %s. Cùng xem công sức của mình trên đường đua nhé, Sếp!

Khóa lời thoại: `tutorial.new_engine_car_team_power`.

### Stage 1

**Nhịp 1:**

> Power là sức mạnh tổng hợp của đội. Chiếc xe, tay đua và phụ kiện đều góp phần vào đó.

**Nhịp 2:**

> Mỗi lần cải thiện một phần, mình lại có thêm cơ hội cạnh tranh ở lượt sau.

Khóa lời thoại: `tutorial.power_explained`.

### Stage 2

**Nhịp 1:**

> Nhìn chiếc xe ra đường đua lần nữa, tôi bắt đầu mong tới chiếc cúp đầu tiên của đội rồi.

**Nhịp 2:**

> Sếp chọn hướng đi tiếp theo nhé. Tôi ở đây, có thêm lựa chọn mới sẽ báo Sếp ngay!

Khóa lời thoại: `tutorial.from_now_you_run_things`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A7_race2`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
