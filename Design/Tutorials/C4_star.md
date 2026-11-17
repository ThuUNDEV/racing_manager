# C4_star — Mốc sao doanh thu

**Mục đích:** Hiểu lợi ích tăng doanh thu ở mốc cấp gần nhất.

**Bắt đầu:** Điều kiện `near_revenue_milestone`.

**Hoàn thành:** Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.

**Nguồn chạy thật:** [data/tutorials/tips/revenue_milestone.json](../../data/tutorials/tips/revenue_milestone.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Sắp tới mốc tăng doanh thu rồi, Sếp! %s chỉ còn %d cấp nữa là đạt cấp %d; doanh thu mục này sẽ nhân %s lần.

Khóa lời thoại: `tutorial.levels_away_from_level_earn`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=C4_star`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
