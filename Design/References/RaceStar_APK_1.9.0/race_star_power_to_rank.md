# Race Star – Cần bao nhiêu sức mạnh để vào Top 3 / Top 1 (campaign, APK 1.9.0)

Tài liệu này ước lượng cần nâng cấp bao nhiêu để vượt đối thủ hạng 3 và hạng 1 trong từng league của chế độ chiến dịch (campaign) của **Race Star – Team Manager** (`com.coolcatsgames.racestaridle`, 1.9.0).

> **Đọc trước:** công thức quy đổi chỉ số thành power nằm trong mã IL2CPP và **không giải mã được**. Mọi con số "cần nâng cấp bao nhiêu" dưới đây là **ước lượng theo một giả định** (mục 3), không phải số của game. Chúng cho biết quy mô và thứ tự các ngưỡng, không phải mức đảm bảo thắng.

Nhãn dùng trong tài liệu:

| Nhãn | Ý nghĩa |
|---|---|
| **Observed** | Đọc trực tiếp từ cấu hình hoặc hằng số trong gói |
| **Inferred** | Suy ra từ tên field, method, cấu trúc dữ liệu |
| **Model** | Kết quả tính theo giả định của tài liệu này |
| **Unknown** | Không có bằng chứng trong gói |

## 0. Thuật ngữ (quan trọng khi tham khảo)

Dữ liệu trong gói dùng nhãn **môn thể thao** làm khóa: `Basketball`, `Soccer`, `Hockey`, `Football`, `Baseball`, `Volleyball` (và `Tennis` ở Grand Tour / Sport Breaker). Mã vẫn còn nhiều lớp mô phỏng thể thao (`FootballMatchSimulation`, `BaseballMatchSimulation`, `TennisMatchSimulation`). Game chạy thật là **đua xe**: có `RacingSimulationViewBase` (tối đa 12 xe), `RacingVisualRunner`, và chấm hạng bằng `RaceScoring` / `RaceOutcome`.

| Nhãn trong dữ liệu | Hiểu theo đua xe | Mức chắc chắn |
|---|---|---|
| `Basketball` | Loại xe Racing | **Inferred** (từ tên SKU, chưa xác minh) |
| `Soccer`, `Hockey`, `Football`, `Baseball`, `Volleyball` | Stock, Rally, Superbike, Monster, Speedster | **Inferred** |
| "cầu thủ" / `Player` | Tay đua | **Inferred** |
| `Offense` / `Defense` | Hai chỉ số sức mạnh | **Observed** tên khóa; ý nghĩa đua xe là Inferred |
| League (0..9) | Giải đấu, 9 đội đối thủ mỗi giải | **Observed** |

Mô hình ở đây chỉ dùng dữ liệu của môn `Basketball`. 6 môn chiến dịch **dùng chung bảng giá nâng cấp** (**Observed**), nhưng power đối thủ bị nhân thêm hệ số theo `unlockOrder` (mục 2.2).

## 1. Cách xếp hạng (Observed / Inferred)

- Mỗi league có **9 đội** đối thủ (`team_0` … `team_8`), mỗi đội một số `PlayerPower`. **Observed**.
- `SeasonTeamStanding` có `Id`, `TeamName`, `Power`, `Points`, `IsPlayer`. `SeasonResult` / `SeasonHistoryResult` có `Rank`, `Points`. **Observed** tên field.
- `RaceScoring` có `PointsByPosition`, `Variance`, `IsPodium`, `TrophiesForPosition`, `PayoutMultiplier`, `FinishingPositions`. `RaceOutcome` có `PlayerPosition`, `FieldSize`, `Positions`. **Observed** tên field.
- **Inferred:** mỗi trận (cuộc đua) là một cuộc đua nhiều xe, vị trí về đích cho điểm theo `PointsByPosition`, hạng cuối mùa tính bằng `CalculatePlayerRank` theo tổng điểm.
- **Unknown:** giá trị `PointsByPosition`, `Variance`, số trận mỗi mùa, và quy tắc lên league (`CheckAndSetLeagueAdvance`). Chúng nằm trong mã hoặc dữ liệu chưa đọc được.

Quy ước trong tài liệu: **Top 3** nghĩa là power của người chơi vượt đội mạnh thứ 3 (`team_6`). **Top 1** nghĩa là vượt đội mạnh nhất (`team_8`). Đây là cách quy đổi đơn giản, không phải luật của game.

## 2. Dữ kiện từ cấu hình

### 2.1. Power đối thủ ở `unlockOrder` 0 (Observed)

