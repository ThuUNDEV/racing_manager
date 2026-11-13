# Làm một game như Crash Ramp

Hướng dẫn từng bước cho AI agent (và người) làm một game hybrid-casual 3D bằng Horus SDK, ra kết quả cùng loại với **Crash Ramp: Car Upgrade** của Horus: một màn chơi ngắn, tiền kiếm được theo quãng đường, nâng cấp giữa các lượt, nhiều map nối nhau, quảng cáo rewarded và interstitial, shop gem, offer, lưu và cloud save, analytics, Remote Config, thông báo nhắc chơi, rồi build ra Android/iOS qua Horus.

Cách dùng: làm lần lượt từ bước 0. Mỗi bước có **Xong khi**: kiểm đủ các ý đó rồi mới sang bước sau. Con số trong hướng dẫn là của Crash Ramp (bản 0.1.0 trên store), dùng làm điểm xuất phát rồi chỉnh theo game. API đầy đủ: `horus-sdk.d.ts`; quy tắc ngắn: `AGENTS.md`.

## Prompt cho agent

Dán vào Claude Code, Cursor, Codex... ở gốc repo game (đã chép gói SDK vào `horus-sdk/`). Sửa phần trong `< >`.

**Bắt đầu game mới:**

```
Đọc hết horus-sdk/GAME-GUIDE.md và horus-sdk/AGENTS.md trước khi viết code.
Làm game "<tên game>": <2-3 câu: người chơi làm gì trong một lượt, tiền theo gì, nâng cấp gì, map sau khác gì>.
Game tham khảo: <tên hoặc link>. Hướng màn hình: <portrait/landscape>. Số map đầu tiên: <6>.

Làm đúng thứ tự các bước 0 đến 19 của GAME-GUIDE.md:
- Bước 0: viết docs/design.md, hỏi tôi những gì chưa rõ và chờ tôi đồng ý rồi mới làm tiếp.
- Sau mỗi bước: kiểm đủ mục "Xong khi" của bước đó trên trình duyệt ở cỡ điện thoại, báo tôi một dòng
  (bước nào xong, đã kiểm gì), rồi làm bước kế. Một mục chưa đạt thì sửa, không bỏ qua.
- Mọi con số để trong src/config.js, bắt đầu từ số của Crash Ramp trong hướng dẫn. Đổi kinh tế thì chạy
  mô phỏng (economy.simulateEconomy) và cho tôi xem bảng trước khi chốt.
- Chỉ dùng Horus SDK cho quảng cáo, mua hàng, analytics, lưu game; không thêm SDK hay thư viện tracking nào khác,
  không tải gì từ CDN, không sửa file trong horus-sdk/.
- Build: chỉ --dry-run và APK thử. --play hay --ios chỉ khi tôi bảo.
```

**Phiên mới, làm tiếp:**

```
Đọc docs/design.md, horus-sdk/GAME-GUIDE.md và horus-sdk/AGENTS.md. Xem lại từng bước 0 đến 19 theo mục "Xong khi"
(chạy game trên trình duyệt để kiểm, đừng đoán), cho tôi bảng bước nào xong, bước nào chưa, rồi làm tiếp bước đầu tiên chưa xong.
```

**Kiểm trước khi gửi build:**

```
Kiểm game theo bước 18 của horus-sdk/GAME-GUIDE.md và mục "Kiểm tra trước khi báo xong" của horus-sdk/AGENTS.md.
Sửa mọi lỗi tìm thấy, chạy node horus-sdk/horus-build.mjs --dry-run tới khi không còn dòng "chú ý:", rồi build APK thử
và báo tôi đường dẫn file.
```

**Đổi một con số hay một luật:**

```
<Ví dụ: Map 1 dễ quá, người chơi qua trong 5 phút>. Sửa trong src/config.js (không sửa code chơi), chạy lại mô phỏng
cho 3 kiểu người chơi, cho tôi xem bảng trước và sau, ghi quyết định vào docs/design.md kèm ngày.
```

## 0. Trước khi viết code

Viết ra (trong `docs/design.md` của repo game) năm dòng: vòng chơi một lượt (người chơi làm gì trong 10 đến 40 giây), cái gì quyết định lượt đó đi xa hay gần, tiền nhận theo gì, nâng cấp gì, và map sau khác map trước thế nào.

Crash Ramp: kéo ná bắn xe xuống dốc; xe bay, lướt, đâm qua cổng; tiền theo mét đi được; ba nâng cấp (Ná: lực bắn, Xe: lướt và bám đường, Thu nhập: tiền mỗi mét); về đích một map thì mở map sau, xe mới, giá và tiền mỗi mét cao hơn.

Hỏi người dùng nếu chưa rõ: hướng màn hình, số map đầu tiên, game tham khảo, có online hay không (SDK này cho game offline; chơi mạng cần nói chuyện với Horus).

**Xong khi:** có `docs/design.md` với năm dòng trên, người dùng đồng ý.

## 1. Thư mục game

