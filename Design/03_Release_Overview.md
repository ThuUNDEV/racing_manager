# Racing Manager — Thiết kế bản chính thức v1.0: Tổng quan và lộ trình

Ngày: 09/11/2026. Trạng thái: **đã duyệt các quyết định mặc định D1–D12 (09/11/2026)**; các số liệu vẫn là giá trị khởi đầu cho playtest. Còn mở: quy mô đội, ngân sách art, ngày phát hành dự kiến. Tên làm việc: **Pitlane Club**.

Bộ tài liệu v1.0 thay thế phần "Sau MVP" của v0.2 và mở rộng nó thành kế hoạch phát hành. Hai tài liệu v0.2 ([UI](01_UI_Design.md), [Gameplay](02_Gameplay_Design.md)) vẫn là đặc tả của prototype hiện có; khi mâu thuẫn, tài liệu v1.0 đi sau ghi rõ thay đổi.

| Tài liệu | Nội dung |
|---|---|
| **03 — Tổng quan (file này)** | Tầm nhìn, phạm vi, lộ trình, tiêu chí, rủi ro, quyết định cần duyệt |
| [04 — Gameplay v1.0](04_Gameplay_Release.md) | Mô phỏng đã hiệu chỉnh, track, giải, xe, tay đua, cơ sở, nhiệm vụ, sự kiện |
| [05 — Kinh tế và kiếm tiền](05_Economy_Monetization.md) | Tiền tệ, đường cong giá, nhịp tiến trình, quảng cáo, IAP, tuân thủ |
| [12 — BigNumber Economy](12_BigNumber_Economy.md) | Economy v2: thang tiền K/M/B/T/AA/AB…ZZ, tám nâng cấp, BigNumber, save và mô hình tài chính; thay phần economy cũ; lõi runtime đã triển khai, cần playtest |
| [06 — UI/UX v1.0](06_UI_UX_Release.md) | Danh sách màn hình, luồng, nghệ thuật, âm thanh, trợ năng, bản địa hóa |
| [07 — Kỹ thuật](07_Technical_Architecture.md) | Kiến trúc Godot, dữ liệu, save, cloud, analytics, QA, phát hành |
| [10 — Đua liên tục theo thời gian](10_Continuous_Race_Loop.md) | Thiết kế mới: tự nối lượt, countdown 3 giây, thời lượng cấu hình; thay luồng đua thủ công trước đây, chưa triển khai |
| [Workshop GP asset pack](Workshop_GP_Asset_Pack.md) | Bộ art 2D v0.1 đã chọn làm hướng nghệ thuật (xem 06 §5) |

Thiết kế trang bị đang đối chiếu: [14 — Race Star gear và mockup v0.2](14_Driver_Equipment.md). Chỉ đạo 10/11/2026: bám sát bản gốc trước; đã rút phương án bốn ô/chế tạo tự đặt của v0.1. Bảng phạm vi cũ bên dưới chưa chuyển toàn bộ sang hướng này; tài liệu 14 phân biệt bằng chứng trực tiếp và cơ chế còn cần xác minh.

## 1. Tầm nhìn và định vị

Game quản lý đội đua idle, một người chơi, chơi offline được, màn hình dọc, Android và iOS. Người chơi làm chủ đội: đầu tư vào xe, tay đua và cơ sở, rồi xem cuộc đua tự động cho thấy các quyết định đó có tác dụng thật. Phiên chơi 3–5 phút, quay lại nhiều lần mỗi ngày.

Tham khảo cấu trúc vòng lặp của game cùng thể loại (nâng cấp, sưu tầm, đua tự động) nhưng nội dung, tên gọi, nghệ thuật và công thức là của riêng dự án. Mọi con số là giá trị khởi đầu cho playtest.

**Đối tượng:** người chơi mobile casual đến mid-core thích tối ưu hóa và tiến bộ đều; chơi ngắn trên đường đi, không cần mạng liên tục. Thị trường ưu tiên: Việt Nam, sau đó Đông Nam Á và thị trường nói tiếng Anh. Đây là giả định để đặt ngôn ngữ và giá, cần kiểm chứng khi soft launch.

### Bốn trụ cột (kế thừa và mở rộng v0.2)

