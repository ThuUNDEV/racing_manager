# 17. Thiết kế lại layout và kế hoạch asset

Ngày 11/11/2026 · **Đề xuất thiết kế, chưa triển khai giao diện Godot.**

## 1. Mục tiêu và nguồn đối chiếu

Thiết kế nơi dùng asset trước khi sản xuất thêm: mỗi hình phải có màn hình, kích thước hiển thị, trạng thái và chức năng cụ thể. Dùng Racing UI HD làm phong cách chủ đạo: cartoon thể thao, khối xanh, hành động cam, phần thưởng vàng, nhận quà xanh lá. Giữ artwork Workshop GP tương thích; chuyển dần hình lệch phong cách theo backlog.

Đối chiếu source hiện tại: `ui/main.gd`, `hd_ui.gd`, `gear_page.gd`, `driver_roster_page.gd`, `garage_page.gd`, `shop_page.gd`; catalog `data/drivers.json`, `cars.json`, `gear.json`; manifest và resource của hai bộ art. Không dùng screenshot preview cũ làm bằng chứng giao diện hiện tại. Chưa chạy game/QA native trong lượt thiết kế này.

Hiện có **5 tab Đua · Túi · Đội · Giải · Shop**, khung đua ghim trên các trang; 12 tay đua, 15 xe, 30 phụ kiện. Một số tài liệu UI cũ ghi 4 tab hoặc trang bị lắp theo tay đua đã lỗi thời. Tài liệu này ưu tiên cấu trúc hiện tại và không thay luật gameplay, giá, xác suất, save hay cách tính chỉ số.

## 2. Chẩn đoán

| Hiện trạng từ source | Tác động | Quyết định layout |
|---|---|---|
| Đua ghim nguyên khối ở trên mọi tab | Vùng quản lý bị ngắn, khó thấy nội dung chính | Đua lớn tại tab Đua; các tab khác dùng dải đua thu gọn, chạm để trở lại Đua |
| Khung HD nhưng nhiều card dùng nền phẳng riêng | Cùng một ứng dụng có nhiều ngôn ngữ hình ảnh | Một hệ panel/button, chỉ đổi phân cấp, không đổi skin từng trang |
| Engine dùng energy, tyre dùng gear, chassis dùng crane, gearbox dùng research | Hình không giải thích chức năng | Thay bằng 4 icon phụ tùng chính xác; các icon cũ giữ đúng mục đích nếu có |
| Gear hiển thị tên và số, chưa có hình món | Kho thiếu điểm nhận diện và động lực sưu tầm | Hình món là trọng tâm; chi tiết số chuyển sang sheet |
| Có 12 tay đua nhưng portrait resource mới có An/Bình/Chi | Nhân vật sau dùng fallback, khó phân biệt | 12 portrait riêng; không tạo portrait bằng đổi màu người cũ |
| 15 xe nhưng chưa có 5 thân xe riêng theo hạng | Khó cảm nhận tiến trình nâng hạng | 5 thân xe; 3 biến thể mỗi thân bằng màu/decal |
| Shop có nhiều nội dung chưa giao dịch thật | Thứ tự ưu tiên bị lẫn với quà nhận được | Quà ngày lên đầu; nội dung chưa có gắn “Sắp có”, không CTA mua giả |

## 3. Khung chung và kích thước

Thiết kế chuẩn 390 × 844 logical px, kiểm 320 × 568, 360 × 800, 412 × 915. Tọa độ dưới đây tính trong safe area, không cộng vùng notch/home indicator.

| Khối | Cao ở 390 × 844 | Hành vi |
|---|---:|---|
| Tài nguyên | 64 | Avatar 40, coins + thu nhập, gem, settings; đứng yên |
| Đua trên tab Đua | 248 | Tiêu đề chặng 32 + track 192 + trạng thái 24; không cuộn theo danh sách nâng |
| Đua trên tab khác | 52 | Cờ + vị trí + thời gian + nhãn “Đang đua”; chạm về Đua |
| Điều hướng đáy | 72 | 5 ô bằng nhau, icon 30–36 + nhãn 12–13; vùng chạm từng ô ≥44 |
| Nội dung quản lý | Phần còn lại | Một vùng cuộn dọc, không lồng scroll |

