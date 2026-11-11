"""Financial design model only. Run from repo root with Python 3, no packages.

Decimal models large money; this is NOT the Godot BigNumber implementation.
Race position is an input, not a prediction from TrafficSim. No ads, daily,
offline, gem, discounts, or legacy bonuses. Amounts are normalized per tier.
"""
from decimal import Decimal, getcontext, ROUND_CEILING
from pathlib import Path
import json

getcontext().prec = 40
D = Decimal
BASE = [D(150), D(300), D(500), D(800)]
GROWTH = D("1.45")
FACTORS = [D(x) for x in ("1", ".9", ".8", ".7", ".6", ".5", ".45", ".4")]
PACING = [D(x) for x in (1, 2, 4, 8, 16, 32)]


def rate(levels):
    t, c, p, g = levels
    return (D(8) + D("2.5") * t + D("7.5") * c + D("12.5") * p) * (1 + D(".5") * g)


def cost(base, n):
    return (base * GROWTH ** n).to_integral_value(rounding=ROUND_CEILING)


def simulate(position, strategy, cycle):
    wallet = D(1000)
    cumulative = 0
    output = []
    previous_parts = [0] * 4
    for tier in range(6):
        scale = D(1000) ** tier
        pacing = PACING[tier]
        levels = [0] * 4
        # L0 -> L1 keeps class 1; later transitions require a fresh car.
        parts = previous_parts.copy() if tier == 1 else [0] * 4
        part_scale = D(".001") if tier == 1 else D(1)
        part_pacing = PACING[0] if tier == 1 else pacing
        target = 8 if tier == 0 else 10
        if tier == 5:
            target = 20
        revenue_target = 20 if tier == 5 else 12
        gate = D(0) if tier == 5 else pacing * rate([12] * 4) * (300 if tier == 0 else 900)
        seconds = 0
        race_rate = rate(levels)
        season_exposure = D(0)
        earned = D(0)
        first_upgrade = None
        # Wallet stays in world units at transitions; normalize for computation.
        wallet /= scale
        if tier > 0:
            wallet += 1000 * pacing  # one-time opening reserve, not revenue
        while seconds < 86400:
            while True:
                candidates = []
                r = rate(levels)
                for i, lv in enumerate(levels):
                    if lv >= revenue_target:
                        continue
                    price = cost(BASE[i] * pacing, lv)
                    after = levels.copy()
                    after[i] += 1
                    roi = price / (rate(after) - r)
                    # Cost-only and ROI are contrasting synthetic policies.
                    priority = price if strategy == "cheapest" else roi
                    candidates.append((priority, price, "revenue", i))
                for i, lv in enumerate(parts):
                    if lv >= target:
                        continue
                    price = cost(D(120) * part_pacing, lv) * part_scale
                    priority = price if strategy == "cheapest" else price / D(2)
                    candidates.append((priority, price, "part", i))
                if not candidates:
                    break
                _, price, kind, idx = min(candidates)
                # Wait for the preferred candidate, rather than buying a
                # cheaper option just because it is affordable this second.
                if price > wallet:
                    break
                wallet -= price
                (levels if kind == "revenue" else parts)[idx] += 1
                if first_upgrade is None:
                    first_upgrade = seconds
            if min(levels) >= revenue_target and min(parts) >= target and wallet >= gate:
                wallet -= gate
                break
            wallet += rate(levels)
            earned += rate(levels)
            seconds += 1
            if seconds % cycle == 3:
                race_rate = rate(levels)  # after the 3-second countdown
            if seconds % cycle == 0:
                payout = race_rate * cycle * D(".25") * FACTORS[position - 1]
                wallet += payout
                earned += payout
                season_exposure += race_rate * cycle
                if seconds % (5 * cycle) == 0:
                    payout = season_exposure * D(".1")
                    wallet += payout
                    earned += payout
                    season_exposure = D(0)
        cumulative += seconds
        output.append({
            "tier": tier, "minutes": round(seconds / 60, 2),
            "cumulative_minutes": round(cumulative / 60, 2),
            "first_upgrade_seconds": first_upgrade,
            "revenue_levels": levels, "part_levels": parts,
            "exit_rate_per_second": str(rate(levels) * scale),
            "gross_earned": str(earned * scale),
            "financial_goal_reached": seconds < 86400,
        })
        previous_parts = parts
        wallet *= scale
    return output


if __name__ == "__main__":
    report = {
        "status": "design_model_not_runtime_or_player_validation",
        "precision": "Python Decimal 40 significant digits; not BigNumber conformance",
        "assumptions": "continuous online, fixed position input, instantaneous purchases; no promotion probability simulated",
        "scenarios": {
            f"p{p}_{policy}_{cycle}s": simulate(p, policy, cycle)
            for p, policy, cycle in [(2, "roi", 63), (8, "roi", 63),
                                     (2, "cheapest", 63), (2, "roi", 33),
                                     (2, "roi", 93)]
        },
    }
    dest = Path(__file__).with_name("economy_v2_report.json")
    dest.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for name, rows in report["scenarios"].items():
        print(name, "tier minutes:", [r["minutes"] for r in rows],
              "all financial goals:", all(r["financial_goal_reached"] for r in rows))
