# Racing Manager — Thiết kế v1.0: Kinh tế và kiếm tiền

> **Economy v2 — 10/11/2026:** [12 — BigNumber Economy](12_BigNumber_Economy.md) thay công thức coins, giá xe/nâng cấp, thưởng coins, gem lặp mỗi mùa, nhịp tiến trình và định dạng tiền của bản này. Dùng BigNumber và thang tiền theo bậc kinh doanh; các bảng bên dưới được giữ làm tham chiếu cũ. Lõi runtime đã được triển khai; xem [biên bản 13](13_Economy_v2_Implementation.md).

> **Cập nhật nhịp đua 09/11/2026:** [10 — Đua liên tục theo thời gian](10_Continuous_Race_Loop.md) chuyển sang lượt tự nối với countdown 3 giây và thời lượng cấu hình (mặc định đề xuất 60 giây). Giữ bảng thưởng làm điểm xuất phát; cần đo lại thưởng/phút và nhịp tiến trình bên dưới vì không còn thời gian người chơi chờ bấm đua/chuyển mùa. Chưa triển khai hoặc xác nhận cân bằng cho luồng mới.

Ngày: 09/11/2026. Trạng thái: đề xuất để duyệt. Đi cùng: [03 Tổng quan](03_Release_Overview.md), [04 Gameplay](04_Gameplay_Release.md).

Mọi con số là **giá trị khởi đầu**. Nhịp tiến trình ở §5 đến từ một mô hình tham lam sơ bộ (người chơi mua rẻ nhất trước, giả định hạng 3 mỗi chặng), không phải dữ liệu người chơi. Phải mô phỏng lại bằng công cụ trong `tests/` và chỉnh qua remote config sau beta.

## 1. Nguyên tắc

1. Phần thưởng cơ bản (đua, offline, nhiệm vụ, quà ngày) **không bao giờ** nằm sau quảng cáo hay mua hàng.
2. Mua hàng không mua kết quả trận đấu trực tiếp. Có thể mua tiện ích (trần offline, bỏ quảng cáo), mỹ phẩm; tiền mềm trong gói chỉ ở mức "tiết kiệm thời gian" và ghi rõ giá trị theo phút thu nhập.
3. Mọi giá hiển thị đầy đủ trước khi bấm; không xác nhận lại cho tiền mềm, có xác nhận cho gem và tiền thật.
4. Không popup bán hàng sau thua, không đếm ngược gây áp lực, không offer ngẫu nhiên theo hành vi.
5. Một giao dịch = một ID. Thưởng chỉ phát sau khi ghi save thành công.

## 2. Tiền tệ và thước đo

| Tên | Loại | Cách có | Cách tiêu | Bán bằng tiền thật? |
|---|---|---|---|---|
| **Tiền** | Mềm | Thu nhập cơ sở, thưởng đua/mùa, nhiệm vụ, quà ngày, offline | Nâng cấp xe, tay đua, cơ sở; mua xe | Chỉ gói khởi đầu nhỏ (quy đổi phút thu nhập) |
| **Gem** | Cao cấp, kiếm được | Thành tích, hoàn tất mùa, chuỗi ngày, Thử thách ngày; gói mua | Mỹ phẩm, mở rộng trần offline, làm mới nhiệm vụ | Có |
| **Điểm tuyển (SP)** | Thước đo tiến độ | Mỗi chặng đua, nhiệm vụ | Tuyển tay đua (cùng một lượng tiền) | Không |

Quyết định: không thêm mảnh, vé, năng lượng hay tiền sự kiện trong v1.0. SP không phải ví để mua bán mà là thanh tiến độ sưu tầm; không đổi được thành tiền hay gem.

## 3. Công thức

Ký hiệu: `L` là chỉ số giải 0–5; `k` là chỉ số hạng xe 0–4; `v` là cấp Trụ sở 0–20 (riêng cho từng giải); `n` là cấp nâng.

```text
rate_online(L, v, legacy) = 8 × 3^L × (1 + 0.12 × v) × (1 + legacy)
legacy = 0.01 × tổng cấp Trụ sở của các giải ĐÃ qua (tối đa 0.30)
rate_offline = 0.5 × rate_online lưu lúc rời app, trần mặc định 2 giờ

hq_next_cost(L, v)   = ceil(150 × 5^L × 1.20^v)
part_next_cost(k, n) = ceil(120 × 5^k × 1.17^n)      # mỗi bộ phận của xe hạng k
driver_next_cost(t,n)= ceil(100 × 5^t × 1.18^n)      # t = tầng tay đua 0–3
workshop(n)  = ceil(400 × 1.15^n)    # Xưởng: giảm giá nâng xe 1,5%/cấp, tối đa 30% (cấp 20)
academy(n)   = ceil(800 × 1.15^n)    # Học viện: giảm giá huấn luyện 1,5%/cấp, tối đa 30% (cấp 20)
                                     #           và +2% SP mỗi chặng mỗi cấp
```

