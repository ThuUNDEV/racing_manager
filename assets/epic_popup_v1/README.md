# Epic popup v1

Sprite cho popup Xe Epic (`ui/shop_epic_detail.gd`), cắt thẳng từ concept đã duyệt
`Design/Concepts/IAP_Epic_Garage_v1/epic_car_popup_v1.png` bằng `tools/build_epic_popup_assets.py`.
Ảnh thô: `output/imagegen/epic_popup_v1/`. Toạ độ cắt và provenance: `manifest.json`.

| File | Kích thước (px) | Mode |
|---|---|---|
| `stage_zenith.png` | 832x596 | stage (AI sinh theo model 3D Zenith) |
| `stage_zenith_concept.png` | 832x596 | stage (cắt thẳng từ concept, không dùng trong game) |
| `stage_pico/nova/apex/titan.png` | 832x596 | stage (AI sinh theo ảnh chụp model 3D) |
| `stage_paint_aurora/solar/midnight/sakura/neon.png` | 832x596 | stage (AI sinh theo ảnh chụp model 3D xe Apex đổi sơn) |
| `header_gift.png` | 135x140 | cutout |
| `close_round.png` | 106x106 | cutout |
| `tile_speed.png` | 151x103 | cutout |
| `tile_collect.png` | 177x128 | cutout |
| `tile_flag.png` | 148x105 | cutout |
| `header_bar.png` | 173x122 | slice |
| `chip.png` | 88x73 | slice |
| `tile.png` | 80x214 | slice |
| `button.png` | 174x153 | slice |

- `stage`: ảnh đục, viền hoà vào màu thẻ `#fcede2`.
- `cutout`: nền trong suốt (art-tools remove-bg; `close_round` dùng mặt nạ tròn).
- `slice`: 9-slice ngang (nắp trái + cột giữa + nắp phải), vẽ bằng `EpicDetail.draw_slice`; nắp ghi trong `SLICES`.
- `stage_zenith` có chữ "EPIC" in sẵn: khóa `shop.epic_ribbon` là "EPIC" ở cả 8 ngôn ngữ.
- `stage_pico/nova/apex/titan`: sinh bằng `tools/gen_epic_stages.py` (gpt-image-2.6-flare, quality low, ref phong cách `stage_zenith_concept.png` + ảnh chụp model 3D từ `tests/epic_car_ref_capture.gd`), hậu xử lý `tools/build_epic_stages.py`; ảnh thô và prompts ở `output/imagegen/epic_popup_stage/`.
