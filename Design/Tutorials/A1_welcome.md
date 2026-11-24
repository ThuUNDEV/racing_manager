# A1_welcome — Nhận đội

**Mục đích:** Biết Linh là ai và mục tiêu cùng xây dựng đội đua.

**Bắt đầu:** Điều kiện `new_game`.

**Hoàn thành:** Đọc và xác nhận hết các nhịp thoại.

**Nguồn chạy thật:** [data/tutorials/onboarding/welcome.json](../../data/tutorials/onboarding/welcome.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Sếp tới rồi! Tôi là Linh, lo phần kỹ thuật cho đội. Gara hơi chật, xe cũng còn nhiều thứ phải sửa… nhưng cuối cùng mình đã được ra đua.

**Nhịp 2:**

> Đội còn %s tiền để bắt đầu. Sếp tính chuyện phát triển, tôi lo chuẩn bị xe. Cùng đưa đội tiến xa nhé?

Khóa lời thoại: `tutorial.hi_boss_our_team_has`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A1_welcome`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
