# Racing Manager — Thiết kế v1.0: UI/UX

> **Cập nhật nhịp đua 09/11/2026:** [10 — Đua liên tục theo thời gian](10_Continuous_Race_Loop.md), đặc biệt §6–7, thay CTA bắt đầu/tiếp tục, bộ đếm vòng 1/3, khóa nâng cấp và panel kết quả/tổng kết bắt buộc trong tài liệu này. UI mục tiêu tự countdown 3 giây, hiển thị giờ còn lại và kết quả không chặn lượt sau; chưa triển khai.

Ngày: 09/11/2026. Trạng thái: đề xuất để duyệt. Mở rộng [01 UI v0.2](01_UI_Design.md) cho bản phát hành. Đi cùng [04 Gameplay](04_Gameplay_Release.md) và [05 Kinh tế](05_Economy_Monetization.md).

## 1. Chuẩn màn hình và bố cục

- Thiết kế gốc **886 × 1920 px** (tỉ lệ ≈ 9:19,5), engine co giãn hệ số 2,27 nên layout tính theo ≈ **390 × 845 logical px**. Kích thước dưới đây là logical px.
- Kiểm tra thêm: 360×800, 412×915, 320×568 (thấp), 393×852 (iPhone thường), máy tính bảng.
- Chừa safe area (tai thỏ, thanh điều hướng, đảo động). Lề cạnh 16, nhịp 4/8/12/16/24.
- Máy tính bảng và màn hình rộng: nội dung giữ khung dọc tối đa 600 logical px, hai bên là nền trang trí; không kéo giãn bố cục.
- Chữ nội dung 14–16, nhãn phụ ≥ 12, giá trị chính 20–28. Tùy chọn cỡ chữ 100% / 115% / 130%; layout không tràn ở 130%.
- Vùng chạm ≥ 44×44, nút chính ≈ 48–52. Nút hành động chính đặt ở **ba phần tư dưới** màn hình để dùng một tay.
- Chỉ một CTA chính mỗi trạng thái. Thanh đáy và tài nguyên cố định; nội dung dài cuộn.
- Số lớn rút gọn (12,4K / 3,2M / 1,2B); chạm vào số để xem đầy đủ. Giá nâng cấp không rút gọn nếu gây hiểu nhầm khả năng mua.

## 2. Cấu trúc điều hướng

Thanh đáy 5 tab, thứ tự cố định:

| Tab | Chứa | Ghi chú |
|---|---|---|
| **Đua** | Đua, lịch mùa tóm tắt, nâng cấp nhanh, nhiệm vụ gần xong | Màn mở mặc định |
| **Tay đua** | Danh sách, chi tiết, tuyển, huấn luyện, chọn người đua | |
| **Garage** | Phân tab: Xe · Bộ sưu tầm · Cơ sở | Xe hiện tại, đổi xe, nâng cấp, Trụ sở/Xưởng/Học viện |
| **Giải** | Phân tab: Mùa · Thử thách ngày · Thành tích | Lịch chặng, điểm, danh hiệu |
| **Cửa hàng** | Quà ngày, gói, gem, livery, mở rộng offline | |

Bản dựng thử của concept Workshop GP dùng thanh 6 mục. Quyết định đề xuất: **giữ 5 tab** như trên (D11); nếu muốn 6 mục, mục thứ sáu phải là chức năng thật và có nội dung đủ để không thành tab rỗng.

Lối vào phụ: avatar → Hồ sơ/Cài đặt; số gem → Cửa hàng; biểu tượng nhiệm vụ → panel Nhiệm vụ ngày. Không thêm tab thứ sáu. Huy hiệu đỏ chỉ dùng cho việc đã sẵn sàng hành động (quà ngày, nâng cấp đủ tiền cho mục đang theo dõi, tuyển được), tối đa 1 số/tab, và biến mất khi người chơi đã xem.

## 3. Danh sách màn hình

