# A3_income — Nguồn tiền

**Mục đích:** Tìm ô tiền mỗi giây, hiểu các yếu tố tác động, tự nâng doanh thu và quan sát số tăng ngay.

**Bắt đầu:** Sau tutorial `A4_engine`.

**Hoàn thành:** Mua một lần nâng Ticket Marketing, thấy số tiền mỗi giây trước–sau và xác nhận kết quả.

**Nguồn chạy thật:** [data/tutorials/onboarding/income.json](../../data/tutorials/onboarding/income.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Có khán giả tới xem rồi, Sếp! Nhìn ô thu nhập này: đội đang thu %s tiền mỗi giây. Khoản này sẽ giúp mình có tiền chăm xe.

Khóa lời thoại: `tutorial.crowd_pays_cash_per_second`.

### Stage 1

**Nhịp 1:**

> Xe có thêm sức rồi. Muốn tiếp tục nâng, mình cần nguồn tiền đều đặn. Ticket Marketing, Victory Celebrations và Parking thêm tiền thu được; Grandstands nhân doanh thu.

**Nhịp 2:**

> Các mốc sao, cơ sở và boost cũng giúp tăng thu nhập. Trước mắt, mình thử nâng Ticket Marketing một lần nhé.

Khóa lời thoại: `tutorial.income.sources`.

### Stage 2

**Nhịp 1:**

> Mình bắt đầu với Ticket Marketing nhé. Giá nâng cấp là %s tiền — Sếp bấm ở đây, rồi cùng xem thu nhập tăng thế nào!

Khóa lời thoại: `tutorial.income.upgrade`.

### Stage 3

**Nhịp 1:**

> Sếp nhìn này: %s → %s tiền mỗi giây rồi! Nâng doanh thu có hiệu lực ngay.

**Nhịp 2:**

> Có thêm kinh phí để tiếp tục chăm xe rồi. Giờ mình cùng xem kết quả lượt đua nhé!

Khóa lời thoại: `tutorial.income.increased`.

### Stage 4

**Nhịp 1:**

> Còn thiếu một chút tiền để nâng Ticket Marketing thôi. Cứ để thu nhập tích thêm nhé, tôi kiểm tra xe trong lúc chờ.

Khóa lời thoại: `tutorial.income.waiting`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A3_income`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
