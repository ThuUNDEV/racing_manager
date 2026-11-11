# Trang bị — đối chiếu Race Star đang chơi, v0.5

Ngày: 10/11/2026. **Ưu tiên người dùng: bám sát bản mới nhất của game gốc trước.** Chưa triển khai gameplay Godot. Tài liệu này thay toàn bộ v0.1; [bản cũ](14_Driver_Equipment_v0_1_Superseded.md) chỉ lưu lịch sử, không dùng để triển khai.

## 1. Mốc tham chiếu

Nguồn chính: quan sát trực tiếp cửa sổ Race Star của người dùng trên **Google Play Games cho Windows**, ngày 10/11/2026. Người dùng cho biết đang chơi bản mới nhất. **Chưa đọc số version/build trong ứng dụng**, nên không khẳng định trùng bản Android/iOS hay mới nhất toàn cầu. Giá trị quan sát thuộc tài khoản/loại đua hiện tại; có thể khác theo cấu hình máy chủ.

Nguồn phụ: [Google Play](https://play.google.com/store/apps/details?id=com.coolcatsgames.racestaridle&hl=en) và [App Store](https://apps.apple.com/us/app/race-star-team-manager-game/id6782871814). Mô tả chính thức xác nhận gear, shards và coupons nhưng không giải thích chi tiết cách dùng. Lịch sử App Store ghi nhận gear từng được làm lại; không dùng video cũ mà chưa kiểm tra phiên bản.

Ảnh ở [References/RaceStar_2026-11-10](References/RaceStar_2026-11-10/), dùng nội bộ vì có thông tin tài khoản trong cửa sổ; không đưa vào tài nguyên game hoặc xuất bản.

Nguồn bổ sung v0.3: người dùng đang chơi xác nhận trực tiếp trong chat ngày 10/11/2026: mở gói nhận phụ kiện; nếu đã có thì đổi ra mảnh để nâng level; phụ kiện tự tăng sức mạnh toàn đội; Equipped 3/30 là sở hữu 3 trên tổng 30 phụ kiện; một coupon bằng một lần mở gói. Đây là thông tin người dùng xác nhận, không phải các giao dịch đã được agent thử trong tài khoản.

Bổ sung v0.4, người dùng xác nhận tiếp cùng ngày: **mảnh riêng cho từng phụ kiện; nâng level chỉ tốn mảnh; coupon Standard và Elite là hai loại riêng; game dùng coupon trước gem**. Các quy tắc này thay các điểm chưa rõ tương ứng của v0.3.

Bổ sung v0.5: người dùng xác nhận **ngôi sao thể hiện level; số mảnh cần nâng và giới hạn level phải cấu hình được**. Không cần sao chép bảng ngưỡng nâng hoặc khóa trần năm level từ ảnh tham chiếu. Các giá trị cân bằng cụ thể sẽ nằm trong dữ liệu, chưa được chốt trong lượt xác nhận này.

## 2. Đã xác minh trực tiếp

| Hạng mục | Quan sát | Bằng chứng |
|---|---|---|
| Lối vào | Tab túi riêng, thứ hai từ trái trên thanh đáy bảy biểu tượng | [Tổng quan](References/RaceStar_2026-11-10/gear_overview.png) |
| Khung chung | Tài nguyên và thu nhập trên cùng, khung đua tiếp tục chạy, nội dung tab bên dưới | Tổng quan |
| Gói thường | STANDARD GEAR — Chance to get Epic Gear; Open x1 = 10 gem, x10 = 100 gem | Tổng quan |
| Gói cao cấp | ELITE GEAR — Chance to get Legendary Gear; Open x1 = 30 gem, x10 = 300 gem | Tổng quan |
| Tỉ lệ thường | Rare 85%, Epic 15% | [Standard Gear](References/RaceStar_2026-11-10/standard_gear.png) |
| Tỉ lệ cao cấp | Epic 85%, Legendary 15% | [Elite Gear](References/RaceStar_2026-11-10/elite_gear.png) |
| Thông tin gói | Nút i mở modal Drop Information; X đóng, không mua | Hai modal |
| Kho | INVENTORY, EQUIPPED 3 / 30, lưới ba cột | [Kho](References/RaceStar_2026-11-10/balaclava.png) |
| Thẻ có dữ liệu | Balaclava, nền/viền xanh, hình vải trùm đầu | Kho |
| Chỉ số | Biểu tượng kiếm đỏ +20, khiên xanh +20 | Kho |
| Tiến độ | Balaclava: 0/10; hàng năm vị trí sao tối ở đầu thẻ | Kho |
| Thẻ chưa có thông tin | Nền xanh/tím nhạt, dấu ? lớn | Kho |
| Đua vẫn chạy | Đồng hồ/vị trí đổi khi ở tab và khi xem modal | Quan sát trực tiếp |

Tỉ lệ là xác suất **bậc trang bị**, chưa phải từng món. x10 có giá đúng mười lần x1; chưa thấy giảm giá hoặc bảo đảm trong gói gear. Không lấy “guaranteed in 14 draws” của gói tay đua sang trang bị.

## 3. Vòng lặp đã được người dùng xác nhận

```text
Mở gói → nhận phụ kiện
  Chưa sở hữu → thêm vào bộ sưu tập → tự cộng sức mạnh toàn đội
  Đã sở hữu  → quy đổi ra mảnh → dùng mảnh nâng level phụ kiện
```

- **Sở hữu là có hiệu lực toàn đội**: không thiết kế lắp/tháo hoặc chia đồ theo từng tay đua. Không có preset An/Bình hay giao dịch chuyển món.
- **30 phụ kiện trong bộ sưu tập**; 3/30 là số mẫu đã sở hữu, không phải số ô đang lắp. Nhận trùng không tăng bộ đếm sở hữu.
- **Một coupon = một lượt mở gói**, có hai ví riêng: Standard và Elite. Dùng coupon đúng loại trước gem; không dùng chéo hai loại. Với x1, khi có coupon phù hợp thì tiêu một coupon và không tiêu gem; hết coupon mới dùng giá gem của gói. x10 tương ứng mười lượt; cách thanh toán khi chỉ có 1–9 coupon còn cần xác nhận, chưa mặc định tự bù gem.
- **Mảnh riêng từng phụ kiện; nâng level chỉ tốn mảnh của chính phụ kiện đó**, không trừ coins/gem/coupon và không tiêu mảnh của món khác. Món trùng chỉ cộng vào số mảnh của đúng mẫu. Ngưỡng mảnh theo từng level và trần level đọc từ cấu hình; lượng mảnh quy đổi khi trùng vẫn chưa có giá trị xác nhận.
- **Ngôi sao thể hiện level**: một nguồn dữ liệu level duy nhất, không tạo thêm tiến trình sao độc lập. Các lần nâng đều cập nhật level và số sao tương ứng.
- Không tự thêm chế tạo chọn món, huấn luyện bằng coins hoặc thưởng vật liệu cố định sau đua. Các nguồn nhận ngoài mở gói còn cần xác minh.

## 3.1. Chi tiết còn cần xác nhận

- Đã biết tổng 30 phụ kiện và bonus toàn đội, nhưng chưa có đủ tên/chỉ số 30 món hoặc quy tắc giữ bonus khi đổi bộ môn.
- Kiếm/khiên chưa có tooltip; không gán công thức Attack/Defense hoặc chuyển sang P/T/C.
- Thanh tiến độ dùng mảnh riêng hiện có / ngưỡng cấu hình cho lần nâng kế tiếp. 0/10 chỉ là trạng thái trong ảnh, không phải hằng số áp dụng mọi món/level.
- Đã xác nhận sao thể hiện level và trần level cấu hình được. Chưa thấy thao tác nâng thực tế, mức level khi nhận món lần đầu hoặc giá trị cân bằng cuối; không suy ra trần cố định 5 từ năm vị trí sao của ảnh.
- Balaclava có nền xanh, phù hợp màu Rare trong modal nhưng chưa đọc được nhãn độ hiếm trực tiếp; đây mới là suy luận hình ảnh.
- Đã xác nhận hai loại coupon và ưu tiên coupon trước gem; còn thiếu nguồn coupon và thanh toán x10 khi chỉ có 1–9 coupon phù hợp.
- Đã xác nhận món mới vào bộ sưu tập, món trùng đổi mảnh; còn thiếu số phụ kiện mỗi lượt, lượng mảnh quy đổi, pity và animation kết quả.
- Chưa quan sát thao tác nâng level; nhấn thân thẻ đang thấy không mở thêm panel. Không dựng panel nâng như thể đã thấy trong game. Lắp/tháo không còn là điểm chờ vì bonus tự áp dụng.
- Chưa xác minh điều kiện mở tab, quà tutorial, nguồn nhận khi thắng, trao đổi, giữ đồ khi chuyển bộ môn hoặc thời điểm bonus có hiệu lực.

Cửa sổ game không còn xuất hiện khi đang đọc kho; đã dừng điều khiển và không tự mở lại. Không mua/open gói, nâng đồ, thay đội hoặc tiêu gem trong lượt đối chiếu. Số dư có thể tăng do vòng đua tự chạy.

## 4. Thay đổi so với v0.1

| V0.1 tự đề xuất | Hướng hiện tại |
|---|---|
| Bốn ô mũ/găng/đồ/giày từng người | Bỏ; sở hữu phụ kiện tự tăng sức mạnh toàn đội |
| 12 mẫu, ba độ hiếm tự đặt | Bộ sưu tập 30 phụ kiện; dùng Rare/Epic/Legendary đã đọc, tên/chỉ số danh mục còn mở |
| Chế tạo món tự chọn bằng vật liệu chung | Bỏ; mở gói nhận món, trùng đổi mảnh nâng level |
| Bỏ coupon | Hai loại coupon Standard/Elite riêng, ưu tiên trước gem; mảnh riêng từng mẫu |
| Cộng P/T/C cố định | Bỏ; ghi chỉ số kiếm/khiên, mapping sim còn mở |
| Cấp 1–5, giá coins theo R_ref | Trần level/ngưỡng mảnh cấu hình được; sao biểu thị level; không có giá coins |
| +2 vật liệu/lượt, +6/mùa, gói đầu 40 | Bỏ toàn bộ nguồn thưởng tự thiết kế |
| Preset và chuyển An/Bình | Bỏ vì bonus tự áp dụng toàn đội |
| Đội → Tay đua → Trang bị | Thay mockup bằng tab túi riêng; điều hướng dự án cần cập nhật khi tích hợp |

Các tài liệu 03/05/06 trước đây loại gacha/gear hoặc dùng năm tab sẽ cần cập nhật khi triển khai hướng mới; không dùng giới hạn cũ để tiếp tục giản lược trái chỉ đạo bám gốc. Giữ tám nâng cấp, BigNumber và save hiện hành hoạt động khi tích hợp.

## 5. Luồng UI có bằng chứng để dựng

1. Mở tab túi, giữ tài nguyên và khung đua phía trên.
2. Hiện hai gói cạnh nhau: tên, phụ đề, i, Open x1/x10 và giá đã đọc.
3. Nhấn i mở Drop Information, hai hàng xác suất, nút X, nền game tối đi. Game phía dưới tiếp tục chạy.
4. Dưới gói: INVENTORY, EQUIPPED 3/30 từ fixture quan sát, lưới ba cột. Balaclava có sao, hình, tên, kiếm/khiên và 0/10; các thẻ chưa thấy nội dung giữ ?.
5. Nội dung tab cuộn bên dưới khung đua, thanh đáy ở cạnh dưới.

Luồng kết quả đã chốt ở mức hành vi: món mới thêm bộ sưu tập và tăng bộ đếm; món trùng đổi mảnh và không tăng bộ đếm; mảnh dùng nâng level, bonus tăng cho toàn đội. Khi UI được bổ sung phải phân biệt “Mới” và “Trùng → +N mảnh”; N lấy từ cấu hình đã xác minh, không tự đặt. Không có CTA lắp/tháo/chuyển người.

Chưa dựng giao dịch mở/nâng đầy đủ trước khi rõ loot table, lượng mảnh và chi phí level. Mockup v0.2 vẫn chỉ cho xem/đóng bảng tỉ lệ; nút Open bị khóa, chưa giả phát đồ/trừ tài nguyên. Nhãn nghiên cứu ở ngoài khung game. Đây là giới hạn mockup, không phải hành vi gốc. Chưa cập nhật mockup với số coupon hoặc lượng mảnh minh họa để tránh đưa thêm giả định.

## 6. Mockup v0.2

Nguồn: [race_star_gear_reference.html](Mockups/race_star_gear_reference.html). Ảnh: [tổng quan](Mockups/race_star_gear_reference.png), [modal Standard](Mockups/race_star_gear_standard.png).

Giữ bố cục/nhãn để đối chiếu: trắng/xám nhạt, xanh lam/tím cho gói, xanh lá cho kho, khung đua graphite và sân xanh; chưa áp màu Workshop GP. Icon dùng biểu tượng sơ đồ, không chép asset độc quyền. Khung đua tĩnh, số dư snapshot, không kết nối tài khoản.

Dựng sáu thẻ đầu đã thấy vị trí; người dùng đã xác nhận bộ sưu tập có tổng 30 phụ kiện, nhưng mockup hiện chưa dựng đủ danh mục. Chỉ Balaclava có dữ liệu; năm ô ? thể hiện phần giao diện đã thấy, không khẳng định vị trí hai món sở hữu còn lại.

## 7. Dữ liệu và giao dịch dự kiến

Cấu trúc chức năng đã chốt: hai gói (`id`, giá x1/x10, phân bố bậc), catalog 30 gear, tập sở hữu duy nhất theo mẫu; mỗi mẫu lưu `level` và `shards`; ví coupon tách `standard`/`elite`; kết quả nhận gói. Một mẫu mới chỉ được thêm một lần; bản trùng quy đổi mảnh đúng mẫu trong cùng giao dịch. Bộ đếm sở hữu tính từ tập mẫu, không cộng theo số lần roll. Bonus toàn đội tính từ các mẫu sở hữu và level, không cần bảng loadout từng người.

Nâng level là giao dịch chỉ sửa mảnh và level của mẫu được chọn; không đụng ví coins/gem/coupon hoặc mảnh mẫu khác. Giá mảnh đọc từ bảng cấu hình level, kiểm tra lại khi commit, rollback cả level và mảnh khi lưu lỗi. Mỗi lần nâng trừ đúng ngưỡng, giữ phần mảnh dư, tăng level một bậc và cập nhật sao từ cùng level. Màn nâng hiển thị mảnh hiện có/cần, level/sao hiện tại → tiếp theo và chỉ số trước/sau; không thêm giá coins. Đạt trần hiển thị “Cấp tối đa”, không đọc giá vượt bảng. Bố cục chi tiết vẫn cần ảnh thực tế để bám gốc.

### Hợp đồng cấu hình level và mảnh

Đây là đặc tả dữ liệu đề xuất để đáp ứng yêu cầu cấu hình, chưa thêm file runtime:

| Trường | Vai trò |
|---|---|
| `initial_level` | Level khi lần đầu nhận phụ kiện; phải không âm và không vượt `max_level` |
| `max_level` | Level tối đa; không viết cứng bằng 5 trong code hoặc UI |
| `level_up_shards` | Bảng ánh xạ level hiện tại → số mảnh cần để lên level kế; đầy đủ từ `initial_level` tới `max_level - 1` |
| `stats_by_level` | Chỉ số kiếm/khiên ở từng level; tách khỏi giá nâng để đổi cân bằng độc lập |
| `duplicate_shards` | Lượng mảnh của chính mẫu khi nhận trùng; để trong cấu hình, giá trị còn cần chốt |

Cho phép dùng bộ cấu hình chung theo độ hiếm và ghi đè từng phụ kiện; phân giải ra một cấu hình hiệu lực trước khi validate. Không tự tạo đường tăng giá hoặc ngưỡng thiếu. Ngưỡng nâng phải là số nguyên dương; level/giá trị mảnh là số nguyên; bảng chỉ số phải có đủ các level hợp lệ. Catalog có tổng 30 mẫu theo tham chiếu đã xác nhận.

UI dùng level làm số sao đã đạt, phân biệt sao đạt/chưa đạt bằng hình và màu. Nếu `max_level` lớn làm hàng sao không vừa, reflow hoặc dùng nhãn sao kèm `Lv. N / Max` thay vì thu nhỏ vô hạn; đây là quy tắc thích ứng cấu hình của dự án, chưa phải bố cục đã quan sát trong game gốc. Không tăng sức mạnh từ cả level lẫn sao hai lần.

Save chỉ lưu tiến trình `level` và `shards` theo mẫu; không lưu một trường sao độc lập. Nếu cấu hình thay đổi ngưỡng, giữ mảnh đã tích, kiểm tra lại giá mới khi nâng. Nếu giảm `max_level` xuống dưới level đã sở hữu, yêu cầu migration có phiên bản trước khi áp cấu hình; không tự cắt level, xóa mảnh hoặc để UI đọc chỉ số ngoài bảng.

**Chưa chốt schema save cuối, các giá trị cân bằng của bảng cấu hình hoặc mapping chỉ số vào mô phỏng.** Cơ chế level/sao, ngưỡng mảnh có cấu hình, mảnh riêng và hai ví coupon đã rõ. Không giả định tăng trực tiếp P/T/C khi chưa rõ kiếm/khiên. Khi roll x10, xử lý theo thứ tự: nếu một mẫu xuất hiện lần đầu rồi lặp trong chính gói đó, lần sau phải là trùng; lưu toàn bộ kết quả nguyên tử. Đây là quy tắc tích hợp suy ra từ hành vi đã xác nhận, chưa phải giao dịch x10 đã quan sát thực tế.

Khi code: kiểm tra giá/ví, ghi kết quả roll và trừ tiền cùng giao dịch, ID chống nhận trùng, giữ kết quả qua crash, rollback khi lưu lỗi; không roll lại khi reload. Snapshot race đang chạy không đổi giữa chừng theo yêu cầu tương thích dự án; thời điểm game gốc áp bonus vẫn cần xác minh. Đây là yêu cầu kỹ thuật dự án, không phải cơ chế đã đọc từ bản gốc.

## 8. Bằng chứng còn cần

| Cần xem | Để chốt |
|---|---|
| Version/build trong app hoặc gói đã cài | Mốc phiên bản cụ thể |
| Toàn kho và món đã có | Tên/chỉ số đủ 30 phụ kiện; ý nghĩa 3/30 đã được xác nhận |
| Tooltip kiếm/khiên, đội trước/sau | Ý nghĩa và công thức chỉ số; bonus toàn đội đã xác nhận |
| Màn coupon, nguồn miễn phí | Nguồn nhận, thanh toán x10 thiếu coupon; hai loại, tỉ lệ 1:1 và ưu tiên đã xác nhận |
| Kết quả gói mới/trùng | Số món mỗi lượt, lượng mảnh, trình bày kết quả; mảnh riêng và quy tắc mới/trùng đã xác nhận |
| Món đủ nâng trước/sau | Bố cục và phản hồi nâng; sao=level, giá chỉ mảnh và ngưỡng/trần cấu hình đã chốt; còn thiếu mức khởi đầu/chỉ số thực |
| Đổi bộ môn/đội, reload | Sở hữu, persistence, thời điểm hiệu lực |

Không tiêu tài nguyên tài khoản đang chơi chỉ để điền bảng. Dùng tài khoản thử hoặc ghi nhận phiên người dùng chủ động thao tác tiếp theo.

## 9. Nghiệm thu

- Mỗi giá/tỉ lệ/nhãn truy được tới ảnh; phần chưa rõ để mở, không thế bằng công thức tự đặt.
- Hai bảng tỉ lệ đủ 100%; x10 đúng giá quan sát, không gán pity của driver pack.
- Mockup mở/đóng modal bằng chuột và bàn phím, không thay số dư khi xem tỉ lệ.
- Khi triển khai: món mới tăng bộ đếm đúng một mẫu; trùng chỉ tăng mảnh; x10 trùng ngay trong cùng batch được xử lý đúng; nâng level không nhân đôi mẫu hoặc cộng bonus nhiều lần sau reload; toàn đội nhận bonus mà không phải lắp đồ.
- Kiểm tra món A trùng/nâng không thay mảnh món B; nâng không trừ coins/gem/coupon; mở Standard không tiêu coupon Elite; có coupon đúng loại thì x1 không tiêu gem; lỗi lưu hoàn tác toàn giao dịch và không đổi phương thức thanh toán ngầm.
- Kiểm tra cấu hình với nhiều trần level và bảng ngưỡng khác nhau: không viết cứng 5 hoặc 10; đúng giá ở biên, giữ mảnh dư, khóa ở max, bảng thiếu bị từ chối; sao và level luôn đồng nhất, không cộng bonus hai lần. Cấu hình giảm trần không làm mất tiến trình âm thầm.
- Kiểm tra 320/360/390/412 logical px; hai gói và kho ba cột không tràn. Runtime Godot, save, RNG/giao dịch và cân bằng kiểm chứng sau khi triển khai thật.

Đã kiểm tra mockup v0.2 bằng Edge headless: mở/đóng cả hai modal, Escape, tỉ lệ đúng, bốn giao dịch mở gói bị khóa, sáu thẻ phần kho đã thấy; không lỗi JavaScript hoặc tràn ngang ở 320/360/390/412 px. Đã xem ảnh tổng quan 390 px. Đây là kiểm tra trình duyệt, chưa phải nghiệm thu Godot hoặc kiểm chứng cơ chế nâng đồ.
