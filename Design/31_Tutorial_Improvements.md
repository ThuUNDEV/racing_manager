# 31. Cải tiến tutorial: dẫn dắt thật sự và chỉ đường tới tab

Ngày 16/11/2026. Trạng thái: **đã duyệt cả 7 quyết định (T2-D1…D7) và đã triển khai ngày 16/11/2026** (xem §7). Bổ sung cho [23](23_Tutorial_Script.md); khi mâu thuẫn, các mục được duyệt ở đây thay thế mục tương ứng của 23.

## 1. Vấn đề (đo trên bản chạy ngày 16/11/2026, màn 390 px)

Chụp A1–A4 bằng `--tutorial-step=…`. Điều quan sát được:

| # | Vấn đề | Bằng chứng |
|---|---|---|
| P1 | Lớp phủ không chặn chạm. Lời dẫn bảo "bấm Động cơ" nhưng người chơi vẫn bấm được Lốp, tab, quảng cáo | `mouse_filter = IGNORE` ở [tutorial_overlay.gd:55](../ui/tutorial_overlay.gd) |
| P2 | A3 nói về "8 tiền/giây" nhưng spotlight chiếu ô tiền `1K`, callout lại che ô `INCOME 8/s` | ảnh A3 |
| P3 | A2 không có vòng quanh xe người chơi như thiết kế §4 | ảnh A2 |
| P4 | Mỗi hộp 2–3 câu, cao ~250 px, che gần hết khung đua (trái giới hạn 30% ở 23 §1.3) | ảnh A1, A2 |
| P5 | A1–A3 chỉ có nút `Tiếp`, không có thao tác thật (trái nguyên tắc "học bằng làm") | 23 §1.2 |
| P6 | A4/A5 hiện callout cả khi chưa đủ tiền, nút xám, người chơi không làm theo được | đọc `Tutorial.pauses_game` |
| P7 | Tab mới mở chỉ có chấm đỏ nhỏ; không có gì chỉ người chơi bấm tab. 23 §5.3 còn ghi "không tự chuyển tab" | [main.gd:2405](../ui/main.gd), `data/tutorial.json` không có target nào là tab |

Tham khảo: lumber-tycoon (Horus_Project) chặn chạm bằng chính vùng spotlight (`ICanvasRaycastFilter`), có bước chờ im lặng tới khi đủ điều kiện, và lời mỗi bước một câu ngắn.

## 2. Mục tiêu

1. Mỗi bước có đúng một việc người chơi làm được, và mọi chạm khác không có tác dụng.
2. Người chơi luôn thấy **thứ đang được nói tới** (không bị callout che).
3. Người chơi biết phải bấm tab nào khi có tính năng mới.
4. Không thêm bước, không kéo dài Phần A (vẫn ~1,5–2 phút).

Không đổi: lịch mở khóa theo số lượt (23 §5), quà mở khóa, save, Phần C (mẹo), nhân vật Linh.

## 3. Thay đổi đề xuất

### 3.1. Chặn chạm ngoài vùng sáng (P1)

- Lớp phủ nhận chạm (`MOUSE_FILTER_STOP`) khi tutorial đang hiện callout. Chỉ chạm **trong rect mục tiêu** (+ callout + nút `Bỏ qua`) lọt xuống UI bên dưới; chạm ngoài thì bị nuốt.
- Bước không có mục tiêu (A1, A6…): chạm bất kỳ đâu = `Tiếp` ở bước chỉ đọc; bước A6 giữ như hiện tại.
- Không chặn khi tutorial đang ẩn (đang ở tab khác, có modal, bảng kết quả) và không chặn khi người chơi đang xác nhận "Bỏ qua".
- Lối thoát: `Bỏ qua` luôn bấm được; nếu mục tiêu không tồn tại (node chưa dựng) thì **không chặn** thay vì chặn toàn màn hình.
- **Rủi ro cần kiểm:** kẹt người chơi nếu rect sai sau khi cuộn/đổi cỡ màn. Giảm bằng: tính lại rect mỗi frame (đã làm), và tự nhả chặn nếu mục tiêu ngoài màn > 1 giây.

