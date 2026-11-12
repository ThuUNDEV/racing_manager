# Đối chiếu công thức airport_empire với Pitlane Club

Ngày: 11/11/2026. Trạng thái: **nghiên cứu và đề xuất, chưa sửa code**. Nguồn: tài liệu 8 công thức của airport_empire (ảnh người dùng cung cấp). Nền đối chiếu: [12](12_BigNumber_Economy.md), [13](13_Economy_v2_Implementation.md), `core/economy/pricing.gd`, `data/economy.json`.

## 1. Tóm tắt công thức airport_empire

| # | Công thức | Ý nghĩa |
|---|---|---|
| 1 | `UpgradeCost(n) = BaseCost × Kc^(n-1)`; máy đầu tiên dùng `^(n-2)`; Building 1 mỗi map scale riêng Kc từ 3→13 (mỗi level +1) ở level 1→10 | Giá tăng hình học theo cấp, mỗi máy có Kc riêng |
| 2 | `SellPrice(n) = BaseSell × StarMult^sao × Kp^(n-1) × Multiplier`; Building 1 scale Kp 5→25 (level 1→20) | **Lợi nhuận cũng tăng hình học**, cộng mốc sao và hệ số ngoài (total upgrade, manager, ad boost). Tiền ghi nhận khi kết thúc sản xuất |
| 3 | `Cost = BaseCost × Kscale(map)`, `Kscale = TargetEfficiency × K(hero)^n` | Giá theo map gắn với pacing mong muốn và cấp Hero yêu cầu |
| 4 | `Cash/s = Σ(giá bán × slot / thời gian sản xuất) × multiplier × Kh`, `Kh = 0.8` | Thu nhập thực tế có hệ số hao hụt sân bãi 0.8 |
| 5 | Offline = công thức 4 chỉ cho máy đã automate, nhân thêm `Ko` | Offline chỉ tính phần tự động hóa |
| 6 | `OfferCash = Cash/s × thời gian cấu hình` | Quà quảng cáo/ưu đãi theo thời gian thu nhập |
| 7 | `UpgradeCost(L) = B × K^L`, L = tổng level máy | Nâng cấp toàn cục dùng tổng level làm biến |
| 8 | `ManagerProfit = BaseProfit × K^N` | Manager tăng hình học theo level |

## 2. Hiện trạng game (điểm khác biệt then chốt)

- **Giá**: hình học, `S × ceil(base × Q × 3 × g^m / K)` với `g = 1.45^(1/10)`, tức ×1.45 mỗi 10 cấp, 200 cấp. Giống công thức 1.
- **Lợi nhuận**: **tuyến tính**. `ticket = 8 + 0.25L`, `celebration = 0.75L`, `parking = 1.25L`, `capacity = 10 + 0.5L`. Khác công thức 2.
- **Không có** sao/mốc nhân, `Kh`, multiplier ngoài, tổng-level-biến, manager.
- **Đã giống**: offline dùng `ratio = 0.5` (≈ `Kh×Ko`), quà ngày/offer = `rate × giây` (công thức 6), thưởng chặng theo `R_start × C`.

### Hệ quả đo được

Mô phỏng nhanh Ticket (base 150, bậc 0): hoàn vốn tăng nhanh theo cấp.

| Cấp | Giá | ΔRate/s | Hoàn vốn |
|---:|---:|---:|---:|
| 0 | 38 | 0,25 | 2,5 phút |
| 50 | 243 | 0,25 | 16 phút |
| 100 | 1.555 | 0,25 | 1,7 giờ |
| 150 | 9.969 | 0,25 | 11 giờ |
| 199 | 61.567 | 0,25 | 68 giờ |

Giá hình học nhưng ΔRate cố định nên hoàn vốn phình mũ: **đây là "bức tường" khiến cấp cao không còn đáng mua**. Hiện bức tường được che bằng việc mở bậc (S ×1000) cho phép chuyển cơ sở. Airport tránh bằng cách cho lợi nhuận cũng nhân hình học và có mốc sao.

## 3. Đề xuất áp dụng (theo thứ tự ưu tiên)

### A. Lợi nhuận hình học + mốc sao (công thức 1–2). Ưu tiên cao

Thay `rate_i(L) = base + per_level × L` bằng:

```text
rate_i(L) = BaseRate_i × StarMult^stars(L) × Kp^(L-1)
stars(L)  = số mốc đã qua trong [25, 50, 100, 150]   (đề xuất, chỉnh sau)
Kc ≈ 1.15 (giá), Kp ≈ 1.10 (lợi nhuận), StarMult = 2
```

Với Kc 1.15 / Kp 1.10 (cùng ví dụ trên): hoàn vốn giữ ở khoảng 3–7 phút đến cấp 50, rồi tăng ~32 phút ở cấp 100, 2,4 giờ ở cấp 150. Vẫn tăng, nhưng mốc sao tạo các "cú nhảy" giảm hoàn vốn tại 25/50/100/150 (khoảng 40% ở cấp 25), đúng cảm giác idle tycoon. Kc/Kp phải được đặt sao cho `Kc > Kp` (nếu không tiền vô hạn), và **mỗi nguồn doanh thu có Kc/Kp riêng** như "hệ số cố định cho mỗi máy" của airport.