| ID | Màn hình | Mô tả ngắn | Phiên bản |
|---|---|---|---|
| UI-01 | Đua (trang chủ) | Khung đua, CTA, nâng cấp nhanh theo đặc điểm track | 0.5 |
| UI-02 | Danh sách tay đua | 12 thẻ: đang dùng / sở hữu / có thể tuyển / khóa | 0.8 |
| UI-03 | Chi tiết tay đua | Chỉ số, đặc tính, huấn luyện, nút tuyển/chọn | 0.8 |
| UI-04 | Garage — Xe | Xe đang dùng, 4 bộ phận, so sánh trước/sau | 0.5 |
| UI-05 | Garage — Bộ sưu tầm | Lưới 15 xe, giá, điều kiện, livery | 0.8 |
| UI-06 | Garage — Cơ sở | Trụ sở, Xưởng, Học viện, trần offline | 0.8 |
| UI-07 | Giải — Mùa | 5 chặng, điểm, bảng quy đổi, danh hiệu | 0.5 |
| UI-08 | Thông tin chặng | Track, tỷ lệ thẳng/cua, bộ phận quan trọng, kỷ lục cá nhân | 0.8 |
| UI-09 | Kết quả đua | Vị trí, bảng 8 xe, thưởng, giải thích từ log | 0.5 |
| UI-10 | Tổng kết mùa | Điểm, thưởng, thăng hạng hoặc ở lại | 0.8 |
| UI-11 | Mở giải mới | Giải kế tiếp, xe yêu cầu, thưởng mở giải | 0.8 |
| UI-12 | Thu nhập vắng mặt | Thời gian, rate, hệ số, tiền, nút nhận gấp đôi (nếu bật) | 0.5 |
| UI-13 | Thử thách ngày | Track, hạn chế, bảng xếp hạng, thưởng | 0.9 |
| UI-14 | Nhiệm vụ ngày và thành tích | Danh sách, tiến độ, nhận thưởng | 0.8 |
| UI-15 | Cửa hàng | Quà ngày, gói khởi động, gem, livery, mở rộng offline | 0.9 |
| UI-16 | Xác nhận mua | Món, giá thật, điều kiện; dùng cho gem và tiền thật | 0.9 |
| UI-17 | Hồ sơ | Tên đội, thống kê, danh hiệu, tài khoản nền tảng | 0.9 |
| UI-18 | Cài đặt | Âm nhạc, SFX, rung, giảm chuyển động, cỡ chữ, ngôn ngữ, thông báo, xóa dữ liệu, hỗ trợ, phiên bản | 0.8 |
| UI-19 | Hướng dẫn đầu game | 6 bước, có bỏ qua | 0.8 |
| UI-20 | Đồng ý quyền riêng tư và quảng cáo | Theo khu vực | 0.9 |
| UI-21 | Khôi phục save | Save lỗi, dùng bản sao, xác nhận | 0.8 |
| UI-22 | Đồng bộ đám mây | So sánh hai save, người chơi chọn | 0.9 |
| UI-23 | Chọn livery | Xem trước màu xe trên khung đua | 0.9 |
| UI-24 | Hệ thống thông báo | Toast, lỗi mạng/ads/IAP, cập nhật bắt buộc | 0.9 |
| UI-25 | Loading khởi động | Tiến độ 0–100%, chuẩn bị gameplay và tự chuyển scene; [đặc tả đề xuất](09_Startup_Loading_Design.md), chưa triển khai | Mốc riêng trước bản chơi tiếp theo |

Mỗi màn có đủ trạng thái: mặc định, đang tải, rỗng, lỗi, khóa (kèm điều kiện mở), offline. Wireframe và prototype Figma/mockup cho mọi UI-xx do thiết kế bàn giao ở M3, trước khi dựng.

## 4. Chi tiết các màn thay đổi so với v0.2

### UI-01 — Đua

