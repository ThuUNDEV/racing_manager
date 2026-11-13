# 20. Layout hồ sơ người chơi

**Luật đổi tên đã triển khai:** Lần đổi tên đầu tiên miễn phí, từ lần thứ hai tốn **50 gem/lần** (config `team_rename_gems`). Popup ghi rõ chi phí và số gem đang có trước khi xác nhận. Save v11 lưu `team_name_changes`; trừ gem, cập nhật tên và số lần đổi trong cùng một lần ghi save thành công. Giữ nguyên tên hiện tại không tính lượt hay trừ gem. Thiếu gem/lỗi ghi không thay đổi tên, gem hoặc lượt miễn phí. Save cũ có tên tùy chỉnh được tính đã dùng lượt miễn phí, tên mặc định vẫn giữ lượt đó. Quy tắc này thay thế các mô tả đổi tên miễn phí ở bản thiết kế ban đầu bên dưới.

**Cập nhật theo yêu cầu mới:** Hồ sơ hiện là popup giữa màn hình, nền game tối phía sau. Rộng tối đa 390, cao tối đa 720 logical px; chừa lề ngang 16 và lề dọc tối thiểu 32. Header có nút × và Cài đặt; footer có nút Đóng. Chỉ phần nội dung cuộn. Các mô tả toàn màn ở bản thiết kế ban đầu bên dưới là lịch sử trước thay đổi này. Test profile và render native ở 320/360/390/412 px đã đạt sau khi chuyển popup.

Ngày 12/11/2026. **Đã tích hợp Godot theo yêu cầu sau khi xem demo.** Phần thiết kế ban đầu bên dưới được giữ làm tham chiếu; trạng thái triển khai thực tế xem mục cuối.

Mockup: [player_profile.html](Mockups/player_profile.html). Mở bằng trình duyệt; selector phía trên cho xem hồ sơ có tiến trình, người chơi mới và tên dài. Sửa tên hoạt động trong trang xem thử, không ghi save.

## Mục tiêu và lối vào

Chạm avatar trên HUD để mở hồ sơ toàn màn, phủ trang hiện tại. Đóng bằng mũi tên hoặc “Trở lại game” để về đúng trang trước đó. Không thêm tab điều hướng. Bánh răng mở bảng Cài đặt hiện có; sau khi đóng Cài đặt trở lại hồ sơ. Cuộc đua tiếp tục theo cơ chế hiện tại; hồ sơ không cung cấp thao tác thay đổi cuộc đua.

Hồ sơ thể hiện danh tính và tiến trình của người chơi, tách khỏi trang chi tiết tay đua. Không dùng chỉ số Launch/Speed hay portrait của tay đua làm thông tin người chơi.

## Bố cục

Chuẩn 390 × 844 logical px, lề 16, khoảng cách 10–16, vùng chạm ít nhất 44. Nền xanh nhạt #E7F0FF, chữ #16355C, panel trắng xanh, thẻ danh tính xanh đậm, nút quay lại màu cam theo Racing UI HD.

| Thứ tự | Nội dung | Quy cách |
|---|---|---|
| 1 | Header cố định | Mũi tên đóng 44, tiêu đề Hồ sơ người chơi, bánh răng 44; cao khoảng 68 |
| 2 | Thẻ danh tính | Avatar 80, tên đội tối đa 2 dòng với tên tiếng Việt thông thường, huy hiệu giải hiện tại; hàng dưới có Sửa tên đội |
| 3 | Hành trình đua | Hai thẻ ngang: lượt đã hoàn tất và mùa hoàn tất; số lớn 23, nhãn 12 |
| 4 | Bộ sưu tập | Ba hàng Xe đua, Tay đua, Trang bị; số sở hữu/tổng catalog và thanh tiến độ |
| 5 | Đội hình đang dùng | Hai thẻ bằng nhau, ảnh 64, nhãn Tay đua/Xe đua và tên đang chọn |
| 6 | Dữ liệu | Thông tin dữ liệu trên thiết bị, chưa hỗ trợ đồng bộ tài khoản |
| 7 | Footer cố định | Trở lại game, cao 48, lề dưới theo safe area |