```
my-game/
  horus-sdk/            gói SDK, chép nguyên, không sửa
  horus-game.json       thông tin game gửi Horus (bước 2)
  icon.png              1024×1024, không bo góc
  package.json          "build": lệnh ra bản web
  build.mjs             esbuild: src/ -> www/ (hoặc dist/)
  src/
    main.js             khởi động (bước 4)
    config.js           MỌI con số của game: giá, tiền, luật quảng cáo, offer, thông báo
    save.js             kho lưu (bước 11)
    game.js             vòng chơi, trạng thái màn hình
    world.js            cảnh three.js, map
    ui.js               HUD, menu, thẻ nâng cấp, shop, popup (HTML/CSS trên canvas)
    analytics.js        tên sự kiện, phễu FTUE (bước 13)
    notify.js           lịch thông báo (bước 15)
    i18n/en.json ...    chữ theo ngôn ngữ (bước 17)
  www/                  bản build web (gửi đi), không commit
  build-online/         APK/AAB tải về, không commit
```

`package.json` của Crash Ramp:

```json
{
  "type": "module",
  "scripts": { "build": "node build.mjs --target=android", "web": "node build.mjs", "ui": "node horus-sdk/horus-build.mjs ui" },
  "dependencies": { "esbuild": "0.28.2", "three": "0.186.1" }
}
```

Dùng ES module và import SDK một chỗ duy nhất:

```js
// src/sdk.js: mọi file khác import từ đây
export { platform, start, save, cloud, monetize, liveops, economy, app, fx, perf } from '../horus-sdk/horus-sdk.mjs';
```

Bản build gộp mọi thứ vào `www/` (index.html, game.js, model, âm thanh, font), đường dẫn tương đối, không tải gì từ CDN.

**Xong khi:** `npm install && npm run build` ra `www/index.html` mở được qua `npx serve www`, Console không lỗi; `.gitignore` có `www/`, `build-online/`, `node_modules/`.

## 2. horus-game.json

Điền đủ ngay từ đầu, và sửa mỗi khi thêm placement, SKU, khoá Remote Config hay sự kiện. Horus cài quảng cáo, store và Firebase từ file này.

```json
{
  "name": "My Game",
  "version": "0.1.0",
  "versionCode": 1,
  "appId": "",
  "web": "www",
  "build": "npm install --no-audit --no-fund && npm run build",
  "icon": "icon.png",
  "orientation": "portrait",
  "colors": { "background": "#0B1030" },
  "languages": ["en", "vi"],
  "ads": {
    "rewarded": ["x2_coins", "upgrade_free", "shop_gems", "rocket_free", "comeback_x2"],
    "inter": ["result_exit"]
  },
  "products": [
    { "sku": "gems_pack_1", "usd": 2.99, "consumable": true, "title": "10 gems" },
    { "sku": "gems_pack_2", "usd": 6.99, "consumable": true, "title": "30 gems" },
    { "sku": "gems_pack_3", "usd": 14.99, "consumable": true, "title": "100 gems" },
    { "sku": "remove_ads", "usd": 4.99, "consumable": false, "title": "Remove ads" },
    { "sku": "starter_pack", "usd": 6.99, "consumable": false, "title": "Starter pack" },
    { "sku": "upgrade_pack", "usd": 0.99, "consumable": true, "title": "Upgrade pack" }
  ],
  "remoteConfig": { "ads_interEvery": "2", "ads_interCooldown": "120", "m1_priceGrowth": "1.45", "offer_on": "1" },
  "events": ["run_start", "run_end", "upgrade", "map_clear", "rv_offer", "rv_start", "rv_done", "inter_show", "offer_show", "offer_buy"],
  "support": "support@horusvn.com",
  "notes": "Hybrid-casual 3D, 6 maps. Gems only from ads and IAP."
}
```

Quy tắc: placement chữ thường không dấu; SKU không bao giờ đổi sau khi đã lên store (đặt tên theo gói, không theo số gem: `gems_pack_1`, không `gems_80`); `appId` để trống tới khi Horus cấp.

**Xong khi:** mọi placement, SKU, khoá Remote Config và sự kiện mà code dùng đều có trong file (tìm trong `src/` bằng grep và so).

## 3. Một file config cho mọi con số

Mọi số ảnh hưởng tới kinh tế và quảng cáo nằm trong `src/config.js`, dạng object để Remote Config ghi đè được (bước 14). Không viết số thẳng trong `game.js` hay `ui.js`.

```js
// src/config.js (Crash Ramp)
export const M1 = { priceBase: 60, priceGrowth: 1.45, pay: 0.14, startCoins: 60, clear: 8000 };   // Map 1
export const UPGRADES = [
  { id: 'sling',  name: 'Slingshot' },   // lực bắn
  { id: 'car',    name: 'Car' },         // lướt, bám đường, chịu va chạm
  { id: 'income', name: 'Income' },      // tiền mỗi mét
];
export const MAX_LEVEL = 100;
export const LEVEL_LEN = [1500, 1900, 2100, 2300, 2600, 2900];   // mét mỗi map
export const GEMS = { start: 10, adReward: 1 };                   // gem chỉ từ quảng cáo (1 video = 1 gem) và IAP
export const ADS = { ...monetize.INTER_DEFAULTS, interOnX2Skip: 1, interFromRun: 4, interEvery: 2, interCooldown: 120, sessionWarmup: 90, rewardedGrace: 45, rvWaitMs: 3000 };
export const SHORT = { ...monetize.SHORT_DEFAULTS, afterBuys: 1, freeAds: 1, gemStep: 1, adsForGems: 1, maxSteps: 0, pin: 1, fromRun: 2 };
```

