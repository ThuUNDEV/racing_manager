# Racing Manager — Concept Asset 2D v2.0 (hướng LumberTycoon)

Ngày: 10/11/2026. Trạng thái: **đề xuất để duyệt**. Thay thế hoàn toàn phong cách Workshop GP (kem/cam/graphite) ở [Workshop_GP_Asset_Pack.md](Workshop_GP_Asset_Pack.md). Chưa thay art trong project; bộ `assets/workshop_gp/` giữ nguyên cho tới khi duyệt.

Nguồn tham khảo: file Figma LumberTycoon (page UI + Page 2). Chỉ học **phong cách và cách tổ chức asset**; không copy hình, tên, nhân vật hay bố cục của game đó. Mọi asset của Pitlane Club phải vẽ/sinh mới.

## 0. Định hướng style chốt (11/11/2026) — Cartoon hiện đại, đua xe

Người duyệt đã loại hai bản thử trước (tranh tay kiểu Hay Day và voxel pixel của Airport Empire) vì quá đồ chơi hoặc lệch chủ đề, và tự đưa bảng định hướng mới. **Bảng này thay §2–§3 bên dưới về style và palette**; §4–§7 (cấu trúc hub, danh mục asset, quy cách kỹ thuật) vẫn dùng làm khung. Ảnh thử trong Figma đã xóa; chưa còn ảnh nào của style này.

### 0.1. Nguyên tắc

- **Phong cách:** cartoon hiện đại, bo góc lớn, đổ bóng nhẹ, nút bấm có chiều sâu; nổi bật, màu tươi, tương phản cao.
- **Thế giới (nền, đường đua, công trình):** isometric sáng, chi tiết vừa phải, có khán đài, tháp điều hành, garage, biển quảng cáo, cọ và cây. Nội dung phải là hình mới, không sao chép game nào.
- **Icon:** 3D stylized, khối đơn giản, dễ nhận trên màn hình điện thoại; trộn 3D và flat nhưng nhất quán chủ đề đua xe.
- **Typography:** sans-serif đậm, dễ đọc; số tiền và chỉ số được nhấn mạnh (lớn, đậm, có viền/bóng nhẹ). Phải hỗ trợ dấu tiếng Việt.
- **Panel:** nền xanh-trắng, viền rõ; tránh che quá nhiều sân đua.
- **Chạm:** bo góc dày, vùng chạm ≥ 44 px, một CTA chính mỗi trạng thái (theo [UI 3.2](01_UI_Design.md)).

### 0.2. Bảng màu (gợi ý từ người duyệt)

| Vai trò | Hex | Dùng cho |
|---|---|---|
| Primary | `#3B82F6` | Nút chính, UI, chip, thanh tab |
| Action | `#FF8A00` | Đua, nâng cấp |
| Reward | `#FFD23F` | Thưởng, nổi bật, vàng cúp |
| Success | `#22C55E` | Hoàn thành, nhận thưởng |
| Alert | `#EF4444` | Cảnh báo, badge thông báo |
| Neutral | `#6B7280` | Panel, nền phụ |
| Background | `#F1F5F9` | Nền sáng |

Quy tắc dùng: xanh dương cho giao diện, vàng/cam cho hành động quan trọng, xanh lá cho nhận thưởng. Kiểm tra tương phản chữ trên nền vàng/cam trước khi chốt.

### 0.3. Thành phần UI cần có

- **Nút:** Đua ngay (vàng-cam, to, có mũi tên), Nâng cấp (xanh dương), Hủy (trắng viền), Nhận (xanh lá). Bốn trạng thái: thường / nhấn / khóa / đang chạy.
- **HUD:** chip tiền, gem, năng lượng/nitro có nút cộng; avatar + cấp + thanh XP; nút cài đặt tròn.
- **Menu cạnh:** Nhiệm vụ, Giải đấu, Sự kiện (trái); Cửa hàng, Battle Pass, Quà đăng nhập (phải). Với phạm vi MVP, Battle Pass và Sự kiện chưa có; chỉ làm khi thiết kế release duyệt ([03](03_Release_Overview.md)).
- **Thanh đáy:** Garage, Nâng cấp sân, Nghiên cứu, Nhân sự và CTA lớn "Đua ngay". Lưu ý: bốn nút này khác năm tab hiện có (Đua / Tay đua / Garage / Giải đấu / Cửa hàng) nên **cần đối chiếu** trước khi đổi điều hướng.
- **Component:** thanh cấp XP, sao, tab lọc, công tắc, checkbox, spinner, thanh tiến trình, thẻ chỉ số có mũi tên nâng cấp.
- **Panel:** Nâng cấp xe (ảnh xe, thanh Tốc độ / Tăng tốc / Bám đường / Nitro, nút giá), Kết quả đua (huy chương hạng, tiền, cúp, nút Nhận thưởng).

