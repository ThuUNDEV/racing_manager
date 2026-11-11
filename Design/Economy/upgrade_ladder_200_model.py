"""Mô hình thang 200 cấp cho tám nâng cấp (Design/13). Chạy: python Design/Economy/upgrade_ladder_200_model.py

Ý tưởng: chia mỗi cấp cũ (1..20) thành 10 cấp nhỏ. Hiệu ứng mỗi cấp = hiệu ứng cũ / 10 (cùng điểm cuối).
Giá cấp m (m -> m+1) = ceil(base * Q * D * g^m / K) với g = growth^(1/10), K = tổng 10 hệ số g^j (j=0..9),
nên tổng giá của 10 cấp nhỏ bằng đúng giá một cấp cũ nhân D.

Mô phỏng chỉ xét bậc b0 (S=Q=1), chỉ tính bốn nguồn doanh thu, chiến lược ROI: luôn mua mục có giá / Δrate nhỏ nhất,
chờ cho đủ tiền (không bỏ qua mục rẻ hơn), mua tức thời, bước theo sự kiện. Không mô phỏng thưởng đua, offline, mua xe.
Đây là mô hình đối chiếu, không phải kiểm định playtest.
"""
import math
import json
import sys

GROWTH = 1.45
BASES = {"ticket": 150, "celebration": 300, "parking": 500, "grandstands": 800}
START_COINS = 1000.0


def rate(lv, scale):
    """Doanh thu/giây. Hiệu ứng mỗi cấp = hiệu ứng gốc / scale (scale = 1 cho thang 20 cấp, 10 cho thang 200)."""
    t, c, p, g = lv["ticket"], lv["celebration"], lv["parking"], lv["grandstands"]
    return (8 + 2.5 * t / scale + 7.5 * c / scale + 12.5 * p / scale) * (10 + 5 * g / scale) / 10


def cost(kind, level, scale, D):
    if scale == 1:
        return math.ceil(BASES[kind] * D * GROWTH ** level)
    g = GROWTH ** (1.0 / scale)
    k = sum(g ** j for j in range(scale))
    return math.ceil(BASES[kind] * D * g ** level / k)


def simulate(scale, max_level, goal_level, D, milestones):
    lv = {k: 0 for k in BASES}
    coins = START_COINS
    t = 0.0
    spent = 0.0
    hit = {}
    total_levels = 0
    while min(lv.values()) < goal_level:
        r = rate(lv, scale)
        best = None
        for k in BASES:
            if lv[k] >= goal_level:
                continue
            c = cost(k, lv[k], scale, D)
            d = rate({**lv, k: lv[k] + 1}, scale) - r
            score = c / d
            if best is None or score < best[0]:
                best = (score, k, c)
        _, k, c = best
        if coins < c:
            dt = (c - coins) / r
            t += dt
            coins += r * dt
        coins -= c
        spent += c
        lv[k] += 1
        total_levels += 1
        # Mốc: khi cấp THẤP NHẤT trong bốn nguồn chạm mốc
        low = min(lv.values())
        for m in milestones:
            if low >= m and m not in hit:
                hit[m] = (t, rate(lv, scale), spent, total_levels)
    return t, spent, hit, rate(lv, scale)


def fmt_time(sec):
    if sec < 3600:
        return f"{sec / 60:,.1f} phút"
    return f"{sec / 3600:,.2f} giờ"


def fmt_num(x):
    for suf, v in (("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= v:
            return f"{x / v:,.2f}{suf}"
    return f"{x:,.1f}"


def main():
    out = {}
    print("== Đối chiếu thang 20 cấp (v2 hiện tại) và thang 200 cấp, D = 1, bậc b0, chỉ doanh thu ==")
    for label, scale, ml, goal, ms in (
        ("20 cấp  → cấp 12 (mốc mở bậc)", 1, 20, 12, [6, 12]),
        ("200 cấp → cấp 120 (mốc mở bậc)", 10, 200, 120, [60, 120]),
        ("20 cấp  → cấp 20 (đủ)", 1, 20, 20, [12, 20]),
        ("200 cấp → cấp 200 (đủ)", 10, 200, 200, [120, 200]),
    ):
        tt, sp, hit, rt = simulate(scale, ml, goal, 1.0, ms)
        print(f"  {label}: {fmt_time(tt)}, tổng giá {fmt_num(sp)}, doanh thu cuối {fmt_num(rt)}/s")
        out[label] = {"seconds": tt, "spent": sp, "final_rate": rt}

    print("\n== Mốc trong thang 200 cấp (D = 1): cấp thấp nhất của bốn nguồn chạm mốc ==")
    ms = [10, 25, 50, 75, 100, 120, 150, 175, 200]
    _, _, hit, _ = simulate(10, 200, 200, 1.0, ms)
    print("  mốc | thời gian | doanh thu/s | tổng đã chi | số lần mua")
    for m in ms:
        t, r, sp, n = hit[m]
        print(f"  {m:>4} | {fmt_time(t):>12} | {fmt_num(r):>10} | {fmt_num(sp):>10} | {n}")

    print("\n== Thời gian đủ 200 cấp b0 theo hệ số kéo dài D ==")
    for D in (1, 2, 3, 5, 10):
        tt, sp, _, _ = simulate(10, 200, 200, float(D), [200])
        print(f"  D = {D:>2}: {fmt_time(tt)} (tổng giá {fmt_num(sp)})")
        out[f"D={D}"] = {"seconds": tt, "spent": sp}

    print("\n== Giá một bộ phận xe ở b0 (xe hạng 1, D = 1): giá cấp m → m+1 và cộng dồn ==")
    g = GROWTH ** 0.1
    k = sum(g ** j for j in range(10))
    cum = 0
    print("  cấp | giá bước | cộng dồn | +chỉ số tích lũy")
    for m in range(0, 200):
        c = math.ceil(120 * g ** m / k)
        cum += c
        if m + 1 in (1, 5, 10, 25, 50, 100, 150, 200):
            print(f"  {m + 1:>4} | {fmt_num(c):>8} | {fmt_num(cum):>8} | +{0.2 * (m + 1):.1f}")
    json.dump(out, open("Design/Economy/upgrade_ladder_200_report.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