*Mục đích:* biến tutorial từ gợi ý thành dẫn dắt; người chơi không đi lạc rồi mắc kẹt ở bước chờ.

### 3.2. Sửa spotlight A2, A3 (P2, P3)

- **A3:** spotlight chữ nhật bo góc quanh ô `INCOME x/s`; callout đặt phía dưới ô đó. Thêm số `+x` nhảy lên 2 lần (đã ghi "chưa làm" ở 23 §14).
- **A2:** code hiện cố ý làm sáng **cả khung đua** ([main.gd:2515](../ui/main.gd)), lệch với lời ("chấm sáng") và thiết kế 23 §4 (vòng quanh xe). Không phải lỗi hiển thị. Đề xuất: vòng quanh xe người chơi (`RaceView.player_marker()`) có nhịp nhấp nháy, hoặc giữ khung đua nhưng sửa lời cho khớp ("Đây là xe của mình, hạng ở góc trên"). Callout đặt dưới khung đua. Chọn một trong hai ở T2-D7.

*Mục đích:* người chơi thấy đúng thứ Linh nói; doanh thu theo giây là khái niệm khó nhất của game.

### 3.3. Rút gọn lời thoại (P4)

- Mỗi bước **một câu, ≤ 60 ký tự** (23 §2 hiện cho phép 90 và nhiều câu). Callout cao tối đa ~30% màn.
- Câu phụ "áp dụng lượt sau" (A4) chuyển thành nhãn nhỏ cạnh ô, không phải một hộp chữ mới.
- Lời mới viết ở bảng chuỗi i18n (vi/en) như hiện tại; **danh sách câu cụ thể sẽ gửi duyệt riêng** vì ảnh hưởng giọng văn.

*Mục đích:* người chơi mới không đọc đoạn dài; mỗi bước truyền một ý.

### 3.4. A4/A5 chờ im lặng (P6)

- Chưa đủ tiền mua ô được chỉ: **không hiện callout**, thu nhập chạy tiếp. Đủ tiền mới hiện, spotlight + bàn tay.
- Nếu chờ quá 60 giây vẫn chưa đủ (ví dụ người chơi mua thứ khác), Linh nhắc một lần "Cần thêm tiền, chờ chút nhé".

*Mục đích:* không bảo người chơi bấm cái nút đang xám. Hiện `Tutorial.pauses_game` đã dừng game chỉ khi đủ tiền; thay đổi này làm nốt phần hiển thị.

### 3.4b. Chỉ hướng dẫn một ô nâng cấp (theo yêu cầu 16/11/2026)

- **Bỏ A5 (Ticket Marketing).** Chỉ còn **A4 Động cơ**, một lần mua là qua bước (đúng với hành vi hiện tại, `level_of("engine") >= 1`).
- Chọn Động cơ vì kết quả thấy ngay ở A7 (Power trước → sau). Ticket bị bỏ vì chỉ dạy "doanh thu có hiệu lực ngay", mà ý này đã có ở A3 (tiền theo giây) và có thể nói trong câu phụ của A4.
- Câu phụ sau khi mua gộp hai ý thành một câu ngắn, ví dụ: "Xe nhanh hơn từ lượt sau. Nâng doanh thu thì có tiền ngay." (≤ 60 ký tự, lời chốt ở bản lời gửi duyệt riêng).
- Người chơi tự khám phá 7 ô còn lại. Doc này **không** thêm hướng dẫn cho chúng; nếu thấy người chơi không hiểu ô nào, xử lý bằng mẹo Phần C sau.
- Phần A còn 6 bước: A1 Chào → A2 Xe → A3 Tiền/giây → A4 Động cơ → A5 Kết quả → A6 Lượt 2 (đánh số lại). `STEPS`, lưu `tutorial.step` và test phải đổi theo; save đang dừng ở bước `A5_ticket` hoặc `A6_result`/`A7_race2` cần ánh xạ sang bước mới.
- Hệ quả: tiền thưởng và Power ở lượt 1 hơi thấp hơn bản hai ô (không mua Ticket), cần lab kiểm lại mục tiêu P1–P4 ≥ 70% ở 23 §7.

