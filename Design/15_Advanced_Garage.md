# Garage chuyên sâu — mua xe, phụ tùng và ngoại hình

Ngày: 10/11/2026. Trạng thái: **thiết kế đề xuất và mockup tương tác, chưa tích hợp Godot**.

**Triển khai Godot (10/11/2026):** Đội có hai mục con Tay đua/Garage. Garage gồm Xe · Phụ tùng · Ngoại hình và bộ sưu tập mở từ Đổi xe (`ui/garage_page.gd`, `ui/car_preview.gd`). `data/garage_cosmetics.json` chứa 8 màu + 4 decal; save lên v6 với `garage_cosmetics`; nâng cấp xe dự bị qua `GameState.buy_many_for(car_id, …)`; snapshot lượt đua lưu `paint_id`/`decal_id`. Test: `tests/garage_test.gd`. Chưa có: năm thân xe khác nhau theo hạng (dùng chung một thân xe), decal chi tiết trong đua (chấm xe chỉ hiện họa tiết rút gọn), QA native nhiều cỡ màn.

## 1. Tham khảo Race Star và giới hạn bằng chứng

Yêu cầu: hoàn thiện thiết kế Garage có mua/chọn xe, phụ tùng, màu sơn và decal. Các quy tắc chi tiết bên dưới là phương án cho Pitlane Club; không coi là cơ chế đã trích xuất từ game gốc.

