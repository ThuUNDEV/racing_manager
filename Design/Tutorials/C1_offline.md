# C1_offline — Thu nhập khi vắng mặt

**Mục đích:** Hiểu tỷ lệ và giới hạn thời gian tích lũy thu nhập offline.

**Bắt đầu:** Điều kiện `offline_report_closed`.

**Hoàn thành:** Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.

**Nguồn chạy thật:** [data/tutorials/tips/offline_income.json](../../data/tutorials/tips/offline_income.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Sếp về rồi! Trong lúc Sếp vắng, đội vẫn tích được %d%% doanh thu, tối đa %d giờ. Vào xem mình làm được gì tiếp nhé?

Khóa lời thoại: `tutorial.while_you_re_away_team`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=C1_offline`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
