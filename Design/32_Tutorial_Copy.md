# Kịch bản tutorial — Những vòng đua đầu tiên

Cập nhật 24/11/2026: bản chạy hiện đưa giải thích Power và nâng Động cơ lên trước Doanh thu. Sau khi mua, Linh chỉ thanh thông báo Power tăng, hiển thị số thật trước → sau và mức tăng màu xanh; thanh được giữ đến khi bấm Tiếp. Hướng dẫn nâng Power chỉ chạy một lần, không lặp ở lượt đua sau. Kịch bản chi tiết hiện hành: [Nâng Power đầu tiên](Tutorials/A4_engine.md), [Nguồn tiền](Tutorials/A3_income.md). Các đoạn bên dưới là bản thoại tham chiếu trước thay đổi thứ tự này.

Bản quản lý theo từng tutorial độc lập hiện ở [Design/Tutorials](Tutorials/README.md); mỗi phần có mục đích, điều kiện bắt đầu, kịch bản và điều kiện hoàn thành riêng.

Ngày 16/11/2026. **Đã đưa vào bản chạy thử tiếng Việt.**

Cốt truyện: Sếp vừa nhận việc quản lý một đội đua nhỏ. Linh phụ trách kỹ thuật, đặt hy vọng vào đội và cùng Sếp chăm chút chiếc xe qua từng lượt đua. Linh hồi hộp, vui khi có tiến bộ, động viên khi kết quả chưa tốt; mọi kết quả và phần thưởng lấy từ trạng thái thật.

Mỗi đoạn trích dưới đây là một nhịp thoại. Giải thích mục đích trước, rồi mới chỉ thao tác. Đoạn dài chờ bấm Tiếp; sau khi kể mục đích ở bước chỉ tab, không kể lại khi vào tab. Giữ nguyên mốc mở khóa và quà. Bản thử chỉ thay lời tiếng Việt.

## A. Những vòng đua đầu tiên

### Nhận đội

> Chào Sếp, tôi là Linh, phụ trách kỹ thuật. Đội mình còn nhỏ, nhưng tôi mong một ngày được thấy chiếc xe này lên bục nhận cúp.

> Mình có %s tiền để bắt đầu. Sếp lo hướng phát triển, tôi lo chiếc xe. Cùng thử sức nhé?

Khóa: `tutorial.hi_boss_our_team_has`.

### Ra đường đua

> Xe mình đây, Sếp! Nhìn nó ra đường đua, tôi vẫn hồi hộp như lần đầu.

> Tay đua sẽ tự thi đấu. Mình theo dõi hạng ở góc trên, rồi tính cách giúp xe chạy tốt hơn ở lượt sau nhé.

Khóa: `tutorial.this_race_window_glowing_dot`.

### Tiền nuôi đội

> Muốn chiếc xe tiến bộ, mình cần tiền để chăm chút cho nó. May là khán giả đang mang về %s tiền mỗi giây, kể cả lúc chờ đua.

> Mình dùng khoản này để nâng xe hoặc đầu tư thêm doanh thu. Cứ tích góp từng chút, đội sẽ có thêm cơ hội.

Khóa: `tutorial.crowd_pays_cash_per_second`.

### Quyết định đầu tiên

> Tôi muốn chiếc xe có thêm tốc độ để bám đuổi đối thủ. Nâng Động cơ là bước đầu tiên mình có thể làm cho nó.

> Sếp bấm nút %s tiền ở đây nhé. Để tôi chuẩn bị Động cơ mới!

Khóa: `tutorial.upgrade_engine_make_car_faster`.

### Sau khi nâng

> Xong rồi! Tôi cũng nóng lòng xem chiếc xe chạy thế nào. Động cơ mới sẽ được lắp từ lượt sau, mình chờ xe về nhé.

Khóa: `tutorial.car_already_racing_so_upgrade`.

### Chờ đủ tiền

> Mình còn thiếu chút tiền rồi, Sếp. Cứ để doanh thu tích thêm, tôi chờ được.

Khóa: `tutorial.need_more_cash_wait_moment`.

### Kết quả — top 3

> P%d! Được lên bục ngay lượt đầu, vui thật đấy Sếp! Đội nhận %s tiền thưởng rồi.

Khóa: `tutorial.finished_p_cash_prize_went`.

### Kết quả — ngoài top 3

> Mình về P%d, nhận %s tiền thưởng. Tôi vẫn muốn thấy chiếc xe tiến xa hơn. Lượt sau thử với Động cơ mới nhé, Sếp.

Khóa: `tutorial.finished_p_everyone_nervous_their`.

### Ý nghĩa phần thưởng

> Tiền thưởng giúp mình tiếp tục chăm chút cho đội. Còn mỗi lần về top 3, mình sẽ có thêm cúp để mua nâng cấp ở tab Giải.

Khóa: `tutorial.finish_top_3_earn_trophies`.

### Lượt tiếp theo

> Động cơ mới đã lắp xong! Power đội: %s → %s. Cùng xem công sức của mình trên đường đua nhé, Sếp!

Khóa: `tutorial.new_engine_car_team_power`.

### Hiểu Power

> Power là sức mạnh tổng hợp của đội. Chiếc xe, tay đua và phụ kiện đều góp phần vào đó.

> Mỗi lần cải thiện một phần, mình lại có thêm cơ hội cạnh tranh ở lượt sau.

Khóa: `tutorial.power_explained`.

### Sếp tiếp quản

> Nhìn chiếc xe ra đường đua lần nữa, tôi bắt đầu mong tới chiếc cúp đầu tiên của đội rồi.