Giá lưu số nguyên; giảm giá áp dụng sau cùng và làm tròn lên. Giá luôn tính theo cấp trước khi mua. Không mua x10/xMax trong v1.0.

### Thưởng theo giải (thưởng nhân hệ số 3^L)

Điểm mùa theo vị trí giữ nguyên v0.2 (10/8/6/5/4/3/2/1). Tiền: `bảng_v0.2[pos] × 3^L`.

| Giải L | Rate cơ bản /giây | Thưởng P1 / P3 / P8 | Hoàn tất mùa | Thăng giải (1 lần) |
|---|---:|---|---:|---:|
| 0 Tập sự | 8 | 120 / 85 / 35 | 150 | 300 |
| 1 Bán chuyên | 24 | 360 / 255 / 105 | 450 | 900 |
| 2 Chuyên nghiệp | 72 | 1.080 / 765 / 315 | 1.350 | 2.700 |
| 3 Quốc gia | 216 | 3.240 / 2.295 / 945 | 4.050 | 8.100 |
| 4 Châu lục | 648 | 9.720 / 6.885 / 2.835 | 12.150 | 24.300 |
| 5 Thế giới | 1.944 | 29.160 / 20.655 / 8.505 | 36.450 | 72.900 (không có, giải cuối) |

### Tổng chi phí tham chiếu

| Hạng xe k | Giá cấp đầu / bộ phận | Tổng 1 bộ phận (0→20) | Tổng 4 bộ phận | Tổng 4 bộ phận tới cấp 12 |
|---|---:|---:|---:|---:|
| 1 (k=0) | 120 | 15.613 | 62.452 | 15.780 |
| 2 (k=1) | 600 | 78.031 | 312.124 | 78.800 |
| 3 (k=2) | 3.000 | 390.108 | 1.560.432 | 393.904 |
| 4 (k=3) | 15.000 | 1.950.503 | 7.802.012 | 1.969.456 |
| 5 (k=4) | 75.000 | 9.752.481 | 39.009.924 | 9.847.200 |

Tổng Trụ sở cấp 20 theo giải: 28.011 / 140.024 / 700.087 / 3.500.406 / 17.502.006 / 87.510.006.

### Giá mua xe

Mỗi hạng có 3 xe (xem 04 §5). Xe hạng 1: xe khởi đầu miễn phí, hai xe còn lại 2.500 và 5.000. Từ hạng 2 trở lên, giá = mốc theo hạng × hệ số biến thể (1,0 / 1,5 / 2,0).

| Hạng | Mốc giá (biến thể thứ nhất) | Giải yêu cầu để mua |
|---|---:|---|
| 2 | 855.000 | Chuyên nghiệp (L2) |
| 3 | 4.300.000 | Quốc gia (L3) |
| 4 | 21.500.000 | Châu lục (L4) |
| 5 | 107.000.000 | Thế giới (L5) |

Giải kế tiếp yêu cầu xe hạng tối thiểu theo bảng ở 04 §4; hai biến thể sau cùng hạng là đồ sưu tầm, không bắt buộc.

### Tuyển tay đua (SP)

- Điểm tuyển mỗi chặng: `điểm mùa nhận được × 1 + 4` (5–14 SP), cộng nhiệm vụ.
- Tuyển người thứ `i` (i = 0…10, người đầu tiên là An có sẵn): cần `40 + 20×i` SP và một khoản tiền theo tầng (xem 04 §6).
- Toàn bộ danh mục hiện công khai; có thể tuyển bất kỳ ai đã đủ điều kiện mở, không ngẫu nhiên.

## 4. Offline và nền

- Thu nhập vắng mặt: 50% rate đã lưu, trần mặc định 2 giờ. Dưới 60 giây vẫn cộng nhưng không mở panel.
- Mở rộng trần bằng gem (tiện ích, không phải sức mạnh): 4 giờ (150 gem), 8 giờ (400 gem), 12 giờ (800 gem). Có thể kiếm gem miễn phí đủ cho bậc 4 giờ sau mùa đầu tiên (xem §6).
- Quảng cáo thưởng khi quay lại: một lần "nhận gấp đôi phần vừa nhận" cho phần offline; phần cơ bản đã ghi save trước khi hỏi.
- Không mô phỏng đua khi vắng mặt. Thu nhập cơ sở và tiến trình giải là hai hệ thống khác nhau.
- Giờ thiết bị lùi: cộng 0, cập nhật mốc. Giờ nhảy tiến quá 24 giờ so với lần đồng bộ server gần nhất (nếu có mạng): vẫn áp trần, ghi cờ để phân tích; không phạt người chơi.

