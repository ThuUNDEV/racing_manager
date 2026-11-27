# Concept thiết kế lại Garage v2 (chờ duyệt)

Ngày 27/11/2026. Ảnh concept để duyệt mỹ thuật và bố cục, chưa triển khai Godot. Sinh bằng `gpt-image-2.6-flare` (`tools/gen_image.py`, tham chiếu `approved/04-garage.png`). Prompt và nguồn gốc: `prompts.json`.

| Ảnh | Nội dung |
|---|---|
| `01-car.png` | Tab Xe: showroom nhỏ, tên + hạng, 4 chỉ số, Nâng cấp / Đang dùng, lưới Bộ sưu tập 3 cột ngay trên tab |
| `02-parts.png` | Tab Phụ tùng: 4 thẻ lớn 2x2 (cấp/200, chỉ số trước → sau), khung mua cố định ở đáy (x1 / x10 / Tối đa) |
| `03-look.png` | Tab Ngoại hình: xem trước trên xe, 8 màu sơn, 4 họa tiết, Hủy / Lưu |

## Thay đổi so với bản duyệt cũ

Học từ bố cục Race Star đã giải mã (`../../References/RaceStar_Garage_Extract/garage_layout.md`), giữ nguyên kinh tế và dữ liệu của dự án:
- Chọn xe ngay trên tab Xe, bỏ bước mở Bộ sưu tập riêng; nút hành động nằm cạnh thông tin xe.
- Phụ tùng thành thẻ lớn có khung mua cố định ở đáy, thay cho danh sách rời rạc.
- Ngoại hình chia mục Màu sơn / Họa tiết trên một trang, có Hủy / Lưu.
- Giữ showroom 3/4 Soft Miniature (game gốc dùng ảnh nhìn từ trên xuống).

## Lưu ý số liệu

- Dùng dữ liệu thật: Pico Tia chớp base S46 H38 B38 A38, cấp 40/30/20/10 (fixture trong `Design/15_Advanced_Garage.md`), mỗi cấp +0,2.
- Giá `1,2K` và định dạng số trong ảnh chỉ minh họa; giá thật lấy từ `core/economy/pricing.gd`.
- Chữ do ImageGen dựng, có thể lệch nhẹ. Bố cục chuẩn khi triển khai sẽ lấy theo `Design/34_Layer_Layout_Spec.md`.
- Chưa có: thân xe khác nhau theo hạng, màu decal (game gốc có, dự án chưa).
