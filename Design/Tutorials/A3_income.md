# A3_income — Nguồn tiền

**Mục đích:** Tìm ô tiền mỗi giây, hiểu các yếu tố tác động, tự nâng doanh thu và quan sát số tăng ngay.

**Bắt đầu:** Sau tutorial `A2_car`.

**Hoàn thành:** Mua một lần nâng Ticket Marketing, thấy số tiền mỗi giây trước–sau và xác nhận kết quả.

**Nguồn chạy thật:** [data/tutorials/onboarding/income.json](../../data/tutorials/onboarding/income.json).

## Kịch bản

### Stage 0

**Nhịp 1:**

> Muốn chăm chút cho chiếc xe, đội cần có tiền đều đặn. Sếp nhìn ô thu nhập ở đây nhé: mình đang thu %s tiền mỗi giây, kể cả lúc chờ đua.

Khóa lời thoại: `tutorial.crowd_pays_cash_per_second`.

### Stage 1

**Nhịp 1:**

> Nhóm Doanh thu nằm ở đây, Sếp. Ticket Marketing, Victory Celebrations và Parking bổ sung tiền thu được; Grandstands nhân doanh thu.

**Nhịp 2:**

> Các mốc sao, cơ sở và boost thu nhập cũng tác động lên số tiền mỗi giây. Trước mắt, mình thử một nâng cấp để xem nhé.

Khóa lời thoại: `tutorial.income.sources`.

### Stage 2

**Nhịp 1:**

> Mình bắt đầu với Ticket Marketing nhé. Sếp bấm nút %s tiền này để nâng một lần, rồi cùng xem thu nhập thay đổi thế nào!

Khóa lời thoại: `tutorial.income.upgrade`.

### Stage 3

**Nhịp 1:**

> Sếp nhìn lại ô thu nhập nhé: %s → %s tiền mỗi giây! Nâng doanh thu có hiệu lực ngay, không cần chờ lượt đua sau.

**Nhịp 2:**

> Khoản tiền này giúp mình tiếp tục đầu tư cho chiếc xe. Giờ mình thử nâng Động cơ nhé!

Khóa lời thoại: `tutorial.income.increased`.

### Stage 4

**Nhịp 1:**

> Mình còn thiếu chút tiền để nâng Ticket Marketing. Chờ thu nhập tích thêm nhé, Sếp.

Khóa lời thoại: `tutorial.income.waiting`.

## Kiểm tra riêng

`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson=A3_income`

Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.

Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.

## Sửa và đồng bộ

Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.