## 5. Nhịp tiến trình mục tiêu

Mô hình sơ bộ: đua một chặng mỗi 90 giây, hạng 3, mua nâng cấp rẻ nhất trước, thăng giải khi bốn bộ phận trung bình **cấp 4 ở giải đầu và cấp 10 ở các giải sau** (khoảng Δ +8 so với đối thủ, tức tỉ lệ thăng ~98% theo lab, 04 §3.3) và đủ tiền mua xe hạng kế. Thời gian là **giờ chơi tương đương** (thu nhập cộng dồn, không phải giờ chạm màn hình).

| Mốc | Giờ tương đương | Ghi chú |
|---|---:|---|
| Thăng Bán chuyên (L1) | ≈ 0,15 | Bị giới hạn bởi độ dài mùa 5 chặng (≈ 8–10 phút); mùa đầu xong trong 2–3 phiên ngắn |
| Thăng Chuyên nghiệp (L2) | ≈ 3,4 | Mua xe hạng 2 là mục tiêu lớn đầu tiên |
| Thăng Quốc gia (L3) | ≈ 8,2 | |
| Thăng Châu lục (L4) | ≈ 15,2 | |
| Thăng Thế giới (L5) | ≈ 25,3 | Nội dung chính xong khoảng 3–4 tuần chơi thường |
| Hoàn tất bộ sưu tầm | ngoài mốc trên | Mục tiêu dài hạn cho người chơi kỹ |

Ngưỡng cần đo ở beta: tỷ lệ người chơi thoát khi chờ tiền; số cấp mua ngay sau lần quay lại offline (nếu một lần quay lại mua quá nhiều cấp, giảm tỷ lệ offline hoặc rate trước khi thêm tiền tệ); thời gian tới mốc đầu tiên của mỗi giải.

Công cụ điều chỉnh qua remote config (không cần phát hành lại): hệ số 3^L, 5^k, tăng trưởng giá 1,17/1,18/1,20, tỷ lệ offline, trần offline, thưởng đua, SP mỗi chặng.

## 6. Nguồn gem miễn phí (ước lượng)

| Nguồn | Gem | Ghi chú |
|---|---:|---|
| Hoàn tất mùa | 20 | Mỗi mùa, có thể lặp |
| Thăng giải lần đầu | 50 | Một lần mỗi giải |
| Thành tích | 10–50 | Danh sách ở 04 §9 |
| Chuỗi 7 ngày | 30 | Bấm nhận, không phạt khi gián đoạn (giữ chuỗi trong 48 giờ) |
| Thử thách ngày | 5–20 | Theo hạng, xem 04 §8 |
| Khởi đầu | 100 | Như v0.2 |

Tổng dự kiến đến cuối nội dung chính khoảng 600–900 gem, đủ cho 1–2 mỹ phẩm và trần offline 4 giờ. Số này cần chỉnh theo giá bán thật.

## 7. Quảng cáo và mua hàng

### 7.1. Quảng cáo thưởng (D4: chỉ rewarded, tự nguyện)

> **Cập nhật 12/11/2026:** D4 đã đổi (có thêm Ads Break xen giữa các lượt). Danh sách vị trí, trần ngày (nâng từ 8 lên 12 rewarded/ngày) và phần thưởng mới nằm ở [26 — Vị trí đặt quảng cáo](26_Ads_Placements.md) và **thay** bảng dưới đây. Câu "Không interstitial, không banner" dưới bảng chỉ còn đúng cho banner.

| Vị trí | Phần thưởng | Giới hạn |
|---|---|---|
| Sau chặng đua | + tiền bằng đúng phần tiền cơ bản của chặng (không nhân điểm mùa) | 1 lần/chặng |
| Quay lại sau vắng | Nhận gấp đôi phần offline vừa nhận | 1 lần/lần quay lại |
| Tăng tốc thu nhập | ×2 thu nhập online trong 30 phút | 3 lần/ngày, không cộng dồn thời gian |
| Thử thách ngày | 1 lượt thử thêm | 1 lần/ngày |

Mọi nút nêu rõ số tiền cộng thêm. Phát thưởng chỉ sau callback thành công và ID quảng cáo duy nhất. Hủy/lỗi: giữ thưởng cơ bản, nút chuyển sang "Chưa có quảng cáo". Không interstitial, không banner. Trần mềm 8 quảng cáo thưởng/ngày/người để tránh kiệt sức.

### 7.2. Danh mục mua hàng (giá thật do store trả về, D8)