- Thứ tự giữ như v0.2: tài nguyên, tiến trình mùa, khung đua, thông tin track, CTA, nâng cấp nhanh, một nhiệm vụ.
- **Nâng cấp nhanh nay chọn theo track hiện tại**: hai bộ phận xe có trọng số lớn nhất ở track đó (dữ liệu `weights` của track) cộng Trụ sở. Mỗi ô ghi lý do ("Lốp quan trọng ở chặng này"). Garage chứa đủ 4 bộ phận.
- Khung đua giữ 3 trạng thái: trước (grid), trong (vị trí, vòng, đồng hồ, khoảng cách xe trước), sau (khung hình về đích). Không popup che đường đua.
- Hiển thị xe đang dùng và tay đua đang dùng ở một dòng dưới khung đua; chạm để đổi (tối đa 2 chạm, khi ở trạng thái sẵn sàng).
- Trạng thái nút mua: đủ tiền → mua; thiếu → khóa, ghi "Thiếu N"; tối đa → "Cấp tối đa"; đang đua → bộ phận thi đấu khóa, Cơ sở vẫn mua được.

### UI-02/03 — Tay đua

- Hàng đầu: người đang đua (chân dung, tên, Pace/Technique/Composure, cấp, đặc tính).
- Lưới 12 thẻ: **Đang đua / Đã có / Có thể tuyển (hiện SP cần) / Khóa (điều kiện)**; danh mục công khai nên người chơi lập kế hoạch.
- Chi tiết: mô tả vai trò, chỉ số, đặc tính, xem trước tác động khi chọn (so với tay đua hiện tại, theo từng track).
- Nút "Tuyển" hiện cả SP và tiền; thiếu thì khóa kèm số thiếu. Chọn người chỉ khi sẵn sàng (không trong đua).

### UI-04/05/06 — Garage

- **Xe:** tên xe, hạng, 4 hàng bộ phận (icon, cấp 0–20, chỉ số → mới, giá, mô tả hành vi); nút thông tin hiện giá trị số.
- **Bộ sưu tầm:** lưới 15 xe, nhóm theo hạng; thẻ: ảnh, giá, điều kiện, đã có/chưa; thưởng bộ sưu tầm hiển thị tiến độ.
- **Cơ sở:** ba thẻ (Trụ sở: thu nhập; Xưởng: giảm giá xe; Học viện: giảm giá huấn luyện và SP), ghi rõ nhãn "Kinh tế". Phân biệt rõ với nâng xe bằng màu nhấn vàng và nhãn.
- Đổi xe chỉ khi sẵn sàng; xe không đủ hạng cho giải hiện tại bị khóa kèm lý do.

### UI-09 — Kết quả đua

Như v0.2, thêm: SP nhận được, tiến độ tuyển, kỷ lục cá nhân trên track (nếu phá). Giải thích kết quả chỉ dùng số liệu đo được (lỗi, giây mất do bám xe, vượt xe). Nút quảng cáo phụ xuất hiện chỉ khi SDK sẵn sàng và có quảng cáo; ghi đúng phần tiền cộng thêm.

### UI-12 — Thu nhập vắng mặt

Như v0.2; thêm nút phụ "Nhận gấp đôi" (xem quảng cáo) hoặc tự nhận nếu người chơi có gói Đội tự do. Phần cơ bản luôn ghi trước và không phụ thuộc nút phụ.

## 5. Hướng nghệ thuật

