# 26. Cơ sở độc lập: doanh thu, giải, nâng cấp riêng, tiền chung một ví

Ngày 12/11/2026. Trạng thái: **đã duyệt theo đề xuất; F0–F1 đã triển khai 12/11/2026** (`businesses`, `managed_class`, `manage_class`, ví chung, thu nhập mọi cơ sở, thưởng theo cơ sở đang đua, giá mở cơ sở theo giải cao nhất; test `facility_test`). Chưa làm: F2 offline tách theo cơ sở, F3 thẻ "Thăng giải" và HUD/hồ sơ, F4 lab cân bằng, F5. Khác thiết kế ban đầu: `race_counter`, `completed_races`, `processed_rewards`, `last_result` dùng **chung toàn tài khoản** (để mốc mở khóa tính năng, quà mở khóa và seed đua không lặp theo cơ sở). Mở rộng [22 — Class đua](22_Race_Classes.md): ở 22, "cơ sở" mới chỉ là ô quyết định class nào chơi được. Tài liệu này biến mỗi cơ sở thành **một business hoàn chỉnh**: doanh thu, giải, nâng cấp, garage riêng như một lần chơi mới (không chạy lại tutorial), nhưng **tiền thu từ mọi cơ sở cộng về một ví chung**, và người chơi **chuyển qua lại giữa các cơ sở tùy ý để nâng cấp**.

**Cập nhật 12/11/2026 (theo yêu cầu):** (1) tiền từ các cơ sở cộng chung về một nguồn; (2) chuyển cơ sở tùy ý để nâng cấp. Hai điều này thay quyết định "ví riêng" ở bản nháp đầu.

Số liệu lấy từ `data/economy.json`, `core/economy/pricing.gd`, `game/game_state.gd` ngày 12/11/2026.

## 1. Thuật ngữ

| Từ | Nghĩa |
|---|---|
| **Cơ sở** | Một business gắn với **một class** (Racing, Rally…). Mua ở màn Classes (22 §5.0). Tối đa 6. |
| **Giải** | Bậc 0–5 **bên trong một cơ sở** (`business_tier`): Tập sự … Thế giới. Mỗi cơ sở có giải riêng. |
| **Thăng giải** | Lên giải kế trong cơ sở: cơ chế "mở cơ sở" cũ (reset 4 nguồn doanh thu, thu nhập ×10⁶, vốn khai trương). Đổi tên để khỏi trùng với "mở cơ sở mới". |
| **Đang quản lý** | Cơ sở mà các tab Đua/Túi/Giải/Garage/Tay đua đang hiển thị và nâng cấp. Đổi **tức thì**. |
| **Đang đua** | Cơ sở có cuộc đua trực tiếp. Đổi ở ranh giới lượt (22 §5.1). |
| **Tài khoản** | Phần dùng chung ngoài mọi cơ sở. |

Việc bỏ thẻ "Mở cơ sở" khỏi tab Giải (12/11/2026) nghĩa là hiện **chưa có cách thăng giải**. Thiết kế đưa lại thao tác đó dưới tên "Thăng giải" cho từng cơ sở (§6).

## 2. Một ví chung: hệ quả và cách xử lý

Tiền (`coins`) là **một ví của tài khoản**. Thu nhập mỗi giây và thưởng đua của **mọi cơ sở** cộng vào ví này; mọi khoản chi (nâng cấp, mua xe, tuyển tay đua, mở cơ sở, thăng giải) trừ từ ví này.

Điểm cần chú ý: `Pricing.scale_of(tier) = 10^(6 × tier)`, nên cơ sở giải 1 kiếm và tốn gấp **một triệu lần** cơ sở giải 0. Với một ví chung, hai hệ quả:

1. **Cơ sở mới (giải 0) đóng góp thu nhập rất nhỏ** cho tới khi leo giải, và nâng cấp của nó **rẻ như cho không** so với ví đang có. Người chơi có thể mua hết nâng cấp doanh thu và xe của cơ sở mới trong vài giây.
2. **Nút thắt tiến trình chuyển từ tiền sang số lượt đua**: thăng giải cần 36 điểm (Design/23 §13), mà chỉ cơ sở **đang đua** nhận điểm. Một cơ sở mới cần khoảng 5 × 36 = 180 điểm (khoảng 30 lượt, ~25 phút đua) để lên giải 5, dù tiền không còn là vấn đề.

