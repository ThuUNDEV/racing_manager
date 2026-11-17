# U4_shop — Mở phụ kiện đầu tiên

**Mục đích:** Dùng coupon mở đúng một gói và hiểu phụ kiện tăng Power cho đội.

**Bắt đầu:** Sau 3 lượt hoàn tất, hướng dẫn ở `shop`.

**Hoàn thành:** Thực hiện thao tác được hướng dẫn thành công, rồi xác nhận kết quả; không yêu cầu mua thêm lần nữa.

**Nguồn chạy thật:** [data/tutorials/features/first_gear_pack.json](../../data/tutorials/features/first_gear_pack.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Ngoài nâng xe, mình còn có thể bổ sung phụ kiện để tăng Power cho cả đội. Tôi muốn thử xem chúng giúp đội tiến bộ thế nào.

**Nhịp 2:**

> Mình được tặng một coupon mở gói phụ kiện. Sếp bấm nút này nhé, lần mở này không tốn gem.

Khóa lời thoại: `data.tutorial.gear_boosts_driver_stats_open`.

### Stage 1

**Nhịp 1:**

> Có phụ kiện cho đội rồi, Sếp! Hiện chúng đang cộng thêm %s Power. Mỗi chút sức mạnh đều đáng quý lúc mới bắt đầu thế này.

Khóa lời thoại: `data.tutorial.duplicates_turn_into_shards_with`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U4_shop`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