### 0.4. Quyết định còn mở

| ID | Vấn đề | Ghi chú |
|---|---|---|
| D-S1 | Thanh đáy 4 nút của bảng định hướng so với 5 tab hiện tại | Giữ 5 tab MVP hay đổi điều hướng; ảnh hưởng [UI-02](01_UI_Design.md) |
| D-S2 | Menu cạnh có Battle Pass, Sự kiện, Quà đăng nhập | Ngoài phạm vi MVP, chỉ giữ nếu thiết kế release thêm |
| D-S3 | Chỉ số xe (Tốc độ / Tăng tốc / Bám đường / Nitro) | Khác 4 bộ phận hiện tại (Động cơ / Lốp / Khung gầm / Hộp số); cần ánh xạ |
| D-S4 | Năng lượng (30/30) trong HUD | MVP không có năng lượng; bỏ khỏi HUD hoặc thay |
| D-S5 | Chữ do AI sinh trong ảnh | Dựng UI thật bằng thành phần, không dùng ảnh AI trực tiếp |

## 1. Phân tích file tham khảo

| Quan sát | Chi tiết | Áp dụng |
|---|---|---|
| Góc nhìn | Isometric ~30°, một "diorama" vuông 1920×1920 trên nền cỏ phẳng | Khu đội đua (hub) và đường đua là một diorama |
| Render | Giả 3D: khối có bevel, highlight cạnh trên, bóng đổ mềm cùng một hướng (sáng từ trên-trái) | Mọi asset dùng cùng một hướng sáng |
| Màu | Bão hòa cao, ít màu trung tính; mỗi vật thể có 1 màu chủ đạo (mái đỏ, mái xanh, xe nâng đỏ, trực thăng vàng) | Mỗi nhóm asset gắn một màu chủ đạo, xem §3 |
| Viền | Không viền đen; mép sáng nhạt ở đường/bãi, vật thể tách nền bằng tương phản giá trị | Không outline đen; dùng rim light |
| Tách lớp | Nền cỏ trơn, khung cây/đá rìa, đường, bãi đất, nhà, xe, người tách thành layer riêng | Xuất asset rời để ghép trong Godot |
| Kit đường | Đường, vạch kẻ, mũi tên chỉ hướng, ô đậu "P" có biến thể khóa/mở | Kit đường đua + ô khóa garage |
| Biến thể trạng thái | Xe nâng 5 góc nhìn + trạng thái chở gỗ/hàng; ô khóa/mở | Xe đua nhiều góc + trạng thái |
| HUD | Chip tài nguyên bo tròn có icon 3D bên trái; thanh tiến trình có mốc; thẻ nhiệm vụ trắng; nút thưởng vàng; thanh đáy 4 nút vuông bo + 1 CTA tím lớn có bộ đếm; badge đỏ thông báo | HUD mới, xem §5 |
| Icon | Icon dạng "huy hiệu" tròn viền vàng, hình 3D bên trong; nhãn giảm giá hình tag | Icon offer/booster |
| Wireframe | Sơ đồ khối (đường vào/ra, nhà, trạm làm việc, kho đệm, mũi tên luồng hàng) | Ta vẽ sơ đồ tương tự cho hub, xem §4 |

## 2. Hướng nghệ thuật cho Pitlane Club

Một câu: **"Khu đội đua đồ chơi bóng bẩy"** — toy-like, isometric, bão hòa, ánh sáng ấm, xe đua nhìn như mô hình sơn bóng.

Nguyên tắc:

1. Isometric 2:1 (góc 26,57°), ô lưới cơ sở 128×64 px ở bản gốc 2x. Mọi khối đặt trên lưới này.
2. Ánh sáng cố định từ trên-trái; bóng đổ xuống dưới-phải, màu `#2E4A1F` độ mờ 35% trên cỏ, `#1B1F2A` 35% trên nhựa đường.
3. Ba mức giá trị: sáng (mặt trên) / giữa (mặt trái) / tối (mặt phải). Không dùng gradient phức tạp ngoài bevel.
4. Không viền đen. Tách nền bằng giá trị và rim light 2 px màu sáng hơn 15%.
5. Mỗi asset đọc được ở 48 px chiều cao (icon) và 160 px (xe) trên màn 390 logical px.
6. Xe đua của người chơi luôn nổi nhất khung: màu chủ đạo bão hòa nhất và có nhãn "Bạn" (không dựa vào màu đơn thuần, như [UI 3.1](01_UI_Design.md)).
7. Nội dung gốc: không dùng thương hiệu xe/đội/tay đua thật; logo đội là hình học đơn giản.

## 3. Bảng màu (đề xuất, cần chốt bằng mẫu thử)

| Vai trò | Hex | Dùng cho |
|---|---|---|
| Nền cỏ | `#96BC4F` | Mặt nền diorama |
| Cỏ tối / bóng cây | `#5E8F2E` | Rìa, tán cây |
| Nhựa đường | `#5B6573` | Đường đua, đường nội bộ |
| Vạch / mép sáng | `#D9E8A0` | Vạch kẻ, rim đường |
| Đất bãi | `#B98A5B` | Pit area, bãi đậu |
| Đỏ đội (xe người chơi) | `#E23B34` | Xe chính, mái nhà garage |
| Xanh dương | `#2F6FD6` | Mái, kính, xe đội 2 |
| Vàng thưởng | `#FFC53D` | Tiền, nút nhận thưởng, cúp |
| Tím CTA | `#8A3FE0` | Nút hành động chính (Đua) |
| Cam cảnh báo | `#FF8A1F` | Badge, tăng tốc |
| Trắng thẻ | `#FFFFFF` | Thẻ, nền chip |
| Chữ đậm | `#1F2733` | Chữ trên thẻ trắng |

Tám màu xe AI chọn từ hue cách nhau ≥ 40°, giữ độ bão hòa 70–85%; mỗi xe có thêm sọc/số để không phụ thuộc màu.

## 4. Chuyển "sơ đồ nhà máy" thành sơ đồ khu đội đua

File tham khảo có sơ đồ khối: đường vào → tòa nhà → trạm làm việc → kho đệm → đường ra. Tương ứng:

| Tham khảo | Pitlane Club | Chức năng game |
|---|---|---|
| Nhà chính | **Garage chính** | Tab Garage, nâng xe |
| Nhà xưởng 1/2/3 | **Xưởng Động cơ / Lốp / Khung gầm-Hộp số** | 4 bộ phận nâng cấp |
| Trạm làm việc + kho đệm | **Ô bay (bay slot)** có thể khóa/mở | Cơ sở cấp 0–20, thu nhập/giây |
| Nhà máy khác | **Học viện tay đua** | Tab Tay đua |
| Trực thăng + bãi H | **Bãi trực thăng nhà tài trợ** | Quà ngày / thu nhập vắng mặt |
| Xe nâng chạy vòng | **Xe kéo/xe tiếp liệu** chạy loop | Chuyển động idle làm sống khu |
| Công nhân | **Thợ máy** 3 pose | Hoạt ảnh bay slot |
| Đường nội bộ có mũi tên | **Đường pit + vạch hướng** | Nối các tòa nhà |
| Biển rìa cây/đá | **Hàng rào, lốp xếp chồng, cây** | Lấp rìa |

Hai màn dùng diorama riêng:

- **Hub (tab Đua nền + Garage):** diorama khu đội, cuộn/zoom nhẹ.
- **Đường đua:** diorama track, giữ góc nhìn toàn đường, **không camera bám xe** (đã chốt, xem bộ nhớ [[race-feel-direction]]).

> **Quyết định cần duyệt D-A1:** track dùng isometric thật hay top-down 2D như hiện tại? Khuyến nghị: **track 3/4 tilt (nén chiều dọc 0,6)**, đường chạy vẫn là polyline 2D trong `track.json`, xe là sprite 16 hướng xoay được. Isometric đầy đủ buộc dựng lại hệ tọa độ mô phỏng và hit-test, rủi ro cao cho lợi ích thấp.