Lề 16 (320 px: 12), khoảng 8/12/16/24; góc panel 16, thẻ 12. Chữ chính 14–16, tiêu đề 20–24, chữ phụ ≥12. Giá và chỉ số không bị cắt; tên dài xuống tối đa 2 dòng trước khi mở chi tiết. Header: ở 320 px giảm avatar còn 32 và coins/gem chữ 14, thu nhập thành dòng riêng; nút settings vẫn 44.

Màn thấp: track tab Đua giảm xuống 144; dải đua tab khác 44; header 56; nav 64. Giữ nội dung cuộn và cỡ chữ, không thu cả màn. Đây là thay đổi layout được đề xuất: cuộc đua vẫn tiếp tục nền; không thêm nút điều khiển chiến thuật hay chọn chế độ ga.

Palette sản phẩm: nền #DCEBFF, panel #E4EFFF, chữ #16355C, chữ phụ #5A7294, xanh #2F6FE0, cam #D96A00, nhận #15803D, lỗi #C62828. Không đưa gradient trang trí vào vùng đọc số. Chỉ dùng chữ trắng có viền trên art/header/nav; nội dung card dùng chữ navy.

## 4. Layout từng tính năng

### L01 — Đua và nâng cấp nhanh

Thứ tự: tài nguyên → chặng/mùa + Lịch → track → vị trí/thời gian/stamina → banner kết quả → selector Xe đua/Doanh thu → danh sách nâng → nav. Track là khu vực chính; xe người chơi có vòng đánh dấu và nhãn, không chỉ phân biệt màu. Kết quả là banner không chặn lượt mới; Chi tiết mở snapshot đã chốt.

Hàng nâng: icon 48 bên trái; tên + cấp + chỉ số hiện tại→sau ở giữa; CTA giá rộng tối thiểu 96 bên phải; selector ×1/×10/×Max dùng chung cho danh sách. Bốn nâng xe và bốn nâng doanh thu giữ nguyên; chia hai mục để giảm chiều dài. 320 px: giá chuyển xuống hàng cuối nếu cần. Không gán tiền cho “Nâng” trong mockup thành giá gameplay mới.

Asset: `workshop_gp/textures/workshop_oval.png` cho sân đang hỗ trợ; bộ `cars/*.tres` cho sprite; HD flag/first_place/cash; panel_body, hud_bar, button_race/upgrade. Thêm A01–A04 (icon đúng phụ tùng). Nền `racing_ui_hd/backgrounds` chỉ là minh họa: không thay collision/path bằng ảnh có xe gắn sẵn.

### L02 — Doanh thu

Chung khung Đua, chuyển selector sang Doanh thu. Đầu vùng cuộn là thu nhập/giây và dòng “Nâng áp dụng theo luật hiện tại”; bên dưới 4 hàng: Tiếp thị vé, Ăn mừng chiến thắng, Bãi đỗ, Khán đài. Mỗi hàng minh họa 64 + tên/cấp/hiệu quả hiện tại→sau + giá; không giả lập thành bản đồ xây dựng có đặt công trình.

Asset giữ cash/crown/garage/seats trong giai đoạn đầu. Thêm A05–A08 là bốn minh họa công trình/hoạt động, dùng cả hàng nâng và màn mở cơ sở. Không cần nhiều hình cho 200 cấp: thay thanh tiến độ và dữ liệu chữ.

### L03 — Túi trang bị

Dải đua thu gọn → tiêu đề Túi + sở hữu n/30 → bonus toàn đội (kiếm/khiên có nhãn) → selector Bộ sưu tập/Mở gói. Mặc định Bộ sưu tập, lưới 3 cột ở ≥360; 320 px dùng 2 cột. Thẻ chứa hình 64, tên 2 dòng, độ hiếm bằng chữ + viền, level/sao và tiến độ mảnh. Không nhét nút nâng và mọi chỉ số vào thẻ nhỏ.

