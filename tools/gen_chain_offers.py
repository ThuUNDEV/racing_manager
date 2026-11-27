"""Sinh 56 SKU Chain Offer (Design/35 §Đợt B) vào data/iap.json từ cấu hình game gốc đã giải mã.

Nguồn: Team_Manager/data/odin/ChainOffersConfig (gem, vé theo bước) và iap_catalog.json (giá USD).
Chạy lại an toàn: xóa mọi sản phẩm kind "chain" rồi ghi lại. SKU không được đổi sau khi lên store.
Ánh xạ vé (đề xuất, xem Design/35): vé Player -> driver_coupon.pro, vé Gear -> gear_coupon.standard.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Team_Manager" / "data"
CHAINS = {
    "driver": {"odin": "player_chain", "offer": "ChainOfferPlayerPack", "coupon": "driver_coupon", "kind": "pro"},
    "gear": {"odin": "gear_chain", "offer": "ChainOfferGearPack", "coupon": "gear_coupon", "kind": "standard"},
}


def main() -> None:
    odin = json.loads((SOURCE / "odin" / "ChainOffersConfig__ChainOffersConfig.json").read_text(encoding="utf-8"))["ChainData"]
    catalog = {x["id"]: x["price_usd"] for x in json.loads((SOURCE / "iap_catalog.json").read_text(encoding="utf-8"))}
    path = ROOT / "data" / "iap.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    products = [p for p in data["products"] if p.get("kind") != "chain"]
    for chain_id, cfg in CHAINS.items():
        steps = odin[cfg["odin"]]
        for step in steps:
            index = int(step["Index"]) + 1
            usd = float(catalog["%s_%d" % (cfg["offer"], index)])
            rewards = {r["RewardId"]: int(r["Amount"]) for r in step["Rewards"]}
            tickets = next(v for k, v in rewards.items() if k != "Gems")
            sku = "chain_%s_%02d" % (chain_id, index)
            prev = "chain_%s_%02d" % (chain_id, index - 1)
            unlock = {"any": [{"bought": "starter_3"}, {"tier": 2}]} if index == 1 else {"bought": prev}
            products.append({
                "sku": sku, "kind": "chain", "chain_id": chain_id, "chain_step": index,
                "usd": usd, "price_fallback": "$%.2f" % usd, "consumable": True, "once": True,
                "unlock": unlock,
                "grant": {"gems": rewards["Gems"], cfg["coupon"]: {cfg["kind"]: tickets}},
            })
    data["products"] = products
    out = json.dumps(data, indent=1, ensure_ascii=False) + "\n"
    path.write_bytes(out.replace("\n", "\r\n").encode("utf-8"))
    print("chain products:", sum(1 for p in products if p.get("kind") == "chain"))


main()