1. **Đầu tư có tác dụng nhìn thấy được.** Mỗi nâng cấp cho biết trước/sau; kết quả đua giải thích bằng số liệu đo thật (lỗi, bám xe, vượt xe), không bằng lý do dựng sẵn.
2. **Lựa chọn thay cho may rủi.** Phân bổ tiền giữa xe, tay đua và cơ sở. Sưu tầm bằng lựa chọn có kế hoạch, **không dùng gacha/hộp ngẫu nhiên** trong v1.0.
3. **Thua vẫn tiến bộ.** Không phí đua, năng lượng, mất xe hay tụt giải.
4. **Tôn trọng thời gian người chơi.** Phần thưởng cơ bản không bao giờ khóa sau quảng cáo; không pop-up mua hàng sau khi thua; quảng cáo luôn tự nguyện.

## 2. Phạm vi bản v1.0

Bảng dưới là phạm vi **đề xuất**; mục "Ngoài v1.0" cần phiên bản riêng, kể cả khi hấp dẫn.

| Hệ thống | Có trong v1.0 | Ngoài v1.0 (v1.1+) |
|---|---|---|
| Mô phỏng đua | 8 xe tự động, công thức hiệu chỉnh, 10 track, seed lặp lại được | Thời tiết, pit stop, lốp mòn |
| Tiến trình | 6 giải × mùa 5 chặng, thăng hạng, danh hiệu | Mùa đặc biệt, giải sự kiện dài ngày |
| Xe | 15 xe / 5 hạng, 4 bộ phận mỗi xe, bộ sưu tập, livery | Trang bị, xe giới hạn |
| Tay đua | 12 tay đua, tuyển chọn có kế hoạch, cấp 0–20, 1 đặc tính mỗi người | Cặp đôi đồng đội, đặc tính tiến hóa |
| Cơ sở | 3 dòng: Trụ sở, Xưởng, Học viện | Nhân viên, tài trợ |
| Nội dung ngày | Quà ngày, nhiệm vụ ngày, Thử thách ngày (seed theo ngày UTC) | Cúp tuần (v1.1), Club (v1.2) |
| Meta dài hạn | Thành tích, sưu tầm, danh hiệu theo giải | Prestige "Di sản" (v1.2, sau khi có dữ liệu) |
| Kiếm tiền | Quảng cáo thưởng, No Ads, gói khởi đầu, gem, mỹ phẩm | Pass theo mùa (v1.1) |
| Online | Lưu đám mây tùy chọn (tài khoản nền tảng), bảng xếp hạng điểm Thử thách ngày | PvP, club, trò chuyện |
| Ngôn ngữ | Tiếng Việt, tiếng Anh | Thêm theo dữ liệu thị trường |

Quyết định cố ý không đưa vào: PvP thời gian thực, gacha, merge, đua thủ công, năng lượng/vé đua. Mỗi cái cần một vòng thiết kế riêng và dữ liệu v1.0 trước.

## 3. Lộ trình phiên bản

| Phiên bản | Mục tiêu | Nội dung chính |
|---|---|---|
| **0.2 Prototype** (đã có) | Chứng minh vòng lặp | 1 xe, 1 track, mô phỏng, nâng cấp, kết quả, offline, save |
| **0.5 Vertical slice** | Đủ cảm giác chơi để duyệt hướng nghệ thuật | 3 track, 2 giải, 3 xe, 3 tay đua, art thật cho đua và Garage |
| **0.8 Closed beta** | Đủ nội dung cho 1 tuần chơi | 6 giải, 15 xe, 12 tay đua, nhiệm vụ, onboarding, save + backup, analytics |
| **0.9 Soft launch** | Đo giữ chân và kinh tế | Quảng cáo thưởng, IAP, cloud save, bản địa hóa EN/VI, remote config |
| **1.0 Phát hành** | Phát hành toàn cầu | Cân bằng theo dữ liệu soft launch, store assets, hỗ trợ khách hàng |
| 1.1 | Giữ chân sau phát hành | Cúp tuần, pass theo mùa, thêm track |
| 1.2 | Chiều sâu dài hạn | Prestige "Di sản", club nhẹ |

### Mốc công việc và tiêu chí thoát

