# A6_result — Kết quả cuộc đua

**Mục đích:** Phân biệt tiền thưởng lượt đua với cúp dành cho top 3.

**Bắt đầu:** Sau tutorial `A4_engine`. Chờ điều kiện `race_result`.

**Hoàn thành:** Đọc hai phần kết quả và phần thưởng, rồi đóng bảng kết quả.

**Nguồn chạy thật:** [data/tutorials/onboarding/race_result.json](../../data/tutorials/onboarding/race_result.json).

## Kịch bản

### Stage 0 — top3

**Nhịp 1:**

> P%d! Được lên bục ngay lượt đầu, vui thật đấy Sếp! Đội nhận %s tiền thưởng rồi.

Khóa lời thoại: `tutorial.finished_p_cash_prize_went`.

### Stage 0 — other

**Nhịp 1:**

> Mình về P%d, nhận %s tiền thưởng. Tôi vẫn muốn thấy chiếc xe tiến xa hơn. Lượt sau thử với Động cơ mới nhé, Sếp.

Khóa lời thoại: `tutorial.finished_p_everyone_nervous_their`.

### Stage 1

**Nhịp 1:**

> Tiền thưởng giúp mình tiếp tục chăm chút cho đội. Còn mỗi lần về top 3, mình sẽ có thêm cúp để mua nâng cấp ở tab Giải.

Khóa lời thoại: `tutorial.finish_top_3_earn_trophies`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A6_result`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
