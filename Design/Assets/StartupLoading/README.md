# Startup Loading — asset thiết kế v0.1

Ngày: 09/11/2026. Phạm vi: thiết kế và tạo asset, **chưa tích hợp vào scene hoặc script game**.

Đặc tả: [09_Startup_Loading_Design.md](../../09_Startup_Loading_Design.md).

## Tệp bàn giao

| Tệp | Định dạng | Vai trò |
|---|---|---|
| `loading_background.png` | PNG RGB, 948 × 1659, opaque | Nền garage kem/cam/graphite, không xe, không chữ/UI |
| `loading_car.png` | PNG RGBA, 1536 × 1024 | Xe cam góc 3/4, nền alpha, bóng/ánh sáng mềm |
| `loading_screen_concept.png` | PNG opaque | Concept hoàn chỉnh để xem bố cục, có chữ và thanh 68% minh họa |

Các tệp là ảnh sinh bởi ImageGen. Nguồn tham chiếu nội bộ: `Design/Previews/Workshop_GP_Complete/race.png` cho phong cách và `assets/workshop_gp/atlases/cars.png` cho xe cam. Nền được tạo trước, xe được tạo với tham chiếu nền và atlas; concept dùng hai ảnh mới này. Bản sinh gốc giữ tại thư mục `C:/Users/thupv/.codex/generated_images/01a1bf44-7748-7c21-9398-2770097b03e3/` với tên lần lượt `exec-e0652df7-8c1d-4b76-9df0-6937451da4e5.png`, `exec-be5b649e-2c53-4e0a-8f52-09f8f714325a.png`, `exec-41d87b37-6313-4447-8611-4b40275fde33.png`.

## Quy tắc bố trí

- Nền và xe tách lớp. Không gắn chữ, logo hoặc phần trăm vào texture dùng trong game.
- Nền dọc dùng giữ tỷ lệ và căn giữa; bố cục chính nằm ở khoảng giữa màn. Với tỷ lệ khác, ưu tiên phủ vùng thừa bằng màu kem lấy tại biên ảnh; tránh crop mất sàn garage. Không kéo dãn ảnh.
- Garage nằm khoảng y = 32–68% của ảnh nền. Top trống cho nhận diện, bottom trống cho tiến độ/mẹo/footer.
- Vị trí xe đề xuất để bắt đầu căn: tâm ở `(52%, 57.5%)` của rect ảnh nền; chiều rộng toàn texture xe khoảng 55% chiều rộng rect ảnh nền, giữ đúng tỷ lệ 3:2. Đây là giá trị căn art ban đầu, cần duyệt vị trí bánh xe trên sàn khi dựng UI.
- Không xoay thêm xe để giả chuyển động; đây là góc camera riêng cho loading, không thay sprite nhìn từ trên xuống của cuộc đua.
- Header khoảng 12–25% chiều cao safe area; vùng loading khoảng 74–86%; footer khoảng 94%. Chừa lề ngang tối thiểu 24 ở tham chiếu 390 × 844, xử lý safe area bằng layout.
- Font/tên logo ở concept là tham khảo mỹ thuật, không phải font được đóng gói hoặc logo vector bàn giao. Runtime dùng font có đủ dấu tiếng Việt; tên hiện tại là tên làm việc Pitlane Club.
- Thanh 68% trong concept chỉ minh họa. Khi triển khai phải cập nhật bằng dữ liệu thật theo đặc tả.

## Kiểm tra đã làm và giới hạn

- Đã xem ảnh nền, xe và concept được tạo; nội dung hình và chữ concept phù hợp hướng đề xuất.
- Đã đọc kích thước/định dạng ảnh bằng `System.Drawing` và kiểm tra alpha xe ở các điểm nền mẫu. Không khẳng định toàn bộ bóng/halo đã đạt chuẩn compositing chỉ từ kiểm tra điểm mẫu.
- Chưa kiểm tra việc ghép hai lớp trong Godot, chưa duyệt crop/safe area hoặc hiệu năng trên thiết bị. Khi tích hợp, kiểm tra halo xe trên nền kem và tinh chỉnh art nếu cần.
- Không đổi `project.godot`, scene, script, tài nguyên đang được gameplay tham chiếu hoặc save người chơi để bàn giao bộ này.
