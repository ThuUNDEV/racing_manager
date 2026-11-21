# gear_icons_soft_v1

30 icon gear (id khớp `data/gear.json`), Soft Miniature clay, màu theo nhóm: đầu = tím lavender, tay = xanh trời, chân/bảo hộ = navy, thân = xanh lá, dụng cụ = cam mơ.

- File: `gear_<id>.png`, RGBA 512x512, nền trong suốt, icon căn giữa.
- Nguồn: gpt-image-2.5-flare (tools/gen_image.py, --quality low, 6 sheet 1536x1024) -> art-tools remove-bg (refine) -> cắt lưới 3x2, căn giữa. Ảnh thô và prompt: `output/imagegen/gear_icons_soft_v1/` (không commit).
- Chưa tích hợp vào game: `ExpansionArt`/`Soft.expansion` vẫn dùng `assets/racing_ui_hd_expansion`. Chưa có trong manifest của pack.
