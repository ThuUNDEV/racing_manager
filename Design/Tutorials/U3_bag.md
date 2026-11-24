# U3_bag — Quản lý phụ kiện

**Mục đích:** Biết Túi giữ phụ kiện, đồ trùng thành mảnh và đủ mảnh thì nâng cấp.

**Bắt đầu:** Sau 4 lượt hoàn tất, hướng dẫn ở `bag`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/features/gear_bag.json](../../data/tutorials/features/gear_bag.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Phụ kiện của đội được giữ trong Túi này nhé, Sếp. Lúc nào muốn kiểm tra đồ đang có, mình vào đây.

**Nhịp 2:**

> Nếu mở trùng một món, mình nhận mảnh của món đó. Gom đủ mảnh là nâng cấp được — tôi thích tận dụng những gì đội đã có.

Khóa lời thoại: `data.tutorial.bag_holds_gear_upgrade`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U3_bag`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
