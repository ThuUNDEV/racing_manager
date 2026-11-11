# Racing Manager — Thiết kế UI v0.2

Ngày: 09/11/2026. Trạng thái: đề xuất để duyệt và triển khai prototype.

Tài liệu đi cùng: [Gameplay](02_Gameplay_Design.md). Tên làm việc: **Pitlane Club**.

> **Phạm vi tài liệu:** đây là đặc tả UI của **prototype**. Thiết kế bản chính thức nằm ở [03](03_Release_Overview.md)–[07](07_Technical_Architecture.md), UI chi tiết ở [06](06_UI_UX_Release.md).

## 1. Định hướng và phạm vi

Game quản lý đội đua idle trên Android/iOS, màn hình dọc. Người chơi là chủ đội: tuyển tay đua, nâng xe, tăng thu nhập và thi đấu giải. Cuộc đua chạy tự động, thể hiện rõ kết quả của các quyết định quản lý.

Thiết kế tham khảo cấu trúc của [Race Star](https://play.google.com/store/apps/details?id=com.coolcatsgames.racestaridle), nhưng dùng nhận diện, nội dung và quy tắc riêng. Đây là thiết kế mới; các chức năng mô tả ở đây không phải khẳng định về cơ chế bên trong Race Star.

Ưu tiên bám vòng lặp nâng cấp, sưu tầm và đua tự động của game mẫu. Các con số, tên nội dung và công thức trong tài liệu Gameplay là cấu hình prototype đề xuất, chưa phải thông số được trích xuất từ game mẫu. Tính năng mới ngoài vòng lặp tham chiếu cần được tách thành đề xuất để duyệt trước khi đưa vào phạm vi chính.

Giả định sản phẩm: chơi đơn, có thể chơi offline; chưa cần tài khoản, PvP hay backend trong MVP. Workspace đang có project Godot; tài liệu chưa thay đổi cấu hình hay tạo gameplay trong engine.

**Trải nghiệm cần đạt:** trong 10 giây, người chơi nhận ra đang ở giải nào, đội đang mạnh/yếu ở đâu và có thể nâng cấp gì. Trong một phiên 3–5 phút, hoàn tất ít nhất một quyết định đầu tư và một cuộc đua.

## 2. Kiến trúc điều hướng

Thanh đáy có 5 tab, luôn cùng thứ tự:

| Tab | Chức năng | Ưu tiên |
|---|---|---|
| Đua | Trung tâm tiến trình, thu nhập, nâng cấp nhanh, đường đua | MVP |
| Tay đua | Danh sách, chi tiết, huấn luyện và chọn người thi đấu | MVP |
| Garage | Thông số xe, nâng cấp và chọn hướng đầu tư | MVP |
| Giải đấu | Lịch 5 chặng, điểm số, điều kiện thăng hạng | MVP |
| Cửa hàng | Quà hằng ngày; vị trí cho offer và IAP sau này | MVP chỉ quà miễn phí |

Từ avatar mở hồ sơ/cài đặt. Từ số gem mở cửa hàng sau khi IAP được triển khai; trong prototype số gem là chỉ báo, không tạo liên kết mua giả. Thông báo nhiệm vụ mở danh sách nhiệm vụ nhỏ thay vì thêm tab thứ sáu.

Luồng chính: mở game → nhận thu nhập vắng mặt nếu có → tab Đua → đầu tư hoặc chọn tay đua → đua tự động → kết quả → chặng tiếp theo hoặc tổng kết mùa.

Luồng phụ: Đua → Garage/Tay đua → nâng cấp → quay về Đua, giữ nguyên chặng và tay đua đã chọn.

## 3. Hệ thống hình ảnh và bố cục

### 3.1. Ngôn ngữ hình ảnh

- Phong cách đã chọn: **Workshop GP** — kem ấm cho nền, graphite cho khung đua, cam cho hành động chính và vàng cho phần thưởng. Bộ asset và hướng dẫn ở [Workshop GP](Workshop_GP_Asset_Pack.md).
- Đường đua nhìn từ trên xuống dạng 2D. Mỗi xe có thân xe nhỏ, mũi chỉ hướng, số xe. Xe người chơi có viền và nhãn “Bạn”; không chỉ dùng màu để phân biệt.
- Tay đua dùng chân dung minh họa gốc. Prototype dùng avatar chữ cái; không dùng hình tay đua/thương hiệu thật.
- Hiệu ứng ưu tiên giải thích: thanh tăng chỉ số, tiền tăng, xe vượt đối thủ. Tránh che đường đua bằng pop-up thưởng nhỏ.

### 3.2. Quy chuẩn mobile

- Thiết kế gốc 886 × 1920 px (tỉ lệ ≈ 9:19,5). Trong engine dùng hệ số co giãn 2,27 nên layout tính theo ≈ 390 × 845 logical px; các kích thước dưới đây là logical px. Kiểm tra thêm 360 × 800, 412 × 915 và màn hình thấp 320 × 568.
- Chừa safe area trên/dưới; khoảng cách cạnh 16 px; nhịp khoảng cách 4/8/12/16/24 px.
- Chữ nội dung 14–16 px; nhãn phụ không dưới 12 px; giá trị chính 20–28 px; hỗ trợ font có dấu tiếng Việt.
- Vùng chạm tối thiểu 44 × 44 px. Nút chính cao khoảng 48 px. Dòng tiền không tràn khi lên triệu/tỷ.
- Số tiền lớn rút gọn 12,4K / 3,2M; chạm vào số để thấy đầy đủ. Không rút gọn giá nâng cấp nếu gây hiểu nhầm khả năng mua.
- Chỉ một CTA chính tại mỗi trạng thái. Tay đua đang được sử dụng có cả nhãn và dấu chọn.
- Nội dung dài cuộn trong màn hình; thanh đáy và tài nguyên cố định trong sản phẩm. Trên màn hình thấp, giảm chiều cao đường đua và đưa nâng cấp xuống phần cuộn, không thu nhỏ chữ.
- Có tùy chọn giảm chuyển động, âm thanh, rung. Không bắt buộc nghe âm thanh để hiểu kết quả.

## 4. Chi tiết màn hình

### UI-01 — Đua / trang chủ

Thứ tự trên xuống:

1. **Thanh tài nguyên:** avatar, tiền mềm, gem. Thu nhập hiện ở dòng riêng “8 tiền/giây”; không gộp vào tiền thưởng đua.
2. **Tiến trình:** “Giải tập sự · Chặng 1/5”, nút xem lịch, tên đường đua.
3. **Khung đua:** trước đua hiển thị grid và xe người chơi; đang đua hiển thị vị trí P3/8, vòng 2/3, đồng hồ, khoảng cách tới xe trước; kết thúc giữ khung hình về đích.
4. **Thông tin đường đua:** ví dụ “Harbor Oval · 75% đoạn thẳng”. Gợi ý ngắn dựa trên chỉ số thật: “Động cơ tăng tốc độ trên đoạn thẳng”.
5. **CTA:** “Đua chặng 1” trước đua; “Đang đua” bị khóa khi chạy; “Xem kết quả” nếu đã xong và người chơi đang ở tab khác.
6. **Nâng cấp nhanh:** Động cơ, Lốp và Cơ sở. Mỗi ô có cấp, tác dụng hiện tại → sau nâng, giá và nút mua. Garage chứa đủ 4 bộ phận.
7. **Nhiệm vụ:** chỉ hiện một nhiệm vụ gần hoàn tất cùng nút mở danh sách.

Wireframe:

```text
┌──────────────────────────────────┐
│ [Avatar]  1.000 tiền      100 gem │
│ Thu nhập 8/giây                   │
│ Tập sự · Chặng 1/5       [Lịch]   │
│ Harbor Oval · 75% đoạn thẳng      │
│ ┌──────────────────────────────┐ │
│ │ P3/8       Vòng 2/3    00:38 │ │
│ │       ĐƯỜNG ĐUA 2D          │ │
│ │       Xe số 01: Bạn         │ │
│ └──────────────────────────────┘ │
│ [          ĐUA CHẶNG 1         ] │
│ Động cơ cấp 0    40 → 42    120  │
│ Lốp cấp 0       40 → 42    120  │
│ Cơ sở cấp 0      8 → 8,96/s 150  │
│ [Đua][Tay đua][Garage][Giải][Shop]│
└──────────────────────────────────┘
```

**Trạng thái:** đủ tiền → mua ngay; thiếu tiền → nút hiện giá, bị khóa, kèm “Thiếu 35”; tối đa → “Cấp tối đa”; đang đua → nâng cấp thi đấu bị khóa, cơ sở vẫn mua được; đang nhận kết quả → khóa CTA đua mới.

Nút mua không đổi vị trí sau giao dịch. Hiển thị chỉ số tăng ngay và làm mới giá tiếp theo. Không yêu cầu xác nhận cho nâng cấp dùng tiền mềm; có bước xác nhận khi dùng gem ở phiên bản mở rộng.

### UI-02 — Tay đua

- Hàng đầu: người đang thi đấu, chân dung, tên, 3 chỉ số Pace / Technique / Composure và cấp huấn luyện.
- Danh sách: 3 tay đua ban đầu; An được sở hữu sẵn, Bình và Chi mở theo mốc. Mỗi thẻ ghi rõ Đang thi đấu / Có thể chọn / Điều kiện mở.
- Chi tiết: mô tả vai trò, chỉ số chính xác, preview thay đổi khi chọn, giá và hiệu quả lần huấn luyện tiếp theo.
- CTA chọn chỉ có khi đã sở hữu và đang ngoài cuộc đua. Không bán tay đua và không có merge trong MVP.
- Khi đổi người, xe không đổi; preview chỉ số tổng cập nhật ngay. Không hiển thị một điểm sức mạnh duy nhất như lời bảo đảm thắng.

### UI-03 — Garage

- MVP có một xe, 4 hàng nâng cấp: Động cơ, Lốp, Khung gầm, Hộp số.
- Mỗi hàng: icon, cấp 0–20, chỉ số hiện tại → mới, giá tiếp theo.
- Khối dưới có Cơ sở cấp 0–20, thu nhập hiện tại → mới; phân biệt bằng nhãn “Kinh tế”.
- Nút thông tin giải thích chỉ số bằng ngôn ngữ hành vi: “Lốp giúp xe giữ tốc độ qua cua”; phần chi tiết có giá trị số.
- Khi đang đua, phần thi đấu hiện “Có thể nâng sau khi đua”; không trừ tiền hoặc xếp hàng mua ngầm.
- Xe thứ hai, skin và trang bị là nội dung mở rộng, chưa hiện các ô khóa hàng loạt trong MVP.

### UI-04 — Giải đấu

- Tiêu đề giải, mùa hiện tại, điểm hiện có và mục tiêu thăng hạng 36/50.
- Danh sách 5 chặng: đường đua, kết quả nếu đã chạy, chặng tiếp theo, chặng chưa mở.
- Bảng quy đổi vị trí → điểm có thể mở xem. Chỉ có bảng kết quả của người chơi, chưa giả lập BXH mùa của cả tám đội.
- Kết thúc mùa: tổng điểm, thưởng mùa, trạng thái thăng hạng hoặc ở lại. Nút “Bắt đầu mùa mới” là bước xác nhận; không tự xóa màn tổng kết.
- Sau giải cao nhất hiển thị “Bảo vệ danh hiệu”: chơi mùa mới cùng độ khó, không làm tăng chỉ số giải vô hạn.

### UI-05 — Kết quả cuộc đua

- Vị trí, bảng 8 xe, tổng thời gian, điểm mùa nhận được, thưởng tiền.
- Một dòng giải thích lấy từ log thật: số lần lỗi, thời gian chậm do bám xe. Không tạo nguyên nhân thua ngẫu nhiên như “thiếu động cơ” nếu không đo được.
- Thưởng cơ bản được ghi save trước khi mở panel. Đóng/mở lại không phát thưởng lần hai.
- Nếu reward ads đã tích hợp và có quảng cáo sẵn: nút phụ “Xem quảng cáo · +120 tiền”, ghi đúng phần tiền cộng thêm. Không nhân điểm mùa.
- Nếu chưa tích hợp SDK: không hiện nút quảng cáo hoạt động giả trong bản phát hành. Mockup có thể bỏ hoàn toàn.
- Sau chặng 1–4: CTA “Tiếp tục”. Sau chặng 5: CTA “Tổng kết mùa”.

### UI-06 — Thu nhập vắng mặt

- Chỉ mở khi vắng ít nhất 60 giây; hiển thị thời gian được tính, rate, hệ số 50%, số tiền thực nhận, trần 2 giờ.
- CTA “Tiếp tục”; tiền đã ghi save khi panel xuất hiện. Không yêu cầu xem quảng cáo để nhận phần cơ bản.
- Không thông báo đội đã thắng các cuộc đua khi offline. Thu nhập cơ sở và tiến trình giải là hai hệ thống khác nhau.
- Nếu thiếu dữ liệu hoặc giờ thiết bị lùi: nhận 0, không làm âm tiền; không đổ lỗi cho người chơi bằng thông báo gian lận.

### UI-07 — Cửa hàng và nhiệm vụ

- MVP: quà miễn phí 200 tiền mỗi ngày, không yêu cầu mạng; reset theo ngày UTC. Nhận xong có giờ reset và trạng thái đã nhận.
- Bản mở rộng: gói chào mừng, cosmetic, rewarded ads, No Ads. Mỗi offer phải nêu vật phẩm, giá thật do store trả về, điều kiện và phạm vi No Ads.
- Không tự bật cửa hàng khi mở game hoặc sau mỗi cuộc đua.
- Nhiệm vụ MVP là chuỗi một lần, panel 3 hàng: hoàn thành đua đầu, mua 3 cấp nâng cấp bất kỳ, hoàn tất mùa đầu. Thưởng chi tiết ở tài liệu Gameplay.

### UI-08 — Cài đặt

Âm nhạc, hiệu ứng, rung, giảm chuyển động, ngôn ngữ; phiên bản build. Trong prototype chỉ cần tiếng Việt. Nút xóa tiến trình có xác nhận riêng, nêu rõ sẽ mất tiến trình local. Tài khoản, khôi phục mua và consent chỉ xuất hiện khi các hệ thống đó đã triển khai.

## 5. Onboarding liên kết Gameplay

1. Cho thấy xe An và 1.000 tiền; giải thích vai trò chủ đội trong một câu.
2. Hướng dẫn nâng Động cơ một lần, giá 120. Chỉ số 40 → 42, tiền còn 880 trước thu nhập theo thời gian.
3. Giới thiệu xe và tay đua đang sử dụng; cuộc đua sẽ chạy tự động.
4. Chạy chặng đầu. Chỉ đánh dấu xe người chơi, vị trí và vòng; không chồng nhiều tooltip.
5. Nhận thưởng, xem điểm mùa, gợi ý Cơ sở giúp tăng thu nhập.
6. Mở điều hướng đầy đủ. Có nút bỏ qua; các bước đã thực hiện không bị yêu cầu làm lại.

Onboarding không bảo đảm thắng bằng một kết quả dựng sẵn. Nếu muốn thử cảm giác chiến thắng đầu game, điều chỉnh đối thủ tutorial bằng cấu hình và kiểm chứng bằng nhiều seed.

## 6. Phản hồi, lỗi và tính nhất quán

| Tình huống | UI mong muốn |
|---|---|
| Mua khi vừa thiếu tiền | Không trừ; cập nhật số thiếu; không mở cửa hàng |
| Bấm đua hai lần | Chỉ tạo một race_id; nút khóa ngay |
| Đổi tab giữa cuộc đua | Cuộc đua tiếp tục; tab Đua có trạng thái đang chạy |
| App ra nền | Dừng tiến trình đua; trở lại hiện thu nhập vắng mặt rồi tiếp tục đua |
| Tải save lỗi | Thông báo phục hồi bản sao; không ghi đè bằng save trắng tự động |
| Không có quảng cáo | Không khóa thưởng cơ bản; hiện trạng thái tạm chưa có nếu nút đã được mở |
| Đang offline | Các màn MVP hoạt động; tính năng cần mạng sau này ghi đúng trạng thái |
| Từ chối mua/cancel | Giữ nguyên màn và số dư |

## 7. Phạm vi theo giai đoạn và nghiệm thu UI

**Prototype:** UI-01, UI-03, UI-05; 1 đường đua; tài nguyên, nâng cấp và kết quả thật.

**MVP:** đủ 5 tab, 3 đường đua, 3 tay đua, 3 giải, offline, nhiệm vụ, save, onboarding. Cửa hàng chỉ có quà miễn phí; không cần backend/SDK.

**Sau MVP:** IAP, rewarded ads, cosmetic; sau đó mới cân nhắc nhiều hạng xe, sưu tầm, sự kiện, club.

Tiêu chí nghiệm thu:

- Từ Đua, tối đa 2 lần chạm để nâng bộ phận hoặc chọn tay đua đã sở hữu.
- Mọi giao dịch luôn thấy giá và thay đổi trước khi bấm.
- Tài nguyên đồng nhất trên mọi tab; không có nút có vẻ mua được khi tiền không đủ.
- Hiển thị rõ 3 trạng thái trước/trong/sau cuộc đua; các khóa nâng cấp/chọn người đúng tài liệu Gameplay.
- Không tràn chữ/số và không bị safe area che trên các kích thước quy định.
- Khôi phục đúng panel kết quả/mùa/offline sau khi app bị đóng; không lặp thưởng.
- Người mới sau 5 phút giải thích được sự khác nhau giữa nâng cơ sở và nâng xe. Đây là mục tiêu usability cần đo, chưa phải kết quả kiểm thử.

## 8. Gói mockup đi kèm

Mockup trong cuộc trò chuyện cho phép đổi tab, mua nâng cấp và xem một kết quả minh họa. Dùng để duyệt thứ bậc thông tin và tương tác; thời gian chạy rút ngắn và kết quả minh họa không thay thế mô phỏng hoặc cân bằng Gameplay.