Đề xuất **chấp nhận hệ quả này** (D-F2): cơ sở mới là một "lớp huấn luyện" nhanh về tiền nhưng chậm về lượt đua. Nó tạo vòng lặp "chuyển sang cơ sở mới, đua để lên giải, thu nhập của nó dần bắt kịp rồi **cộng dồn** vào ví" mà không cần chặn tiền. Nếu thử nghiệm thấy cơ sở mới quá dễ, có phương án thay (D-F9, §7).

**Hiển thị:** HUD có một ví chung. Mỗi cơ sở hiện thu nhập/giây của riêng nó; ô tiền hiện tổng thu nhập/giây của mọi cơ sở.

## 3. Cái gì riêng, cái gì chung

### 3.1. Riêng theo cơ sở (reset khi mở cơ sở mới)

| Dữ liệu | Ghi chú |
|---|---|
| 4 nâng cấp doanh thu (Ticket, Celebration, Parking, Grandstands) | `levels` cấp 0. |
| 4 nâng cấp xe (Engine, Tyre, Chassis, Gearbox) | `car_levels` theo từng xe, **theo cơ sở**. |
| `business_tier`, `unlocked_tier`, `promo_points`, `revenue_history`, `expansion_requested` | Giải và thanh thăng giải riêng. Bắt đầu giải 0. |
| `owned_cars`, `active_car_id`, `garage_cosmetics` | Garage riêng: xe mua bằng ví chung, nhưng thuộc cơ sở đã mua. Bắt đầu chỉ có xe khởi đầu. |
| Cúp: `trophies`, `trophies_earned`, `trophy_levels`, `trophy_cap_bonus` | Cây nâng cấp cúp riêng (cúp nhận theo giải của cơ sở). |
| `recent_results`, `records` | Lịch sử lượt gần nhất và kỷ lục riêng. (`race_counter`, `completed_races`, `processed_rewards`, `last_result` là của tài khoản, xem đầu tài liệu.) |
| `active_driver_id` | Tay đua đang dùng cho cơ sở. |
| `saved_online_rate` | Thu nhập/giây của cơ sở (tổng toàn tài khoản = tổng các cơ sở). |

### 3.2. Chung của tài khoản (không reset)

| Dữ liệu | Lý do |
|---|---|
| **`coins`, `income_remainder`** | Một ví chung (yêu cầu 12/11/2026). |
| `gems` | Tiền cao cấp. |
| Gacha và bộ sưu tập: `owned_drivers`, `driver_progress`, `driver_coupons`, `driver_pity`, `gear_owned`, `gear_coupons`, gói đã mở | Hàng đổi bằng gem/coupon; nhân bản theo cơ sở sẽ phá mô hình kiếm tiền (Design/05). Chỉ số gear và tay đua áp dụng cho **mọi cơ sở**. |
| `scout_points` | Mua tay đua thuộc bộ sưu tập chung. Kiếm ở mọi cơ sở. |
| Quà hằng ngày, tên đội, hồ sơ, cài đặt | Thuộc người chơi. |
| `tutorial` | Phần A chỉ chạy một lần, ở cơ sở đầu tiên. |
| `facilities`, `active_class`, `pending_class`, `managed_class` | Cấu trúc nhượng quyền và cơ sở đang quản lý/đang đua. |

## 4. Vận hành nhiều cơ sở

### 4.1. Chỉ một cuộc đua, nhưng mọi cơ sở đều kiếm tiền

- Chỉ **cơ sở Đang đua** có cuộc đua trực tiếp. Thưởng đua, điểm thăng giải, cúp vào cơ sở đó; tiền thưởng vào ví chung.
- **Thu nhập mỗi giây chạy ở mọi cơ sở** (kể cả đang không đua), cộng vào ví chung: `Σ online_rate(cơ sở i)`.
- **Offline:** tính thu nhập từng cơ sở theo công thức hiện có (`ratio 0,5`, trần `cap_sec` 7.200), cộng vào ví, hiện một bảng "Khi bạn vắng mặt" kèm tách theo cơ sở.
- Mọi cơ sở dùng một đồng hồ thực; không nhân thời gian theo số cơ sở.

