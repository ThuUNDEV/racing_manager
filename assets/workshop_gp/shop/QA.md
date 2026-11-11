# Asset QA — 2026-11-10

- Godot 4.7.2, OpenGL Compatibility, Windows/NVIDIA GTX 1660 SUPER.
- Import thành công trong project tạm độc lập, không dùng autoload/save của game.
- Nạp và render: 16 AtlasTexture, 2 PNG banner, 8 SVG qua 8 StyleBoxTexture; `SHOP_ASSET_QA failures=0 icons=16 styles=8`, exit 0.
- Atlas RGBA 1254 × 1254, alpha có cả 0 và 255; mọi ô có nội dung. Các vùng atlas dùng ranh giới nguyên theo tỉ lệ 1/4, nên ô rộng/cao 313 hoặc 314 px.
- Banner RGB 2172 × 724 (3:1), không gắn chữ/giá/bộ đếm.
- Đã xem trực tiếp contact sheet `preview/asset_sheet.png`: icon không bị cắt mất đối tượng chính, không lẫn ô kế bên, nền alpha hiển thị trên kem; banner có vùng trái đặt chữ; khung/nút giãn đúng hình.
- Chưa tích hợp Shop, chưa kiểm tra giao dịch, thiết bị hoặc màn Shop chạy thật.
