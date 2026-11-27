# Làm một game như Crash Ramp

Hướng dẫn từng bước cho AI agent (và người) làm một game hybrid-casual 3D bằng Horus SDK, ra kết quả cùng loại với **Crash Ramp: Car Upgrade** của Horus: một màn chơi ngắn, tiền kiếm được theo quãng đường, nâng cấp giữa các lượt, nhiều map nối nhau, quảng cáo rewarded và interstitial, shop gem, offer, lưu và cloud save, analytics, Remote Config, thông báo nhắc chơi, rồi build ra Android/iOS qua Horus.

Cách dùng: làm lần lượt từ bước 0. Mỗi bước có **Xong khi**: kiểm đủ các ý đó rồi mới sang bước sau. Con số trong hướng dẫn là của Crash Ramp (bản 0.1.0 trên store), dùng làm điểm xuất phát rồi chỉnh theo game. API đầy đủ: `horus-sdk.d.ts`; quy tắc ngắn: `AGENTS.md`. Game Godot: `godot/README.md` và `godot/AGENTS.md`.

## Prompt cho agent

Dán vào Claude Code, Cursor, Codex... ở gốc repo game (đã chép gói SDK vào `horus-sdk/`). Sửa phần trong `< >`.

**Bắt đầu game mới:**

```
Đọc hết horus-sdk/GAME-GUIDE.md và horus-sdk/AGENTS.md trước khi viết code.
Làm game "<tên game>": <2-3 câu: người chơi làm gì trong một lượt, tiền theo gì, nâng cấp gì, map sau khác gì>.
Game tham khảo: <tên hoặc link>. Hướng màn hình: <portrait/landscape>. Số map đầu tiên: <6>.

Làm đúng thứ tự các bước 0 đến 21 của GAME-GUIDE.md:
- Bước 0: viết docs/design.md, hỏi tôi những gì chưa rõ và chờ tôi đồng ý rồi mới làm tiếp.
- Sau mỗi bước: kiểm đủ mục "Xong khi" của bước đó trên trình duyệt ở cỡ điện thoại, báo tôi một dòng
  (bước nào xong, đã kiểm gì), rồi làm bước kế. Một mục chưa đạt thì sửa, không bỏ qua.
- Mọi con số để trong src/config.js, bắt đầu từ số của Crash Ramp trong hướng dẫn. Đổi kinh tế thì chạy
  mô phỏng (economy.simulateEconomy) và cho tôi xem bảng trước khi chốt.
- Chỉ dùng Horus SDK cho quảng cáo, mua hàng, analytics, lưu game; không thêm SDK hay thư viện tracking nào khác,
  không tải gì từ CDN, không sửa file trong horus-sdk/.
- Build: chỉ --dry-run và APK thử. --play hay --ios chỉ khi tôi bảo.
- Làm cả bản cho video editor và bộ playable cho marketing (bước 19, hai mục "Bản cho video editor" và "Bản playable cho marketing"), báo tôi link của từng cái.
```

**Phiên mới, làm tiếp:**

```
Đọc docs/design.md, horus-sdk/GAME-GUIDE.md và horus-sdk/AGENTS.md. Xem lại từng bước 0 đến 21 theo mục "Xong khi"
(chạy game trên trình duyệt để kiểm, đừng đoán), cho tôi bảng bước nào xong, bước nào chưa, rồi làm tiếp bước đầu tiên chưa xong.
```

**Kiểm trước khi gửi build:**

```
Kiểm game theo bước 18 của horus-sdk/GAME-GUIDE.md và mục "Kiểm tra trước khi báo xong" của horus-sdk/AGENTS.md.
Sửa mọi lỗi tìm thấy, chạy node horus-sdk/horus-build.mjs --dry-run tới khi không còn dòng "chú ý:", rồi build APK thử
và báo tôi đường dẫn file.
```

**Game chậm trên máy yếu:**

```
Game chạy <N> khung/giây trên <tên máy>. Đọc mục 5 của horus-sdk/GAME-GUIDE.md. Đo trước (bench trên máy thật,
đếm lệnh vẽ, profile CPU), cho tôi bảng thời gian GPU và JS mỗi khung và việc định làm. Chỉ làm những việc giữ
nguyên hình (so từng điểm ảnh, lệch tối đa 1/255); việc nào đổi hình (hạ độ nét, tắt bóng, tắt bloom) thì hỏi tôi trước.
```

**Có crash mới:**

```
Crashlytics có crash/ANR mới: <mã issue hoặc ảnh chụp>. Làm theo mục 21 của horus-sdk/GAME-GUIDE.md: bao nhiêu người
chơi thật, bản nào, máy và WebView nào; nguyên nhân kèm bằng chứng (stack, sự kiện analytics trước lỗi); sửa kèm test.
Nói rõ khi nào mới biết chắc đã hết lỗi.
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
  "privacyUrl": "https://mygame.example/privacy",
  "termsUrl": "https://mygame.example/terms",
  "urlScheme": "mygame",
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

Mẫu trên chỉ có phần của game. Phần id của app (`sdk`, `android.sdk`, `ios.sdk`: ad unit MAX, Adjust kèm token bốn mốc `mkt_*` trong `adjust.events`, Facebook, licence key Play) chép từ file mẫu `horus-sdk/horus-game.json` của gói SDK rồi điền (README mục 12, "Id của app"). Game có quảng cáo MAX mà `privacyUrl` trống thì build bị từ chối.

Quy tắc: placement chữ thường không dấu; SKU không bao giờ đổi sau khi đã lên store (đặt tên theo gói, không theo số gem: `gems_pack_1`, không `gems_80`); `appId` để trống tới khi Horus cấp.

**Xong khi:** mọi placement, SKU, khoá Remote Config và sự kiện mà code dùng đều có trong file (tìm trong `src/` bằng grep và so).

## 3. Một file config cho mọi con số

Mọi số ảnh hưởng tới kinh tế và quảng cáo nằm trong `src/config.js`, dạng object để Remote Config ghi đè được (bước 14). Không viết số thẳng trong `game.js` hay `ui.js`.

```js
// src/config.js (Crash Ramp)
import { monetize } from './sdk.js';
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
  for (const p of await platform.iap.pending()) if (p.state !== 'pending') game.grant(p);   // 7. đơn đã trả tiền chưa giao ('pending': chưa trả xong, không giao, không finish)
  recoverLostAds(game);                                // 7b. quảng cáo thưởng xem hết lúc trang bị tắt (bước 8)
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

Ngân sách cho máy tầm trung (mục tiêu 60 khung/giây): dưới 150 draw call (máy yếu như Galaxy A10: dưới 80), dưới 300 nghìn tam giác trên màn hình, một đèn có bóng, bóng nướng sẵn cho cảnh tĩnh, texture tối đa 1024, model gộp mesh theo vật liệu. Hiệu ứng hạt dùng `fx.Fx` (tối đa 4 draw call cho mọi hạt), xu bay về ví dùng `fx.createCoinFly` trên lớp HTML.

Màn 90/120 Hz: gọi `platform.device.setFrameRate(60)` lúc mở game và vẽ tối đa 60 khung/giây (bỏ khung `requestAnimationFrame` thừa), cho đổi bằng Remote Config. Nhanh hơn 60 chỉ làm máy nóng và tốn pin, người chơi không thấy khác (Crash Ramp v87). Bỏ khung theo đồng hồ, không chỉ "mỗi khung thứ n": màn 90 Hz không chia hết cho 60, mà máy có thể không cho đổi chế độ. Galaxy A16 (Android 17, store 25/11/2026) giữ 90 Hz trong app, `skip = floor(90 / 60)` = 1 nên game vẽ 90 khung/giây. Crash Ramp v107l: màn là bội số của 60 (120, 180) thì vẽ mỗi khung thứ n, đều nhau; màn khác (90, 144) thì vẽ khi tới lượt 1/60 s, tối đa 60 khung/giây (ở 90 Hz là 2 trong 3 khung). Kiểm tần số màn trong app: `adb shell dumpsys SurfaceFlinger --latency '<tên layer>'` (dòng đầu là vsync, 11,1 ms = 90 Hz) hoặc `dumpsys display | grep mActiveRenderFrameRate`.

Nhạc nền dùng `.mp3`, không `.ogg`: iPhone đời cũ không giải mã được `.ogg` và game mất nhạc mà không báo lỗi. Khi `pause` thì nhả nhạc nền khỏi bộ nhớ, `resume` thì nạp lại: máy RAM thấp hay giết WebView khi game ở nền (Crash Ramp v90).

### Máy yếu và WebView cũ

Nhiều máy Android 10 rẻ chưa bao giờ cập nhật WebView: Galaxy A10 (2 GB) trong Firebase Test Lab chạy Chrome 81. Build JS cho Chrome 80 (`?.` và `??` có từ 80; dưới đó trang không chạy). Từ SDK 0.26.1 file Horus SDK tự thêm những hàm mới hơn mà game hay gọi, chỉ khi WebView thiếu (`@horus/webgame/compat`, game dùng kit thì `import '@horus/webgame/compat';` ở dòng đầu tiên của `main.js`): `Array.prototype.at` (Chrome 92), `Element.prototype.replaceChildren` (86), `CanvasRenderingContext2D.prototype.roundRect` (99), `Element.animate()` với keyframe thiếu thuộc tính và `Element.getAnimations()` (84). Ở Crash Ramp, một `.at()` trong bench làm cả bài test trên A10 không ra kết quả (v97d); `animate([{ opacity: 0 }])` (chỉ một keyframe) ném lỗi lúc dựng Map 2 nên trang tải lại, và `getAnimations()` thiếu làm game kẹt ở thẻ kết quả (v98c).

Những thứ polyfill không cứu được, tự tránh: `String.prototype.replaceAll` (Chrome 85: dùng `.split(a).join(b)` hoặc regex `/g`; một bản thử Crash Ramp trên A10 không vẽ gì vì nó), CSS `:where()` (Chrome 88: WebView cũ bỏ cả rule, nên viết thêm một selector thường cho rule quan trọng), thuộc tính CSS `inset` (87: để bước build hạ xuống `top/right/bottom/left`).

Máy có WebView dưới 80 thì game không chạy và cũng không gửi được gì. Từ @horus/webgame 0.49.0 app Android tự kiểm trước khi mở game: WebView cũ hơn `android.minWebView` (mặc định 80) thì hiện màn có nút mở trang WebView trong Play Store để cập nhật, và ghi `webview_old` `{ wv, min, pkg }` để đếm số máy như vậy. Game build cho Chrome thấp hơn 80 thì hạ `android.minWebView` theo.

Đổi map trên máy 2 GB là lúc dễ chết nhất: RAM gần hết, GPU có thể ngừng trả khung hình. Crash Ramp v97f trên A10 đứng ở màn chờ Map 2 mãi vì code nạp map chờ `requestAnimationFrame` không giới hạn. Luật từ v97g:
- Giải phóng map cũ (mesh, texture, xe) trước khi dựng map mới.
- Mọi lần chờ khung hình trong lúc nạp tối đa 100 ms; dịch shader trước (`precompile` / `compileAsync`) tối đa 8 giây.
- Bọc hàm nạp map bằng try/catch và một watchdog: 30 giây không có bước nào tiến thì ghi map mới vào save rồi tải lại trang, để map mới dựng từ trang sạch. Tối đa một lần tải lại mỗi phút; lần sau thì hiện nút "tải lại", không lặp.
- Thời gian app nằm nền không tính vào 30 giây đó: khi trang ẩn, hoặc timer của watchdog bị giữ lâu hơn 15 giây, thì đếm lại từ lúc trang hiện lại. Nếu không, người chơi chuyển sang app khác trong lần mở đầu (máy yếu tải 15-70 giây) sẽ bị tải lại từ đầu khi quay về (Crash Ramp v98a).
- Mất context WebGL trong lúc nạp thì cũng tải lại (cùng giới hạn một lần mỗi phút).
- Không đặt timer cần WebGL trước khi WebGL có: app bị chuyển ra nền ngay lúc mở thì context chưa có. Gửi `boot_fail` và tải lại khi trang hiện lại.

**Lỗi driver GPU trên một dòng máy: né đúng máy đó (Crash Ramp, Pixel 10, 11/2026).** WebView mới chạy WebGL qua ANGLE trên driver PowerVR D-Series của Pixel 10 / 10 Pro (Android 17, WebView 156-157). Vẽ có lấy mẫu shadow map làm crash native trong `libGLESv2_powervr` 2-5 giây sau khi mở, hoặc `gl_lost` ngay sau `ready` rồi `boot_fail`. Cả 6 người chơi Pixel 10 chưa chơi được ván nào và gỡ game. Firebase Test Lab không tái hiện được vì máy ở đó chạy WebView 134 (chưa có ANGLE). Cách làm:
- Có sẵn một "chế độ an toàn GPU" trong game (tắt bóng thật, bỏ bước GPU nặng lúc mở như môi trường, đọc pixel không đồng bộ), bật theo model máy **và** tên GPU (`gpu` của `device_perf`), khớp hẹp: một luật `/PowerVR/` rộng sẽ dính cả máy rẻ PowerVR GE8320 vốn chạy tốt.
- GPU lỗi nhiều thì vào chế độ an toàn từ lần mở đầu, đừng chờ máy hỏng một lần (Crash Ramp v106o, 23/11/2026, BigQuery 14-22/11): GPU tên "PowerVR SGX Maca" (BXM: moto g54 / g64 / g power 2024, Redmi 24094RAD4G) gặp lỗi ở 7/49 máy, Mali + Adreno + Xclipse cộng lại 1/3.193. So tỉ lệ lỗi theo tên `gpu` (tham số của `boot`) trước khi chọn máy. Máy vừa vào thang mà bản cũ mới crash thì vẫn bắt đầu ở mức nhẹ nhất (v106p).
- Tải lại trang ngay sau khi mất WebGL trên màn hình thường không tạo được context mới (Chrome / WebView chặn khoảng 2 phút sau khi GPU reset): 5/5 lần `boot_fail` của Crash Ramp 0.1.6-0.1.9 đến 4-12 s sau `gl_lost`, trang đứng ở màn tải và 3/5 người không quay lại. Boot hỏng vì WebGL phải hiện thẻ có nút bằng DOM thường (UI của game chưa có) và tự tải lại theo nhịp dài dần (5 / 15 / 30 / 45 / 60 s), đếm trong `sessionStorage`, chỉ xoá đếm sau 30 s chơi; trang đang ẩn thì chờ hiện lại. Không tự tải lại khi không đếm được.
- Ghi chế độ đang dùng vào Crashlytics key và analytics (`gpu_safe`) để biết có hết lỗi.
- Test Lab chạy WebView cũ hơn người chơi thật thì "Test Lab qua" không chứng minh lỗi đã hết: chỉ tin Crashlytics của bản mới trên đúng dòng máy đó.

### Tối ưu GPU máy yếu, không đổi hình

Crash Ramp trên Galaxy A10 (Mali-G71 MP2, 2 GB, WebView 81) chạy 12 khung/giây ở Map 1: GPU khoảng 83 ms mỗi khung, JS khoảng 30 ms. Mục tiêu trên 30 khung/giây mà hình không đổi. Luật rút ra (v98g đến v98q):

**Đo trên máy yếu thật trước khi sửa.** Firebase Test Lab có A10 trong quota miễn phí (30 phút máy thật mỗi ngày, ngày tính theo nửa đêm giờ Pacific; không trả phí). Game có bench tự chơi (`?bench`, chạy bằng Game Loop của Test Lab) báo fps, ms JS chia phần update của game và phần render của three, và các biến thể bỏ từng phần (mặt đất, cảnh vật, trời, hậu kỳ, cảnh rỗng) để biết khung đi đâu. Mỗi lần chạy chỉ một máy, không chạy lại khi lỗi.

**Ngân sách.** Mali-G71 MP2 khoảng 2 lõi × 450 MHz: 30 khung/giây là khoảng 30 triệu chu kỳ shader mỗi khung. Màn 412×869 ở 1.5x là khoảng 800 nghìn điểm ảnh, tức khoảng 37 chu kỳ mỗi điểm ảnh cho mọi thứ, kể cả hậu kỳ. Đo chu kỳ của shader thật bằng Mali Offline Compiler (Arm Performance Studio, chạy trong Docker không mạng): dump nguồn GLSL của từng program sau khi three compile (`gl.getShaderSource`), rồi so đường dài nhất. Shader mặt đất của Crash Ramp: 76 chu kỳ, dùng 64 thanh ghi (một nửa số luồng).

**Tìm phần nặng trong một shader.** Từ nguồn GLSL đã dump, làm vài bản chẩn đoán, mỗi bản bỏ đúng một phần (gán hằng số cho một biến). Chạy Mali Offline Compiler cho từng bản và so đường dài nhất với bản gốc. Các bản này chỉ để đo, không đưa vào game. Crash Ramp v100c, mặt đất Map 1 (ánh sáng theo đỉnh), 2/11/2026:

| Bản | Mali-G52 (chu kỳ) | Mali-G68 (chu kỳ) |
|---|---|---|
| Nguyên bản | 18,0 | 15,1 |
| Bỏ phần màu đường | 11,5 (−36%) | 10,1 (−33%) |
| Bỏ khối đá | 15,0 (−17%) | 12,4 (−18%) |
| Bỏ các lần đọc nhiễu chi tiết | 17,0 (−6%) | 14,5 (−4%) |
| Bỏ bóng nướng | 17,7 (−2%) | 14,9 (−2%) |

Shader không tràn thanh ghi ra bộ nhớ và không có phép tính 16 bit. Phần nặng là các phép tính màu của đường và đá, không phải số lần đọc texture.

Đổi varying trong `onBeforeCompile` (ví dụ sang `mediump`): các varying của three (`vNormal`, `vColor`...) lúc đó vẫn còn là dòng `#include <normal_pars_fragment>`, chỉ hiện ra khi three ghép chunk sau `onBeforeCompile`. Phép thay chữ không khớp mà không báo lỗi. Viết chunk ra trước (`THREE.ShaderChunk[...]`) rồi mới thay, và luôn kiểm bằng shader đã dịch (`gl.getShaderSource`), không bằng chuỗi nguồn. Crash Ramp v100f thiếu vNormal nên đường đất trên G68 vẫn 50 thanh ghi; v100h sửa.

**Một khung 3x đi vào đâu** (Galaxy A16, Mali-G68 MP2, Chrome, Crash Ramp v100g/h Map 1 lúc bắt đầu, 1080x1929, 2/11/2026; cách đo ở "Đo cho đúng"). Khung có bloom như người chơi thấy: khoảng 25 ms GPU, tức tối đa khoảng 40 fps. Mỗi dòng là thời gian khung bớt đi khi bỏ phần đó:

| Phần | ms | Phần | ms |
|---|---|---|---|
| Bầu trời (shader tính mỗi điểm ảnh) | 4,4 | Hậu kỳ (target trung gian + pass toàn màn) | 2,0 |
| Bloom, trong đó pass lọc sáng đọc cả cảnh 3x 3,1 | 4,3 | Bóng thật của xe | 1,2 |
| Cây, bụi, đá (ánh sáng theo đỉnh) | 3,4 | Cỏ | 0,6 |
| Mặt đất | 3,7 | Xe | 0 |

Trên G68, đổi target và pass rỗng gần như không tốn: 5 pass vào target 4x4 thêm 0,0 ms. Phép tính của pass cuối chỉ khoảng 0,3 ms, target half float thay 8 bit chỉ khoảng 0,2 ms. JS khoảng 4 ms mỗi khung cho phần vẽ, 6-7 ms khi đang chạy: GPU là chỗ nghẽn. Đo cả khung trước khi tối ưu một shader. Bầu trời nặng hơn mặt đất, và bench cũ chưa từng tách riêng nó ra.

Tách tiếp từng phần (v100j, cùng cách đo):
- **Bầu trời:** khoảng 29 chu kỳ mỗi điểm ảnh trên G68 (phần mây), gấp 2-3 lần mặt đất, phủ nửa trên màn hình.
- **Cây, bụi, đá:** tắt ghi màu của chúng (vẫn chạy shader đỉnh, raster, độ sâu) vẫn còn 3,0 trong 3,4 ms. Chi phí nằm ở đỉnh (187 nghìn tam giác), không ở điểm ảnh. Shader điểm ảnh chỉ khoảng 3 chu kỳ, shader đỉnh nghẽn ở đọc dữ liệu.
- **Pass lọc sáng của bloom:** nghẽn ở đọc texture half float có lọc. Cùng pass trên cảnh 8 bit chỉ 0,3 ms thay vì 3,0; một mẫu thay vì bốn: 1,3 ms.
- **Varying 16 bit cho cỏ hai mặt và cho mây:** mỗi cái 0,3 ms. Ảnh lệch tối đa 2/255.
- **Cảnh vật đứng yên, không đổ bóng, chỉ vẽ instance trong tầm nhìn (v100k):** đỡ 0,7 ms. Thời gian JS của phép lọc không đo ra được trên đường chạy.
- **Nhiễu của mây đọc bằng một lần lấy mẫu có lọc của texture (v100l), thay vì `texelFetch` rồi tự trộn 4 góc:** đỡ 1,2 ms. Ảnh lệch 1/255 trên 1,2% điểm ảnh.
- **Sau v100l:** khung có bloom còn khoảng 21 ms ở 3x (trước v100f khoảng 25 ms).

- **Ẩn hết mọi vật (chỉ còn xoá target HDR và pass cuối):** vẫn tốn 3,6 ms, trong khi xoá canvas thẳng chỉ tốn 0,5 ms. Riêng việc vẽ qua target trung gian ở 3x đã khoảng 3 ms.
- **Núi xa, ná, xu, hạt, chim:** mỗi thứ khoảng 0 ms.
- **Bóng xe:** vẽ bản đồ bóng 0,6 ms, lấy mẫu bóng 0,4 ms.
- **Bầu trời:** chiếm 42% điểm ảnh ở góc nhìn đầu Map 1.
- Bớt từng phần thì không cộng dồn được: ẩn mặt đất lộ ra trời, ẩn cây lộ ra đất.
- **Độ nét, khung có bloom như người chơi thấy (v100l, khung đứng yên):**

  | Độ nét | 3x | 2,75x | 2,5x | 2,25x | 2x |
  |---|---|---|---|---|---|
  | GPU mỗi khung | 21,4 ms | 18,3 | 16,1 | 14,5 | 12,4 |

  Trên đường chạy: 3x 33,8 fps, 2,5x 44,8 fps; JS khoảng 7,7 ms ở cả hai.