> **Cập nhật 12/11/2026:** danh mục, giá, offer, pass và luồng kỹ thuật IAP nằm ở [28 — Hệ thống gói IAP](28_IAP_Packs.md) và **thay** bảng dưới đây. Câu "Không có gacha" không còn đúng (gói Pro/All-Star đã có, xem 28 §8).

| Sản phẩm | Loại | Nội dung | Ghi chú |
|---|---|---|---|
| **Đội tự do** (No Ads) | Một lần | Mọi quảng cáo thưởng ở §7.1 được **nhận trực tiếp**, không cần xem; không bao giờ hiện quảng cáo | Không dùng từ "No Ads" nếu vẫn phải xem quảng cáo cùng loại |
| **Gói khởi động** | Một lần, hiện ở mục Cửa hàng sau mùa đầu | 300 gem, 1 livery, tiền bằng 60 phút thu nhập ở giải hiện tại | Không tự bật popup |
| **Gói gem** ×4 | Tiêu thụ | Gem theo 4 bậc giá | Gem không bao giờ rẻ hơn mức kiếm được theo giờ chơi quá nhiều (kiểm tra trong cân bằng) |
| **Livery** | Mỹ phẩm | Biến thể màu/họa tiết dựng sẵn của xe (art theo 06 §5) | Mua bằng gem hoặc trọn gói; không đổi chỉ số |
| **Mở rộng offline** | Gem | Xem §4 | Không bán trực tiếp bằng tiền thật |

Không có gacha, hộp ngẫu nhiên, hay vật phẩm thay đổi xác suất thắng. Pass theo mùa là đề xuất v1.1 và cần vòng cân bằng riêng.

## 8. Tuân thủ và rủi ro (cần kiểm tra khi triển khai)

Bản này chỉ liệt kê điểm cần xác minh; **kiểm tra yêu cầu hiện hành của từng store và từng thị trường trước mốc M5**, vì chính sách thay đổi thường xuyên.

| Chủ đề | Việc cần làm |
|---|---|
| Quyền riêng tư | Chính sách riêng tư công khai; khai báo dữ liệu thu thập ở Google Play (Data safety) và App Store (privacy labels) |
| Đồng ý quảng cáo | Hộp thoại consent theo khu vực (ví dụ GDPR qua nền tảng consent của SDK quảng cáo); hộp thoại theo dõi trên iOS nếu có theo dõi |
| Trẻ em | D10 nhắm 12+, không nhắm trẻ em; nếu đổi, hạn chế SDK/quảng cáo theo chương trình dành cho gia đình của store |
| IAP | Nút "Khôi phục mua" trên iOS; xác thực biên nhận bằng thư viện store; xử lý hoàn tiền (thu hồi quyền lợi tiêu thụ không áp dụng, quyền vĩnh viễn kiểm tra khi khôi phục) |
| Giá | Hiển thị giá từ store, không viết cứng; quy đổi gem rõ ràng |
| Quy định phát hành địa phương | Xác minh yêu cầu cấp phép/đăng ký trò chơi ở từng thị trường mục tiêu (ví dụ Việt Nam) với tư vấn pháp lý; game offline chơi đơn có thể thuộc diện khác game có tương tác online |
| Đánh giá nội dung | Khai báo bảng câu hỏi độ tuổi; không có cờ bạc mô phỏng, không có xác suất mua |

## 9. Chống lạm dụng (chơi đơn, mức vừa phải)

- Reward ID duy nhất; danh sách ID đã xử lý nằm trong save (xem 07 §3).
- Quảng cáo/IAP: chỉ phát sau callback/biên nhận hợp lệ.
- Thời gian: không tin giờ thiết bị cho quyết định có giá trị lớn; với tính năng online (bảng xếp hạng Thử thách ngày) dùng giờ server.
- Sửa save cục bộ không thể ngăn hoàn toàn: mã hóa nhẹ, hash toàn vẹn, và chấp nhận rằng người chơi tự gian lận ở chế độ chơi đơn chỉ ảnh hưởng chính họ. Chỉ bảng xếp hạng online cần kiểm chứng phía server (xem 07 §6).

## 10. Đo lường kinh tế

Sự kiện cần ghi (xem 07 §7): `purchase_upgrade`, `purchase_car`, `scout_driver`, `race_reward`, `offline_claim`, `ad_offered`, `ad_completed`, `iap_started`, `iap_completed`, `currency_balance_snapshot` (đầu và cuối phiên). Báo cáo tuần: thời gian tới mỗi mốc §5, phân phối số dư, tỷ lệ chuyển đổi quảng cáo, chuyển đổi IAP, ARPDAU, tỷ lệ thoát khi chờ tiền.
