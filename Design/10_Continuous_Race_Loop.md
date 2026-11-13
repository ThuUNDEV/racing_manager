# Pitlane Club — Thiết kế đua liên tục theo thời gian

Ngày: 09/11/2026. Trạng thái: **đã cập nhật thiết kế theo yêu cầu; chưa triển khai vào gameplay**.

Yêu cầu: các cuộc đua tự nối tiếp, đếm ngược **3 giây trước mỗi lần xuất phát**, thời lượng mỗi cuộc đua lấy từ cấu hình. Tài liệu này thay phần bắt đầu/kết thúc cuộc đua, chuyển chặng/mùa và màn kết quả trong [02](02_Gameplay_Design.md), [04](04_Gameplay_Release.md), [06](06_UI_UX_Release.md), [07](07_Technical_Architecture.md) và [08](08_Race_Traffic_Revision.md). Mã hiện tại vẫn chạy theo số vòng và nút bấm.

## 1. Nhịp chơi mới

Trong tài liệu này, **lượt đua** là một cuộc đua/chặng có trao thưởng; **vòng đường** là một lần xe chạy hết đường đua. Hiểu yêu cầu “mỗi vòng đua có thời gian config” là thời lượng của mỗi lượt đua, không ép mọi xe hoàn thành một vòng đường trong cùng thời gian.

```text
Loading hoàn tất, gameplay hoạt động
→ Đếm ngược 3 → 2 → 1
→ Đua trong race_duration_seconds
→ Hết giờ: chốt thứ hạng + trao thưởng + lưu tiến trình
→ Đếm ngược 3 → 2 → 1 của lượt tiếp theo
→ Lặp liên tục
```