Ảnh hưởng mã: `Pricing.revenue_rate` và `revenue_value` (đang cộng tuyến tính), `data/economy.json` thêm `kp`, `kc`, `star_levels`, `star_mult` cho từng nguồn. `Pricing._cost` hiện đã hình học nên chỉ đổi tham số. Cần BigNumber `pow_nonnegative_int` (đã có) cho `Kp^(L-1)`; `Kp` đọc từ chuỗi.

### B. Hao hụt `Kh` (công thức 4). Ưu tiên thấp

Hệ số này chỉ có ý nghĩa vì airport có "sân bãi" (hành khách thất thoát). Game đua không có. Nếu muốn một núm cân bằng online, đặt `online_ratio = 0.8` trong config; còn không thì bỏ. Đề xuất: **không áp dụng**, giữ `offline.ratio 0.5` thay cho `Kh×Ko`.

### C. Multiplier ngoài (công thức 2, 4, 8). Ưu tiên trung bình

Thêm một "ngăn xếp" multiplier nhân vào rate: Manager/Tay đua (công thức 8 `Profit = Base × K^N`), tổng nâng cấp, ad boost x2. Chỉ nhân ở **một chỗ** (`revenue_rate`) và snapshot cùng R_start để thưởng chặng không lệch. Ánh xạ gợi ý:

| Airport | Pitlane Club |
|---|---|
| Manager level N | Cấp tay đua/đội trưởng kỹ thuật, `K^N` |
| Total upgrade | Cấp tổng các bộ phận xe (đã có 4 bộ phận ×200 cấp) |
| Ad boost | Gói x2 trong Shop (chưa bật ads, chỉ chuẩn bị hook) |
| Hero level (công thức 3) | Cấp xe yêu cầu để vào giải (đã có điều kiện hạng xe) |

### D. Giá tăng theo tổng level (công thức 7). Ưu tiên trung bình

`Cost(L) = B × K^L` với L = tổng cấp. Áp dụng cho **bộ phận xe**: giá cấp mới phụ thuộc tổng cấp 4 bộ phận của xe, không chỉ cấp riêng. Ngăn người chơi dồn một bộ phận rẻ. Lưu ý đổi `part_cost(class_index, level)` thành nhận `total_level`; `GameState._cost_at` và hàm tính gói mua nhiều cấp phải truyền tổng cấp đang thay đổi.

### E. Scale theo bậc từ pacing mong muốn (công thức 3). Ưu tiên thấp

`Kscale = TargetEfficiency × K(hero)^n` tương ứng với bảng `S(b) × Q(b)` hiện có. Hai bảng đã tương đương ý tưởng: Q là pacing, S là scale tiền. Giữ nguyên; chỉ nên ghi `target_efficiency` như tài liệu cho Q để người cân bằng hiểu vì sao Q = 1,2,4,8,16,32.

### F. Tiền ghi nhận khi kết thúc sản xuất (công thức 2) ≈ Thưởng chặng snapshot

Game đã có tương đương: thưởng lượt dùng `R_start` snapshot, nâng cấp giữa race không đổi thưởng đã chốt. Không cần sửa.

## 4. Những điểm không nên sao chép

- Công thức 1 đặc biệt cho "máy đầu" `^(n-2)` và Kc scale từ 3→13 theo level: nó là hiệu chỉnh tutorial của airport. Game có `reference_revenue_level` và `opening_reserve` thay vai trò này.
- Offline chỉ cho máy đã automate: game không có khái niệm automate; mọi doanh thu đều passive.
- Slot number / thời gian sản xuất: không có tương đương trong vòng đua liên tục.

## 5. Kế hoạch thử nghiệm nếu được duyệt

1. Thêm cấu hình `kp/kc/star` vào `data/economy.json` (schema_version 3), giữ mặc định tương thích để save cũ không đổi.
2. Sửa `Pricing.revenue_rate` + test `economy_test` thêm ca Kp/sao; mở rộng `tools/` mô hình Python (`Design/Economy/economy_v2_model.py`) để so thời gian hoàn vốn cũ/mới theo cấp.
3. Chỉ sau khi mô hình cho hoàn vốn mỗi cấp trong dải mục tiêu (3–10 phút tới cấp 50, tăng dần tới ≤ 3 giờ ở cấp 150) mới đổi dữ liệu thật.
4. Migration: save hiện có giữ cấp, rate đổi theo công thức mới; cần changelog vì rate/giá thay đổi.

## 6. Câu hỏi cần chốt

1. Có chấp nhận **đổi lợi nhuận sang hình học** (đề xuất A), kéo theo đổi cân bằng toàn bộ sáu bậc không?
2. Giữ **200 cấp** hay rút còn 20 cấp như tài liệu 12 từng ghi?
3. Mốc sao dùng **4 mốc cố định** hay mỗi nguồn doanh thu có mốc riêng?