Khối 2–6 nằm trong một vùng cuộn. Không ghim HUD tài nguyên, đường đua hay nav đáy bên trong hồ sơ. Màn thấp 320 × 568: lề 12, avatar 64, header thu còn 60; vẫn giữ cỡ chữ và nút, cuộn để xem hết nội dung. Màn rộng: khung dọc tối đa 470; dùng safe area do thiết bị cung cấp khi dựng Godot. Ảnh preview không bao gồm notch hệ điều hành.

## Dữ liệu và phạm vi triển khai sau duyệt

Đối chiếu `game/game_state.gd`, `data/cars.json`, `data/drivers.json`, `data/gear.json`, `data/leagues.json` ngày 12/11/2026.

| Thành phần | Nguồn / yêu cầu |
|---|---|
| Tên đội, avatar người chơi | Chưa có trường profile trong save. Tên mặc định “Đội của bạn”; bổ sung trường và migration khi được yêu cầu tích hợp. Avatar tái dùng `icons/avatar.png`; chưa có bộ chọn avatar |
| Giải hiện tại | `business_tier` tra tên giải trong catalog; không dùng nhãn thành tích hoặc cấp tài khoản |
| Lượt đã hoàn tất | Cần bộ đếm bền vững tăng sau khi kết quả được ghi thành công; `race_counter` hiện không được coi là thống kê lịch sử đã hoàn tất. Save cũ thiếu lịch sử: hiện “—” + “Bắt đầu ghi nhận từ bản cập nhật”, không gán 0 hay suy đoán từ mùa |
| Mùa hoàn tất | `completed_seasons` |
| Bộ sưu tập | Đếm ID hợp lệ, duy nhất trong `owned_cars`, `owned_drivers`, `gear_owned`; tổng từ catalog, không đếm mảnh trùng. Hiện source có 15 xe, 12 tay đua, 30 gear; không hardcode khi tích hợp |
| Đội hình | `active_driver_id`, `active_car_id`; tên và ảnh từ catalog/resource, không lấy snapshot đội hình của lượt đang chạy |
| Trạng thái dữ liệu | Khối thông tin về lưu trên thiết bị, không phải chỉ báo save vừa thành công. Khi `save_blocked`/lỗi ghi: đổi sang thông báo lỗi thực tế và đường dẫn tới xử lý lưu hiện có |

Các số 128 lượt, 24 mùa, 6/15 xe, 4/12 tay đua, 18/30 trang bị trong mockup chỉ là dữ liệu minh họa. Hình xe là icon bố cục, không phải art chính xác của Pico. Chưa có ID tài khoản/server, đăng nhập, cờ quốc gia, cấp XP, win rate hay hệ thống danh hiệu trong layout này.

## Tương tác và trạng thái

- **Sửa tên đội:** dialog tiêu đề, input, Hủy và Lưu tên. Đề xuất giới hạn 24 ký tự hiển thị, trim khoảng trắng đầu/cuối, không nhận tên rỗng; giữ dấu tiếng Việt. Khi tích hợp cần đếm ký tự Unicode hiển thị, hỗ trợ bàn phím và báo lỗi ghi save; chỉ đóng dialog sau khi lưu thành công. Đổi tên không tốn tiền theo đề xuất này.
- **Người chơi mới:** tên mặc định, lượt/mùa 0 sau khi hệ thống đếm được khởi tạo, một xe và một tay đua khởi đầu, trang bị 0. Không ẩn mục chưa có tiến trình.
- **Tên dài:** xuống dòng, tăng cao thẻ; chuỗi liền không khoảng trắng vẫn ngắt an toàn. Không thu nhỏ toàn màn.
- **Thiếu ảnh hoặc ID cũ không hợp lệ:** ảnh placeholder cùng kích thước; nhãn “Chưa chọn” khi không có đối tượng hợp lệ. Không làm hỏng phần thống kê.
- **Đóng dialog:** Hủy/Escape trở lại hồ sơ, focus về Sửa tên. Khi mở giữ focus trong dialog; trên mobile cuộn input lên trên bàn phím.
- **Bộ sưu tập/đội hình:** chỉ xem trong phiên bản này; tránh tạo nút dẫn sang trang khác làm mất ngữ cảnh.

