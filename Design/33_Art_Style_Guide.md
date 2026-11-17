# 33. Art Style Guide — Glossy Casual Cartoon

Ngày 17/11/2026 · **Đề xuất thiết kế, chưa triển khai trong Godot.**

## 1. Phạm vi và nguồn

Chốt phong cách hình ảnh chung cho toàn game, rút từ các concept đã được duyệt:

- `Design/Concepts/RookiePack_Popup_v1/1_cartoon_garage.png` (popup Gói Tân binh)
- `Design/Concepts/StyleTest_v2_data_accurate/` (`race_tab.png`, `shop_top.png`, `shop_bottom.png`)

Tài liệu này **chỉ quy định ngôn ngữ hình ảnh** (hình khối, ánh sáng, màu, chữ, icon). **Không đổi** cấu trúc màn hình, luật gameplay, giá hay số liệu. Layout vẫn theo [17](17_Layout_Asset_Redesign.md), Shop theo [14](14_Shop_Integration.md) và [28 §5](28_IAP_Packs.md).

Các concept là ảnh AI gen liền khối. Chúng dùng để chốt hướng nhìn, không phải asset đưa thẳng vào game. Hex ở §3 là giá trị lấy mẫu từ ảnh nên chỉ là **xấp xỉ**; khi sản xuất asset thật phải chốt lại bằng token cuối cùng.

## 2. Nguyên tắc cốt lõi

1. **Mập, tròn, dễ chạm.** Mọi panel, nút, thẻ bo góc lớn; không có góc nhọn trong UI.
2. **Viền dày cùng tông, không viền đen.** Viền là phiên bản đậm hơn của màu nền (nút xanh lá → viền xanh lá đậm).
3. **Bóng kẹo (glossy).** Highlight trắng cong ở nửa trên, mép dưới tối hơn; gradient mềm, không chuyển gắt.
4. **Một màu cho một nghĩa.** Mỗi loại tiền tệ, hành động, trạng thái có màu cố định xuyên suốt mọi màn.
5. **Chủ đề đua xe qua chi tiết nhỏ**: cờ caro, vạch xanh–cam trên xe, nhãn số xe; không dùng chi tiết thừa che nội dung.
6. **Đọc được trước, đẹp sau.** Vùng chứa số liệu dùng nền sáng và chữ navy; hiệu ứng bóng/rực chỉ ở khung, nút, art.

## 3. Bảng màu

Hai nhóm. Nhóm "Đọc" lấy từ [17 §3](17_Layout_Asset_Redesign.md) và **giữ nguyên** cho vùng chứa chữ/số. Nhóm "Art" là màu nhấn bão hòa hơn của concept, dùng cho khung, nút, icon.

### 3.1 Nền và chữ (giữ theo 17 §3)

| Vai trò | Hex | Ghi chú |
|---|---|---|
| Nền trang | `#DCEBFF` | Concept lấy mẫu gần `#E2F4FE` |
| Panel/thẻ | `#E4EFFF` | Concept lấy mẫu gần `#D6EFFD` |
| Chữ chính | `#16355C` | Navy; dùng trên mọi thẻ sáng |
| Chữ phụ | `#5A7294` | Tối thiểu 12 px |
| Lỗi/đóng | `#C62828` | Nút đóng dùng đỏ bóng |

### 3.2 Token màu nhấn đã chọn — phương án A "Royal Blue" (17/11/2026)

Người dùng đã chọn phương án A (giống concept đã duyệt). Giá trị là **đề xuất để chốt**, chưa phải màu lấy mẫu từ ảnh; khi tạo asset phải đối chiếu lại với ảnh concept.

| Token | Hex | Dùng cho |
|---|---|---|
| `blue_primary` | `#1E6FE8` | Header mục, tab đang chọn, viền panel |
| `blue_deep` | `#0C3A8B` | Thanh điều hướng đáy, dải đua |
| `orange_accent` | `#FF9A1F` | Sọc xe, ribbon, vạch đồ đua, điểm nhấn |
| `green_action` | `#22C03C` | Nút mua, Nâng, Nhận, banner kết quả tốt |
| `green_action_edge` | `#12862A` | Viền/chữ viền của nút xanh lá (bắt buộc cho chữ trắng) |
| `purple_gem` | `#8A3FE0` | Gem và mọi nút trả bằng gem |
| `gold` | `#F5B800` | Huy hiệu `x2`/`x4.4`, ribbon "FIRST TIME", cúp |
| `red_danger` | `#E53935` | Nút đóng, cảnh báo |

Chữ trắng trên `green_action` có độ tương phản thấp, nên **luôn có viền `green_action_edge`**. `blue_primary` và `red_danger` khác nhóm nền/chữ ở §3.1 vì đây là màu của art, không dùng cho chữ đọc số liệu.

