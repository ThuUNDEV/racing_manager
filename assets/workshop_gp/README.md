# Workshop GP — bộ asset MVP 2D v1.0

Hoàn thiện theo concept **Workshop GP**: kem ấm, cam và graphite. Đủ art/audio cho phạm vi MVP đã thiết kế: ba đường đua, ba tay đua, tám xe, năm tab và các cửa sổ hỗ trợ.

Đây là **asset 2D mang phong cách render 3D**. PNG tách nền có alpha thật; không chứa mesh 3D. Chữ, tiền, cấp và thông số do engine vẽ, không gắn vào texture.

## Nội dung

| Nhóm | Nội dung |
|---|---|
| Track | Harbor Oval, Pine Circuit, City Technical; mỗi nền 1536 × 1024; không gắn xe/UI; có centerline Bézier JSON và Control render |
| Xe | Tám màu; AtlasTexture riêng; một kiểu thân xe đúng phạm vi MVP |
| Tay đua | An, Bình, Chi; bust tách nền và vùng avatar |
| Đạo cụ | Garage, khán đài, thông, cây tán tròn, barrier, chồng lốp, tủ dụng cụ, cột đèn |
| Phần thưởng | Ba cúp, hộp quà, hộp dụng cụ, túi tiền, cờ đích, mô hình cơ sở |
| Huy hiệu | Ba cấp giải và ba huy chương |
| Icon | 12 icon render + 40 icon chức năng; mỗi icon chức năng có bản sáng/tối |
| UI | 31 SVG UI, 17 StyleBoxTexture và Theme; normal/hover/pressed/disabled, selected/locked, success/danger, focus; progress, toggle, checkbox, tooltip arrow, tutorial hand, loading |
| Godot | Chín card/component và năm dialog overlay; nhận dữ liệu và phát signal, không gắn luật game |
| VFX | Sáu animation / 74 frame SVG; SpriteFrames và scene: nâng cấp, bung thưởng, confetti, về đích, xoay tiền, vòng đánh dấu xe |
| Audio | 17 SFX, hai vòng tiếng động cơ, hai bản nhạc 32 giây; WAV stereo PCM 16-bit / 44,1 kHz; catalog, bus layout và audio helper |
| Nhận diện | Icon app SVG 1024px, nền splash SVG |
| Gallery | 12 màn; năm tab MVP, đổi ba track, chọn tay đua minh họa, thử VFX và nghe từng cue |

Đường dẫn từng resource ở [asset_catalog.json](asset_catalog.json). Ma trận theo màn hình ở [ASSET_COVERAGE.md](ASSET_COVERAGE.md).

## Mở xem

ZIP `Workshop_GP_2D_Complete_v1.0.zip` có project Godot độc lập tại thư mục gốc. Giải nén sang thư mục mới, mở `project.godot` bằng Godot 4.7.2 và Run. **Không cần Python để dùng asset hoặc chạy gallery.**

Từ repo hiện tại có thể tạo project riêng:

```powershell
python assets/workshop_gp/tools/build_preview_project.py D:/WorkshopGPArtPreview
```

Mở project vừa tạo. Gallery không có autoload gameplay, không đọc/ghi save. Thanh chọn trên cùng mở 12 màn; thanh đáy là năm tab MVP. Vào **Cài đặt → Thư viện asset & âm thanh** để thử VFX/audio. Âm thanh mặc định tắt; thư viện có nút nghe từng cue và dừng.

`preview/workshop_gp_preview.tscn` được giữ làm bản concept ban đầu sáu mục. `preview/asset_gallery.tscn` là gallery MVP hiện tại năm tab.

## Tích hợp

Giữ nguyên `res://assets/workshop_gp/`. Gán `theme.tres` cho UI root. Dùng `.tres` làm Texture2D trực tiếp, không cần cắt lại atlas.

