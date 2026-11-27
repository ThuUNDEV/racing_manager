# Asset Garage trích từ Race Star – Team Manager 1.9.0

Ngày: 27/11/2026. **Chỉ để tham khảo nghiên cứu, không dùng làm art của dự án.** Bản quyền thuộc chủ sở hữu game gốc.

Nguồn: `Team_Manager/work/Data` (giải nén từ `com.coolcatsgames.racestaridle.apk`). Công cụ: UnityPy 1.25.4, trích Texture2D theo tên. 134 ảnh, 0 lỗi.

| Thư mục | Số ảnh | Nội dung |
|---|---:|---|
| `carthumb/` | 24 | Ảnh xe 3/4 (256px) cho danh sách xe, 6 loại × 4 rarity, mỗi rarity một màu (trắng / xanh / tím / cam) |
| `carbase/` | 24 | Xe nhìn từ trên xuống, 640x960, nền cho tuỳ biến |
| `carbodymask/` | 24 | Mặt nạ thân xe để đổi màu sơn |
| `carpatternsheet/` | 24 | Sheet họa tiết decal 1280x1920 (chevron, caro, sọc) |
| `garagegear/` | 8 | Icon 8 bộ phận (dạng nét trắng) |
| `icon/` | 25 | Icon tab Garage, 3 decal, 14 màu decal, shard |
| `_sheet_*.png` | 4 | Bảng tổng hợp để xem nhanh |

## Điều rút ra

- Xe trong Garage có hai dạng ảnh: thumbnail 3/4 để chọn xe, và ảnh nhìn từ trên xuống để tuỳ biến, đúng với góc nhìn đường đua.
- Tuỳ biến hoạt động theo lớp: `CarBase` + `CarBodyMask` (tô màu sơn) + `CarPatternSheet` (decal) + màu decal.
- Decal chỉ có 3 kiểu (Chevron, Line, Checker). Màu decal có 14 màu. Màu sơn dùng mask nên có thể là màu bất kỳ.
- Xe trong Garage khác nhau về hình dáng theo loại và rarity (thân khác hẳn). Dự án hiện dùng chung một thân xe.
- Icon bộ phận dùng kiểu nét trắng đơn sắc, không có khung màu.

## Chưa giải mã

Bố cục màn Garage (prefab, vị trí nút, tab) chưa có. Ảnh nền, khung panel và font nằm ở các GameObject/MonoBehaviour khác, chưa đọc.
