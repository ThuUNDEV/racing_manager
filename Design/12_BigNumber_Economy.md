# Pitlane Club — Economy v2 dùng BigNumber

Ngày: 10/11/2026. Trạng thái: **đã triển khai lõi BigNumber/economy v2 vào gameplay ngày 10/11/2026; cân bằng còn cần playtest**. Xem [biên bản triển khai](13_Economy_v2_Implementation.md). Yêu cầu đã chốt: dùng **BigNumber**, hỗ trợ tiền lên triệu, tỷ, nghìn tỷ, triệu tỷ và cao hơn. Các hệ số, thời gian và cơ chế mở rộng bên dưới là phương án thiết kế để triển khai/playtest, chưa phải cân bằng đã duyệt.

## 1. Phạm vi và thứ tự áp dụng

Tài liệu này thay phần công thức coins, giá mua xe/nâng cấp, thưởng coins, nhịp tiến trình và định dạng tiền trong [05](05_Economy_Monetization.md). Giữ vòng lặp đua liên tục ở [10](10_Continuous_Race_Loop.md) và đúng tám nâng cấp ở [11](11_Eight_Upgrades.md): bốn bộ phận xe và Ticket Marketing, Victory Celebrations, Parking, Grandstands. Tay đua có kỹ năng nền cố định, không trở lại cơ chế huấn luyện bằng tiền.

Thay đổi cần có so với thiết kế cũ: bỏ hệ số tiền `3^L`, giá `5^L/5^k`, legacy cộng rate và các giá xe cố định cũ; thay bằng thang kinh doanh chung. Bỏ gem lặp mỗi mùa. Chỉ số đua, seed, hình học, tám xe, 5 chặng/mùa, ngưỡng 36 điểm và điều kiện hạng xe giữ nguyên; phải kiểm tra lại chúng bằng sim trước khi khẳng định thời gian thăng giải.

Hiện trạng đã đọc ngày 10/11: `GameState` dùng save v3, ví `coins:int`, bốn nguồn doanh thu đã có cấu hình; prototype vẫn cố định `LEAGUE = 0`. Tài liệu 10 và một số phần 04/07 mô tả trạng thái cũ; mã hiện tại đã có countdown và đua theo thời lượng tính từ track. Đây là hiện trạng trước triển khai. Mã hiện tại đã chuyển sang BigNumber/save v4; biên bản 13 phân biệt phần đã làm với giới hạn còn lại.

## 2. Vòng lặp và vai trò tiền tệ

Đầu tư doanh thu → có coins đều đặn → chọn đầu tư tiếp hoặc nâng xe → đua lấy điểm và thưởng → đủ điều kiện mở giải → mua xe bắt buộc nếu có → trả chi phí mở cơ sở kinh doanh của giải mới → bắt đầu thang tiền tiếp theo.

| Giá trị | Kiểu | Vai trò |
|---|---|---|
| Coins, tổng kiếm/tổng tiêu | BigNumber | Tiền mềm dùng chung xuyên giải, không đổi tiền |
| Giá, doanh thu/giây, phần thưởng, dự toán offline | BigNumber | Toàn bộ đường tính coins dùng cùng kiểu |
| Gem | int | Mỹ phẩm và tiện ích, không tăng theo thang coins |
| Điểm mùa, SP, cấp, chỉ số giải/hạng xe | int | Tiến trình và dữ liệu rời rạc |
| Thời gian và chỉ số chuyển động | float thông thường | Chỉ chuyển thời gian thành hệ số nhân cho BigNumber; không chuyển tiền thành float |

Coins đầu game = 1.000; gem = 100. Không phí đua, không mất coins vì thua. Không thêm vé, năng lượng hoặc tiền prestige. BigNumber là kiểu dữ liệu, không phải tiền tệ mới.

## 3. Thang kinh doanh

Đặt `b = 0..5`, tương ứng giải đang kinh doanh; `S(b) = 10^(3b)` và hệ số nhịp `Q(b) = [1,2,4,8,16,32]`. `S` làm tiền lớn dần; `Q` kéo dài thời gian đầu tư ở nội dung sau. Nâng cả tiền lẫn giá cùng `S` không tự tạo tiến trình dài hơn.