| Bằng chứng đọc ngày 10/11/2026 | Xác nhận được | Không xác nhận được |
|---|---|---|
| [Google Play chính thức](https://play.google.com/store/apps/details?id=com.coolcatsgames.racestaridle), mục Garage | Sưu tầm phương tiện, tăng sức mạnh bằng Vehicle Parts, tùy chỉnh màu và decal | Cách mua xe, nguồn Parts, số ô, giá, trần cấp, công thức |
| [App Store chính thức](https://apps.apple.com/us/app/race-star-team-manager-game/id6782871814), lịch sử 1.2.1 | Garage, Vehicle Parts, màu/decal; hồ sơ có mục Garage và BXH hiện xe trang bị | Không chứng minh bố cục Garage hiện tại hoặc các bonus cụ thể |
| [Website nhà phát triển](https://www.gryphon.games/) | Garage thuộc vòng lặp quản lý đội và nâng phương tiện | Không có đặc tả kinh tế Garage |
| Bốn ảnh Google Play đã mở và xem, lưu ở [References/Garage](References/Garage/README.md) | Đường đua top-down, xe/chấm màu trên circuit | Các ảnh này **không chụp màn Garage**; không dùng chúng để suy ra bố cục Garage |

Video tham chiếu cũ không tải được trong lần nghiên cứu này. Chưa chơi trực tiếp bản gốc. Vì vậy **chưa thể khẳng định thiết kế dưới đây giống nguyên bản về bố cục**. Khi có ảnh/video Garage thực tế, đối chiếu lại thứ tự khu vực, cách chọn xe, màn Parts và trình chỉnh màu; không tự gán wireframe đề xuất thành ảnh tái dựng bản gốc.

Hướng giữ lại từ tham chiếu: sưu tầm → chọn phương tiện → tăng sức mạnh → cá nhân hóa → thấy xe đó trong cuộc đua. Không tự mở rộng sang sáu bộ môn, gacha xe, hợp nhất xe hoặc bonus sưu tầm chưa có thiết kế.

## 2. Nền hiện hành và quyết định thiết kế

Đã đọc `data/cars.json`, `ui/main.gd`, `game/game_state.gd`, `core/economy/pricing.gd` và tài liệu 11–14:

- Điều hướng hiện tại: **Đua · Đội · Giải · Shop**. Đội đang chứa tay đua và danh sách xe; không khôi phục thanh năm tab trong tài liệu UI cũ.
- Có 15 xe, năm hạng × ba biến thể; mua/chọn đã có API. Mua xe không tự chọn. Cấp bốn bộ phận lưu riêng từng xe.
- Bốn phụ tùng Động cơ/Lốp/Khung gầm/Hộp số đã có nâng cấp 0–200 bằng coins, mỗi cấp +0,2; mua ×1/×10/×Max, D=3 theo tài liệu 13.
- Save hiện là v5. Chưa có dữ liệu màu/decal riêng từng xe trong GameState đã đọc.
- Trang bị tay đua ở tài liệu 14 là hệ thống riêng; không dùng chung vật liệu hoặc ô trang bị.

**Chốt cho bản thiết kế này:** Garage là nơi quản lý xe sâu hơn; bốn ô phụ tùng biểu diễn chính bốn nâng cấp xe hiện có. Không thêm một lớp bonus Parts thứ hai chồng lên +0,2/cấp. Cách diễn giải này tương thích kinh tế dự án, nhưng chưa chứng minh tương đương Vehicle Parts của Race Star. Kho phụ tùng rời để lắp/tháo, độ hiếm và mảnh Parts là mở rộng chưa thiết kế, không được ngầm đưa vào lúc lập trình.

## 3. Kiến trúc màn hình và bố cục

Vào **Đội → Garage**. Đội có hai mục con Tay đua/Garage. Garage có ba mục **Xe · Phụ tùng · Ngoại hình**; Bộ sưu tập mở từ nút Đổi xe. Không thêm tab toàn cục.

Thứ tự từ trên xuống:

1. Thanh coins/gem cố định, giữ quy tắc định dạng BigNumber hiện hành.
2. Tiêu đề Garage, xe đang dùng và nhãn trạng thái lượt.
3. Khu trưng bày xe 2D, tên/hạng/đặc tính và nút Đổi xe. Không giả vờ hỗ trợ xoay mô hình 3D.
4. Ba mục cục bộ; nội dung đổi tại chỗ, giữ xe đang xem.
5. Tóm tắt thay đổi trước/sau và CTA đúng ngữ cảnh.
6. Thanh điều hướng bốn tab hiện hành.

```text
┌────────────────────────────────────┐
│ 120K coins                 100 gem │
│ Đội                 Tay đua/Garage │
│ GARAGE                   [Đổi xe] │
│ Pico Tia chớp · Hạng 1            │
│         [xe trên sàn xưởng]        │
│ Đang dùng · thay đổi từ lượt sau   │
│ [Xe] [Phụ tùng] [Ngoại hình]       │
│ Tốc độ 54,0     Bám đường 44,0     │
│ Ổn định 42,0    Tăng tốc 40,0      │
│                                    │
│ Nội dung theo mục đang mở          │
│ So sánh từng chỉ số · điều kiện    │
│           [Hành động chính]        │
│ Đua       Đội       Giải      Shop │
└────────────────────────────────────┘
```

Wireframe là đề xuất. Phong cách Workshop GP đã chọn: kem #F3EBDD, graphite #25282C, cam #ED742B; xe là trọng tâm, tránh trang trí nhiều hơn thông tin. Header tài nguyên và nav cố định khi triển khai native; phần giữa cuộn. CTA đặt sau thông tin cần đọc, không che nội dung.

Màn thiết kế 390 logical px, kiểm thêm 320/360/412. Vùng chạm ≥44 px, nội dung ≥14 px, phụ ≥12 px. Màn thấp giảm khu trưng bày từ khoảng 180 xuống 120 px, không thu nhỏ chữ. Tên xe xuống dòng; giá dài xem được chi tiết đầy đủ. Trạng thái dùng chữ và dấu chọn, không chỉ màu. Preview tương tác trong chat để nội dung chảy dọc theo khung chat; không mô phỏng scroll/safe area của thiết bị.

## 4. Bộ sưu tập, mua và chọn xe

### Danh mục kế thừa

| Hạng | Dòng | Ba biến thể | Bậc mở mua |
|---|---|---|---:|
| 1 | Pico | Tia chớp / Bám đường / Bền bỉ | 0 |
| 2 | Nova | Tia chớp / Bám đường / Bền bỉ | 2 |
| 3 | Apex | Tia chớp / Bám đường / Bền bỉ | 3 |
| 4 | Titan | Tia chớp / Bám đường / Bền bỉ | 4 |
| 5 | Zenith | Tia chớp / Bám đường / Bền bỉ | 5 |

Dùng nguyên ID, base, `entry_tier`, giá trong catalog hiện có; không tăng giá theo số dư. Pico khởi đầu miễn phí; hai Pico còn lại 2.500/5.000 coins. Giá các hạng sau lấy Pricing, không chép cứng giá rút gọn từ UI vào giao dịch.

Bộ sưu tập dạng lưới hai cột; mỗi thẻ có ảnh, tên, hạng, Đang dùng/Đã có/Chưa mua/Khóa. Lọc Tất cả/Đã có; nhóm theo hạng. Chạm thẻ chỉ **xem**, không mua hoặc chọn ngay. Xe chưa sở hữu vẫn xem chỉ số và ngoại hình mặc định, nhưng không chỉnh hoặc nâng.

Panel so sánh lấy xe được xem với cấp thật nếu đã sở hữu, cấp 0 nếu chưa mua; đối chiếu xe đang chọn cho lượt kế, không đối chiếu chỉ số nền trừ khi bật nhãn rõ. Hiện đủ S/H/B/A và chênh lệch +/−. Không rút thành điểm sức mạnh tổng hay hứa chắc chắn thắng.

| Trạng thái | CTA / phản hồi |
|---|---|
| Chưa mua, đủ điều kiện/coins | Mua [giá] → xác nhận tên, giá, ví còn lại; không tự chọn |
| Thiếu coins | CTA khóa, ghi thiếu bao nhiêu; vẫn xem được |
| Khóa tiến trình | Ghi tên giải cần mở; quyền mua dùng `unlocked_tier`, không dùng riêng bậc đang kinh doanh |
| Đã có, hợp lệ | Dùng xe này; miễn phí, giữ cấp và ngoại hình riêng |
| Đang chọn cho lượt kế | Đang dùng; không tạo giao dịch thừa |
| Hạng thấp hơn mức giải hiện tại | Vẫn xem/chỉnh ngoại hình; khóa chọn đua và ghi hạng tối thiểu |
| Save lỗi / đang giao dịch | Khóa thao tác ghi, hiển thị lý do; giữ quyền xem |

Không bán xe, không mua trùng, không tính phí đổi xe, không chuyển cấp từ xe cũ sang xe mới. Nút nâng xe hạng thấp không hợp lệ tại giải hiện tại được khóa để tránh chi tiêu vô ích; vẫn giữ dữ liệu cấp cũ. Mua xe mới tạo bốn cấp 0, màu cam/decal trống mặc định.

## 5. Phụ tùng và nâng cấp

### Bốn ô cố định trên mỗi xe

| Ô | Chỉ số | Nội dung chi tiết |
|---|---|---|
| Động cơ | S — Tốc độ | Nền + 0,2 × cấp; lợi ích đoạn thẳng |
| Lốp | H — Bám đường | Nền + 0,2 × cấp; lợi ích đoạn cua |
| Khung gầm | B — Ổn định | Nền + 0,2 × cấp; dùng công thức sim hiện hành |
| Hộp số | A — Tăng tốc | Nền + 0,2 × cấp; dùng công thức sim hiện hành |

Cấp 0 nghĩa là bộ phận tiêu chuẩn đã lắp, không phải xe thiếu động cơ/lốp. Mỗi ô hiện tên, cấp/200, chỉ số hiện tại; chọn một ô mở chi tiết. Mua ×1/×10/×Max là điều khiển chung của màn; CTA hiện đúng **số cấp thực mua**, tổng giá và kết quả. ×10 gần trần mua phần còn lại nếu đủ tiền; thiếu tiền cho số cấp mục tiêu thì khóa, dùng ×Max để mua ít hơn. Không tự chuyển sang mua một cấp.

```text
stat(part) = base_car[part] + 0,2 × level(part)
g = 1,45^(1/10)
K = tổng(g^j), j = 0..9
cost(m→m+1) = S(entry_tier) × ceil(120 × Q(entry_tier) × 3 × g^m / K)
cost_bulk = tổng từng giá cấp đã làm tròn
```

Dùng Pricing/BigNumber thực tế làm nguồn chuẩn. ×Max tìm số cấp đủ tiền, tối đa 200−cấp hiện tại; tính lại lúc commit. Không dùng số hiển thị rút gọn để so ví. Bốn mục doanh thu tiếp tục ở màn Đua; không hiện chúng như phụ tùng xe. Đây vẫn là tám nâng cấp trong toàn game, không phải thêm bốn mục thứ chín trở đi.

Ví dụ so sánh có thể kiểm tra: Pico Tia chớp ở cấp Động cơ/Lốp/Khung/Hộp số = 40/30/20/10 có S54/H44/B42/A40. Pico Bám đường cấp 0 là S38/H46/B38/A38; đổi xe làm −16/+2/−4/−2. Màu/decal không tham gia phép tính này.

### Xe đang xem và xe đang đua

- Nâng xe dự bị không tự chọn xe đó. Chi tiết ghi rõ tên xe nhận cấp.
- API nâng hiện tại dựa vào `active_car_id`; khi triển khai cần giao dịch nhận **car_id tường minh**, không tạm đổi xe active chỉ để nâng xe dự bị.
- Nâng nhanh trên màn Đua và màn Garage dùng cùng dữ liệu/giao dịch. Đổi xe khi panel nâng đang mở phải làm mới giá, cấp và chênh lệch.
- Max cấp: hiện Cấp tối đa, không giá giả hoặc nút còn hoạt động. Thiếu tiền, hạng không hợp lệ và lỗi save có thông báo riêng.

## 6. Ngoại hình — màu sơn và decal

Đề xuất bản đầu: **tám màu và bốn decal đều miễn phí**, không tăng chỉ số. Mục tiêu là hoàn chỉnh thao tác tùy biến trước khi thiết kế kinh tế mỹ phẩm. Không tiêu gem, không thêm shop mỹ phẩm hoặc phần thưởng sưu tầm ngầm.

| Loại | Danh mục ban đầu | Quy tắc |
|---|---|---|
| Màu | Cam, Đỏ, Xanh dương, Vàng, Trắng, Graphite, Xanh ngọc, Tím | Một màu thân, giữ bánh/kính/bóng; dùng tám màu từ asset hiện có |
| Decal | Trống, Sọc đôi, Tia chớp, Ô bàn cờ | Một mẫu toàn thân, vị trí/kích thước cố định; thay mẫu cũ |

Mỗi xe giữ `paint_id` và `decal_id` riêng. Không có kéo/thả decal, đổi màu decal, tải ảnh cá nhân, logo thật, text tự do hay nhiều lớp trong bản đầu. Decal cần asset mới; tám màu hiện có không đồng nghĩa đã có hệ decal.

Luồng: chọn màu/decal → xem trực tiếp trên xe → **Lưu ngoại hình**. Chọn mẫu chỉ đổi bản nháp. Hủy trở lại ngoại hình đã lưu; rời màn/đổi xe khi có bản nháp mở Lưu/Bỏ thay đổi/Ở lại. Nút Lưu chỉ bật khi có thay đổi và save hoạt động; thông báo thành công sau khi ghi thành công. Không mất bản nháp chỉ vì tiền hoặc thưởng đua cập nhật.

Xe chưa sở hữu chỉ xem mặc định, CTA dẫn về Mua xe. Xe sở hữu nhưng không đủ hạng đua vẫn chỉnh được. Xe đang đua giữ ngoại hình snapshot đến hết lượt; khu trưng bày hiện cấu hình mới và ghi Áp dụng từ lượt sau. Viền/nhãn “Bạn” trong race luôn còn, kể cả chọn màu trùng đối thủ.

## 7. Hiệu lực, giao dịch và trạng thái lỗi

Quy tắc thống nhất cho chọn xe, phụ tùng và ngoại hình: **lượt nào đã tạo snapshot thì giữ nguyên đến kết thúc**. Khi đang racing, thay đổi áp dụng lượt kế. Trong countdown, thay đổi trước lúc tạo snapshot áp dụng lượt sắp bắt đầu. Đọc snapshot thực tế để ghi nhãn; không chỉ kiểm tra tab hay đồng hồ.

Nếu xe active đã đổi nhưng snapshot vẫn là xe cũ, UI tách “Đang đua: …” và “Lượt kế: …”. Phép so sánh mua/chọn dùng xe lượt kế. Mở Garage, collection hay xác nhận mua không dừng đua; phần thưởng tiếp tục được chốt bình thường, không đè bản nháp ngoại hình.

Mỗi mutation: kiểm tra ID/quyền sở hữu/tiến trình/giá → giữ bản trước → cập nhật ví/cấp/lựa chọn/ngoại hình → ghi save → báo thành công. Lỗi ghi phục hồi toàn bộ và giữ nội dung người chơi đang xem. Khóa chạm lặp trong commit, hàng đợi chung với settlement lượt và mở cơ sở; kiểm tra lại trạng thái giải khi lệnh thực thi. Nếu mở cơ sở làm xe dự kiến không đủ hạng, hủy chọn xe đó với lý do cụ thể.

## 8. Art và dữ liệu bàn giao

- Tái sử dụng theme Workshop GP và atlas tám màu. Hiện các màu là biến thể art; **không đủ để thể hiện năm hình dáng xe khác nhau**. Cần năm thân xe khác biệt hoặc ít nhất silhouette rõ từng hạng, không dùng màu để giả thành hạng.
- Chuẩn bị năm bộ thân xe × tám màu + ba lớp decal không trống. Cùng pivot, canvas và hướng mũi giữa tất cả lớp; decal cắt theo thân, không phủ bánh/kính. Cần bản lớn cho garage và bản đọc được ở kích thước race; đánh giá decal ở race trước khi hứa nhìn rõ.
- Bốn icon phụ tùng, trạng thái khóa/đang dùng, sàn garage đơn giản. Preview dùng minh họa sơ đồ 2D, không phải art cuối hay ảnh game gốc.
- Chỉ số lấy catalog + cấp, không lấy tên sprite. Danh mục ngoại hình có ID ổn định, tên dịch, texture và màu tương phản decal cố định.

Đề xuất `data/garage_cosmetics.json`; không thay catalog xe/giá kinh tế trong đợt này. Bổ sung save tối thiểu:

```json
{
  "garage_cosmetics": {
    "car_pico_tia_chop": {"paint_id": "orange", "decal_id": "none"}
  }
}
```

Giữ `owned_cars`, `active_car_id`, `car_levels` hiện có. Bản nháp chỉ tồn tại trong UI, không ghi save. Migration từ v5 lên version trống kế tiếp **sau khi kiểm tra lại version lúc lập trình**; tài liệu trang bị tay đua cũng đang dự kiến v6 nên không giành cứng version. Save cũ gán ngoại hình mặc định, không reset tiền/cấp, không phát quà. ID cosmetic không còn tồn tại thì fallback mặc định có log; lỗi sở hữu/cấp dùng luồng phục hồi save hiện hành.

Race snapshot mới lưu `car_id` và ngoại hình resolved; checkpoint cũ không có cosmetic dùng mặc định cố định cho phần lượt còn lại. Không sửa snapshot stats cũ hoặc phát lại thưởng khi migration.

## 9. Mockup và phạm vi nghiệm thu

Mockup tương tác đi cùng câu trả lời: ba mục Garage, xem bộ sưu tập, so sánh, mua/chọn xe, bốn phụ tùng, mua nhiều cấp, màu/decal, lưu/hủy bản nháp. Fixture độc lập: 120.000 coins, 100 gem, quyền mở bậc 0; hai Pico đầu đã sở hữu, xe thứ ba mua được, Nova trở lên khóa. Pico Tia chớp cấp 40/30/20/10; Pico Bám đường cấp 0. Mọi thao tác chỉ đổi dữ liệu preview, không đọc/ghi save Godot. Không giả lập đua hoặc tự cộng thưởng.

Kiểm tra mockup ngày 10/11: JavaScript qua `node --check`; chạy logic bằng Node VM với DOM giả đã qua các luồng chỉ số fixture, xác nhận mua/trừ tiền, không tự chọn, chặn mua trùng, chọn xe, nâng nhiều cấp, cảnh báo bản nháp/bỏ thay đổi, lưu màu/decal và chặn mua xe khóa. Chưa kiểm tra render bằng trình duyệt, Godot hoặc thiết bị. Ví preview dùng số nhỏ của fixture; đây không phải bản triển khai BigNumber dùng cho runtime.

Tiêu chí khi triển khai:

- Mua một lần đúng giá; không tự chọn; mua trùng, thiếu tiền, khóa giải và chạm kép không mất tiền. Chọn đúng điều kiện hạng, giữ cấp riêng khi đổi qua lại.
- Chênh lệch ví dụ §5 chính xác; nâng dự bị không đổi active; hai màn nâng hiển thị cùng cấp/giá; ×10/Max gần cấp 200 và BigNumber cao không vượt trần hoặc âm ví.
- Màu/decal không thay S/H/B/A, thu nhập, thời lượng hay kết quả sim. Preview/Lưu/Hủy và cảnh báo rời màn hoạt động; reload giữ ngoại hình từng xe.
- Mua/đổi/nâng/lưu khi racing hoặc countdown không sửa snapshot đã tồn tại. Lượt sau dùng dữ liệu mới; save lỗi và settlement đồng thời không nhân đôi/trừ mất tài nguyên.
- Kiểm tra migration cùng tính năng equipment khi có, checkpoint cũ, thiếu asset và save backup. Không chạy test trên save người dùng.
- QA native ở 320×568, 360×800, 390×845, 412×915: safe area, cuộn, touch, tên dài, dấu Việt, giá rất lớn, disabled và modal. Mockup chat không thay thế kiểm thử này.

Thứ tự triển khai dự kiến: catalog cosmetic/art → giao dịch nâng nhận car_id + save/snapshot → Garage/Bộ sưu tập → Ngoại hình → QA runtime. Lập trình và cân bằng mới chưa được thực hiện trong nhiệm vụ thiết kế này.

## 10. Quan hệ với tài liệu cũ

Tài liệu này đề xuất thay UI Garage trong 01/06 và cách truy cập xe ở trang Đội, giữ nền kinh tế 12–13 và đua liên tục 10. Không ghi đè tài liệu cũ hoặc tự chuyển trạng thái tính năng thành đã phát hành. Sau khi duyệt, cập nhật các mục UI/phạm vi tương ứng; tài liệu 14 về equipment không bị nhập vào Garage.
