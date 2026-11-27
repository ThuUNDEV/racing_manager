# Bố cục màn Garage của Race Star 1.9.0 (giải mã từ prefab)

Ngày: 27/11/2026. Nguồn: prefab `MainMenuPopupView` (file `cc40eba3…` trong `Team_Manager/work/Data`), nhánh `GarageContentView`. Cây node đầy đủ: [garage_prefab_tree.txt](garage_prefab_tree.txt). Wireframe vẽ lại từ số liệu: [_wireframe_garage_1179x2556.png](_wireframe_garage_1179x2556.png).

**Chỉ để tham khảo.** Không dùng art gốc. Đây là số liệu đọc trực tiếp từ prefab (anchor, kích thước, màu, sprite), khác với suy luận trong các tài liệu trước.

## Giới hạn khi đọc

- File không có typetree nên các trường Image/Text/LayoutGroup/Grid được parse thô theo bố cục byte; đã đối chiếu với giá trị hợp lý (màu, cỡ chữ, ô lưới) nhưng chưa kiểm chứng bằng cách chạy game.
- Cỡ chữ (`fs~`) là ước lượng: lấy số nguyên đầu tiên hợp lệ sau chuỗi.
- Kích thước tự dãn theo LayoutGroup/ContentSizeFitter hiện là 0 trong prefab, chỉ ghi được cấu hình.
- Chuỗi trong prefab là chữ mẫu (ví dụ "Super Long Amazing Car Name", "22.2AB"), không phải dữ liệu thật.
- Không xác định được vị trí thanh điều hướng dưới. Khoảng trống 230 px giữa khối trên và bảng bộ sưu tập có thể là nơi thanh này đè lên.

## Khung chung

- Canvas Scaler: ScaleWithScreenSize, tham chiếu **1179 × 2556**, match theo chiều rộng (0). Nội dung rộng 1100, lề ngang ~40.
- Màn là popup toàn màn hình, nền sáng `#f8fafc`; panel `#e2e8f0`; viền `#cbd5e1`. Màu chủ đạo xanh `#2e6de5`, nút xác nhận xanh lá `#22c55e`, nút khóa xám `#d4d4d8`.
- Đầu màn (420 px): hàng tiền tệ (Coins trái, Gems phải, mỗi cái 350×75, bo tròn) rồi hàng tab 1100×150.
- **3 tab:** Garage (xe) / Parts (bộ phận) / Customization. Tab đang chọn xanh `#2e6de5`, chữ trắng 42; tab còn lại trắng. Mỗi tab có chấm thông báo đỏ `#fe5d70` ở góc trên phải.
- Nút lớn: bo tròn hết cỡ (`SlicedCircle_60`), cao 120–140, chữ 50, rộng tối thiểu 300 (ưa 650).

## Tab Garage (xe)

Khối trên cao 1106, khối dưới (bộ sưu tập) cao 800 neo đáy.

| Vùng | Kích thước | Nội dung |
|---|---|---|
| Ảnh xe | 580 × 871, bên trái | `CarBase_*` nhìn từ trên xuống |
| Cột thông tin | 500 rộng, bên phải, xếp dọc, giãn 20 | 5 khối, bên dưới |
| Hàng nút | 1100 × 140, cách đáy khối trên 30, giãn 50 | **Upgrade** (xanh lá) + **Equip** (xanh); xe chưa có: **Unlock** (xám) + nút mua IAP (xanh đậm, giá tiền thật) |
| Bộ sưu tập | 800 cao, lưới **4 cột**, ô **230 × 285**, giãn 40, đệm trên/dưới 60 | Thẻ xe, cuộn dọc |

Cột thông tin (trên xuống):
1. **Tên xe + huy hiệu rarity**: tên chữ 35; huy hiệu có 2 ngôi sao và chữ rarity (30), tô màu theo rarity (Legendary vàng `#f9a825`).
2. **Star Level**: 5 sao vàng `#ffc30b` (60 px, giãn 10).
3. **Shards to upgrade**: thanh tiến độ cao 50, icon shard bên trái.
4. **For Owning**: Offense (kiếm đỏ `#ef4444`) và Defense (khiên xanh), mỗi dòng cao 80, giá trị căn phải.
5. **For Equipping**: cùng cấu trúc.

Thẻ xe (230 × 285): nền bo tròn (màu theo rarity, ví dụ tím `#c084fc`); ảnh xe chiếm 80% trên, thanh tiến độ shard chiếm 20% dưới. Trạng thái: **Equipped** (nhãn đáy, cao 35), **Locked** (ổ khóa 40 góc phải trên, phủ mờ), chọn (viền ngoài).

## Tab Parts (bộ phận)

- Danh sách cuộn 1100, lưới thẻ **335 × 425**, giãn 35 ngang / 45 dọc, đệm trên 40; hàng cuối căn giữa (8 thẻ: 3 + 3 + 2).
- Thẻ bộ phận: nền xám `#6c757d` theo rarity, 55% trên là vùng tranh (3 sao ở trên, icon 150 ở giữa), 45% dưới là dải dữ liệu trắng: tên (40), hai chip Attack (kiếm) và Defense (khiên) bên cạnh nhau, thanh tiến độ dưới cùng. Thẻ chưa nhặt hiện dấu hỏi 128 ("Unrevealed Garage Gear").
- Khung mua cố định ở đáy: 1100 × 425 cách đáy 30, nền `#f1f5f9`. Tiêu đề "Boost Your Ride" (50), mô tả (30), nhãn "Open x1 / Open x10", hai nút xanh 510 × 120 kèm giá gem (1 và 10).

## Tab Customization

- Ảnh xe xem trước 580 × 871 ở giữa trên, cách đỉnh 25.
- Bảng cuộn 965 cao neo đáy, nền `#e2e8f0` có gradient, gồm 3 mục xếp dọc; mỗi mục có tiêu đề cao 100 (chữ 40, gạch chân 4px `#64748b`):
  - **Car Color**: lưới ô **165 × 165**, giãn 20.
  - **Decals**: lưới ô **170 × 170**, giãn 15.
  - **Decal colors**: lưới ô **170 × 170**, giãn 15 (tiêu đề chỉ có đường kẻ, không có chữ).
- Ô tuỳ biến (250 × 250 trong prefab mẫu): ô bo tròn, mẫu màu bên trong; **đang dùng** = dấu tích xanh `#4ade80` 100 px ở giữa; **khóa** = phủ trắng 30% + ổ khóa 100; **đang chọn** = viền vàng `#fcd34d` dày 5.
- Hàng nút đáy 1100 × 130, giãn 30: **Equip / Equipped**, **mua bằng gem** (hiện giá), **Free** (xem quảng cáo, icon quảng cáo). Màu nào chưa mở thì mua bằng gem hoặc xem quảng cáo.

## Điểm rút ra cho thiết kế lại

- Garage gốc là màn **toàn màn hình, 3 tab ngang**, xe lớn bên trái, thông tin bên phải, lưới chọn xe 4 cột bên dưới. Không có showroom 3/4 hay bục xoay; xe hiện nhìn từ trên xuống.
- Chọn xe ngay trên tab, không cần mở bộ sưu tập riêng; mua/nâng cấp/trang bị dùng chung hàng nút 2 chiều.
- Bộ phận quản lý bằng thẻ lớn 3 cột, kiểu sưu tầm thẻ có sao và rarity; nâng cấp theo hệ shard/gói, không mua trực tiếp từng cấp.
- Tuỳ biến tách 3 mục (màu, decal, màu decal) trên một trang cuộn, mua mở khoá bằng gem hoặc quảng cáo.