- Không cần bấm bắt đầu hoặc tiếp tục; không có thời gian hồi chờ ngoài 3 giây đếm ngược.
- Thời lượng mặc định đề xuất: **60 giây/lượt**. Đây là giá trị khởi đầu cho playtest, chưa phải cân bằng đã xác nhận.
- Tại tốc độ ×1, một chu kỳ bình thường là **63 giây**: 3 giây chuẩn bị + 60 giây đua, chưa tính thời gian xử lý/lưu kết quả.
- Tự đua khi gameplay đang hoạt động, kể cả khi người chơi xem Garage, Tay đua hoặc Giải.
- Hình học Circuit A, 8 xe, công thức chỉ số và cơ chế xe không cản nhau của [08 §10](08_Race_Traffic_Revision.md#10-đo-hiện-trạng-và-đề-xuất-v04-đua-kiểu-bảng-xếp-hạng-có-hình-ảnh-xe-không-cản-nhau) được giữ làm nền mô phỏng.

## 2. Đếm ngược trước xuất phát

- Bắt đầu khi gameplay nhận quyền hoạt động sau loading, và sau khi kết quả lượt trước đã lưu thành công.
- Xe xếp ở grid và đứng yên; hiển thị số lớn **3, 2, 1**, mỗi số một giây, sau đó **ĐUA!** và xe bắt đầu chạy.
- Đồng hồ cuộc đua bắt đầu từ 0 tại thời điểm xuất phát; 3 giây chuẩn bị không bị trừ vào thời lượng đua.
- Đếm ngược dùng thời gian gameplay đang hoạt động, không dùng giờ hệ thống; tua nhanh mô phỏng không rút ngắn 3 giây này.
- Loading chưa hoàn tất, app ra nền hoặc gameplay bị tạm dừng thì không chạy đếm ngược. Quay lại tiếp tục phần thời gian còn lại.
- Không thêm countdown thứ hai sau khi hết số 1; hiệu ứng “ĐUA!” không trì hoãn xe xuất phát.

## 3. Cuộc đua kết thúc theo thời gian

- Mọi xe chạy đến cùng một mốc `race_duration_seconds`, bất kể đã hoàn thành bao nhiêu vòng đường. **Bỏ điều kiện đủ 3 vòng là kết thúc.**
- Hết giờ, xếp hạng theo **tổng tiến trình dọc đường `s` giảm dần**, bao gồm số vòng đã chạy. Không so vị trí hình học sau phép chia dư vì xe đi trước một vòng vẫn phải đứng trên.
- Giữ grid hai cột so le hiện có và cùng vạch xuất phát. Xe xuất phát sau phải bù khoảng cách grid; không cộng bù khoảng cách khi xếp hạng.
- Nếu hai xe có tiến trình bằng nhau, dùng `id` tăng dần để phân hạng ổn định.
- Vạch xuất phát chỉ còn là mốc tính vòng đường; xe vượt qua vạch sau vòng thứ ba vẫn chạy tiếp nếu còn giờ.
- Khi hết giờ, khóa kết quả của tất cả xe tại cùng thời điểm; không đợi xe cuối cùng cán vạch. Chuyển về grid cho countdown tiếp theo, không thêm giai đoạn lăn sau về đích làm dài chu kỳ.
- “Nước rút” (`sprint`) chuyển từ vòng cuối sang **10 giây cuối**, giới hạn bằng thời lượng lượt nếu cấu hình lượt ngắn hơn 10 giây; hiệu ứng vẫn +1% tốc độ. Các lỗi “tối đa một lần mỗi vòng” và đặc tính Kỷ luật vòng đầu tiếp tục dùng vòng đường thực tế.
- Thống kê kết quả lưu hạng, quãng đường, số vòng hoàn tất, lỗi và lượt vượt. Không dùng thời gian về đích để phân hạng vì mọi xe có chung thời lượng.
- Kỷ lục chuyển sang **quãng đường xa nhất**, so riêng theo track và cùng thời lượng; không so với kỷ lục thời gian cũ hoặc giữa lượt 30 giây và 60 giây.

## 4. Cấu hình

Nhóm dự kiến thêm vào `data/sim.json` khi triển khai:

```json
"race_loop": {
  "race_duration_seconds": 60.0,
  "sprint_duration_seconds": 10.0
}
```

| Giá trị | Quy tắc |
|---|---|
| Đếm ngược | Cố định 3 giây theo yêu cầu; dùng một hằng số chung cho điều phối và UI |
| `race_duration_seconds` | Số hữu hạn > 0, đơn vị giây; ví dụ 30, 60, 90 |
| `sprint_duration_seconds` | Số hữu hạn ≥ 0; thời gian hiệu lực = min(giá trị này, thời lượng lượt) |

- `GameData.validate()` kiểm tra cấu hình trước khi vào gameplay; báo rõ trường sai, không cho chạy vòng lặp với thời lượng bằng 0/âm.
- Chốt bản cấu hình cho lượt kế tiếp khi bắt đầu countdown; thay đổi cấu hình sau đó áp dụng từ lượt sau, không kéo dài/cắt ngắn lượt đang chuẩn bị hoặc đang chạy.
- Thời gian đua là thời gian mô phỏng. Chế độ thử ×4 hoàn thành lượt 60 giây trong khoảng 15 giây thực, countdown vẫn 3 giây; bản chơi bình thường dùng ×1.
- Fixed tick 0,1 giây; bước cuối dùng `min(tick, duration - elapsed)` để mọi xe được tính đúng thời điểm hết giờ, kể cả thời lượng không chia hết cho tick.

## 5. Thưởng, chặng và mùa

> **12/11/2026:** đã bỏ mùa/chặng; thăng giải bằng điểm tích lũy và thưởng tham gia mỗi lượt — xem [23 §13](23_Tutorial_Script.md#13-bỏ-tính-năng-mùa-đã-triển-khai-12112026). Phần dưới giữ làm tham chiếu.

- Mỗi lượt hoàn tất là một chặng; bảng tiền/điểm theo hạng vẫn lấy từ cấu hình kinh tế.
- Chốt kết quả, phát tiền/điểm và ghi tiến trình trong cùng giao dịch, đúng một lần theo ID mùa/chặng. Chỉ tạo countdown kế tiếp sau khi lưu thành công.
- Vẫn **5 chặng/mùa**. Hết chặng 5, tự tổng kết, phát thưởng hoàn tất/thăng giải đủ điều kiện rồi tự chuyển mùa mới; không chờ nút “Bắt đầu mùa mới”.
- Với cấu hình 60 giây, 5 chu kỳ tương đương **5 phút 15 giây** đếm ngược và đua. Thời gian xử lý/lưu không thuộc ngân sách này.
- Nếu mở giải mới còn yêu cầu mua xe, ghi nhận giải đã mở và thưởng một lần; tiếp tục mùa ở giải đang chơi tới khi đội đáp ứng điều kiện. Không đưa xe không đủ điều kiện vào giải mới và không chặn vòng lặp bằng màn mua xe.
- Kết quả chặng và tổng kết mùa trở thành thông tin xem lại. Popup hoặc thao tác đóng kết quả không điều khiển trạng thái đua.
- Lưu thất bại: giữ giao dịch đang chờ, hiển thị lỗi và cho thử lưu lại; không tạo lượt mới hay phát thưởng lại trong quá trình thử lại.

## 6. Nâng cấp trong vòng lặp liên tục

- Người chơi được nâng xe, huấn luyện và chọn xe/tay đua trong lúc xem đua hoặc đếm ngược; vẫn kiểm tra tiền, cấp và điều kiện sở hữu như trước.
- Chỉ số, xe và tay đua của lượt đang chạy là **snapshot tại thời điểm xuất phát**. Mua/chọn giữa cuộc đua có hiệu lực ở lượt kế tiếp, không đổi tốc độ giữa chặng.
- Thay đổi trong 3 giây countdown áp dụng cho lượt sắp xuất phát; grid lúc countdown là xem trước và được cập nhật nếu đội thay đổi trước giờ xuất phát.
- UI phân biệt đội đang thi đấu và đội sẽ dùng ở lượt tới; giao dịch giữa cuộc đua ghi “Áp dụng lượt sau”. Cơ sở kinh tế vẫn có hiệu lực ngay.

## 7. Giao diện

- Bỏ CTA “Đua”/“Chặng tiếp theo”/“Bắt đầu mùa mới” khỏi luồng chính.
- Khi chuẩn bị: trạng thái “Xuất phát sau 3 giây”, countdown lớn trên khung đua. Không dùng modal che màn hình.
- Khi đua: ưu tiên **thời gian còn lại**, vị trí `P?/8`, số vòng đường đã hoàn tất; bỏ mẫu “Vòng 1/3”.
- Hết lượt: banner gọn “P3 · +6 điểm · +80 tiền” bằng dữ liệu thưởng thật. Banner tồn tại trong countdown kế tiếp và không kéo dài nó; tổng kết mùa nằm trong tab Giải để xem lại.
- Mở chi tiết kết quả là xem snapshot của lượt đã chọn. Lượt mới kết thúc không thay nội dung đang đọc; đóng bảng không dừng, reset hoặc tạo thêm race.
- Chuyển tab không ngừng vòng lặp. Tab Đua hiển thị trạng thái countdown/đang đua để người chơi biết cuộc đua vẫn hoạt động.
- Hướng dẫn đầu game chỉ dẫn nâng cấp trong lúc vòng lặp chạy; không chờ bước “bấm Đua” và không tự mở panel thưởng chặn lượt sau.

## 8. Vòng đời ứng dụng và lưu

Máy trạng thái mục tiêu:

```text
Boot → Loading → Countdown(3s) → Racing(duration) → Resolving → Countdown(3s) → ...
                     ↕               ↕              ↕
                  Suspended        Suspended      SaveError
```

- Vòng lặp do tầng `game` điều phối, không phụ thuộc tab Đua có đang hiển thị hay không. UI chỉ đọc trạng thái và gửi thao tác quản lý đội.
- Khi ra nền: dừng thời gian countdown/đua và lưu checkpoint. Quay lại hoặc khởi động lại: phục hồi countdown/đua từ checkpoint, không tính thời gian vắng mặt vào race.
- Checkpoint gồm trạng thái, thời gian còn lại/đã chạy, cấu hình của lượt, race ID/seed/RNG state, snapshot chỉ số và từng xe. Lưu theo chu kỳ và khi ra nền; thoát đột ngột chỉ có thể lùi về checkpoint đã ghi gần nhất.
- **Không mô phỏng các lượt vắng mặt.** Thu nhập offline tiếp tục dùng cơ chế kinh tế riêng, không sinh tiền thưởng chặng hoặc điểm mùa khi app đóng.
- Save cũ ở `ready` bắt đầu countdown mới. Save cũ có kết quả chờ: giữ kết quả/thưởng đã ghi, chuyển chặng/mùa đúng một lần rồi countdown, không yêu cầu đóng panel cũ. Race cũ chưa có checkpoint: bắt đầu countdown lại chặng chưa chốt, không trao thưởng cho phần đua dở.
- Lỗi boot/save vẫn cần xử lý trước khi chạy; không tự bỏ qua lỗi tiến trình để duy trì vòng lặp.

## 9. Kiểm chứng khi triển khai

1. Vào gameplay tự countdown; 2,9 giây chưa có xe chạy, đủ 3 giây xuất phát đúng một lần. Lặp lại điều này sau mỗi chặng và sau chặng cuối mùa.
2. Cấu hình lượt 30, 60, 90 và 60,05 giây: kết thúc đúng mốc cho tất cả xe, không kết thúc sớm khi đủ 3 vòng và không kéo dài vì xe cuối chưa qua vạch.
3. Hạng dùng tổng tiến trình, đúng cả khi hơn kém một vòng; cùng seed + snapshot + cấu hình cho cùng kết quả ở FPS khác nhau.
4. Chạy liên tục ít nhất hai mùa: đúng 10 kết quả, 10 thưởng chặng, 2 thưởng hoàn tất, không cần chạm UI; khôi phục/thử lưu lại không cộng trùng.
5. Đổi tab, mở/đóng kết quả và nâng cấp không dừng hoặc tạo thêm cuộc đua. Nâng cấp trong race chỉ ảnh hưởng lượt kế; nâng trong countdown áp dụng ở giờ xuất phát.
6. Ra nền giữa countdown, giữa race và lúc chốt thưởng; kiểm tra khôi phục, không sinh race offline và không nhảy qua countdown.
7. Đo lại đóng góp chỉ số, tỉ lệ thăng hạng, thưởng mỗi phút và nhịp kinh tế. Các lab 60–90 giây/thời gian về đích cũ chỉ là tham chiếu, chưa xác nhận cân bằng cho đua theo giờ.

## 10. Phạm vi triển khai tiếp theo

Thiết kế này cần thay điều kiện kết thúc và thống kê trong `TrafficSim`, thêm điều phối countdown/vòng lặp ở tầng `game`, cập nhật UI/kết quả, cấu hình/validation, migration/checkpoint và test liên quan. `RaceSim` cũ có thể tiếp tục giữ làm tham chiếu; không dùng kết quả golden cũ để khẳng định mô hình mới đã đúng. **Đợt cập nhật này chỉ sửa tài liệu thiết kế.**