Chạm món mở sheet: hình 128, tên/rarity, level, bonus hiện tại→sau, mảnh có/cần, nút Nâng bằng mảnh. Món chưa có: silhouette cùng vị trí ảnh + “Chưa sở hữu”. Đủ mảnh: badge “Có thể nâng”. Max: “Cấp tối đa”, không thanh tiến độ giả. Sao thể hiện level; nếu vượt chỗ hiển thị thì ghi Lv. n, không chốt trần 5.

Mục Mở gói: Standard/Elite xếp dọc, mỗi panel có hình gói 88, mô tả, coupon đúng loại, nút thông tin tỉ lệ, x1/x10 và phương thức thanh toán cụ thể. Không chuyển gear sang cơ chế lắp/tháo. Thanh toán hiển thị kết quả từ API hiện tại; không tự thêm bù coupon bằng gem. Kết quả mở là sheet lưới, nhãn “Mới”/“Trùng → +n mảnh”, Tổng bonus, Đóng. Không thêm pity cho gear.

Asset cần: A09–A38 (30 món đúng ID), A39–A42 (2 gói + 2 coupon), A43–A44 (kiếm/khiên). Có thể tái dùng star_gold/empty; silhouette được sinh từ alpha của mỗi món, không vẽ 30 hình mới.

### L04 — Đội / Tay đua

Dải đua → Tay đua/Garage → thẻ tay đua đang chọn (portrait 72, tên, phong cách, level, trạng thái lượt sau) → selector Danh sách/Tuyển → danh sách theo trạng thái hiện có. Mỗi hàng portrait 56, tên, hai chỉ số nổi bật, Đang dùng/Đã tuyển/Khóa. Không gộp bảy chỉ số thành điểm sức mạnh cam kết thắng.

Sheet chi tiết: portrait 112, tên/phong cách, 7 hàng Launch/Speed/Braking/Cornering/Racecraft/Composure/Endurance; mỗi hàng có số hiện tại và chênh lệch so với tay đua đang chọn. CTA đúng trạng thái: Dùng tay đua/Tuyển [chi phí]/Nâng [chi phí]/Khóa + điều kiện. Ảnh không che số. Tách chọn và mua.

Mục Tuyển giữ cả SP và gói tay đua đang có trong source: panel SP + điều kiện tuyển xác định; bên dưới 2 gói có coupon, tỉ lệ và bảo đảm lấy từ cấu hình. Không chuyển bảo đảm tay đua sang gear.

Asset: giữ An/Bình/Chi tạm thời; A45–A53 bổ sung 9 portrait thiếu. A54–A56 đồng bộ lại 3 portrait cũ sau, không chặn vòng đầu. A57–A60: 4 phong cách dùng badge nhỏ. Chưa cần 7 icon chỉ số: chữ và thanh ngang đã đủ rõ.

### L05 — Garage / Xe và bộ sưu tập

Dải đua → Tay đua/Garage → tên xe/hạng + Đổi xe → khu trưng bày 176 → Xe/Phụ tùng/Ngoại hình → nội dung → CTA theo xe đang xem. Dùng render 3/4, sàn showroom riêng, bóng riêng. Không vẽ nút xoay khi chỉ có sprite 2D.

Mục Xe: 4 chỉ số dạng 2×2 và so sánh với xe đang chọn. “Đang dùng” chỉ cho xe được chọn; mua xong không tự chọn. Xe dự bị hiển thị trạng thái rõ. Chỉ dùng nhãn “Lượt sau” tại thao tác thực sự có hiệu lực từ lượt sau.

Bộ sưu tập mở toàn vùng nội dung: lưới 2 cột, ảnh 112×72, tên/hạng/Đã có/Chưa mua/Khóa. Chạm xem trước, sheet đủ giá + ví còn lại + điều kiện + xác nhận. Xe không hợp lệ với giải: khóa chọn đua theo luật hiện tại, ghi lý do.

Asset: icon HD car_red dùng placeholder bố cục; A61–A65 là 5 thân Pico/Nova/Apex/Titan/Zenith, không dùng một hình xe cho cả 15 mẫu khi phát hành. 3 biến thể/hạng dùng màu/decal theo catalog, không thêm thân riêng. A66: sàn showroom không có xe vẽ sẵn.

### L06 — Garage / Phụ tùng