Ước lượng thời gian giả định đội nhỏ: 2 lập trình, 1 họa sĩ UI/2D, 1 thiết kế kiêm QA bán thời gian. Con số này **chưa được xác nhận**, cần điều chỉnh theo đội thực tế.

| Mốc | Ước lượng | Tiêu chí thoát |
|---|---|---|
| M1 Nền tảng dữ liệu | 3 tuần | Mọi hằng số nằm trong dữ liệu, mô phỏng tách khỏi UI, test tự động chạy trong CI |
| M2 Nội dung lõi | 5 tuần | 10 track, 6 giải, 15 xe, 12 tay đua chơi được từ đầu đến cuối bằng công cụ mô phỏng |
| M3 UI và nghệ thuật | 6 tuần | Toàn bộ màn hình ở [06](06_UI_UX_Release.md) đạt checklist trợ năng và kích thước màn hình |
| M4 Kinh tế và save | 3 tuần | Save có phiên bản + migration + backup, offline đúng, khóa giao dịch đúng, bộ test giao dịch qua |
| M5 Thương mại và online | 4 tuần | Ads, IAP, consent, cloud save chạy trên máy thật; không có lỗi phát thưởng trùng |
| M6 Beta kín | 4 tuần | Crash-free sessions và các chỉ số ở mục 4 đạt ngưỡng; sửa cân bằng theo dữ liệu |
| M7 Soft launch | 4–6 tuần | Retention và kinh tế đạt ngưỡng; quyết định phát hành toàn cầu |
| M8 Phát hành | 2 tuần | Store listing, tuân thủ chính sách, kế hoạch hỗ trợ |

Tổng ước lượng khoảng 31–33 tuần tới phát hành toàn cầu, nếu không có thay đổi phạm vi.

## 4. Chỉ số thành công (giả thuyết, không phải cam kết)

Chưa có dữ liệu thực nên các ngưỡng dưới đây là **mục tiêu khởi điểm để đo**, không phải dự báo. Điều chỉnh sau beta kín.

| Nhóm | Chỉ số | Ngưỡng khởi điểm để tiếp tục |
|---|---|---|
| Chất lượng | Phiên không crash | ≥ 99,5% |
| Chất lượng | Thời gian khởi động nguội trên máy tầm trung | ≤ 4 giây |
| Chất lượng | Khung hình khi đua | ≥ 55 FPS trên máy tầm trung |
| Onboarding | Hoàn tất hướng dẫn | ≥ 85% người mở game lần đầu |
| Giữ chân | Quay lại ngày 1 / 7 | đo; ngưỡng tham chiếu D1 ≥ 35%, D7 ≥ 12% |
| Gắn kết | Số cuộc đua mỗi người mỗi ngày hoạt động | 4–10 |
| Kinh tế | Tỷ lệ nhận thưởng quảng cáo trên số lần hiển thị nút | đo, không đặt mục tiêu ép |
| Kinh tế | Tỷ lệ người chơi hoàn tất mùa đầu | ≥ 70% |
| Cảm nhận | Người mới giải thích được khác biệt "nâng cơ sở" và "nâng xe" sau 5 phút | ≥ 80% trong thử nghiệm với người dùng |

## 5. Rủi ro chính