**Xong khi:** `grep -n "[0-9]\{3,\}" src/game.js src/ui.js` không còn giá, tiền thưởng hay thời gian chờ quảng cáo nào.

## 4. Thứ tự khởi động

Đúng thứ tự này, trong `src/main.js`. Sai thứ tự là mất tiến độ hoặc giao hàng hai lần.

```js
import { platform, start, save, cloud } from './sdk.js';
import { store, further, merge } from './save.js';
import { ALL_SKUS, applyRemoteConfig } from './config.js';

window.addEventListener('error', (e) => platform.crash(e.message, e.error?.stack));
window.addEventListener('unhandledrejection', (e) => platform.crash(String(e.reason?.message || e.reason), e.reason?.stack));

async function boot() {
  await start({ skus: ALL_SKUS() });                  // 1. app info, Remote Config, giá store, cloud save
  store.restoreBackup(platform.save.backup);          // 2. máy trống: lấy bản dự phòng của app
  await cloud.settleAtBoot(platform, save.conflictRules(store, {   // 3. server khác máy: giữ bản đi xa hơn
    further, merge, mirror: (j) => platform.save.mirror(j), flush: () => platform.save.flush(),
  }));
  applyRemoteConfig(platform.rc.values);              // 4. Remote Config ghi đè config.js
  await setLang(pickLang());                          // 5. ngôn ngữ trước khi vẽ chữ
  const game = new Game(store.load());                // 6. đọc save
  for (const p of await platform.iap.pending()) game.grant(p);   // 7. đơn đã trả tiền chưa giao
  await game.loadFirstMap();
  game.start();
  platform.ready();                                    // 8. app tắt màn hình chờ
}
boot().catch((e) => { console.error(e); platform.ready(); });
```

Màn hình chờ của `index.html` (một div tên game trên nền `colors.background`) hiện tới khi map đầu đã dựng.

**Xong khi:** mở trang, thấy màn chờ rồi menu trong dưới 3 giây trên máy tính; tải lại trang, tiến độ còn; Console không lỗi.

## 5. Vỏ three.js và ngân sách hiệu năng

Dùng `app.createApp` thay vì tự dựng renderer: nó chỉnh cho điện thoại (pixel ratio, mất context WebGL, governor hạ chất lượng khi tụt khung). Truyền `THREE` của game vào; SDK không chứa three.js.

```js
import * as THREE from 'three';
import { app as A, fx as F, perf } from './sdk.js';

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, 1, 0.1, 800);
const effects = new F.Fx(THREE, scene);
const shell = A.createApp({
  THREE, canvas: document.querySelector('canvas'), tickHz: 60,
  onTick: () => game.step(1 / 60),                 // vật lý bước cố định
  onFrame: (now) => { effects.update(now / 1000); shell.render(scene, camera); },
  onResize: (w, h) => { camera.aspect = w / h; camera.updateProjectionMatrix(); },
  onTier: (tier) => game.setQuality(tier),         // tier cao = máy yếu: bớt bóng, bớt hạt
});
shell.start();
```

Ngân sách cho máy tầm trung (mục tiêu 60 khung/giây): dưới 150 draw call, dưới 300 nghìn tam giác trên màn hình, một đèn có bóng, bóng nướng sẵn cho cảnh tĩnh, texture tối đa 1024, model gộp mesh theo vật liệu. Hiệu ứng hạt dùng `fx.Fx` (tối đa 4 draw call cho mọi hạt), xu bay về ví dùng `fx.createCoinFly` trên lớp HTML.

Màn 90/120 Hz: gọi `platform.device.setFrameRate(60)` lúc mở game và vẽ tối đa 60 khung/giây (bỏ khung `requestAnimationFrame` thừa), cho đổi bằng Remote Config. Nhanh hơn 60 chỉ làm máy nóng và tốn pin, người chơi không thấy khác (Crash Ramp v87).

Nhạc nền dùng `.mp3`, không `.ogg`: iPhone đời cũ không giải mã được `.ogg` và game mất nhạc mà không báo lỗi. Khi `pause` thì nhả nhạc nền khỏi bộ nhớ, `resume` thì nạp lại: máy RAM thấp hay giết WebView khi game ở nền (Crash Ramp v90).

**Xong khi:** chế độ thiết bị của Chrome (Moto G4, CPU chậm 4 lần) vẫn chơi được; `shell` báo tier không lên quá 2 khi đứng yên ở menu.

## 6. Vòng chơi

Một lượt có các trạng thái rõ ràng, mỗi trạng thái một hàm vào và ra: `menu` (ná, thẻ nâng cấp, nút shop) → `aim` (kéo ná) → `run` (xe chạy, camera bám) → `result` (thẻ kết quả: mét, tiền, x2) → về `menu` hoặc sang map sau.

Luật của Crash Ramp:
- Lượt đầu tiên của người mới phải đi được khoảng 25 đến 35% map và nhận đủ tiền mua 1 đến 2 nâng cấp. Người chơi phải thấy mình tiến bộ sau mỗi lượt.
- Tiền một lượt: `mét × pay × hệ số Income` cộng thưởng kỷ lục (phần mét vượt kỷ lục cũ × 50%) cộng thưởng về đích (lần đầu đủ, lần sau 15%).
- Về đích map thì mở map sau: xe mới, đường dài hơn, giá và pay cao hơn (bước 7).
- Nút tạm dừng trong lượt, và mọi thao tác chạm được bằng một ngón cái.

