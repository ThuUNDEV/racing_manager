# Trang bị tay đua — v0.1 ĐÃ THAY THẾ

> Không dùng để triển khai. Người dùng yêu cầu bám sát game gốc trước; [v0.2](14_Driver_Equipment.md) thay toàn bộ phương án tự đề xuất dưới đây.

Ngày: 10/11/2026. Trạng thái: **đề xuất để duyệt, chưa triển khai vào Godot**. Mockup tương tác đi kèm dùng dữ liệu minh họa, không thay đổi save thật.

## 1. Mục tiêu và căn cứ

Tạo một mục tiêu phát triển lâu dài bên cạnh tám nâng cấp hiện có: đua → nhận vật liệu → chế tạo trang bị → lắp cho tay đua → nâng cấp → quan sát thay đổi ở lượt kế tiếp. Trang bị đi theo đội qua các bậc kinh doanh, không bị reset khi mở cơ sở.

Tham chiếu: [Race Star trên Google Play](https://play.google.com/store/apps/details?id=com.coolcatsgames.racestaridle) mô tả trang bị tay đua, mảnh và coupon để mở/nâng thiết bị. Chưa xác minh trực tiếp số ô, bảng rơi, loại vật phẩm hay công thức của bản gốc. **Toàn bộ danh mục, số liệu và quy tắc dưới đây là đề xuất của dự án**, không phải bản sao cơ chế đã kiểm chứng. Bản đầu dùng nhận thưởng/chế tạo xác định; coupon và hộp ngẫu nhiên chưa thuộc phạm vi này.

Nền hiện hành: [10](10_Continuous_Race_Loop.md) đua nối lượt; [11](11_Eight_Upgrades.md) kỹ năng nền tay đua cố định; [12](12_BigNumber_Economy.md) BigNumber; [13](13_Upgrade_Ladder_200.md) tám nâng cấp cấp 0–200. Trang bị bổ sung P/T/C, không khôi phục huấn luyện bằng coins, không thêm dòng nâng cấp thứ chín vào Garage.

## 2. Phạm vi và mở khóa

- Mở sau khi **hoàn tất mùa đầu tiên**, bất kể thứ hạng. Save cũ đã có ít nhất một mùa hoàn tất được mở ngay.
- Cấp một lần 40 vật liệu để người chơi tự chọn chế tạo bốn món Tiêu chuẩn; không ép chi tiêu hết. ID thưởng `equipment_intro/v1`.
- Bản đầu: 4 ô, 12 mẫu, chế tạo, nâng cấp cấp 1–5, lắp/tháo/chuyển, so sánh, kho dùng chung và preset riêng từng tay đua.
- Chưa có set bonus, chỉ số phụ ngẫu nhiên, độ bền, bán/phân rã, reroll, coupon, mua vật liệu bằng gem/tiền thật, trang bị giới hạn, tự lắp tối ưu hay phần thưởng offline cho trang bị.
- Không thêm tab điều hướng toàn cục. Vào **Đội → Tay đua → Trang bị**; nhóm Đội là nơi danh sách tay đua hiện nằm trong runtime.

## 3. Ô trang bị và danh mục

Mỗi tay đua có bốn ô. Mỗi mẫu chỉ sở hữu một bản trong cả đội; chế tạo lại bị chặn, vật liệu không tự tiêu. Một món không thể ở hai tay đua cùng lúc. Cấp nâng thuộc món, không thuộc người mặc.

| Ô | Tiêu chuẩn (q=0) | Hiệu năng (q=1) | Elite (q=2) | Chỉ số nhận |
|---|---|---|---|---|
| Mũ | Mũ Rookie | Mũ Focus | Mũ Apex | 100% B vào Composure (C) |
| Găng | Găng Grip | Găng Precision | Găng Apex | 100% B vào Technique (T) |
| Bộ đồ | Bộ đồ Club | Bộ đồ Aero | Bộ đồ Apex | 50% B vào T, 50% B vào C |
| Giày | Giày Sprint | Giày Launch | Giày Apex | 100% B vào Pace (P) |

ID ổn định: `helmet_standard`, `helmet_performance`, `helmet_elite`; tương tự `gloves`, `suit`, `boots`. Tên hiển thị không dùng làm khóa save.

Độ hiếm gắn chữ và ký hiệu I/II/III, đồng thời màu xám/xanh lam/tím. Không chỉ dùng màu. Không có vật phẩm rơi ngẫu nhiên hoặc bậc bí mật.

| Bậc | Điều kiện chế tạo | Vật liệu chế tạo | Cấp khi tạo | Trần cấp |
|---|---|---:|---:|---:|
| Tiêu chuẩn | Mở tính năng | 10 | 1 | 5 |
| Hiệu năng | Mở cơ sở bậc 1 | 30 | 1 | 5 |
| Elite | Mở cơ sở bậc 3 | 80 | 1 | 5 |

Không cần hi sinh món cũ để tạo món mới. Món cấp cao hơn không mặc nhiên mạnh hơn món cũ đã nâng: ví dụ Tiêu chuẩn cấp 5 = B6, Elite cấp 1 = B4. Màn so sánh phải hiển thị đúng điều này.

## 4. Chỉ số và mô phỏng

```text
B(q, level) = 2 + q + (level - 1), q=0..2, level=1..5
P_effective = P_base + tổng P từ bốn món đã lắp
T_effective = T_base + tổng T từ bốn món đã lắp
C_effective = C_base + tổng C từ bốn món đã lắp
```

Giữ số thực, không làm tròn trước khi đưa vào sim. UI hiện tối đa một chữ số thập phân. S/H/B/A của xe và bốn nguồn doanh thu không thay đổi. Trang bị không tăng tiền thưởng, SP, thu nhập offline, thời lượng lượt hay hệ số AI.

Ví dụ An P40/T40/C40, bốn món Tiêu chuẩn cấp 1 → P42/T43/C43. Full Elite cấp 5 → P48/T52/C52. Đây là trần cộng dồn dự kiến, không phải cam kết tốc độ tăng bao nhiêu hay thắng giải nào.

`GameState.player_stats()` là điểm tích hợp dự kiến: lấy kỹ năng nền rồi cộng equipment bonus. `TrafficSim.setup()` nhận snapshot đã cộng sẵn; sim không đọc kho live. Không thêm RNG hoặc logic vượt mới. Chỉ số P/T/C đi qua công thức hiện có; không mô tả kỹ năng trang bị gây chặn xe hay va chạm.

### Thời điểm hiệu lực

- Mua, lắp, tháo, chuyển và nâng được thực hiện khi countdown/đang đua; áp dụng từ **snapshot lượt kế tiếp**. UI ghi “Áp dụng từ lượt sau”.
- Lượt đã tạo snapshot và checkpoint dùng đúng chỉ số cũ đến khi kết thúc, kể cả sau reload.
- Thao tác trong countdown trước khi snapshot lượt mới được tạo sẽ có hiệu lực ở lượt sắp bắt đầu.
- Mở kho hoặc xem chi tiết không tạm dừng cuộc đua. Không popup thưởng chặn tự nối lượt.
- Khi `save_error` hoặc đang commit giao dịch khác, khóa thao tác thay đổi và hiển thị lý do; vẫn xem được kho.

## 5. Vật liệu, giá và nhịp nhận

Một tài nguyên mới: **Vật liệu trang bị**, số nguyên không âm, không đổi sang coins/gem/SP. Dùng chung cho mọi mẫu và mọi bậc; không thêm bốn loại mảnh theo ô. Tách khỏi SP tuyển tay đua.

| Nguồn | Số nhận | Điều kiện |
|---|---:|---|
| Mở tính năng | 40 | Một lần, dùng cùng giao dịch mở khóa |
| Hoàn tất lượt đua thường | 2 | Mọi vị trí, sau khi tính năng đã mở |
| Hoàn tất mùa | 6 | Đủ 5 chặng, cộng thêm vào thưởng lượt cuối |

Mùa dùng để mở tính năng nhận gói 40, chưa cộng vật liệu 2+6 cho chính lượt mở khóa. Sau đó mỗi mùa đủ 5 lượt nhận 16 vật liệu. Mùa dở kết thúc do mở cơ sở không nhận 6; vẫn giữ vật liệu các lượt đã hoàn tất. Chưa có nhiệm vụ ngày runtime nên không lấy nhiệm vụ/ads làm nguồn bắt buộc. Không rơi khi chỉ nhận offline. Không giới hạn kho hoặc trần vật liệu khiến mất thưởng.

Chế tạo chỉ tốn vật liệu. Nâng cấp tốn vật liệu và coins:

| Lần nâng | Vật liệu: Tiêu chuẩn / Hiệu năng / Elite | Coins theo mốc tham chiếu |
|---|---|---|
| 1 → 2 | 4 / 8 / 12 | 15 × R_ref(b) |
| 2 → 3 | 8 / 16 / 24 | 30 × R_ref(b) |
| 3 → 4 | 12 / 24 / 36 | 45 × R_ref(b) |
| 4 → 5 | 16 / 32 / 48 | 60 × R_ref(b) |

`R_ref(b)` là rate của bậc kinh doanh hiện tại nếu bốn nguồn doanh thu đều cấp 120/200 theo 12–13; không dùng rate live của người chơi. Coins mỗi lần nâng = `ceil_BigNumber(R_ref(b) × 15 × level_trước_nâng)`. Tính bằng Pricing/BigNumber, không ép coins sang float. Giá phụ thuộc bậc hiện tại, không phụ thuộc bậc chế tạo; giữ trang bị cũ khi mở bậc. Panel phải làm mới dự toán khi đổi bậc và kiểm tra lại lúc bấm.

Ví dụ b0: `R_ref = 1.946 coins/s`; lần nâng cấp 1→2 tốn 29.190 coins và 4/8/12 vật liệu. Mockup ban đầu có 120.000 coins, 24 vật liệu, An đang dùng ba món Tiêu chuẩn cấp 1 (mũ, găng, bộ đồ); giày Sprint cấp 1 do Bình giữ, ô giày của An trống để thử chuyển đồ. Đây là fixture thao tác, không phải tình trạng save hay tài nguyên khởi đầu thật.

Nhịp lý thuyết sau gói mở khóa, chưa tính coins: một Tiêu chuẩn chế tạo mới cần 5 lượt; một Elite cần 25 lượt trọn 5 mùa để có 80 vật liệu. Nâng một Tiêu chuẩn 1→5 cần 40 vật liệu; một Elite 1→5 cần 120. Full bốn Elite chế tạo và max cần 800 vật liệu ≈ 250 lượt/50 mùa nếu bắt đầu từ 0 và đủ mùa. Đây là phép tính lượng vật liệu, **chưa phải thời gian playtest** vì thời lượng đua theo track/config có thể đổi.

## 6. Giao dịch, chuyển món và các trạng thái

1. Bấm một món mở chi tiết: loại, bậc, cấp, chỉ số, người đang dùng, điều kiện và giá chính xác.
2. Món chưa có: “Chế tạo · N vật liệu”; tạo xong không tự lắp hay thay đồ, CTA chuyển thành “Lắp cho An”.
3. Món đã có, đang rảnh: “Lắp cho An”; thay món cùng ô, món cũ về kho, miễn phí.
4. Món đang ở tay đua khác: “Chuyển từ Bình”; xác nhận ghi cả hai người và món sẽ tháo khỏi An. Chỉ chuyển món đang chọn; không tráo món cũ sang Bình. Bình để trống ô đó.
5. Món đang lắp: có “Tháo” và nút nâng cấp. Không cần xác nhận thao tác coins thông thường; chuyển giữa người cần xác nhận vì ảnh hưởng hai preset.
6. Thiếu tài nguyên: khóa CTA, ghi riêng “Thiếu N vật liệu” / “Thiếu X coins”. Món chưa đủ bậc: hiện điều kiện bậc, không đề nghị mua gem.
7. Cấp 5: “Cấp tối đa”, không hiện giá nâng giả. Sau chế tạo/lắp/nâng giữ vị trí cuộn và lựa chọn.

Nâng món ở tay đua dự bị vẫn hợp lệ; panel chỉ rõ người hưởng chỉ số. Đổi tay đua giữ preset riêng, không tự chuyển cả bộ. Chọn món mạnh hơn ở P nhưng giảm T/C phải hiện từng chênh lệch, không hiện điểm sức mạnh tổng hoặc dự báo thắng.

Mỗi thay đổi là một giao dịch nguyên tử: validate → chụp dữ liệu trước → thay vật liệu/coins/kho/preset → ghi save → xác nhận UI; lỗi ghi phục hồi toàn bộ. Khóa lặp bấm trong giao dịch. Lượt kết thúc và thao tác người chơi đi qua cùng hàng đợi commit; không ghi đè thưởng.

## 7. UI và mockup

Nguồn mockup cũ đã thay thế: [driver_equipment_v0_1_superseded.html](Mockups/driver_equipment_v0_1_superseded.html) (fragment tương tác cho viewer Codex; khi mở trực tiếp trong trình duyệt, icon phụ thuộc runtime Lucide). Ảnh cũ: [đang lắp](Mockups/driver_equipment.png), [xác nhận chuyển](Mockups/driver_equipment_transfer.png).

Phong cách Workshop GP: nền kem, khung graphite, cam cho CTA, vàng tài nguyên. Nội dung dọc, bố cục ở 390 logical px, reflow 320 px; chừa safe area khi vào Godot. Chữ có dấu, nút tối thiểu 44 px. Bậc có nhãn chữ, chênh lệch có dấu +/−.

| Màn | Nội dung / hành động |
|---|---|
| Tay đua — Trang bị | Chọn An/Bình, tổng P/T/C, 4 ô và món hiện tại, lối vào Kho |
| Kho | 12 mẫu, lọc theo ô, nhãn Đã có/Đang dùng/Chưa chế tạo/Khóa bậc |
| Chi tiết | So với món cùng ô ở tay đua đang chọn, chỉ số trước/sau, chế tạo/lắp/tháo, nâng cấp |
| Chuyển trang bị | Xác nhận người nhường, người nhận, món bị tháo; đồng ý/hủy |
| Nhận vật liệu | Dòng +2 vật liệu trong kết quả không chặn đua; +6 cùng tổng kết mùa |
| Chưa mở | Điều kiện “Hoàn tất mùa đầu tiên”, chưa có thao tác mua |

Mockup tương tác: chọn tay đua, đổi ô, lọc kho, chọn mẫu, chế tạo, lắp/tháo/chuyển có xác nhận, nâng với trừ tài nguyên, hiển thị khóa bậc/thiếu vật liệu/max cấp. Có lựa chọn bậc kinh doanh trong điều khiển xem thiết kế để duyệt ba tầng mở khóa; đây không phải nút cho người chơi đổi bậc miễn phí. Không giả lập đua hay phát thưởng. Thanh điều hướng hiển thị ngữ cảnh Đội; các tab ngoài tính năng không dẫn tới trang giả.

## 8. Dữ liệu và save dự kiến

Không thay runtime trong đợt thiết kế này. Khi triển khai, thêm `data/equipment.json` cho catalog, trọng số chỉ số, điều kiện, nguồn thưởng, chi phí, và service thuần `EquipmentRules` để tính/validate. UI chỉ gọi giao dịch GameState; không tự trừ ví.

```json
{
  "equipment": {
    "unlocked": true,
    "materials": 24,
    "owned": {"helmet_standard": {"level": 1}},
    "loadouts": {"driver_an": {"helmet": "helmet_standard"}},
    "intro_claimed": true
  }
}
```

Migration dự kiến save **v5 → v6**, xác minh lại version khi bắt đầu lập trình. Save cũ: kho rỗng, material=0, loadout rỗng; chỉ mở và cấp 40 nếu có bằng chứng mùa đã hoàn tất. Không suy luận từ coins hoặc số xe. Việc cấp intro là settlement sau load với ID lưu cùng ví, không lặp mỗi lần migration. Checkpoint race đang dở giữ nguyên stats/config cũ.

Tính mở khóa bằng cờ settlement bền vững và lịch sử mùa thực tế. Schema phải kiểm tra mẫu hợp lệ, cấp 1–5, tay đua sở hữu, ô đúng loại và một mẫu tối đa một người; save hỏng đi qua luồng phục hồi backup hiện có, không lặng lẽ xóa món. Thưởng vật liệu đặt trong cùng kết quả có ID race/season hiện hành, không dựng một cơ chế claim song song.

## 9. Kiểm chứng khi triển khai

- Bốn Tiêu chuẩn cấp 1 cho An = 42/43/43; full Elite cấp 5 = 48/52/52. Tháo/chuyển không để lại bonus ảo; dự bị không cộng vào người đua.
- Cùng snapshot và seed cho kết quả giống nhau; đổi đồ giữa lượt không sửa checkpoint hoặc kết quả đang chạy; lượt mới dùng đúng đồ mới.
- Chế tạo/lắp/nâng/chuyển, chạm kép, hết coins/vật liệu, đổi bậc trong lúc xem giá, crash và lỗi save không gây mất hoặc nhân đôi đồ/tài nguyên.
- Migration cũ, intro, reload kết quả/mùa không lặp thưởng; lượt mở khóa không nhận cộng thêm 2+6; mùa dở không nhận 6.
- Lab so sánh không đồ / Tiêu chuẩn / Elite với cùng xe, tay đua, track, bậc và nhiều seed; đo quãng đường, lỗi và tỷ lệ thắng, không suy ra chỉ từ +chỉ số. Kiểm tra đồ không thay doanh thu/thời lượng/AI và không bỏ qua yêu cầu hạng xe, doanh thu, phí mở cơ sở.
- Mục tiêu cân bằng: full Elite tạo khác biệt quan sát được nhưng không khiến xe thiếu hạng hoặc xe chưa đầu tư thống trị giải kế; điều chỉnh B/chi phí sau lab. Chưa có kết quả xác nhận.
- Kiểm tra UI 320/360/390/412 px: tên dài, giá BigNumber, thiếu tài nguyên, khóa, max; chuyển món bằng bàn phím/touch, tương phản và dấu tiếng Việt.

## 10. Thứ tự bàn giao

1. Duyệt thiết kế và mockup này; mọi số liệu vẫn là cấu hình khởi đầu.
2. Catalog + EquipmentRules + migration + giao dịch + thưởng có idempotency.
3. Snapshot sim và kiểm chứng cân bằng.
4. UI Godot + art riêng cho 12 món + onboarding ngắn sau mùa đầu.
5. QA save/runtime/thiết bị; chỉ sau đó thay các ô “Sắp có” phù hợp. Gói trang bị quảng cáo/IAP tiếp tục chờ thiết kế nguồn thưởng và tích hợp riêng.

Tài liệu này đề xuất mở rộng phạm vi trang bị vốn ngoài v1.0 ở 03 và thêm một tài nguyên vào 05. Không tự coi thiết kế đã duyệt hay đổi phạm vi phát hành; khi chốt, cập nhật các bảng phạm vi và tiền tệ tương ứng. Quy tắc tám nâng cấp và kinh tế 12–13 tiếp tục là nền.

## 11. Kiểm tra bản mockup

Ngày 10/11/2026: đã chạy mockup bằng Chromium/Edge headless; kiểm tra lắp, tháo, xác nhận/hủy chuyển, nâng và trừ tài nguyên, khóa bậc, chế tạo, thiếu tài nguyên, cấp tối đa và khôi phục trạng thái. Không ghi nhận lỗi JavaScript trong lượt kiểm tra đã hoàn tất. Kiểm tra không tràn ngang ở 320/360/390/412 px; đã xem ảnh màn đang lắp ở 390 px. Đây là kiểm tra mockup trình duyệt, chưa kiểm chứng runtime Godot, cân bằng mô phỏng hay thiết bị thật.