- **HUD bằng DOM là phần nặng nhất khi đang chạy (v100n):** trên đường, ẩn HUD (`display:none`) đưa A16 ở 3x từ 34,3 lên 48,7 fps. Khoảng cách khung giảm từ 28,9 xuống 21,1 ms, khung từ 37 ms trở lên giảm từ 27% xuống 3%. Khi khung đứng yên, HUD chỉ tốn khoảng 1,5 ms. Cái đắt là HUD đổi mỗi khung (chữ, vòng tốc độ, transform): trình duyệt phải vẽ lại ở tỉ lệ điểm ảnh 3 rồi ghép lên canvas.
  - Đo khoảng 8 ms chênh giữa khung đứng yên và khung đang chạy: ẩn HUD trước, rồi mới nghi tới GPU.
  - Cùng lần đo, xung GPU vẫn 949 MHz, bận 94%. Đóng băng bản đồ bóng chỉ được 7%.
  - Xung và độ bận của GPU đọc được không cần root: `adb shell cat /sys/kernel/gpu/gpu_clock /sys/kernel/gpu/gpu_busy` (Samsung Exynos).
  - Cách sửa giữ nguyên hình (v100r): mỗi phần HUD đổi mỗi khung (khoảng cách, tốc độ, thanh) có lớp ghép riêng, `will-change: transform` trên từng widget, không bao giờ trên khung chứa phủ cả màn. Không có thì Chrome vẽ lại một lớp cả màn ở tỉ lệ điểm ảnh của máy mỗi khung rồi trộn lên game: A16 ở 3x tốn khoảng 10 ms một khung khi đang chạy, tách lớp lấy lại khoảng 6 ms (trên đường 31,6 lên 38,4 fps, hình như cũ).
  - Canvas phủ cả màn đang rảnh (như canvas CoinFly) thì ẩn bằng `visibility:hidden`.
  - Kiểm bằng CDP `LayerTree` trong một lượt chạy: ngoài canvas game không còn lớp nào to bằng màn hình.
  - Phần tử HUD có lớp ghép riêng (`will-change: transform`, hoặc đang animate transform) không được mang `filter` (drop-shadow, blur), kể cả filter đứng yên. Đo trên OPPO A15 (PowerVR GE8320), nút tên lửa đang có gợi ý của Crash Ramp: bỏ filter mà giữ animation scale thì nhanh hơn 10 ms mỗi khung. Bỏ animation mà giữ filter tĩnh (v100y) thì không nhanh hơn chút nào (1 ms). Ẩn hẳn nút: 12 ms. Có lẽ compositor áp lại filter của lớp đó mỗi khung. Glow thì vẽ thẳng vào nội dung lớp: `box-shadow` tĩnh hoặc nền `radial-gradient` (thêm pseudo-element nếu cần), rồi chỉ animate `transform` và `opacity`. Cũng không animate `box-shadow` hay `text-shadow`, vì chúng vẽ lại mỗi khung.
    - Đã kiểm (v100z): glow bằng `box-shadow` tĩnh, `filter: none`, chỉ animate scale. Khi gợi ý bật: 42,9 ms một khung, bản dùng filter tĩnh 56,3 ms (23,1 so với 18,5 fps cả lượt). Khung có gợi ý không còn chậm hơn khung không có.
  - **Menu chậm vì một glow CSS (Crash Ramp v102m, 9/11; menu chỉ 17-24 khung/giây trên Galaxy A16):**
    - Chrome của A16, 3x, canvas 1080x1929, GPU 949 MHz bận 99 %: menu không giới hạn khung chạy 26,7 fps. Bỏ từng phần ra để đo: ẩn cả UI 45-47 fps; chỉ dừng animation glow viền của một thẻ (đổi `box-shadow` theo nhịp) 43 fps (+61 %). Bloom, mặt đất, xe mỗi thứ chỉ 5-19 %.
    - Vì sao: animation CSS đổi thuộc tính phải vẽ (`box-shadow`, `filter`, `left`, `background`...) làm Chrome vẽ lại cả lớp chứa nó mỗi khung, rồi GPU raster lại lớp đó ở tỉ lệ điểm ảnh của máy. Ở menu, lớp đó là lớp UI phủ cả màn. Animation đổi `transform` / `opacity` chạy trên compositor, không vẽ lại.
    - Cách sửa, giữ hình: vẽ sẵn glow trên một lớp riêng (`::before` / `::after` mang `box-shadow`, vẽ một lần), animation chỉ đổi `opacity` của lớp đó, thêm `transform` nếu cần phóng to. Glow quanh nút tròn: `box-shadow` của lớp riêng thay `filter: drop-shadow`. Vệt sáng chạy ngang: `translateX` thay `left`. Nút có `overflow: hidden` thì chuyển phần cắt vào phần tử con, để lớp glow nằm ngoài viền. Bóng của chính nút (mép tối dưới) nằm trên glow như cũ: bóng chuyển sang một lớp riêng (`z-index: -1`) trên lớp glow (`-2`), nút có stacking context riêng (`isolation: isolate`), nên vẫn dưới hình và huy hiệu của nút. Lớp có animation đặt ở `::after`: bộ co chữ (`@horus/i18n` fit) ẩn `::before` của nút lúc đo, animation ở đó sẽ chạy lại từ đầu. Khác về hình duy nhất: viền dày sẵn rồi mờ dần, thay vì to dần từ 0.
    - Kết quả (Chrome của A16, menu để yên, hai vòng cũ / mới / mới / cũ, mỗi trang 6 lượt 4 s, máy mát): game vẽ ở trần 30 lần/giây: trước chỉ được 20-21,5, sau đủ 30 (khung trình duyệt 33,3 → 11,1 ms, GPU bận 99 → 87 %); không giới hạn khung: 26,2-26,7 → 42,5-43,2 fps (+60 %). Ẩn cả UI: 45 fps, nên phần UI còn lại chỉ tốn khoảng 6 %.
    - Gate (`tools/framegate.mjs` của Crash Ramp, luồng `idle`): menu để yên 10 s, đếm số lần Chrome vẽ lại UI mỗi giây (sự kiện `Paint` trong trace, canvas WebGL không tính) và liệt kê animation đang chạy đổi thuộc tính khác `transform` / `opacity` (`document.getAnimations()`); có là trượt. Crash Ramp trước: 120 lần vẽ lại mỗi giây; sau: 0. GPU của PC không thấy chi phí này, nên gate đo nguyên nhân, không đo fps.
    - Chụp ảnh so sánh bằng puppeteer: `page.screenshot` mặc định đổi cỡ viewport lúc chụp. Animation của `::before` trong `<button>` khi đó chạy lại từ đầu, nên ảnh không thấy glow. Dùng `captureBeyondViewport: false`.
  - Web Animation (`element.animate`) không có `fill` thì hủy khi xong: `a.onfinish = () => a.cancel()`. Còn gắn trên phần tử thì các CSS animation của phần tử đó không chạy trên compositor (Crash Ramp v101b, trace Chrome: compositeFailed 64, khoảng 120 lần tính lại style + 1.000 lần cập nhật layer mỗi 2 giây trên luồng chính).
- **Máy rất yếu, OPPO A15 (Helio P35, PowerVR GE8320, 2,9 GB RAM, màn 720x1600 60 Hz, tỉ lệ điểm ảnh 2), Crash Ramp v100t trong Chrome, đang chạy:**

  | Độ nét | 2x | 1,5x | 1,25x | 1x | 1x, ẩn HUD |
  |---|---|---|---|---|---|
  | fps | 10,3 | 15,6 | 18,6 | 19,6 | 24,2 |

  - JS khoảng 21 ms mỗi khung (update 5,4 + render 16,1 ms trên lõi A53), nên riêng CPU đã chặn khoảng 45 fps.
  - HUD bằng DOM tốn khoảng 10 ms, vì DOM vẫn vẽ ở tỉ lệ 2 dù canvas để 1x.
  - Bản Play tester đo được 18,9 fps.
  - Cùng máy, một game Unity thủ thành (Unity 2022.3, IL2CPP, GLES) đạt 57,8 fps ở đủ 720x1600: cảnh nhìn từ trên xuống, nền phẳng, phần CPU chạy hai luồng mã máy.
  - Ở 1x một khung khoảng 51 ms: mặt đất khoảng 13 ms, cây cỏ 13, trời 5, xe 5. Không vẽ cảnh 3D nào, trang vẫn tốn khoảng 20 ms (update, ghép HUD, trình chiếu). Máy nghẽn ở GPU.
  - Thử cấu hình máy yếu trên chính máy này (đang chạy, mỗi cấu hình một lượt riêng):
    - mức thấp nhất hiện nay (1x, không bloom, có bóng, target HDR): 18,2 fps;
    - bỏ bóng thời gian thực, bỏ target HDR và pass hậu kỳ, nửa số cây cỏ: 22,9 fps;
    - thêm mặt đất đơn giản và trời không mây: 23,0;
    - hạ tiếp xuống 0,85x: 23,1.
  - Sau bước đầu, bớt tô màu không còn giúp gì: máy kẹt ở JS (~19 ms), HUD DOM (~10 ms) và phần trình chiếu.
  - Cùng cấu hình bỏ bóng / bỏ HDR / nửa cây cỏ mà ẩn thêm HUD DOM: 32,1 fps (khung giật dài từ 58% còn 26%). HUD tốn khoảng 12 ms mỗi khung trên máy này, nên trên máy yếu nó là bước lớn nhất sau khi đã giảm hình.
  - Cấu hình đó thành bản game ở Crash Ramp v100v: cờ máy rất yếu `crashramp.vweak`, do governor tự đặt; bỏ bóng, vẽ thẳng ra màn (không target HDR, không hậu kỳ), nửa cây cỏ; chỉ khi Settings để Tự động. Một lượt 128 giây trên đường, HUD DOM bật và ẩn xen kẽ mỗi 9 giây: có HUD 26,4 fps (37,9 ms, khung ≥37 ms 41%, update 5,0 + render 11,0 ms), ẩn HUD 39,2 fps (25,5 ms, 16%, 3,6 + 10,5 ms). Cao hơn lượt thử bằng công tắc bench (22,9 và 32,1), render JS 11 ms thay vì 15.
  - v100w chỉ ghi số trên HUD (xu, mét, km/h) 3 khung một lần. Bốn lượt xen kẽ V, W, V, W, có HUD: 26,3 lên 28,2 fps, khung ≥37 ms từ 40% còn 35%. Phần HUD (có trừ ẩn, trong cùng lượt) từ khoảng 14 ms còn 10-11 ms. Ẩn HUD hai bản như nhau (41,5 và 40,3 fps). Phần lớn chi phí HUD không nằm ở việc đổi chữ.
  - v100x (shader tự ra sRGB trên đường vẽ thẳng, shader biên dịch trước lượt chạy): fps như v100w (26,3 và 25,8, có HUD). Khung dài nhất trong 3 giây đầu lượt 119-135 ms thay vì 175-185 ms, không còn shader nào biên dịch trong lượt.
  - Luật rút ra từ v100x cho game three.js có hai đường vẽ (thẳng ra màn và qua composer HDR): mọi `ShaderMaterial` tự viết phải kết thúc bằng `#include <tonemapping_fragment>` và `#include <colorspace_fragment>` (vào target tuyến tính thì hai dòng này không làm gì). Thiếu chúng thì trên đường vẽ thẳng màu ra tối và đậm (Crash Ramp: bụi nâu sẫm, trời đậm hơn trên OPPO A15). Dịch shader trước (`compileAsync`) với target giống đầu ra thật: three dịch biến thể khác nhau cho màn hình và cho render target (Crash Ramp thấy 14 lần dịch ở đầu lượt cho tới khi sửa).
  - Ẩn từng phần HUD 4 giây, xen kẽ với 4 giây hiện đủ, so mỗi cửa sổ với cửa sổ hiện đủ ngay trước và sau nó (cùng đoạn đường): đồng hồ tốc độ, thanh động cơ, nút dừng, tay và chữ hướng dẫn, toast đều khoảng 0 ms. Khối trên (xu, mét, thanh tiến độ) 1-5 ms. Nút tên lửa 10-14 ms, toàn bộ là nhịp gợi ý `.hintp` (xem luật animation ở trên). Không có gợi ý, HUD còn khoảng 7 ms mỗi khung. Gộp HUD về một lớp (bỏ class `hudl`) chậm hơn khoảng 4 ms.
  - Cửa sổ ẩn/hiện phải tính theo thời gian chạy và lệch chu kỳ với độ dài lượt chơi. Chu kỳ 56 giây trùng lượt chạy khoảng 60 giây làm mỗi phần luôn rơi vào cùng một đoạn: ẩn thanh động cơ ra +3,6 ms, vô lý.
  - Bench không lưu (`nosave`) là người chơi mới mỗi lượt: gợi ý tên lửa chờ bấm nên bật 61% số khung. Số "có HUD" của bench như vậy gồm cả nhịp gợi ý.
  - Trên máy hạng này, hạ độ nét không đủ, phải bớt việc mỗi khung ở cả CPU lẫn GPU.
  - Đo fps của bất kỳ app nào không cần root: `adb shell dumpsys SurfaceFlinger --latency '<tên layer>'` (tên lấy từ `--list`; mỗi lần trả khoảng 127 khung gần nhất).
- **Target cảnh R11F_G11F_B10F thay half float:** nhanh hơn 2,1 ms, nhưng 82% điểm ảnh lệch, tối đa 6/255. Trời thành từng bậc (thấy rõ khi tăng tương phản). Đây là đổi hình, không phải tối ưu giữ hình.

Quy đổi nhanh trên Galaxy A16 (Mali-G68 MP2) ở 3x: 1 chu kỳ malioc mỗi điểm ảnh trên cả màn (2 triệu điểm ảnh) tốn khoảng 1,1 ms. Bầu trời khoảng 7 chu kỳ trên nửa màn là khoảng 3,7 ms, khớp số đo. "Đường dài nhất" của malioc tính cả nhánh của map khác (sao, hành tinh: 29 chu kỳ). Muốn biết đường thật của một map thì gấp các nhánh đó thành `false` trước khi chạy malioc.

**Làm được mà hình giữ nguyên** (mỗi cái đã so từng điểm ảnh):
- Gấp shader theo map: phép thử trên uniform không đổi trong cả map (biome, biển, sỏi, tuyết...) thay bằng `true` / `false` trong `onBeforeCompile`, thêm khoá vào `customProgramCacheKey`. Compiler bỏ hẳn nhánh không dùng: mặt đất Map 1 từ 76 xuống 54 chu kỳ.
- Pass hậu kỳ cuối ở `mediump`, giữ `highp` cho toạ độ texture (màn hơn 1024 điểm ảnh), sampler HDR, đồng hồ (giây từ lúc mở game) và hash. Ra 8 bit nên ảnh như cũ: 14.1 xuống 11.9 chu kỳ.
- Lớp màu có trọng số 0 thì bỏ qua cả phép tính (`if (w > 0.0)`); hash nhiễu đọc từ texture tính sẵn thay vì `sin` mỗi điểm ảnh.
- Bớt draw call (thời gian JS của three và driver trên mỗi lệnh): cảnh vật chia đoạn dọc đường thành một lệnh mỗi loại bằng `app.InstanceWindow` (khung chạy Map 1 từ 104 xuống 76 lệnh, Map 6 từ 88 xuống 44); mesh tĩnh cùng vật liệu gộp bằng `app.mergeParts`; cờ nhiều màu thành một geometry trắng với màu theo instance (1 × màu ra đúng màu cũ); đèn nhấp nháy theo nhóm thành một mesh mỗi nhóm.
- Bóng của cảnh tĩnh nướng sẵn vào mặt đất một lần khi dựng map; chỉ xe đổ bóng thời gian thực.
- Không gửi lệnh vẽ rỗng: bộ hạt chưa có hạt nào thì ẩn (`visible = false`), không để three vẽ 0 hạt. Crash Ramp v99l: mỗi khung có 2 lớp hạt rỗng, cả lượt chơi 2174 lệnh vẽ rỗng, sau sửa còn 0.

**Ánh sáng theo đỉnh (hình lệch rất ít, chủ dự án đã chọn).** Tính ánh sáng mặt đất và cảnh vật ở đỉnh thay vì ở từng điểm ảnh: A10 nhanh hơn khoảng 24%, ảnh lệch tối đa 33/255 trên 0,6% điểm ảnh, nhìn bằng mắt không thấy. Crash Ramp v99h bật cho mọi máy. Lần thử đầu (v98i) chỉ chuyển một phần ánh sáng nên không nhanh hơn; phải chuyển cả phần tính đèn của vật liệu, chỉ giữ ở điểm ảnh những gì đổi theo điểm ảnh (texture, sương mù).

**Đã thử, không nên làm lại:**
- `mediump` cho mọi fragment shader: A10 không nhanh hơn chút nào.
- Varying 16 bit (mediump) cho màu, ánh sáng, trọng số 0..1 của mặt đất và cảnh vật: malioc báo đường ngắn nhất giảm 17-20%, nhưng trên A16 ở 3x chỉ đỡ 0,4 ms trên 21 ms (2%). Ảnh lệch tối đa 3/255 trên 2,6% điểm ảnh. Rẻ nên vẫn để, nhưng đừng mong thêm fps.
- Bớt một nửa cây cỏ: không nhanh hơn (cảnh vật chỉ khoảng 10% điểm ảnh).
- Chỉ chuyển một phần ánh sáng sang đỉnh: 12.0 khung/giây như cũ (chuyển hết thì được, xem trên).
- Đổi màu mặt đất sang công thức nhẹ hơn: A10 không nhanh hơn (chi phí mặt đất là số điểm ảnh, không phải phép tính màu). Đừng dùng API mới hơn Chrome 80 trong bản thử (`String.replaceAll` có từ 85 làm bản thử trên A10 không vẽ gì).
- Gộp hậu kỳ vào vật liệu: nước, đèn, quầng sáng trộn trong HDR tuyến tính, nên hình khác.
- Gộp mặt đất thành một buffer: phải đẩy khoảng 30 MB lên GPU lúc mở map, máy 2 GB khựng. Mặt đất giữ mỗi đoạn một lệnh.
- Hạ độ phân giải, tắt bóng, tắt bloom: đổi hình, chỉ làm khi chủ dự án chọn, và theo luật độ nét tự động bên dưới.

**Kiểm chứng mỗi thay đổi "không đổi hình":** vẽ cùng một khung hai cách trên cùng một trang (đồng hồ cố định, camera cố định, hạt và chim tắt), lệch tối đa 1/255 trên mọi map, ở menu và lúc chạy; đếm `drawElements*` / `drawArrays*`, số lần đổi vật liệu và `useProgram` của một khung trước và sau; rồi fps trên A10 trước và sau. Trong kit: `node tools/gpu-audit.mjs draws | diff | shaders <url>` làm ba việc đầu khi trang (bản dev) đặt `window.__gpuAudit = { renderer, scene, render, freeze, toggles }`.

### Giao diện thẳng hàng (Crash Ramp v102w-v103a, 11/11/2026)

Người chơi thấy ngay khi một nút lệch 2 px. Luật cho shop, Settings và mọi pop-up:
- Các ô cùng hàng có nút giá trên cùng một đường, lệch không quá 1 px: ô thiếu chip vẫn giữ chỗ cho chip.
- Không phần tử nào phình to để gây chú ý (gói nổi bật đổi màu viền, không đổi cỡ). Một cỡ chữ nút cho mỗi thẻ.
- Mọi pop-up cùng bề rộng với shop. Thẻ có ✕: header 76 px, ✕ cách mép trên và mép phải 16 px. Thẻ không có ✕: hộp thoại ở giữa.
- Pop-up gần bằng nhau thì dùng chung chiều cao, nhưng không để một khoảng trống lớn: chia phần dư đều giữa các khối (`margin-top: auto` cho từng khối), chữ giải thích sát khối của nó. Dư quá khoảng 100 px thì để pop-up cao theo nội dung.
- Đo bằng tool (Crash Ramp `tools/popalign.mjs`), không đo bằng mắt. Pop-up mới phải được thêm vào tool đó. Kiểm trên các cỡ màn phổ biến: 360×640/800/820, 384×832, 390×844, 393×852, 412×892/915, 430×932, 800×1280.

### Bớt việc CPU mỗi khung

Trên máy yếu, phần lớn thời gian JS mỗi khung là lệnh vẽ của three, không phải logic game. Galaxy A10 tốn khoảng 30 ms JS mỗi khung; profile CPU (máy tính, CPU chậm 6 lần cho giống A10) cho thấy render của three chiếm 26 ms, riêng đổi shader program 12 ms. Galaxy Tab A8 ở 1x: 16,8 ms JS, trong đó update của game 3,2 ms, 148 lệnh vẽ. Trước khi sửa, đếm `useProgram`, lệnh vẽ và lệnh GL của một khung (`tools/gpu-audit.mjs draws` ở trên).

Những việc giữ nguyên hình (Crash Ramp v99c, v99d, so từng điểm ảnh trên 6 map):
- Vật liệu trong suốt hai mặt (`side: DoubleSide`) bị three vẽ hai lần (mặt sau rồi mặt trước). Với vật liệu cộng sáng (`AdditiveBlending`), thứ tự không đổi kết quả: đặt `forceSinglePass = true`.
- Vật đổ bóng vẽ bằng instance: mỗi loại dùng chung một `customDepthMaterial` (`MeshDepthMaterial`). Không thì mỗi vật liệu có một program riêng trong pass bóng.
- Sắp vật đặc theo program trước, khoảng cách sau (`renderer.setOpaqueSort`). Vật trong suốt giữ thứ tự xa tới gần.
- Phần chỉnh màu không đổi trong cả map thì gấp vào shader hậu kỳ, như gấp shader mặt đất ở trên.
- Camera bóng chỉ bao những vật đổ bóng đang thấy, và dời theo đúng lưới texel của shadow map để bóng không rung.
- Gộp sẵn (bake) các vật nhỏ nhiều mảnh đứng yên: một mesh cho mỗi vật liệu + cách đổ bóng, mảnh gốc giữ ẩn nếu code cần vị trí của chúng (vòi phun, điểm bắn). Trên máy yếu mỗi lệnh vẽ tốn khoảng 0,1-0,2 ms CPU qua WebView/ANGLE. Crash Ramp v100u: bệ tên lửa từ 17 xuống 6 lệnh vẽ, hình như cũ (người thử báo lag trên OPPO A15).

Kết quả cộng lại của ba việc đầu (CPU chậm 6 lần, Map 1): `useProgram` giảm 26%, lệnh vẽ 4%, lệnh GL 5%; số lần tra program trong pass bóng từ 7,4 xuống 0,45 mỗi khung, pass bóng từ 1,41 xuống 1,01 ms.

Đừng bật tắt giữa lượt chơi những thứ làm đổi shader program (bóng, sương mù, loại vật liệu): A10 đứng khoảng 7 giây để dịch shader mới. Chọn lúc mở game, hoặc ở màn tải giữa hai lượt.

**Thêm một thứ vẽ mới mà không thêm shader program** (Crash Ramp v105w, vệt bánh xe): dùng đúng loại vật liệu của một thứ đã có trong map (ở đây là vạch YOUR BEST: `MeshBasicMaterial` trong suốt, không ghi độ sâu, không tone map), rồi so khoá program, không đoán. Khoá của three gồm cả hình học, không chỉ vật liệu: có hay không có attribute `normal` (`vertexNormals`), `color` 4 thành phần, `tangent`. Vệt bánh không có normal nên vẫn ra program thứ 52 trên Map 1 (51 trước đó); thêm một normal hướng lên kiểu `Int8Array` chuẩn hoá (3 byte mỗi đỉnh, gán một lần) thì dùng lại program của vạch: 51. Cách so: `renderer.properties.get(material).currentProgram.cacheKey` của hai vật liệu, tách theo dấu phẩy, xem ô nào khác; và `renderer.info.programs.length` trước / sau một lượt chơi.
- Dải mỏng vẽ dần trên mặt đất (vệt bánh, vệt trượt): mỗi điểm hai đỉnh, buffer cấp một lần, đưa lên GPU theo đoạn mới (`addUpdateRange`), `drawRange` theo số tam giác; ẩn mesh khi chưa có tam giác nào (three vẫn gọi lệnh vẽ với drawRange 0). Vật liệu chỉ vẽ mặt trước (`DoubleSide` là program khác) thì chọn thứ tự đỉnh cho từng đoạn theo dấu của tích có hướng, để mặt luôn hướng lên kể cả khi xe lùi: vệt Crash Ramp lúc đầu vẽ đủ lệnh mà không thấy gì vì mọi tam giác quay mặt xuống đất.

