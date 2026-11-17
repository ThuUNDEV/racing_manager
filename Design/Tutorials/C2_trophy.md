# C2_trophy — Đủ cúp để đầu tư

**Mục đích:** Nhắc dùng số cúp đang đủ mua nâng cấp.

**Bắt đầu:** Điều kiện `trophy_upgrade_affordable`.

**Hoàn thành:** Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.

**Nguồn chạy thật:** [data/tutorials/tips/enough_trophies.json](../../data/tutorials/tips/enough_trophies.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Những lần lên bục đã có ích rồi, Sếp! Mình có %d cúp, đủ mua nâng cấp ở tab Giải. Vào chọn cho đội nhé.

Khóa lời thoại: `tutorial.you_have_trophies_enough_upgrade`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=C2_trophy`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