### 4.2. Chuyển cơ sở tùy ý để nâng cấp (yêu cầu 12/11/2026)

Tách hai thao tác, không dùng chung một nút:

| Thao tác | Nút trên thẻ cơ sở | Hiệu lực | Ghi chú |
|---|---|---|---|
| **Quản lý** | "Quản lý" (hoặc chạm vào thẻ) | **Tức thì, mọi lúc**, kể cả giữa lượt đua | Đổi cơ sở mà các tab hiển thị và nâng cấp |
| **Đua** | "Watch" | Ở ranh giới lượt (22 §5.1) | Đổi cơ sở có cuộc đua trực tiếp |

- Mua nâng cấp ở cơ sở **không đang đua** không ảnh hưởng cuộc đua đang chạy; cuộc đua dùng snapshot chỉ số lúc xuất phát (Design/10 §6), nên nâng cấp ở cơ sở đang đua vẫn "áp dụng lượt sau" như hiện tại.
- Mặc định `managed_class` = cơ sở đang đua; chuyển sang cơ sở khác chỉ đổi cách xem. Có chỉ báo trên HUD khi cơ sở đang quản lý khác cơ sở đang đua: "Đang quản lý Rally · đang đua Racing".
- Thưởng lượt luôn vào cơ sở có tên trong `race_snapshot.class_id`, không theo cơ sở đang quản lý.
- Chuyển cơ sở không mất trạng thái nào (cuộn tab, bộ lọc nâng cấp có thể reset về mặc định cho gọn).

### 4.3. Không có "tổng tài sản theo giải"

Vì thang giá trị mỗi giải lệch 10⁶ lần, không gộp thành điểm "sức mạnh kinh tế". Màn Classes liệt kê thu nhập/giây, giải, thanh thăng giải của từng cơ sở.

## 5. Mở cơ sở mới

Giữ UX đã chốt: nút giá trên thẻ "Cơ sở" → popup lưới chọn loại → OK. Thay đổi:

| Mục | Quy tắc |
|---|---|
| Ví trả | **Ví chung.** |
| Giá | `facility_price_mult[n-1]` × `Pricing.expansion_cost(giải cao nhất trong các cơ sở)`. Hệ số 0,5 / 1 / 2 / 4 / 8 như 22. Dùng **giải cao nhất** để giá theo sát sức mạnh ví thay vì rẻ vì cơ sở đang quản lý ở giải thấp. |
| Điều kiện | Tối đa 6; mỗi class một cơ sở; phải chọn class cho cơ sở đang chờ. |
| Trạng thái đầu | Giải 0, 4 nguồn doanh thu cấp 0, xe khởi đầu, tay đua An, không cúp. Không cấp tiền khởi đầu (đã có ví chung). |
| Quà mở lần đầu | `first_league_gems` (50 gem) một lần mỗi cơ sở (id `facility_open/<class>`). |
| Sau khi chọn class | Tự đặt `managed_class` = cơ sở mới (người chơi vừa mở thường muốn nâng cấp ngay); không tự đổi cơ sở đang đua. |
| Tutorial | **Không chạy Phần A.** Một callout 2 dòng lần đầu: "Cơ sở mới có nâng cấp và giải riêng; tiền chung một ví." |

## 6. Thăng giải trong từng cơ sở

- Thanh thăng giải (36 điểm) là của từng cơ sở; đầy thanh thì `unlocked_tier` của cơ sở đó tăng. **Chỉ cơ sở đang đua nhận điểm.**
- Tab Giải (của cơ sở đang quản lý) có lại thẻ **"Thăng giải lên <tên giải>"**: điều kiện giữ nguyên (bốn nguồn doanh thu ≥ cấp 120, xe đủ hạng giải kế, đủ `Pricing.expansion_cost` của giải đó, trả bằng ví chung). Hành động: reset 4 nguồn doanh thu, `business_tier + 1`, vốn khai trương, thu nhập ×10⁶.
- Chỉ ảnh hưởng cơ sở đang quản lý; các cơ sở khác giữ nguyên giải.
- Nếu muốn thăng giải **tự động** khi đầy thanh (không reset), kinh tế phải thiết kế lại; đây là thay đổi lớn hơn (D-F1).

