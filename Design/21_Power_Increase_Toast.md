# Thông báo tăng Power — đề xuất thiết kế

Ngày: 12/11/2026. Đã tích hợp banner vào Godot theo yêu cầu sau khi duyệt demo. Tham chiếu: ảnh người dùng cung cấp; giữ cấu trúc icon đội → tổng Power → mũi tên và mức tăng, không có nhãn “Power đội”. Các mục dưới mô tả thiết kế; trạng thái triển khai và kiểm tra thực tế ở cuối tài liệu.

## Bố cục

Banner navy nằm giữa theo chiều ngang, cách đáy HUD đua 12 px. Giữ nguyên HUD thường trực gồm sức mạnh hiện tại, vị trí và thời gian đua; banner chỉ là lớp thông báo tạm thời phía dưới, không thay HUD. Không đặt theo tọa độ toàn màn khi tích hợp. Màn 390: rộng 310, cao 62; màn 320: rộng 256, cao 62. Không làm tối nền hoặc chặn thao tác bên dưới.

| Thành phần | Thiết kế |
|---|---|
| Nền | Navy #102B4F gần đặc, viền #79A4ED 1,5 px, bo 15, bóng nhẹ bên dưới |
| Icon | Hai người nét trắng trong ô xanh 40 × 40, bo 11; khớp ý nghĩa icon đội đang có trong HUD |
| Tổng mới | Chỉ hiện số trắng đậm 25 px, màn 320 dùng 22 px; căn giữa theo chiều dọc với icon và mức tăng |
| Phần tăng | Hai chevron hướng lên + dấu cộng + delta, #55EB97, 24 px; màn 320 dùng 21 px |
| Khoảng cách | Padding 12 ngang / 9 dọc; gap 12; không có nút đóng |

Ví dụ trong demo đã cập nhật: 460,4 → 468,6; banner hiển thị **468,6 ↑ +8,2** và sức mạnh trên HUD cũng cập nhật thành 468,6. Tổng là giá trị sau thay đổi; delta tính trên giá trị gốc chưa rút gọn. Dùng dấu phẩy thập phân để khớp `RaceView.format_team_power()` hiện có. Số trong prototype chỉ minh họa.

## Hành vi đề xuất

- Khi một thao tác hợp lệ đã áp dụng và `team_power()` tăng ít nhất 0,1: hiện banner. Theo nguồn hiện tại, Power là tổng 4 chỉ số xe và 7 chỉ số tay đua trong `GameState.player_stats()`; không thêm công thức mới.
- Nguồn tăng có thể gồm nâng bộ phận, nâng tay đua hoặc đổi đội hình mạnh hơn, nhưng luôn so tổng thực tế trước/sau. Không suy ra tăng Power từ giá mua, độ hiếm hoặc số trang bị nhận được. Giao dịch thất bại, giảm hoặc giữ nguyên Power không phát banner này.
- Vào game, load save và cập nhật HUD lần đầu chỉ khởi tạo mốc, không phát thông báo tăng giả. Chuỗi cập nhật trong cùng giao dịch gom thành một kết quả sau khi giao dịch kết thúc; không đọc dữ liệu giữa chừng.
- Fade + trượt lên 8 px + scale 0,96 → 1 trong 220 ms; giữ 1.600 ms; ẩn trong 180 ms. Tổng khoảng 2 giây theo yêu cầu người dùng. Đề xuất số tổng chạy từ cũ đến mới trong 300 ms khi tích hợp; prototype hiện đổi số ngay.
- Nếu tăng tiếp trong lúc hiện: giữ mốc trước lần tăng đầu, cập nhật tổng mới và cộng dồn delta, khởi động lại thời gian giữ; chỉ một banner. Sau khi bắt đầu ẩn, lần tăng tiếp mở phiên mới. Không phát hàng đợi dài khi nâng nhanh.
- Không có âm riêng mặc định, dùng phản hồi nâng cấp hiện có. Giảm chuyển động: chỉ fade, đổi số trực tiếp. Dấu cộng và mũi tên giúp nhận biết mà không phụ thuộc màu.
- Khi mở modal/kết quả che vùng đua: giữ một bản tổng hợp chờ, hiển thị sau khi đóng nếu vẫn trong phiên thao tác; xóa khi rời phiên hoặc load lại. Đây là quy tắc đề xuất khi tích hợp, chưa mô phỏng trong HTML.

## Số dài và kích thước nhỏ