Giao diện DOM trên game: đừng để một lần vẽ lại màn bắt trình duyệt tính layout nhiều lần (Crash Ramp v102j; anh báo giật khi nhận xu ở popup quà quay lại trên Galaxy A16):
- **Co chữ cho vừa nút** (`@horus/i18n` `autoFit`):
  - Code cũ đo lại mọi nhãn có chữ vừa được ghi, kể cả khi ghi lại đúng chữ cũ. Nó đo từng nhãn một, và mỗi nhãn bắt tính layout cả trang hai lần.
  - Một lần vẽ lại menu (25-35 nhãn) tốn 40-55 ms layout bị ép trong một khung, trên Chrome của A16.
  - Thêm phần tử thẳng vào gốc UI (chữ "+80" bay lên, toast) cũng làm đo lại cả UI (50-60 nhãn).
  - Cách sửa: bỏ qua nhãn còn y như lúc co lần trước (chữ, class, hộp, phần tràn); các nhãn còn lại đo cùng nhau, đọc hết rồi mới ghi (`fitAll`). Cỡ chữ ra y như cũ: so 20 ngôn ngữ × Chữ lớn bật/tắt × 5 màn, 0 khác.
- **Dữ liệu tính nền về nhiều phần** (dự đoán của worker):
  - Vẽ lại màn một lần, khi phần cuối về.
  - Hỏi chúng ngay khi màn mở, đừng đợi lần vẽ lại đầu tiên. Crash Ramp chỉ hỏi lúc người chơi bấm nhận thưởng, nên 3 lần vẽ lại rơi đúng lúc xu đang bay.
- **Popup kế tiếp chờ hiệu ứng thưởng xong** (`CoinFly.busy`), đừng hẹn giờ cố định: 1,5 s không đủ trên máy chậm, popup quà ngày bật lên dưới mấy đồng xu cuối.
- PC, CPU chậm 4 lần, save của người chơi quay lại:
  - khung lúc xu bay lớn nhất 69-74 ms → 22-29 ms;
  - phần co chữ trong khung bấm nhận 20-75 ms → 5-7 ms;
  - 3 lần vẽ lại do dự đoán: hết.
- Cùng cách sửa ở luồng nâng cấp (sếp báo giật khi "ghép đồ"):
  - **Vị trí cần lúc chạm thì đọc ngay khi chạm**, trước khi ghi DOM. Chữ "+12 m" trên thẻ đọc vị trí thẻ sau lần vẽ lại, nên bắt tính layout cả màn: 12-16 ms.
  - **Thẻ chỉ ghi phần đổi.** Trước đó mỗi lần vẽ lại đều ghi lại `innerHTML` của nút giá, kể cả icon SVG.
  - **Trạng thái mới của vật liệu cần shader riêng**: mờ dần, trong suốt. Dịch sẵn lúc tải. Lần mờ đầu tiên của ná từng dịch shader giữa menu: 93 ms ở CPU / 4.
  - Kết quả: khung lớn nhất khi lắp phần xe 83-133 → 50-67 ms, ná 117-134 → 67-100 ms.

Luật cho mọi game có giao diện DOM (Crash Ramp v102j, anh duyệt 9/11):
- Không đọc layout (`offsetWidth`, `getBoundingClientRect`, `scrollWidth`, `getComputedStyle`) xen giữa các lần ghi DOM, nhất là trong vòng lặp: đọc hết rồi mới ghi.
- Co chữ chỉ đo nhãn đã đổi (`@horus/i18n` `autoFit` làm sẵn).
- Không dựng lại cả màn cho một con số. So rồi mới ghi: chữ, `innerHTML`, class, thuộc tính.
- Không bật popup khi một hiệu ứng còn chạy (xu bay, show nâng cấp). Chờ hiệu ứng xong, có trần thời gian.
- Animation lặp chỉ đổi `transform` / `opacity` (v102m). Glow, viền sáng, bóng: vẽ sẵn trên lớp riêng rồi đổi `opacity`. Không animate `box-shadow`, `filter`, `left` / `top` / `width`, `background`: cả lớp UI bị vẽ lại mỗi khung (mục "Tối ưu GPU máy yếu"). Gate có thêm luồng menu đứng yên: không có lần vẽ lại UI nào khi màn không đổi.
- **Gate khung hình trước khi đưa bản vào nhánh chính.** Mẫu là `tools/framegate.mjs` của Crash Ramp:
  - các luồng của người chơi quay lại, chạm thật;
  - Chrome, CPU chậm 4 lần, save do chính game tạo;
  - khung nào trên 34 ms thì trượt; khung đã biết thì ghi lý do và trần ms;
  - luồng trượt được chạy lại một lần, chỉ trượt khi trượt cả hai lần.
- **Trước mỗi lần upload store, chạy cùng các luồng trên điện thoại thật**, ít nhất một máy tầm trung và một máy yếu. Crash Ramp dùng Galaxy A16 và OPPO A15; chỉ dùng máy khi chủ máy đồng ý, không dùng lúc họ đang dùng.

### Độ nét tự động: bắt đầu nét nhất, chỉ hạ khi chậm thật

Người chơi chê hình mờ nhiều hơn chê chậm vừa phải. Luật của Crash Ramp (v99e đến v99n), áp dụng cho game mới:

- Mở game ở đúng độ nét của máy (pixel ratio của màn, tối đa 3x), có bloom. Không đoán trước theo RAM hay tên máy rồi hạ sẵn.
- Chỉ đếm thời gian đang chơi: menu, màn tải, quảng cáo, lúc trang ẩn không tính.
- Chỉ hạ khi 15 giây liền, mỗi giây đều 30 khung/giây trở xuống. Một lần khựng (dịch shader, nạp map, GC) không bao giờ đủ để hạ.
- Hạ từng bậc một, mỗi bậc đo lại ít nhất 5 cửa sổ 1 giây đang chơi và 120 khung. Bậc thấp hơn phải nhanh hơn thật (ít nhất 8%) mới giữ; không nhanh hơn là máy nghẽn ở CPU, quay lại bậc cũ và thôi hạ. Đang đo một bậc thì không hạ tiếp.
- Máy dưới 10 khung/giây thì đo xong sau 12 cửa sổ dù chưa đủ 120 khung, để máy chỉ chạy 2-3 khung/giây không mất vài phút mới xuống được bậc vừa sức (v99n).
- Hai lần chậm cách nhau quá 5 giây (hết lượt, về menu) là hai đoạn riêng, không cộng dồn; số đo gốc của một bậc chỉ lấy các cửa sổ từ sau khoảng nghỉ cuối (ít nhất 5). Cộng dồn thì cuối lượt trước nhẹ cộng đầu lượt sau nặng làm bậc thấp hơn trông như không nhanh hơn: Galaxy Tab A8 với v99u không giữ được 1x, với v99v giữ 1x tới cuối (trung vị 20 khung/giây).
- Bậc 1.5x là sàn của máy bình thường. Máy vẫn 30 khung/giây trở xuống ở 1.5x mới xuống tiếp 1.25x rồi 1x (máy cỡ Galaxy A10).
- Lên lại bậc nét hơn khi số đo cho thấy bậc đó vẫn giữ được khoảng 36 khung/giây.
- Trình duyệt tự giới hạn 30 khung/giây (iPhone tiết kiệm pin, trang nhúng): đó không phải máy chậm, giữ nguyên độ nét (`onCap` của `createApp`).
- Giới hạn 30 khung/giây do chính game đặt khi máy nóng (mục dưới) cũng không phải máy chậm: lúc bị giới hạn, chỉ cửa sổ dưới 27 khung/giây mới tính là chậm.

Kết quả thật: Galaxy Tab A8 trung bình 19 lên 21,4 khung/giây, khung thấp nhất 9 lên 15 (v99l, sau khi bỏ lệnh vẽ rỗng và đo bậc lâu hơn để không nhảy qua lại). Galaxy A16 (Mali-G68) ở 2x có bloom khoảng 41 khung/giây, ở 3x khoảng 21: máy tầm trung 2024 không cần hạ dưới 2x.

### Máy nóng khi chơi lâu

Governor giữ GPU chạy 100% để có nhiều khung nhất, nên chơi lâu thì máy nóng. Galaxy A16 ở 1.5x: chip từ 32 lên 47,6 °C trong 3,5 phút mà Android vẫn báo trạng thái nhiệt `'none'`. Chỉ có ít khung hơn hoặc ít điểm ảnh hơn mới làm máy mát; tối ưu shader làm mỗi khung rẻ hơn nhưng governor lại dùng phần dư để vẽ nét hơn.

Số đo Crash Ramp v99x/v99z trên Galaxy A16 (2/11/2026; Chrome 156 qua `adb reverse`, game tự chơi 10 phút mỗi bài, bắt đầu khi chip 35 °C, máy đang sạc qua cáp):

| Bài | fps khi chạy (thấp nhất) | Mặt máy cao nhất | Android báo |
|---|---|---|---|
| 3x | 30,6 (21) | 40,1 °C | `'light'` ở phút thứ 10 |
| 3x khoá 30 | 23,6 (18) | 39,2 °C | `'none'` |
| 2x | 48,8 (31) | 38,4 °C | `'none'` |
| 2x khoá 30 | 28,7 (22) | 39,3 °C | `'none'` |

Chip lên 47-48 °C ở cả bốn bài. Vẽ ít điểm ảnh hơn vừa mượt hơn vừa mát hơn. Khoá khung trong một trang Chrome gần như không làm mát, vì Chrome vẫn ghép màn hình ở 90 Hz. Đo hiệu quả của khoá khung trong app, nơi `platform.device.setFrameRate` hạ được tần số màn hình, không đo trong trình duyệt.

Luật (Crash Ramp v99j, chủ dự án chọn "khoá 30 khung/giây, giữ nét"; ngưỡng sửa ở v107j, 25/11/2026):
- `platform.device.thermal.status` từ `'light'` trở lên, hoặc `headroom` từ 0,83 trở lên: giới hạn lúc chơi ở 30 khung/giây, giữ nguyên độ nét và hiệu ứng.
- Mở lại khi máy mát liền 20 giây (`'none'` và `headroom` dưới 0,75, hoặc không biết headroom).
- Đừng đặt ngưỡng dưới mức `'light'` của chính máy. `headroom` là dự báo 10 giây, 1,0 = `'severe'`. Galaxy A16 (`dumpsys thermalservice`, dòng "Temperature headroom thresholds") có `'light'` ở 0,833. Bản store 25/11: headroom 0,61 ngay lúc mở game (da 33 °C), 0,77 sau 5 phút chơi (da 38 °C), trạng thái vẫn `'none'`. Ngưỡng cũ 0,6 vì vậy khoá 30 từ giây đầu trên máy còn mát; mở khoá cần dưới 0,5 nên không bao giờ mở khi đang chơi. Firebase: fps của `run_end` dồn đúng 30 ở 4.104 lượt, A16 gần như lượt nào cũng 30.
- Gửi lý do khoá kèm sự kiện fps (Crash Ramp `run_end` `cap` = `<lý do>.<headroom×100>.<game mode>`), nếu không thì số liệu không tách được "máy bị khoá 30" với "máy chỉ chạy được 30".
- Chỉ ở `'severe'` trở lên mới bỏ bớt hiệu ứng.
- Từ @horus/webgame 0.51.0 iOS cũng báo nhiệt (`ProcessInfo.thermalState`: fair, serious, critical thành `'light'`, `'moderate'`, `'severe'`; headroom luôn -1), nên cùng một đoạn code chạy cả hai nền tảng.

```js
let hot = false, coolSince = 0;
function onThermal() {
  const t = platform.device.thermal, now = performance.now();
  const warm = ['light', 'moderate', 'severe', 'critical', 'emergency', 'shutdown'].includes(t.status) || t.headroom >= 0.83;
  const cool = t.status === 'none' && t.headroom < 0.75;   // headroom -1 (không biết) cũng là mát
  if (warm) { hot = true; coolSince = 0; }
  else if (hot && cool) { if (!coolSince) coolSince = now; if (now - coolSince > 20000) hot = false; }
  game.setFpsCap(hot ? 30 : 60);                          // chỉ giới hạn lúc chơi; menu đã nhẹ
  game.setEffects(['severe', 'critical', 'emergency', 'shutdown'].includes(t.status) ? 'low' : 'full');
}
platform.on('thermal', onThermal);
setInterval(onThermal, 5000);                             // để đếm 20 giây mát khi không có sự kiện mới
```

**Popup che cảnh đứng yên: đừng vẽ lại cảnh 3D** (Crash Ramp v106b, 20/11/2026). Shop, Settings, offer, quà ngày mở trên menu (hay màn ná, màn kết quả) mà cảnh phía sau không chuyển động: bỏ qua cả update lẫn render của khung đó. Canvas WebGL không bị xoá khi không vẽ (`preserveDrawingBuffer` false chỉ xoá sau một lần vẽ), nên nền tối mờ của popup vẫn nằm trên khung cuối. Luật: vẽ 2 khung đầu khi popup vừa mở (khung phía sau là khung mới); vẽ ngay khi bộ đệm đổi cỡ dưới popup (đổi chất lượng trong Settings) để không nháy đen; không bỏ khi camera đang bay hay vật đang diễn (xe nhấc, tiến hoá); việc nền (dự đoán, tải dần) vẫn chạy; cửa sổ fps của governor bắt đầu lại sau đó để các khung không vẽ không bị tính là chậm. Bản web 390x844 (Edge): menu 30 lần vẽ mỗi giây, Shop mở 0 (trước 30), đóng Shop lại 30; ảnh Shop giống hệt.

Vì sao game Unity cùng loại thường mát hơn: Unity mặc định 30 khung/giây, độ phân giải thấp hơn 3x, thường không có HDR, bloom hay chỉnh màu, và vẽ thẳng bằng Metal/Vulkan. Game web vẽ WebGL qua lớp dịch sang Metal và WebView còn chép khung thêm một lần. Muốn mát như vậy thì giới hạn khung khi máy ấm, không phải hạ hình từ đầu.

### Mở game nhanh

- **Thời gian mở app theo Google Play (Android vitals).** Ngưỡng "chậm": cold start từ 5 giây, warm từ 2 giây, hot từ 1,5 giây, đo tới khung hình đầu của activity (TTID). Từ webgame 0.84.0 app vẽ ngay một bản sao splash và tạo WebView sau khung đầu (Crash Ramp: cold 834 → 336 ms trên Galaxy A16), và gọi `reportFullyDrawn` ở `platform.ready()` / `Horus.ready()`. Game không phải làm gì, nhưng `ready()` phải đúng lúc màn đầu đã vẽ. Đo: `adb shell am start -W <package>/<activity>` (dòng `TotalTime`, lấy trung vị nhiều lần); warm start: bật "Don't keep activities" trong Developer options, về Home rồi mở lại.
- **Không dịch shader giữa ván.** Đếm số shader program mới được dịch trong lúc chơi mỗi map (three.js: `renderer.info.programs.length` trước và sau ván): phải là 0. Crash Ramp gặp một program dịch giữa ván ở map sau (một bức tường trong suốt hai mặt chưa dựng sẵn), và một gói làm nóng chứa 15 program không còn dùng. Số program tự nó không làm chậm fps (GPU tốn theo pixel); gộp thành uber-shader lại làm chậm. Có test hỏng khi gói làm nóng cũ so với code.
- Đo từng bước của lần mở đầu trên người chơi thật trước khi sửa (sự kiện `boot`, bước 16). Crash Ramp v98a, 5 lần mở đầu thật 14-24 giây: dịch shader trước 4,9-9,9 giây, dựng map 2,5-5,5 giây, vẽ ảnh nhỏ của shop 1,7-3,2 giây.
- Chỉ dịch trước shader menu cần (Crash Ramp 36 trên 72 program), phần còn lại dịch nền sau khi menu hiện; dựng đoạn đường gần điểm xuất phát trước; ảnh nhỏ của shop làm sẵn lúc build (giống từng điểm ảnh) thay vì vẽ lúc mở game; thông tin app, cloud save, ngôn ngữ chạy song song; quảng cáo bắt đầu tải sau khung đầu của menu. Việc nền nhường khoảng 700 ms sau mỗi lần chạm để menu không khựng. Crash Ramp v98b, máy tính CPU chậm 4 lần: tới menu từ 4,76 xuống 3,47 giây.
- Máy không có `KHR_parallel_shader_compile` cũng hiện menu trước, rồi mới dịch phần còn lại (v98d): A10 tới menu từ 36 xuống 23 giây sau khi mở app.
- Mỗi tổ hợp vật liệu khác nhau là một shader program phải dịch trên máy ở lần mở đầu (Unity dịch sẵn lúc build). Gộp các vật liệu chỉ khác nhau ở tham số thành một program (kiểu thành uniform, khoá `customProgramCacheKey` chung): Crash Ramp v98x từ 37 xuống 32 program ở menu, hình như cũ. Đừng gộp những vật liệu thật sự khác nhau thành shader nhiều nhánh: rẻ lúc mở nhưng đắt mỗi khung trên máy yếu.
- Bắt đầu việc GPU sớm: tạo renderer, nướng texture nhiễu, dựng trời và môi trường của map đoán trước ngay sau khi gọi `platform.init`, song song lúc chờ save và Remote Config (Crash Ramp v98w). Đọc kết quả GPU (`readRenderTargetPixels`) bằng PBO và fence, không đọc chặn.
- Máy không có `KHR_parallel_shader_compile` (A10, máy ảo Test Lab) thì khung đầu phải trả hết các shader đã gửi; chỉ có cách gửi sớm để chồng lên thời gian chạy JS.
- Máy không có `KHR_parallel_shader_compile` thì không bao giờ để một khung dịch hết shader: Crash Ramp v101c, lần mở đầu (driver chưa có cache) trên máy 2 GB mất 8,3 giây ở khung đầu của menu và 9,4 giây ở cổng vào lượt đầu, màn tải đứng hình, máy PowerVR báo ANR trong `PVRUniFlexCompileToHw`. Việc GPU của WebView chạy trong tiến trình của app, nên một mẻ dịch vài giây chặn luôn khung hình của app. Cách làm: mỗi khung dịch một program, vẽ ấm một vật cho mỗi program mới vào một target 1x1 giống của cảnh, giữa hai lần có một khung trống, vừa làm vừa "cho ăn" watchdog của màn tải. Ghi số đo mỗi lần mở (thời gian khung `boot_bg`, cổng vào lượt, số program đã dịch).
- Món người chơi sẽ mua sau mà mang kiểu vật liệu mới (Crash Ramp: mảnh ná các cấp sau) thì dựng sẵn vật liệu của nó (cả bản đặc lẫn bản mờ) trong việc nền và giữ lại, đừng để mỗi lần dựng lại vật mới dịch program lúc vật cũ mờ đi: vật cũ bị huỷ thì program của nó cũng mất. Crash Ramp v102u, Firebase Test Lab 10/11, thêm mảnh ná: khung dài nhất Galaxy A03s (PowerVR) 499 → 283 ms, Galaxy A10 (Mali, WebView 81) 667 → 300 ms, không còn dịch shader trong luồng đó.
- Gói shader làm nóng lúc mở game (đọc từ file, dịch trước khi game cần) gần như không kịp chạy trên điện thoại thật: Crash Ramp v102u cho nó chạy tới lúc game tự dịch menu, nhưng trên A03s và A10 nó chỉ dịch được 0 và 1 program (trên PC 27-30), vì gói đọc xong khi game đã bắt đầu dịch. Muốn có tác dụng thì phải đọc gói ngay từ khung đầu, trước mọi việc khác trên GPU. Đo trên máy thật trước khi tin số của PC.
- Không dựng một map trong một việc đồng bộ dài: Crash Ramp v102v trên Galaxy A16 lần mở đầu dựng cả map (đường, cảnh, đất gần, nướng bóng, xe) trong một việc 1,1-2,4 giây, Android không thấy khung nào suốt lúc đó (nguy cơ ANR, "GPU không phản hồi") và thanh tải đứng. Cứ khoảng 50 ms việc thì nhường một khung (một `slicer(budget)` chờ `requestAnimationFrame` khi hết ngân sách; hàm dựng viết kiểu generator, `yield` giữa các phần). Cùng việc, cùng thứ tự, cùng kết quả; khung tải dài nhất còn 0,6-1,0 giây (lúc trang chạy script).
- Không có `KHR_parallel_shader_compile` (mọi WebView Android trong dữ liệu của mình) thì `compileAsync` của three.js chỉ xếp hàng các program; lần vẽ đầu chờ link tất cả cùng lúc. Dịch mỗi khung một program và chạm vào nó (`currentProgram.getUniforms()`) ở khung sau.
- Tìm những khung dài như vậy bằng trace Chrome qua USB (CDP Tracing có `disabled-by-default-v8.cpu_profiler`), không đoán: ở Crash Ramp luồng GPU chỉ bận khoảng 0,1 giây trong khung 1,5 giây.
- Thời gian mở game dao động theo độ bận của máy (5-7 giây giữa hai lần trên cùng máy): so hai bản cùng ngày, cùng máy, chạy xen kẽ, lấy trung vị nhiều lần. Bench mở game trên trang có thẻ viewport (trang không có viewport bị bố cục 980 px, chậm gấp 4).

### Đo cho đúng

- Một lần đo fps trên máy thật Test Lab tốn khoảng 10 phút quota, một lần đo mở game khoảng 3 phút; quota miễn phí 30 phút mỗi ngày nên lên kế hoạch từng lần chạy.
- Máy ảo Test Lab và Chrome headless (SwiftShader) không dùng để kết luận fps: chỉ dùng để kiểm game chạy hết lượt không lỗi. Kết luận fps bằng máy thật (A10 trong Test Lab, điện thoại cắm USB qua `adb reverse` với bench).
- So trong cùng một lần chạy (tỉ lệ giữa các biến thể), không so số tuyệt đối giữa hai ngày: nhiệt độ máy khác nhau.
- Bench chỉ đo lúc xe đang chạy và mỗi bậc ít nhất 45 khung; số đo lúc đứng yên ở menu làm bậc nào cũng trông nhanh.
- Mỗi bước của một lần đo chạy trên một đoạn đường khác: so hai cấu hình thì xen kẽ nhiều vòng (A, B, A, B... 8 vòng), không chạy A rồi B một lần.
- Thay đổi chỉ vài % thì đo trên đường chạy không thấy: trên A16, cùng một A/B ra +6% rồi -2% khi đảo thứ tự. Đo GPU trên một khung đứng yên:
  - mỗi lượt vẽ cùng một khung, trước hết 6 khung làm nóng, rồi 12 khung liền nhau với một `readPixels` 1 điểm ảnh ở cuối (không chờ GPU sau từng khung);
  - bản đồ bóng vẽ lại mỗi khung như lúc xe chạy;
  - thứ tự các lượt xoay vòng mỗi vòng, 16 vòng;
  - thêm một lượt giống hệt lượt gốc (A/A) để biết sai số: A16 ra khoảng 1%.
- Đừng đặt lượt nhẹ (vẽ rỗng) ngay trước lượt cần đo. GPU Mali hạ xung khi rảnh, nên lượt ngay sau đo chậm hơn khoảng 30%.
- Bench phải vẽ đúng như game. Crash Ramp từng gặp ba lỗi:
  - lượt GPU chiếu sáng mặt đất theo điểm ảnh trong khi game đã chiếu theo đỉnh, nên "mặt đất gần nửa khung" là sai (thật khoảng 20%);
  - canvas không có depth nên lượt "vẽ thẳng ra màn" rẻ hơn thật;
  - trang đo chiếm luồng chính nên phần cảnh dựng nền (cây xa) không bao giờ xong.
  Mỗi lượt, kiểm số lệnh vẽ và số tam giác giống lượt gốc.
