#!/usr/bin/env python3
"""Build output/screens/gallery.html (self-contained) from tools/capture_all_screens.gd output."""
import base64, datetime, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent / "output" / "screens"
WIDTHS = ["320", "390", "412"]

# Problems seen while reviewing the shots: id -> note. Delete entries once fixed.
NOTES = {
    "iap_offer_combo_2": "Số gem 1000 bị xuống dòng thành 100 / 0 (cả 3 cỡ).",
    "shop_6": "Cỡ 320: nút 'Xem video' ở ô gem bị cắt thành 'em video'.",
    "iap_starter_2": "Thiếu hình tay đua Marchetti, nửa trái phần quyền lợi chính để trống.",
    "shop_1": "Hai thẻ cùng tên 'Thu nhập ×2' với giá $4.99 và $9.99, cần kiểm tra.",
}

screens = json.loads((ROOT / "index.json").read_text(encoding="utf-8"))
# Pack popups (IAP detail, drop rates, opening results) sit together, right after Shop.
PACKS = ("iap_", "gear_rates", "gear_result", "driver_rates", "driver_result")
packs = [s for s in screens if s["id"].startswith(PACKS)]
for s in packs:
    s["group"] = "Popup pack"
screens = [s for s in screens if s not in packs]
at = max(i for i, s in enumerate(screens) if s["group"] == "Shop") + 1
screens[at:at] = sorted(packs, key=lambda s: not s["id"].startswith("iap_"))

for s in screens:
    s["note"] = NOTES.get(s["id"], "")
    s["img"] = {}
    for w in WIDTHS:
        if "widths" in s and int(w) not in s["widths"]:
            continue  # Do not reuse an obsolete scroll-step image from an earlier capture.
        path = ROOT / w / (s["id"] + ".webp")
        if not path.exists():  # a taller/wider screen needs fewer scroll steps
            continue
        data = path.read_bytes()
        s["img"][w] = "data:image/webp;base64," + base64.b64encode(data).decode()