| b | Giải | S | Q | Rate khởi đầu | Rate nếu cả 4 nguồn cấp 20 |
|---:|---|---:|---:|---:|---:|
| 0 | Tập sự | 1 | 1 | 8/s | 5,038K/s |
| 1 | Bán chuyên | 1K | 2 | 8K/s | 5,038M/s |
| 2 | Chuyên nghiệp | 1M | 4 | 8M/s | 5,038B/s |
| 3 | Quốc gia | 1B | 8 | 8B/s | 5,038T/s |
| 4 | Châu lục | 1T | 16 | 8T/s | 5,038AA/s |
| 5 | Thế giới | 1AA | 32 | 8AA/s | 5,038AB/s |

Đây là **rate**, không phải cam kết số dư. Người chơi thường tiêu tiền liên tục; bảng mốc số dư phải đo riêng. BigNumber hỗ trợ vượt xa sáu bậc này; bản nội dung đầu chỉ có sáu bậc, không tự sinh giải/độ khó vô hạn.

### Mở bậc kế tiếp

1. Hoàn tất một mùa đạt ít nhất 36 điểm; ghi quyền mở giải kế đúng một lần.
2. Bốn nguồn doanh thu của cơ sở hiện tại đều từ cấp 12. Xe đủ hạng theo 04; nếu cần thì mua xe mới bằng giá cố định ở §5.
3. Có đủ phí mở rộng ở §5. Màn Giải hiển thị rõ các điều kiện còn thiếu; mùa tại giải hiện tại vẫn tự chạy.
4. Người chơi bấm **Mở cơ sở [tên giải]**. Giao dịch được xếp vào ranh giới lượt: hoàn tất và lưu thưởng lượt đang chạy trước, rồi trừ phí, đổi bậc, cấp vốn và lưu; chỉ sau đó countdown giải mới. Snapshot không dùng lẫn hai economy. Nếu mùa hiện tại chưa đủ 5 chặng, lưu lịch sử mùa dở và không phát thưởng hoàn tất; giải mới bắt đầu mùa có serial mới ở chặng 1. Kiểm tra lại giá, quyền mở và tiền tại lúc commit; không đủ thì hủy lệnh chờ và tiếp tục giải cũ.

Khi mở bậc: giữ ví, xe sở hữu, cấp của từng xe, tay đua, gem, SP, thành tích và lịch sử. Bốn nguồn doanh thu bắt đầu cấp 0 tại **cơ sở mới**; cơ sở cũ lưu cấp trong lịch sử, không còn cộng doanh thu. Màn xác nhận ghi rõ trước/sau; đây là thay đổi tiến trình được đề xuất trong bản này, không phải reset ngầm.

Vốn khai trương cấp một lần = `1.000 × Q(b_mới) × S(b_mới)` coins. Bậc 0 đã có 1.000 ban đầu nên không cấp thêm. ID `business_open/<b>` gắn cùng giao dịch mở rộng; không thể quay về bậc cũ để nhận lại. Không bán lại xe hoặc cơ sở, không chuyển bậc qua lại để farm.

Doanh thu cũ tối đa `5.038 × S(b)`; rate cơ sở mới là `8.000 × S(b)`, nên việc chuyển không làm giảm rate ngay cả khi cơ sở cũ đã max. Giá mới cũng tăng tương ứng; vốn khai trương giúp có vài quyết định mua ngay.

## 4. Bốn nâng cấp doanh thu

Đặt `t,c,p,g = 0..20`, là cấp tại cơ sở hiện tại:

```text
ticket      = 8 + 2,5t
celebration = 7,5c
parking     = 12,5p
capacity    = 10 + 5g
R(b,t,c,p,g) = S(b) × (ticket + celebration + parking) × capacity/10
```

Victory Celebrations là nguồn coins/giây; không phụ thuộc thắng. Grandstands nhân tổng ba nguồn, không tự tạo một dòng thu nhập thứ tư độc lập. Mọi hiệu ứng kinh tế áp dụng ngay, kể cả đang đua/countdown; phần thưởng lượt dùng snapshot riêng ở §6.

Giá mua cấp `n → n+1`:

```text
cost_i(b,n) = S(b) × ceil(base_i × Q(b) × 1,45^n)
base = Ticket:150, Celebration:300, Parking:500, Grandstands:800
```

Làm tròn **trước khi nhân S** để cấu hình, game và mô hình ra cùng giá. `1,45` thay `1,2` ở 11: giới hạn 20 nhưng mỗi cơ sở cần đủ thời gian đầu tư. Cấp 0 không phải giá cấp 1 sau tăng trưởng.

Ví dụ b0, cấp 0: rate 8/s. Mua Ticket giá 150 → 10,5/s; Celebration giá 300 → 15,5/s nếu mua riêng từ đầu; Parking giá 500 → 20,5/s; Grandstands giá 800 → 12/s. Quyết định thực tế phụ thuộc cấp của cả bốn nguồn.