Hai phương án không chọn (lưu để tham khảo): **B** khớp tài liệu 17 (`#2F6FE0`, `#15803D`, `#D96A00`); **C** kem–cam ấm (nền `#FFF4E0`, xanh `#1F5FD0`, cam `#FF8A00`).

Quy tắc màu:
- **Tiền mặt = xanh lá**, **gem = tím**, **vé/Pro = xanh dương**, **vé Standard = xanh lá**. Không đổi giữa các màn.
- **Nút trả bằng tiền thật = xanh lá**; **trả bằng gem = tím**. Hai loại này không hoán đổi.
- **Cam chỉ là điểm nhấn** (không dùng làm nền diện rộng); nếu màn nào xanh dương chiếm gần hết, thêm cam/vàng ở một điểm, không tô lại cả khung.
- Màu trạng thái "chưa mở/Sắp có": xám xanh nhạt + nhãn chữ, không chỉ bằng màu.

## 4. Hình khối, viền, bóng

| Thành phần | Quy tắc |
|---|---|
| Góc | Panel 16, thẻ 12 (theo 17 §3); nút bo tròn hoàn toàn (pill) |
| Viền | Dày 2–3 px logical, **cùng tông** màu nền nhưng đậm hơn; không viền đen |
| Gradient | Sáng ở trên → đậm hơn ở dưới, chênh nhẹ; không gradient nhiều màu |
| Highlight | Một vệt trắng cong mờ ở nửa trên nút/vật phẩm |
| Bóng đổ | Mềm, ngay dưới vật; không bóng cứng kiểu cắt |
| Chiều sâu nút | Mép dưới dày hơn 2–4 px, thể hiện nút "nổi" |
| Nền art lớn | Giảm chi tiết sau vùng có chữ; không đặt chữ lên vùng nhiễu |

## 5. Typography

- **Font hiển thị đã chọn: Baloo 2** (ExtraBold/Bold) cho tiêu đề, nút, số lớn. Chữ trong concept là chữ AI vẽ mô phỏng, không phải Baloo 2, nên hình dáng thật sẽ hơi khác.
- **Chưa kiểm tra:** bộ glyph tiếng Việt của Baloo 2 và giấy phép (Baloo 2 phát hành theo SIL OFL; cần xác nhận bản tải về). Font **chưa có trong project**; hiện chỉ có `assets/clean_modern/fonts/Roboto-*.ttf`.
- **Font dự phòng cho 8 ngôn ngữ** (`i18n/`: en, vi, id, ms, th, ja, ko, zh_Hans): Baloo 2 chỉ chắc phủ Latin/Việt; Thái, Nhật, Hàn, Hoa cần font dự phòng như Noto Sans Thai và Noto Sans CJK. Chưa thử cài dự phòng trong Godot.
- Chữ nhỏ trong thẻ (mô tả, caption) dùng font dễ đọc hơn Baloo 2 nếu thấy nặng ở 12 px; cần thử trên màn 320 × 568.
- **Tiêu đề/nhãn nổi bật** (tên gói, nút lớn): chữ trắng, viền navy đậm, đổ bóng nhẹ.
- **Vùng đọc số liệu** (thẻ sáng): chữ navy `#16355C`, không viền, không bóng. Theo 17 §3: chữ trắng có viền chỉ dùng trên art/header/nav.
- Cỡ chữ theo 17 §3: chính 14–16, tiêu đề 20–24, phụ ≥12.
- Số lượng/giá nằm trong pill tương phản (xanh đậm hoặc nút màu theo §3.2).

## 6. Thành phần UI

- **Header mục (SPECIAL, GEM…)**: pill xanh dài, icon tròn bên trái, chữ trắng viền navy.
- **Nút hành động chính**: pill xanh lá bóng, chữ trắng viền xanh lá đậm; chỉ một nút chính mỗi vùng nhìn.
- **Nút phụ**: nền nhạt, viền xanh mảnh, chữ xanh.
- **Nút gem**: pill tím + icon gem; giá nằm cùng nút.
- **Thẻ vật phẩm**: nền sáng, một vật phẩm chính 64–88 px, tên trên cùng, giá dưới cùng.
- **Huy hiệu**: vàng, hình tròn/ribbon, chữ đậm ngắn (`x2`, `FIRST TIME x2`).
- **Tab/selector**: segmented control bo tròn; mục đang chọn xanh đặc, mục khác nhạt.
- **Thanh điều hướng đáy**: xanh đậm, tab đang chọn là ô xanh sáng có viền sáng; icon 30–36 px + nhãn.
- **Banner trạng thái**: pill dài; kết quả tốt xanh lá, kèm icon cúp.

