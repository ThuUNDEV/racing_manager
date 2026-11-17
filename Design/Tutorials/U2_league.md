# U2_league — Nâng cấp bằng cúp

**Mục đích:** Tự dùng cúp mua một nâng cấp tốc độ, xem chỉ số trước–sau và hiểu áp dụng từ lượt tiếp theo.

**Bắt đầu:** Sau 2 lượt hoàn tất, hướng dẫn ở `league`. Chờ đủ cúp mua nâng cấp được hướng dẫn.

**Hoàn thành:** Thực hiện thao tác được hướng dẫn thành công, rồi xác nhận kết quả; không yêu cầu mua thêm lần nữa.

**Nguồn chạy thật:** [data/tutorials/features/trophy_upgrades.json](../../data/tutorials/features/trophy_upgrades.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Cúp là phần thưởng cho những lần về top 3. Mình có thể dùng chúng để cải thiện chỉ số của đội, bên cạnh nâng xe bằng tiền.

**Nhịp 2:**

> Thử nâng tốc độ nhé, Sếp. Bấm nút %d cúp này để mua một cấp.

Khóa lời thoại: `data.tutorial.finish_top_3_earn_trophies`.

### Stage 1

**Nhịp 1:**

> Xong rồi! Thưởng tốc độ từ nâng cấp này: +%d → +%d. Lượt đua sau đội sẽ dùng chỉ số mới.

Khóa lời thoại: `tutorial.trophy.upgraded`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=U2_league`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