| League | Top 3 (`team_6`) | Top 1 (`team_8`) |
|---:|---:|---:|
| 0 | 130 | 200 |
| 1 | 314 | 450 |
| 2 | 812 | 1.200 |
| 3 | 1.886 | 2.700 |
| 4 | 4.033 | 5.700 |
| 5 | 8.326 | 11.700 |
| 6 | 16.914 | 23.700 |
| 7 | 34.089 | 47.700 |
| 8 | 54.939 | 71.700 |
| 9 | 75.789 | 95.700 |

- Mỗi league tăng khoảng ×2 (league 8, 9 tăng chậm hơn).
- `unlockOrder` là thứ tự mở môn của người chơi. Nó nhân đều power của mọi đội, từ ×1,00 (order 0) lên khoảng ×1,15 (order 5). Ví dụ `team_0` của league 0: 40 (order 0), 41 (order 1).

### 2.2. Nguồn tăng power (Observed)

| Nguồn | Loại | Giá trị tối đa (môn `Basketball`) |
|---|---|---|
| Nâng cấp Cash `Offense_1` + `Offense_2` (L300) | % | +600 % và +900 % = **+1.500 %** |
| Nâng cấp Trophy `Trophy_Offense_1` + `_2` (L75) | % | +750 % và +750 % = **+1.500 %**, tốn **5.700 trophy** |
| Skill tree: tổng `basketball_offense_percentage` mọi nút | % | +742,5 % (tổng mọi nút cộng lại; **Inferred:** tên khóa có `Tradeoff`, nên có thể không chọn hết được) |
| Xe Legendary trang bị (`any_sport_offense_percentage`) | % | +50 % |
| Gear (8 món, L24) | phẳng | +2.000 offense, +2.000 defense (4 món mỗi loại, +500 mỗi món) |
| Xe Legendary L10 (`OwnedEffects`) | phẳng | +400 offense, +400 defense |
| Skill tree phẳng (`career_player_offense`) | phẳng | +245 offense |

Hiệu ứng nâng cấp Cash là **tuyến tính** theo cấp: `Offense_1` cho +2 % mỗi cấp, `Offense_2` cho +3 % mỗi cấp. Giá tăng theo cấp số nhân (chi tiết ở [race_star_price_progression.md](./race_star_price_progression.md)). Xe và gear: xem [race_star_upgrades_cars_tracks.md](./race_star_upgrades_cars_tracks.md).

## 3. Giả định của mô hình (Model)

$$\text{power} = F \times \left(1 + \frac{P}{100}\right)$$

- $F$ là **power nền phẳng** (tay đua, gear, xe, kỹ năng). Là tham số đầu vào.
- $P$ là tổng % bonus, cộng dồn: cash `Offense_1` + `Offense_2`, tùy chọn Trophy, skill tree, xe trang bị.
- Chỉ tính Offense. Defense và cách tay đua đóng góp không được tính.
- Ước lượng $F$ tối đa từ dữ liệu: gear 2.000 + xe Legendary 400 + skill 245 = **2.645** (chưa tính tay đua). Đây là một ước lượng thô.
- Chi phí cash được tối thiểu hóa bằng cách luôn mua cấp có **giá trên mỗi % thấp nhất** (hợp lý vì giá mỗi cấp tăng đơn điệu).
- Hệ quả: nếu công thức thật là cộng chứ không nhân, hoặc có Defense tham gia, kết quả sẽ khác đáng kể.

Không có bằng chứng nào cho thấy công thức nhân $F \times (1+P/100)$. Đây chỉ là giả định gần nhất với tên field `_percentage` và tính chất cộng dồn của các bonus. **Inferred**.

## 4. Kết quả

### 4.1. Power nền $F$ tối thiểu (Model)

Nếu nâng cấp hết mức của kịch bản, cần $F$ tối thiểu bao nhiêu để vượt ngưỡng. Kịch bản:

| Kịch bản | Tổng % bonus | Hệ số |
|---|---:|---:|
| A. Chỉ cash | 1.500 | ×16,0 |
| B. Cash + Trophy | 3.000 | ×31,0 |
| C. Cash + Trophy + skill tree + xe Legendary | 3.792,5 | ×38,9 |

Kịch bản C lấy tổng skill tree 742,5 % (cộng mọi nút, xem 2.2), nên đây là cận trên lạc quan.