```js
// tiền một lượt (config.js)
export function runPayout({ idx, dist, best, finished, firstClear, mult }) {
  const rate = PAY_PER_M[idx], base = Math.floor(dist * rate);
  const record = best > 0 ? Math.floor(Math.max(0, dist - best) * rate * 0.5 * mult) : 0;
  const clear = finished ? Math.floor(clearBonus(idx) * (firstClear ? 1 : 0.15)) : 0;
  return { base, income: Math.floor(base * mult) - base, record, clear, total: Math.floor(base * mult) + record + clear };
}
```

**Xong khi:** chơi 5 lượt liền trên trình duyệt: mỗi lượt có thẻ kết quả, tiền cộng đúng, lượt sau đi xa hơn khi đã nâng cấp.

## 7. Kinh tế: giá, nâng cấp, map

Giá nâng cấp là đường mũ có làm tròn kiểu shop:

```js
import { economy } from './sdk.js';
const priceM1 = economy.priceCurve({ base: M1.priceBase, growth: M1.priceGrowth, round: economy.ROUNDING.even });
priceM1(0);   // 60
priceM1(5);   // ~384, làm tròn số chẵn
```

Crash Ramp: Map 1 giá 60 × 1,45 mỗi cấp, pay 0,14 xu/m, bắt đầu với 60 xu; các map sau giá và pay nhân theo map (map 2 khó hơn map 1, map 3 bằng map 1, map 4 khó hơn map 2, map 5 bằng map 2, map 6 khó hơn map 4: nhịp khó, nghỉ, khó hơn). Nút **BEST BUY** sáng trên thẻ nên mua: `economy.bestBuy(cands, { coins })` với `cands = [{ id, lv, cost }]`.

Trước khi chốt số, chạy mô phỏng cho 3 kiểu người chơi (không xem quảng cáo, thỉnh thoảng xem, xem nhiều) bằng `economy.simulateEconomy` trong Node (`horus-logic.mjs`). Mục tiêu của Crash Ramp: Map 1 khoảng 8 đến 12 phút, mỗi map sau lâu hơn một chút; ba kiểu người chơi chênh nhau cùng một tỉ lệ ở mọi map; không có map nào người không xem quảng cáo bị kẹt quá 3 lượt không mua được gì.

```js
// tools/sim.mjs (node tools/sim.mjs)
import { economy } from '../horus-sdk/horus-logic.mjs';
const res = economy.simulateEconomy({ maps: 6, upgrades: ['sling', 'car', 'income'], run, pay, pick, start: { coins: 60 } });
console.log(economy.economyReport(res));
```

Khi đổi đường giá hay pay sau khi đã có người chơi: tăng `ECON_VERSION` trong config và để `save.createSaveStore({ economy: { version, reset } })` cho bản lưu cũ làm lại tiền và nâng cấp (giữ cài đặt, mua hàng).

**Xong khi:** `node tools/sim.mjs` in bảng 3 kiểu người chơi × 6 map, đạt các mục tiêu trên; người dùng xem và đồng ý con số.

## 8. Quảng cáo rewarded

Mỗi chỗ mời xem một placement. Nút chỉ sáng khi có quảng cáo; bấm lúc đang tải thì chờ tối đa 3 giây rồi báo "chưa có video".

```js
import { platform, monetize } from './sdk.js';

async function rewarded(placement, give) {
  track('rv_offer', { pl: placement });                       // mỗi lần nút hiện ra
  if (!platform.ads.ready().rv) {
    const r = await monetize.waitRewarded(platform.ads, { waitMs: ADS.rvWaitMs, gone: () => game.state !== 'result' });
    if (r !== 'ready') { toast(t('ads_no_video')); track('rv_unavailable', { pl: placement }); return; }
  }
  store.save(S);                                               // hệ điều hành có thể đóng trang lúc quảng cáo chạy
  track('rv_start', { pl: placement });
  const r = await platform.ads.rewarded(placement);
  if (!r.ok) { track(r.reason === 'closed' ? 'rv_cancel' : 'rv_fail', { pl: placement, why: r.reason }); return; }
  monetize.noteRewarded(S.ads, Date.now());
  give(); store.save(S); track('rv_done', { pl: placement });
}
platform.on('ads', (s) => ui.setAdButtons(s.rv));
```

Các chỗ của Crash Ramp: **x2 xu** trên thẻ kết quả (lượt đầu cho miễn phí để người chơi biết nút), **nâng cấp miễn phí** khi thiếu xu (bước 9), **1 gem** trong shop (1 video = 1 gem, không chờ), **rocket miễn phí** trước lượt, **x2 quà quay lại**. Gọi `platform.ads.load('rv')` khi thẻ kết quả mở và khi về menu.

**Xong khi:** trên trình duyệt với `platform.ads.simulate(...)`, mọi nút rewarded chỉ thưởng khi xem hết, đóng sớm không thưởng; analytics có `rv_offer`, `rv_start`, `rv_done` cho từng placement.