Giữ một hàng; rút gọn tổng và delta cùng quy ước K/M/B… nếu vượt chỗ, tối đa khoảng 6 ký tự mỗi số. Chưa dùng formatter BigNumber của tiền cho Power float mà không có chuyển đổi rõ ràng; khi tích hợp cần mở rộng formatter Power hiện chỉ hỗ trợ K. Không hiện `+0,0` cho tăng dương do làm tròn. Màn 320 giữ icon, giảm gap xuống 8 nếu cần; không thu toàn bộ banner. Nếu thiết bị thay cỡ chữ hệ thống lớn, cho phép banner cao hơn để delta xuống hàng thứ hai.

## Bàn giao

- `Design/Mockups/power_increase.html`: bản xem trước có nút phát hiệu ứng, tăng tiếp để xem cộng dồn; ảnh nền cập nhật theo ảnh người dùng gửi, lưu tại `Design/Mockups/layout_review_assets/power_race_context.png`. HUD sức mạnh có lớp số cập nhật theo demo; vị trí/thời gian là nội dung ảnh tĩnh.
- `Design/Previews/power_increase_390.png` và `power_increase_320.png`: vị trí trên giao diện hiện tại.
- `Design/Previews/power_increase_board.png`: bảng giới thiệu thiết kế.

Chữ, icon vector và số là các lớp UI riêng trong prototype. Không cần sinh ảnh chứa chữ để dựng Godot. Khi tích hợp: một Control overlay trong vùng đua, `mouse_filter = IGNORE`; dùng Tween cho thời gian, nhận sự kiện sau thay đổi dữ liệu thay vì so HUD đã format. Chưa thay đổi gameplay, save hay scene.

Kiểm tra prototype: viewport 320/360/390/412 không tràn ngang hoặc tràn nội dung banner, ảnh tải đủ; tăng liên tiếp cho delta +24,6, tự ẩn và phát lại đều đúng, không có lỗi JavaScript. Đã xem ảnh render ở 390 và 320. Ảnh game phía dưới là screenshot co theo khung, không chứng minh layout Godot ở các kích thước này; màn prototype tối đa rộng 390. Chưa kiểm tra Godot hoặc thiết bị.

## Triển khai Godot — 12/11/2026

- `ui/power_increase_banner.gd`: Control con của RaceView, dưới HUD 12 px; icon vector, số và chevron vẽ riêng. Không nhận input. Fade/trượt trong 220 ms, fade-out 180 ms, tổng 2 giây theo delta frame thật, độc lập tốc độ mô phỏng đua. Không có nhãn chữ hoặc âm riêng.
- `ui/main.gd`: theo dõi `team_power()` trong refresh sau `GameState.changed`, khởi tạo mốc trong lúc chuẩn bị loading. Giao dịch lưu thất bại không phát sự kiện tăng; nâng doanh thu và mua trang bị không tăng Power thực không phát thông báo giả. HUD được redraw khi dữ liệu đổi.
- Một banner cộng dồn khi tăng tiếp trong thời gian giữ; lần tăng khi đã fade-out bắt đầu chuỗi mới. Giảm Power xóa banner cũ. Tạm ẩn/chờ khi modal, hồ sơ, kết quả hoặc tab ẩn đường đua; hiển thị lại một bản tổng hợp khi vùng đua xuất hiện.
- `RaceView.format_team_power()` dùng chung cho HUD/banner, hỗ trợ K/M/B/T…; số HUD tự giảm cỡ khi cần để không bị cắt trên màn 320. Không thay gameplay, công thức Power, snapshot đua hay schema save.
- Những đề xuất chưa triển khai: count-up số, scale-in, tùy chọn giảm chuyển động/cỡ chữ hệ thống và reflow hai hàng. Hiện số đổi ngay, animation dùng fade + trượt; chữ co trong banner một hàng khi số dài.

Kiểm tra: `tests/power_banner_test.gd` chạy headless và renderer native Compatibility đều qua, gồm giao dịch nâng engine thực, HUD đồng bộ, không phát khi mua thất bại, cộng dồn, giảm Power, pending và tắt sau 2 giây. Test dùng save riêng `power_banner_test.*`, không reset save người chơi. Đã render 320/390/412 và xem ảnh 320/390 tại `Design/Previews/power_banner_native_*.png`; HUD vẫn hiển thị phía trên banner. Có cảnh báo RID/ObjectDB khi thoát UI harness; không có lỗi script. Chưa chạy thiết bị/mobile hoặc toàn bộ suite. Đã thêm test mới vào hai script chạy test chuẩn.