UI mỗi mục hiển thị giá, rate trước/sau, tăng thêm/s và thời gian hoàn vốn `giá / Δrate`. Đây là chỉ báo tại trạng thái hiện tại, không hứa tổng thời gian hoàn vốn khi người chơi tiếp tục mua các mục khác. Không tự mua, không thưởng rate bí mật theo hành vi.

## 5. Bộ phận xe, xe mới và các khoản tiêu

### Bốn bộ phận

Giữ tối đa 20 cấp/bộ phận/xe và chỉ số `nền xe + 2n`. Cấp xe không nhân với BigNumber, nên tăng tiền không làm tốc độ hay tọa độ đua thành số khổng lồ.

```text
part_cost(car,n) = S(entry_tier) × ceil(120 × Q(entry_tier) × 1,45^n)
```

`entry_tier` cố định theo danh mục: xe hạng 1 = 0; hạng 2 = 2; hạng 3 = 3; hạng 4 = 4; hạng 5 = 5. Không định giá theo ví hay rate hiện tại. Xe hạng 1 dùng ở Bán chuyên vẫn có giá nâng bậc 0; giới hạn cấp/hạng xe chặn việc dùng xe cũ vô hạn. Xe đã mua giữ nguyên cấp khi mở cơ sở mới. Mua trong race chỉ áp dụng từ lượt sau.

### Phí mở rộng và mua xe

Đặt `R12(b) = R(b,12,12,12,12) = 1.946 × S(b)`.

| Khoản | Công thức | Mốc b0 minh họa |
|---|---|---:|
| Phí mở bậc b+1, trả tại b | `300 × Q(b) × R12(b)` | 583.800 |
| Xe bắt buộc của bậc b+1, nếu đổi hạng | `600 × Q(b) × R12(b)` | Không cần xe mới để vào b1 |
| Biến thể thứ 2/3 của hạng mới | Giá xe bắt buộc × 1,5 / 2 | Không bắt buộc thăng giải |
| Hai xe hạng 1 bổ sung | 2.500 / 5.000 | Giữ giá khởi đầu |

Ví dụ từ b1 sang b2: xe hạng 2 = 2,3352B; mở cơ sở = 1,1676B. Tổng 3,5028B, chưa tính nâng xe. Xe mới mở mua khi đã mở quyền vào giải đích, có thể chọn ở giải cũ; phần thưởng vẫn theo cơ sở đang kinh doanh.

Mốc xe/thưởng không dùng `giá = rate hiện tại × thời gian` lúc bấm mua: người chơi nâng doanh thu phải rút ngắn được thời gian chờ. Các hằng số 300/600 là hệ số thiết kế cố định theo bậc, không phải giá động.

### Mua nhiều cấp

Bản đầu dùng x1. Chuẩn bị API tính tổng giá bằng lặp tối đa 20 cấp với cùng quy tắc ceil từng cấp; x10 và Max có thể bật sau. Max dùng tìm nhị phân số cấp đủ tiền, kiểm tra lại tổng và giới hạn trước giao dịch; không dùng công thức tổng hình học chưa làm tròn để trừ tiền. Báo hiệu quả tổng trước khi mua.

## 6. Nguồn coins và chống ảnh hưởng từ độ dài race

### Online

Mỗi khoảng gameplay thực sự hoạt động `dt` giây, cộng `R × dt` bằng BigNumber. Không floor riêng từng frame; ví nội bộ có phần lẻ, UI hiển thị coins nguyên. Không cộng thêm một dòng `base_rate` ngoài bốn nguồn. Ngừng tích lũy online khi app nền/loading; khoản vắng mặt xử lý một lần bằng offline.

### Thưởng chặng

Chốt `R_start`, cấu hình economy, bậc và thời lượng `d` tại xuất phát; `C = 3 + d`. Với prototype hiện tại, d có thể được tính từ thời gian vòng chuẩn của track; thiết kế này không ép mọi track về 60 giây.

```text
F(P1..P8) = [1, 0,9, 0,8, 0,7, 0,6, 0,5, 0,45, 0,4]
race_coins = floor(R_start × C × 0,25 × F(position))
```

Ở rate 8, d=60: P1 = 126, P2 = 113, P3 = 100, P8 = 50 coins. Đây là bảng mới thay thưởng cố định cũ. Giảm race xuống 30 giây không nhân đôi thưởng/giờ vì thưởng tỷ lệ cả chu kỳ C. Chỉ race thực sự hoàn tất mới có thưởng; không trả cho abort. Các chế độ ×4/skip của công cụ dev không được bật trong build phát hành hoặc sinh tiến trình phát hành.