## 9. Thiếu xu: bậc gem và quảng cáo

Khi người chơi bấm một thẻ nâng cấp không đủ xu, thẻ đó cho mua bằng quảng cáo hoặc gem theo bậc (`monetize.createShortLadder`). Luật Crash Ramp (theo mỗi lần vào menu): giá gem 1, 2, 3...; vào menu với 0 gem thì bậc đầu là xem quảng cáo, rồi 1, 2, 3 gem; có 1 gem thì 1 gem, quảng cáo, 2, 3; có hơn 1 gem thì không mời quảng cáo nữa.

```js
const ladder = monetize.createShortLadder(SHORT);      // SHORT là object sống trong config: Remote Config đổi được
const v = ladder.view(S.runs);                          // { open, step, gems, ads, prog }
if (v.open && v.ads) showFreeUpgradeButton();           // "Xem quảng cáo: nâng cấp miễn phí"
else if (v.open && v.gems) showGemButton(v.gems);
// mua xong: ladder.bought(id, 'coin' | 'gem' | 'ad'); xem xong: ladder.adWatched(S.runs)
```

**Xong khi:** với 0, 1 và 5 gem, thứ tự nút hiện ra đúng như luật trên; mua bằng gem trừ đúng gem, `an.spend('gem', ...)` được gửi.

## 10. Interstitial

Chỉ ở một chỗ: khi rời thẻ kết quả về menu, và chỉ khi mọi luật cho phép:

```js
const { due } = monetize.interDue(S.ads, ADS, {
  now: Date.now(), runs: S.runs, noAds: S.noAds, x2Skipped: x2Offered && !x2Taken,
  sinceStart: (Date.now() - sessionStart) / 1000, block: firstSession && !S.cleared[0],
});
if (due && platform.ads.ready().inter) {
  monetize.noteInter(S.ads, S.runs, Date.now());
  track('inter_show', { pl: 'result_exit' });
  await platform.ads.inter('result_exit');
}
```

Luật Crash Ramp: chỉ khi thẻ đã mời x2 mà người chơi không lấy; không trước lượt thứ 4; cách ít nhất 2 lượt và 120 giây; không trong 90 giây đầu phiên; không trong 45 giây sau một rewarded; phiên đầu không có cho tới khi qua Map 1. Đã mua Remove Ads thì không bao giờ có.

**Xong khi:** chơi 15 lượt liền không xem x2: interstitial ra đúng nhịp; mua Remove Ads (giả lập): không còn interstitial, rewarded vẫn có.

## 11. Lưu game

Một kho lưu cho cả game, có phiên bản, gộp ghi, bản dự phòng trong app:

```js
// src/save.js
import { platform, save, monetize, liveops } from './sdk.js';
export const ECON_VERSION = 1;
const defaults = () => ({
  coins: M1.startCoins, gems: GEMS.start, upg: { sling: 0, car: 0, income: 0 }, map: 0, unlocked: 1, cleared: [0, 0, 0, 0, 0, 0],
  best: {}, runs: 0, playMs: 0, noAds: false, buys: [],   // playMs: game tự cộng thời gian chơi
  settings: { sfx: true, music: true, haptics: true, notif: true, lang: '' },
  ads: monetize.pacingState(), offers: { last: -999, o: {} },
  meta: liveops.createMeta(), daily: liveops.createCalendar(), missions: liveops.createMissions(), notify: liveops.createNotify(),
  an: { ftue: {}, counts: {}, log: [] }, econ: ECON_VERSION,
});
export const store = save.createSaveStore({
  key: 'mygame.v1', defaults, mirror: (json) => platform.save.mirror(json),
  economy: { version: ECON_VERSION, reset: (d, f) => Object.assign(d, { coins: f.coins, upg: f.upg, map: 0 }) },
});
export const further = save.further('runs', 'playMs');   // bản nào chơi nhiều hơn thì đi xa hơn
```

Lưu thường (`store.queue(S)`) sau mỗi thay đổi nhỏ; lưu ngay (`store.save(S)`) sau khi mua hàng, trước khi hiện quảng cáo và khi về menu; `platform.on('pause', () => store.flush())`.

**Xong khi:** mua nâng cấp, tải lại trang: còn; xoá localStorage nhưng giữ bản mirror (giả lập `platform.save.backup`): tiến độ quay lại.

## 12. Mua trong app và shop

```js
import { platform, save } from './sdk.js';

function grant(p) {                       // p: { sku, token, orderId }
  const item = productBySku(p.sku);
  if (!item) return;
  if (!S.buys.some((b) => b.token === p.token)) {
    giveGoods(S, item);                   // gem, noAds, gói offer
    S.buys.push({ sku: p.sku, id: item.id, token: p.token, t: Date.now() });
    store.save(S);                        // lưu trước
    platform.an.earn('gem', item.gems || 0, 'iap');
  }
  platform.iap.finish({ sku: p.sku, token: p.token, orderId: p.orderId, consumable: !item.once, usd: item.usd });   // finish sau
}
async function buy(sku) {
  const r = await platform.iap.buy(sku);
  if (r.status === 'ok') grant(r);
  else if (r.status === 'pending') toast(t('shop_pending'));
}
export const merge = (into, from) => save.mergePurchases(into, from, { credit: (s, b) => giveGoods(s, productBySku(b.sku)), flags: ['noAds'] });
```