- Trước khi tin số đo của các bậc độ nét, xem fps của cảnh đứng yên có giữ được 5 phút không. Ashlar tụt 20-40% sau 5 phút đứng yên ở cả bản cũ lẫn bản mới, nên bậc đo sau trông chậm hơn chỉ vì cảnh chậm dần.
- Máy đo phải yên: trong 60 giây trước và trong lúc đo, không build, không Gradle, không chương trình nào khác dùng quá 25% một lõi. Có thì bỏ lần đo đó.
- **Samsung Game Booster (GOS) hạ trần xung CPU của app game khi tải nhẹ.**
  - Galaxy A16, menu 30 fps: lõi lớn bị khoá ở 864 MHz (tối đa 2,4 GHz). Đọc bằng `adb shell cat /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq`; logcat có `SemDvfsHyPerManager ... CPUMaxFreq / 533000`.
  - Một việc đột ngột sau lúc để yên (bấm nhận thưởng) chạy chậm 2-3 lần so với Chrome trên cùng máy. GOS cần khoảng 2 s mới nâng trần.
  - Chrome không bị GOS khoá, nên số đo trên Chrome là cận dưới. Giữ việc của mỗi khung trong lúc đó thật nhỏ.
- **Đo khung kẹt trên Chrome của điện thoại không cần DevTools:**
  - Trang thử chèn script đo vào `<head>`: `PerformanceObserver` loại `long-animation-frame` (Chrome 123+). Mỗi khung dài cho biết các script (`invoker`, `sourceCharPosition`, `duration`, `forcedStyleAndLayoutDuration`).
  - Build bản không minify (`--dev`) để `sourceCharPosition` chỉ đúng hàm.
  - Gửi kết quả về PC bằng POST qua `adb reverse`; bấm bằng `adb shell input tap`.
- **Đo tình huống của người chơi bằng save thật do chính game tạo** (đã qua hướng dẫn, nhiều lượt chơi, popup tự hiện), không chỉ trang `?nosave`. Trang nosave của Crash Ramp không cho thấy 3 lần vẽ lại của dự đoán, cũng không cho thấy popup quà ngày bật ngay sau.
- Thêm vật liệu làm đổi chuỗi `Math.random` (three dùng nó tạo uuid), nên hạt và mảnh vỡ ra khác giữa hai bản: tắt chúng khi so ảnh.
- Test Lab luôn báo renderer crash lúc dọn máy sau khi bài test đã xong: bỏ qua dòng đó.
- Đo nóng máy trên điện thoại cắm USB: mỗi 30 giây đọc `adb shell dumpsys thermalservice` (Thermal Status và nhiệt độ AP, SKIN, BAT). Trước mỗi bài chờ chip về dưới 35 °C. Mỗi bài ít nhất 10 phút, giữ cùng độ sáng và cùng tình trạng sạc. Mặt máy (SKIN) là con số người chơi cảm thấy.
- Chrome headless trên Windows bị hạ xung sau khoảng một phút. Trình duyệt chạy không cửa sổ (Playwright, Puppeteer headless) bị Windows coi là việc nền: sau 60-90 giây, power throttling (EcoQoS) cho nó chạy ở xung gốc thay vì boost, nên cùng một khung tốn khoảng 1,8 lần và số fps hay thời gian tải đo sau đó thấp hơn thật.
  - Ashlar, 2/11/2026 (i5-13400F, Windows 10, boost 4,6 GHz, gốc 2,5 GHz): một vòng JS cố định trong trang từ 51 lên 95 ms giữa giây 60 và 90; cùng vòng đó trong node thường thì phẳng; ghim trình duyệt vào lõi P không đỡ.
  - Dấu hiệu: trong CPU profile mọi hàm chậm gần cùng một tỉ lệ, còn heap, số lệnh vẽ, số tam giác và số vật thể phẳng.
- Edge 157 trên Windows (máy build Horus, 10/11/2026): Puppeteer tự mở Edge thì Edge thoát ngay ("Failed to launch the browser process: Code: 0"), cả headless lẫn có cửa sổ; Edge headless chỉ chạy khi có `--no-sandbox`. Cách chạy tool: tự mở Edge (`--headless=new --no-sandbox --remote-debugging-port=<cổng>`, profile riêng) rồi `puppeteer.connect`. Crash Ramp có preload `tools/edge-nosandbox.mjs` (`node --import ./tools/edge-nosandbox.mjs tools/<tool>.mjs`) để tool cũ không phải sửa.
  - Cách sửa: công cụ test mở trình duyệt thì tự tắt power throttling cho cây tiến trình của nó (`SetProcessInformation` `ProcessPowerThrottling`, tốc độ không bị hạ) và đặt lại mỗi 10 giây khi trình duyệt còn chạy. Không đổi gì toàn máy (power plan, `powercfg`, registry). Ví dụ: Ashlar `tools/qa/browser.mjs` `launch()` với `tools/qa/quiet/nopowerthrottle.ps1`; `launch({ boost: false })` giữ cách cũ của Windows.
  - Sau khi sửa: 300 giây ở 1x phẳng (bench 50-56 ms, script 2,0-2,1 ms mỗi khung); CPU chậm 16 lần 13,1 fps 30 giây đầu, 16,6 fps 60 giây cuối, script 42-47 ms phẳng.
  - Người chơi không bị: tab đang hiện ở trước không bị hạ xung kiểu này. Điện thoại chậm đi vì nóng, phần đó đã có luật nóng máy của Crash Ramp.
  - A/B chạy xen kẽ trên cùng máy với cùng độ dài vẫn so được với nhau; số tuyệt đối đo sau khoảng 60 giây trước khi sửa thì thấp hơn thật.

### Game online: tải và mạng yếu (Ashlar)

- Màn tiêu đề hiện ngay từ ảnh chụp sẵn, rồi mới tải 3D. Trong lúc người chơi đứng ở màn tiêu đề, tải trước file của vùng sẽ vào (quái, NPC, texture vùng, wasm dự đoán), sau file của chính màn tiêu đề, trước các mô hình vào sau.
- Đo thời gian tải bằng nhiều hồ sơ mạng (nhanh với CPU chậm 4 lần, mạng khoảng 300 KiB/s), lần đầu và lần sau, ít nhất 3 lần mỗi bản, lấy trung vị: một lần đo lần đầu dao động khoảng 15 giây.
- Art để trên CDN khác server game, có thử lại 4 lần và quay về server game khi CDN lỗi.
- Mạng yếu: đừng bỏ socket im lặng quá sớm (Ashlar từng bỏ sau 3 giây, người chơi Việt Nam vào server Los Angeles RTT khoảng 180 ms rớt liên tục). Bỏ sau khoảng 12 lần RTT, thử lại nhiều phút khi trang đang hiện, vào lại đúng chỗ từ save, trang ẩn thì không nối lại. Chi tiết trong `@horus/netplay`.
- Độ nét của game online theo cùng luật độ nét tự động ở trên.
- Vật thể rời tầm nhìn rồi quay lại phải được gắn lại hình (Ashlar, 3/11/2026). Với tầm nhìn theo bán kính (interest management), vật thể ra khỏi bán kính bị client bỏ và quay lại là một object MỚI với CÙNG id. Bảng hình vẽ theo id mà vẫn gắn hình cũ vào object cũ thì để lại một bóng ma đứng yên ở chỗ cũ, còn con quái thật thì vô hình: người chơi bị đánh bởi con quái không thấy.
  - Sửa: khi object đằng sau một id đổi, dựng lại hoặc gắn lại hình của nó (và chuyển aura, đèn, các rig khác theo id đó); bắt đầu mờ dần từ lúc vật thể rời đi (một mốc `leftAt`); xác vẫn là xác.
  - Đừng dùng mốc giả theo thời gian như `time - 40`: nó âm trong những giây đầu sau khi tải trang hay vào vùng, nên mờ dần không bao giờ bắt đầu. Ashlar bị nặng nhất trong 40 giây đầu sau mỗi lần vào vùng.
  - Kiểm: đi tới khi một đàn quái ra khỏi tầm nhìn, đi lại, đếm số đòn từ hình cũ hoặc vô hình (Ashlar: 104/189 trước, 0/181 sau); cả sau khi kết nối lại lúc có quái gần (10/11 hình cũ trước, 0/11 sau).
- Đòn đánh của chính mình phải thấy nhanh khi chơi online (Ashlar, 3/11/2026; Việt Nam vào server Los Angeles, RTT khoảng 185 ms). Online chậm hơn offline khoảng 370 ms: RTT 186 + đồng hồ vẽ trễ khoảng 100 + server chờ input 51-96 + vòng gửi 25 Hz khoảng 25. Đo từng phần trước khi sửa; bộ đếm "view lag" làm cho lag compensation (RTT + vẽ trễ + chờ + hộp thư) không phải độ trễ vẽ, đừng đọc nó như vậy.
  - Những cách bớt mà luật chơi giữ nguyên (đo trên đường giả 85/85 ms, rung ±6 ms): đọc socket mỗi khung, không theo nhịp gửi; đòn của chính nhân vật mình chơi lúc đọc snapshot, không theo đồng hồ vẽ trễ (các vật khác vẫn theo); vẽ đạn của mình ngay khung bắn rồi giao cho sự kiện sinh đạn của server (thấy đạn 712 xuống 340 ms); mục tiêu ngoài tầm thì đoán trước việc đi tới (đi ngay, vung khi tới tầm: 529 xuống 145 ms); server giữ dự phòng input 0-1 tick thay vì đệm cố định (bớt 15-20 ms chờ; kiểm không mất input trên đường xấu: Ashlar 0 mất ở rung ±28 ms, 60 giây giữ đánh và bấm liên tục); đừng lấy RTT ban đầu từ một pong trang giữ lại lúc đang tải.
  - Đòn cận chiến thấy trúng từ 627 xuống khoảng 500 ms. Phần còn lại chủ yếu là một vòng mạng; chỉ dời server hoặc đổi luật mới bớt được.
  - Đếm số lần vung đoán trước bị server từ chối. Phần lớn là bấm vào quái server đã giết. Với dự phòng input nhỏ, một cú bấm có thể rơi đúng tick cú vung trước kết thúc và server bắt đầu muộn một tick: cho trang một tick châm chước trước khi coi là bị từ chối, nếu không cú vung mờ đi rồi chơi lại muộn.
  - Đo trên Windows thì tắt power throttling cho trình duyệt headless (xem "Đo cho đúng").

### Nhẹ khi quảng cáo che game

Quảng cáo toàn màn hình là màn native đè lên WebView, nên trong lúc đó game không cần bộ đệm vẽ. Ngay trước `platform.ads.rewarded` / `platform.ads.inter`, nhả những gì dựng lại được; khi quảng cáo đóng (xong, lỗi, hay quá 2 phút mà vẫn chưa về) thì trả **đúng** pixel ratio và kích thước cũ, không thấp hơn, rồi vẽ ngay một khung. Cảnh, geometry, texture và bóng đã nướng giữ nguyên, không phải tải lại.

```js
// src/adlight.js
import * as THREE from 'three';
let light = null;
export function adLightOn(shell, game) {
  if (light) return;
  const r = shell.renderer, size = r.getSize(new THREE.Vector2());
  light = { pr: r.getPixelRatio(), w: size.x, h: size.y };
  game.disposePostTargets();                          // render target hậu kỳ (bloom...): tự dựng lại lần vẽ sau
  const sh = game.sun.shadow; if (sh.map) { sh.map.dispose(); sh.map = null; }   // shadow map thời gian thực, cũng vậy
  r.renderLists.dispose();
  game.audio.releaseMusic();                          // nhạc đã giải mã: phần lớn bộ nhớ nhả được trên máy yếu (nhả thật: xem dưới)
  r.setPixelRatio(1); r.setSize(1, 1, false);         // false: giữ kích thước CSS, chỉ bỏ bộ đệm vẽ
}
export function adLightOff(shell, game) {
  if (!light) return;
  const r = shell.renderer;
  r.setPixelRatio(light.pr); r.setSize(light.w, light.h, false);   // đúng như trước quảng cáo
  light = null;
  game.audio.restoreMusic();
  game.drawNow();                                     // một khung ngay, trước khi game hiện lại
}
```

Từ webgame 0.68.0 (Android 8+), gọi `platform.device.keepFrame()` **trước** `adLightOn` và chờ nó (tối đa ~250 ms, rồi chiếu quảng cáo dù sao): app giữ khung hình đang hiện (canvas WebGL và HTML trên nó) để che trang mở lại nếu renderer chết dưới quảng cáo (mục dưới). Gọi sau khi đã nhẹ thì ảnh là bộ đệm vẽ 1x1. Bản chép mất khoảng một khung; JPEG làm ngoài luồng chính.

Màn hình xoay trong lúc quảng cáo thì cho qua hàm resize của game với pixel ratio cũ. Crash Ramp v97g đo trên máy ảo Android: renderer WebView từ 236 MB xuống 145 MB trong lúc quảng cáo, sau đó về đúng 771×1371 ở pixel ratio 1.25, khung đầu sau 18 ms. Trên điện thoại thật còn nhả thêm bộ nhớ GPU của canvas, render target và shadow map.

Máy RAM 4 GB trở xuống còn nhả thêm bản GPU của hình khối và texture đã nạp của cảnh (`geometry.dispose()`, `texture.dispose()` trên đồ trong cảnh, không đụng texture của render target): three tự gửi lại ở lần vẽ sau, hình y hệt từng pixel. Phần này nhỏ (khoảng 12 MB một map của Crash Ramp v101c) nhưng cộng thêm với bộ đệm vẽ 1x1 và render target hậu kỳ đã nhả.

**Nhạc phải được nhả thật** (Crash Ramp v102f, 9/11/2026). Trang của quảng cáo chạy chung tiến trình renderer với game, vì mọi WebView của một app dùng một renderer. Android tắt tiến trình nặng nhất ở mức foreground, và đó là renderer: Crash Ramp 0.1.2 có 112 lần `renderer_gone` dưới quảng cáo, lần nào cũng do hệ thống tắt, không lần nào là crash.

Lỗi nằm ở `source.stop()`. Quảng cáo che trang thì trang thành hidden và game suspend AudioContext. Một `stop()` trên context đã suspend không bao giờ chạy tới cuối, nên AudioBuffer của nhạc (khoảng 24 MB PCM) bị giữ suốt quảng cáo, và cả lúc app ở nền.

Nhả đúng cách:

```js
src.stop(); src.disconnect(); src.buffer = null;   // rồi bỏ mọi tham chiếu tới source và buffer
```

Số đo trên LDPlayer (4 GB, WebView 138), Crash Ramp debug, đọc dump memory-infra của Chromium (ArrayBuffer còn sống):

| Cách nhả | Context đang chạy | Context đã suspend |
| --- | --- | --- |
| Chỉ `stop()` | 51,3 → 26,9 MB | 51,6 → 51,6 MB (không nhả gì) |
| `stop()` + `disconnect()` + `buffer = null` | | 51,6 → 27,2 MB |

Âm lặp chỉ nghe lúc chơi (gió, mặt đường, tên lửa; khoảng 5,5 MB) cũng nhả, rồi giải mã lại sau quảng cáo. Giữ tiếng một lần (xu, nút) để tiếng thưởng kêu ngay khi quảng cáo đóng. Giải mã lại bài nhạc 0,8 MB mp3 mất 0,9-1,1 s trên LDPlayer, không chặn khung.

Cách đo trên máy: bản debug, chrome://inspect qua `adb forward`, rồi `Tracing.requestMemoryDump` với category `disabled-by-default-memory-infra`. Đọc các allocator của tiến trình Renderer:
- `partition_alloc/partitions/array_buffer` → `allocated_objects_size`: ArrayBuffer còn sống; PCM của AudioBuffer nằm ở đây.
- `v8`, `cc`, `gpu`, `canvas`.

`dumpsys meminfo` chỉ thấy phần lớn renderer là "Unknown" nên không đủ.

Quảng cáo test của MAX cũng là một WebView trong app. Trên LDPlayer lúc nó hiện, renderer thêm khoảng 40 MB (`cc`, `media`).

Trang của quảng cáo (video, playable, end card) chạy **chung một tiến trình renderer** với game: mọi WebView của app dùng một renderer. Android tắt tiến trình nặng nhất khi máy hết RAM, nên dưới quảng cáo renderer là tổng của game và quảng cáo. Crash Ramp v102o đo trên LDPlayer (4 GB, bản debug, Chromium memory-infra): renderer ~157-167 MB ở menu, quảng cáo test của MAX tự cộng thêm ~20-100 MB. Nhưng đọc `process_state` của Crashlytics trước: ở Crash Ramp 0.1.2, 116/120 lần renderer "chết dưới quảng cáo" là lúc app đã ở nền (người chơi bấm Home hay bấm quảng cáo sang store giữa chừng), chỉ 4 lần trong 2 tuần là lúc người chơi đang xem; người bị tắt quay lại chơi như người không bị. Phần ở nền là Android lấy RAM của app nền: không chặn được, chỉ cần quay lại êm. Sau nhạc (v102f), bộ đệm vẽ, render target, shadow map và bản GPU của cảnh (nhả trên **mọi** máy: máy 8 GB cũng bị tắt dưới quảng cáo; nạp lại ở khung đầu sau quảng cáo, LDPlayer ~93 ms), phần của game còn lại đã gần tối thiểu: tiếng một lần không phát ngay sau quảng cáo (~3 MB, giữ tiếng thưởng) là phần nhỏ cuối cùng đáng nhả. Đừng ẩn canvas hay lớp UI DOM dưới quảng cáo: khi app bị che, Chromium tự bỏ tile của compositor, PSS như nhau, còn khôi phục chậm thêm ~70 ms. Dữ liệu lớn hơn (thư viện mô hình, hình khối địa hình) phải dựng lại sau quảng cáo nên giữ. Phần còn lại là việc của quảng cáo: ghi một sự kiện khi trang chết dưới quảng cáo (Crash Ramp `ad_page_lost`: chỗ đặt, loại, mạng, `navigator.deviceMemory`) và đọc `renderer_gone` theo `net` / `ram`, rồi chỉnh tần suất interstitial hay mạng cho máy RAM thấp.

**Quay lại êm sau khi renderer chết (webgame 0.68.0).** Renderer chết lúc app khuất (dưới quảng cáo, hay người chơi ra ngoài) thì trang mới chỉ dựng khi người chơi quay lại, và app che nó bằng khung hình cuối người chơi thấy (lớp tối nhẹ + vòng quay trắng) cho tới `app.ready` + 300 ms, tối đa 20 s; ảnh che được vẽ trước khi tạo WebView mới (tạo WebView có thể giữ luồng chính vài giây), và WebView mới chỉ tạo khi quảng cáo toàn màn hình của trang cũ đã trả lời (tối đa 2,5 s): Galaxy A16, `onAdHidden` (thưởng) tới 0,6 s sau khi game trở lại, trang mới đã đọc `ads.lost` trước đó nên thưởng mất 1/2 lần; chờ thì trả 3/3. Lúc mở lại, gửi % của màn tải bằng `platform.device.loading(pct)` (thanh trắng trên ảnh che, để không trông như đứng hình) và tắt màn tải ngay, không mờ dần. App tự giữ khung lúc người chơi rời app (`pause` `bg`); trước quảng cáo game gọi `keepFrame()` như trên. Không dựng lại ngay dưới quảng cáo: cả game nạp lại cạnh trang quảng cáo là đúng phần RAM vừa làm renderer chết, và câu trả lời của quảng cáo sẽ tới một trang đã đọc xong `ads.lost`. Game nên: trả thưởng trong `ads.lost` và **cho người chơi thấy** (xu bay vào ô xu ngay khi menu hiện, không chỉ toast), ghi một sự kiện có `platform.device.relaunch` và thời gian boot (Crash Ramp v102q: `relaunch` {why, state, net, ram, s, ms, pl, kind, paid}). Đưa về màn kết quả cũ thì cần cả trạng thái lượt chơi; về menu với thưởng đã cộng là đủ êm (đó là chỗ nút "tiếp tục" đưa tới). Crash Ramp trên LDPlayer: giết renderer dưới quảng cáo thưởng x2_coins, đóng quảng cáo: ảnh che hiện ngay, WebView mới sau 1,2 s, menu sau ~12 s (LDPlayer chậm), 333 xu trả đúng. Galaxy A16 (v102s, 3 lần): ảnh che -> menu 5,6-7,5 s, luồng chính của app không bị chặn (khung đầu ~10 ms, tạo WebView 35-50 ms): thời gian là game khởi động lại trong renderer (nạp JS ~1,3 s, dịch shader 1,8-2,6 s, việc nền trước menu ~1 s), không có nguy cơ ANR vì ảnh che nhận chạm.

Khi quảng cáo đóng, gọi `adLightOff` trong `try/catch` rồi mới tới callback trao thưởng: vẽ lại khung lỗi (GPU yếu, context vừa mất) không được làm mất thưởng người chơi đã xem (Crash Ramp v98a).

**Xong khi:** chế độ thiết bị của Chrome (Moto G4, CPU chậm 4 lần) vẫn chơi được; `shell` báo tier không lên quá 2 khi đứng yên ở menu; một lần khựng ngắn lúc chơi không làm hạ độ nét; giả `'thermal'` `'light'` thì lượt chơi giới hạn 30 khung/giây mà độ nét giữ nguyên; đếm lệnh vẽ của một khung không có lệnh nào vẽ 0 phần tử, không vật liệu cộng sáng nào vẽ hai lần; trang chạy trên Chrome 81 không lỗi; sau một quảng cáo giả, `renderer.domElement.width` và `height` bằng đúng trước đó; nhả nhạc khi AudioContext đã suspend thì ArrayBuffer còn sống (memory-infra) giảm đúng cỡ bài nhạc.

## 6. Vòng chơi

Một lượt có các trạng thái rõ ràng, mỗi trạng thái một hàm vào và ra: `menu` (ná, thẻ nâng cấp, nút shop) → `aim` (kéo ná) → `run` (xe chạy, camera bám) → `result` (thẻ kết quả: mét, tiền, x2) → về `menu` hoặc sang map sau.

Luật của Crash Ramp:
- Lượt đầu tiên của người mới phải đi được khoảng 25 đến 35% map và nhận đủ tiền mua 1 đến 2 nâng cấp. Người chơi phải thấy mình tiến bộ sau mỗi lượt.
- Lượt hướng dẫn chỉ cho thấy những gì game thật có (Crash Ramp v100m, 3/11/2026). Bản v98p-v98s cho lượt đầu đâm vào một bức tường phuy dựng riêng rồi nổ tung, màn kết quả có dòng "Crash bonus"; game thật không bao giờ nổ xe, lượt thường kết thúc vì xe hết đà trên dốc. Người chơi vừa chờ một trải nghiệm không bao giờ tới, vừa học sai vòng chơi (tưởng lượt kết thúc vì đâm, không phải vì xe còn yếu). Bản sửa: lượt đầu kết thúc như mọi lượt (hết đà, "SO CLOSE"), cùng số xu, dòng thưởng đổi thành "First run bonus"; cái kết cũ vẫn bật lại được bằng Remote Config.
- Bỏ một cái kết dựng sẵn thì đo lại khoảng cách bằng máy tự lái: lượt hướng dẫn có món miễn phí (tên lửa) có thể đi xa ngang lượt 2 đã nâng cấp, và bài học "nâng cấp thì đi xa hơn" mất. Crash Ramp Map 1 (econ 2): tên lửa 1 s cho lượt 1 tới 188 m, lượt 2 (Xe + Ná Lv 1, tên lửa) 190 m; tên lửa của lượt hướng dẫn cháy 0,6 s thì lượt 1 dừng ở 168 m, lượt 2 hơn khoảng 22 m.
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