- **Hướng đã chọn: Workshop GP** (xem [Workshop_GP_Asset_Pack.md](Workshop_GP_Asset_Pack.md) và `assets/workshop_gp/`): ảnh 2D mang phong cách render 3D (không có mesh), nền kem, graphite, cam an toàn; garage và đường đua thể thao hiện đại. Đây là bộ asset **v0.1**, chưa thay UI gameplay hiện tại và chưa kiểm tra trên thiết bị; phải duyệt ở kích thước thật trước khi chốt. Chân dung tay đua là minh họa gốc, không dùng hình hoặc thương hiệu thật.
- **Bảng màu và theme:** lấy từ `theme.tres` và palette trong `manifest.json` của bộ Workshop GP, thay cho bảng xanh đậm/cyan của prototype. Vàng chỉ dành cho phần thưởng; đỏ/cam cảnh báo cần tách khỏi màu cam thương hiệu bằng biểu tượng hoặc nhãn. Mỗi giải có một màu nhấn riêng (6 màu) cho tiêu đề và thẻ giải. Mọi cặp chữ/nền đạt tỉ lệ tương phản tối thiểu 4,5:1 (chữ nhỏ) / 3:1 (chữ lớn, biểu tượng); phải kiểm lại trên palette mới vì nền kem.
- **Xe:** bộ hiện có là 8 xe 2D theo 8 màu (cam, graphite, trắng, xanh dương, đỏ, vàng, teal, tím), ảnh dựng sẵn nên **không đổi màu bằng palette trong game**. Với 15 xe, silhouette theo hạng và livery cần thêm art; v1.0 đề xuất mỗi xe một sprite chính, livery là các biến thể màu đã dựng sẵn (không tách lớp). Xe người chơi luôn có viền và nhãn "Bạn" dù trùng màu với AI.
- **Đường đua:** art hiện chỉ có một nền oval (1536×1024) và centerline `workshop_oval_path.json`. **Mỗi track cần nền và centerline riêng, ánh xạ chính xác sang sector và quãng đường của RaceSim** (path hiện chỉ để xem mỹ thuật; không lấy tốc độ preview làm luật thắng thua). Vùng vượt và cua được vẽ chồng bằng nét rõ phía trên nền. Chi phí art của 10 track là rủi ro (03 §5).
- **Chữ:** bộ Workshop GP hiện dùng font mặc định của Godot, không đóng gói font riêng. Với bản chính thức cần font hỗ trợ đầy đủ dấu tiếng Việt trên mọi thiết bị; đề xuất họ font có giấy phép mở (ví dụ Be Vietnam Pro, SIL OFL; xác minh giấy phép trước khi dùng). Hai cỡ đậm/thường để giữ kích thước tệp. Chữ, tiền, cấp và phần trăm luôn do Godot hiển thị, không gắn cứng vào texture (như bộ asset hiện tại).
- **Icon:** một bộ 48 px đồng nhất nét; không dựa chỉ vào màu để phân biệt trạng thái (thêm hình dạng hoặc nhãn).
- **Chuyển động:** ưu tiên giải thích (thanh chỉ số tăng, tiền tăng, xe vượt đối thủ), ≤ 300 ms; tùy chọn Giảm chuyển động tắt hiệu ứng nền, rung màn hình, đếm số.

## 6. Âm thanh và rung

- Nhạc nền một vòng lặp theo màn (menu, đua), có thể tắt riêng; hiệu ứng: mua nâng cấp, tiền, bắt đầu/kết thúc đua, vượt xe, lỗi, nhận thưởng.
- Không bắt buộc nghe để hiểu kết quả; mọi sự kiện có biểu hiện hình ảnh.
- Dừng khi app ra nền hoặc có cuộc gọi; tôn trọng chế độ im lặng của thiết bị.
- Rung nhẹ cho mua, nhận thưởng, kết thúc đua; tắt được; không rung liên tục.

## 7. Trợ năng

- Cỡ chữ 100/115/130%; layout không tràn.
- Không chỉ dùng màu; có chế độ màu hỗ trợ mù màu cho vị trí xe (kết hợp số, hình).
- Giảm chuyển động; không hiệu ứng chớp nháy nhanh.
- Vùng chạm ≥ 44; khoảng cách giữa nút nguy hiểm (xóa dữ liệu, mua) tối thiểu 16.
- Hỗ trợ trình đọc màn hình ở mức engine cho phép: tên nút có nhãn; ghi nhận hạn chế của Godot trên mobile trong kế hoạch QA và ưu tiên văn bản hóa các trạng thái đua.
- Văn bản kết quả và thông báo hiển thị ở dạng chữ, không chỉ biểu tượng.

## 8. Bản địa hóa

