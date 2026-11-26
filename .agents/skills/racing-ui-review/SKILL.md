---
name: racing-ui-review
description: "So sánh UI đã setup trong Racing Manager với demo hoặc concept đã duyệt, phát hiện sai khác và sửa để khớp khi được yêu cầu. Dùng khi review độ giống demo, kiểm tra implementation UI hoặc yêu cầu setup đúng ảnh mẫu."
---

# Racing UI Review

Lấy demo người dùng chỉ định làm chuẩn để kiểm tra UI runtime. Mục tiêu là implementation giống demo về bố cục và mỹ thuật, đồng thời giữ đúng dữ liệu và tương tác của game. Không tự diễn giải lại thiết kế theo sở thích.

## Xác định chuẩn đối chiếu

- Đọc AGENTS.md và CLAUDE.md ở gốc dự án; kiểm tra git diff để giữ các thay đổi đang có.
- Dùng demo/ảnh người dùng chỉ định. Nếu chưa chỉ định, tìm concept tương ứng trong Design/Demos/SoftMiniature/approved/ và tài liệu liên quan. Nếu có nhiều bản không rõ bản chuẩn, hỏi người dùng chọn trước khi kết luận hoặc sửa theo ảnh.
- Mở và xem ảnh thật; không chỉ đọc tên file hoặc prompt. Đọc Design/34_Layer_Layout_Spec.md và code UI liên quan. Nếu đặc tả và demo mâu thuẫn, ghi rõ; yêu cầu trực tiếp mới nhất của người dùng có ưu tiên. Không tự đổi giá, phần thưởng hoặc điều kiện game để giống chữ trong ảnh.
- Chốt phạm vi màn hình/popup, phiên bản demo, kích thước tham chiếu, ngôn ngữ và trạng thái game. Ghi lại đường dẫn ảnh chuẩn trong kết quả.

## Thu thập UI đã setup

- Đọc code dựng node trong ui/, theme/helper và manifest asset liên quan. Kiểm tra container, anchor, size flags, minimum size, stretch, clipping, thứ tự layer và scale texture để truy nguyên sai lệch.
- Chạy theo quy trình an toàn trong CLAUDE.md: cô lập save; mặc định headless cho kiểm tra cấu trúc. Cửa sổ thật phải dùng CLI với --screen 1, --audio-driver Dummy và XDG_DATA_HOME tạm. Không dùng game_run không-headless vì không truyền được các cờ màn hình/âm thanh; nếu dùng MCP headless, phải có --economy-test. Không chạy --reset.
- Ưu tiên harness preview/test sẵn có. Đặt đúng tab, popup, ngôn ngữ, dữ liệu và trạng thái như demo; chờ layout ổn định trước khi lấy kích thước hoặc chụp.
- Lấy cây node/kích thước thực và chụp nội dung viewport game. Ảnh editor không thay thế ảnh runtime. Lưu bằng chứng vào Design/Previews/<ten-review>/, tách ảnh chuẩn và ảnh runtime bằng tên rõ ràng.
- Headless dump node chỉ chứng minh cấu trúc. Nếu renderer không tạo được ảnh hợp lệ, ghi rõ giới hạn; không dùng ảnh đen/trống để đánh giá mỹ thuật.

## So sánh với demo

Đầu tiên so ở cùng kích thước và tỷ lệ khung hình với demo. Phân biệt pixel vật lý với đơn vị logical theo cấu hình hiện tại; không so trực tiếp tọa độ 886x1920 với 390x845. Có thể chuẩn hóa kích thước ảnh bằng scale đồng nhất; không kéo méo hoặc crop che phần sai lệch.

Kiểm tra theo từng vùng từ trên xuống dưới:

- Bố cục: vị trí, kích thước, tỷ lệ các khối, lề, khoảng cách, căn hàng, padding, vùng cuộn và phần nội dung nhìn thấy.
- Hình ảnh: đúng sprite, crop, tỷ lệ icon, texture, nền, màu, gradient, viền, bo góc, bóng, độ trong và thứ tự chồng lớp.
- Typography: font, cỡ, độ đậm, màu, căn lề, xuống dòng, chiều cao dòng và khoảng cách chữ với icon/nút.
- Nội dung và trạng thái: thứ tự phần tử, nhãn, giá, phần thưởng, badge, selected/disabled/locked và nội dung popup. Phân biệt dữ liệu động khác với lỗi dựng UI.
- Tương tác: hit area có trùng nút nhìn thấy, lớp phủ có chặn đúng input, popup mở/đóng và cuộn hoạt động đúng. Không hy sinh tương tác hoặc vùng chạm tối thiểu để khớp ảnh.

Hiển thị ảnh demo và runtime cạnh nhau khi báo cáo; dùng overlay/diff nếu công cụ hiện có hỗ trợ. Ghi sai lệch bằng vùng ảnh, tọa độ/kích thước logical hoặc giá trị đo được khi có thể. Không đặt điểm giống phần trăm nếu chưa có phương pháp đo rõ ràng; pixel diff chỉ là bằng chứng hỗ trợ vì font rendering và anti-aliasing có thể khác.

Sau khi đối chiếu kích thước chuẩn, kiểm tra thích ứng ở chiều rộng logical 320/390/412 và overflow ở 8 ngôn ngữ theo CLAUDE.md. Phân biệt sai lệch với demo ở kích thước chuẩn và lỗi responsive/i18n ở kích thước khác.

## Review hoặc sửa cho khớp

- Yêu cầu chỉ review: báo cáo sai lệch, chưa sửa UI runtime. Có thể tạo bằng chứng/preview cần thiết trong phạm vi kiểm tra.
- Yêu cầu setup/sửa cho giống demo: thực hiện sửa trong ui/ theo phạm vi đã được cho phép, không dừng ở đề xuất. Đọc .claude/skills/godot-ui/SKILL.md và áp dụng quy trình dự án; UI mặc định dựng bằng GDScript, không tự tạo scene mới.
- Tái dùng helper và asset hiện có. Nếu thiếu sprite/font đúng mẫu, chỉ rõ phần thiếu và ảnh hưởng; không thay bằng hình gần giống rồi kết luận đã khớp. Nếu cần tạo asset, tuân thủ quy trình asset trong CLAUDE.md.
- Sửa sai lệch lớn về bố cục/asset trước, sau đó typography và chi tiết. Chạy kiểm tra script/test UI liên quan, kiểm tra cả log lỗi vì exit code Godot không đủ chứng minh thành công.
- Sau mỗi lượt sửa có ảnh hưởng thị giác, chụp lại cùng trạng thái/kích thước và đối chiếu. Hoàn tất khi các sai lệch đã phát hiện được giải quyết và bằng chứng mới xác nhận; nếu thiếu công cụ/asset hoặc có xung đột chưa giải quyết, báo rõ phần còn lệch, không tuyên bố hoàn thành.

## Báo cáo

- Nêu kết luận mức độ khớp demo trước, kèm đường dẫn ảnh chuẩn và ảnh runtime đã kiểm tra.
- Liệt kê sai lệch quan trọng trước: vùng UI, mong đợi theo demo, thực tế, ảnh hưởng, file:dòng gây ra khi xác định được và hướng sửa hoặc thay đổi đã thực hiện.
- Tách lỗi xác nhận được khỏi điểm chưa kiểm chứng. Không coi sự tồn tại của code hoặc test pass là bằng chứng UI giống demo.
- Nếu đã sửa, kèm ảnh kết quả mới nhất, kiểm tra đã chạy và sai lệch còn lại. Nếu không tìm thấy sai lệch trong phạm vi đã kiểm tra, nói rõ phạm vi và giới hạn thay vì khẳng định giống tuyệt đối.