## 7. Cân bằng

| Chỉ tiêu | Mục tiêu đề xuất (lab chốt) |
|---|---|
| Thời gian cơ sở thứ 2 lên giải 1 | 40–60% thời gian cơ sở đầu |
| Cơ sở phụ có lý do tồn tại | Thu nhập của nó **cộng vào tổng** khi lên giải; class mới có lối chơi riêng (22) |
| Giá mở cơ sở | Mua được cơ sở kế tiếp sau khoảng một giải trọn vẹn ở cơ sở cao nhất |
| Không build thống trị giữa các class | Theo 22 §9 |

**Rủi ro:** vì cơ sở phụ rẻ về tiền nhưng chậm về lượt đua, người chơi có thể bỏ quên cơ sở phụ do chỉ cơ sở đang đua mới nhận điểm. Hai biện pháp dự phòng, chưa bật ở bản đầu:

- **D-F9 (phương án thay thế "thang tiền chung"):** cơ sở mới mở ở **thang kinh tế của giải cao nhất hiện có** (giải dùng để định giá và thu nhập = giải cao nhất), còn "giải đối thủ" và thanh thăng giải vẫn bắt đầu từ 0. Khi đó nâng cấp của cơ sở mới tốn tiền thật, thu nhập của nó có ý nghĩa ngay, và đây là một khoản đầu tư hoàn vốn như "mở cơ sở" trong game tycoon. Cần tách `business_tier` thành `scale_tier` (tiền) và `league` (đối thủ, điểm). Đổi lớn hơn ở `Pricing` và `GameState`.
- **D-F6 (thưởng liên cơ sở):** mỗi cơ sở đạt giải t cho các cơ sở khác +2% × t thu nhập.

## 8. Giao diện

- **HUD:** một ô tiền chung và tổng thu nhập/giây; huy hiệu class của cơ sở đang quản lý; nếu khác cơ sở đang đua thì thêm chỉ báo nhỏ.
- **Màn Classes:** thẻ mỗi cơ sở thêm hai dòng: "+34/giây" và "Giải Bán chuyên · 18/36". Hai nút trên thẻ: **Quản lý** (xanh dương) và **Watch/Active/Sau lượt này** (như 22). Thẻ đang quản lý có viền đậm.
- **Chuyển Quản lý:** mờ nhanh 0,3 giây, toast "Đang quản lý Rally".
- **Bảng offline:** tổng một dòng, rồi tối đa 3 dòng tách theo cơ sở, còn lại gom "và n cơ sở khác".
- **Hồ sơ:** "Cơ sở đã mở" liệt kê cơ sở và giải của từng cái.

## 9. Mô hình dữ liệu và save

**Mẫu "ngăn kéo"** để không viết lại ~1.800 dòng `GameState`:

- Các trường phẳng hiện có thuộc §3.1 (`levels`, `business_tier`, `car_levels`…) là **bản làm việc của cơ sở đang quản lý**. Các trường §3.2 (`coins`, `gems`, bộ sưu tập…) nằm ngoài ngăn kéo.
- Mỗi cơ sở lưu trong `businesses: {class_id: {…§3.1…}}`.
- `_stash()` ghi bản làm việc vào `businesses[managed]`; `_load_business(id)` nạp ngược. Đổi **Quản lý** = stash rồi load, **được phép bất kỳ lúc nào**, kể cả đang đua (cuộc đua không đọc bản làm việc: dùng `race_snapshot` và sim đã dựng).
- Thưởng khi chốt lượt ghi vào `businesses[race_snapshot.class_id]` (nếu cơ sở đua ≠ đang quản lý) thay vì bản làm việc, điểm thăng giải, cúp, `recent_results` cũng vậy.
- Thu nhập nền của cơ sở không quản lý: hàm thuần `Pricing.revenue_rate(levels, tier)` trên dữ liệu đã stash, cộng thẳng vào `coins`.
- Save v11: thêm `businesses`, `managed_class`; các trường phẳng ghi cho cơ sở đang quản lý. **Migration:** save cũ → `businesses = {racing: <trường phẳng>}`, `managed_class = "racing"`.
- Checkpoint đã có `class_id` và `business_tier` trong snapshot, nên khôi phục lượt đúng.