Giữ preview xe nhỏ 120; bốn ô phụ tùng 2×2, mỗi ô icon 48 + tên/cấp. Chạm ô đổi panel chi tiết bên dưới, không mở giao dịch. Chi tiết: chỉ số hiện tại→sau, cấp, ×1/×10/×Max, số cấp sẽ mua, tổng giá, Nâng. Đây là cách nhìn khác của cùng 4 nâng cấp ở tab Đua; dùng chung dữ liệu và không tạo tồn kho phụ tùng rời.

Asset tái dùng A01–A04, không tạo thêm 4 bộ tranh khác. Max/thiếu tiền/đang ghi save đều có chữ, không chỉ đổi màu.

### L07 — Garage / Ngoại hình

Preview xe 176 → Sơn/Decal → swatch 44 + tên màu → decal tile 56 → thanh “Chưa lưu” + Bỏ thay đổi/Lưu ngoại hình. Chọn swatch chỉ đổi bản xem trước. Rời xe/tab khi có bản nháp: giữ quy tắc xử lý draft hiện tại. Không gắn stat hoặc giá mới cho sơn/decal.

Màu dùng dữ liệu, không xuất 8 ảnh nguyên chiếc. A67–A69: 3 decal Sọc đôi/Tia chớp/Ô bàn cờ trong catalog, dạng mask alpha; phải có bản giản lược trên sprite đua. Lựa chọn Trống không cần art; A70 là bóng xe tách lớp dùng chung. Asset car_red hiện là minh họa có sơn gắn sẵn nên không đáp ứng đổi sơn thật; mockup chỉ trình bày vị trí và bảng chọn, không giả vờ là render cuối.

### L08 — Giải / Mùa và mở cơ sở

Dải đua → huy hiệu + tên giải/mùa → điểm hiện tại/mục tiêu và progress → timeline chặng → thẻ mở cơ sở → bảng quy đổi vị trí dạng mở rộng. Chặng hiện tại tô nền + chữ Đang đua, chặng xong hiện vị trí/điểm, chặng sau ghi Chưa tới. Danh sách chỉ là xem lịch, không bấm bỏ qua chặng.

Thẻ cơ sở: hình 128×80 + điều kiện còn thiếu + chi phí + Xem mở cơ sở. Sheet xác nhận giải đích/chi phí/thời điểm áp dụng. Không thiết kế BXH các đối thủ khi source chưa có dữ liệu mùa của họ. Không thêm thumbnail ba track để ám chỉ đã có chọn track.

Asset: giữ badges/rookie/semi_pro/pro, medals; A71–A75: 5 vignette cơ sở theo bậc, không phải 5 map gameplay. Dùng placeholder huy hiệu cho bậc chưa có art riêng, nhãn tên giải vẫn là dữ liệu.

### L09 — Shop

Dải đua → Shop → Quà hằng ngày (hero 88 + nội dung thưởng thật + Nhận) → selector Gói/Tiền tệ → danh mục. Những offer chưa tích hợp nằm dưới, badge “Sắp có”, nút chỉ xem mô tả. Không dùng timer đếm ngược, giá giảm hoặc “Best value” khi không có dữ liệu.

Quà ngày đứng riêng một hàng toàn chiều rộng; offer rộng 100%; gem/coins lưới 2 cột (320 px 1 cột nếu giá dài). Ưu tiên một vật phẩm chính 64–88 mỗi card, bỏ tranh nền quá nhiều chữ. Hiển thị giá thật chỉ khi có nguồn giao dịch; mockup không hiện giá VND dự kiến như giá đang bán. Các panel gói chưa có không che quà đã nhận được.

Asset: tái dùng atlas shop_icons và resource `shop/icons/*.tres` (daily_reward, gear_crate, driver_helmet, gem, cash_*...), không yêu cầu vẽ lại toàn bộ. A76–A77: hai key art Standard/Elite tay đua nếu art cũ không phân biệt được; gear dùng A39–A40. Offer thương mại chỉ sản xuất thêm banner khi nội dung đã chốt.

### L10 — Kết quả chặng / Mùa

