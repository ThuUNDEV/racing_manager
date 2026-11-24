# A6_result — Kết quả cuộc đua

**Mục đích:** Phân biệt tiền thưởng lượt đua với cúp dành cho top 3.

**Bắt đầu:** Sau tutorial `A3_income`. Chờ điều kiện `race_result`.

**Hoàn thành:** Đọc hai phần kết quả và phần thưởng, rồi đóng bảng kết quả.

**Nguồn chạy thật:** [data/tutorials/onboarding/race_result.json](../../data/tutorials/onboarding/race_result.json).

## Kịch bản

### Stage 0 — winner

**Nhịp 1:**

> P%d! Sếp thấy không, xe mình về đầu rồi! Để tôi lấy chỗ cất chiếc cúp đầu tiên! Mình nhận thêm %s tiền thưởng nữa.

Khóa lời thoại: `tutorial.story.first_win`.

### Stage 0 — top3

**Nhịp 1:**

> P%d! Đội mình được lên bục rồi, Sếp! Chiếc cúp đầu tiên… tôi muốn đặt nó ngay cửa gara. Mình nhận thêm %s tiền thưởng nữa!

Khóa lời thoại: `tutorial.finished_p_cash_prize_went`.

### Stage 0 — other

**Nhịp 1:**

> P%d, nhận được %s tiền thưởng rồi. Chưa lên bục lần này, nhưng xe về là mình có việc để làm tiếp.

Khóa lời thoại: `tutorial.finished_p_everyone_nervous_their`.

### Stage 1

**Nhịp 1:**

> Tiền thưởng để dành đầu tư tiếp nhé. Về top 3 còn có cúp; sau này mình dùng cúp mua thêm nâng cấp ở tab Giải.

Khóa lời thoại: `tutorial.finish_top_3_earn_trophies`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A6_result`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