## 10. Ảnh hưởng mã

| Phần | Việc |
|---|---|
| `game/game_state.gd` | `businesses`, `managed_class`, `_stash/_load_business`, `manage_class(id)`, `_new_business()`, `buy_facility()` theo giải cao nhất, tick thu nhập mọi cơ sở, offline theo cơ sở, định tuyến thưởng theo `race_snapshot.class_id`, `promote_tier()` |
| `core/economy/pricing.gd` | `facility_price(max_tier, n)`; công thức nền không đổi |
| `ui/main.gd`, `ui/class_page.gd` | Thẻ "Thăng giải", nút Quản lý, huy hiệu HUD, bảng offline nhiều cơ sở |
| `ui/player_profile.gd` | Danh sách cơ sở |
| Tests | migration v10→v11; nâng cấp ở B không đổi A; thu nhập nền chạy ở cơ sở không quản lý; đổi Quản lý giữa lượt không đổi kết quả lượt đang chạy; thưởng vào đúng cơ sở; offline gộp; mở cơ sở trừ ví chung theo giải cao nhất; golden Racing giữ nguyên |

## 11. Lộ trình

| Bước | Nội dung | Rủi ro |
|---|---|---|
| F0 | `businesses` + migration + stash/load; một cơ sở, kết quả giữ nguyên | Trung bình |
| F1 | Cơ sở mới độc lập, nút Quản lý tức thì, định tuyến thưởng theo snapshot | Cao |
| F2 | Thu nhập nền và offline mọi cơ sở vào ví chung | Trung bình |
| F3 | Thẻ "Thăng giải", thẻ cơ sở (thu nhập, giải), HUD, hồ sơ | Thấp |
| F4 | Lab cân bằng §7; quyết định D-F9 | Cần chạy nền |
| F5 | Thưởng liên cơ sở nếu cần | Thấp |

## 12. Quyết định cần duyệt

| Mã | Câu hỏi | Đề xuất | Hậu quả nếu khác |
|---|---|---|---|
| D-F1 | Thăng giải bằng nút "Thăng giải" (reset doanh thu, ×10⁶) cho từng cơ sở? | **Có** | Thăng tự động: mất nhịp reset, phải làm lại kinh tế |
| D-F2 | Ví chung (yêu cầu 12/11/2026); chấp nhận cơ sở mới rẻ về tiền, chậm về lượt đua? | **Chấp nhận** | Xem D-F9 nếu thấy cơ sở mới quá dễ |
| D-F3 | Xe riêng từng cơ sở; tay đua và gear chung? | **Xe riêng; tay đua, gear chung** | Tay đua/gear riêng làm mất giá trị gacha |
| D-F4 | Mở cơ sở giá theo **giải cao nhất**, trả bằng ví chung | **Có** | Giá theo cơ sở đang quản lý sẽ rẻ bất thường khi quản lý cơ sở mới |
| D-F5 | Mọi cơ sở kiếm tiền nền và offline | **Có** | Nếu không, cơ sở phụ vô nghĩa |
| D-F6 | Thưởng liên cơ sở +2% × giải | **Chưa** | Cơ sở phụ có thể bị bỏ quên |
| D-F7 | Quản lý đổi tức thì; Đua đổi ở ranh giới lượt | **Có** (yêu cầu 12/11/2026) | |
| D-F8 | Tutorial cơ sở mới: một callout 2 dòng | **Có** | |
| D-F9 | Cơ sở mới mở ở thang kinh tế của giải cao nhất (tách `scale_tier`/`league`) | **Chưa**, thử D-F2 trước | Nếu D-F2 quá dễ thì bật D-F9 |