## 5. Danh mục asset

Kích thước theo bản gốc 2x. Định dạng PNG có alpha (atlas khi nhập Godot); icon có thêm bản SVG nếu vẽ phẳng.

### 5.1. Môi trường

| ID | Asset | Kích thước | Ghi chú |
|---|---|---|---|
| ENV-01 | Nền cỏ lát được | 512×512 | Lát không thấy ranh, 2 biến thể |
| ENV-02 | Khung rìa cây/đá/núi | 1920×1920, alpha | Đặt trên nền, như tham khảo |
| ENV-03 | Cây thông 3 cỡ, bụi, đá 3 cỡ | 96–192 px cao | Bóng đổ cùng hướng |
| ENV-04 | Kit đường đua: thẳng, cua 45°/90°, hairpin, vạch xuất phát, kerb đỏ-trắng | ô 256×128 | Ghép theo path |
| ENV-05 | Mũi tên hướng, vạch DRS/đoạn thẳng, ô P khóa/mở | 64–128 px | Biến thể khóa/mở |
| ENV-06 | Bãi đất, bãi pit, hàng rào, lốp xếp chồng, cờ | 128–512 px | |
| ENV-07 | Khán đài, biển quảng cáo (nội dung gốc), cổng | 384–768 px | Mỗi track 1 chủ đề |

### 5.2. Công trình hub

| ID | Asset | Kích thước | Màu chủ đạo |
|---|---|---|---|
| BLD-01 | Garage chính (3 mức nâng cấp trực quan) | 512×448 | Mái đỏ |
| BLD-02 | Xưởng Động cơ | 384×352 | Mái xanh dương |
| BLD-03 | Xưởng Lốp | 384×352 | Vàng |
| BLD-04 | Xưởng Khung gầm / Hộp số | 384×352 | Cam |
| BLD-05 | Học viện tay đua | 448×416 | Trắng-xanh nhạt |
| BLD-06 | Bãi trực thăng + trực thăng | 272×200 / 224×212 | Vàng |
| BLD-07 | Bay slot mở / khóa / đang nâng cấp | 256×128 | Đất + ô gạch |

### 5.3. Xe và nhân vật

| ID | Asset | Số lượng | Ghi chú |
|---|---|---|---|
| CAR-01 | Xe đua người chơi | 16 hướng × 1 màu | 160 px dài; tham khảo xe nâng 5 góc nhìn |
| CAR-02 | Xe AI | 7 màu × 16 hướng | Có số xe trên mũi; sinh bằng recolor |
| CAR-03 | Trạng thái xe: nâng cấp, hư/lỗi, về đích, tăng tốc | 4 overlay | Dùng cho sự kiện vượt/lỗi |
| CAR-04 | Xe hub (kéo/tiếp liệu) | 3 góc | Chạy loop |
| CHR-01 | Tay đua An / Bình / Chi: avatar tròn 3D + toàn thân đứng | 3 + 3 | Ba silhouette khác nhau |
| CHR-02 | Thợ máy: đứng, vặn, bê | 3 pose × 2 áo | Cỡ 48–64 px cao |
| CHR-03 | Người hâm mộ nền | 4 biến thể | Cực nhỏ |

### 5.4. UI/HUD (thay SVG Workshop GP)

| ID | Thành phần | Mô tả |
|---|---|---|
| UI-01 | Chip tài nguyên | Nền xanh đậm bo tròn, icon 3D chồm trái, số trắng. Tiền, gem, cấp đội |
| UI-02 | Thanh tiến trình mùa | Thanh có mốc tròn (chặng 1–5), mốc đang tới sáng, mốc cuối là cúp |
| UI-03 | Thẻ nhiệm vụ | Nền trắng bo 24, thanh tiến độ xanh lá |
| UI-04 | Nút nhận thưởng | Vàng, icon tiền 3D, chữ "NHẬN THƯỞNG" |
| UI-05 | Nút CTA chính | Tím, cao 48+, đổ bóng dưới; trạng thái thường / nhấn / khóa / đang chạy |
| UI-06 | Thanh đáy 5 tab | Nút vuông bo 110 px, icon 3D, badge đỏ; tab hiện tại sáng và nâng lên |
| UI-07 | Badge/tag | Giảm giá, "Bạn", cảnh báo, thông báo |
| UI-08 | Panel/dialog | Trắng bo 28, header màu, nút đóng tròn |
| UI-09 | Huy hiệu icon tròn | Viền vàng, hình 3D bên trong (booster, quà, đua) |

