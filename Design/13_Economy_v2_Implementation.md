# Economy v2 — Biên bản triển khai

Ngày: 10/11/2026. Đã triển khai trong Godot 4.7.2 theo [thiết kế 12](12_BigNumber_Economy.md). Đây là xác nhận chức năng và kiểm thử, chưa phải xác nhận cân bằng bằng playtest.

## Những gì đã có

- `core/math/big_number.gd`: decimal 24 chữ số có nghĩa, exponent tách riêng, tính trên chuỗi chữ số; không ép toàn bộ tiền qua int64/float64. Các phép toán không sửa đối tượng đầu vào. Hậu tố `K/M/B/T/AA/AB…AZ/BA…ZZ`, rồi scientific; hỗ trợ cả số mũ rất lớn ngoài phạm vi nội dung.
- `Pricing`, `Balance`, `GameState`: BigNumber xuyên suốt ví, tám nâng cấp, giá xe, tuyển tay đua, online/offline, quà ngày, thưởng chặng và mùa. Có snapshot rate/phần thưởng tại xuất phát. Gem/SP vẫn là số nguyên.
- Sáu bậc kinh doanh với S/Q của thiết kế; bốn nguồn doanh thu có cấp riêng tại mỗi cơ sở; cấp xe lưu theo từng xe. Đủ điểm mở quyền vào giải, đủ cấp doanh thu/xe/coins mới mở cơ sở. Lệnh giữa race chờ đến ranh giới lượt; cơ sở cũ và mùa dở được lưu lịch sử, không cộng doanh thu cũ.
- Luồng mua/chọn 15 xe, tuyển/chọn 12 tay đua; chi phí tuyển ban đầu `600 × 5^tier_driver × Q(entry_tier) × S(entry_tier)`, entry_tier theo điều kiện mở trong danh mục. Mỗi người cần SP tăng theo thứ tự tuyển. Portrait chưa có dùng hình An làm fallback; chưa bổ sung art mới.
- Save v4 và `MoneyCodec`: canonical significand string + exponent; bảo toàn token số nguyên cũ trước JSON parse, kể cả >2^53. Migration v2 hoàn training theo giá lịch sử, v3 giữ tám cấp và số dư; race/mùa cũ đang dở giữ thưởng legacy cho phần chuyển tiếp. Không reset save thật khi chạy test.
- Mua/quà/offline lỗi ghi thì rollback; thưởng kết quả chỉ publish sau commit, retry hoặc phục hồi checkpoint không phát trùng. Backup hợp lệ không bị ghi đè bởi primary hỏng. Boot/save mới hơn vẫn khóa ghi.
- UI dùng cùng formatter cho số dư, rate, giá, thiếu tiền, thưởng và offline. Tooltip cho giá trị khoa học; nút mua tự cập nhật khi đủ tiền, không cần chờ kết thúc race. Tên dài wrap trong hàng nâng cấp.

## Điểm cần đọc cùng thiết kế

UI hiện có tốc độ đua cố định ×4. Triển khai giữ lựa chọn này; `reward_duration` snapshot bằng `simulation_duration / time_scale`, nên thưởng dùng **thời gian thực của chu kỳ** cộng countdown 3s. Không trả gấp bốn lần coins/giờ vì chạy sim nhanh. Thời lượng track vẫn tính từ cấu hình vòng/track hiện có. Mô hình tài chính của thiết kế 12 dùng chu kỳ giả định 33/63/93s ở ×1; không được xem là đo thời gian retention của runtime ×4.

BigNumber dùng chuỗi chữ số thay phương án ba limb ban đầu để đơn giản hóa kiểm chứng. Save/API và độ chính xác 24 chữ số giữ như đặc tả. Sai số dưới độ phân giải ở ví cực lớn là đánh đổi đã nêu trong thiết kế; ID giao dịch/cấp/điểm vẫn chính xác.

Mỗi giải hiện vẫn chạy Circuit B có hình học. Chưa đưa lịch 10 track có art riêng vào vòng chơi. Không thay thuật toán điều khiển xe hay bộ golden chuyển động; tăng độ khó theo nền giải hiện có. Chưa triển khai ads/IAP, cloud, remote-config transport, mở rộng cap offline bằng gem hoặc bộ nhiệm vụ mới.

## Kiểm chứng

Lệnh: `./tools/run_tests.ps1` hoặc `./tools/run_tests.sh`. Chín bộ test đạt: `big_number_test`, `economy_test`, `data_test`, `golden_test`, `sim_test`, `traffic_test`, `state_test`, `upgrade_test`, `boot_test`.

- BigNumber có 240 ca đối chiếu Python Decimal 24 chữ số/half-even, cùng ca carry/borrow, ties/sticky, 1e300×1e300, giới hạn exponent, hậu tố và round-trip. Tái tạo fixture: `python tools/generate_big_number_oracle.py`.
- Kiểm tra giao dịch fail/retry, phần thưởng chưa commit, kill/reload từ checkpoint kết thúc, legacy integer 9.007.199.254.740.993, lưu ví 1e300, FPS 30/60/120, ownership/cấp xe, SP, cả năm lần mở bậc và ngăn mua trùng.
- Golden của RaceSim/TrafficSim và bộ chống treo/đặc tính hiện có đạt. Đây là hồi quy mô phỏng, không chứng minh mọi build thắng được hoặc nhịp economy đã cân bằng.
- Đã render giao diện Godot bằng OpenGL tại 443×960 và xem ảnh Garage/Giải với tiền AB, cùng hậu tố BA. Công cụ: `godot --path . --rendering-method gl_compatibility -s res://tests/economy_preview.gd`; save của công cụ cũng được cô lập.
- `boot_test` có cảnh báo ObjectDB RefCounted khi thoát harness bất đồng bộ (khoảng 64–66 đối tượng tùy lượt chạy); các assertion đều đạt. Chưa xác minh nguyên nhân cảnh báo. Lượt render preview và các test economy/BigNumber không phát cảnh báo đó.

Ảnh: [Garage](../docs/screenshots/economy_v2/tab_2.png), [Giải](../docs/screenshots/economy_v2/tab_3.png), [hậu tố BA](../docs/screenshots/economy_v2/suffix_BA.png).

Chưa kiểm tra trên Android/iOS, chưa playtest nhịp thắng–thua ở sáu giải và chưa mô phỏng đầy đủ SP/tuyển, collection, lịch chơi offline hoặc cap mở rộng. Các hệ số là điểm xuất phát để hiệu chỉnh.