| League | Hạng | Ngưỡng | F tối thiểu (A) | F tối thiểu (B) | F tối thiểu (C) |
|---:|---|---:|---:|---:|---:|
| 0 | Top 3 | 130 | 8 | 4 | 3 |
| 0 | Top 1 | 200 | 12 | 6 | 5 |
| 1 | Top 3 | 314 | 20 | 10 | 8 |
| 1 | Top 1 | 450 | 28 | 15 | 12 |
| 2 | Top 3 | 812 | 51 | 26 | 21 |
| 2 | Top 1 | 1.200 | 75 | 39 | 31 |
| 3 | Top 3 | 1.886 | 118 | 61 | 48 |
| 3 | Top 1 | 2.700 | 169 | 87 | 69 |
| 4 | Top 3 | 4.033 | 252 | 130 | 104 |
| 4 | Top 1 | 5.700 | 356 | 184 | 146 |
| 5 | Top 3 | 8.326 | 520 | 269 | 214 |
| 5 | Top 1 | 11.700 | 731 | 377 | 301 |
| 6 | Top 3 | 16.914 | 1.057 | 546 | 435 |
| 6 | Top 1 | 23.700 | 1.481 | 765 | 609 |
| 7 | Top 3 | 34.089 | 2.131 | 1.100 | 876 |
| 7 | Top 1 | 47.700 | 2.981 | 1.539 | 1.225 |
| 8 | Top 3 | 54.939 | 3.434 | 1.772 | 1.411 |
| 8 | Top 1 | 71.700 | 4.481 | 2.313 | 1.842 |
| 9 | Top 3 | 75.789 | 4.737 | 2.445 | 1.947 |
| 9 | Top 1 | 95.700 | 5.981 | 3.087 | 2.459 |

Đọc bảng: với $F$ = 2.645, league 8 Top 3 chỉ vượt được khi có cả Trophy (cột B cần 1.772) và league 9 Top 1 chỉ vượt được ở kịch bản C (cần 2.459).

### 4.2. Cash cần với $F$ = 2.645 (Model, `unlockOrder` 0)

Mỗi ô là cấp `Offense_1` / `Offense_2` và tổng Coins. "Không đủ" nghĩa là nâng hết cash vẫn chưa đủ. Cột sau cho biết cần thêm gì.

| League | Hạng | Chỉ cash | + Trophy | + Trophy + skill + xe |
|---:|---|---|---|---|
| 0-2 | Top 3 / Top 1 | 0 | 0 | 0 |
| 3 | Top 3 | 0 | 0 | 0 |
| 3 | Top 1 | L1/L1, 75 | 0 | 0 |
| 4 | Top 3 | L13/L9, 2,4e4 | 0 | 0 |
| 4 | Top 1 | L26/L22, 1,9e6 | 0 | 0 |
| 5 | Top 3 | L46/L41, 6,1e8 | 0 | 0 |
| 5 | Top 1 | L71/L67, 8,3e11 | 0 | 0 |
| 6 | Top 3 | L111/L106, 4,1e16 | 0 | 0 |
| 6 | Top 1 | L163/L157, 4,4e22 | 0 | 0 |
| 7 | Top 3 | L241/L236, 5,9e31 | 0 | 0 |
| 7 | Top 1 | Không đủ | L44/L39, 3,4e8 | 0 |
| 8 | Top 3 | Không đủ | L99/L94, 1,5e15 | 0 |
| 8 | Top 1 | Không đủ | L226/L220, 9,3e29 | L67/L62, 2,3e11 |
| 9 | Top 3 | Không đủ | L257/L251, 3,6e33 | L98/L93, 1,2e15 |
| 9 | Top 1 | Không đủ | Không đủ | L249/L243, 4,3e32 |

"0" ở cột + Trophy nghĩa là bonus Trophy đã đủ, không cần mua thêm cash. Nó **không** có nghĩa Trophy miễn phí: Trophy tối đa cần 5.700 trophy.

### 4.3. Khi $F$ thấp hơn: $F$ = 1.000 (Model, `unlockOrder` 0)

| League | Top 3 (chỉ cash) | Top 1 (chỉ cash) |
|---:|---|---|
| 0-1 | 0 | 0 |
| 2 | 0 | L6/L3, 1,2e3 |
| 3 | L21/L16, 3,2e5 | L37/L33, 5,3e7 |
| 4 | L64/L59, 9,9e10 | L97/L92, 8,9e14 |
| 5 | L150/L145, 1,5e21 | L217/L212, 9,8e28 |
| 6 | Không đủ; thêm Trophy: L21/L17, 3,9e5 | Không đủ; thêm Trophy: L157/L152, 1e22 |
| 7 | Chỉ khi có cả Trophy + skill + xe: L207/L201, 5,8e27 | Không đạt |
| 8-9 | Không đạt | Không đạt |

Ở $F$ = 1.000, league 8 và 9 **không thể** đạt Top 3 hay Top 1 dù mọi bonus đều tối đa. Đây là kết luận của mô hình, không phải của game. Nó chỉ ra rằng $F$ (tay đua, gear, xe) phải tăng theo league.

### 4.4. `unlockOrder` 5 (Model)