### 5.5. Icon (3D mini, 128×128, đọc được ở 48)

Tiền, gem, cúp, huy chương 1–3, động cơ, lốp, khung gầm, hộp số, cơ sở, tay đua, giải đấu, cửa hàng, nhiệm vụ, cài đặt, quà, bản đồ/lịch, đồng hồ, mũi tên nâng cấp, khóa.

### 5.6. VFX và âm thanh

VFX giữ 6 hiệu ứng cũ nhưng vẽ lại theo palette mới: vượt, lỗi, tăng tiền, nâng cấp, về đích, confetti. Âm thanh Workshop GP có thể giữ; chỉ đổi nếu tông không hợp, việc này tách khỏi đợt art.

## 6. Quy cách kỹ thuật

- Bản gốc 2x, xuất 1x/2x. Atlas ≤ 2048×2048 cho mỗi nhóm để giữ bộ nhớ Android thấp.
- Pivot đặt tại điểm chạm đất giữa đáy; tên file `nhóm_tên_biếnthể.png`.
- Nén: Godot import ETC2/ASTC cho di động; kiểm tra viền alpha để không lộ halo.
- Xe 16 hướng: render từ một khối nguồn rồi xoay 22,5°; nếu sinh bằng AI thì phải dựng từ 1 sprite chuẩn và recolor bằng mask, không sinh riêng từng hướng (sai lệch).
- Thứ tự vẽ (y-sort): nền → đường → bóng → vật thể sắp theo y.

## 7. Quy trình sản xuất đề xuất

1. **Spike phong cách (1–2 ngày):** 1 xe, 1 garage, 3 icon, 1 chip HUD, ghép thành mockup màn Đua 886×1920. Duyệt palette và ánh sáng.
2. **Khóa style guide:** đóng băng palette, hướng sáng, độ dày rim, bevel.
3. **Sản xuất theo nhóm:** CAR → UI/HUD/icon → hub → track → VFX. Mỗi nhóm có bảng kiểm trước khi qua nhóm sau.
4. **Tích hợp Godot:** copy vào `assets/lumber_style/` (không ghi đè `workshop_gp/`), thêm catalog mới, đổi theme theo từng màn, chạy lại ảnh chụp 320×568 / 360×800 / 412×915.
5. **QA:** độ tương phản chữ, vùng chạm ≥ 44 px, nhận diện xe người chơi khi không có màu, hiệu năng atlas.

Công cụ: có thể sinh ảnh nháp bằng generator hình ảnh, nhưng bản cuối cần họa sĩ/chỉnh tay để đồng nhất. Prompt mẫu cho xe (đã dùng ngôn ngữ gốc, không nhắc game khác):

```text
isometric toy-like race car, glossy 3D-rendered look, saturated red body, white racing stripe,
number 01 on nose, soft top-left light, rim highlight, soft shadow bottom-right,
transparent background, no black outline, clean game asset, 3/4 view
```

## 8. Rủi ro và quyết định cần duyệt

| ID | Vấn đề | Khuyến nghị |
|---|---|---|
| D-A1 | Track isometric thật hay 3/4 tilt | 3/4 tilt, giữ polyline 2D (§4) |
| D-A2 | Nguồn art: sinh AI + chỉnh, hay thuê họa sĩ | AI cho nháp, họa sĩ cho bản cuối |
| D-A3 | Bản quyền: file tham khảo có ảnh dạng sinh AI/asset thương mại | Không dùng lại; chỉ tham khảo |
| D-A4 | Chi phí số lượng: ~16 hướng × 8 xe | Recolor bằng mask; xe AI dùng 8 hướng nếu thiếu thời gian |
| D-A5 | Chữ trong HUD (tham khảo dùng chữ trắng viền đậm) | Dùng font có dấu tiếng Việt, kiểm tra độ rộng |

Chưa làm: chưa dựng mockup, chưa sinh ảnh, chưa sửa `ui/` hay `assets/`.
