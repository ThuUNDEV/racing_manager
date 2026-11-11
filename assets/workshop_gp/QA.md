# Kiểm tra bàn giao Workshop GP 1.0

Ngày 09/11/2026. Engine thực tế: Godot 4.7.2 stable, Compatibility/OpenGL 3.3, NVIDIA GTX 1660 SUPER trên Windows.

## Tài nguyên

- Ba PNG track 1536×1024; ba đường cong đóng. Đã xem render xe trên cả ba nền và kiểm tra 1.000 điểm lấy mẫu centerline với ảnh nguồn.
- 42 vùng AtlasTexture nằm trong ảnh nguồn; PNG sprite có alpha thật. Chín PNG nguồn giữ nguyên byte, không encode lại.
- 89 native resources `.tres`/`.tscn` có đủ tham chiếu trong pack và được Godot load. Không cần resource của main scene/gameplay.
- SVG parse được, không có ảnh/font/link bên ngoài. Có đủ 14 component/dialog, sáu animation và 74 frame.
- 21 WAV giải mã được trong Godot; stereo PCM 16-bit/44,1 kHz; không clipping. Bốn loop có độ nhảy biên nhỏ hơn 0,04 mức full-scale; helper thiết lập đúng loop mode/end sample.
- SHA-256 và kích thước file nằm trong manifest; ZIP được kiểm tra CRC sau khi đóng archive.

## UI và native runtime

| Kích thước logical px | Kiểm tra native | Kết quả |
|---|---:|---|
| 320×568 | 1.072 | 0 lỗi |
| 360×800 | 1.072 | 0 lỗi |
| 390×844 | 1.072 | 0 lỗi |
| 412×915 | 1.072 | 0 lỗi |

Kiểm tra gồm load/instance resource, card selected/disabled, tạo player và giải mã audio, cấu hình loop, đổi 12 màn, đo chiều ngang các Control, phát signal chọn Bình và nhận quà, kiểm tra nút sau nhận bị khóa. Đây là kiểm tra tự động trong gallery, không phải thao tác gameplay hoặc playtest.

Mỗi kích thước đã render 12 màn và hai biến thể track Pine/City, tổng 56 ảnh. Đã xem các màn đại diện ở cả bốn kích thước và hai bảng tổng quan. Chữ/số tài nguyên, nav và bố cục không tràn ngang. Màn hình thấp dùng cuộn dọc, giữ tài nguyên và thanh tab.

Lỗi bó chữ ở lượt render đầu và tràn lưới props ở 320px đã được sửa trước khi đóng gói. Bảng tổng quan và các ảnh trong gói là bản sau sửa.

## Phạm vi xác nhận

- Gallery dùng project độc lập không có autoload, không truy cập `user://` hoặc save gameplay. Các số tiền/chỉ số/kết quả là dữ liệu xem art.
- UI, RaceView, mô phỏng và cân bằng của game chính chưa được thay bằng bộ art này. Caller cần nối signal và dữ liệu khi tích hợp.
- Chưa kiểm tra Android/iOS, safe area phần cứng, bộ nhớ/FPS trên điện thoại hoặc cân bằng âm lượng bằng loa/tai nghe thiết bị thật. Các kiểm tra audio ở trên là kiểm tra tín hiệu/giải mã, không phải chứng nhận chất lượng thu âm/mastering.

Các log native và báo cáo asset đi kèm thư mục `QA/` trong ZIP; ảnh ở `Previews/`. Công cụ có trong pack để chạy lại.
