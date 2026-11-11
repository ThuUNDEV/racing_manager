# Workshop GP — Asset MVP 2D v1.0

Bộ art/audio hoàn chỉnh cho phạm vi MVP ba track, ba tay đua, tám xe và năm tab. Phong cách concept số 1: Workshop GP, kem/cam/graphite, ảnh 2D mang phong cách render 3D.

- Gói bàn giao: [Workshop_GP_2D_Complete_v1.0.zip](AssetPacks/Workshop_GP_2D_Complete_v1.0.zip).
- Hướng dẫn và API: [README](../assets/workshop_gp/README.md).
- Catalog resource: [asset_catalog.json](../assets/workshop_gp/asset_catalog.json).
- Ma trận theo màn: [ASSET_COVERAGE](../assets/workshop_gp/ASSET_COVERAGE.md).
- Kết quả kiểm tra: [QA](../assets/workshop_gp/QA.md).
- [Toàn bộ hình](Previews/Workshop_GP_Complete/ASSET_CATALOG.png) và [các màn UI](Previews/Workshop_GP_Complete/OVERVIEW.png), đều render từ Godot.

## Thành phần

| Nhóm | Số lượng |
|---|---:|
| Track PNG 1536×1024 + đường chạy JSON | 3 |
| Tay đua + avatar | 3 |
| Màu xe | 8 |
| Props rời | 8 |
| Vật phẩm thưởng/cúp | 8 |
| Huy hiệu/huy chương | 6 |
| Icon render + icon chức năng | 12 + 40, bản chức năng có hai màu |
| SVG UI / StyleBoxTexture | 31 / 17 |
| Card và dialog tái sử dụng | 9 + 5 |
| Animation VFX / frame SVG | 6 / 74 |
| SFX / engine loop / music loop | 17 / 2 / 2 |
| Màn gallery | 12, kèm hai biến thể track |

ZIP có project Godot độc lập để mở xem mà không dùng autoload hay save của game. Khi đưa vào project chính, copy `assets/workshop_gp/` và nối dữ liệu/signal. Scene gameplay hiện có chưa được thay art hoặc sửa mô phỏng. Chưa kiểm tra trên thiết bị Android/iOS.
