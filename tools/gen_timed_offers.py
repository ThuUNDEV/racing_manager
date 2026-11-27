"""Sinh 24 SKU ưu đãi xoay tuần (Design/35 đợt C+D) vào data/iap.json từ cấu hình game gốc đã giải mã.

Gói Giới hạn (kind "limited"): 4 vòng xoay x 3 ô. Gói Chọn Một (kind "chooseone"): 3 vòng xoay x S/M/L/Tất cả.
Nguồn: Team_Manager/data/odin/LimitedOfferConfig, ChooseOneOfferConfig và iap_catalog.json (giá USD).
Chạy lại an toàn: xóa mọi sản phẩm kind limited/chooseone rồi ghi lại. SKU không được đổi sau khi lên store.

Ánh xạ phần thưởng (đề xuất, xem Design/35):
- Key_Player_Pro + Key_Player_Starter -> driver_coupon.pro; Key_Gear_Pro + Key_Gear_Starter -> gear_coupon.standard.
- ChoicePack_Player_E/L/M/U (chọn 1 tay đua) -> driver_coupon.allstar 2/3/5/8; Collection Rare/Epic/Legendary -> allstar 1/2/3.
- ShardBundle Rare/Epic/Legendary N -> driver_shards_tier pro/elite/legend N (cộng vào tay đua đang sở hữu cùng bậc).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Team_Manager" / "data"
CHOICE_ALLSTAR = {"ChoicePack_Player_E_1": 2, "ChoicePack_Player_L_1": 3, "ChoicePack_Player_M_1": 5, "ChoicePack_Player_U_1": 8,
                  "Collection_Pack_Rare": 1, "Collection_Pack_Epic": 2, "Collection_Pack_Legendary": 3}
SHARD_TIER = {"Rare": "pro", "Epic": "elite", "Legendary": "legend"}
SIZES = {"S": "s", "M": "m", "L": "l", "All": "all"}


def grant_of(rewards: list) -> dict:
    gems = pro = gear = allstar = 0
    shards: dict = {}
    for reward in rewards:
        rid, amount = reward["RewardId"], int(reward["Amount"])
        if rid == "Gems":
            gems += amount
        elif rid.startswith("Key_Player_"):
            pro += amount
        elif rid.startswith("Key_Gear_"):
            gear += amount
        elif rid in CHOICE_ALLSTAR:
            allstar += CHOICE_ALLSTAR[rid] * amount
        elif rid.startswith("ShardBundle_"):
            _, rarity, count = rid.split("_")
            tier = SHARD_TIER[rarity]
            shards[tier] = shards.get(tier, 0) + int(count) * amount
        else:
            raise SystemExit("phần thưởng chưa ánh xạ: " + rid)
    grant: dict = {"gems": gems}
    if pro or allstar:
        grant["driver_coupon"] = {}
        if pro:
            grant["driver_coupon"]["pro"] = pro
        if allstar:
            grant["driver_coupon"]["allstar"] = allstar
    if gear:
        grant["gear_coupon"] = {"standard": gear}
    if shards:
        grant["driver_shards_tier"] = shards
    return grant


def main() -> None:
    odin = SOURCE / "odin"
    limited = json.loads((odin / "LimitedOfferConfig__LimitedOfferConfig.json").read_text(encoding="utf-8"))["_slotsByRotation"]
    choose = json.loads((odin / "ChooseOneOfferConfig__ChooseOneOfferConfig.json").read_text(encoding="utf-8"))["_slotsByRotation"]
    catalog = {x["id"]: x["price_usd"] for x in json.loads((SOURCE / "iap_catalog.json").read_text(encoding="utf-8"))}
    path = ROOT / "data" / "iap.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    products = [p for p in data["products"] if p.get("kind") not in ("limited", "chooseone")]
    forced = {"popup_group": "forced", "unlock": {"tier": 2}, "consumable": True}
    for rotation, slots in limited.items():
        for slot in slots:
            number = 4 - int(slot["SlotId"])
            usd = float(catalog[slot["IapProductId"]])
            product = {"sku": "limited_%s_%d" % (rotation, number), "kind": "limited", "rotation": int(rotation), "slot": number,
                       "usd": usd, "price_fallback": "$%.2f" % usd, "week_cap": int(slot["Limit"]), "prio": 60 + number, "strip_prio": 90}
            product.update(forced)
            product["high_priority"] = True
            if number == 3:
                product["best_value"] = True
            if number == 2:
                product["auto_popup"] = 1
            product["grant"] = grant_of(slot["Rewards"])
            products.append(product)
    for rotation, slots in choose.items():
        skus = {SIZES[s["IapProductId"].split("_")[1]]: "chooseone_%s_%s" % (SIZES[s["IapProductId"].split("_")[1]], rotation) for s in slots}
        for slot in slots:
            size = SIZES[slot["IapProductId"].split("_")[1]]
            usd = float(catalog[slot["IapProductId"]])
            product = {"sku": skus[size], "kind": "chooseone", "rotation": int(rotation), "size": size,
                       "usd": usd, "price_fallback": "$%.2f" % usd, "week_cap": 1, "prio": 50, "strip_prio": 85}
            product.update(forced)
            product["week_conflict"] = [skus[k] for k in (["s", "m", "l"] if size == "all" else ["all"])]
            if size == "m":
                product["auto_popup"] = 1
            product["grant"] = grant_of(slot["Rewards"])
            products.append(product)
    data["products"] = products
    out = json.dumps(data, indent=1, ensure_ascii=False) + "\n"
    path.write_bytes(out.replace("\n", "\r\n").encode("utf-8"))
    print("limited:", sum(1 for p in products if p.get("kind") == "limited"), "chooseone:", sum(1 for p in products if p.get("kind") == "chooseone"), "total:", len(products))


main()
