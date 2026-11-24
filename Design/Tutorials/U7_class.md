# U7_class — Chọn bộ môn

**Mục đích:** Hiểu mỗi bộ môn có chỉ số ưu tiên để định hướng đầu tư.

**Bắt đầu:** Sau 10 lượt hoàn tất, hướng dẫn ở `race`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/features/race_classes.json](../../data/tutorials/features/race_classes.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Đi cùng nhau được một chặng rồi, Sếp nhỉ. Giờ mình có thể tính xem đội muốn theo bộ môn nào.

**Nhịp 2:**

> Mỗi bộ môn cần thế mạnh khác nhau. Sếp mở Class xem thử nhé — chọn hướng rồi, mình sẽ biết nên đầu tư vào đâu.

Khóa lời thoại: `data.tutorial.each_discipline_favors_different_stats`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U7_class`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