### 3.5. Chỉ đường tới tab khi tính năng mới mở (P7)

Hiện: tính năng mở → dòng "Mở khóa" trong bảng kết quả → chấm đỏ trên tab. Người chơi phải tự bấm.

Đề xuất thêm một **bước chỉ tab** trước hướng dẫn trong tab:

1. Sau khi đóng bảng kết quả có mở khóa, và người chơi đang ở tab Đua, không có modal: spotlight vào **tab mới mở**, bàn tay trỏ tab, chặn chạm ngoài (theo 3.1).
2. Lời Linh một câu, ví dụ: "Có quà mới ở Shop! Bấm vào đây nhé." (≤ 60 ký tự, số thật chèn từ dữ liệu).
3. Người chơi bấm tab → chuyển tab bình thường → chạy hướng dẫn trong tab như hiện tại (callout + spotlight nút, đã có).
4. **Không tự chuyển tab hộ người chơi.** Điều này vẫn đúng tinh thần câu "không tự chuyển tab" ở 23 §5.3 (không chiếm quyền điều khiển), nhưng **thay đổi** việc trước đây chỉ có chấm đỏ.

Phạm vi và mức bắt buộc (cần duyệt, mục 5):

| Mốc | Tab | Chỉ tab | Ghi chú |
|---|---|---|---|
| U2 lượt 2 | Giải | Nhẹ (tab nháy, không chặn) | không có thao tác kiếm thưởng ngay |
| U4 lượt 3 | Shop | **Bắt buộc** (spotlight + chặn) | có quà ngày miễn phí |
| U3 lượt 4 | Shop (mở gói Standard) | Bắt buộc | có coupon quà |
| U5 lượt 5 | Shop (gói Pro) | Bắt buộc | có coupon quà |
| U6 lượt 7 | Garage (Đội) | Nhẹ | |
| U7 lượt 10 | nút Class trên tab Đua | Không cần | đang ở tab Đua |

Quy tắc chung: chỉ một lần cho mỗi tính năng (lưu `intro_seen`-tương tự, không đổi `SAVE_VERSION`); bấm `Bỏ qua` hoặc đổi sang tab khác thì coi như đã xem; thoát app giữa chừng thì lần mở sau không lặp; nếu `tips_off` hoặc đã `skipped` Phần A thì dùng chế độ **nhẹ** cho mọi mốc (23 §8: bỏ qua chỉ tắt lời dẫn Phần A, nên ở đây chọn nhẹ để không ép người đã từ chối).

*Mục đích:* người chơi mới không biết các tab bên dưới là nơi có tính năng mới; chấm đỏ nhỏ dễ bị bỏ qua, tính năng mở xong mà không ai dùng (23 §1: mục tiêu ≥ 60% mở gói ngay khi được mở).

## 4. Phạm vi kỹ thuật (dự kiến, chưa sửa)

| Tệp | Thay đổi |
|---|---|
| [ui/tutorial_overlay.gd](../ui/tutorial_overlay.gd) | chặn chạm theo rect mục tiêu; spotlight chữ nhật cho A3; bước "chỉ tab" mới dùng lại callout hiện có; tự nhả chặn khi mục tiêu mất |
| [game/tutorial.gd](../game/tutorial.gd) | lời thoại ngắn; điều kiện hiển thị A4/A5 chờ đủ tiền; hàm xác định tab cần chỉ |
| [ui/main.gd](../ui/main.gd) | `_tutorial_target` trả rect tab (`Nav_*`); đặt tên node tab cố định; gọi bước chỉ tab sau bảng kết quả |
| `data/tutorial.json` | thêm `nav_hint` (`none`/`soft`/`force`) cho mỗi tính năng |
| `i18n/` | chuỗi mới (vi/en), lời gửi duyệt riêng |
| `tests/tutorial_*_test.gd` | thêm kiểm tra chặn chạm, rect tab, không lặp bước chỉ tab, không kẹt khi mục tiêu mất |