> Sếp chọn hướng đi tiếp theo nhé. Tôi ở đây, có thêm lựa chọn mới sẽ báo Sếp ngay!

Khóa: `tutorial.from_now_you_run_things`.

## B. Từng bước xây dựng đội

### Lượt 2 — Giải

> Những chiếc cúp đội mang về còn giúp mình mạnh hơn. Có thêm một lý do để cố gắng lên bục, Sếp nhỉ?

> Sếp dùng cúp mua nâng cấp ở tab Giải này nhé. Khi đủ cúp, mình chọn thứ phù hợp với đội.

Khóa: `data.tutorial.finish_top_3_earn_trophies`.

### Lượt 3 — Phụ kiện

> Ngoài nâng xe, mình còn có thể bổ sung phụ kiện để tăng Power cho cả đội. Tôi muốn thử xem chúng giúp đội tiến bộ thế nào.

> Mình được tặng một coupon mở gói phụ kiện. Sếp bấm nút này nhé, lần mở này không tốn gem.

Khóa: `data.tutorial.gear_boosts_driver_stats_open`.

### Sau khi mở phụ kiện

> Có phụ kiện cho đội rồi, Sếp! Hiện chúng đang cộng thêm %s Power. Mỗi chút sức mạnh đều đáng quý lúc mới bắt đầu thế này.

Khóa: `data.tutorial.duplicates_turn_into_shards_with`.

### Lượt 4 — Túi

> Những món mình kiếm được vẫn còn nâng lên được nữa, Sếp. Tôi thích cảm giác tận dụng tốt những gì đội đang có.

> Túi giữ phụ kiện của đội. Mở trùng sẽ nhận mảnh của món đó; đủ mảnh thì nâng cấp để tăng thêm Power nhé.

Khóa: `data.tutorial.bag_holds_gear_upgrade`.

### Lượt 5 — Tay đua

> Chiếc xe đang tốt dần lên rồi. Tôi cũng muốn tìm thêm người cầm lái để đội có nhiều lựa chọn hơn.

> Mỗi tay đua có chỉ số và kỹ năng riêng. Sếp dùng coupon mở Pro Pack ở đây nhé, xem ai sẽ về với đội mình!

Khóa: `data.tutorial.every_driver_has_their_own`.

### Sau khi tuyển

> Có kết quả rồi, Sếp! Vào tab Đội xem chỉ số và kỹ năng nhé. Mình chọn người phù hợp cho lượt sau, tôi lo chuẩn bị xe.

Khóa: `data.tutorial.pick_new_driver_next_race`.

### Lượt 7 — Garage

> Sếp có nghĩ tới một chiếc xe khác cho đội chưa? Tôi cũng muốn xem mình có thể làm được gì với một chiếc xe tốt hơn.

> Xe mới có chỉ số nền cao hơn, nhưng mỗi xe cần nâng cấp riêng. Sếp xem giá và chỉ số trong Garage trước khi chọn nhé.

> Ở đây còn đổi được sơn và decal nữa. Khi nào Sếp muốn, mình làm cho chiếc xe mang dấu ấn riêng của đội!

Khóa: `data.tutorial.new_cars_have_higher_base`.

### Lượt 10 — Bộ môn

> Mình đã đi được một chặng rồi, Sếp. Giờ đội có thể tính xem muốn thử sức ở bộ môn nào.

> Mỗi bộ môn ưu tiên chỉ số khác nhau. Sếp bấm Class để xem nhé; chẳng hạn Rally cần Lốp và Khung gầm tốt.

Khóa: `data.tutorial.each_discipline_favors_different_stats`.

## C. Mẹo theo tình huống

### Trở lại sau khi offline

> Sếp quay lại rồi! Lúc Sếp vắng, đội vẫn thu được %d%% doanh thu, tối đa %d giờ. Mình có thêm tiền để tiếp tục chăm chút cho đội.

Khóa: `tutorial.while_you_re_away_team`.

### Đủ cúp

> Những lần lên bục đã có ích rồi, Sếp! Mình có %d cúp, đủ mua nâng cấp ở tab Giải. Vào chọn cho đội nhé.

Khóa: `tutorial.you_have_trophies_enough_upgrade`.

### Gần mốc doanh thu

> Sắp tới mốc tăng doanh thu rồi, Sếp! %s chỉ còn %d cấp nữa là đạt cấp %d; doanh thu mục này sẽ nhân %s lần.

Khóa: `tutorial.levels_away_from_level_earn`.

### Đủ mảnh

> Gom đủ mảnh của %s rồi, Sếp! Vào Túi nâng cấp để món này giúp đội mạnh hơn nhé.

Khóa: `tutorial.has_enough_shards_upgrade`.

### Tay đua mạnh hơn

> Tôi thấy %s có tổng chỉ số tốt hơn người đang lái. Sếp vào Đội xem thử nhé, biết đâu đây là thay đổi mình đang cần.

Khóa: `tutorial.stronger_than_current_driver_pick`.

## Chạy thử

Chạy `godot --path . -s res://tools/preview_tutorial_story.gd`. Bản thử dùng save riêng và bắt đầu lại ở lời chào của Linh.

Thêm `-- --capture` để chụp ảnh và kiểm tra bố cục tại 320, 390 và 412 px.

Các ký hiệu `%s`, `%d`, `%%` giữ theo bảng dịch và được chèn số liệu thật khi hiển thị. Số Power phụ kiện là tổng hiện tại, không phải mức tăng riêng của gói vừa mở.