### Thưởng mùa, quà ngày, thăng giải

```text
season_coins = floor(0,10 × tổng(R_start_i × C_i) của đúng 5 chặng)
daily_coins  = floor(600 × R_claim)
```

Thưởng mùa không cần thắng và không nhân thêm Q/S lần nữa. Với rate cố định, tổng thưởng chặng + mùa tăng thu nhập online dài hạn khoảng 20% ở P8 đến 35% ở P1, trước sai số floor. Mua doanh thu giữa race có tác dụng online ngay nhưng thưởng của race đó không thay đổi.

Quà ngày: một lần/ngày UTC, rate và số tiền khóa khi tạo giao dịch nhận, không khóa khi chỉ mở màn Shop. Không trả bù ngày bỏ lỡ. Không phát thêm thưởng coins "thăng giải" cũ 300×3^L: vốn khai trương đã thay vai trò này. Nhiệm vụ bổ sung sau này dùng ngân sách thời gian thu nhập cố định theo bậc và công khai, phải mô phỏng lại tổng faucet trước khi bật.

## 7. Offline, gem và monetization

- Offline = `floor(R_saved × 0,5 × min(max(now-last,0), cap_seconds))`; mặc định 2 giờ. Lưu **BigNumber R_saved**, không tính theo bậc/rate mới sau khi trở lại. Không race, không điểm mùa/SP/gem tự sinh offline. Thời gian <60s cộng nhưng không panel.
- Một đoạn thời gian thuộc online hoặc offline. Khi vào nền, chốt mốc; khi boot/resume, giao dịch offline cập nhật mốc và ví cùng lúc. Khôi phục save/retry không cộng lại. Đồng hồ lùi cho thưởng 0 và cập nhật mốc.
- Gem đầu 100. Đề xuất 20 gem cho **lần đầu hoàn tất mùa ở mỗi giải** (6 ID), 50 cho **lần đầu mở năm giải sau**; quà ngày 5 gem. Thành tích/mỹ phẩm khác cần ngân sách riêng. Không 20 gem mỗi mùa lặp 5 phút vì sẽ tạo nguồn gem vô hạn quá nhanh.
- SP theo điểm chặng và danh mục tuyển ở 05; khoản coins tuyển mỗi tay đua = `S(entry_tier_driver) × Q(entry_tier_driver) × scout_base_coins`, với base hữu hạn công khai cho từng người. Triển khai ban đầu chốt base = `600 × 5^tier_tay_đua`, entry_tier theo điều kiện mở trong danh mục; không đưa lại driver_level hoặc academy bonus. Chi phí tuyển vẫn chưa nằm trong mô hình §12, cần đo lại.
- Giữ các mở trần offline của 05 (4/8/12h với 150/400/800 gem) như giá khởi đầu. Lợi ích thực của offline tăng theo cap; phải mô phỏng lịch quay lại trước khi bán. Không coi đây là cân bằng đã xác minh.
- Ads/IAP thuộc giai đoạn sau: giữ quyền nhận thưởng cơ bản; mọi coins gói/quảng cáo được chốt bằng BigNumber và transaction ID. Gói khởi đầu tối đa 60 phút rate đang có, khóa số khi giao dịch bắt đầu và lưu trong receipt context. Chưa đưa doanh thu ads/IAP vào nhịp chuẩn. Không tự bật ads, SDK hay shop khi triển khai lõi economy.

## 8. Đặc tả BigNumber

### Quyết định

Dùng **số thập phân có 24 chữ số có nghĩa và số mũ tách riêng** cho coins. Đây là độ chính xác hữu hạn có chủ ý, không tuyên bố lưu chính xác mọi chữ số của số vô hạn. Không dùng float64 đơn thuần cho toàn bộ ví; không cần lưu hàng trăm chữ số zero để biểu diễn 1e300.

Biểu diễn giá trị không âm:

```text
value = coefficient × 10^(exponent - 23)
10^23 <= coefficient < 10^24; exponent là số mũ khoa học cơ số 10
zero: coefficient=0, exponent=0
ví dụ 1,25e30: coefficient="125000000000000000000000", exponent=30
```