**Card:** instance `components/upgrade_card.tscn`, `driver_card.tscn` hoặc card tương ứng; gọi `configure()` với dữ liệu rồi nối `action_requested(id)` tới logic game. Các khóa: `item_id`, `title`, `subtitle`, `image_path`, `action_text`, `disabled`, `selected`, `progress`. Caller kiểm tra điều kiện, giao dịch và save.

**Dialog:** instance `components/*_dialog.tscn`; nối `accepted`/`dismissed`, xử lý dữ liệu trong game rồi đóng instance. Có kết quả, offline, mùa giải, quà ngày và xác nhận. Overlay co theo chiều rộng, nút chính 48px.

**Track:** `components/track_art.gd` chỉ vẽ. Đặt `track_id` trước khi thêm vào tree; sau `_ready` gọi:

```gdscript
track.set_racers([
    {"lap_fraction": 0.25, "color": 0, "player": true},
    {"lap_fraction": 0.38, "color": 3, "player": false},
])
```

`lap_fraction` do mô phỏng cung cấp, ánh xạ lên đường cong hình ảnh. Component không tự chạy đua hoặc suy ra sector từ ảnh. Xe nguồn hướng **+Y**; khi tự dùng Sprite2D, đặt góc `direction.angle() - PI/2`. Màu 0–7: cam, graphite, trắng, xanh dương, đỏ, vàng, teal, tím. Xe người chơi có vòng và mũi tên.

**VFX:** instance `vfx/*.tscn`. Hiệu ứng một lần tự giải phóng. `coin_spin`/`player_ring` lặp; caller dừng và giải phóng. Frame là SVG nguồn 256px. Game xử lý giảm chuyển động khi gọi hiệu ứng.

**Audio:** thêm node dùng `components/workshop_audio.gd`, gọi `play("upgrade")`, `play("music_race_loop")` và `stop_all()`. Helper đặt loop từ catalog, thêm bus Music/SFX/Engine nếu thiếu, không thay layout đang có. Giữ player trả về để điều chỉnh pitch/volume động cơ; không gọi tiếng xe mỗi frame.

## Import và nguồn

- PNG lossless, Linear filter. AtlasTexture có `filter_clip`; PNG nguồn giữ nguyên byte.
- SVG co giãn; StyleBoxTexture dùng 9-slice. Thay kích thước Control thay vì Scale cả UI. Capsule tối thiểu 32px, stat chip tối thiểu 20px; nút gallery tối thiểu 44px.
- Theme dùng font mặc định Godot, hỗ trợ tiếng Việt; không đóng gói font Windows.
- Âm thanh tổng hợp theo phong cách game, không phải bản thu động cơ thực. Nhạc/engine đã đo biên nối vòng; PCM không clipping.
- Nền track chứa công trình tĩnh. Tám props rời có thể dùng để trang trí; đây không phải hệ thống tilemap đường đua.
- [PROVENANCE.md](PROVENANCE.md) ghi nguồn và cách dựng.

## Kiểm tra và dựng lại

Xem [QA.md](QA.md) cho kiểm tra Godot và giới hạn thực tế. Bản bàn giao kèm ảnh từng màn và hai bảng tổng quan render trong engine.

Chỉ công cụ dựng lại cần Python và `tools/requirements.txt`:

```powershell
python assets/workshop_gp/tools/build_complete_pack.py
python assets/workshop_gp/tools/validate_complete_pack.py
python assets/workshop_gp/tools/build_complete_pack.py --inventory-only
python assets/workshop_gp/tools/validate_complete_pack.py --check-hashes
```

`manifest.json` là chỉ mục, `asset_catalog.json` dùng để tích hợp; `manifest_complete.json` chứa kích thước/SHA-256. Công cụ chỉ đọc alpha để đo atlas, viết SVG/resource và tổng hợp WAV; không sửa PNG.

Phạm vi hoàn thành là **asset cho MVP**. Gallery dùng dữ liệu minh họa. Bộ này chưa thay UI/renderer trong main scene, chưa nối RaceSim/kinh tế/SDK và chưa kiểm tra trên điện thoại.
