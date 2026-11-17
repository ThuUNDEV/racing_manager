# Các tutorial độc lập

Mỗi tutorial có một file dữ liệu chạy thật và một bản kịch bản để đọc riêng. Bộ điều phối chọn thời điểm; overlay chỉ lo hiển thị và tương tác. ID cũ được giữ để tương thích save.

Tiến độ từng tutorial lưu riêng: chưa bắt đầu → đang chạy (stage, nhịp thoại) → hoàn thành. Vừa hiện lời thoại chưa được tính hoàn thành. Mở gói xong chuyển sang xác nhận, không chỉ nút mua tiếp. Với tutorial dạy một cơ chế, người chơi phải thực hiện thao tác thật và quan sát kết quả; bấm Tiếp chỉ chuyển lời thoại, không thay cho thao tác.

| ID | Tutorial | Mục đích |
|---|---|---|
| [A1_welcome](A1_welcome.md) | Nhận đội | Biết Linh là ai và mục tiêu cùng xây dựng đội đua. |
| [A2_car](A2_car.md) | Theo dõi cuộc đua | Nhận ra xe của đội, hiểu xe tự đua và biết xem hạng. |
| [A3_income](A3_income.md) | Nguồn tiền | Tìm ô tiền mỗi giây, hiểu các yếu tố tác động, tự nâng doanh thu và quan sát số tăng ngay. |
| [A4_engine](A4_engine.md) | Nâng Động cơ đầu tiên | Mua một cấp Động cơ và hiểu nâng cấp áp dụng từ lượt sau. |
| [A6_result](A6_result.md) | Kết quả cuộc đua | Phân biệt tiền thưởng lượt đua với cúp dành cho top 3. |
| [A7_race2](A7_race2.md) | Sức mạnh đội | Nhìn thấy nâng cấp được áp dụng và hiểu ý nghĩa Power. |
| [U2_league](U2_league.md) | Nâng cấp bằng cúp | Tự dùng cúp mua một nâng cấp tốc độ, xem chỉ số trước–sau và hiểu áp dụng từ lượt tiếp theo. |
| [U4_shop](U4_shop.md) | Mở phụ kiện đầu tiên | Dùng coupon mở đúng một gói và hiểu phụ kiện tăng Power cho đội. |
| [U3_bag](U3_bag.md) | Quản lý phụ kiện | Biết Túi giữ phụ kiện, đồ trùng thành mảnh và đủ mảnh thì nâng cấp. |
| [U5_drivers](U5_drivers.md) | Tuyển tay đua | Dùng coupon tuyển một tay đua và biết nơi xem, chọn người lái. |
| [U6_garage](U6_garage.md) | Chọn xe | Hiểu giá trị xe mới, nâng cấp riêng từng xe và nơi đổi diện mạo. |
| [U7_class](U7_class.md) | Chọn bộ môn | Hiểu mỗi bộ môn có chỉ số ưu tiên để định hướng đầu tư. |
| [C1_offline](C1_offline.md) | Thu nhập khi vắng mặt | Hiểu tỷ lệ và giới hạn thời gian tích lũy thu nhập offline. |
| [C2_trophy](C2_trophy.md) | Đủ cúp để đầu tư | Nhắc dùng số cúp đang đủ mua nâng cấp. |
| [C6_weaker](C6_weaker.md) | Tay đua mạnh hơn | Nhắc xem tay đua sở hữu có tổng chỉ số tốt hơn người đang lái. |
| [C5_shards](C5_shards.md) | Đủ mảnh nâng phụ kiện | Nhắc nâng đúng món phụ kiện đã đủ mảnh. |
| [C4_star](C4_star.md) | Mốc sao doanh thu | Hiểu lợi ích tăng doanh thu ở mốc cấp gần nhất. |

## Thứ tự và điều phối

Phần làm quen chạy theo thứ tự trong danh sách `onboarding` của `data/tutorial.json`. Các tutorial tính năng theo mốc 2/3/4/5/7/10 lượt. Mẹo chỉ hiện khi đúng tình huống. Mỗi lúc chỉ một tutorial chiếm callout.

Tutorial tính năng tự xuất hiện từ bất kỳ tab nào khi đủ điều kiện, sau khi đóng modal hoặc bảng kết quả. Bàn tay dẫn tới đúng tab; Garage có thêm bước Đội → Garage. Chỉ hoàn tất dẫn đường khi tới đúng nơi. Đọc mục đích rồi thì không lặp khi vào tab. Rời tutorial đang dở sẽ được dẫn trở lại, giữ nguyên tiến độ.

Cơ chế game (mua, trao quà, mô phỏng đua) vẫn dùng logic thật, không nằm trong kịch bản. Đổi phần thưởng hoặc điều kiện game cần kiểm tra logic tương ứng.

## Kiểm tra

`tutorial_lessons_test.gd` kiểm tra từng định nghĩa, chạy riêng, save giữa thao tác, save sau mở gói, không chi tiền lặp và tương thích save cũ. Các test tutorial hiện có vẫn kiểm tra luồng toàn game.