Đề xuất `core/math/big_number.gd`, thuần logic, immutable. Triển khai hiện tại lưu coefficient bằng chuỗi 24 chữ số, cộng/trừ/nhân/chia dài trên từng chữ số thập phân. Chọn cách này để dễ kiểm chứng trong GDScript; không nhét coefficient vào int64 và không dựng toàn bộ giá trị bằng `pow(10, exponent)` float. Kết quả chuẩn hóa và làm tròn 24 chữ số sau mỗi phép tính. Có thể tối ưu thành limb sau nếu profiling cho thấy cần, giữ nguyên API/save format.

Giới hạn ứng dụng: exponent -1.000.000 đến +1.000.000; vượt phạm vi là lỗi cấu hình/giao dịch, giữ save hiện có, không clamp thành tiền tối đa hoặc cho Infinity. Số âm dùng ở lớp delta riêng `{direction, amount}`; ví/giá/rate từ chối giá trị âm. Coefficient của zero phải canonical.

### API và phép tính

`zero`, `from_int`, `parse_decimal`, `parse_scientific`, `compare`, `add`, `subtract_checked`, `multiply`, `divide`, `multiply_ratio(int,int)`, `pow_nonnegative_int`, `floor`, `ceil`, `to_save`, `from_save`, `format_compact`, `format_scientific`.

- Các số thập phân cân bằng như `1.45`, `0.5`, `2.5` nạp từ **chuỗi** hoặc tỷ lệ nguyên; thời gian được lượng tử thành microsecond rồi dùng `multiply_ratio(us, 1_000_000)`. Không parse tiền lớn qua float rồi chuyển lại BigNumber.
- Cộng/trừ: căn exponent, giữ 24 chữ số cùng guard/round/sticky trước làm tròn. Nhân/chia: chuẩn hóa sau phép toán. Làm tròn về gần nhất, hòa thì chữ số cuối chẵn; `floor/ceil` là phép riêng. Chia 0, parse lỗi, subtract thiếu tiền đều trả kết quả lỗi, không sửa đối tượng gốc.
- Độ phân giải tại exponent e là `10^(e-23)`. Ví dụ 1e30 có đơn vị biểu diễn 1e7: cộng 1 coin có thể không thay đổi ví. Đây là đánh đổi được chấp nhận cho coins ở quy mô đó; gem và điểm mùa vẫn chính xác nguyên. Giao dịch được đánh dấu xử lý dù thay đổi dưới độ phân giải; không retry mãi vì ví không đổi.
- So đủ tiền dùng `compare` trên giá trị chuẩn, không dựa trên text UI và không dùng epsilon để cho mua thiếu. Trừ xong không âm. Tăng/giảm cực nhỏ có thể mất khi làm tròn ở quy mô lớn; giới hạn cấp và reward ID vẫn phải giữ chính xác.
- Online gom dt của một giây hoặc một tick kinh tế ổn định trước khi credit; giữ pending income cùng save để phần lẻ không mất ở mỗi frame. Chốt pending trước giao dịch/suspend. Hai lần chia frame khác nhau phải cho tổng cùng trong sai số 1 đơn vị biểu diễn; chưa đạt thì chưa phát hành.
- Không chuyển BigNumber sang `int`/`float` trong `Pricing`, wallet, offline, rewards, save hoặc formatter. Chỉ UI biểu đồ/progress dùng tỷ lệ đã clamp 0..1, không dùng tỷ lệ đó để quyết định giao dịch.

### Save và cấu hình

```json
{
  "coins": {"significand": "125000000000000000000000", "exponent": 30},
  "saved_online_rate": {"significand": "800000000000000000000000", "exponent": 15}
}
```

Significand là **chuỗi 24 chữ số**, zero chỉ dùng `"0"`; exponent là JSON integer trong miền cho phép. Kiểm tra canonical trước khi dùng. Cấu hình mới lưu mọi literal tiền/hệ số thập phân dưới chuỗi khoa học/thập phân; không đưa `1e30` JSON number vào đường đọc float. Các mốc BigNumber analytics dùng coefficient string + exponent và log10, không ép về int64.

## 9. Hiển thị và trải nghiệm mua

| Bậc | Hậu tố | Cách gọi tiếng Việt |
|---:|---|---|
| 10^3 | K | nghìn |
| 10^6 | M | triệu |
| 10^9 | B | tỷ |
| 10^12 | T | nghìn tỷ |
| 10^15 | AA | triệu tỷ |
| 10^18 | AB | tỷ tỷ |
| 10^21 / 10^24 / 10^27 / 10^30 | AC / AD / AE / AF | Tiếp tục mỗi bậc ×1.000 |
| 10^90 | AZ | Kết thúc nhóm A |
| 10^93 | BA | Bắt đầu nhóm B |
| 10^168 | BZ | Kết thúc nhóm B |
| 10^1965 | ZA | Bắt đầu nhóm Z |
| 10^2040 | ZZ | Kết thúc bảng hậu tố hai chữ |
| từ 10^2043 | `1,23e2043` | Ký hiệu khoa học sau khi hết ZZ |