## Asset và bàn giao

Tái dùng `assets/racing_ui_hd/icons/{avatar,gear,flag,trophy,car_red,staff,tools}.png`; portrait An dùng ảnh hiện có trong mockup. Không cần tạo art mới để duyệt layout. Chữ, số, thanh tiến độ đều là UI riêng.

HTML là prototype độc lập, nút đóng và Cài đặt giải thích điểm nối bằng toast; không kết nối game. Đã có đặc tả các điểm nối để thực hiện sau khi layout được duyệt. Kiểm tra HTML ở 320/360/390/412 px và tương tác dialog; kiểm tra Godot/native/device thuộc bước tích hợp sau này.

Kết quả kiểm tra: 12 tổ hợp (4 kích thước × 3 trạng thái) không tràn ngang, không lỗi ảnh, footer nằm trong màn hình. Dialog từ chối tên rỗng và cập nhật tên hợp lệ trong mockup. Đã xem ảnh render hồ sơ và dialog ở 390 px; ảnh bàn giao trong `Design/Previews/player_profile_*.png`. Chưa kiểm tra bàn phím thiết bị hoặc runtime Godot.

## Tích hợp Godot — 12/11/2026

- `ui/player_profile.gd`: màn phủ toàn trang, header/footer cố định, nội dung cuộn bằng touch-scroll hiện có; giữ bố cục và màu demo. Dùng portrait và art xe thực tế của game thay ảnh minh họa HTML.
- `ui/main.gd`: avatar là nút mở hồ sơ; Cài đặt phủ trên hồ sơ, đóng để trở lại hồ sơ; cuộc đua tiếp tục nền, không đổi tab hiện tại.
- Save v8: bổ sung `player_team_name`, `completed_races`, `race_history_complete`. Tên mặc định “Đội của bạn”, đổi tên miễn phí và chỉ công bố sau khi ghi save thành công. Đếm tối đa 24 grapheme Unicode để hỗ trợ dấu tiếng Việt dạng tổ hợp.
- Lượt hoàn tất tăng cùng giao dịch kết quả; lỗi ghi và thử lại không cộng trùng. Save cũ thiếu lịch sử bắt đầu đếm từ 0, nhãn **Lượt từ cập nhật**, không suy diễn lịch sử. Mùa hoàn tất vẫn lấy dữ liệu hiện có.
- Bộ sưu tập đếm theo catalog và dữ liệu sở hữu, đội hình dùng ID đang chọn. Thiếu ảnh có icon dự phòng. Khối dữ liệu hiển thị lỗi khi save bị khóa hoặc kết quả đang chờ ghi lại.
- `tests/player_profile_test.gd` kiểm tra lưu/reload, migration, lỗi ghi, tên tiếng Việt, tên dài, giao dịch lượt hoàn tất, điều hướng và kích thước 320×568/360×800/390×844/412×915. Mọi file save kiểm thử nằm trong `user://tests/`, không dùng save người chơi.
- Test profile, state và boot đạt; đã chạy profile bằng renderer OpenGL native và lưu ảnh `Design/Previews/profile_native_*.png`. Log thoát vẫn có cảnh báo tài nguyên/RID chưa được giải phóng (cũng xuất hiện ở boot test); chưa kiểm tra thiết bị di động hoặc bàn phím ảo.