### Ba ván đầu: dạy ít, chờ ít (Crash Ramp v102p, 10/11/2026)

Số đo: Crash Ramp 0.1.2 (Android, 1.517 người cài từ Google Ads 4-8/11) dạy khoảng 10 thứ trong ván 1-3 (kéo ná, lái, tên lửa, x2, thẻ nâng cấp, mảnh xe, cánh, sao, rương, thông báo); 62 % người cài tới ván 3, 55 % tới ván 4, 8 % ván 1 không tới thẻ kết quả. Game gốc (Car Evolve 1.5.15, quay trên Galaxy A16 9/11) không dạy gì ở 4 lượt đầu: mở là kéo, nút tên lửa chỉ hiện sau lượt 3. Crash Ramp v102p đưa các luật dưới đây vào A/B `lean3`; kết quả (tới ván 4, D1 theo `ab_lean3`) chưa có.

- Ván 1-3 dạy tối đa 3 thứ của vòng chơi chính (game ná: kéo, mua nâng cấp, một vật phẩm). Mọi bài khác (vật phẩm thứ hai, lái, sao, tip phụ, thẻ phụ ở menu, câu hỏi bật thông báo) chờ tới ván 5 hoặc ngày 2. Gom điều kiện vào một hàm (`leanHold(save)`) để A/B hay Remote Config bật tắt ở một chỗ. Kiểm trong lượt chạy thì nhớ bộ đếm lượt đã tính lượt đang chơi (Crash Ramp đếm lúc bắn): ở menu `runs < 4`, trong lượt `runs <= 4`; lần đầu viết thiếu, bong bóng lái hiện ở ván 4.
- Câu hỏi bật thông báo đi cùng lời hứa quà ngày mai, không chen giữa các ván đầu.
- Đứng ở màn bắn mà không chạm: sau 3 s cho chính vật đó diễn động tác (Crash Ramp: xe lùi 1,4 m trong ná rồi bật về, dây ná rung, bàn tay chạy lại cùng lúc), lặp mỗi 3,5 s tới lần chạm đầu, không bao giờ tự bắn. Bẫy: Crash Ramp lấy lực của một lần chạm nhanh (không kéo) từ đích kéo hiện tại, nên phần diễn trả đích kéo về 0 ngay đầu handler chạm, trước mọi thứ đọc nó; không thì một cú chạm giữa lúc diễn thành một cú bắn yếu.
- Từ lúc xe dừng tới thẻ kết quả: Crash Ramp v102m 2,0 s (đứng yên 0,7 s mới tính là dừng, rồi 1,25 s chờ xu bung); v102p 1,1 s (0,35 s + 0,75 s, xu vẫn bung). Rút ngưỡng "dừng" thì chạy lại máy tự lái trên mọi map với cả hai ngưỡng: 540 lượt, không lượt nào ngắn đi quá 0,2 m (`tools/leanstop.mjs`).
- Ván mất cùng trang (mất WebGL, app bị Android tắt giữa ván): cất tiền của ván theo nhịp (Crash Ramp có từ v72j), lần mở sau hiện thành một thẻ có số mét và xu bay về, không chỉ một toast. Ván hướng dẫn cất kèm phần thưởng hướng dẫn để bài nâng cấp sau đó vẫn đủ tiền. Thẻ chỉ dùng chữ đã có (không thêm chữ cho 20 ngôn ngữ, không làm lại font).
- Đo trong A/B: thời gian tới cú kéo đầu (`sling_wait` ms, `ftue_step` first_pull), thời gian từ lúc lượt hết tới thẻ (`run_end.end_ms`), tỉ lệ ván 1 tới thẻ kết quả, tỉ lệ tới ván 4 và D1 theo nhánh.

### Năm ván đầu phải xa dần thấy được (Crash Ramp v106s, 23/11/2026)

Số đo: Crash Ramp 0.1.8 (Android, người cài mới 12-22/11/2026), trung vị quãng đường ván 1-8: 125, 169, 208, 214, 229, 249, 302, 305 m. Chỉ 67 / 63 / 51 / 47 % người có ván 2 / 3 / 4 / 5 xa hơn ván trước ít nhất 10 m. Hai nguyên nhân:
- Đường có các đỉnh dốc (Map 1: khoảng 167, 190, 210, 229, 250, 305, 358 m). Giữa hai đỉnh, một cấp nâng cấp chỉ thêm 1-4 m: xe vẫn dừng ở cùng chân dốc.
- Vật phẩm miễn phí của các ván dạy (rocket ván 1-2, cánh ván 2-3) làm ván đó dài hơn ván sau không có.

Cách sửa đã làm:
- Mấy cấp đầu cho thêm một phần (Crash Ramp: ma sát lăn giảm tới 18 % theo tổng cấp Xe + Ná), giảm dần về 0 ở khoảng cấp 7/7, để mỗi ván 1-5 qua một đỉnh mới mà phần sau của map không dễ đi (Map 1 không xem quảng cáo: 49 ván, trước 51).
- Vật phẩm đã dạy giữ miễn phí tới hết ván 5, không chỉ một ván.
- Kiểm bằng máy tự lái trong game thật, cả không dùng vật phẩm lẫn dùng đúng lúc gợi ý (`tools/firstruns.mjs`): không món 125, 149, 170, 190, 229 m. Người dùng món đúng lúc vẫn chạm một đỉnh lớn (305 m) ở ván 3-5: quãng đường đi theo bậc, nên đo theo đỉnh dốc, không theo % ma sát.

### Lessons from Crash Ramp v102g (9/11/2026): parts fitted to a car, and runs that never end

**Measure a model at rest before you fit things to it, and never cache a measurement taken mid-animation.**
Crash Ramp fits the rocket pods and the wings to the car's bounding box (measured once per car look and cached).
A Car upgrade's new part drops in from 1.6 m over the roof (a pop-in animation, tiny at first). A player who tapped
to skip the upgrade show while the part was still in the air got the box measured right then: the pods stood 1.1 to
1.6 m over the roof on a tall rack until the next look. Fix: the car offers `atRest(fn)`, which puts every part that
is still animating at its resting place, runs the measurement, and puts them back. Also leave effects out of the box
(exhaust flames, a rocket's 2.6 m flame): mark them (`userData.noBox`) and skip them when measuring.
Check it the way a player breaks it: buy, skip the show at different moments, then compare the fitted item with a
fresh measurement (Crash Ramp `tools/podcheck.mjs`: 24 Car levels bought with the show skipped; the old build was off
by +1.0 to +1.2 m on 4 of them).

**Every run needs a watchdog on progress, not only on speed.** Ending a run on "speed under 0.5 m/s for 2.5 s" misses
a car wedged in terrain: Crash Ramp's car fell off the verge onto a narrow ledge under a 3.4 m vertical step of the
coast terrain, one side's wheels touching the step's top, and shook there for good (speed bouncing 0 to 18 m/s, the
run ran until the 5-minute cap). Fix: if the run gains less than 1.5 m in 3 s (no rocket burning, no flight item
flying), put the car back on the lane when it is off the road with fuel left (at most twice a run), otherwise end the
run where it is (analytics `why: 'stuck'`). Reproduce such reports headless at the exact spot from the video (map,
distance, side offset) with the physics alone, then run the whole autopilot sweep before and after: the watchdog
must change nothing in normal runs (Crash Ramp: 324 runs, 6 maps, identical).

### Slingshot / launch games: aiming is a skill, a record is a place, a line is not a shove (Crash Ramp v102i, 9/11/2026)

Feedback after the owner played Crash Ramp against the reference game (three points, all fixed in one build):

- **Let the aimed shot fly off the road.** An in-air "track magnet" that steers the opening flight back over the lane,
  plus a touchdown that turns the car along the road, made every aim land on the road: players stopped caring where
  they aimed. Fix: the shot from the launcher keeps its own heading (no magnet on that flight only; later jumps keep
  it), off the road it touches down along its flight and loses speed on the rough (Crash Ramp: up to 50 %, full at
  half a road width past the edge), with dust and a thump. On the road nothing changes, so the tuned economy and maps
  still hold for a straight shot. Check with a sim: an aimed shot must never go further than the straight one
  (Crash Ramp `tools/aimgrid.mjs`: 0 runs further on 6 maps; a floating rail map falls off at full aim, by design).
- **Warn on the aim line, before the release.** Predict the landing with a cheap ballistic step (same pitch and hang
  as the real launch, no drag; within 1.5 m of the physics) and tint the aim strip red, throbbing, while it would
  land off the road. Re-predict only when the aim or power moves a step (1/200 rad, 1/20 power). A shader change
  means the early shader-warm pack must be captured again.
- **A new record must be seen where it happened.** Plant the best marker (a flag on a tall pole, its cloth the
  "YOUR BEST / N m" banner, streaming in over the road where the chase camera looks) where the run ended, rising out
  of the ground; hold the result card ~1.5 s for it. Build it from the material kinds the marker already used
  (unlit, with and without a map, single sided) so no new shader program compiles at the run's end; animate the
  cloth on the CPU (a 10x1 plane is nothing).
- **Crossing a line must not feel like a push.** A slow-motion beat that returns to full speed, and an FOV kick, both
  read as the car being shoved forward. Keep the banner, sound, haptic and a light flash; drop time scaling and FOV
  punches on lines the car merely crosses.

Addendum to the section "Slingshot / launch games: aiming is a skill ..." (Crash Ramp v102k -> v102l, 9/11/2026):

- **A bowl-shaped road undoes the aim after landing.** Crash Ramp's road lies in a half-pipe whose banks keep rising
  past the edges (so cars never slam into a lip); a car that came down on the bank was rolled back to the middle by
  gravity, and the owner still saw "the game pulls the car back". Also check the aim range against the SHORTEST shot:
  at 0.16 rad the first upgrades' 20 m lob never left the road; 0.35 rad does.
- **Let the miss play out, don't end the run for it.** v102k ended the run ("FELL OFF") when the shot came down 1.5 m
  past the edge; the owner asked why at once and chose instead: the car stays out on the grass (the bank's sideways
  pull cancelled while it is off the road), slows a fixed m/s² (5) until it stops, and the distance counts. Steering
  back onto the road makes it a normal car again; no air magnet and no "put back on the lane" recovery while it is out.
  A floating track with nothing beside it (a rail over a void) may still drop the car. Rule: a punishment the owner
  did not ask for (ending the run) gets offered as a choice first, not shipped.
- Probe: run the shot and keep stepping until it stops, logging the sideways offset past the edge: it must never come
  back onto the road by itself (Crash Ramp tools/offprobe.mjs, test/v102i.test.mjs).

### Game nhiều màn (puzzle): level online

Game theo màn (puzzle, sort, merge…) không viết level cứng vào code: mỗi level một file `levels/level_<n>.json`, nạp qua `levels.createLevels` (README mục 8, "Level online"; game mẫu `packages/levels/example` "Tắt Đèn" trong kit). Sau khi lên store, PM của game sửa, thêm, thử level trên trang admin cloud save của game mà không ra bản mới; dev không phải làm gì thêm.

- Level có sẵn trong app = đúng các file đó (bộ 0). Kiểm mỗi file bằng `validate` của game: level online không qua thì máy giữ bộ cũ. Test tự động: mọi level giải được, `par` đúng bằng số bước ít nhất (game mẫu: `test/smoke.mjs`).
- `levels.get(n)` ở đầu màn; `levels.apply()` chỉ ở menu, sau khi xong một màn hay lúc mở app, không bao giờ giữa màn.
- `started(n)` mỗi lần vào màn (cả chơi lại), `won(n, { moves, stars })`, `lost(n, { moves, reason })` (`limit`, `restart`, `quit`). Đó là nguồn của tỉ lệ qua màn trên Firebase; không gửi thêm sự kiện màn của riêng game trùng nghĩa.
- Tiến độ lưu theo số màn. Hết level thì game tự quyết (lặp từ màn 4, "đang làm thêm"); bộ mới có thể dài hơn (`levels.count`).
- Tools ẩn của game có dòng Level online: bộ đang dùng, bộ chờ, Support ID (QA dán vào mục Máy thử), "Kiểm tra ngay", "Dùng bộ mới".

**Xong khi:** trên trình duyệt (không có server) chơi hết level có sẵn; với server giả (truyền `url`, như `tools/serve-fake.mjs` của game mẫu) một bộ online tới máy ở menu, không tới giữa màn; `level_end` có `level_set`, `level_hash`, `success`.

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
  if (platform.ads.busy()) return;                             // chạm lần hai khi quảng cáo đang mở: không làm gì cả
  track('rv_offer', { pl: placement });                       // mỗi lần nút hiện ra
  if (!platform.ads.rewardable(placement)) {                   // rewarded đã load, hoặc interstitial SDK đổi vào (rv swap)
    const r = await monetize.waitRewarded(platform.ads, { pl: placement, waitMs: ADS.rvWaitMs, gone: () => game.state !== 'result' });
    if (r !== 'ready') { toast(t('ads_no_video')); track('rv_unavailable', { pl: placement }); return; }
  }
  S.adPend = { pl: placement, coins: placement === 'x2_coins' ? S.lastRunCoins : 0 };   // thưởng cần trả nếu trang bị tắt
  store.save(S);                                               // hệ điều hành có thể đóng trang lúc quảng cáo chạy
  track('rv_start', { pl: placement, swap: platform.ads.swapOf(placement) });
  adLightOn(shell, game);                                      // bước 5
  const back = setTimeout(() => { try { adLightOff(shell, game); } catch (e) {} }, 120000);   // 2 phút chưa về: vẽ lại
  const r = await platform.ads.rewarded(placement);
  clearTimeout(back);
  if (r.reason === 'busy') return;                             // quảng cáo trước còn đang chạy: để nó tự trả lời
  try { adLightOff(shell, game); } catch (e) { console.error(e); }   // lỗi ở đây không được làm mất thưởng
  delete S.adPend; store.save(S);                              // mọi đường ra đều xoá dòng chờ và lưu ngay
  if (!r.ok) { track(r.reason === 'closed' ? 'rv_cancel' : 'rv_fail', { pl: placement, why: r.reason }); return; }
  monetize.noteRewarded(S.ads, Date.now());
  give(); store.save(S); track('rv_done', { pl: placement, swap: r.swap });   // swap 1 / 2: interstitial đã hiện thay, thưởng như nhau
}
platform.on('ads', () => ui.setAdButtons(platform.ads.rewardable('x2_coins')));
```

**rv swap (SDK webgame 0.90.0, mặc định bật).** Bấm nút rewarded mà MAX định giá interstitial đã load cao hơn rewarded đã load, hoặc chưa có rewarded nào mà có interstitial, thì SDK hiện interstitial và trả `ok` true khi nó đã hiện: game trao đúng phần thưởng của nút. Crash Ramp: v104g chạy A/B (nhánh `swap`), v105l (19/11/2026) bật cho mọi người chơi, kể cả người đã mua Remove Ads (họ tự bấm để lấy thưởng; interstitial bắt buộc của họ vẫn tắt). Ghi `swap` vào `rv_start` / `rv_done` để tách doanh thu; SDK tự gửi `rv_swap` với eCPM hai bên (`rv_v`, `iv_v`). Interstitial đổi vào không tính vào nhịp interstitial (`noteRewarded`, không `noteInter`). Luật store: cho thưởng khi người chơi tự chọn xem là được; không bao giờ làm ngược lại (hiện rewarded như interstitial bắt buộc). Placement không muốn đổi (ví dụ revive giữa lượt): `platform.init({ rvSwap: { skip: 'revive' } })`; tắt hẳn: `rvSwap: false` hoặc Remote Config `wg_rv_swap` = 0. Interstitial đổi vào không có trong `platform.ads.lost`: dòng `S.adPend` ở trên là đường bù duy nhất khi trang chết dưới nó. Game đã tự làm swap (như Crash Ramp `rvSwapPick`) bỏ code của mình khi lên SDK này, hoặc `rvSwap: false`, để không đổi hai lần.

**Big ad offer (SDK webgame 0.93.0, mặc định tắt).** Thỉnh thoảng MAX load được một quảng cáo giá rất cao (Crash Ramp 19/11/2026: vài lượt $0.5-$2.5 một lượt, so với $0.004 của một rewarded thường). Khi đó game hiện một thẻ vàng nổi bật "xem video này, nhận thưởng lớn" và `showBig` hiện **đúng** quảng cáo đó: người chơi được nhiều, studio được nhiều. SDK chọn quảng cáo (định dạng trong `formats`, giá cao hơn; hoà thì rewarded), giữ giới hạn (`perDay` 3 lần trả thưởng một ngày chung mọi placement, `cooldownMin` 20 phút, không trong phiên đầu, không trên robot) và gửi `bigad_*`. Game vẽ thẻ, chạy đồng hồ đếm ngược và quyết phần thưởng:

```js
await platform.init({ ..., bigAd: true });   // game bật; Remote Config wg_bigad = 0 tắt từ xa

// phần thưởng theo tier (số mốc tiers [0.2, 0.5, 1, 2] giá đạt được), định theo cái người chơi THẤY, so với gói IAP:
// gói $2.99 = 10 gem trong shop, nên thẻ cao nhất 30 gem là "bằng 3 gói": lớn mà không phá shop.
// Không tính theo doanh thu của mình (40% của $1.5): người chơi không thấy giá quảng cáo, chỉ thấy gem.
const BIG_GEMS = [5, 5, 10, 20, 30];                         // tier 0..4 (tier 0 chỉ khi minUsd < mốc đầu)
const PACK = { gems: 10, usd: 2.99 };                        // gói gem rẻ nhất của shop
// người đã mua (IAP thật, Remove Ads): gem là thứ họ trả tiền mua, cho theo giá gói x1.5, tối đa 10 (Crash Ramp v105m)
const payer = () => S.noAds || (S.buys || []).some((b) => !b.test);
const bigGems = (o) => payer() ? Math.min(10, Math.max(1, Math.round(o.usd * PACK.gems / PACK.usd * 1.5))) : BIG_GEMS[o.tier];