**Quy tắc đã chốt theo người dùng:** `K → M → B → T → AA → AB → … → AZ → BA → BB → … → BZ → … → ZA → ZB → … → ZZ`. Chữ bên phải tăng A–Z trước, hết Z thì chữ bên trái tăng một bậc. Mỗi lần đổi hậu tố là ×1.000; không dùng Qa/Qi hoặc tên số tiếng Anh làm hậu tố.

Với nhóm nghìn `g = floor(exponent / 3)`: g=1..4 dùng K/M/B/T. Từ g=5, đặt `i=g-5`; nếu 0≤i<676 thì hậu tố là `alphabet[floor(i/26)] + alphabet[i%26]`, với `alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"`. Vượt ZZ dùng ký hiệu khoa học, không quay vòng AA và không làm thay đổi giá trị BigNumber.

Đơn vị đổi theo nhóm 1.000; dùng tối đa 3 chữ số có nghĩa, bỏ zero thập phân cuối. Locale vi dùng dấu phẩy thập phân, dưới 1.000 hiển thị số nguyên. Ví `1.250.000` → `1,25M`; `1e9` → `1B`; `1e15` → `1AA`; `1e18` → `1AB`. Không hiển thị `1000M` hay chuỗi số tràn thẻ.

Giá và số dư trên thẻ **cắt xuống** ở độ chính xác hiển thị để không đổi sang bậc kế trước khi thực sự đạt; formatter phân nhóm lại sau mọi phép làm tròn được dùng ở báo cáo. Chạm/nhấn giữ mở dạng khoa học với tối đa 24 chữ số có nghĩa; chỉ hiển thị dạng đầy đủ nếu exponent ≤23 và vừa khung. Không bịa chữ số chính xác đã mất trong làm tròn.

Nếu hai số hiển thị giống nhau nhưng `compare` vẫn thiếu tiền, nút ghi "Thiếu ..." bằng formatter có độ chính xác tăng dần hoặc ước tính thời gian còn thiếu; không cho nút sáng sai. Sau mua hiện cấp và hiệu ứng thật, kể cả thay đổi ví dưới độ phân giải ở giai đoạn muộn. Coins không cần modal xác nhận từng cấp; mở cơ sở có màn xem trước vì đổi cơ sở và cấp doanh thu. Gem dùng xác nhận riêng.

## 10. Giao dịch, migration và tích hợp

Một lệnh mua/thưởng/mở rộng tạo `transaction_id`; tính trạng thái mới trên bản sao immutable, xác thực → ghi file tạm và kiểm tra → thay save chính → publish state/UI. Ghi thất bại giữ giao dịch pending và có retry; không bắt đầu lượt mới hoặc phát thêm giao dịch cùng ID. Reopen app đọc bản cuối đã commit; reward hoặc capital chưa commit không được coi đã hoàn thành. Không cần triển khai SQLite để có nguyên tắc này.

**Save v4 đề xuất** (v3 hiện có): coins, pending income, R_saved, money trong kết quả/lịch sử, reward payload và counters đều chuyển BigNumber. Thêm `business_tier`, `revenue_levels_by_tier`, `economy_version`, `business_open` IDs và trạng thái giao dịch nếu cần. Giữ race checkpoint, ownership và skill snapshots.

- Save v2 đi qua migration v2→v3 ở 11 (hoàn training đúng một lần), rồi v3→v4. Refund phải diễn ra trước chuyển giá mới; không hoàn theo giá Q/S mới.
- Save v3 hiện tại chỉ ở b0: giữ nguyên số dư, bốn cấp doanh thu và cấp xe; b=0; không cấp lại 1.000. Giá mua tiếp theo đổi theo v2, không hoàn toàn bộ các cấp cũ. UI changelog giải thích thay đổi giá nếu bản này có người dùng thật.
- Đọc JSON tiền nguyên cũ bằng token thập phân gốc, không thông qua float. Với save từng bị làm tròn trước đây không thể suy ra phần đã mất; giữ giá trị thực sự có trong file, không tự dựng lại. Hỗ trợ fixture sát ngưỡng int64 và số nguyên >2^53.
- Reward đã nhận giữ ID; không phát lại quà ngày, thưởng mùa, offline hoặc opening capital. Race đang dở giữ payload economy cũ hoặc legacy reward descriptor để chốt đúng giá trị đã snapshot, áp economy mới từ lượt kế.
- Lưu backup cũ trước migrate; file mới hỏng/phiên bản mới hơn khóa ghi theo boot flow. Migration và đổi schema chỉ commit một lần, retry không hoàn training/cấp vốn lặp.