Không đổi: `SAVE_VERSION`, logic mở khóa theo số lượt, khóa tầng game (`Tutorial.unlocked_at`), Phần C.

## 5. Quyết định cần duyệt

| # | Câu hỏi | Đề xuất |
|---|---|---|
| T2-D1 | A1–A3: chạm bất kỳ đâu để tiếp, hay chỉ nút `Tiếp`? | Chạm bất kỳ đâu; `Bỏ qua` luôn bấm được |
| T2-D2 | Chặn chạm ngoài vùng sáng ở các bước có mục tiêu? | Có (3.1) |
| T2-D3 | Thêm bước chỉ tab? Mức bắt buộc cho tab nào? | Có; bắt buộc cho Shop (lượt 3, 4, 5), nhẹ cho Giải và Garage (bảng 3.5) |
| T2-D4 | Người đã bấm `Bỏ qua` Phần A có bị bước chỉ tab bắt buộc không? | Không, chỉ nhẹ |
| T2-D5 | Lời thoại ≤ 60 ký tự, một câu | Có; tôi gửi bản lời để duyệt trước khi sửa chuỗi |
| T2-D6 | Chỉ hướng dẫn một ô nâng cấp: giữ ô nào? | Động cơ; bỏ A5 Ticket (3.4b) |
| T2-D7 | A2: vòng quanh xe hay giữ sáng cả khung đua? | Vòng quanh xe (đúng thiết kế gốc) |

## 6. Kiểm chứng (sau khi duyệt và làm)

1. Chụp A1–A5 và bước chỉ tab ở 320/390/412 px; spotlight trùng mục tiêu, callout không che mục tiêu, cao ≤ 30% màn.
2. Mô phỏng chạm ngoài vùng sáng: không có mua/chuyển tab xảy ra; chạm trong vùng: có.
3. Mục tiêu bị ẩn/ngoài màn: chặn tự nhả ≤ 1 giây, `Bỏ qua` vẫn bấm được.
4. Đua 10 lượt không chạm UI: mỗi mốc U2–U7 hiện bước chỉ tab đúng một lần; tab Shop bắt buộc ở lượt 3–5.
5. Save cũ (`done`) và save `skipped`: không có chặn chạm bắt buộc; không lặp bước đã xem.
6. Chạy lại `tests/tutorial_test.gd`, `tutorial_unlock_test.gd`, `tutorial_tips_test.gd` đều 0 failures.
7. Chưa thử trên điện thoại thật: ghi rõ trong báo cáo nếu vẫn chưa.

## 7. Trạng thái triển khai (16/11/2026)

Đã làm theo đúng các quyết định đã duyệt:

- **Chặn chạm (3.1):** 4 tấm chặn dưới callout, chừa lỗ đúng rect mục tiêu (A4, hướng dẫn có thao tác, bước chỉ tab bắt buộc); A1–A3, A6, A7 (câu 2, 3) phủ cả màn và chạm bất kỳ đâu = `Tiếp` (bỏ qua chạm trong 0,4 giây đầu). Không có mục tiêu hợp lệ hoặc mục tiêu ngoài màn thì không chặn. Đã thử bằng sự kiện chuột thật: bấm ngoài lỗ không mua được, bấm trong lỗ mua được, bấm header/tab bị nuốt.
- **A2/A3 (3.2):** A2 có vòng quanh xe người chơi (nền tối nhẹ hơn để vẫn thấy xe); A3 sáng ô thu nhập `IncomePill`, callout nằm dưới. Hiệu ứng `+x` bay lên **chưa làm**.
- **Lời thoại (3.3):** viết lại 8 khóa, một câu ngắn, ở cả 8 ngôn ngữ. Bản en/vi do tôi viết; **6 ngôn ngữ còn lại (id, ms, ja, ko, th, zh_Hans) do máy dịch, cần người bản ngữ xem lại.**
- **Một ô nâng cấp (3.4b):** bỏ A5. `STEPS` còn 6 bước, giữ id `A6_result`/`A7_race2`; save đang dừng ở `A5_ticket` tự tiếp tục ở `A6_result` (`Tutorial.LEGACY_STEPS`), không đổi `SAVE_VERSION`. Khóa i18n của Ticket đã xóa.
- **A4 chờ đủ tiền (3.4):** chưa đủ tiền thì không hiện callout, không chặn, không dừng game; chờ quá 60 giây thì nhắc một lần ("Cần thêm tiền, chờ chút nhé!") rồi lại chờ im lặng.
- **Chỉ tab (3.5):** `data/tutorial.json` có `nav_hint` (`force` cho U4/U3/U5 Shop; `soft` cho U2 Giải và U6 Garage; `none` cho U7). Chỉ hiện khi đang ở tab Đua, không modal; hiện một lần (`tutorial.nav_seen`, trường tùy chọn của save, không đổi `SAVE_VERSION`); người đã `Bỏ qua` Phần A chỉ nhận chế độ nhẹ. Bàn tay đứng trên tab, chỉ xuống. Thứ tự ưu tiên: hướng dẫn trong tab > chỉ tab > mẹo.
- **Kiểm chứng:** `tests/tutorial_test.gd`, `tutorial_unlock_test.gd`, `tutorial_tips_test.gd` đạt 0 failures (chạy với `LANG=vi_VN.UTF-8`; ở máy locale en các test này vốn dò chữ tiếng Việt nên báo lỗi); `tools/i18n_check.py` OK; chụp ảnh A1–A4 và bước chỉ tab ở 390 px.
- **Ngoài phạm vi, lỗi có sẵn:** `state_test` ("Ticket Marketing cấp 1 => 8,25075/giây"), `ads_v1_test` ("dữ liệu sai bị báo đúng chỗ") và `daily_rewards_ui_test` (2 kiểm tra) vẫn đỏ; đã xác nhận đỏ cả khi gỡ các thay đổi tutorial.
- **Chưa làm:** hiệu ứng `+x` ở A3, chưa thử trên điện thoại thật, chưa chụp ảnh ở 320/412 px, lab kiểm hạng lượt 1 (23 §7) sau khi bỏ Ticket chưa chạy lại.

## 8. Thay tut quà ngày bằng tut mở gear (16/11/2026, theo yêu cầu)

- **Bỏ** hướng dẫn nhận quà ngày ở Shop (lượt 3). Quà ngày vẫn dùng được từ lượt 3 và vẫn tự bật popup như thường; chỉ không còn lời dẫn của Linh.
- **U4_shop (lượt 3)** nay là hướng dẫn **mở gói gear**: bàn tay chỉ nút mở gói Standard, tặng 1 coupon Standard Gear (reward id `unlock/U4_shop`), câu thứ hai nói Power đội vừa tăng. Mở gói được ngay khi Shop mở (`gear_can_afford` và nút gói ở Shop theo `U4_shop`).
- **U3_bag (lượt 4)** chỉ còn mở tab Túi, một câu giới thiệu ("Túi giữ phụ kiện… đủ mảnh thì nâng cấp"), không còn quà; nâng cấp gear vẫn khóa tới lượt 4. Chỉ tab: nhẹ.
- Đã xóa 2 khóa i18n của quà ngày; thêm 1 khóa mới ở 8 ngôn ngữ (bản ngoài vi/en là máy dịch).
- Save đang ở giữa lịch (đã qua lượt 3, chưa tới lượt 4) sẽ không nhận coupon vì quà đã chuyển từ lượt 4 sang lượt 3; bỏ qua vì chỉ save mới bị gated và game chưa phát hành.
- Kiểm chứng: `tutorial_unlock_test`, `tutorial_tips_test`, `tutorial_test`, `i18n_test`, `gear_test`, `gear_ui_test`, `iap_test`, `shop_packs_test`, `daily_rewards_test` đạt 0 lỗi. `shop_ui_test` ("Settings button opens audio and tips controls", đếm 3 công tắc) đỏ, không liên quan tutorial.
