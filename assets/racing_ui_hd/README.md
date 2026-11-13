# Racing UI HD

Bộ PNG tái tạo theo ảnh mẫu, đã tách từng asset. Artwork raster; nhãn chữ nên được vẽ riêng bằng Label trong Godot.

## Nội dung

- `icons/`: 21 icon minh họa, avatar, xe và huy hiệu.
- `controls/`: 11 chi tiết điều khiển, sao, checkbox và toggle.
- `surfaces/`: 8 nền nút, thanh tài nguyên và panel không có chữ.
- `backgrounds/`: 1 nền trường đua 1536 × 1024.

`manifest.json` chứa ID, đường dẫn `res://`, kích thước thực và SHA-256 của 41 PNG trong bộ export ban đầu.

Ngày 2026-11-12, cả 7 nền `surfaces/button_*.png` được giảm phản sáng góc trái và viền bóng để đồng bộ phong cách dịu hơn. Giữ kích thước PNG, nền trong suốt và đường dẫn hiện có để các trạng thái nút và biến thể màu tiếp tục dùng chung asset. `button_amber.png` là asset bổ sung ngoài danh sách 41 PNG ban đầu.

## Dùng trong Godot

Kéo PNG từ FileSystem vào TextureRect hoặc gán vào texture của TextureButton. Godot sẽ tự import khi mở dự án. Giữ tỷ lệ khi hiển thị icon; dùng lọc Linear khi thu nhỏ. Đặt Label riêng lên nền nút để thay đổi chữ và bản địa hóa.

Nền trường đua là ảnh minh họa có xe và công trình gắn sẵn, không phải đường đua/tilemap dành cho mô phỏng. Bản nền nằm ngang; cần bố trí lại nếu dùng trong màn hình dọc của dự án.

Thao tác này chỉ nhập asset vào dự án; các scene và texture reference hiện tại chưa được chuyển sang bộ mới.

## Figma

- Asset: https://www.figma.com/design/8VBWw193bPHoBgNNrFkagO?node-id=12-108
- Màn hình ghép: https://www.figma.com/design/8VBWw193bPHoBgNNrFkagO?node-id=13-78