Các điểm sửa khi triển khai: `GameState` wallet/thu nhập/giao dịch/save; `Pricing` và `Balance`; `GameData` schema validation; `data/economy.json`, giá xe/tuyển; tất cả text tiền trong `ui/main.gd` và reward cards; startup offline; test fixtures và analytics. Các file runtime đó đã được cập nhật ở đợt triển khai ghi trong biên bản 13.

## 11. Cấu hình đề xuất

Các literal tiền/hệ số decimal dùng chuỗi; số cấp/ID là int. Ví dụ cấu trúc để triển khai, chưa phải JSON schema đã được GameData hỗ trợ:

```json
{
  "economy_version": 2,
  "number_format": {
    "precision_digits": 24,
    "base_suffixes": ["K", "M", "B", "T"],
    "alphabetic_suffix_start": "AA",
    "alphabetic_suffix_end": "ZZ",
    "scientific_from_exponent": 2043
  },
  "start_coins": "1e3",
  "start_gems": 100,
  "business": {
    "scale_exponents": [0, 3, 6, 9, 12, 15],
    "pacing": [1, 2, 4, 8, 16, 32],
    "opening_reserve_base": "1000",
    "expansion_rate_seconds": 300,
    "required_car_rate_seconds": 600,
    "reference_revenue_level": 12,
    "expansion_min_revenue_level": 12
  },
  "upgrade_growth": "1.45",
  "revenue_max_level": 20,
  "part_max_level": 20,
  "revenue_cost_bases": ["150", "300", "500", "800"],
  "part_cost_base": "120",
  "rewards": {
    "race_ratio": "0.25",
    "position_factors": ["1", "0.9", "0.8", "0.7", "0.6", "0.5", "0.45", "0.4"],
    "season_ratio": "0.1",
    "daily_rate_seconds": 600
  },
  "offline": {"ratio": "0.5", "cap_seconds": 7200}
}
```

Validate đủ sáu bậc tăng dần, Q dương, tám ID nâng cấp không trùng, 8 position factors dương, growth>1, mức mở ≤max, prices/rates hữu hạn không âm, không vượt miền BigNumber; từ chối cấu hình lỗi trước gameplay. Economy version snapshot cùng giao dịch/lượt; remote config chỉ áp giữa lượt và không thay kiểu số/precision hay diễn giải save.

## 12. Mô hình và giới hạn bằng chứng

Chạy `python Design/Economy/economy_v2_model.py` từ root; kết quả lưu [economy_v2_report.json](Economy/economy_v2_report.json). Mã dùng Python Decimal 40 chữ số để kiểm tra đường tiền, **không phải triển khai hoặc kiểm định BigNumber Godot**. Lượng thời gian tính bước 1 giây, cho mua tức thời; rate thưởng snapshot sau countdown 3 giây.

Hai chiến lược giả lập: `roi` xếp nâng doanh thu theo cost/Δrate, xếp nâng xe theo cost/2 rồi so cùng hàng ưu tiên (heuristic, không phải tối ưu toàn cục); `cheapest` mua mục rẻ nhất. Cả hai mua đúng bộ mục tiêu, không mua doanh thu quá cấp 12 trước mở bậc, không mô phỏng chọn xe/track/AI. Mục tiêu xe 8 ở b0, 10 ở b1–4, 20 ở b5 chỉ là ngân sách tham chiếu; **không phải ngưỡng thắng đã xác nhận**. B1 giữ xe hạng 1 và cấp đã mua; b2–5 dùng xe mới.

| Bậc | P2/ROI, phút trong bậc | P2/rẻ nhất, phút trong bậc | P8/ROI, phút trong bậc |
|---:|---:|---:|---:|
| 0 | 10,30 | 15,77 | 10,50 |
| 1 | 34,02 | 36,02 | 37,00 |
| 2 | 68,25 | 93,38 | 74,90 |
| 3 | 135,43 | 184,12 | 148,63 |
| 4 | 268,80 | 366,57 | 296,18 |
| 5 — hoàn thiện toàn bộ 20 cấp | 972,50 | 1.389,72 | 1.073,47 |

