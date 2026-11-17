# U5_drivers — Tuyển tay đua

**Mục đích:** Dùng coupon tuyển một tay đua và biết nơi xem, chọn người lái.

**Bắt đầu:** Sau 5 lượt hoàn tất, hướng dẫn ở `shop`.

**Hoàn thành:** Thực hiện thao tác được hướng dẫn thành công, rồi xác nhận kết quả; không yêu cầu mua thêm lần nữa.

**Nguồn chạy thật:** [data/tutorials/features/first_driver_pack.json](../../data/tutorials/features/first_driver_pack.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Chiếc xe đang tốt dần lên rồi. Tôi cũng muốn tìm thêm người cầm lái để đội có nhiều lựa chọn hơn.

**Nhịp 2:**

> Mỗi tay đua có chỉ số và kỹ năng riêng. Sếp dùng coupon mở Pro Pack ở đây nhé, xem ai sẽ về với đội mình!

Khóa lời thoại: `data.tutorial.every_driver_has_their_own`.

### Stage 1

**Nhịp 1:**

> Có kết quả rồi, Sếp! Vào tab Đội xem chỉ số và kỹ năng nhé. Mình chọn người phù hợp cho lượt sau, tôi lo chuẩn bị xe.

Khóa lời thoại: `data.tutorial.pick_new_driver_next_race`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U5_drivers`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