Banner tại Đua: vị trí + tiền + điểm + Chi tiết, không chặn tự chạy. Sheet: cúp 80, vị trí/chặng, tiền/điểm/SP từ snapshot, danh sách kết quả thực tế; Đóng. Mùa: huy hiệu, điểm/mục tiêu, trạng thái thăng hạng, thưởng đã chốt. Không ghi “Nhận” nếu phần thưởng đã cộng. Kết quả cũ không đổi theo lượt đang chạy.

Tái dùng trophy/first_place, medals, confetti/reward_burst và audio cũ. Không cần một tranh mới cho từng vị trí; thay số, badge và màu nhấn.

### L11 — Offline / Quà ngày / Mở gói

Offline: money_bag 96 → thời gian được tính + mức giới hạn hiện tại → tổng thưởng → Nhận theo logic đang có. Chỉ thêm x2/x3 khi có hành động thực. Quà ngày: gift 96 → danh sách thưởng → Nhận/Đã nhận. Mở gói: hình món/tay đua, Mới hoặc số mảnh trùng, Đóng. Dùng chung reward sheet; mỗi loại giữ hành vi giao dịch riêng.

Giữ tiền/gem là Label riêng, không ghi vào ảnh. Ưu tiên tái dùng `workshop_gp/rewards/money_bag.tres`, `daily_gift.tres` và shop daily_reward. Không sản xuất thêm ba nền modal riêng.

### L12 — Cài đặt / Hướng dẫn / Loading / Trạng thái hệ thống

Cài đặt mở sheet: Nhạc/Âm thanh/Rung/Giảm chuyển động theo tùy chọn thực có; toggle 44, nhãn luôn rõ. Onboarding là callout 2 dòng cạnh hành động đang hướng dẫn + Tiếp/Bỏ qua, tối đa một spotlight; chỉ làm khi flow được triển khai. Loading dùng nền/car hiện có, progress và trạng thái đọc được, giữ báo lỗi/Thử lại. Trạng thái rỗng/khóa/lỗi lưu dùng icon + lý do + hành động phù hợp, không chỉ ảnh minh họa.

Tái dùng controls toggle/checkbox, gear, SVG check/lock/help, tutorial hand và assets/startup_loading. Trạng thái focus/pressed/disabled làm bằng theme; không cần bộ PNG riêng cho từng màn.

## 5. Quy tắc phối và sản xuất asset

- UI surface HD là nguồn thống nhất: panel_body 9-slice; hud_bar cho tài nguyên; button_race cho hành động chính; claim cho nhận; cancel cho đóng/hủy. Kiểm mép cắt trên ảnh gốc trước khi chốt slice, không kéo dãn cả ảnh.
- Tranh vật thể: góc 3/4 nhất quán, ánh sáng trên trái, bóng mềm tách lớp, tỷ lệ đồ chơi thể thao, không chữ, không số, không UI đóng sẵn. Xem ở kích thước nhỏ trước khi xuất lớn.
- Icon UI không viền trắng dạng sticker dày nếu không cần; chỉ giữ contour đồng nhất với pack HD. Nền transparent, padding khoảng 10–12%, vật thể chiếm ~76–80% khung, không cắt bánh xe/mũ.
- Tên, giá, cấp, rarity, thanh tiến độ, sao, badge Mới là lớp UI. Không bake vào ảnh.
- Mỗi asset trong `18_Asset_Backlog.csv` có ID, màn dùng, resource hiện có/fallback, kích thước xuất và ưu tiên. Tất cả là **đề nghị sản xuất**, chưa có file art mới.
- Source có layer + PNG RGBA sRGB. UI 512×512, gear 512×512, portrait 512×512; kiểm alpha trên nền xanh nhạt và navy. Dùng mipmap cho texture thu nhỏ mạnh theo cấu hình đích; không tự bật cho mọi UI.
- Xe: body neutral 1024×640 + mask màu chính/phụ/decal/bóng; sprite top-down 256×256 cùng nhận diện. Preview và sprite đua là 2 góc nhìn, không thể dùng chung một render 3/4.
- Decal: mask 512×512 và phiên bản thu gọn đọc ở xe đua 20–32 px. Lưu anchor/UV theo từng thân, tránh trượt khi đổi xe.
- Gói/coupon có hình và chữ UI phân biệt Standard/Elite, không chỉ khác màu. Rarity cũng có nhãn chữ.
- Không sao chép art từ hình tham khảo Race Star. Không tạo asset cho gameplay mới chưa được yêu cầu.