Giá hiện trên nút: `platform.iap.price(sku) || item.price`. Shop của Crash Ramp: 6 gói gem (10, 30, 100, 150, 200, 500 gem; $2.99 đến $29.99), Remove Ads $4.99, 1 gem cho mỗi video. Có nút **Restore purchases** khi `platform.iap.restorable`.

**Xong khi:** mua giả lập từng SKU: hàng vào đúng một lần; tải lại giữa chừng (trước `finish`): `pending()` giao lại, không trùng; `status: 'invalid'` không thưởng.

## 13. Offer

Bốn offer của Crash Ramp, luật bằng `monetize.due / shown / bought / openOffers` trên `S.offers`:

| Offer | Khi nào | Có gì | Giá |
| --- | --- | --- | --- |
| Starter | qua Map 1 hoặc lượt 12, mở 48 giờ, một lần | 60 gem, 5 rocket, tiền 5 lượt | $6.99 |
| Remove Ads | ngay sau interstitial thứ 3 trong ngày, tối đa 1 lần/ngày, 3 lần tổng | bỏ interstitial + 10 gem | $4.99 |
| Upgrade | 3 lượt liền không vượt kỷ lục (kẹt), mỗi 24 giờ | 3 gem, tiền 4 lượt | $0.99 |
| Season | đầu mỗi vòng map mới, mở 72 giờ | 30 gem, 10 rocket, tiền 8 lượt | $4.99 |

Chung: không popup trong 5 phút đầu phiên đầu, cách nhau ít nhất 3 lượt; offer đang mở có chip đếm ngược ở menu và dòng trên cùng của shop. "Tiền N lượt" tính theo map người chơi đang ở, để gói có giá trị như nhau ở mọi map.

```js
const st = monetize.offerState(S);
const d = monetize.due(st, OFFER_DEFS, OFFER, { now: Date.now(), runs: S.runs, day: liveops.dayKey() });
if (d) { monetize.shown(st, OFFER_DEFS.find((o) => o.id === d.id), OFFER, ctx); ui.offerPopup(d.id); track('offer_show', { id: d.id, why: d.trigger }); }
```

**Xong khi:** đổi giờ giả lập (`liveops.clock`), mỗi offer bật đúng lúc, đếm ngược đúng, mua một lần thì không hiện lại.

## 14. Remote Config

Mọi object trong `config.js` ghi đè được bằng khoá `<nhóm>_<khoá>`:

```js
import { monetize } from './sdk.js';
export function applyRemoteConfig(rc) {
  monetize.applyConfig({ ads: ADS, short: SHORT, offer: OFFER, m1: M1, notif: NOTIFY }, rc, new URLSearchParams(location.search));
}
```

Trên trình duyệt thử bằng query: `?ads=interEvery:3,interCooldown:60`. Giá trị Remote Config luôn là chuỗi; code luôn có mặc định.

**Xong khi:** `?ads=interFromRun:1` làm interstitial ra từ lượt 2; mọi khoá dùng có trong `remoteConfig` của `horus-game.json`.

## 15. Giữ chân: quà, nhiệm vụ, thu nhập khi vắng, thông báo

Dùng `liveops` thay vì tự viết đồng hồ và ngày:
- Phiên và ngày: `liveops.bootMeta(S.meta)` lúc mở, `liveops.resumeSession` / `pauseSession` theo `platform.on('resume' | 'pause')`.
- Quà 7 ngày: `liveops.calendarInfo` / `claimCalendar`. Nhiệm vụ ngày: `ensureMissions`, `missionProgress` (gắn vào `onTrack` của analytics), `claimMission`.
- Thu nhập khi vắng: `accrueOffline` / `claimOffline` (x2 bằng rewarded).
- Quà quay lại sau 7 ngày vắng: `liveops.giftDue`.

Thông báo local (Crash Ramp v2): tuần đầu tối đa 3 lần/ngày, đặt trước giờ người chơi hay mở game 15 phút, không trước 8:00 hay sau 22:00, rồi 1 lần/ngày tới ngày 14, rồi ngày 16, 18, 21, 24, 27, 30. Bỏ qua 9 lần liền thì chỉ 1 lần/ngày. Tiêu đề viết hoa, nội dung nói đúng thứ đang chờ (nâng cấp mua được, quà, kỷ lục).

```js
const plan = liveops.planNotifications({ now: Date.now(), starts: S.meta.hours, ignored: S.notify.ignored, config: NOTIFY, candidates, text });
platform.notif.schedule(liveops.toReminders(plan));
S.notify.plan = liveops.planRecord(plan);
// lúc mở lại: quay lại trong 4 giờ sau một thông báo cũng là phản hồi; thông báo tắt trên máy thì không đếm bị bỏ qua
const st = await platform.notif.state();
liveops.noteReturn(S.notify, Date.now(), platform.notif.opened?.kind || '', { respond: 240, enabled: !st.supported || st.enabled });
```

Xin quyền: `platform.notif.ask()` sau lượt thứ 2 (không ngay khi mở game; hỏi muộn thì phần lớn người chơi đã bỏ game trước khi được hỏi). Lập lại lịch mỗi lần `pause`. Thông báo có tiếng riêng lấy từ âm thanh có sẵn trong game (người chơi nghe là nhận ra game nào): `notif { sound: "sfx/notify.wav", headsUp: true }` trong `webgame.config.json`; Android nhắc bằng alarm nên Doze không nuốt.

