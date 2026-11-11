# Nguồn asset

- Chín PNG nguồn được tạo bằng ImageGen cho concept Workshop GP đã chọn. Không trích xuất ảnh từ APK hoặc tải art game mẫu vào gói.
- SVG UI, icon chức năng, huy hiệu, nhận diện và frame VFX được viết cho bộ này; mã dựng nằm trong `tools/build_complete_pack.py` và `tools/build_pack.py`.
- 21 WAV được tổng hợp bằng mã: tone, noise, bass, percussion và vòng nhạc nguyên bản. Không dùng sample ngoài, ca khúc có sẵn, giọng nói hoặc bản thu xe thật.
- PNG giữ nguyên byte. Vùng cắt được lưu trong AtlasTexture/JSON. Những đốm alpha nhỏ ở mép ô được loại khỏi phép đo bounding rectangle; pixel nguồn không đổi.
- Font hiển thị là font mặc định đi cùng Godot, không phân phối font hệ điều hành.
- Scene/script/tài liệu viết cho dự án. Không cần plugin trả phí, SDK hoặc dịch vụ mạng để mở gallery.

`manifest_complete.json` lưu SHA-256 và kích thước file. Tay đua là nhân vật hư cấu; không dùng hình/thương hiệu tay đua thật.
