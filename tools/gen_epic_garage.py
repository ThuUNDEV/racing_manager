"""Sinh Xe Epic và Bộ sơn Epic (Design/35 đợt E1) từ cấu hình game gốc: 5 SKU epic_car_* + 5 SKU epic_paint_*.

Nguồn: Team_Manager/data/iap_catalog.json (CarEpic 9,99 USD, PlayerOutfitEpic 9,99 USD). Game này có 5 hạng xe nên 5 xe thay cho 6.
Ghi: data/epic_cars.json, các màu sơn Epic trong data/garage_cosmetics.json, 10 sản phẩm trong data/iap.json,
horus-game.json và danh sách IAP_SKUS của web/shell.html. Chạy lại an toàn (xóa phần Epic cũ rồi ghi lại). SKU không được đổi sau khi lên store.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLASSES = ["pico", "nova", "apex", "titan", "zenith"]
STAT_BONUS = 1.09
CAR_PAINT = {"pico": "epic_sapphire", "nova": "epic_jade", "apex": "epic_ruby", "titan": "epic_aurum", "zenith": "epic_amethyst"}
PAINTS = [
    ("epic_sapphire", "#2f7ae0", "#ffd447", None, "car_pico_epic"),
    ("epic_jade", "#19b59a", "#fff2a8", None, "car_nova_epic"),
    ("epic_ruby", "#d6304a", "#ffe08a", None, "car_apex_epic"),
    ("epic_aurum", "#e8a91c", "#5b2a86", None, "car_titan_epic"),
    ("epic_amethyst", "#8a3fd0", "#f2c230", None, "car_zenith_epic"),
    ("epic_aurora", "#7a6fe0", "#7ff0e0", "epic_paint_aurora", None),
    ("epic_solar", "#ffb020", "#e8412a", "epic_paint_solar", None),
    ("epic_midnight", "#1b1d26", "#43d9ff", "epic_paint_midnight", None),
    ("epic_sakura", "#f7a8c8", "#c2386f", "epic_paint_sakura", None),
    ("epic_neon", "#17e0c8", "#3a1d7a", "epic_paint_neon", None),
]
PAINT_TIER = {"aurora": 1, "solar": 1, "midnight": 2, "sakura": 2, "neon": 3}


def write_crlf(path: Path, text: str) -> None:
    path.write_bytes(text.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))


def epic_cars() -> list:
    cars = json.loads((ROOT / "data" / "cars.json").read_text(encoding="utf-8"))["cars"]
    out = []
    for index, name in enumerate(CLASSES, start=1):
        group = [c for c in cars if int(c["class"]) == index]
        base = {k: int(round(max(int(c["base"][k]) for c in group) * STAT_BONUS)) for k in ("S", "H", "B", "A")}
        out.append({"id": "car_%s_epic" % name, "class": index, "class_name": group[0]["class_name"], "variant": "epic",
                    "name": "@data.cars.%s_epic" % name, "base": base, "price": "0", "starter": False,
                    "entry_tier": int(group[0]["entry_tier"]), "iap_only": True, "sku": "epic_car_%s" % name,
                    "default_paint": CAR_PAINT[name]})
    return out


def products() -> list:
    out = []
    for index, name in enumerate(CLASSES, start=1):
        out.append({"sku": "epic_car_%s" % name, "kind": "epic_car", "usd": 9.99, "price_fallback": "$9.99", "consumable": False, "once": True,
                    "unlock": {"races": 7}, "popup_group": "high_value", "prio": 80 + index,
                    "popup_unlock": {"races": 10, "tier": index - 1}, "auto_popup": 2, "strip_prio": 95,
                    "grant": {"car": "car_%s_epic" % name}})
    for name, tier in PAINT_TIER.items():
        out.append({"sku": "epic_paint_%s" % name, "kind": "epic_paint", "usd": 9.99, "price_fallback": "$9.99", "consumable": False, "once": True,
                    "unlock": {"races": 7}, "popup_group": "high_value", "prio": 70 - tier,
                    "popup_unlock": {"races": 20, "tier": tier}, "auto_popup": 1, "strip_prio": 90,
                    "grant": {"paint": "epic_%s" % name}})
    return out


def patch_iap() -> list:
    path = ROOT / "data" / "iap.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    kept = [p for p in data["products"] if p.get("kind") not in ("epic_car", "epic_paint")]
    new = products()
    data["products"] = kept + new
    write_crlf(path, json.dumps(data, indent=1, ensure_ascii=False) + "\n")
    return new


def patch_cosmetics() -> None:
    path = ROOT / "data" / "garage_cosmetics.json"
    text = path.read_bytes().decode("utf-8").replace("\r\n", "\n")
    text = re.sub(r'\n    \{"id": "epic_[^\n]*\},?', "", text)
    lines = []
    for paint_id, color, ink, sku, car in PAINTS:
        entry = {"id": paint_id, "name": "@data.garage_cosmetics.%s" % paint_id, "color": color, "ink": ink, "finish": "pearl"}
        entry["epic"] = "paint" if sku else "car"
        if sku:
            entry["sku"] = sku
        if car:
            entry["car"] = car
        lines.append("    " + json.dumps(entry, ensure_ascii=False))
    marker = '\n  ],\n  "decals"'
    head, tail = text.split(marker)
    head = head.rstrip(",")
    text = head + ",\n" + ",\n".join(lines) + marker + tail
    json.loads(text)
    write_crlf(path, text)


def patch_store(new: list) -> None:
    path = ROOT / "horus-game.json"
    text = path.read_text(encoding="utf-8")
    text = re.sub(r',\n    \{\n      "sku": "epic_[a-z_]+",\n      "usd": 9.99,\n      "consumable": false\n    \}', "", text)
    entries = "".join(',\n    {\n      "sku": "%s",\n      "usd": 9.99,\n      "consumable": false\n    }' % p["sku"] for p in new)
    text = text.replace('\n    }\n  ],\n  "remoteConfig"', "\n    }" + entries + '\n  ],\n  "remoteConfig"', 1)
    json.loads(text)
    path.write_text(text, encoding="utf-8")
    shell = ROOT / "web" / "shell.html"
    html = shell.read_text(encoding="utf-8")
    html = re.sub(r', "epic_[a-z_]+"', "", html)
    html = html.replace('"chooseone_all_3"]', '"chooseone_all_3"' + "".join(', "%s"' % p["sku"] for p in new) + "]", 1)
    shell.write_text(html, encoding="utf-8")


def main() -> None:
    (ROOT / "data" / "epic_cars.json").write_text(json.dumps({"schema_version": 1, "cars": epic_cars()}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    new = patch_iap()
    patch_cosmetics()
    patch_store(new)
    print("epic cars:", len(CLASSES), "skus:", len(new))


main()