let card = null, left = 0, expired = '';                      // thẻ đang hiện, mili giây còn lại, thẻ đã hết giờ
const keyOf = (o) => `${o.fmt}:${o.tier}`;
function bigSync() {                                          // gọi mỗi ~2 s ở menu (không gọi khi platform.ads.busy())
  const o = platform.ads.bigAd({ pl: 'big_ad' });            // SDK gửi bigad_offer khi thẻ bật / tier tăng
  if (!o.ok || keyOf(o) === expired) { card = null; ui.bigCard(null); return; }   // hết giờ: chờ ad khác / tier cao hơn
  if (!card) left = 20000;                                    // đồng hồ 20 s: thấy là quan trọng, không chờ mãi
  card = { ...o, gems: bigGems(o) };                          // số trên thẻ là số sẽ trao
  ui.bigCard({ gems: card.gems, left, total: 20000 });        // nút ghi rõ "xem quảng cáo" (biểu tượng video)
}
function bigTick(dt) { if (card && (left -= dt) <= 0) { expired = keyOf(card); card = null; ui.bigCard(null); } }
async function bigTap() {
  if (platform.ads.busy() || !card) return;
  const gems = card.gems;                                     // trao đúng số trên thẻ, không tính lại theo r.usd
  store.save(S);                                              // hệ điều hành có thể đóng trang lúc quảng cáo chạy
  adLightOn(shell, game);
  const r = await platform.ads.showBig('big_ad');            // { ok, reason, usd, fmt, tier }
  try { adLightOff(shell, game); } catch (e) { console.error(e); }
  if (r.reason === 'busy') return;                            // (đã kiểm busy() ở trên: hiếm) quảng cáo trước tự trả lời
  if (r.ok) { S.gems += gems; track('big_reward', { gems, payer: payer() ? 1 : 0 }); }   // thưởng là việc của game
  else if (r.reason === 'changed' || r.reason === 'gone') toast(t('ads_no_video'));     // ad rẻ hơn / hết: thẻ vẽ lại theo giá mới
  store.save(S); card = null; bigSync();
}
// lúc mở game, cùng chỗ trả ads.lost (dưới đây): rewarded của thẻ mà trang chết dưới nó, đã xem hết, SDK đã đếm vào giới hạn
for (const b of platform.ads.bigLost) S.gems += bigGems(b);  // { pl, usd, fmt, net, tier } của lần mời; ads.lost cũng có dòng 'big_ad': bỏ qua dòng đó
```

Vài điều Crash Ramp đã học: một thẻ ở một chỗ một lúc (menu, màn chuẩn bị, thẻ kết quả dùng chung một quota); số trên thẻ tính lại mỗi lần `bigAd()` vì giá ad đã load đổi khi một ad khác load vào, và `showBig` trả `changed` và không hiện gì nếu ad lúc bấm rẻ hơn cái đã mời (khác định dạng, tier thấp hơn hoặc giá thấp hơn): game trao đúng số trên thẻ, người chơi không bao giờ nhận ít hơn số đã thấy và studio không trả thẻ $1.9 cho một ad $1.0; thẻ đừng chen vào màn hướng dẫn hay những lượt đầu (`firstSession: false` của SDK, game có thể thêm luật của mình như "5 lượt đầu ngày cài"). Rewarded của thẻ không qua rv swap (`showBig` hiện đúng định dạng đã mời); interstitial của thẻ cũng như swap: không tính vào nhịp interstitial (`noteRewarded`, không `noteInter`), người có Remove Ads vẫn được mời. Trang chết dưới interstitial của thẻ: không có gì để bù (interstitial không có trong `ads.lost`, như swap); dưới rewarded đã xem hết: `platform.ads.bigLost`, mỗi dòng một lần, `lostDone()` xoá. Đừng bù từ một dòng game tự ghi trước khi mở quảng cáo (như `S.adPend`) mà không có `ads.lost`: tắt app giữa video là được thưởng. Thử trên web: `platform.ads.simulate(fn, { rvValue: 1.2 })` cho ad giả giá $1.2. Godot: `Horus.start({"big_ad": true})`, `Horus.ads.big_ad()`, `await Horus.ads.show_big(pl)`.

**Mỗi lúc một quảng cáo.** Người chơi chạm hai, ba lần liền vào nút quảng cáo (30-70 ms) thì lần chạm sau gọi quảng cáo lần nữa khi cái đầu đang mở. Trước SDK 0.26.1 app trả lần sau là `not_ready`; game coi đó là "không có quảng cáo", trả lại bộ đệm vẽ, cảnh 3D và nhạc ngay dưới video đang chạy, và WebView crash trong `draw_gl` (Crash Ramp 2/11/2026: crash nặng đầu tiên trên Crashlytics, cùng một người chơi ba lần dưới video Unity Ads). Từ SDK 0.26.1 lần gọi sau trả ngay `{ ok: false, reason: 'busy' }` (interstitial: `{ shown: false, busy: true }`), không hỏi app, và analytics có `ad_dup` `{ pl, kind }`. Game kiểm `platform.ads.busy()` trước mọi việc trong hàm bấm nút, và gặp `busy` thì không đổi gì: không trả bộ đệm vẽ, không bật nhạc, không xoá `S.adPend`.

Android có thể tắt trang web trong lúc quảng cáo thưởng đang chạy (máy RAM thấp): người chơi xem hết mà callback không bao giờ về, trang mở lại ở menu. Từ SDK 0.22.0, app giữ những lần đó trong `platform.ads.lost` (`[{ pl, at }]`, web là `[]`). Game trao thưởng mỗi lần đúng một lần ngay sau khi đọc save, rồi gọi `lostDone()`:

```js
function recoverLostAds(game) {
  const lost = platform.ads.lost || [], pend = S.adPend;
  delete S.adPend;
  for (const { pl } of lost) {
    if (pl === 'x2_coins') game.addCoins(pend?.pl === pl ? pend.coins : S.lastRunCoins);   // lượt đã mất: số xu ghi trước quảng cáo
    else if (pl === 'shop_gems') game.addGems(GEMS_PER_VIDEO);  // như một video thường
    else (S.adCredit ||= {})[pl] = 1;                           // quà chưa trao: lần sau ở chỗ đó miễn xem quảng cáo
    track('ad_reward_recovered', { pl });
  }
  store.save(S);
  if (lost.length) platform.ads.lostDone();
}
```

Không bao giờ cho gem ở chỗ vốn không cho gem. Crash Ramp: một người chơi Galaxy A17 mất thưởng hai lần như vậy rồi gỡ game sau 27 giây.

Các chỗ của Crash Ramp: **x2 xu** trên thẻ kết quả (lượt đầu cho miễn phí để người chơi biết nút), **nâng cấp miễn phí** khi thiếu xu (bước 9), **1 gem** trong shop (1 video = 1 gem, không chờ), **rocket miễn phí** trước lượt, **x2 quà quay lại**. Gọi `platform.ads.load('rv')` khi thẻ kết quả mở và khi về menu.

**Xong khi:** trên trình duyệt với `platform.ads.simulate(...)`, mọi nút rewarded chỉ thưởng khi xem hết, đóng sớm không thưởng; analytics có `rv_offer`, `rv_start`, `rv_done` cho từng placement.

### Âm thanh sau quảng cáo trên iOS

Sau quảng cáo, bảng Game Center hay khi chuyển app, WebKit có thể báo `AudioContext` là `running` mà không ra tiếng: mạng quảng cáo đổi audio session của app. Crash Ramp (10/2026) gặp: mất tiếng sau quảng cáo, quảng cáo đầu tiên của lần mở bị câm, mất tiếng sau lần chuyển app đầu, và tiếng "tách" khi tạm dừng. App đặt lại audio session sau quảng cáo và khi app quay lại, rồi gửi sự kiện `'audio'` (`{ reason }`, iOS). Game:
- Nghe `'resume'`, `visibilitychange`, `pageshow` và `platform.on('audio', ...)`: mỗi lần thì "đá" context (suspend rồi resume), thử lại mỗi 0,4 giây trong 6 giây nếu chưa chạy. Gộp các lần đá trong 0,3 giây, tối đa một lần khởi động lại mỗi 2 giây.
- Trước khi `suspend`, giảm gain về 0 trong vài chục ms; khi resume thì tăng lại. Suspend đột ngột gây tiếng tách, cả khi vuốt ra màn chuyển app.
- `@horus/audio` đã tự resume khi trang hiện lại và về `'locked'` khi iOS ngắt tiếng (chạm kế tiếp mở lại); phần trên là thêm cho quảng cáo.
- Thử trên iPhone thật: xem hết một rewarded, đóng sớm một rewarded, một interstitial, chuyển app và quay lại: lần nào nhạc cũng còn, không có tiếng tách.

### Quảng cáo thưởng xong thì Android tắt luôn cả app (máy 2-4 GB)

`platform.ads.lost` chỉ gồm lần trang web chết mà app còn sống. Crash Ramp v101c đo trên người chơi thật: máy 2-4 GB cứ khoảng 10 quảng cáo thưởng thì một lần kết thúc bằng app bị tắt hẳn (`platform.device.exits` ghi `reason: 'low_memory'`), người chơi xem xong mà không được thưởng. Game tự giữ phần thưởng qua lần mở sau:

1. Ngay trước `platform.ads.rewarded`, ghi vào save một dòng ghi nhớ: placement, thưởng gì, lúc nào (lưu ngay, không đợi lần lưu sau).
2. Quảng cáo kết thúc bình thường (được thưởng hay bỏ giữa chừng): xoá dòng đó và lưu ngay.
3. Lần mở sau, đọc save xong: dòng ghi nhớ còn đó và `platform.device.exits` có một lần hệ thống tắt app (`low_memory` hay kiểu tắt khác của hệ thống, không phải người chơi tự đóng) từ 5 giây tới 10 phút sau lúc quảng cáo bắt đầu, thì trả thưởng đúng một lần rồi xoá dòng ghi nhớ.

Không bao giờ trả tiền cao cấp (gem) kiểu này: chỉ quảng cáo xem hết thật mới được trả gem. Xu, lượt chơi lại, x2 phần thưởng thì được.

Nếu có cả `platform.ads.lost` lẫn dòng ghi nhớ cho cùng một quảng cáo, chỉ trả một lần: trả theo `lost` rồi xoá dòng ghi nhớ; dòng ghi nhớ chỉ dùng khi app bị tắt hẳn (không có `lost`).

**Quảng cáo đưa người chơi sang game khác.** Crash Ramp (11/2026): 22 % người chơi đã vào game từng bấm vào quảng cáo thưởng rồi không xem hết; 12 người gỡ game ngay lúc quảng cáo đang mở, 8 trong số đó trên quảng cáo của chính một mạng. Chặn quảng cáo game cùng thể loại / đối thủ trong MAX Ad Review và trong dashboard từng mạng (Horus và chủ game làm). Theo dõi hai chỉ số: gỡ app trong 2 giờ, gỡ app khi quảng cáo đang mở.

### Quảng cáo không đóng được, crash hay ANR dưới quảng cáo: tìm creative rồi chặn

Crash Ramp 11-13/11/2026: interstitial là playable của AppLovin không có nút đóng, Back không ăn; người chơi chỉ còn cách tắt app. Không có mốc thời gian nào phân biệt được quảng cáo kẹt với quảng cáo dài (có quảng cáo chạy hơn 60 s), nên vỏ app (webgame 0.98+) ghi lại theo kiểu "app chết khi quảng cáo còn mở", game không phải làm gì:

- `ad_stuck` (analytics, lần mở app sau): `network`, `ar_creative` (mã Ad Review của AppLovin), `creative`, `dsp`, `open_s`, `bg` / `clicked` (1: app ở nền lúc chết / người chơi đã bấm quảng cáo: không phải kẹt), `exit` (Android 11+: `user` / `other:remove task` là người chơi tắt app, `crash`, `anr`, `low_memory`).
- Crashlytics: crash và ANR có key `ad_open` khác rỗng là xảy ra dưới quảng cáo; key chứa mã Ad Review.
- `renderer_gone` có `state` = `ad` kèm `creative`.

Tắt app vì quảng cáo lỗi hay vì không muốn xem? Một lần thì không biết; nhìn theo creative. Người không muốn xem tắt sớm (vài giây) với mọi creative; quảng cáo lỗi thì người chơi chờ, chạm góc trên (chỗ nút X) hay bấm Back nhiều lần (`corner`, `back`) rồi mới tắt, và tỉ lệ tắt của creative đó cao hơn hẳn creative khác (mẫu số: `ad_impression` có `ad_creative`).

Mỗi tuần: đếm `ad_stuck` theo `ar_creative`, chỉ dòng `bg` = 0 và `clicked` = 0 (bỏ `exit` = `low_memory`: máy thiếu RAM, không phải lỗi creative), cộng crash/ANR theo `ad_open`. Luật chặn đề xuất: từ 3 lần trở lên có `open_s` > 30 và (`corner` ≥ 2 hoặc `back` ≥ 1), và trên 5% số `ad_impression` của creative đó. Creative như vậy thì vào MAX dashboard > Ad Review, tìm theo mã, Block. Một creative bị nhiều người tắt app thì báo rep AppLovin chặn cả nhà quảng cáo.

**Đo trên máy (Idle Jump Ball, game Godot, Galaxy A16 4 GB, 25/11/2026, 21 quảng cáo thật):** 5/5 playable của AppLovin (interstitial lẫn rewarded, 3 creative khác nhau) không bao giờ có nút đóng: cây view của màn quảng cáo (`uiautomator dump`) chỉ có WebView của creative, AppLovin không thêm view đóng nào (không phải bị che hay nằm dưới tai thỏ), và AppLovin nhận Back (`OnBackInvokedCallback`) rồi bỏ qua. Kẹt 3-13 phút tới khi tắt app. Playable của Unity, quảng cáo AdMob và InMobi đóng bình thường. Vậy lỗi nằm ở creative / SDK, không phải ở game hay vỏ app (Crash Ramp bản web cũng gặp). Trong lúc kẹt, bộ nhớ của app cộng renderer quảng cáo đứng ~930-1020 MB, mức cao nhất cả phiên: playable kẹt cũng là ứng viên cho báo cáo "OOM / bộ nhớ cao lúc interstitial". Quảng cáo đóng được thì 30 s sau bộ nhớ về lại mức trước, không tăng dần qua 17 quảng cáo. Đo bộ nhớ dưới quảng cáo phải cộng cả tiến trình renderer riêng của quảng cáo (`com.google.android.webview:sandboxed_process` cùng uid với app, `dumpsys meminfo <pid>`): `dumpsys meminfo <app>` không có phần đó.

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
if (due && !platform.ads.busy() && platform.ads.ready().inter) {   // busy(): rewarded còn đang mở, không chồng hai quảng cáo
  monetize.noteInter(S.ads, S.runs, Date.now());
  track('inter_show', { pl: 'result_exit' });
  adLightOn(shell, game);
  try { await platform.ads.inter('result_exit'); } finally { adLightOff(shell, game); }
}
```

Luật Crash Ramp: chỉ khi thẻ đã mời x2 mà người chơi không lấy; không trước lượt thứ 4; cách ít nhất 2 lượt và 120 giây; không trong 90 giây đầu phiên; không trong 45 giây sau một rewarded; phiên đầu không có cho tới khi qua Map 1. Đã mua Remove Ads thì không bao giờ có.

Đổi một chỗ rewarded thành interstitial chỉ vì eCPM interstitial cao hơn: Crash Ramp đo eCPM interstitial $17,5 so với rewarded $20, lợi tối đa khoảng 10 % tổng và phần lớn từ một mạng. Làm thì làm như một A/B. Quảng cáo thưởng phải do người chơi tự chọn xem; ép xem rewarded như interstitial là trái chính sách AdMob.

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

function grant(p) {                       // p: { sku, token, orderId, state }
  if (p.state === 'pending') return;      // chưa trả xong / Ask to Buy: không giao, không finish; đơn về lại qua 'purchase'
  const item = productBySku(p.sku);
  if (!item) { track('iap_unknown_sku', { sku: p.sku }); return; }   // SKU game không bán: không giao, không finish (store tự hoàn tiền)
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
  if (r.status === 'ok') { grant(r); platform.cloud?.sync(); }   // ?.: không có platform.cloud khi start({ cloud: false })   // gửi save lên cloud ngay sau khi mua (bình thường chờ tới 2 phút)
  else if (r.status === 'pending') toast(t('shop_pending'));
}
platform.on('purchase', (p) => { if (p.state !== 'pending') grant(p); });   // đơn trả xong lúc game đang chạy (thanh toán chậm, Ask to Buy)
export const merge = (into, from) => save.mergePurchases(into, from, { credit: (s, b) => giveGoods(s, productBySku(b.sku)), flags: ['noAds'] });
```

Giá hiện trên nút: `platform.iap.price(sku) || item.price`. Shop của Crash Ramp: 6 gói gem (10, 30, 100, 150, 200, 500 gem; $2.99 đến $29.99), Remove Ads $4.99, 1 gem cho mỗi video. Có nút **Restore purchases** khi `platform.iap.restorable`.

Không cho bấm mua khi mất mạng: nút mua mờ đi kèm dòng "Cần kết nối mạng" (`navigator.onLine` và sự kiện `online`/`offline`). Crash Ramp 0.1.4 (9-11/11/2026): 176 lần mua lỗi so với 1 lần thành công, gần hết là bấm khi không có mạng (lỗi sau 150-300 ms, bảng mua không kịp mở). Khi lỗi, ghi `iap_result` có `reason`. Cần 30-50 người mua mới đọc được số IAP.

**Chạm nhầm vào nút mua.** Crash Ramp 0.1.4 (11/2026): 80 trên 137 lần mở bảng mua của store đến từ shop tự mở khi thiếu gem, 42 lần là bấm Remove Ads (dòng trên cùng) chứ không phải gem, 20 lần bấm trong 1 giây sau khi shop mở; nút của offer bị bấm 1-2 giây sau khi popup hiện. Sửa: nút mua không nhận chạm trong 700 ms đầu sau khi màn hay popup hiện; shop mở vì thiếu gì thì cuộn tới đúng gói đó; chỉ mời Remove Ads sau khi người chơi đã gặp interstitial. Hầu hết lần huỷ là chạm nhầm, không phải người chơi chê giá.

Store, gói và giá (Horus làm với tài khoản store):
- App Store: gói IAP đầu tiên (consumable) phải gửi duyệt cùng một bản app.
- Google Play: chỉ tạo được sản phẩm sau khi đã upload một bản có quyền BILLING. Play đặt giá mới theo tiền của tài khoản: đặt lại giá USD.
- Android: hỏi thông tin sản phẩm lúc bấm mua có thể lỗi một lần (Crash Ramp 0.1.8: 15 người mua bị `query_failed` khoảng 0,25 s sau khi bấm). Kit 0.94.1 hỏi lại sau 1 s, rồi dùng thông tin `iap.products` đã có; lý do lỗi có mã của Play (`query_failed <mã>`).
- iOS: sau khi người chơi huỷ, StoreKit có thể trả lời chậm khoảng 7 giây: nút mua hiện lại giá ngay khi bảng mua đóng, không chờ kết quả.

**Xong khi:** mua giả lập từng SKU: hàng vào đúng một lần; tải lại giữa chừng (trước `finish`): `pending()` giao lại, không trùng; `status: 'invalid'` không thưởng.

**Phí Google thật (earnings tháng 10/2026, Horusent Sing và Horus Ent HK, cả hai không trong mức 15% của 1 triệu USD đầu):** gói thuê bao 15%; gói mua một lần 30%, nhưng 25% với người cài app sau khi phí mới bắt đầu ở nước đó (Mỹ, Anh, EEA từ 30/6/2026; Úc, Nhật từ 30/9/2026). Ở các nước đó 80% tiền gói một lần là người cài mới, nên trung bình khoảng 26%. Tổng cả tháng: Sing 26%, HK 22.5% (HK nhiều thuê bao). Đừng tính doanh thu net với 15%: horus-iap tính theo luật này (`feeFrom` trong câu trả lời), app Android gửi `installedAt` để biết người cài mới. Số chính xác từng đơn: báo cáo earnings của Play Console, cột Service Fee % và Fee Description.

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
const ctx = { now: Date.now(), runs: S.runs, day: liveops.dayKey(), playS1: firstSession ? playSecs : Infinity };   // playS1: giây chơi của phiên đầu (minSecs)
const d = monetize.due(st, OFFER_DEFS, OFFER, ctx);
if (d) {
  const def = OFFER_DEFS.find((o) => o.id === d.id);
  const n = monetize.shown(st, def, OFFER, ctx);   // lần hiện thứ mấy
  ui.offerPopup(d.id);
  track('offer_show', { offer: d.id, trigger: d.trigger, shown: n, price: productUsd(d.id), value: offerValue(d.id) });   // tên tham số: ANALYTICS.md mục 8; giá và giá trị từ bảng sản phẩm của game
}
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

Trong app, giá trị mới có từ **phiên sau** (app dùng giá trị đã tải ở phiên trước; lượt cài mới chờ tối đa 2 giây rồi dùng mặc định, README mục 6). Mặc định trong `config.js` phải là cách chơi mong muốn của phiên đầu; A/B cần có hiệu lực từ phiên đầu thì chia trong code.

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

Xin quyền: `platform.notif.ask()` sau lượt thứ 2 (không ngay khi mở game; hỏi muộn thì phần lớn người chơi đã bỏ game trước khi được hỏi). Lập lại lịch mỗi lần `pause`. Thông báo có tiếng riêng lấy từ âm thanh có sẵn trong game (người chơi nghe là nhận ra game nào): `"notif": { "sound": "sfx/notify.wav", "headsUp": true }` trong `horus-game.json` (README mục 12); Android nhắc bằng alarm nên Doze không nuốt. Icon nhỏ và màu thông báo Android riêng của game: `"notif": { "icon": "brand/ic_stat_<game>.xml", "color": "#RRGGBB" }` trong `horus-game.json` (VectorDrawable trắng, nền trong suốt, 24dp, hoặc thư mục `drawable-<dpi>/` mỗi thư mục một .png; README mục 12). Không tự thêm `res/drawable/webgame_notify` vào app.

Chia sẻ, mời bạn, mã quà (Crash Ramp v89):
- Nút Share ở màn kết quả: vẽ ảnh kết quả bằng canvas rồi `platform.share.open({ title, text, url, image: canvas.toDataURL('image/png') })` (Android chooser, iOS share sheet, web `navigator.share` hay chép link; README mục 11). Link thách đấu để trong Remote Config.
- "Mời bạn": chỉ link, không thưởng (thưởng theo lượt mời là chỗ gian lận).
- "Mã quà": `liveops.redeemCode(S.codes, mã, rc.gift_codes, { caps: { coins: 2000, rockets: 5 } })`; bảng mã rỗng mặc định, mỗi người một lần, không bao giờ gem, trần kẹp trong code để Remote Config sai không làm lạm phát.

**Xong khi:** `platform.notif.schedule` được gọi khi ra nền với danh sách trong khung giờ; tắt Notifications trong Settings thì `cancelAll()`.

## 16. Analytics và phễu người mới

Bộ event đầy đủ, tham số chung và quy tắc tên: `ANALYTICS.md` (Analytics chuẩn Horus). Làm đúng bộ đó; phần dưới là cách gắn và bài học của Crash Ramp.

```js
import { liveops, platform } from './sdk.js';
export const FTUE_STEPS = ['open', 'first_play', 'first_launch', 'first_result', 'first_upgrade', 'run_2', 'run_5', 'map1_clear'];   // bước chung (ANALYTICS.md mục 5); bước riêng của game thêm vào giữa
const an = liveops.createAnalytics({
  state: S.an, steps: FTUE_STEPS, installAt: () => S.meta.installAt, build: GAME_BUILD,   // GAME_BUILD trong config.js ('v90'): tham số build trên mọi event
  ctx: () => ({ sess: S.meta.sessions, day: liveops.dayIndex(S.meta), runs: S.runs, map: S.map, season: S.season }),   // createAnalytics chỉ tự thêm build; còn lại từ ctx
  sink: { log: (n, p) => platform.an.log(n, p), user: (p) => platform.an.user(p) },
});
export const track = (n, p) => an.track(n, p);
```

Sự kiện tối thiểu (bảng "Bắt buộc" của `ANALYTICS.md`): `session_begin`, `session_pause`, `day_return`, `boot` (`ms` từ lúc mở tới khi chơi được), `run_start`, `run_end` (map, mét, tiền, thắng/thua: kèm `platform.an.result(won)`), `upgrade` (id, cấp, trả bằng gì), `map_clear`, mọi bước FTUE, `rv_offer` / `rv_start` / `rv_done` theo placement, `inter_show`, `offer_show` / `offer_buy`, `shop_open`. Tiền: `platform.an.earn` / `spend` mỗi lần nhận hay tiêu, `platform.an.balance` sau đó. Doanh thu quảng cáo và IAP do app tự gửi.

Để biết máy nào chậm hay lỗi (Crash Ramp v97f, v97g):
- `boot` thêm `wv` (số Chrome của WebView; iOS là phiên bản iOS), thời gian từng bước mở game (`t_js`, `t_plat`, `t_cloud`, `t_game`, `t_world`, `t_pre`...; -1 = không chạy) và `hid` (trang bị ẩn lúc mở: bỏ khỏi thống kê thời gian). Lần mở đầu trên máy yếu mất 15 đến 70 giây; các bước này cho biết vì sao.
- `boot_fail` với `stage` (`init` = chưa có WebGL, `load` = map đầu lỗi).
- `js_error` {`msg`, `at`}: tối đa 3 lần mỗi phiên.
- `gl_lost` {`map`, `ld` đang nạp, `hid`, `mem`}, `load_slow` (nạp map quá 15 giây, kèm từng bước), `load_fail` (watchdog bước 5).
- `ad_reward_recovered` {`pl`} (bước 8).
- User property `webview` để chia mọi chỉ số theo phiên bản WebView.
- `device_perf` (SDK 0.34.0): thư viện tự gửi mỗi phiên fps trung vị và p10 lúc chơi, thời gian mở tới khi chơi được (`boot_ms`, Android thêm `app_ms` tính từ lúc bấm icon), cờ lần đầu mở, RAM, tên GPU. Game chỉ cần gọi `platform.gameState('play' | 'menu')` đúng lúc (và `platform.perf.frame()` nếu tự bỏ khung để khoá fps), xem README mục 5. Team data dùng nó để chọn dòng chip chặn trên store: máy dưới 20 fps ở Crash Ramp 0.1.4 là khoảng 17% lượt cài mà gần như không có doanh thu (10/11/2026). Game đã có `run_end.fps` riêng (Crash Ramp) vẫn giữ: `device_perf` là chỉ số chung để so giữa các game.

**Đọc A/B và so hai bản.** Một nhánh chỉ thắng khi D1 và D3 không giảm. Chỉ số khác chỉ là phụ: tới ván 10, qua map 1, doanh thu quảng cáo mỗi người. Chặn nhánh nếu gỡ app trong 2 giờ, ANR hoặc thời gian mở lần đầu xấu đi. So cùng nguồn traffic, bỏ máy đã chặn, mỗi nhánh từ 100 người thật. Thêm (Crash Ramp 11/2026):
- Tính D1 theo giờ từ `first_open` của từng người (24-48 giờ), không theo `event_date`: ngày của Firebase theo múi giờ của property.
- Hai nhánh cấu hình giống hệt nhau vẫn lệch 2,4 điểm D1 ở khoảng 1000 người mỗi nhánh: chỉ tin chênh từ 4 điểm trở lên. Lúc mới 150 người mỗi nhánh, chênh từng đổi từ -6 thành +1 điểm.
- Kiểm nhánh có thật sự chạy (một A/B từng chết vì mọi offer cùng một hệ số): xem tham số của event theo nhánh trước khi đọc kết quả. Ví dụ Crash Ramp 0.1.4: nhánh nhịp nhanh (x3 xu trong 15 ván) tới ván 10 nhiều hơn (44 % so với 35 %), nhưng D1 thấp hơn (30,8 % so với 37,1 %), nên không làm mặc định.

**Chặn máy yếu trên store (Device catalog).** Dùng `device_perf` (`fps_p50` theo model và `gpu`) để quyết. Crash Ramp (11/2026): máy dưới 20 khung/giây có D1 14-17 % và doanh thu $0,0003-0,002 mỗi người; máy từ 30 khung/giây trở lên $0,073 mỗi người và làm ra 93 % doanh thu. Loại máy RAM từ 2 GB trở xuống cộng một danh sách chip yếu trong Play Console > Device catalog đưa phần người chơi dưới 20 khung/giây từ 11 % xuống khoảng 6 %, trong khi máy bị loại chỉ chiếm 0,9-3,6 % doanh thu ở nhiều game. Loại theo chip, không chỉ theo RAM (loại theo RAM thì mất cả máy 4 GB chạy tốt). Sau khi áp luật, nhóm người chơi trước và sau không so trực tiếp được.

**Mở dần hệ thống phụ.** Ván 1-5 chỉ có gameplay. Các hệ thống khác mở theo lịch ngày hoặc số ván, cái nào tới trước thì mở (Crash Ramp v103: rương ở ngày 2 hoặc ván 12, ngân hàng ở ngày 3 hoặc ván 16). Lịch mở chạy A/B được qua Remote Config.

**AppMetrica (tuỳ chọn, webgame 0.100.0).** Mặc định tắt, không có trong bản build. Game cần báo cáo AppMetrica (thị trường Nga / CIS, đối tác dùng AppMetrica) thì người dùng tạo app trên AppMetrica (một app có thể gồm Android và iOS, cùng API key) và ghi `"sdk": { "appmetrica": { "apiKey": "..." } }` trong `horus-game.json`. Không viết code gì thêm: event đi qua `platform.an.log` như cũ, app gửi cùng tên sang Firebase và AppMetrica. AppMetrica chỉ nhận event trong `eventList` (mặc định `app_open`, `loading_end`, `tut_step`, `game_start`, `game_end`, `iap_show`, `iap_purchase_success`, `iap_purchase_failed`, `ad_complete`, `ad_display_failed`); event riêng cần xem trên AppMetrica thì ghi lại cả danh sách. Doanh thu IAP, doanh thu quảng cáo, phiên, cài đặt luôn gửi (không tính vào giới hạn 3,25 triệu event/ngày của gói Free, chung cho mọi app của công ty). Crash vẫn ở Crashlytics. Khi bật nhớ khai Data safety / App Privacy: Analytics và Device IDs chia sẻ với Yandex. Chi tiết: README của webgame, mục `sdk.appmetrica`.

Robot không phải người chơi: máy Firebase Test Lab, báo cáo trước khi ra mắt của Play và máy ảo Android chạy bản release có `platform.device.robot = true`; vỏ app tự chặn tracking và quảng cáo thật trên đó (webgame 0.33.0, máy ảo từ 0.40.0). Khi đọc số liệu vẫn lọc máy của team và robot: ở Crash Ramp, 74 trên 119 "người chơi" ngày đầu là robot của Google.

**Xong khi:** chơi 3 lượt, mọi bước FTUE đã đi qua đều có trong `an.state.ftue`; mọi event có `sess`, `day`, `runs`, `build` (và `map`); tên sự kiện và tham số chữ thường, phẳng, không trùng tên Firebase giữ riêng; đủ danh sách kiểm tra ở `ANALYTICS.md` mục 12.

## 17. Settings, hỗ trợ, ngôn ngữ, màn hình

Settings có: âm thanh, nhạc, rung, thông báo, ngôn ngữ, **Contact support** (`platform.support.contact({ to: 'support@horusvn.com' })`), mã hỗ trợ (`platform.support.id`), dòng cloud save (`cloud.statusText(await platform.cloud.status())`), **Privacy Policy** (mọi vùng, mục dưới), **Privacy settings** khi `platform.ads.hasPrivacy`, **Restore purchases** khi `platform.iap.restorable`, phiên bản app.

### Quyền riêng tư: consent, Google DMA, Privacy Policy ở mọi vùng

- **Consent và Google DMA.** Ở vùng GDPR (EEA, Anh, Thuỵ Sĩ), app hiện form consent của Google (UMP, qua MAX) lúc mở lần đầu. Lựa chọn của studio (3/11/2026): mọi SDK tiếp tục đo và chia sẻ dữ liệu, kể cả khi người chơi không đồng ý. Từ app build bằng webgame 0.54.0, Adjust gắn consent DMA của Google (đọc từ câu trả lời UMP) vào lượt cài và mọi event; Adjust luôn đếm lượt cài và doanh thu. Facebook không chờ consent: đây là đánh đổi GDPR đã biết, do publisher chọn, game sau có thể quyết khác. Firebase Analytics (webgame 0.64.0, Android; iOS qua UMP) nhận cùng câu trả lời làm consent mode của GA4: người chơi EEA từ chối thì GA4 chỉ có ping không định danh. Publisher bật "consent mode" (cả hai ô advertising và analytics) trong AdMob > Privacy & messaging > European regulations. Nước ngoài GDPR cũng cần form (ví dụ Brazil, LGPD): Horus thêm mã nước vào `sdk.applovin.consentCountries` của app (webgame 0.64.0) và để message European regulations trong AdMob nhắm "Everywhere"; game chỉ hiện form ở GDPR và các nước đó. Người chơi đổi ý qua "Privacy settings" thì Adjust và Firebase nhận câu trả lời mới (AppMetrica nếu game bật: không đồng ý analytics thì ngừng gửi, không đồng ý ad user data thì không gửi GAID / IDFA). Game không phải viết gì cho việc này; đừng tự thêm SDK gửi dữ liệu cho bên thứ ba. Hộp Terms/Privacy Policy của MAX (nút CONTINUE) hiện cho mọi người chơi ngoài GDPR ở lần mở đầu, và MAX chỉ báo khởi động xong sau khi bấm: lượt cài Adjust chờ tới lúc đó, đúng như doc của MAX (khởi động MMP và analytics sau flow) và Adjust (first session delay). Người tắt app trước khi bấm thì lần đó chưa là lượt cài, lần mở sau mới tính; so lượt cài Adjust với Play sau bản phát hành đầu trên webgame 0.54.0 (chủ dự án chọn giữ như doc MAX, 3/11/2026).
- **Số liệu UA sau consent.** Tổng lượt cài và doanh thu không lệch (Adjust đếm đủ; MAX, AdMob, store không đổi). Chỉ camp Google ở EEA lệch: người chơi không đồng ý đến từ Google Ads có thể không được Google nhận, hiện là Organic trên Adjust; Google tự ước lượng phần thiếu nhờ cờ DMA. Đọc camp Google ở EU bằng cách so Adjust với Play Console và xem sự kiện `consent_state` (tỷ lệ đồng ý thật). Muốn tăng tỷ lệ đồng ý thì chỉnh form GDPR trong AdMob > Privacy & messaging (publisher quyết). Không bao giờ gửi `ad_user_data=1` cho người đã từ chối: vi phạm EU User Consent Policy của Google. Chi tiết: README của webgame, mục "Consent và Google DMA".
- **Link Privacy Policy trong Settings, ở mọi vùng.** Nút "Privacy settings" chỉ có ở vùng GDPR (`platform.ads.hasPrivacy`), không thay được link này. Chính sách User Data của Google Play muốn link chính sách quyền riêng tư ở cả hai chỗ: trong Play Console và ngay trong app. Dùng đúng URL đã khai trên store, cũng là `privacyUrl` trong `horus-game.json` (SDK 0.28.0: studio tự điền; bảng xin đồng ý của MAX ở vùng GDPR dẫn tới link này). Trong app, một link `https://` thường (`<a href="https://...">`) mở bằng trình duyệt của máy, game không rời trang. Crash Ramp v100s làm như vậy: Settings có dòng Privacy Policy cho mọi người chơi, cộng nút Privacy settings ở vùng GDPR.