Chia sẻ, mời bạn, mã quà (Crash Ramp v89):
- Nút Share ở màn kết quả: vẽ ảnh kết quả bằng canvas rồi `platform.share({ title, text, url, image })` (Android chooser, iOS share sheet, web `navigator.share` hay chép link). Link thách đấu để trong Remote Config.
- "Mời bạn": chỉ link, không thưởng (thưởng theo lượt mời là chỗ gian lận).
- "Mã quà": `liveops.redeemCode(S.codes, mã, rc.gift_codes, { caps: { coins: 2000, rockets: 5 } })`; bảng mã rỗng mặc định, mỗi người một lần, không bao giờ gem, trần kẹp trong code để Remote Config sai không làm lạm phát.

**Xong khi:** `platform.notif.schedule` được gọi khi ra nền với danh sách trong khung giờ; tắt Notifications trong Settings thì `cancelAll()`.

## 16. Analytics và phễu người mới

```js
import { liveops, platform } from './sdk.js';
export const FTUE_STEPS = ['open', 'first_pull', 'first_launch', 'first_result', 'first_x2', 'first_upgrade', 'run_2', 'run_5', 'map1_clear'];
const an = liveops.createAnalytics({
  state: S.an, steps: FTUE_STEPS, installAt: () => S.meta.installAt, build: GAME_BUILD,   // GAME_BUILD trong config.js ('v90'): tham số build trên mọi event
  ctx: () => ({ map: S.map, runs: S.runs, day: liveops.dayIndex(S.meta) }),
  sink: { log: (n, p) => platform.an.log(n, p), user: (p) => platform.an.user(p) },
});
export const track = (n, p) => an.track(n, p);
```

Sự kiện tối thiểu: `boot` (`ms` từ lúc mở tới khi chơi được), `run_start`, `run_end` (map, mét, tiền, thắng/thua: kèm `platform.an.result(won)`), `upgrade` (id, cấp, trả bằng gì), `map_clear`, mọi bước FTUE, `rv_offer` / `rv_start` / `rv_done` theo placement, `inter_show`, `offer_show` / `offer_buy`, `shop_open`. Tiền: `platform.an.earn` / `spend` mỗi lần nhận hay tiêu, `platform.an.balance` sau đó. Doanh thu quảng cáo và IAP do app tự gửi.

Robot không phải người chơi: máy Firebase Test Lab, báo cáo trước khi ra mắt của Play và máy ảo Android chạy bản release có `platform.device.robot = true`; vỏ app tự chặn tracking và quảng cáo thật trên đó (webgame 0.33.0, máy ảo từ 0.40.0). Khi đọc số liệu vẫn lọc máy của team và robot: ở Crash Ramp, 74 trên 119 "người chơi" ngày đầu là robot của Google.

**Xong khi:** chơi 3 lượt, mọi bước FTUE đã đi qua đều có trong `an.state.ftue`; mọi event có `build`; tên sự kiện và tham số chữ thường, phẳng.

## 17. Settings, hỗ trợ, ngôn ngữ, màn hình

Settings có: âm thanh, nhạc, rung, thông báo, ngôn ngữ, **Contact support** (`platform.support.contact({ to: 'support@horusvn.com' })`), mã hỗ trợ (`platform.support.id`), dòng cloud save (`cloud.statusText(await platform.cloud.status())`), **Privacy settings** khi `platform.ads.hasPrivacy`, **Restore purchases** khi `platform.iap.restorable`, phiên bản app.

Vòng đời: `platform.on('pause')` dừng game, tắt nhạc, lưu; `resume` chạy lại. Nút Back Android: `platform.onBack(() => closeTopPopup())` (trả `true` khi đã đóng một popup; ở menu trả `false` để app ra nền).

Màn hình: game phủ kín mọi máy; giữ chữ và nút trong vùng an toàn (`env(safe-area-inset-*)` trong CSS, sự kiện `platform.on('insets')`). Chữ dài theo ngôn ngữ phải tự co cho vừa nút.

Ngôn ngữ: chữ trong `src/i18n/<lang>.json`, không viết chữ thẳng trong code; tiếng Anh trước, rồi các ngôn ngữ trong `languages` của `horus-game.json`. Ngôn ngữ không phải chữ Latin cần font riêng nằm trong bản build.

**Xong khi:** mỗi nút trong Settings làm đúng việc trên trình duyệt; đổi ngôn ngữ không có chữ tràn nút; nút Back đóng popup trên cùng.

## 18. Kiểm tra trước khi build

Trên trình duyệt (cỡ điện thoại, CPU chậm 4 lần):
- Chơi từ save trống tới qua Map 1: không lỗi Console, không kẹt quá 3 lượt không mua được gì.
- Rewarded: xem hết thì thưởng, đóng sớm không; không có quảng cáo thì báo, không treo.
- Mua hàng: lưu trước `finish` sau, không giao hai lần, `pending()` lúc mở game, Restore.
- Interstitial đúng luật bước 10; Remove Ads bỏ được nó.
- Tải lại trang ở mọi màn: tiến độ còn.
- `horus-game.json` khớp code (placement, SKU, khoá Remote Config, sự kiện).
- Không có Google Analytics, AdSense, Firebase JS hay SDK quảng cáo nào khác; không tải gì từ CDN.