| Rủi ro | Tác động | Giảm thiểu |
|---|---|---|
| Mất cân bằng chỉ số (prototype cho thấy Động cơ áp đảo, Khung gầm và Composure gần như vô tác dụng) | Người chơi chỉ nâng một bộ phận, mất chiều sâu | Công thức v1.0 đã hiệu chỉnh trên lab mô phỏng (mỗi chỉ số xe tiết kiệm 1,6–5,7 giây ở +40 trên 10 track, [04](04_Gameplay_Release.md) §3); còn phải chạy lab cho cả 6 giải và đặc tính tay đua |
| Lỗi mô phỏng (đã tìm thấy một lỗi treo cuộc đua khi hiệu chỉnh) | Race treo, mất thưởng | Đã sửa trong prototype; thêm hồi quy 600+ race ngẫu nhiên vào CI, chốt cưỡng bức ghi sự kiện |
| Offline quá hào phóng so với giá nâng cấp | Người chơi bỏ qua nội dung | Offline chỉ 50% và trần có thể mở rộng bằng cách chơi, không bắt buộc mua; theo dõi "số cấp mua sau lần quay lại" |
| Nội dung cạn nhanh | Rơi rụng sau tuần đầu | Thử thách ngày, bộ sưu tập, danh hiệu theo giải, kế hoạch 1.1 |
| Tuân thủ chính sách quảng cáo/IAP/trẻ em | Bị gỡ khỏi store | Kiểm tra yêu cầu hiện hành của Google Play và App Store trước M5; xem [05](05_Economy_Monetization.md) §8 |
| Khai thác chỉnh giờ thiết bị | Phá kinh tế offline | Chấp nhận mức độ chơi đơn: giới hạn cứng, ghi nhận giờ lùi; thời gian server cho các tính năng online |
| Save hỏng hoặc mất | Mất niềm tin | Ghi nguyên tử, backup, cloud save, test mất điện giữa lúc ghi |
| Phạm vi trôi (scope creep) | Trễ mốc | Danh sách "Ngoài v1.0" là hợp đồng; thêm tính năng phải đổi một tính năng khác |
| Art tốn công hơn dự kiến | Trễ M3 | Hướng đã chọn (Workshop GP) là ảnh dựng sẵn: mỗi track cần nền + centerline riêng và mỗi livery là một sprite. Giảm thiểu: dùng 3–4 môi trường nền tái sử dụng cho 10 track, ưu tiên art cho khung đua và Garage, ước lượng chi phí art trước khi khóa 10 track (có thể giảm xuống 6 track ở v1.0) |

## 6. Quyết định cần duyệt

Mọi mục đã có mặc định để tiến hành thiết kế; đổi quyết định sẽ ảnh hưởng tài liệu nêu trong cột cuối.

| # | Quyết định | Mặc định đề xuất | Phương án khác | Ảnh hưởng |
|---|---|---|---|---|
| D1 | Sưu tầm tay đua | Tuyển từ danh mục công khai bằng điểm tuyển (SP) và tiền, không ngẫu nhiên | Gacha, bán thẳng bằng tiền | 04, 05 |
| D2 | Xe | 15 xe, mua dần, giữ nhiều xe, thưởng bộ sưu tầm | 1 xe nâng liên tục | 04, 05 |
| D3 | Prestige/reset | Chưa có trong v1.0; xem lại ở 1.2 | Có ngay | 04, 05 |
| D4 | Quảng cáo | **Đổi 12/11/2026:** rewarded tự nguyện + Ads Break (interstitial) chỉ xen giữa hai lượt đua, không banner; người mua "Bỏ quảng cáo" không thấy Ads Break. Chi tiết: [26](26_Ads_Placements.md). *(Ban đầu: chỉ rewarded, không interstitial.)* | Chỉ rewarded | 05, 06, 26 |
| D5 | Lưu đám mây | Có, qua tài khoản nền tảng (Google Play Games / iCloud), tùy chọn | Chỉ local | 07 |
| D6 | Engine | Godot 4.x (đã có project) | Unity | 07 |
| D7 | Mô hình tiền tệ | Tiền mềm + gem (gem có thể kiếm được, chỉ dùng cho tiện ích và mỹ phẩm); điểm tuyển là thước đo tiến độ, không bán | Thêm tiền sự kiện | 05 |
| D8 | Giá bán | Theo bậc giá của store; số cụ thể xác định sau soft launch | Cố định | 05 |
| D9 | Ngôn ngữ phát hành | Việt, Anh | Thêm ngôn ngữ khác | 06 |
| D10 | Độ tuổi/đánh giá nội dung | Mục tiêu 12+ (không nhắm trẻ em); cần xác minh khi khai báo | Nhắm trẻ em (hạn chế quảng cáo/analytics nặng) | 05, 07 |

| D11 | Điều hướng | 5 tab như thiết kế (concept Workshop GP dùng 6 mục) | Thanh 6 mục | 06 |
| D12 | Số track ở v1.0 | 10 track (có thể rút còn 6 nếu chi phí art cao) | 6 track | 04, 06 |

Ngoài ra cần xác nhận quy mô đội, ngân sách art, và ngày dự kiến phát hành vì chúng quyết định mốc ở §3.
