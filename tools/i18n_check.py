"""Kiểm tra bảng dịch i18n/<lang>.json so với khóa dùng trong code và data.

Usage:
  python -X utf8 tools/i18n_check.py             # báo cáo mọi ngôn ngữ, exit 1 nếu có lỗi
  python -X utf8 tools/i18n_check.py --missing ja  # in các khóa ja còn thiếu (kèm bản tiếng Anh) dạng JSON

Lỗi: khóa dùng trong code/data mà en.json không có; ngôn ngữ khác thiếu khóa; placeholder
(%d, %s, %.1f, {x}) lệch so với en; chữ có dấu tiếng Việt trong code mà chưa qua I18n
(chỉ cảnh báo); khóa thừa không ai dùng (chỉ cảnh báo).
"""
import glob
import json
import re
import sys

ROOT_DIRS = ["core", "game", "ui", "scenes"]
DATA = glob.glob("data/*.json") + ["assets/iap_offers/manifest.json"]
CALL = re.compile(r'I18n\.(?:t|tn|has|is_any_translation)\("([^"]+)"')
QUOTED = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
KEYLIKE = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$")
PLACEHOLDER = re.compile(r"%[-+0-9.]*[sdf]|%%|\{[a-zA-Z_]+\}")
VI = re.compile(r"[ăâêôơưđàáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹắằẳẵặấầẩẫậếềểễệốồổỗộớờởỡợứừửữự]", re.IGNORECASE)


def strip_comment(line: str) -> str:
    in_q = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == "\\" and in_q:
            i += 2
            continue
        if c == '"':
            in_q = not in_q
        if c == "#" and not in_q:
            return line[:i]
        i += 1
    return line


def catalogs():
    out = {}
    for f in sorted(glob.glob("i18n/*.json")):
        code = f.replace("\\", "/").split("/")[-1][:-5]
        out[code] = json.load(open(f, encoding="utf-8"))
    return out


def used_keys(known: set):
    """Khóa gọi trực tiếp, chuỗi giống khóa có trong bảng (bảng const) và "@id" trong data."""
    used = {}
    raw_vi = []
    for d in ROOT_DIRS:
        for f in glob.glob(d + "/**/*.gd", recursive=True):
            if f.replace("\\", "/").endswith("core/i18n.gd"):
                continue
            for ln, line in enumerate(open(f, encoding="utf-8"), 1):
                code = strip_comment(line)
                for k in CALL.findall(code):
                    used.setdefault(k, f"{f}:{ln}")
                for s in QUOTED.findall(code):
                    if KEYLIKE.match(s) and s in known:
                        used.setdefault(s, f"{f}:{ln}")
                    elif VI.search(s):
                        raw_vi.append(f"{f}:{ln}: {s[:70]}")

    def walk(v, f):
        if isinstance(v, str):
            if v.startswith("@"):
                used.setdefault(v[1:], f)
            elif VI.search(v):
                raw_vi.append(f"{f}: {v[:70]}")
        elif isinstance(v, list):
            for x in v:
                walk(x, f)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x, f)

    for f in DATA:
        walk(json.load(open(f, encoding="utf-8")), f)
    return used, raw_vi


def main():
    cats = catalogs()
    en = cats.get("en", {})
    known = set().union(*[set(c) for c in cats.values()])
    used, raw_vi = used_keys(known)

    if len(sys.argv) >= 3 and sys.argv[1] == "--missing":
        code = sys.argv[2]
        have = cats.get(code, {})
        print(json.dumps({k: en[k] for k in en if k not in have and not k.endswith(".one")}, ensure_ascii=False, indent=1))
        return 0

    errors = 0
    undefined = [k for k in used if k not in en]
    for k in undefined:
        print(f"ERROR en thiếu khóa {k} (dùng ở {used[k]})")
    errors += len(undefined)
    for code, cat in cats.items():
        if code == "en":
            continue
        miss = [k for k in en if k not in cat and not k.endswith(".one")]
        bad = [k for k in en if k in cat and PLACEHOLDER.findall(en[k]) != PLACEHOLDER.findall(cat[k])]
        lines = [k for k in en if k in cat and en[k].count("\n") != cat[k].count("\n")]
        vi_left = [k for k in cat if code != "vi" and VI.search(cat[k])]
        print(f"{code}: {len(cat)}/{len(en)} khóa, thiếu {len(miss)}, lệch placeholder {len(bad)}, lệch xuống dòng {len(lines)}, còn chữ Việt {len(vi_left)}")
        for k in bad[:20]:
            print(f"  ERROR placeholder {code}.{k}: {en[k]!r} -> {cat[k]!r}")
        for k in vi_left[:20]:
            print(f"  ERROR chữ Việt trong {code}.{k}")
        errors += len(miss) + len(bad) + len(vi_left)
    unused = [k for k in en if k not in used and not k.endswith(".one")]
    if unused:
        print(f"WARN {len(unused)} khóa không thấy dùng (có thể là khóa ghép động): {', '.join(unused[:15])}")
    if raw_vi:
        print(f"WARN {len(raw_vi)} chuỗi tiếng Việt chưa qua I18n:")
        for r in raw_vi[:30]:
            print("  " + r)
    print("OK" if errors == 0 else f"{errors} lỗi")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