## 6. Thứ tự sản xuất

| Đợt | Nội dung | Lý do |
|---|---|---|
| P0 | 4 icon phụ tùng; 30 gear; 2 gear pack; 2 coupon; kiếm/khiên; 9 portrait thiếu | Thay ký hiệu sai và bù đối tượng đang có dữ liệu nhưng chưa có hình |
| P1 | 5 thân xe + sprite đua; showroom; 3 decal + bóng xe; 4 hình doanh thu | Làm Garage có tiến trình thị giác và nâng cấp có ngữ nghĩa |
| P2 | Đồng bộ 3 portrait cũ; 4 style badge; 5 vignette cơ sở; 2 gói tay đua | Hoàn thiện nhận diện, không chặn đọc/chọn/nâng |

P0 gồm 49 mục art; P1 gồm 14 mục (mỗi thân xe có cả 3/4 và top-down); P2 gồm 14 mục. 77 dòng backlog là **77 mục sản xuất**, không phải 77 PNG: mask/layer/sprite là deliverable phụ của cùng mục. Chưa ước lượng ngày công khi chưa duyệt một mẫu style và pipeline xe.

Pilot trước sản xuất hàng loạt: engine + Balaclava + một portrait mới + thân Pico. Đặt cả bốn vào mockup để kiểm mức chi tiết/góc nhìn/viền. Sau đó mới làm đủ catalog. Nên hoàn thiện P0 và màn core trước banner thương mại.

## 7. Tiêu chí duyệt thiết kế

1. Mỗi màn có đối tượng chính, thao tác chính và asset được chỉ định rõ; không còn icon cần người chơi đoán chức năng.
2. 320/360/390/412 px không tràn ngang, không cắt giá, nav đủ 5 tab, vùng chạm ≥44, trạng thái có chữ.
3. Tab Đua ưu tiên xem đua; Túi/Đội/Giải/Shop ưu tiên quản lý nhưng còn trạng thái lượt đang chạy.
4. Không thay cơ chế sở hữu gear toàn đội, SP/coupon, bốn nâng xe, cấp/config, mua rồi chọn hoặc thời điểm áp dụng.
5. Kiểm asset gốc, alpha, render thu nhỏ, tên dài, thiếu tiền, locked, max, pending/save error, coupon thiếu và kết quả mở trùng.
6. Mockup chỉ dùng số minh họa và điều hướng cục bộ; không kiểm chứng gameplay, giao dịch hoặc lưu dữ liệu.

## 8. Bàn giao

- `Mockups/layout_asset_redesign.html`: bản xem bố cục nhiều màn, có điều hướng và sheet; dùng ảnh hiện có, không phải screenshot game đã sửa.
- `18_Asset_Backlog.csv`: danh sách sản xuất cụ thể đến ID món/tay đua/xe, có fallback và kích thước.
- Không sửa `ui/`, `game/`, `data/`, scene hay asset hiện có. Các thông số layout là đề xuất để duyệt trước khi triển khai.

### Kiểm tra bản xem thử

Đã kiểm 15 view × 4 chiều rộng 320/360/390/412 px: không tràn ngang, không ảnh lỗi, không lỗi JavaScript; đã thử mở/đóng chi tiết món và đổi lựa chọn màu. Đã xem ảnh render Garage và Túi ở 390 px. Báo cáo: `Mockups/layout_review_assets/validation.json`.

Mockup ở mức duyệt bố cục: dùng màu/ảnh hiện có, surface CSS giản lược, chưa tái tạo pixel đầy đủ skin 9-slice. Gear dùng ký hiệu giữ chỗ vì chưa có art món. Các trang chi tiết/giao dịch được mô phỏng cục bộ; không xác nhận số mẫu là cân bằng thật. Bản trong chat để nội dung chảy dọc, không mô phỏng chiều cao viewport, sticky hay cuộn của Godot. Kích thước và hành vi ghim ở §3 là đặc tả triển khai, cần QA native sau.
