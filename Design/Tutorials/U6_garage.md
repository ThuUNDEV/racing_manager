# U6_garage — Chọn xe

**Mục đích:** Hiểu giá trị xe mới, nâng cấp riêng từng xe và nơi đổi diện mạo.

**Bắt đầu:** Sau 7 lượt hoàn tất, hướng dẫn ở `garage`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/features/garage.json](../../data/tutorials/features/garage.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Sếp có nghĩ tới một chiếc xe khác cho đội chưa? Tôi cũng muốn xem mình có thể làm được gì với một chiếc xe tốt hơn.

**Nhịp 2:**

> Xe mới có chỉ số nền cao hơn, nhưng mỗi xe cần nâng cấp riêng. Sếp xem giá và chỉ số trong Garage trước khi chọn nhé.

**Nhịp 3:**

> Ở đây còn đổi được sơn và decal nữa. Khi nào Sếp muốn, mình làm cho chiếc xe mang dấu ấn riêng của đội!

Khóa lời thoại: `data.tutorial.new_cars_have_higher_base`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U6_garage`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
