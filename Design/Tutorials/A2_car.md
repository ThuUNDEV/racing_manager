# A2_car — Theo dõi cuộc đua

**Mục đích:** Nhận ra xe của đội, hiểu xe tự đua và biết xem hạng.

**Bắt đầu:** Sau tutorial `A1_welcome`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/onboarding/race_view.json](../../data/tutorials/onboarding/race_view.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Xe mình đây, Sếp! Nhìn nó ra đường đua, tôi vẫn hồi hộp như lần đầu.

**Nhịp 2:**

> Tay đua sẽ tự thi đấu. Mình theo dõi hạng ở góc trên, rồi tính cách giúp xe chạy tốt hơn ở lượt sau nhé.

Khóa lời thoại: `tutorial.this_race_window_glowing_dot`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A2_car`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