Vòng đời: `platform.on('pause')` dừng game, tắt nhạc, lưu; `resume` chạy lại. Nút Back Android: `platform.onBack(() => closeTopPopup())` (trả `true` khi đã đóng một popup; ở menu trả `false` để app ra nền).

Màn hình: game phủ kín mọi máy; giữ chữ và nút trong vùng an toàn (`env(safe-area-inset-*)` trong CSS, sự kiện `platform.on('insets')`). Chữ dài theo ngôn ngữ phải tự co cho vừa nút.

Ngôn ngữ: chữ trong `src/i18n/<lang>.json`, không viết chữ thẳng trong code; tiếng Anh trước, rồi các ngôn ngữ trong `languages` của `horus-game.json`. Ngôn ngữ không phải chữ Latin cần font riêng nằm trong bản build.

### Quốc gia của người chơi khi không có mạng (Crash Ramp v100d, cờ nước ở vạch xuất phát)

- Dùng múi giờ của máy trước: `Intl.DateTimeFormat().resolvedOptions().timeZone`, đổi ra nước bằng `zone.tab` của tz database cùng các link.
  - Giữ các link: Chrome và Android WebView trả tên cũ của ICU như `Asia/Saigon`, `Asia/Calcutta`.
  - Bảng 541 múi giờ chỉ 9 KB.
- Múi giờ là UTC / GMT (máy test, máy ảo) thì dùng ngôn ngữ: vùng của `navigator.languages` đầu tiên (`vi-VN` ra VN), hoặc ngôn ngữ chỉ nói ở một nước (`vi` ra VN).
- Không tin vùng của ngôn ngữ hơn múi giờ: `en-US` rất hay gặp trên máy ở Canada, Anh và nhiều nước khác.
- Máy Windows đặt vùng không phải nước mình có một múi giờ cho nhiều nước (ví dụ "SE Asia" thành `Asia/Bangkok` cho Việt Nam, Thái Lan, Indonesia). Chỉ với các múi đó, ưu tiên nước của ngôn ngữ nếu nước đó cùng giờ (kiểm bằng `Intl` `formatToParts` ở múi giờ của nước đó).
- Cờ: flag-icons (MIT), để file giấy phép cạnh asset.
  - Mỗi cờ một ảnh WebP nhỏ, xếp nối nhau trong một file kèm bảng vị trí kết thúc của từng cờ; chỉ giải mã cờ của người chơi.
  - Một tấm lưới 2048 x 1536 tốn 12 MB khi giải mã, nguy hiểm với máy 2 GB.
  - Đừng chép file cờ qua thư mục chung của dự án (nó viết lại file bắt đầu giống WebP): chép bản gzip, hoặc dùng binary patch của git.
- Trong 3D:
  - Tấm vải tỉ lệ 4:3 như ảnh cờ để biểu tượng tròn (Nhật, Bangladesh) vẫn tròn.
  - Hai mặt, cả hai lấy mép trong (hoist) của ảnh ở phía cột (Crash Ramp v100e). Mặt sau vì thế thấy cờ bị lật như cờ thật trên cột, nên góc sao của cờ Mỹ và màu xanh của cờ Pháp luôn ở phía cột từ cả hai phía. Bản v100d cho cả hai mặt đọc xuôi, nên từ một phía góc sao của cờ Mỹ nằm ở đầu tự do.
  - Chỉ cờ có chữ (Ả Rập Xê Út, Iraq, Afghanistan, Iran, Brazil) đọc xuôi ở cả hai mặt; ngoài đời các cờ này may hai lớp để chữ không bao giờ bị lật.
  - Các tấm vải màu dùng chung material với cờ thì gắn map trắng 1 x 1 để cả hai lần vẽ dùng một shader program, menu không thêm program phải biên dịch.
  - Chỉ một lá cờ nước, ở chỗ người chơi nhìn lâu nhất (Crash Ramp v100q: lá cờ sau ná ở màn TAP TO START). Lá thứ hai ở chỗ khác trông như lỗi, không như trang trí; các cờ khác giữ màu của map.
  - Sóng vải trong vertex shader phải chạy từ cột ra đầu tự do: `offset = sin(time * w - distFromPole * k + phase) * amp * distFromPole`. Viết `+ distFromPole * k` thì đỉnh sóng chạy vào phía cột và người chơi thấy cờ "bay ngược" (Crash Ramp v100q). Ảnh chụp đứng yên không thấy lỗi này: tấm vải trông lạ khi chuyển động thì kiểm dấu trước.
- Đo nó: cờ nước là một A/B, không phải điều hiển nhiên. Tạo thử nghiệm Firebase A/B Testing trên tham số Remote Config `ab_nat_flag` (`country` / `color`), chỉ máy cài mới (First open + activation event ở lần mở đầu có giá trị); game đọc nhánh trước khi dựng cảnh đầu tiên, máy không kịp có giá trị giữ nhánh mặc định, và ghi nhánh vào `session_begin`. Không chia nhánh trong code, không làm user property (`ANALYTICS.md` mục 10). Đọc D1 / D3 / D7 theo nhánh từ lượt cài của bản có A/B (Crash Ramp data review, `queries.sql` Q14). Tham số web để thử (`?country=xx`) vẫn phải hiện cờ ở cả hai nhánh.

### Ngôn ngữ đọc phải sang trái (tiếng Ả Rập; Crash Ramp v105s)

- Lật cả giao diện: `<html dir="rtl">` khi ngôn ngữ là RTL (đặt cùng `lang` lúc đổi ngôn ngữ). Flex, grid, `text-align: start` tự lật; tiêu đề popup sang phải, ✕ sang trái, danh sách đọc từ phải.
- Đừng dùng `unicode-bidi: plaintext` trên một bố cục không lật (mỗi ô chữ tự lấy hướng của chữ mình). Crash Ramp trước v105s: tiêu đề vẫn bên trái, ✕ bên phải, và một dòng bắt đầu bằng số (`269 م`) WebKit (iPhone) canh phải còn Chrome canh trái, nên trên iPhone số mét nằm dưới hai nút đặt `right: 0` (đè 7.284 px²), Chrome trên PC không thấy.
- `text-align: left / right` viết thành `start / end` (LTR y như cũ). Phần đặt bằng `left` / `right` / margin vật lý (huy hiệu góc thẻ, ô xe có phần thò ra, núm công tắc, thanh tiến độ có chữ, mũi tên) thì viết thêm luật `:root[dir="rtl"]` đổi bên. `margin-inline` / `inset-inline` cần Chrome 87+: WebView 81 không có.
- Không lật: số, giá, km/h, cảnh 3D; dải cuộn đặt bằng `translateX` (giữ `direction: ltr` cho dải và nút trang, chữ trong thẻ `rtl`); gợi ý có hướng thật của tay ("kéo trái / phải").
- Phân số có dấu cách (`0 / 5`) bị thuật toán bidi đảo thành `5 / 0`: bỏ dấu cách trong chuỗi dịch (`{n}/{max}`) hoặc bọc số trong một span `direction: ltr; unicode-bidi: isolate`.
- Lật hình bằng `transform: rotateY(180deg)` (không đụng `scale` riêng của hình).
- Đo, đừng chỉ nhìn: mọi màn × ngôn ngữ × cỡ màn, đếm chữ đè chữ, chữ tràn khung, chữ Ả Rập canh sai phía, nút cạnh nhau dưới 8 px, và chữ ký bố cục (khung của mọi ô chữ) để chứng minh ngôn ngữ LTR không đổi (Crash Ramp `tools/rtlaudit.mjs`). Trình duyệt máy tính không giả được cách WebKit canh chữ: chèn luật canh của WebKit khi đo trên PC, rồi thử trên iPhone thật.

**Xong khi:** mỗi nút trong Settings làm đúng việc trên trình duyệt; link Privacy Policy mở được (cả khi không phải vùng GDPR); đổi ngôn ngữ không có chữ tràn nút; nút Back đóng popup trên cùng.

## 18. Kiểm tra trước khi build

Trên trình duyệt (cỡ điện thoại, CPU chậm 4 lần):
- Chơi từ save trống tới qua Map 1: không lỗi Console, không kẹt quá 3 lượt không mua được gì.
- Rewarded: xem hết thì thưởng, đóng sớm không; không có quảng cáo thì báo, không treo.
- Mua hàng: lưu trước `finish` sau, không giao hai lần, `pending()` lúc mở game, Restore.
- Interstitial đúng luật bước 10; Remove Ads bỏ được nó.
- Tải lại trang ở mọi màn: tiến độ còn.
- `horus-game.json` khớp code (placement, SKU, khoá Remote Config, sự kiện).
- Không có Google Analytics, AdSense, Firebase JS hay SDK quảng cáo nào khác; không tải gì từ CDN.

Tự động, chạy được trên cloud không có GPU (thêm 24/11/2026):
- Chạy lại một ván theo seed trước và sau mỗi thay đổi: `replay()` của `@horus/build` (đồng hồ cố định, `Math.random` theo seed, thao tác chạm và kéo ghi sẵn, chỉ vẽ ở bước lấy mẫu). `firstDifference(trước, sau)` bằng `null` là bản mới chơi ra y như cũ; khác thì có bước đầu tiên lệch và lệch ở hình hay ở chữ. Crash Ramp v104j: 30 giây game (vào game, kéo thả, xe chạy 125 m, màn kết quả) mất khoảng 46 giây trên cloud. Màn chơi đứng yên lâu (`frozen`) là dấu hiệu treo.
- Chữ trên UI: `horus-i18n shots` báo chữ tràn ô, ra ngoài màn, đè lên chữ khác và nhỏ hơn 10 px CSS (`minFont`). Crash Ramp v104j màn chính: chỉ có `km/h` 8,5 px trong đồng hồ tốc độ.
- Báo xong việc thì mỗi mục ghi rõ là đã kiểm và đạt, chỉ chạy không lỗi, hỏng, hay chưa kiểm được (và vì sao). Chưa có người chơi trên máy thật thì ghi "chưa có người chơi thử".

Trên máy thật yếu, vì trình duyệt máy tính không cho thấy hết RAM, GPU và WebView cũ:
- Firebase Test Lab, kịch bản Game Loop (`platform.testLoop`): game tự chơi khoảng 10 phút, ghi fps, qua lần đổi map và một lần giả lập quảng cáo (bước 5), rồi báo kết quả. Chọn một máy 2 GB (Galaxy A10 có WebView Chrome 81) và một máy tầm thấp khác.
- Gói Blaze của Firebase cho 30 phút máy thật mỗi ngày miễn phí, quá thì tính tiền theo phút. Giữ timeout dưới 13 phút, tối đa 2 máy một ngày, và để Test Lab lưu kết quả ở bucket mặc định (bucket riêng tính tiền lưu trữ). Test Lab sẽ dừng ngày 30/9/2027.
- Máy ảo (LDPlayer, BlueStacks): bản release coi là robot nên không có quảng cáo thật. Đừng bật quảng cáo thật trên máy ảo: mạng quảng cáo tính là traffic không hợp lệ. Kiểm đường nhẹ khi quảng cáo bằng bước giả lập.

Mạng quảng cáo (Horus làm, game không phải làm gì): adapter trong build chưa đủ, ad unit MAX của từng nền tảng còn phải bật đúng các mạng đó với id của chúng. Crash Ramp 8/11/2026: ad unit iOS chỉ bật AppLovin nên mọi mạng khác trên iOS không có lượt hiện nào; Android chưa bật DT Exchange, BIGO, GAM nên 14 ngày không có doanh thu từ ba mạng này. Horus chạy `npx webgame ads check` cho game trước khi lên store: mỗi mạng của build phải bật trong cả ad unit interstitial và rewarded, Android và iOS.

Mỗi mạng quảng cáo thêm DEX vào app. Google Play gắn cờ game có DEX trên 50 MB mà tỉ lệ obfuscation, optimization hay shrinking của R8 dưới 25 % (ảnh hưởng hiển thị trên store từ 2/2027). Crash Ramp: 13 mạng ra 50,7 MB DEX, R8 27 %; một mạng một mình khoảng 5 MB và 8.700 class giữ nguyên tên; ba mạng 14 ngày không có lượt hiện nào; bỏ từ 13 xuống 7 mạng đưa DEX từ 60 xuống 35,8 MB. Sau 14 ngày có người chơi, xem lượt hiện theo từng mạng, bỏ mạng bằng 0, và đọc ba tỉ lệ R8 trong `BUNDLE-METADATA/com.android.tools/r8.json` của AAB mỗi lần thêm hay cập nhật mạng.

**Xong khi:** mọi dòng trên đã kiểm; `node horus-sdk/horus-build.mjs --dry-run` không còn dòng `chú ý:`.

## 19. Build ra app

```
node horus-sdk/horus-build.mjs --dry-run       # kiểm gói gửi đi
node horus-sdk/horus-build.mjs                 # APK cài thử
node horus-sdk/horus-build.mjs --aab           # khi Horus đã cài đặt game (appId)
```

`--play` và `--ios` chỉ khi người dùng yêu cầu. Mỗi bản gửi store tăng `GAME_BUILD`.

Bản lên store qua cổng kiểm tra (webgame 0.72.0, `packages/webgame/RELEASE-GATE.md`). Bài học Crash Ramp 0.1.5 (38), 12/11/2026:
- Máy build Android mới cài kit bằng `npm ci` mà thiếu `sharp` (dependency tuỳ chọn). Bước làm icon chỉ ghi "icons not made" rồi build tiếp với icon mẫu (nút play trắng), và bản đó lên Play internal mà không bước nào báo lỗi.
- Cùng ngày, job iOS treo 2 giờ ở `security unlock-keychain` rồi đứt SSH: login keychain của Mac đang khoá và từ chối mở qua SSH ("User interaction is not allowed"), mà lệnh không có giới hạn thời gian.

Từ đó:
- bản release đọc lại chính file AAB / .ipa (icon so pixel với ảnh gốc, id, www, manifest so với bản trước) và chặn upload khi có gì sai hay đổi mà không khai báo (`release.expect`);
- mọi cảnh báo của job là lỗi, trừ khi được cho qua kèm lý do;
- máy build tự kiểm node_modules đủ và `sharp` load được lúc khởi động.

Thử nghiệm: vc38 bị chặn vì icon; vc39 qua 24 mục; bản cố tình làm hỏng (Firebase lạ, AdMob test id, thêm quyền) bị chặn đúng từng lỗi. Trước khi bấm production vẫn tự xem icon / splash của bản mới cạnh bản trước (bước đầu của kiểm tra phát hành; Horus: `npx webgame release-gate <mới>.aab --prev <trước>.aab --icons so-sanh.png`).

**Bài học build 14-16/11/2026 (Crash Ramp 0.1.7, Little Wukong).**
- Tên app = `name` trong horus-game.json, trên cả Android và iOS (webgame 0.85.5). Đặt ngắn: màn hình chính thường chỉ hiện 12 đến 14 ký tự đầu. Đổi tên thì phải build lại; bản đã gửi trước đó vẫn mang tên cũ (Little Wukong vc10 vẫn hiện "IdleJourney").
- Job bị từ chối "SDK cũ" ngay sau khi lệnh vừa tự cập nhật SDK: lệnh cũ (trước SDK 0.38.5) gửi số phiên bản đọc trước lúc cập nhật. Gửi lại một lần là qua; từ 0.38.5 không còn lỗi này. Sau mỗi lần SDK tự cập nhật, build lại bản web (`--build-web`) để app dùng SDK mới.
- `android.baselineProfile`: profile ghi trên máy chạy thử có lúc không vào bản release (Crash Ramp 0.1.7, job trên máy build Windows, log vẫn báo không có cảnh báo). Từ webgame 0.85.3 job báo `[BASELINE_PROFILE]` và cổng kiểm tra chặn bản đó; từ 0.85.4 job trên Windows build trong thư mục ngắn không dấu cách. Gặp `[BASELINE_PROFILE]` thì gửi lại; lặp lại thì tắt switch và báo Horus.
- Build lỗi Gradle: lời báo của job trích đoạn "What went wrong" của Gradle (webgame 0.85.6); đọc đoạn đó trước, không đọc phần cuối log. Cả log Gradle nằm trong zip của job (`gradle.log`).

**Phát hành từng phần (bài học Crash Ramp 10-11/2026).**
- Mỗi bản gửi store phải build lại phần web từ code mới nhất (`--build-web`): ba bản store của Crash Ramp từng ra mà JS sửa lỗi không có trong đó vì gửi `www` cũ. Hash `www` trong AAB phải bằng bản build của master.
- Thử trước khi lên: so manifest và thư viện của AAB với versionCode đang chạy, cài đè lên bản cũ đang có save (save cũ đọc được ở bản mới), chơi một ván, xem quảng cáo, mua thử.
- Production theo từng phần: 20 % trước, đọc Crashlytics và Android vitals sau khoảng 6 giờ và 24 giờ, rồi mới 100 %.
- Google Play: tắt **Automatic protection** (Play Console > Test and release > App integrity) trước khi lên production. Lớp bảo vệ này bọc `onPause` trong máy ảo của nó và nạp một class chỉ có từ Android 10: Crash Ramp 0.1.5 crash ở 5-6 trên 7 người chơi Android 8-9 (0 ở bản trước). Thử mỗi bản trên một máy ảo Android 8 hay 9.
- Không sửa Play Console trong lúc một lần upload Play đang chạy: lần commit đó hỏng (400 `FAILED_PRECONDITION`), và mỗi lần upload hỏng mất một versionCode.

