# Racing Manager — hướng dẫn cho các phiên làm việc

## Đọc trước khi làm việc

- Đọc `CLAUDE.md` ở gốc dự án trước khi sửa code, làm thiết kế hoặc tạo demo. File đó chứa quy ước kỹ thuật, dữ liệu, cách chạy an toàn và quy trình asset của dự án.
- Làm theo yêu cầu trực tiếp của người dùng khi yêu cầu đó thay đổi phạm vi hoặc quy trình mặc định dưới đây.

## Mặc định khi người dùng yêu cầu demo thiết kế UI

Các yêu cầu như “làm demo”, “demo thiết kế lại”, “làm concept”, “mockup UI”, “thiết kế lại pack/popup” mặc định là **ảnh concept để duyệt mỹ thuật và bố cục**, trừ khi người dùng nói rõ muốn bản tương tác hoặc triển khai code.

1. Đọc mục “Thiết kế và UI”, “Tạo ảnh demo / asset” trong `CLAUDE.md`, tài liệu thiết kế liên quan và ảnh đã duyệt tại `Design/Demos/SoftMiniature/approved/`.
2. Đọc và áp dụng skill **imagegen** đang có trong phiên. Dùng ảnh tham chiếu của người dùng và phong cách **Soft Miniature** hiện hành. Giữ giá, phần thưởng và điều kiện đúng dữ liệu game. Khi yêu cầu thiết kế lại bố cục, được thay đổi bố cục trong phạm vi đó.
3. Tạo ảnh concept trước, lưu tại `Design/Demos/` hoặc `Design/Concepts/`; lưu prompt và nguồn gốc theo `CLAUDE.md`. Hiển thị ảnh trực tiếp để người dùng duyệt.
4. Không tự thay demo mỹ thuật bằng HTML/CSS, trang web hoặc `visualize`. Chỉ dùng các cách này khi người dùng yêu cầu bản tương tác, bản xem trong chat hoặc một sản phẩm HTML/web cụ thể.
5. Sau khi concept được duyệt và người dùng yêu cầu triển khai, mới tách sprite, bổ sung asset và dựng UI Godot. Khi đó đọc `.claude/skills/godot-ui/SKILL.md` và tuân theo cách dựng UI bằng GDScript của dự án.

Nếu skill, công cụ hoặc model được quy trình chỉ định không khả dụng, nêu đúng phần còn thiếu; không âm thầm đổi loại sản phẩm bàn giao hoặc tuyên bố đã dùng skill khi chưa đọc và áp dụng.

## Phạm vi thay đổi

- Yêu cầu demo thiết kế không tự cho phép sửa UI runtime, dữ liệu cân bằng, giá bán hoặc save game.
- Giữ nguyên các thay đổi đang có của người dùng và không sửa file ngoài phạm vi công việc.

## Git

- Được `git push` lên remote mà không cần hỏi lại người dùng.
- Force push, xoá nhánh/tag trên remote vẫn phải hỏi trước.
