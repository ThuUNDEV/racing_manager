# C5_shards — Đủ mảnh nâng phụ kiện

**Mục đích:** Nhắc nâng đúng món phụ kiện đã đủ mảnh.

**Bắt đầu:** Điều kiện `gear_upgrade_affordable`.

**Hoàn thành:** Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.

**Nguồn chạy thật:** [data/tutorials/tips/gear_shards.json](../../data/tutorials/tips/gear_shards.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Gom đủ mảnh của %s rồi! Sếp vào Túi nâng cấp nhé, món này còn giúp đội được nữa.

Khóa lời thoại: `tutorial.has_enough_shards_upgrade`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=C5_shards`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