Power đối thủ nhân thêm khoảng 1,15. Với $F$ = 2.645, league 9 Top 1 **không đạt** ngay cả khi có Trophy, skill và xe. League 9 Top 3 đạt ở kịch bản C với L184/L179, 1,4e25.

## 5. Nhận xét

Các nhận xét sau là suy luận từ bảng số, không phải từ mã.

- **Cash chỉ đủ đến khoảng league 6.** Từ league 7, mô hình cần Trophy. League 8-9 cần thêm skill tree và xe trang bị.
- **Giá tăng nhanh hơn ngưỡng đối thủ.** Mỗi league power đối thủ tăng ×2, nhưng chi phí cash tương ứng tăng 10⁴ đến 10⁷ lần. Một khả năng là khoảng chênh này được bù bởi hệ số thu nhập của league (`League_Income` từ 1 đến 16.000). Không kiểm chứng được vì công thức thu nhập nằm trong mã.
- **Trophy là nút thắt từ league 7.** Trần trophy mỗi league (`League_MaxTrophies`) là 100, 300, 600, 1.000, 1.500, 2.100, 2.800, 3.600, 4.500, 5.500 (**Observed**). Tối đa hóa hai nâng cấp Trophy Offense cần 5.700 trophy. Chưa rõ trần này là giới hạn tích lũy hay giới hạn mỗi giải, nên không kết luận được cần chơi bao lâu.
- **Gear, xe và kỹ năng là đòn bẩy rẻ.** Xe Legendary tốn tổng 600 để lên L10 và cho +400 phẳng, +50 % khi trang bị. Gear L24 cho +500 mỗi món. Đơn vị tiền của gear và xe chưa biết, nên không so trực tiếp với Coins được.
- **Nên chừa biên an toàn.** Vì `Variance` chưa biết, nhắm vượt ngưỡng khoảng 10-20 % cho Top 1 ổn định. Con số này là kinh nghiệm thiết kế, không rút từ dữ liệu.

## 6. Dùng cho dự án khác

Những điều có thể tham khảo mà ít bị phụ thuộc vào công thức chưa biết:

- **Cấu trúc ngưỡng:** 10 league × 9 đội, power league sau xấp xỉ 2 lần league trước, đội yếu nhất league n+1 có power bằng 0,7 lần đội mạnh nhất league n, đúng với cả 9 cặp (**Observed**, đã kiểm lại bằng script).
- **Hiệu ứng tuyến tính, giá mũ:** tăng % phẳng mỗi cấp, giá nhân tỉ lệ giảm dần (×1,8 ở L1 xuống ×1,31 ở L300 với `Offense_1`). Đây là mô hình cho phép đoán trước độ dốc.
- **Ba lớp bonus:** cash (vô hạn dần, giá mũ), Trophy (giá tuyến tính = N trophy ở cấp N, trần theo league), phẳng từ xe và gear (rẻ, giới hạn cấp).
- **Khoảng cách giá và ngưỡng:** ngưỡng đối thủ tăng ×2, nhưng giá ×10⁴-10⁷ mỗi league. Dự án khác cần quyết định nguồn nào bù khoảng này (thu nhập tăng theo league là một lựa chọn).

Không nên sao chép con số "cần L241/L236" như chuẩn: nó phụ thuộc giả định $F$ và công thức nhân ở mục 3.

## 7. Chưa biết

1. Công thức power thật (nhân hay cộng, Defense có tính không).
2. Tay đua đóng góp vào $F$ bao nhiêu.
3. `PointsByPosition`, `Variance`, số trận mỗi mùa.
4. Quy tắc lên league và định nghĩa đạt "Top 3" trong mùa.
5. Thu nhập thực tế theo league, nên không đổi được chi phí ra thời gian chơi.
6. Server hoặc Remote Config có ghi đè bảng hay không.

## 8. Cách tái lập

Công cụ và dữ liệu nằm ở `C:\Users\thupv\Downloads\Team_Manager` (ngoài kho dự án):

```powershell
cd C:\Users\thupv\Downloads\Team_Manager
python tools\power_model.py 0     # unlockOrder 0..5: in bảng F tối thiểu và chi phí cash theo F
python tools\verify_docs.py       # đối chiếu con số của tài liệu với data/
```

| Thông tin | Nguồn |
|---|---|
| Bảng giá và hiệu ứng nâng cấp | `data/upgrades_campaign.json` |
| Power đối thủ và `unlockOrder` | `data/leagues_campaign.json` |
| Skill tree | `data/odin/CareerPlayerSkillsConfig__CareerPlayerSkillsConfig.json` |
| Xe và gear | `data/garage.json` |
| Tên field xếp hạng (`RaceScoring`, `SeasonModel`…) | DLL giả của Cpp2IL (`Features.MatchSimulation.Public.dll`) |
