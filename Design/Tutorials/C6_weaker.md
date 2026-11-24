# C6_weaker — Tay đua mạnh hơn

**Mục đích:** Nhắc xem tay đua sở hữu có tổng chỉ số tốt hơn người đang lái.

**Bắt đầu:** Điều kiện `stronger_owned_driver`.

**Hoàn thành:** Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.

**Nguồn chạy thật:** [data/tutorials/tips/stronger_driver.json](../../data/tutorials/tips/stronger_driver.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Tôi vừa xem hồ sơ của %s. Tổng chỉ số tốt hơn người đang lái đấy, Sếp vào Đội cân nhắc thử nhé?

Khóa lời thoại: `tutorial.stronger_than_current_driver_pick`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=C6_weaker`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