Cập nhật nóng (bản web mới tới người chơi không qua store, `packages/webgame/HOT.md`) mặc định tắt; Horus bật cho từng game. Chỉ cho JS, ảnh, âm thanh, dữ liệu; code native, SDK, icon vẫn cần bản store. Bản nóng đặt `--id` trùng build tag của game. Người dùng thích bấm thì mở trang build: `node horus-sdk/horus-build.mjs ui` (Windows: bấm đúp `horus-sdk\HorusBuild.cmd`). Lỗi thì đọc dòng lý do và log; gửi mã job cho Horus nếu cần.

Ảnh UI nướng sẵn hay kèm theo app (thumbnail, icon có alpha): WebP chất lượng khoảng 0,9 với alpha lossless, không dùng PNG. Mã hoá bằng chính trình duyệt dùng để nướng (`OffscreenCanvas.convertToBlob({ type: 'image/webp', quality })`) và bỏ chunk ICCP (WebP không gắn profile là sRGB, điểm ảnh giải ra y hệt); chỉ giữ PNG dự phòng khi trình duyệt không mã hoá được. WebP chạy được ở mọi nơi kit ship (Android WebView, WKWebView iOS 14+, Safari 14+). Crash Ramp v100t: 36 thumbnail xe từ 1,64 MB PNG xuống khoảng 0,36 MB. Đo phần một bản thêm vào bằng so từng file trong hai AAB của job (cỡ nén của `base/` cho một ABI), không tin con số "so với bản trước" của Play (lệch 4 MB với nội dung AAB của Crash Ramp 0.1.2).

### Bản cho video editor (bắt buộc)

**Mặc định từ SDK 0.41.0:** `node horus-sdk/horus-build.mjs --web` đưa game lên Horus Play và trang đó **là** bản cho video editor, có đủ các mục dưới (game web: Horus Play gắn bảng vào trang, README mục 12 "Bản cho video editor"; game Godot: addon 0.7.0, GODOT.md mục 10). Việc của game chỉ còn khai báo mục Mở khoá (`platform.video.cheat` / `number`, Godot `Horus.video.cheat` / `number`) và đặt `id` / `name` cho các phần UI chính, rồi góc máy, kịch bản có sẵn, công tắc (`platform.video.cameras` / `shot` / `toggle` / `guide`) theo `horus-sdk/video/GAME-SETUP.md`; agent quay clip bằng `horus-sdk/video/rec.mjs`. Link bản cho video editor là link Horus Play của game. Cách cũ dưới đây (module riêng trong game, như Crash Ramp `src/creative.js`) chỉ còn cho game cần công cụ riêng hơn.

Mỗi game làm thêm một bản web riêng cho đội làm video quảng cáo: chính game đó cộng một bảng công cụ để quay. Đội video không đọc code; họ cần dàn cảnh nhanh rồi quay màn hình. Crash Ramp: link artifact riêng (`node build.mjs --creative`), code `src/creative.js`.

Bản này phải có:
- Nút mở bảng (góc màn, ví dụ 🎬) và phím tắt (E). Bảng không che game khi quay.
- **Chỉnh UI trên màn:** chạm chọn một phần UI, kéo để dời, lăn chuột / chụm 2 ngón để đổi cỡ; thanh trượt Ngang / Dọc / Cỡ / Mờ; nút ẩn từng phần; nút ẩn toàn bộ UI; hiện HUD ở menu để chỉnh.
- **Ẩn để quay** (phím R): ẩn bảng và nút mở bảng; hiện lại bằng phím E hoặc chạm 3 ngón.
- **Điều khiển cảnh:** dừng hình (F), tốc độ 0.1x đến 2x.
- **Tiến độ giả:** cộng xu, cộng gem, mở mọi map, đặt cấp nâng cấp của map đang chơi (+/-, gõ số, "tất cả 0", "tất cả max"), nạp lại màn để hình xe/đồ đổi theo.
- **Layout lưu được:** tự lưu trên máy; lưu theo tên; Copy mã / Xem mã / Nhập (dán mã hoặc chọn file .json) để chuyển cho người khác. Artifact không có `confirm()` và không tải file xuống được, nên chuyển layout bằng mã JSON.

Cách làm:
- Một module riêng (`src/creative.js`), bật bằng cờ build (`--creative` ra `dist/creative/`, hằng `__CREATIVE__`). Bản store không chứa nó: esbuild bỏ hẳn module, `dist/fragment.html` của bản store cùng cỡ như khi chưa có.
- Danh sách phần UI chỉnh được để một chỗ (`GROUPS`, theo id / class của game). Đổi id hay class UI thì sửa danh sách này.
- Mọi class bảng thêm vào đều có tiền tố riêng (`cr-`): Crash Ramp từng có bảng không nhận chuột vì class `side` trùng rule `.side{pointer-events:none}` của game.
- Kiểm bằng chuột thật (`page.mouse` của Playwright) bấm vào từng nút của bảng, ở cỡ điện thoại và màn rộng; `el.click()` không bắt được lỗi trên.
- Mỗi bản game mới đã qua kiểm tra thì build lại bản này và cập nhật cùng link, để đội video luôn quay bản đang lên store. Link để riêng tư; người dùng tự share cho đội video.

### Bản playable cho marketing (bắt buộc)

Mỗi game làm thêm bộ playable ad cho đội marketing up lên mạng quảng cáo, và một trang xem thử. Crash Ramp: trang https://claude.ai/artifact/Mktm7CUBADtoW7nWKbqMak, code `dev\CrashRamp-playable` (changelog `CHANGELOG.md`, file ra ở `dist\v<N>\`). Cách đóng gói cho từng mạng: skill `playable-ad-network-export`.

Bộ playable phải có:
- **Biến thể theo order của marketing** (Crash Ramp: 6 biến thể V1-V6 trong Sheet, mỗi biến thể một map, một xe, một kiểu thua, một cao trào).
- **Một file cho mỗi mạng**, mỗi file dưới 5 MB, up thẳng không phải sửa. Crash Ramp: Google Ads (zip, index.html + ExitApi), AppLovin (một HTML, MRAID), Unity Ads (một HTML, MRAID), Mintegral (zip, `<tên>/<tên>.html`), Moloco (một HTML), Facebook / Meta (zip, index.html + game.js). Tên file ghi biến thể, mạng và bản: `<Game>_V3_unity_v1.html`.
- **Vòng chơi ngắn đúng lõi game:** lượt đầu thua (FAIL), nâng cấp vài lần (bắt buộc bấm đủ mới chơi tiếp), lượt sau thắng qua cao trào, end card PLAY NOW + Replay, nút DOWNLOAD luôn hiện. Dựng bằng chính hình và đường của game, không cắt cảnh giữa lượt.
- Chạy cả màn dọc và ngang; chỉ tiếng hiệu ứng (nhạc chưa có bản quyền thì không đưa vào); chữ tiếng Anh; tiếng bật sau lần chạm đầu.
- **Trang xem thử:** chọn biến thể, chơi trong khung điện thoại, mở toàn màn hình, kịch bản của biến thể, link thư mục tải cả bộ file, và nhật ký phiên bản (mỗi vòng góp ý của marketing là một bản mới, ghi rõ đã đổi gì).
- File cho mạng để ở một thư mục Google Drive ai có link cũng tải được (Crash Ramp không dùng Cloudflare cho việc này).

Làm khi game đã chơi được và chốt hình; mỗi vòng góp ý của marketing thì tăng số bản, build lại cả bộ, cập nhật cùng trang và thư mục.

**Xong khi:** có APK trong `build-online/`, cài vào máy Android mở được, chơi một lượt có quảng cáo thử; có link bản cho video editor của đúng bản game này, mọi nút trong bảng đã bấm thử bằng chuột thật; có trang playable và file cho từng mạng (mỗi file dưới 5 MB, đã chơi thử hết vòng tới end card).

## 20. Để được store feature (App Store, Google Play)

Không store nào có checklist bắt buộc: biên tập chọn theo chất lượng, trải nghiệm, trợ năng, ngôn ngữ, trang store và nội dung theo mùa. Làm từ đầu thì rẻ hơn làm sau (Crash Ramp, 24/10/2026).

Trong game:
- **Trợ năng.** Settings có "Reduce motion" (theo `prefers-reduced-motion` của máy cho tới khi người chơi tự bật tắt: rung camera, chớp màn hình, hiệu ứng màu giảm còn khoảng 30%, animation lặp của menu chạy một lần) và "Larger text" (chữ nhỏ dưới 18px phóng 1,2-1,3 lần; mặc định bật khi `platform.info.fontScale` từ 1,3). Mọi nút có chữ hoặc `aria-label`, công tắc có `role="switch"` + `aria-checked`. Vùng chạm từ 48px (thêm vùng chạm vô hình bằng `::before` nếu nút nhỏ hơn). Chữ phụ tương phản từ 4,5:1 với nền.
- **Game Center / Play Games** (`platform.games`, module `games`): bảng xếp hạng (quãng đường xa nhất mỗi map, mùa cao nhất) và ít nhất 10 thành tích, ít nhất 4 cái đạt được trong giờ chơi đầu, tối đa 1 cái trong 5 phút đầu. Đọc từ save, gửi lại tất cả khi có sự kiện `'games'` `{ signedIn: true }` (store giữ điểm cao nhất, bỏ qua mở khoá lần hai). Nút "Leaderboards / Achievements" trong Settings khi `platform.games.signedIn`. Khoá bảng và thành tích là hợp đồng: không đổi nghĩa khi đã lên store.
- **Sự kiện theo mùa** có thật trong game (không phải quà hằng ngày hay giảm giá): đó là nội dung cho In-App Events (iOS) và Promotional content (Play).
- **Kiếm tiền không làm phiền:** không mời mua ngay khi vào game, không chèn quảng cáo giữa màn, offer đúng lúc (bước 13).
- **Ổn định:** crash dưới 1,09%, ANR dưới 0,47% (Android vitals, 28 ngày); dưới 30 fps là mất điểm.

Ngoài game (Horus làm với tài khoản store):
- Game Center: bật cho app trong App Store Connect, tạo bảng và thành tích cùng khoá (ảnh thành tích 1024x1024), gửi duyệt cùng bản app. Play Games: tạo trong Play Console, chép mã project và id từng bảng, thành tích (dạng `CgkI...`, icon 512x512) vào `sdk.games` của `horus-game.json` (`projectId`, `leaderboards`, `achievements`, README mục 12); publish ít nhất 2 giờ trước khi game lên.
- Đề cử Apple: App Store Connect > Featuring > Nominations, ít nhất 3 tuần trước ngày muốn lên, tốt nhất 3 tháng.
- In-App Event: tên 30 ký tự, mô tả 50 và 120; ảnh 16:9 1920x1080 và 9:16 1080x1920, không chữ, không logo; 15 phút tới 31 ngày. App Store Connect không cho nộp event thiếu "Event deep link": bản app trên store phải có `urlScheme` (`horus-game.json`, SDK 0.30.0) và game mở thẳng màn sự kiện với `<urlScheme>://event` (`platform.link.opened` lúc mở, sự kiện `'link'` lúc đang chạy; README mục 11). Promotional content Play: ảnh 1920x1080 không chữ, tagline 80, mô tả 500, tối đa 4 tuần, gửi trước ít nhất 4 ngày.
- Trang store: video gameplay 15-30 giây (iOS) và YouTube (Play), ảnh có chữ bản địa cho thị trường lớn, nhãn trợ năng App Store chỉ khai cái game đạt thật (Larger Text cần chữ 200%, Reduced Motion không khai được nếu quảng cáo video không giảm được chuyển động).

**Xong khi:** Settings có Reduce motion, Larger text và (trong app) Leaderboards / Achievements; mọi nút từ 48px; README của game ghi khoá bảng và thành tích; có ít nhất một sự kiện mùa chạy được trong game.

## 21. Crash và ANR sau khi ra mắt

Crash và ANR là lỗi nặng nhất: người chơi gặp một lần là hay gỡ game, và Google Play hạ hạng game vượt ngưỡng (crash 1,09%, ANR 0,47% người dùng trong 28 ngày). Đọc Crashlytics mỗi ngày trong tuần đầu của mỗi bản, rồi mỗi tuần.

**App tự bắt gì.** Android: crash Java, crash native (NDK, có symbol), ANR (Android 11 trở lên), WebView renderer chết. iOS: crash (có dSYM), treo máy, quá CPU và bị hệ thống giết (MetricKit), tiến trình web bị tắt. Lỗi JavaScript thì chỉ lên khi game gọi `platform.crash` (bước 4). Mỗi báo lỗi có sẵn phiên bản app, module, kích thước save và mọi user property (kể cả `webview`); thêm chỗ người chơi đang đứng bằng `platform.crashKeys({ map, screen })`.

**Đọc cho đúng.**
- Đếm người chơi, không đếm sự kiện: ở Crash Ramp, một máy Vivo còn ở bản cũ gửi 13 báo cáo "renderer gone".
- Xem bản nào. Người chơi không cập nhật vẫn gửi lỗi của bản cũ; lỗi đã sửa thì chỉ xét trên bản mới.
- Event `boot` mất ở khoảng 4-5 % lần mở, kể cả với người chơi sau đó vẫn chơi (event ở ngay đầu lần mở đôi khi không tới). "Vào game" đếm bằng `run_start` hoặc tham số `runs`, không bằng `boot`: Crash Ramp từng tưởng bản mới tụt "boot 86 % so với 94 %" mà thật ra là lỗi đo.
- Lượt cài chỉ có event tự động của Firebase (`first_open`, `session_start`, `screen_view`) mà không event game nào là robot hay máy pre-launch của Google: kiểm robot của app chạy sau mấy event đó. Báo chúng thành nhóm riêng, không gộp vào người chơi thật.
- Bỏ robot: máy báo cáo trước khi ra mắt của Google Play, Firebase Test Lab, máy ảo. ANR `nativePollOnce` trên máy test của Google không phải người chơi.
- `renderer_gone` (sự kiện analytics, `state` `fg`, `ad` hoặc `bg`): `bg` là hệ thống lấy lại RAM khi app ở nền, không phải crash, và không lên Crashlytics. Chỉ `fg` (đang trên màn hình) và `ad` (dưới quảng cáo) là lỗi người chơi thấy. Từ webgame 0.68.0 sự kiện có thêm `net` (mạng của quảng cáo đang hiện), `ram` (GB của máy) và `ad` (1 = lúc đó có quảng cáo mở); `ad` chỉ còn khi app đang ở trước màn hình. Crash Ramp 0.1.2: 116/120 báo cáo "dưới quảng cáo" là app đã ở nền (người chơi bấm Home hay bấm quảng cáo sang store giữa chừng), người bị tắt quay lại chơi như người không bị (72 % / 71 % trong 1 giờ): đó là Android lấy RAM của app nền, chỉ cần quay lại êm (`platform.device.relaunch`, trả thưởng bằng `platform.ads.lost`). Xem `process_state` của Crashlytics trước khi coi một lỗi là người chơi thấy.
- Xem sự kiện analytics ngay trước lỗi: Crash Ramp tìm ra renderer chết dưới quảng cáo thưởng nhờ thấy `rv_start` rồi `boot` mà không có `rv_done`, và tìm ra chạm hai lần nhờ hai `rv_start` cách nhau 30-70 ms. Nhưng kiểm trước xem có phải mọi sự kiện của máy đó đều lặp không: một iPhone XR gửi mọi sự kiện hai lần cách nhau 0,23 giây, đó là analytics lặp, không phải người chơi chạm hai lần.
- Đọc qua BigQuery (Firebase export): bảng hằng ngày và bảng `_REALTIME` có cột khác nhau, truy vấn riêng; tên luồng là `threads[].thread_name`. Truy vấn hẹp (vài ngày, vài cột) để rẻ.

**Lỗi đã gặp và cách sửa** (Crash Ramp, 10-11/2026):

| Thấy gì | Vì sao | Sửa |
| --- | --- | --- |
| Crash nặng SIGTRAP trong `libwebviewchromium` `draw_gl`, dưới video quảng cáo | Chạm hai, ba lần vào nút quảng cáo; lần sau trả "không có quảng cáo", game vẽ lại cảnh 3D và bật nhạc ngay dưới video | Mỗi lúc một quảng cáo: `platform.ads.busy()`, gặp `busy` thì không đổi gì (bước 8, SDK 0.26.1) |
| Xem hết quảng cáo thưởng mà không được thưởng, game mở lại ở menu | Máy ít RAM tắt trang web dưới quảng cáo | Nhẹ khi quảng cáo che game (bước 5), trả thưởng bằng `platform.ads.lost` (bước 8) |
| ANR trong `RenderThread` `draw_gl` lúc mở game lần đầu 53 giây | Mở game quá lâu trên máy yếu | Mở game nhanh (bước 5) |
| Đứng mãi ở màn tải Map 2 trên máy 2 GB | Code nạp map chờ khung hình không giới hạn khi RAM gần hết | Luật nạp map và watchdog (bước 5) |
| Lỗi JS `tick` rồi kẹt màn tải, khi app bị chuyển ra nền ngay lúc mở | Timer cần WebGL chạy trước khi có WebGL | Không đặt timer cần WebGL trước khi có (bước 5) |
| Trang tải lại hay kẹt trên WebView 80-87 | API mới hơn WebView (`animate` keyframe thiếu, `getAnimations`, `replaceAll`, `:where()`) | Build cho Chrome 80, `@horus/webgame/compat`, tự tránh phần polyfill không cứu được (bước 5) |
| iPhone mất nhạc, lỗi JS "Decoding failed" | Nhạc `.ogg` | Dùng `.mp3` (bước 5) |
| Một iPad không tạo được WebGL | Có thể do Lockdown Mode (chưa chắc) | Gửi `boot_fail` `stage: 'init'` (bước 16), hiện một dòng báo thay vì màn đen |
| Màn tải đứng mãi trước khi map nạp, không lỗi JS nào (chờ platform, cloud save, ngôn ngữ) | Một promise lúc khởi động trả lời rất chậm hoặc không bao giờ; watchdog của bước nạp map chưa chạy tới | Watchdog cho cả phần khởi động (Crash Ramp v106b `src/bootwatch.js`): mỗi bước khởi động nuôi nó, 30 s trên màn hình không có bước nào thì gửi `boot_stuck` {stage, idle, hid}; không tính lúc app ở nền hay timer về trễ hơn 15 s. ĐỪNG tự tải lại: Crash Ramp 13-19/11, người cài mới Android: 8 % có lần mở ≥ 30 s vẫn vào được (p99 56 s), chỉ 0,6 % không vào được. Mọi lần tự tải lại khác (mất WebGL dưới màn tải...) giới hạn số lần mỗi lần mở (sessionStorage), storage ném lỗi thì KHÔNG tự tải lại |
| Lần mở đầu tiên sau khi Play tự cập nhật: log `Firebase did not start`, cả phiên không Analytics, Remote Config về giá trị mặc định, không Crashlytics (Crash Ramp vc5, OPPO A15, 8/11) | Android mở app ở nền ngay sau khi cài (đặt lại lịch nhắc) lúc Automatic protection của Play còn chạy app tạm, không ContentProvider nào chạy; người chơi mở game vào đúng process đó | Kit 0.64.1 tự sửa (`ProcessGuard`): build lại game bằng kit mới, không cần tắt Automatic protection. Activity, receiver, service riêng của game gọi `ProcessGuard` như vỏ |
| `ClassNotFoundException` (một class Android 10+) trong `onPause`, stack có `com.pairip.VMRunner`, chỉ Android 8-9, chỉ bản mới (Crash Ramp 0.1.5) | Automatic protection của Google Play bọc `onPause` và nạp class mới hơn máy | Tắt Automatic protection trong Play Console; kit (từ webgame 0.75.0) tách code API mới ra hàm riêng `@NewerApi` và kiểm DEX khi build |
| Crash native `libGLESv2_powervr` 2-5 giây sau khi mở, hoặc `gl_lost` rồi `boot_fail`, chỉ Pixel 10 / 10 Pro, Android 17, WebView 156+ | Driver PowerVR D-Series qua ANGLE, khi lấy mẫu shadow map | Chế độ an toàn GPU theo model và GPU, khớp hẹp (bước 5, "Máy yếu và WebView cũ") |
| SIGSEGV trong WebView trên máy chỉ còn 151 MB RAM trống | Lỗi của WebView, không do game | Theo dõi, không sửa gì |
| ANR lúc mở app, luồng chính trong `WebGameActivity.newWebView` chờ trong native (`ConditionVariable::WaitHoldingLocks`) (Crash Ramp 5/11) | Lần tạo WebView đầu tiên của process nạp gói WebView và khởi động Chromium ngay trên luồng chính | Kit webgame 0.65.2 tự sửa: WebView khởi động trên luồng riêng từ lúc app mở, activity tạo WebView khi xong (splash vẫn hiện; WebView không trả lời thì muộn nhất 15 s). WebView cũ chưa có khởi động không đồng bộ vẫn làm phần của Chromium trên luồng chính, thành một task riêng. Build lại game bằng kit mới |
| ANR trong `WebGame.isRobot` (`Settings.System.getString` trong `Application.onCreate`) (Crash Ramp 7/11) | Đọc cờ Test Lab qua ContentResolver trên luồng chính, lúc hệ thống bận | Kit webgame 0.65.2 tự sửa: đọc trên luồng riêng, lần mở sau dùng câu trả lời đã lưu. Build lại game bằng kit mới |
| ANR trong Mintegral `OtherDeviceInfoProvider` (`AudioManager.getStreamVolume`, chờ binder) (Crash Ramp 4/11) | SDK Mintegral 17.1.81 gom thông tin máy trên luồng gọi | Mintegral 17.2.21 gom trên thread pool, có hẹn giờ. Horus nâng adapter trên máy build (Crash Ramp 9/11); build lại app |
| ANR trong Mintegral `CampaignDao` (`SQLiteDatabase.update` trên luồng chính, sau video thưởng) (Crash Ramp 7/11) | SDK Mintegral ghi database trên luồng chính | Chưa có bản sửa (17.2.21 giữ nguyên đoạn này). Theo dõi; ít người gặp |

**Mỗi lỗi mới, làm theo thứ tự:**
1. Bản nào, bao nhiêu người chơi thật, máy và WebView nào.
2. Stack, key, và sự kiện analytics trước lỗi của vài người chơi đó.
3. Làm lại được lỗi: điện thoại cắm USB (`adb`), máy ảo Android, Firebase Test Lab trong quota miễn phí, Chrome bản cũ cho lỗi WebView cũ.
4. Sửa, kèm một test hỏng trên code cũ và qua trên code mới; nếu cần đo thêm thì thêm một sự kiện analytics cho đúng chỗ đó (Crash Ramp thêm `ad_dup`).
5. Ra bản mới. Chỉ nói "đã hết lỗi" khi người chơi đã lên bản đó và Crashlytics cùng sự kiện mới không còn thấy lỗi.

**Xong khi:** game gọi `platform.crash` cho `error` và `unhandledrejection`, có `platform.crashKeys` ở mỗi màn; một lỗi thử (`throw` trong Settings bản test) hiện trên Crashlytics kèm map và màn; có một người được giao đọc Crashlytics mỗi ngày trong tuần đầu.