Trạng thái nút (theo 28 §5): sẵn sàng → `Đang xử lý…` → `Đã sở hữu` / `Mai mở lại` / `Còn N ngày` / `Chờ thanh toán` / `Không có kết nối`. Nút khóa dùng xám xanh + nhãn chữ.

## 7. Icon và vật phẩm

- Phong cách 3D-cartoon cách điệu: khối đơn giản, highlight rõ, **một vật chính trong mỗi icon**.
- Nền icon (nếu có) là ô vuông bo tròn nền xanh nhạt; vật không bị cắt.
- Tỷ lệ phóng đại nhẹ để đọc được ở 48 px.
- Icon chức năng phải đúng nghĩa: động cơ = động cơ, lốp = lốp, khung gầm = khung gầm, hộp số = bánh răng (xem [17 L01](17_Layout_Asset_Redesign.md): không dùng icon sai mục đích).
- Gem: tinh thể tím hồng, số lượng nhiều thì xếp chồng/rương. Tiền: xấp tiền xanh lá. Vé: hình vé xanh dương có vương miện (Pro) hoặc xanh lá có sao (Standard).

## 8. Xe, nhân vật, bối cảnh

- **Xe**: thân trắng, sọc cam, chi tiết xanh dương; số xe lớn trên cửa. Render 3D-cartoon, không photoreal.
- **Nhân vật**: tỉ lệ chibi nhẹ, đầu lớn, mắt to; đồng phục xanh dương–cam. Chốt thiết kế riêng cho nhân vật chính, không dùng gương mặt từ mỗi lần gen (xem §10).
- **Bối cảnh**: garage, khán đài, đường đua sáng, bầu trời trong; không đưa xe/vật gắn sẵn vào nền khi có sprite thật (17 L01).
- **Track trên màn Đua**: nhìn nghiêng từ trên, viền đỏ–trắng, cỏ xanh; xe người chơi có vòng sáng cam + nhãn `YOU`.

## 9. Prompt mẫu cho image gen

Khối prompt nền (dán đầu mọi prompt):

```text
Glossy casual mobile game art, stylized 3D-cartoon render, thick rounded shapes,
soft gradients with white specular highlights, thick same-hue outlines (no black
outlines), royal blue / orange / glossy green palette, light blue-white panels
with navy text, rounded bold sans-serif lettering with white fill and dark-blue
stroke, racing theme (checkered flags, white-orange race car with number),
friendly chibi-proportion characters. Racing team idle-tycoon game UI.
```

Quy trình gen cho một màn:
1. Đọc tài liệu thiết kế của màn (17, 14, 28…) và liệt kê **đúng thứ tự phần tử**.
2. Dán prompt nền + mô tả layout từng khối theo đúng thứ tự đó.
3. Thêm dòng cấm cụ thể (ví dụ "NO big Race button", "no countdown timers, no fake discounts").
4. Ghi trong mockup số nào là số minh họa.
5. Kiểm tra ảnh đầy đủ độ phân giải, đối chiếu với tài liệu, rồi mới đưa cho người duyệt.

## 10. Vấn đề cần chốt trước khi áp dụng

1. **Xác minh Baloo 2.** Đã chọn Baloo 2 nhưng chưa tải về kiểm glyph tiếng Việt, giấy phép và độ đọc ở 12 px; chưa chọn font dự phòng cho Thái/Nhật/Hàn/Hoa.
2. **Token màu.** Đã chọn phương án A (§3.2) nhưng hex là giá trị đề xuất, chưa đối chiếu lại với ảnh concept; cần xác nhận khi sản xuất asset.
3. **Nhân vật chính.** Chưa có thiết kế gốc; gen lại mỗi lần sẽ cho gương mặt khác nhau.
4. **Hợp với art hiện có.** Game đang dùng `assets/workshop_gp` và Racing UI HD; chưa quyết định thay dần hay giữ song song. Xem backlog [18](18_Asset_Backlog.csv).
5. **Mật độ chi tiết.** Hero art có nhiều chi tiết; cần kiểm tra khả năng đọc ở màn 320 × 568.
6. **Chưa kiểm thử trong Godot.** Concept chưa được thử trên thiết bị/tỷ lệ thật.

## 11. Bước tiếp theo đề xuất

1. Tải Baloo 2, kiểm glyph tiếng Việt/giấy phép, thêm font dự phòng; xác nhận token màu A (mục 10.1–10.2).
2. Sản xuất asset rời: nút, panel, header mục, thanh nav, 8 icon upgrade, icon tiền tệ/vé; kích thước theo 17 §3.
3. Thử một màn nhỏ trong Godot trước (Shop hoặc popup Gói Tân binh) để xem style có chịu được scale 9-slice.
4. Gen các màn còn lại (Revenue, Túi, Đội, Giải) theo quy trình §9.