**Xong khi:** mọi dòng trên đã kiểm; `node horus-sdk/horus-build.mjs --dry-run` không còn dòng `chú ý:`.

## 19. Build ra app

```
node horus-sdk/horus-build.mjs --dry-run       # kiểm gói gửi đi
node horus-sdk/horus-build.mjs                 # APK cài thử
node horus-sdk/horus-build.mjs --aab           # khi Horus đã cài đặt game (appId)
```

`--play` và `--ios` chỉ khi người dùng yêu cầu. Mỗi bản gửi store tăng `GAME_BUILD`.

Cập nhật nóng (bản web mới tới người chơi không qua store, `packages/webgame/HOT.md`) mặc định tắt; Horus bật cho từng game. Chỉ cho JS, ảnh, âm thanh, dữ liệu; code native, SDK, icon vẫn cần bản store. Bản nóng đặt `--id` trùng build tag của game. Người dùng thích bấm thì mở trang build: `node horus-sdk/horus-build.mjs ui` (Windows: bấm đúp `horus-sdk\HorusBuild.cmd`). Lỗi thì đọc dòng lý do và log; gửi mã job cho Horus nếu cần.

**Xong khi:** có APK trong `build-online/`, cài vào máy Android mở được, chơi một lượt có quảng cáo thử.

## 20. Để được store feature (App Store, Google Play)

Không store nào có checklist bắt buộc: biên tập chọn theo chất lượng, trải nghiệm, trợ năng, ngôn ngữ, trang store và nội dung theo mùa. Làm từ đầu thì rẻ hơn làm sau (Crash Ramp, 24/10/2026).

Trong game:
- **Trợ năng.** Settings có "Reduce motion" (theo `prefers-reduced-motion` của máy cho tới khi người chơi tự bật tắt: rung camera, chớp màn hình, hiệu ứng màu giảm còn khoảng 30%, animation lặp của menu chạy một lần) và "Larger text" (chữ nhỏ dưới 18px phóng 1,2-1,3 lần; mặc định bật khi `platform.info.fontScale` từ 1,3). Mọi nút có chữ hoặc `aria-label`, công tắc có `role="switch"` + `aria-checked`. Vùng chạm từ 48px (thêm vùng chạm vô hình bằng `::before` nếu nút nhỏ hơn). Chữ phụ tương phản từ 4,5:1 với nền.
- **Game Center / Play Games** (`platform.games`, module `games`): bảng xếp hạng (quãng đường xa nhất mỗi map, mùa cao nhất) và ít nhất 10 thành tích, ít nhất 4 cái đạt được trong giờ chơi đầu, tối đa 1 cái trong 5 phút đầu. Đọc từ save, gửi lại tất cả khi có sự kiện `'games'` `{ signedIn: true }` (store giữ điểm cao nhất, bỏ qua mở khoá lần hai). Nút "Leaderboards / Achievements" trong Settings khi `platform.games.signedIn`. Khoá bảng và thành tích là hợp đồng: không đổi nghĩa khi đã lên store.
- **Sự kiện theo mùa** có thật trong game (không phải quà hằng ngày hay giảm giá): đó là nội dung cho In-App Events (iOS) và Promotional content (Play).
- **Kiếm tiền không làm phiền:** không mời mua ngay khi vào game, không chèn quảng cáo giữa màn, offer đúng lúc (bước 13).
- **Ổn định:** crash dưới 1,09%, ANR dưới 0,47% (Android vitals, 28 ngày); dưới 30 fps là mất điểm.

Ngoài game (Horus làm với tài khoản store):
- Game Center: bật cho app trong App Store Connect, tạo bảng và thành tích cùng khoá (ảnh thành tích 1024x1024), gửi duyệt cùng bản app. Play Games: tạo trong Play Console, chép mã project và id từng bảng, thành tích (dạng `CgkI...`, icon 512x512) vào `sdk.games` của `webgame.config.json`; publish ít nhất 2 giờ trước khi game lên.
- Đề cử Apple: App Store Connect > Featuring > Nominations, ít nhất 3 tuần trước ngày muốn lên, tốt nhất 3 tháng.
- In-App Event: tên 30 ký tự, mô tả 50 và 120; ảnh 16:9 1920x1080 và 9:16 1080x1920, không chữ, không logo; 15 phút tới 31 ngày. Promotional content Play: ảnh 1920x1080 không chữ, tagline 80, mô tả 500, tối đa 4 tuần, gửi trước ít nhất 4 ngày.
- Trang store: video gameplay 15-30 giây (iOS) và YouTube (Play), ảnh có chữ bản địa cho thị trường lớn, nhãn trợ năng App Store chỉ khai cái game đạt thật (Larger Text cần chữ 200%, Reduced Motion không khai được nếu quảng cáo video không giảm được chuyển động).

**Xong khi:** Settings có Reduce motion, Larger text và (trong app) Leaderboards / Achievements; mọi nút từ 48px; README của game ghi khoá bảng và thành tích; có ít nhất một sự kiện mùa chạy được trong game.