PAGE = """<title>Racing Tycoon Screens</title>
<meta name="claude:viewport-fit-sides" content="cover">
<style>
/* layout: sticky toolbar, then one grid of phone screenshots per tab */
:root{--bg:#f6f1e8;--card:#fffdf9;--ink:#14305a;--muted:#5d6b80;--line:#e3d8c6;--accent:#e8660c;--on:#fff;--warn:#a8320f}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#0f1826;--card:#172336;--ink:#eaf0fa;--muted:#9aabc4;--line:#2a3b55;--accent:#ff8a34;--on:#14202f;--warn:#ff9c7a;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#0f1826;--card:#172336;--ink:#eaf0fa;--muted:#9aabc4;--line:#2a3b55;--accent:#ff8a34;--on:#14202f;--warn:#ff9c7a;color-scheme:dark}
body{background:var(--bg);color:var(--ink);font:14px/1.45 system-ui,sans-serif;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));padding-block:16px 48px}
h1{margin:0;font-size:22px}h2{font-size:16px;margin:28px 0 12px;scroll-margin-top:110px}
p{margin:4px 0;color:var(--muted)}
nav{position:sticky;top:env(safe-area-inset-top,0px);background:var(--bg);padding:10px 0;display:flex;flex-wrap:wrap;gap:8px;border-bottom:1px solid var(--line);z-index:2}
button,nav a{font:inherit;color:var(--ink);background:var(--card);border:1px solid var(--line);border-radius:8px;padding:6px 12px;cursor:pointer;text-decoration:none}
button[aria-pressed="true"]{background:var(--accent);border-color:var(--accent);color:var(--on)}
.sep{width:1px;background:var(--line)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:16px;align-items:start}
figure{margin:0}
figure button{padding:0;display:block;width:100%;overflow:hidden;border-radius:12px;line-height:0}
figure img{width:100%}
figcaption{padding-top:6px}
.note{color:var(--warn);display:block;font-size:12.5px}
dialog{border:1px solid var(--line);border-radius:14px;background:var(--card);color:var(--ink);padding:12px;max-width:96vw;max-height:94vh}
dialog::backdrop{background:rgba(5,10,20,.8)}
.bar{display:flex;gap:8px;align-items:center;margin-bottom:8px}.bar strong{flex:1;min-width:0}
.trio{display:flex;gap:12px;align-items:flex-start;overflow-x:auto}
.trio div{flex:none;text-align:center;color:var(--muted)}
.trio img{display:block;height:min(72vh,844px);width:auto;max-width:none}
</style>
<h1>Racing Tycoon Screens</h1>
<p>__COUNT__ màn hình và popup, tiếng Việt, chụp ngày __DATE__ với dữ liệu giả lập. Bấm ảnh để so 3 cỡ 320 / 390 / 412.</p>
<nav id="nav"></nav>
<main id="main"></main>
<dialog id="zoom">
  <div class="bar"><strong id="zt"></strong><button id="prev">←</button><button id="next">→</button><button id="close">Đóng</button></div>
  <span class="note" id="zn"></span>
  <div class="trio" id="trio"></div>
</dialog>
<script>
const S=__DATA__, W=["320","390","412"];
const $=id=>document.getElementById(id), el=(t,x)=>{const e=document.createElement(t);if(x!=null)e.textContent=x;return e};
let width="390", onlyNotes=false, cur=0, shown=[];
function render(){
  const groups=[...new Set(S.map(s=>s.group))], nav=$("nav"), main=$("main");
  nav.replaceChildren(); main.replaceChildren(); shown=[];
  for(const w of W){const b=el("button",w);b.setAttribute("aria-pressed",w===width);b.onclick=()=>{width=w;render()};nav.append(b)}
  const f=el("button","Chỉ màn có lỗi ("+S.filter(s=>s.note).length+")");f.setAttribute("aria-pressed",onlyNotes);f.onclick=()=>{onlyNotes=!onlyNotes;render()};
  const sep=el("span");sep.className="sep";nav.append(f,sep);
  groups.forEach((g,i)=>{
    const list=S.filter(s=>s.group===g&&(!onlyNotes||s.note)); if(!list.length)return;
    const h=el("h2",g+" ("+list.length+")");h.id="g"+i;
    const jump=el("button",g);jump.onclick=()=>h.scrollIntoView();nav.append(jump);
    const grid=el("div");grid.className="grid";
    for(const s of list){
      const n=shown.push(s)-1, fig=el("figure"), b=el("button"), img=el("img"), cap=el("figcaption",s.title);
      img.src=s.img[width]||s.img["390"]||s.img["320"];img.alt=s.title;img.loading="lazy";b.append(img);b.onclick=()=>open(n);
      if(s.note){const note=el("span",s.note);note.className="note";cap.append(note)}
      fig.append(b,cap);grid.append(fig);
    }
    main.append(h,grid);
  });
}
function open(n){
  cur=(n+shown.length)%shown.length;const s=shown[cur];
  $("zt").textContent=s.group+" · "+s.title;$("zn").textContent=s.note;
  $("trio").replaceChildren(...W.filter(w=>s.img[w]).map(w=>{const d=el("div",w),i=el("img");i.src=s.img[w];i.alt=s.title+" "+w;d.append(i);return d}));
  if(!$("zoom").open)$("zoom").showModal();
}
$("prev").onclick=()=>open(cur-1);$("next").onclick=()=>open(cur+1);$("close").onclick=()=>$("zoom").close();
$("zoom").addEventListener("click",e=>{if(e.target===$("zoom"))$("zoom").close()});
addEventListener("keydown",e=>{if(!$("zoom").open)return;if(e.key==="ArrowLeft")open(cur-1);if(e.key==="ArrowRight")open(cur+1)});
render();
</script>
"""
out = ROOT / "gallery.html"
out.write_text(PAGE.replace("__COUNT__", str(len(screens)))
               .replace("__DATE__", datetime.date.today().strftime("%d/%m/%Y"))
               .replace("__DATA__", json.dumps(screens, ensure_ascii=False)), encoding="utf-8")
print(out, round(out.stat().st_size / 1e6, 1), "MB")