P2/ROI: khoảng **8,61 giờ online** đến mở Thế giới, **24,82 giờ** để hoàn thiện cả sáu bậc. P2/rẻ nhất: khoảng **34,76 giờ** hoàn thiện. Đây là thời gian **đủ tiền và cấp theo giả định**, không cộng thời gian chờ đủ điểm/thắng mùa. P8 không thể đạt 36 điểm nên **không thể thăng giải thật**; cột đó chỉ so độ nhạy nguồn coins khi thứ hạng thấp, mô hình tài chính vẫn cho chuyển bậc giả định.

Kiểm tra thời lượng với P2/ROI: tổng ở chu kỳ 33s ≈24,75h; 63s ≈24,82h; 93s ≈24,88h. Không hoàn toàn bằng nhau do thời điểm payout, snapshot và floor. Tất cả 30 bậc trong 5 kịch bản đạt mục tiêu tài chính dưới giới hạn 24h/bậc. Không có chứng minh optimality hay playtest người thật. Mô hình chuyển bậc tức thì khi đủ mục tiêu tài chính, bỏ qua thời gian chờ ranh giới lượt và không trả thưởng phần mùa chưa đủ 5 chặng khi chuyển.

Offline, quà ngày, SP/tuyển, collection, livery, ads, IAP, menu delay, dao động thứ hạng và nội dung hết sau sáu bậc chưa được đưa vào mô hình. Vì vậy **chưa quy đổi sang số ngày retention**, chưa khẳng định đủ nội dung 3–4 tuần. Ở max b5, 2h offline đã bằng 1h online passive; có thể rút ngắn mạnh mục tiêu cuối. Phải chạy lịch 3 phiên ×5 phút/ngày, 1 phiên/ngày, 8h/24h vắng và trường hợp mở rộng cap trước soft launch.

## 13. Tiêu chí kiểm chứng và thứ tự triển khai

1. **BigNumber độc lập:** chuẩn hóa zero, carry/borrow, cộng/trừ khác exponent, nhân/chia, ceil/floor, 999,999K→1M boundary, parse/save round-trip, 1e300 × 1e300, miền exponent, input hỏng và giá trị dưới độ phân giải. Đối chiếu oracle decimal 40+ chữ số; sai số tối đa 0,5 đơn vị biểu diễn sau mỗi phép làm tròn. Không đánh đồng golden economy với golden chuyển động.
2. **Lõi economy:** chuyển wallet/rate/giá/reward/offline và UI cùng đợt, không cho một đường mua còn int. So giá/thu nhập tại b0, b2, b5 và trạng thái ví giả lập 1e60, 1e300. Giữ gem/điểm chính xác. Cùng 600s hoạt động ở 30/60/120 FPS phải cùng tổng trong sai số đã công bố; bật/tắt app không khai thác được pending income.
3. **Save/giao dịch:** migration v2/v3, giá trị >2^53, đủ/thiếu đúng đơn vị cuối, hỏng save, disk write fail, kill trước/sau commit, retry và crash lúc mở rộng. Mọi ID coin/gem/opening reserve chỉ commit một lần.
4. **Bậc và gameplay:** triển khai league động thay LEAGUE=0; tích hợp ownership xe, điều kiện hạng và khóa chuyển ở ranh giới race; đủ tiền nhưng không đủ điểm không chuyển. Ở max cơ sở cũ, rate mới không giảm. Nâng kinh tế giữa race không tăng thưởng đã snapshot. Chạy TrafficSim nhiều seed ở cả sáu giải để đo số mùa tới 36 điểm và ngân sách thực.
5. **Cân bằng:** so ba cách mua (ROI, rẻ nhất, ưu tiên xe), các lịch online/offline, P1..P8, 30/60/90s và duration theo track; thêm SP/collection, rồi mới ads/IAP. Điều chỉnh Q/giá, không sửa race để ép người chơi chờ tiền. Mục tiêu thử nghiệm: phiên đầu có ≥3 quyết định mua hữu ích; b0 mở trong 10–20 phút online khi đủ điểm; không có ngõ cụt tài chính; người P8 vẫn mua được nâng cấp giúp cải thiện thật.

Theo dõi: thời gian chờ tới mua tiếp theo (P50/P90), bậc/phút chơi, số cấp mua sau offline, tỷ trọng nguồn–khoản tiêu, số dư theo log10, tỷ lệ hết tiền và dừng ở điều kiện xe/điểm/phí mở rộng. Báo cáo tách thời gian hoạt động, offline và lịch thực; một con số tiền lớn trên UI không phải bằng chứng economy đã cân bằng.