- Phát hành tiếng Việt và tiếng Anh. Mọi chuỗi nằm trong bảng dịch (CSV/PO); không viết cứng trong scene hoặc script.
- Dự phòng độ dài: mở rộng 30% cho tiếng Anh/ngôn ngữ khác; kiểm tra bằng giả bản địa hóa.
- Định dạng số theo ngôn ngữ (ví dụ 1.234,5 trong tiếng Việt), thời gian, dạng số nhiều khi cần.
- Tên tay đua, tên giải, tên track là tên riêng không dịch trừ khi cần (giữ danh sách ở dữ liệu).
- Ngôn ngữ chọn theo thiết bị lần đầu, đổi được trong Cài đặt.

## 9. Hướng dẫn đầu game (UI-19)

Mục tiêu: ≥ 85% hoàn tất trong ≤ 3 phút; có nút bỏ qua; bước đã làm không lặp.

1. Chào mừng, cho thấy xe và 1.000 tiền; một câu giải thích vai trò chủ đội.
2. Hướng dẫn nâng Động cơ một lần: giá 120, chỉ số 46 → 48 (xe khởi đầu Pico Tia chớp, 04 §5.1).
3. Giới thiệu xe và tay đua đang dùng; cuộc đua chạy tự động.
4. Chạy chặng đầu; chỉ đánh dấu xe của bạn, vị trí và vòng; không chồng nhiều tooltip.
5. Nhận thưởng, xem điểm mùa, gợi ý Cơ sở tăng thu nhập.
6. Mở điều hướng đầy đủ; các tính năng sau (Tuyển, Cơ sở, Bộ sưu tầm) mở dần bằng gợi ý một lần khi đủ điều kiện.

Không dựng sẵn kết quả thắng; nếu muốn cảm giác thắng đầu game, chỉnh đối thủ tutorial bằng cấu hình và kiểm chứng nhiều seed.

## 10. Thông báo đẩy

- Chỉ thông báo cục bộ, hỏi quyền **sau mùa đầu tiên** (không phải lúc mở lần đầu).
- Loại: thu nhập offline đã đầy, quà ngày sẵn sàng. Tối đa 1 thông báo mỗi ngày, tắt từng loại được, không gửi giờ khuya theo múi giờ thiết bị.
- Không thông báo dùng nỗi sợ mất mát hoặc đếm ngược áp lực.

## 11. Trạng thái lỗi và nhất quán

| Tình huống | UI mong muốn |
|---|---|
| Mua khi vừa thiếu tiền | Không trừ; cập nhật số thiếu; không mở cửa hàng |
| Bấm đua hai lần | Chỉ một cuộc đua; nút khóa ngay |
| Đổi tab khi đang đua | Cuộc đua tiếp tục; tab Đua có chỉ báo đang chạy |
| App ra nền | Đua tạm dừng; quay lại hiện thu nhập vắng mặt rồi tiếp tục |
| Save lỗi | UI-21 khôi phục bản sao; không ghi đè bằng save trắng |
| Không có quảng cáo | Giữ thưởng cơ bản; nút phụ báo "Chưa có quảng cáo" |
| Mất mạng | Mọi màn lõi vẫn hoạt động; tính năng cần mạng báo đúng trạng thái |
| Hủy mua | Giữ nguyên màn và số dư |
| Cập nhật bắt buộc | UI-24 chỉ khi phiên bản save không còn tương thích; cho phép xuất save trước |

## 12. Nghiệm thu UI

- Từ Đua, tối đa 2 chạm để nâng bộ phận hoặc chọn tay đua đã có.
- Mọi giao dịch luôn thấy giá và thay đổi trước khi bấm; tài nguyên đồng nhất trên mọi tab; không nút "mua được" khi tiền không đủ.
- Không tràn chữ/số, không bị safe area che, ở mọi kích thước và cỡ chữ 130%.
- Khôi phục đúng panel kết quả/mùa/offline sau khi app bị đóng; không lặp thưởng.
- Đạt checklist trợ năng ở §7 và kiểm tra tương phản bằng công cụ.
- Người mới sau 5 phút giải thích được sự khác nhau giữa nâng cơ sở và nâng xe (cần đo, chưa phải kết quả).
