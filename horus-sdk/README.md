# Horus SDK

Một file JavaScript cho game HTML5 (JS/TS, Phaser, Three.js, Cocos, PixiJS, Unity WebGL...) để chạy trong app Android và iOS của Horus: quảng cáo, mua trong app, analytics, Remote Config, lưu game, cloud save và thông báo; kèm logic kiếm tiền, giữ chân, kinh tế và công cụ three.js của Horus (mục 13).

Cách làm giống AppLovin MAX: anh/chị gắn SDK vào game và gọi API. Id của app (ad unit MAX, Adjust, Facebook, file Firebase, licence key Play) anh/chị tự điền vào `horus-game.json` (mục 12, "Id của app"). Horus tích hợp SDK vào app, build, ký và đưa lên store. Anh/chị không cần Android Studio, Xcode hay tài khoản nào của Horus.

## Trong gói có gì

| File | Dùng để |
| --- | --- |
| `horus-sdk.js` | SDK cho thẻ `<script>`: tạo biến toàn cục `HorusSDK` |
| `horus-sdk.mjs` | Cùng SDK, dạng ES module: `import { platform, start } from './horus-sdk.mjs'` |
| `horus-logic.mjs` | Chỉ `monetize`, `liveops`, `economy` (ES module, không cần trình duyệt): cho Web Worker hay Node (mục 13) |
| `horus-sdk.d.ts` | Kiểu của API cho TypeScript và gợi ý trong editor |
| `horus-build.mjs` | Lệnh Node: gửi bản build web cho Horus, nhận lại APK/AAB (mục 12) |
| `HorusBuild.cmd` | Windows: bấm đúp mở trang build (mục 12) |
| `example/` | Game mẫu đủ một thư mục: xu, xem quảng cáo, mua hàng, lưu game, `horus-game.json` |
| `horus-game.json` | Mẫu thông tin game gửi Horus |
| `AGENTS.md` | Quy tắc cho AI agent (Claude Code, Cursor, Codex...) làm game three.js (HTML5) với SDK |
| `godot/` | Game Godot 4.7: addon `addons/horus_sdk`, game mẫu, `README.md` (hướng dẫn), `AGENTS.md` (quy tắc cho AI agent) |
| `GAME-GUIDE.md` | Từng bước làm một game như Crash Ramp: vòng chơi, kinh tế, quảng cáo, shop, offer, lưu, analytics, build, hiệu năng máy yếu, crash |
| `ANALYTICS.md` | Analytics chuẩn Horus: bộ event, tham số và user property chung mọi game gửi (theo Crash Ramp), và cách team data đọc số |
| `CHANGELOG.md` | Các bản SDK |

Chạy game mẫu: mở thư mục gói bằng một web server bất kỳ (`npx serve .` hoặc Live Server của VS Code), vào `example/index.html`.

Làm game mới: đưa agent đọc `GAME-GUIDE.md` và làm từng bước (mỗi bước có mục "Xong khi").

Dùng AI agent: chép `AGENTS.md` vào gốc repo game (hoặc thêm một dòng vào `AGENTS.md` / `CLAUDE.md` sẵn có: "Đọc horus-sdk/AGENTS.md trước khi sửa phần quảng cáo, mua hàng, lưu game, hiệu năng hay build"). Game Godot thì chép `godot/AGENTS.md`.

## 1. Gắn SDK

```html
<script src="horus-sdk.js"></script>
<script src="game.js"></script>
```

hoặc với bundler / ES module:

```js
import { platform, save, start } from './horus-sdk.mjs';
```

Với TypeScript: thêm `horus-sdk.d.ts` vào project (`/// <reference path="horus-sdk.d.ts" />` cho bản script, hoặc để cạnh `horus-sdk.mjs`).

Cùng một file chạy được ở cả hai nơi. Trên trình duyệt, quảng cáo và mua hàng là giả lập để anh/chị thử game. Trong app của Horus, SDK tự nói chuyện với app và dùng quảng cáo, store thật. Không cần sửa code giữa hai nơi.

## 2. Khởi động

Gọi một lần, trước khung hình đầu tiên, rồi báo game đã hiện:

```js
const { platform } = HorusSDK;

await HorusSDK.start({ skus: ['coins_100', 'remove_ads'] });   // các SKU game bán
// ... dựng màn hình đầu tiên ...
platform.ready();   // app tắt màn hình chờ
```

`start()` lấy thông tin app, Remote Config, giá trên store, bản lưu dự phòng và kiểm tra cloud save. Cloud save có sẵn; `start({ cloud: false })` để tắt. Máy chưa có save (cài lại) thì `start()` chờ server cloud tối đa 3 giây để lấy lại tiến độ; đổi bằng `start({ cloudWait: 5000 })`.

## 3. Quảng cáo

**Quảng cáo sẵn sàng sau khi game lên (webgame 0.79.0).** MAX khởi động 1,5 giây sau `platform.ready()` (muộn nhất 10 giây), để không tranh CPU lúc game tải. Gọi `rewarded` ngay sau `ready()` nhận `not_ready`. Nút xem quảng cáo sáng theo `platform.ads.ready()` và sự kiện `'ads'`, không giả định có quảng cáo lúc mở game.

```js
// Rewarded: chỉ thưởng khi ok = true
const r = await platform.ads.rewarded('double_coins');
if (r.ok) coins *= 2;
// r.reason khi không xem xong: 'closed' | 'not_ready' | 'error' | 'busy'
// 'busy': quảng cáo trước còn đang mở (chạm hai lần): không đổi gì cả, không trả bộ đệm vẽ, không bật nhạc

// Interstitial: giữa hai màn, game không cần chờ kết quả; không gọi khi platform.ads.busy()
if (!platform.ads.busy()) await platform.ads.inter('level_end');

// Nút "Xem quảng cáo" chỉ sáng khi có quảng cáo
const ready = platform.ads.ready();          // { rv, inter }
platform.on('ads', (s) => { rvButton.disabled = !s.rv; });
platform.ads.load('rv');                     // sắp mời xem quảng cáo (màn kết quả, shop)
```

Tên placement là chữ thường, không dấu, ví dụ `double_coins`. Ghi đủ placement vào `horus-game.json`.

**rv swap (webgame 0.90.0, mặc định bật).** Khi người chơi bấm nút rewarded, SDK hiện interstitial đã load thay cho rewarded nếu MAX định giá interstitial cao hơn (`swap` 1), hoặc nếu chưa có rewarded nào load mà có interstitial (`swap` 2). Interstitial hiện xong thì `ok` là true: trao **đúng** phần thưởng của nút. Code thưởng không đổi; chỉ cần:

```js
// nút sáng / "không có video": hỏi rewardable thay cho ready().rv
rvButton.disabled = !platform.ads.rewardable('double_coins');
track('rv_start', { pl: 'double_coins', swap: platform.ads.swapOf('double_coins') });
const r = await platform.ads.rewarded('double_coins');   // { ok, reason, swap }
if (r.ok) { coins *= 2; track('rv_done', { pl: 'double_coins', swap: r.swap }); }
// tắt cho cả game: platform.init({ rvSwap: false }); lúc chạy: platform.ads.rvSwap(false)
// chỉnh: platform.init({ rvSwap: { margin: 0.1, noRv: false, skip: 'revive' } }); Remote Config wg_rv_swap = 0 tắt từ xa
```

Luật: chỉ khi người chơi tự bấm nút xem quảng cáo có thưởng. Quảng cáo đổi vào là phần thưởng, không phải interstitial bắt buộc: không tính vào nhịp interstitial (`monetize.noteRewarded`, không `noteInter`), người đã mua Remove Ads vẫn nhận (họ tự bấm để lấy thưởng; interstitial bắt buộc của họ vẫn tắt). Không bao giờ làm ngược lại: không hiện rewarded như một interstitial bắt buộc, không đổi khi người chơi không bấm. Nút ghi rõ là xem quảng cáo (biểu tượng video), như mọi nút rewarded. Analytics SDK tự gửi `rv_swap` `{ pl, swap, shown, rv_v, iv_v }`.

**Big ad offer (webgame 0.93.0, mặc định tắt).** Khi ad đã load đáng giá cao (MAX ước tính một lượt ≥ `minUsd`, mặc định $0.2), game hiện một thẻ nổi bật "xem 1 video, nhận thưởng lớn"; `showBig` hiện **đúng** ad đó. SDK chọn ad, giữ giới hạn và gửi analytics; game vẽ thẻ và quyết phần thưởng theo `tier`:

```js
await platform.init({ bigAd: true });   // hoặc { minUsd: 0.3, perDay: 2, cooldownMin: 30, tiers: [0.3, 0.6, 1.2, 2.5] }
const o = platform.ads.bigAd({ pl: 'big_ad' });   // { ok, reason, usd, fmt: 'rv' | 'inter', net, tier }
if (o.ok) ui.bigCard({ gems: GEMS_BY_TIER[o.tier] });   // bảng thưởng của game
// bấm thẻ:
const r = await platform.ads.showBig('big_ad');   // { ok, reason, usd, fmt, tier }: trao đúng số trên thẻ
if (r.ok) { addGems(GEMS_BY_TIER[o.tier]); save(); } else if (r.reason === 'changed' || r.reason === 'gone') redrawCard();
// Remote Config wg_bigad = 0 tắt từ xa; wg_bigad_min, wg_bigad_per_day, wg_bigad_cooldown_min, wg_bigad_tiers chỉnh
```

Giới hạn mặc định: 3 lần trả thưởng một ngày (ngày trên máy, chung mọi placement), 20 phút giữa hai lần, không trong phiên đầu sau khi cài, không trên máy Test Lab / pre-launch. `formats: ['rv']` nếu chỉ muốn rewarded. Ad lúc bấm rẻ hơn lúc mời thì `showBig` trả `changed` và không hiện. Trang chết dưới rewarded của thẻ: trả từ `platform.ads.bigLost` (đã đếm vào giới hạn), bỏ qua dòng `big_ad` của `ads.lost`. Như rv swap: chỉ khi người chơi tự bấm, nút ghi rõ là xem quảng cáo; không tính vào nhịp interstitial. Analytics SDK tự gửi `bigad_offer` / `bigad_tap` / `bigad_done` / `bigad_fail`. Chi tiết và ví dụ đầy đủ: GAME-GUIDE mục 8.

Trong khi quảng cáo chạy, app gửi `pause` (`reason: 'ad'`), xong thì `resume`: tắt nhạc và dừng game theo hai sự kiện này.

Vùng GDPR: khi `platform.ads.hasPrivacy` là true, Settings cần một nút "Privacy settings" gọi `platform.ads.privacy()`. Ngoài nút đó, Settings luôn có link **Privacy Policy** cho mọi người chơi ở mọi vùng (một link `https://` thường, app mở bằng trình duyệt): Google Play muốn link chính sách cả trong Play Console lẫn trong app. Consent do app lo (webgame 0.54.0): Adjust gắn consent DMA của Google từ câu trả lời form consent vào lượt cài và mọi event, Facebook không chờ consent (lựa chọn của studio, GAME-GUIDE mục 17); game không phải viết gì.

Thử trên trình duyệt: `platform.ads.simulate(fn)` cho game tự vẽ quảng cáo giả (xem `example/index.html`); `platform.ads.simulate(fn, { loadMs: 3000 })` giả quảng cáo load mất 3 giây để thử nút "đang tải". Trong app dòng này không làm gì.

**Giá trị quảng cáo (từ SDK 0.6.0, app build từ 0.24.0).** Dùng để quyết định có mời xem quảng cáo hay không, và chia người chơi theo giá trị:

```js
const s = platform.ads.ready();   // { rv, inter, rvValue, interValue, rvNet, interNet }: USD ước tính cho một lượt, -1 khi chưa biết
platform.on('adpaid', (p) => {    // mỗi lượt hiện MAX trả tiền: { value, network, kind, placement, precision, tag }
  S.adUsd = (S.adUsd || 0) + p.value;
});
platform.ads.setSegments?.({ 1: S.payer ? 1 : 0, 2: bucket(S.adUsd) });   // segment MAX (MAX dashboard > Segment Targeting), có tác dụng từ lần mở app sau
```

Doanh thu `adpaid` đã được app gửi sang Firebase, Adjust và Facebook; game chỉ dùng nó cho logic của mình. Gọi hàm mới bằng `?.` để game vẫn chạy với app build trước 0.24.0.

Nhiều ad unit: mặc định app chỉ chạy 1 rewarded và 1 interstitial. Khi anh/chị thêm ad unit phụ (`rewardedExtra` / `interstitialExtra` trong `android.sdk.applovin` / `ios.sdk.applovin` của `horus-game.json`, mục 12), `platform.ads.tags` liệt kê tag của chúng; `platform.ads.units(['hi'])` (hoặc `'*'`) cho các unit đó load, mỗi lần hiện lấy quảng cáo đã load có giá cao nhất. Game mới ra nên giữ 1 unit tới khi ổn định.

Kiểm tra tích hợp trên máy thật: `platform.ads.mediationDebugger()` mở Mediation Debugger của AppLovin MAX (để trong menu ẩn dành cho tester, không cho người chơi thấy).

## 4. Mua trong app

```js
const label = platform.iap.price('coins_100') || '$0.99';   // giá theo nước người chơi; null thì dùng giá của game

const r = await platform.iap.buy('coins_100');
if (r.status === 'ok') grant(r);
// 'pending': chưa thanh toán xong hoặc chưa kiểm tra được, sẽ về qua pending()
// 'cancel' | 'owned' | 'invalid' (mua giả, không thưởng) | 'error'

function grant(p) {
  if (!game.buys.some((b) => b.token === p.token)) {        // chưa giao đơn này
    // 1. cộng hàng vào bản lưu và lưu ngay
    game.coins += 100;
    game.buys.push({ sku: p.sku, token: p.token, t: Date.now() });
    store.save(game);
  }
  // 2. rồi mới finish (consumable: mua được nhiều lần)
  platform.iap.finish({ sku: p.sku, token: p.token, orderId: p.orderId, consumable: true, usd: 0.99 });
}

// state 'pending' (chưa trả xong, Ask to Buy, chưa kiểm được): KHÔNG giao, KHÔNG finish; đơn sẽ về lại khi xong.
// Số hàng, consumable và usd lấy theo bảng sản phẩm của game (horus-game.json), không cố định như mẫu này:
// Remove Ads là consumable: false, usd sai thì ltv_revenue sai.
// lúc mở game: giao những đơn đã trả tiền mà chưa kịp giao (app tắt giữa chừng)
for (const p of await platform.iap.pending()) if (p.state !== 'pending') grant(p);

// đơn tới khi game đang chạy: thanh toán chậm vừa xong, Ask to Buy trên iOS, mua trên máy khác
platform.on('purchase', (p) => { if (p.state !== 'pending') grant(p); });

// giá của store có thể về sau start(): vẽ lại nhãn giá trong shop
platform.on('prices', () => shop.refreshPrices());
```

`usd` trong `finish` là giá gói bằng USD theo bảng giá của game: app dùng nó để tính `ltv_revenue` của người chơi (không có thì chỉ đơn Play tính bằng USD mới được cộng). Quy tắc: lưu hàng trước, `finish` sau; mỗi `token` chỉ giao một lần (ghi đơn đã giao vào `buys` của bản lưu). Món mua một lần (`remove_ads`) dùng `consumable: false`. Game bán món mua một lần cần nút "Restore purchases" khi `platform.iap.restorable`: `await platform.iap.restore()` rồi giao những gì `pending()` trả về.

Horus kiểm tra mọi đơn với Google Play và App Store trên server, nên đơn giả trả về `invalid`.

Đơn có `state: 'pending'` (chưa thanh toán xong, hoặc `reason: 'verifying'`: chưa kiểm được) thì chưa giao; nó sẽ về lại qua `pending()` hay sự kiện `'purchase'` khi xong.

**Đơn test.** Đơn của license tester, mọi đơn của bản debug và mọi đơn trên trình duyệt có `test: true` (`r.test` của `buy`, `p.test` của `pending()` / `'purchase'`). Vẫn giao hàng như thường, nhưng đừng tính vào số tiền người chơi đã chi mà game tự đếm (luật cho người đã trả tiền, VIP, offer). App đã tự tách đơn test khỏi doanh thu gửi Adjust và Facebook.

## 5. Analytics

**Tên bị chặn (SDK 0.37.0):** `platform.an.log` không gửi tên Firebase giữ riêng (`app_update`, `session_start`, `error`...), tên sai dạng, hay `ad_impression` / `in_app_purchase`; nó báo `console.error` kèm cách sửa và gửi `wg_bad_event` `{ name, why }`.

**Gửi gì:** mọi game Horus gửi cùng một bộ event (tên, tham số, lúc gửi) để team data phân tích mọi game bằng cùng truy vấn: xem `ANALYTICS.md` (trang Analytics chuẩn Horus). Mục này chỉ là cách gọi hàm.

```js
platform.an.log('level_end', { level: 12, stars: 3 });   // tên chữ thường, tham số phẳng
platform.an.earn('coin', 50, 'level');                   // nhận tiền trong game
platform.an.spend('coin', 120, 'upgrade_engine');        // tiêu tiền trong game
platform.an.user({ vip: 1 });                            // user property: chỉ thứ cần cắt, Firebase giữ 25 mỗi máy (ANALYTICS.md mục 10)
platform.an.userId(account.id);                          // (SDK 0.31.0) user_id của Firebase, null để xoá
platform.an.context({ stage_id: 'w1_l3', stage_number: 3, stage_config_version: 'v7', game_mode: 'main' });   // (SDK 0.39.0) màn đang chơi, cho event quảng cáo app gửi (ANALYTICS.md mục 0)
```

**user_id.** `platform.an.userId(id)` gửi id riêng của người chơi (id tài khoản hay id cloud save của game) lên Firebase Analytics và Crashlytics, để gộp một người trên nhiều máy và tìm crash theo người chơi. Gọi sau khi biết id (ví dụ sau khi cloud save đăng nhập), `null` để xoá khi đăng xuất. Tối đa 256 ký tự; không dùng email, số điện thoại hay tên (Google cấm dữ liệu cá nhân trong user_id). Trên web là `user_id` của gtag. Godot: `Horus.an.user_id(id)`.

Doanh thu quảng cáo, mua hàng, nguồn cài đặt (Adjust) và các user property chuẩn do app tự gửi; game không cần làm.

**Event app tự gửi lên Firebase (game không gửi lại, kẻo doanh thu đếm hai lần):** `ad_impression` mỗi lần quảng cáo có doanh thu (Android và iOS: `ad_platform` = appLovin, `ad_source` = mạng, `ad_format`, `ad_unit_name`, `value` USD, `currency`); `in_app_purchase` (iOS: app gửi từ giao dịch StoreKit, bỏ đơn sandbox; Android: Firebase tự ghi từ Google Play Billing, chỉ khi project Firebase đã liên kết với Google Play trong Firebase Console > Project settings > Integrations; chưa liên kết thì Android không có event này, doanh thu mua hàng vẫn có ở `purchase_count` / `ltv_revenue` và Adjust). `adjust_attribution` một lần cho mỗi nguồn cài (campaign, chi phí `cost`, `adid`... của Adjust; dùng để tính thu hồi vốn theo campaign trong BigQuery). Doanh thu quảng cáo lên Adjust đã do SDK gửi: trong dashboard Adjust không bật thêm kết nối server-to-server của AppLovin ("AppLovin reporting"), kẻo doanh thu tính hai lần; trong Google Ads chỉ một nguồn chuyển đổi chính (Firebase hoặc Adjust), không cả hai. Event riêng của game đặt tên khác (`iap_offer_shown`, `rewarded_click`...). `login` là event chuẩn của Firebase chỉ khi người chơi đăng nhập tài khoản (tham số `method`); game không có tài khoản thì không gửi, có id người chơi thì dùng `platform.an.userId(id)`. User property có sẵn: `connection_type`, `config_version`, `purchase_count` và `ltv_revenue` (USD, không tính đơn test), `ua_network` / `ua_campaign` / `ua_adgroup` / `ua_creative`, `ua_cost` / `ua_cost_type` (chi phí lượt cài từ Adjust, khi dashboard Adjust bật Cost data in SDK), `win_streak` / `lose_streak` (từ `an.result`), `<tên>_balance` (từ `an.balance`, gửi tối đa 2 giây một lần; app tự gửi phần còn chờ khi ra nền, muốn gửi ngay thì `platform.an.flush()`).

**Nguồn cài đặt.** `platform.ua` là `{ network, campaign, adgroup, creative, costType, cost, costCurrency }` của Adjust (`cost` = -1 khi Adjust không gửi chi phí), hoặc `null` khi Adjust chưa biết (có thể tới trong phiên đầu: `platform.on('ua', ...)`). App cũng đặt user property `ua_campaign`..., nên Remote Config có thể đổi giá trị theo chiến dịch (điều kiện trên `ua_campaign`; phiên đầu dùng giá trị mặc định, lần mở sau mới theo chiến dịch).

**Hiệu năng máy: sự kiện `device_perf` (SDK 0.34.0, tự có, không cần code).** Để team data tìm dòng chip chơi không nổi game mà doanh thu không đủ bù CPI và chặn chúng trong danh mục thiết bị của store, app tự gửi mỗi phiên một sự kiện `device_perf` (Android và iOS; trên web không gửi). Firebase đã có model máy, Play Device catalog có chip và RAM theo model; sự kiện này thêm phần còn thiếu:

| Tham số | Nghĩa |
|---|---|
| `fps_p50`, `fps_p10` | fps trung vị và fps của 10% giây chậm nhất (đếm mỗi giây một cửa sổ) |
| `fps_n` | số giây đã đếm; `fps_on` `play` (game có gọi `platform.gameState`) hay `all`; `fps_by` `raf` (khung của trang) hay `game` |
| `boot_ms` | ms từ lúc trang bắt đầu tới `platform.ready()` |
| `app_ms` | Android, app build từ webgame 0.70.0: ms từ lúc mở tiến trình (bấm icon) tới `platform.ready()`, kể cả lúc WebView khởi động; chỉ lần mở nguội |
| `first` | 1 = phiên đầu của lượt cài |
| `ram_mb` | RAM máy (Android: đúng MB; nơi khác `navigator.deviceMemory`, kèm `ram_est` 1) |
| `cores`, `gpu`, `hz`, `thermal` | số lõi CPU, tên GPU của WebGL ("Mali-G52 MC2", "Adreno (TM) 610"), tần số màn hình, nhiệt độ máy lúc gửi |
| `why` | `time` (đủ 60 giây chơi) hay `bg` (người chơi rời app trước đó; vẫn gửi để có `boot_ms` của máy bỏ game sớm) |

Đếm từ `platform.ready()`. Không tính lúc quảng cáo toàn màn hình, trang ẩn hay app ở nền. Game gọi `platform.gameState('play')` khi vào lượt chơi, `'menu'` khi ra (và `'play', true` lúc nạp level) thì chỉ đếm lúc chơi, bỏ giây đầu của mỗi lượt; nên gọi, không thì fps gồm cả menu. Game tự khoá fps bằng cách bỏ khung (khoá 30 fps, màn 120 Hz vẽ 60) thì gọi `platform.perf.frame()` mỗi khung thật sự vẽ. Thêm tham số riêng (tối đa 6): `platform.perf.note({ tier: 2, cap: 30 })`. Tắt: `HorusSDK.start({ perfEvent: false })` (không gọi `platform.init` lần hai) hoặc Remote Config `wg_perf_off` = `true`. Godot: `Horus.perf` (addon 0.4.0), đếm khung của Godot, `fps_by` `engine`.

**Máy tester.** `platform.an.block?.(true)` tắt mọi tracking trên máy đó (Firebase, Adjust, Facebook, kể cả doanh thu quảng cáo và mua hàng) và giữ qua các lần mở app. Gọi từ menu ẩn của tester để số liệu thật không lẫn số thử.

## 6. Remote Config

```js
const every = Number(platform.rc.values.inter_every ?? 2);
```

Giá trị luôn là chuỗi; số thì kẹp trong khoảng hợp lý, chuỗi rỗng hay `NaN` thì dùng mặc định trong code.

**Giá trị mới có từ phiên sau.** App dùng giá trị đã tải ở phiên trước, nên lượt cài mới chạy bằng giá trị mặc định trong code (lần mở đầu tiên app chờ tối đa 2 giây để tải). Đổi trên Firebase rồi thử ngay trong cùng phiên thì không thấy gì: mở lại app. Vì vậy mặc định trong code phải đúng với cách chơi mong muốn của phiên đầu, và A/B cần có hiệu lực từ phiên đầu thì chia nhánh trong code (`liveops.assignAB`), không qua Remote Config.

**A/B.** Tạo trong Firebase console, A/B Testing, Create experiment, Remote Config, trên một tham số game đọc (`ab_<tên>`,
giá trị = tên nhánh, thiếu hay sai thì game dùng nhánh mặc định). Nhắm App version từ bản đầu tiên đọc tham số đó; chỉ máy
cài mới thì thêm First open và activation event game ghi một lần khi lần mở đầu đã có giá trị. Đặt rõ giá trị cho
Baseline. Kết thúc bằng Roll out (Firebase thêm điều kiện vào template) hoặc Stop. Không chia nhánh trong code, không
gửi nhánh làm user property (`ANALYTICS.md` mục 10).

Ghi các khóa và giá trị mặc định vào `horus-game.json`, rồi đặt chúng trong Remote Config của project Firebase của game (project của anh/chị khi game dùng file Firebase riêng, mục 12); đổi được mà không cần bản mới.

**Bản web (trình duyệt): mặc định tắt.** Trình duyệt không có Firebase của app, nên `platform.rc.values` là `{}` và game chạy bằng mặc định trong code. Game nào cần bản web đọc Remote Config thì bật: thêm một Web app trong Firebase console (Project settings > Your apps > Add app > Web) rồi truyền config của nó lúc khởi động:

```js
await HorusSDK.start({ rcWeb: { apiKey: 'AIza...', projectId: 'my-game-1234', appId: '1:123:web:abc' } });
```

Trên web giá trị có ngay trong phiên đó (game chờ tối đa `rcTimeout`, mặc định 2000 ms); mất mạng hay chậm thì dùng giá trị lần trước của trình duyệt, chưa có thì mặc định trong code. Trong app, `rcWeb` bị bỏ qua (app dùng Firebase của app). Giá trị đổi trên Firebase có thể mất tới vài phút mới tới web (Firebase cache).

## 7. Lưu game

Dùng kho lưu có sẵn: có phiên bản, gộp ghi, giữ bản dự phòng trong app (cài lại game hoặc xóa dữ liệu WebView vẫn còn).

```js
const { save } = HorusSDK;
const store = save.createSaveStore({
  key: 'mygame',
  defaults: () => ({ coins: 0, level: 1, buys: [] }),
  mirror: (json) => platform.save.mirror(json),   // bản dự phòng trong app + cloud save
});

await HorusSDK.start({ skus: [...] });
store.restoreBackup(platform.save.backup);   // máy trống thì lấy lại bản của app
const game = store.load();

store.queue(game);   // lưu thường xuyên (gộp trong 0,4 s)
store.save(game);    // lưu ngay (sau khi mua hàng)
platform.on('pause', () => store.flush());
```

**Thêm trường mới về sau.** `load()` lấy `defaults()` rồi đè giá trị đã lưu lên (cả trong object con), nên trường mới tự có giá trị mặc định, trường sai kiểu quay về mặc định. Đổi cấu trúc thì dùng các tuỳ chọn của `createSaveStore`:

```js
const store = save.createSaveStore({
  key: 'mygame', defaults, mirror: (json) => platform.save.mirror(json),
  before: (old) => { if (old.gold != null) old.coins = old.gold; },   // sửa bản cũ trước khi đè lên defaults (đổi tên trường...)
  after: (s, old) => { s.cars = save.fitArray(s.cars, 12, 0); },     // chỉnh bản đã đầy đủ (mảng đúng độ dài...)
  economy: { version: 2, reset: (s, fresh) => { s.coins = fresh.coins; s.upgrades = fresh.upgrades; } },   // đổi kinh tế: reset phần đó, giữ phần khác
  omit: ['tmp'],                                                       // trường không bao giờ ghi
  seal: { key: 'mygame-v1', onBroken: ({ state }) => platform.an.log('save_edited', { state }) },   // phát hiện save bị sửa ngoài game
});
```

- `economy`: bản lưu có kinh tế cũ hơn `version` thì `reset` chạy một lần, `load()` trả thêm `econReset: 1` để game báo người chơi.
- `version`: định dạng save. Save có `v` khác không được nạp (game mới hoàn toàn); đổi nhỏ thì dùng `before` / `after`, không tăng `version`.
- `seal`: mỗi lần ghi thêm `_seal`; save bị sửa bằng tay thì `store.sealBroken` là true và `onBroken` được gọi. Không chặn người chơi, chỉ để ghi lại hoặc tắt thưởng.
- Nút "Xoá tiến độ" trong Settings: `game = store.wipe(); store.save(game);` (`wipe` xoá bản trong máy và trả `defaults()`; `save` ghi bản mới và đưa nó sang bản dự phòng của app, nếu không bản cũ sẽ quay lại từ dự phòng hoặc cloud).
- **Xoá tài khoản / xoá dữ liệu (như Crash Ramp):** cloud không có lệnh xoá riêng từ game; bản rỗng mới **ghi đè** bản cloud qua đường gửi bình thường. Thứ tự: `game = store.wipe()` → giữ ngôn ngữ (Xoá tiến độ: giữ thêm món đã mua một lần và `buys`) → `store.save(game)` → `platform.cloud.sync()` → chờ sự kiện `cloud` có `state: "synced"` (hoặc `cloud.status()` là `synced`, tối đa ~8 s; `offline`/`pending` thì báo người chơi "sẽ xoá trên cloud khi có mạng") → nạp lại game từ đầu **trong app** (Crash Ramp: `resetProgress()` nạp lại màn 0). **Không thoát app ngay** sau `save` (`quit()`, `exit`): bản rỗng có thể chưa kịp lên, lần mở sau cloud thấy bản cũ khác máy và kéo tiến độ cũ về. Cần xoá hẳn ô cloud (người chơi gửi yêu cầu xoá dữ liệu theo luật store): báo Horus, server có `op delete` xoá ô của người chơi. Hai nút khác nhau: **Xoá tiến độ** giữ món đã mua; **Xoá tài khoản** xoá hết, kể cả món đã mua và `buys` (chỉ giữ ngôn ngữ). Món mua một lần (Remove Ads) vẫn nằm trong tài khoản Google/Apple: người chơi bấm Restore thì store trả lại, game không chặn; gem đã giao thì mất hẳn. Thu hồi hẳn: hoàn tiền + thu hồi đơn trong Play Console; Apple chỉ người chơi tự xin hoàn tiền.

Game đã có cách lưu riêng thì chỉ cần gọi `platform.save.mirror(JSON.stringify(state))` mỗi lần lưu và đọc lại `platform.save.backup` khi localStorage trống.

## 8. Cloud save

Bật sẵn trong `start()`. Mỗi bản `mirror` được app đưa lên server khi có mạng; người chơi đổi máy hoặc cài lại vẫn giữ tiến độ. Server cloud save là của riêng từng game (địa chỉ riêng, trang admin riêng để Horus tìm save theo Support ID): Horus tạo trên trang admin build, anh/chị không phải điền gì; bản build sau khi Horus tạo có cloud save. Khi gói cloud save có bản mới, Horus cập nhật server của các game trên cùng trang đó (nút "Cập nhật tất cả cloud save"); game không phải build lại.

Khi server và máy khác nhau (cài lại lúc không có mạng...), SDK giữ bản đi xa hơn và cộng sang nó những đơn mua chỉ có ở bản kia. Gọi ngay sau `start()`, trước `store.load()`:

```js
const { cloud, save } = HorusSDK;
await cloud.settleAtBoot(platform, save.conflictRules(store, {
  further: save.further('level', 'coins'),            // so theo level, bằng nhau thì theo coins
  merge: (into, from) => save.mergePurchases(into, from, {
    credit: (s, buy) => (buy.sku === 'coins_100' ? (s.coins += 100, 100) : false),
  }),
  mirror: (json) => platform.save.mirror(json),
  flush: () => platform.save.flush(),
}));
```

Để `mergePurchases` làm được việc, mỗi đơn đã giao được ghi vào `buys` của bản lưu: `{ sku, token, t: Date.now() }`. `buys` cũng là danh sách chống giao hai lần (mỗi `token` một lần): không bao giờ xoá nó. `mergePurchases` chỉ so 30 đơn gần nhất (`keep: 30`); thiếu `t` thì đơn bị coi là cũ nhất.

`settleAtBoot` tự quyết xung đột lúc mở và trả `null` (không có gì), hoặc `{ took: 'cloud' | 'local', forced, added }`. Khi `took === 'cloud'` hay `added > 0`, báo người chơi một dòng ("Đã lấy tiến độ từ cloud", "Đã trả lại 3 món đã mua").

**Save theo người chơi sang máy mới (Android, Play Games Recall, từ SDK 0.12.0).** Cloud save giữ save theo từng máy. Khi người chơi đã đăng nhập Play Games, SDK tự gắn save với tài khoản Play Games đó; lần đầu cài game trên máy mới mà chưa có gì, SDK hỏi server save của máy cũ và báo bằng xung đột như mọi xung đột khác (`e.recall` là true): game chọn bản đi xa hơn như bình thường. Game không phải gọi gì thêm; cần app build có module `games` và server cloud save của game bản mới (Horus deploy).

**Save theo Apple ID sang iPhone mới (iOS, iCloud Keychain, từ SDK 0.13.0).** Horus bật cho app trong cấu hình build của Horus (studio không có khoá này trong `horus-game.json`: muốn bật thì báo Horus): mã người chơi có thêm một bản trong iCloud Keychain, nên mọi iPhone / iPad cùng Apple ID là cùng một người chơi, kể cả máy mới cài từ đầu không khôi phục sao lưu. Máy đã có mã riêng sẽ đổi sang mã chung ở lần mở sau: cloud save gặp save của máy kia thành xung đột, game chọn bản đi xa hơn như bình thường, và Support ID của máy đó đổi. Mặc định tắt; game không phải gọi gì thêm.

**Xung đột giữa lúc chơi.** Server có thể có bản khác khi game đang chạy (máy khác vừa lưu). Lúc đó app gửi sự kiện `'cloud'` với `state: 'conflict'` và không gửi gì lên cho tới khi game quyết. Giữa hai lượt chơi, hỏi người chơi "Dùng bản cloud hay bản trên máy này?":

```js
const rules = save.conflictRules(store, { further, merge, mirror: (j) => platform.save.mirror(j), flush: () => platform.save.flush() });
platform.on('cloud', async (s) => {
  if (s.state !== 'conflict') return;
  const useCloud = s.force || await askPlayer(s.savedAt);        // force: bản do admin sửa, luôn lấy
  if (useCloud) { if (await cloud.takeCloud(platform, rules, game, null)) location.reload(); }
  else await platform.cloud.keepLocal();                         // bản trên máy đè lên bản cloud
});
```

Sau khi mua hàng, gọi `platform.cloud.sync()` để gửi bản lưu lên ngay (bình thường app gửi trong vòng 2 phút, và ngay khi ra nền). `platform.cloud.enabled` là false trên trình duyệt và khi bản build không có cloud save: ẩn phần cloud trong Settings.

Dòng trạng thái cho Settings: `cloud.statusText(await platform.cloud.status())` (tiếng Anh: "Saved 2 min ago"...). Dịch: `cloud.statusText(s, { offline: t('cloud_offline'), none: ..., synced: (at) => t('cloud_saved') + ' ' + cloud.ago(at) })`; các chữ mặc định ở `cloud.STATUS_WORDS`.

### Level online (game puzzle, SDK 0.31.0)

Game có nhiều màn (puzzle, sort, merge…) đổi, sửa, thêm level cho người chơi mà không ra bản app mới. PM của game làm trên trang admin cloud save của game, phần **Level online** (Horus bật cho game: `"levels": true` trong cloud save): sửa level nào thì chỉ kéo đúng file level đó vào (không phải tải lại cả bộ), xem level nào sửa / thêm, rồi phát cho máy thử, một phần người chơi (ví dụ 20%) hay tất cả, theo bản app. Sửa một level chỉ tải lên đúng gói 50 level chứa nó.

```js
const levels = HorusSDK.levels.createLevels({
  app: 'com.studio.puzzle',                 // tên gói như trên trang admin
  count: BUILTIN.length,                    // các level có sẵn trong game
  builtin: (n) => BUILTIN[n - 1],
  platform: HorusSDK.platform,              // bản app, Support ID, analytics; server = cloud save của game
  validate: (lv) => Array.isArray(lv?.grid),   // false: bộ level này không dùng, máy giữ bộ cũ
});
await HorusSDK.start();
await levels.start();                       // ngay lập tức, không chờ mạng
const lv = await levels.get(n);             // level online, hoặc level có sẵn
levels.started(n); levels.won(n, { moves, stars }); levels.lost(n, { reason: 'limit' });
if (levels.info().pending) await levels.apply();   // chỉ ở menu, không bao giờ giữa màn
```

- Mỗi file level một số (`level_57.json`, `57.json`), `.json` thành giá trị JSON, `.txt` thành chuỗi, file khác thành byte. Level có sẵn trong game nên cùng định dạng với file đưa lên trang.
- Bộ mới tải ngầm, dùng từ lần mở app sau hoặc khi game gọi `apply()`. Bộ lỗi (level không qua `validate`, app chết 2 lần ngay sau khi đổi bộ) tự quay lại bộ trước.
- `format` (mặc định 1): tăng khi code game đọc được kiểu level mới; bộ có format cao hơn bản app đọc được thì bản đó giữ bộ cũ.
- Tỉ lệ qua màn: `level_start` / `level_end` (`level`, `level_set`, `level_hash`, `success`, `time_s`, `tries` và số của game). Trên trình duyệt và bản app chưa có cloud save chỉ dùng level có sẵn.
- Tải và cache: level đã tải lưu trên máy (IndexedDB; Godot `user://`), `get(n)` không bao giờ gọi mạng. Máy hỏi server tối đa mỗi giờ một lần (đặt từ server, 5 phút tới 1 ngày), không đổi thì trả 304; chỉ tải gói 50 level còn thiếu, lưu từng gói nên tải dở thì lần sau tải tiếp. Gói sai sha256 hay mất mạng: giữ bộ đang dùng. Bộ cũ chỉ xoá khi bộ mới đã chạy được.

**Cho PM: dùng trang Level online** (trang admin cloud save của game, đăng nhập như trang Người chơi, nút **Level online**):

1. Lần đầu: chọn "Tải cả bộ mới", kéo cả thư mục level (`level_1.json` … `level_N.json`), xem lại, bấm **Tạo bộ 1**.
2. Sửa level: để mặc định "Sửa hoặc thêm vài level", kéo **đúng file đã sửa** (một file cũng được). Thêm level: kéo file mới, số nối tiếp level cuối (bộ 120 level: `level_121.json`…). Sửa và thêm cùng một lần được. Chèn level vào giữa, sắp xếp lại hay bớt level: "Tải cả bộ mới".
3. **Xem thay đổi**: trang báo "Sửa 1 level: 57 · Thêm 30 level: 121-150", bấm số level để xem cũ và mới cạnh nhau, ghi chú lý do, **Tạo bộ N**. Bộ mới chưa tới máy nào.
4. **Phát**: trước hết "Chỉ máy thử" (nhập Support ID của máy QA ở mục Máy thử), rồi "Thử cho một phần người chơi" (ví dụ 20%), so tỉ lệ qua màn, rồi "Tất cả người chơi". Chọn "Bộ này chơi được từ bản app nào?" khi level cần bản app mới.
5. Có vấn đề: **Rút lại** dòng đang phát (máy nhận trong vòng 1 giờ, dùng từ lần mở app sau), hay ô **Tắt level online cả game**. Mọi thay đổi có trong **Nhật ký level** (ai, lúc nào, trước và sau).
6. Firebase, một lần mỗi game: Custom definitions, thêm dimension `level`, `level_set`, `level_hash` và metric `success`, `time_s`, `tries` (phạm vi Event). Xem: Explorations > Free form, event `level_end`, hàng `level`, cột `level_set`, giá trị trung bình `success`.

## 9. Vòng đời và nút

```js
platform.on('pause', (e) => pauseGame());     // e.reason: 'bg' (ra nền) | 'ad'
platform.on('resume', () => resumeGame());
platform.onBack(() => closeTopPopup());       // nút Back Android: true khi game đã dùng nó
platform.haptic(20);                          // rung nhẹ
```

Settings nên có nút liên hệ: `platform.support.contact({ to: 'support@horusvn.com' })` mở email của người chơi kèm mã hỗ trợ (`platform.support.id`) và thông tin máy. Không có mạng thì nó trả `{ ok: false, reason: 'offline' }` mà không mở gì: game hiện thông báo "cần internet". Muốn tự viết thư: `platform.support.report(await platform.support.diag())` ra các dòng "SDK Status" về app và máy, rồi `platform.support.mail({ to, subject, body })` mở app email.

**Máy thiếu bộ nhớ (Android, từ SDK 0.9.1, app build từ webgame 0.27.1).** Sự kiện `'trim'` `{ tier }`: `'hidden'` khi người chơi rời game, `'critical'` khi game ở nền và máy cần bộ nhớ (app có thể bị đóng), `'low'` khi game còn trên màn mà máy thiếu bộ nhớ. Bỏ những gì dựng lại được (render target, shadow map, texture chưa cần), dựng lại khi `'resume'`; Play tính bộ nhớ vào Android vitals.

```js
platform.on('trim', ({ tier }) => (tier === 'low' ? lowerQuality() : dropCaches()));
```

**Chế độ game và nhiệt độ máy (Android, từ SDK 0.10.0, app build từ webgame 0.28.0).** `platform.device.gameMode` là lựa chọn của người chơi trong Game Dashboard (`'battery'`: giới hạn fps, bỏ bớt hiệu ứng; `'performance'`: bậc chất lượng cao nhất; `'standard'`, `'custom'`, `'unsupported'`), đổi thì có sự kiện `'gamemode'`. `platform.device.thermal` `{ status, headroom }` cho biết máy nóng tới đâu (sự kiện `'thermal'`; từ `'light'` hoặc headroom ≥ 0,6 thì giới hạn lượt chơi ở 30 khung/giây và giữ độ nét, chỉ `'severe'` mới bớt hiệu ứng: luật và code mẫu ở `GAME-GUIDE.md` mục 5, "Máy nóng khi chơi lâu"). `platform.gameState('play')` khi vào lượt chơi, `'menu'` khi ra, `'content'` khi có quảng cáo. `platform.device.exits` là các lần trước Android tắt game (hết bộ nhớ, ANR...), gửi vào analytics lúc mở game. `platform.device.relaunch` (app build từ webgame 0.68.0; trang đó được app che bằng khung hình cuối cho tới `app.ready`, xem `keepFrame()` để giữ khung trước quảng cáo) khác `null` khi trang vừa được mở lại trong cùng app vì WebView renderer chết (thường là Android lấy RAM lúc quảng cáo toàn màn hình đang chạy, vì trang của quảng cáo chạy chung renderer với game): `{ why, state, net, ram, at }` (`state` `ad` = dưới quảng cáo, `net` = mạng quảng cáo, `ram` = GB của máy); game có thể đưa người chơi về đúng chỗ đang đứng thay vì màn đầu, thưởng của quảng cáo thưởng đã xem hết nằm trong `platform.ads.lost`. Trên trình duyệt các giá trị là `'unsupported'` / `'unknown'` / `[]`; iOS (app build từ webgame 0.51.0) báo `thermal.status` theo `ProcessInfo.thermalState`, headroom -1.

```js
const tier = () => (platform.device.gameMode === 'battery' || platform.device.thermal.status === 'severe' ? 'low' : 'high');
platform.on('gamemode', () => setQuality(tier()));
platform.on('thermal', () => setQuality(tier()));
for (const e of platform.device.exits) platform.an.log('app_exit', { reason: e.reason, foreground: e.foreground });
```

**Màn hình 90/120 Hz, Test Lab và máy robot (Android, từ SDK 0.14.0, app build từ webgame 0.33.0).** Gọi `platform.device.setFrameRate(60)` lúc game chạy: màn 120 Hz chuyển sang chế độ 60 Hz, requestAnimationFrame còn 60 lần mỗi giây (nửa việc GPU, máy đỡ nóng); `platform.device.display` `{ hz, modes }` là tần số đang chạy và các tần số máy có. Máy có thể không cho đổi, nên game vẫn tự bỏ khung thừa khi đo thấy màn trên 100 Hz. Khi Firebase Test Lab mở app bằng Game Loop, `platform.testLoop` là `{ scenario }`: game tự chơi bài đo của nó rồi gọi `platform.testLoop.done(JSON.stringify(report))`, app đóng; còn lại `platform.testLoop` là `null`. `platform.device.robot` true trên máy Test Lab và máy chạy báo cáo pre-launch của Google Play: app tự tắt quảng cáo thật, Adjust, Facebook và Firebase Analytics ở đó, nên số liệu và doanh thu không bị robot làm nhiễu. iOS và trình duyệt: `{ hz: 0 }`, `null`, `false`.

**Vùng an toàn (tai thỏ, thanh điều hướng).** Game phủ kín màn hình, nên chữ và nút phải nằm trong vùng an toàn. Trong app, SDK đặt biến CSS `--sat`, `--sab`, `--sal`, `--sar` (px của thanh hệ thống và tai thỏ ở trên, dưới, trái, phải) và gửi sự kiện `'insets'` khi chúng đổi; trên trình duyệt dùng `env(safe-area-inset-*)`:

```css
.hud { padding-top: max(var(--sat, 0px), env(safe-area-inset-top, 0px)); }
```

**Thông tin app.** `platform.info`: `{ name, version, build, lang, debug, modules, tampered }`. `lang` là ngôn ngữ của máy (chọn ngôn ngữ mặc định cho game), `modules` là các module có trong bản build (ví dụ `'review'`), `tampered` là bản app bị sửa và ký lại. `HorusSDK.target` (export `target`) là `'web'`, `'android'` hay `'ios'`; `platform.kind` là `'web'` hay `'android'`. `platform.exit()` đưa app ra nền (ví dụ nút "Thoát" của hộp hỏi khi bấm Back).

Thông báo nhắc chơi và push: mục 10. Đánh giá trong app, bảng xếp hạng và thành tích, shortcut trên icon, deep link, báo lỗi Crashlytics: mục 11. Toàn bộ API có trong `horus-sdk.d.ts`, mỗi hàm có chú thích.

## 10. Thông báo (nhắc chơi và push)

Có hai loại, cùng chạy trên Android và iOS:

- **Thông báo nhắc (local):** game tự đặt lịch trên máy, không cần server. Dùng để báo quà đã sẵn, nâng cấp mua được, gọi người chơi quay lại.
- **Push từ Firebase:** gửi từ Firebase console tới mọi máy (topic, ví dụ `all`), hiện khi app ở nền. Bật module `firebase-messaging` bằng `"sdk": { "firebase-messaging": { "enabled": true } }` trong `horus-game.json` (game có file Firebase riêng), hoặc Horus bật trong cấu hình app; trên iOS cần thêm khoá APNs (.p8) trên Firebase. Game không phải gọi gì.

**Xin quyền.** Android 13+ và iOS hỏi người chơi một lần bằng hộp thoại của máy. Gọi sau một khoảnh khắc tốt (hết lượt đầu, nhận quà), không bao giờ ngay lúc mở app:

```js
const ok = await platform.notif.ask();            // true: được phép
```

**Đặt lịch khi ra nền, xoá khi quay lại.** Mỗi lần `pause` với lý do `'bg'`, đặt lại cả danh sách (lịch cũ bị thay); lúc `resume` xoá hết (thông báo đang hiện và số trên icon cũng mất):

```js
platform.on('pause', (e) => {
  if (e.reason !== 'bg' || !S.settings.notif) return;
  platform.notif.schedule([
    { id: 'gift', at: Date.now() + 3 * 3600e3, title: 'QUÀ ĐÃ SẴN 🎁', body: 'Vào nhận ngay kẻo lỡ!',
      screen: 'shop', channel: 'rewards', number: 1 },
  ]);
});
platform.on('resume', () => platform.notif.cancelAll());
```

- `id`: loại thông báo; trả về ở `kind` khi người chơi bấm, và trong analytics.
- `channel`: `'rewards'` (mặc định) hoặc `'comeback'` (gọi người vắng lâu). Người chơi tắt riêng từng kênh trong cài đặt Android. Push đi kênh `'news'`.
- `number`: số việc đang chờ, hiện trên icon app (máy nào hỗ trợ). `screen`: màn game mở khi bấm.

**Mở đúng màn khi người chơi bấm thông báo:**

```js
const o = platform.notif.opened;                   // app được mở từ thông báo: { kind, screen, at, shownAt, openedAt }, không thì null
if (o) openScreen(o.screen);
platform.on('notif', (o) => openScreen(o.screen)); // bấm lúc game đang chạy
```

**Công tắc Notifications trong Settings của game.** Người chơi có thể tắt trong cài đặt máy bất cứ lúc nào, nên đọc lại mỗi lần mở và mỗi lần `resume`:

```js
const st = await platform.notif.state?.();       // { supported, enabled, channels: { rewards, comeback, news }, canAsk }
// bật công tắc: st.canAsk ? await platform.notif.ask() : platform.notif.settings()  (mở trang cài đặt thông báo của app)
// tắt công tắc: platform.notif.cancelAll() và không schedule nữa
```

`supported: false` là trình duyệt (hoặc app quá cũ): ẩn công tắc.

**Lịch thông báo có sẵn (`liveops`).** Thay vì tự chọn giờ, dùng bộ lập lịch Horus dùng cho Crash Ramp: đặt trước giờ người chơi hay mở game 15 phút, trong khung 8:00-22:00, tuần đầu tối đa 3 lần/ngày rồi thưa dần, bỏ qua nhiều lần liền thì chỉ 1 lần/ngày:

```js
const { liveops } = HorusSDK;
const plan = liveops.planNotifications({
  now: Date.now(), starts: S.meta.hours, ignored: S.notify.ignored, config: NOTIFY,
  candidates: [{ kind: 'gift', at: giftReadyAt }, { kind: 'daily_ready', day: 1 }],   // at: giờ cụ thể; day: giờ chính của ngày đó (1 = mai)
  text: (it) => ({ title: t('ntf_' + it.kind + '_t'), body: t('ntf_' + it.kind) }),
});
platform.notif.schedule(liveops.toReminders(plan));
S.notify.plan = liveops.planRecord(plan);
```

`S.notify = liveops.createNotify()` và `S.meta` (`liveops.bootMeta`) nằm trong bản lưu; `liveops.noteReturn(S.notify, Date.now(), o?.kind)` lúc quay lại để bộ lập lịch biết người chơi có bấm hay bỏ qua. Cách làm đầy đủ: trang **Làm game như Crash Ramp**, bước 15.

**Analytics:** app tự ghi `notif_shown` (thông báo đã hiện) và `notif_open` (người chơi bấm, kèm `kind`). Nên ghi thêm kết quả hộp thoại xin quyền, ví dụ `notif_prompt` `{ result: 'allow' | 'deny' }`.

**Thử:** trên trình duyệt không có thông báo (`ask()` trả `true`, `schedule` không làm gì, `opened` luôn `null`), nên in danh sách `schedule` ra Console để kiểm giờ và chữ. Thông báo thật chỉ thấy trong APK hoặc bản TestFlight (mục 12): đặt một lời nhắc sau 1 phút, ra màn hình chính rồi chờ.

## 11. Đánh giá, bảng xếp hạng, shortcut, báo lỗi

**Chia sẻ (app build từ webgame 0.38.0).** `platform.share.open({ title, text, url, image })` mở bảng chia sẻ của máy (Android: chooser, iOS: share sheet, trình duyệt: `navigator.share` hoặc chép chữ và link, `via: 'copy'`). `image` là `data:image/png|jpeg|webp;base64,...` (ví dụ `canvas.toDataURL('image/png')`), tối đa 8 MB; giá trị khác bị bỏ không báo. Kết quả `{ ok, via, app }` hoặc `{ ok: false, reason }`; trên Android `ok` chỉ nghĩa là bảng đã mở. `platform.share.supported` cho biết có bảng chia sẻ thật. `platform.share` là object, không gọi `platform.share(...)`.

**Đánh giá trong app (từ SDK 0.6.0).** Hộp đánh giá của chính store, người chơi không phải rời game: Google Play In-App Review trên Android, lời mời đánh giá của App Store trên iOS.

```js
// sau một khoảnh khắc vui (thắng màn, mở xe mới), không gắn vào nút
if (platform.info.modules.includes('review')) await platform.review();   // { shown }
```

`shown: true` chỉ có nghĩa là đã hỏi store: Google và Apple tự giới hạn số lần hiện và không cho biết hộp có hiện thật hay không. Vì vậy không thưởng cho việc đánh giá và không hỏi "anh/chị đã đánh giá chưa?" (store cấm). App của game cần bật module `review` (Horus bật trong cấu hình build); trên trình duyệt luôn `{ shown: false }`.

**Cập nhật trong app (Android, từ SDK 0.11.0, app build từ webgame 0.29.0).** Google Play báo có bản mới và tải ngay trong game, người chơi không phải mở Play Store (app cần module `update`, Horus bật trong cấu hình build).

```js
const U = platform.update;
const u = await U.check();   // { available, versionCode, priority (0-5), staleDays, flexible, immediate }
if (u.available && (u.priority >= 4 || u.staleDays > 30) && u.immediate) U.start(true);   // màn cập nhật toàn màn hình của Play
else if (u.available && u.flexible) U.start(false);   // tải nền, game vẫn chơi
platform.on('update', (e) => { if (e.state === 'downloaded') showRestartButton(() => U.complete()); });   // ở menu, khởi động lại vào bản mới
```

Chỉ app cài từ Google Play mới có cập nhật (bản cài tay: `available: false`); trên iOS và trình duyệt luôn không có gì.

**Cập nhật nóng (Android và iOS, app build từ webgame 0.40.0).** Sửa lỗi hay đổi nội dung của game mà không cần bản mới trên store: Horus phát bản web mới (JS, HTML, hình, âm thanh), app tự tải, kiểm chữ ký và chạy nó từ lần mở sau; bản mới không khởi động được thì app tự quay về bản có sẵn trong app. **Mặc định tắt**: Horus bật cho từng game trong cấu hình build, rồi một bản store mang phần này; từ đó mỗi lần sửa lỗi anh/chị gửi bản web, Horus phát (có thể cho một phần người chơi trước). Chỉ phần web đổi được theo cách này: SDK, quyền, icon, tên app vẫn đi qua store. Không dùng để thêm tính năng lớn mà store chưa duyệt (Apple 3.3.2, 2.5.2).

```js
platform.hot.active    // bản cập nhật nóng đang chạy (null: bản trong app); hiện cạnh build tag ở trang Tools
platform.hot.pending   // bản đã tải xong, chạy ở lần mở sau
if (platform.hot.pending && atMenu) await platform.hot.apply();   // dùng ngay: trang tải lại (save giữ nguyên), chỉ ở menu
```

Game không phải gọi gì để cập nhật nóng chạy. Bản web gửi cập nhật nóng vẫn chỉ dùng được `platform.*` có trong bản app đang cài; trên trình duyệt `platform.hot.on` luôn `false`.

**Bảng xếp hạng và thành tích (từ SDK 0.7.0, app build từ 0.25.0).** Google Play Games trên Android, Game Center trên iOS, cùng một API. Bảng và thành tích gọi bằng khoá của game (`best_map1`, `first_jump`); Horus ghép khoá với id trên store trong cấu hình build.

```js
const G = platform.games;
if (G?.available) {
  const sendAll = () => {                              // gửi lại hết: store giữ điểm cao nhất, bỏ qua mở khoá lần hai
    G.submit('best_map1', S.best[1]);
    for (const id of S.achievements) G.unlock(id);
  };
  if (G.signedIn) sendAll();
  platform.on('games', (e) => { if (e.signedIn) sendAll(); });
}
// nút trong Settings, chỉ hiện khi G.signedIn
btnBoards.onclick = () => G.show('leaderboards');
btnAchievements.onclick = () => G.show('achievements');
// iOS: biểu tượng Game Center ở góc màn menu, tắt khi đang chơi
G?.access(onMenu);
```

Gọi khi người chơi chưa đăng nhập thì bị bỏ qua, nên luôn gửi lại khi có `'games'` `{ signedIn: true }`. Nút "Đăng nhập" (khi `!G.signedIn`): `await G.signIn()`. Khoá đã lên store thì không đổi nghĩa. Cách chọn bảng và thành tích để được store feature: trang Làm game, bước 20.

**Thách đấu và hoạt động Game Center (iOS 26, từ SDK 0.8.0, app build từ webgame 0.26.0).** Trên iPhone iOS 26, `G.social` là true: người chơi thách bạn bè trên một bảng xếp hạng, và app Games có nút "Chơi" mở thẳng một màn của game. Trên Android và iOS cũ `G.social` là false và các lệnh dưới bị bỏ qua.

```js
if (G?.social) btnChallenge.onclick = () => G.challenge('best_map1');   // màn thách đấu của Game Center; không id: mọi thách đấu
G?.activity('map3', true);    // bắt đầu một lượt chơi trên map 3 (khoá hoạt động của game)
G?.activity('map3', false);   // hết lượt
const go = (p) => p && openMap(Number(p.properties.map || 1));   // { activity, properties } từ App Store Connect
go(G?.takePlay());            // lúc mở game: người chơi bấm "Chơi" trong app Games
platform.on('gamesPlay', go); // khi game đang chạy
```

Thách đấu và hoạt động tạo trong App Store Connect (khoá ghép với tiền tố id như bảng xếp hạng); properties của hoạt động (ví dụ `map`) do game tự đọc.

**Game Stats của Play Games (Android, từ SDK 0.9.0, app build từ webgame 0.27.0).** Để vào chương trình Play Games Level Up, game gửi event mỗi lần có việc đó (tạo event và stat trong Play Console > Play Games Services > Game Stats; tên event và thuộc tính phải đúng như Console):

```js
if (G?.stats) G.stat('runCompleted', { map: 2, distance: 812.5, rocket: true });
G?.stat('progressUpdate', { currentProgress: 37 });   // stat tiến độ của Level Up
```

Số nguyên gửi đi là thuộc tính số nguyên; thuộc tính số thập phân có lúc mang số tròn thì Horus ghi tên nó vào `decimals` trong cấu hình build. Chưa đăng nhập Play Games thì event bị bỏ; Play gửi gộp khi game rời màn hình. Trên iOS và trình duyệt `G.stats` là false.

**Cỡ chữ của máy.** `platform.info.fontScale` là cỡ chữ người chơi chọn trong cài đặt máy (1 là mặc định, 1,3 là lớn hơn; trên trình duyệt luôn 1). Dùng để bật sẵn "Larger text" trong Settings của game.

**Shortcut khi giữ icon app.** Giữ icon app hiện thêm vài dòng phía trên "Xoá app" (iOS Quick Actions, Android 7.1+), ví dụ "Gặp lỗi? Báo tụi mình" và "Đừng đi mà! Chơi tiếp nha":

```js
if (platform.shortcuts.supported) platform.shortcuts.set([
  { id: 'support', title: t('sc_support'), icon: 'mail' },
  { id: 'play', title: t('sc_dont_go'), icon: 'heart' },
]);                                                  // tối đa 4; gọi sau start() và mỗi lần đổi ngôn ngữ
const pick = (o) => o.id === 'support' ? platform.support.contact({ to: 'support@horusvn.com' }) : startRun();
if (platform.shortcuts.opened) pick(platform.shortcuts.opened);   // app được mở từ shortcut
platform.on('shortcut', pick);                       // chọn lúc game đang chạy
```

Android hiện khoảng 25 ký tự của `title`; iOS có thêm dòng nhỏ `subtitle`. App tự ghi sự kiện `shortcut_open { id }`.

**Deep link (SDK 0.30.0, app build từ webgame 0.61.0).** Link có scheme riêng của app (`mygame://event`) mở game. App Store Connect cần nó để nộp In-App Event (ô "Event deep link": `mygame://event`). Đặt `"urlScheme": "mygame"` trong `horus-game.json` (mục 12), rồi trong game:

```js
const openLink = (l) => { if (l?.path === 'event') showEvent(); };   // l: { url, path, query, openedAt }
openLink(platform.link.opened);                    // app được mở bằng link
platform.on('link', openLink);                     // link mở lúc game đang chạy
```

`path` là phần sau `://` bỏ `/` hai đầu (`mygame://shop/gems?tab=2`: `shop/gems`, `query` `{ tab: '2' }`). Trên trình duyệt và khi không có `urlScheme`: `platform.link.supported` false, `opened` null. App tự ghi sự kiện `link_open { path }`. Thử trên Android: `adb shell am start -a android.intent.action.VIEW -d "mygame://event"`; iOS: gõ `mygame://event` vào Safari.

**Universal Links / App Links (SDK 0.40.0, webgame 0.88.0, anh 20/11/2026: như Adjust Settings của Unity).** Link https mở thẳng game, như link Adjust `https://mygame.go.link/shop`. Ghi riêng từng nền tảng trong `horus-game.json` (anh 20/11/2026: "để riêng từng platform"), như ba ô Deep linking của Adjust Settings bên Unity: iOS `ios.urlScheme`, `ios.urlIdentifier` (iOS URL Identifier; bỏ trống thì là bundle id), `ios.linkDomains: ["mygame.go.link"]` (Universal Links Domains); Android `android.urlScheme`, `android.linkDomains` (App Links). Tối đa 4 tên miền; không điền thì nền tảng đó không có. `urlScheme` / `linkDomains` ở gốc chỉ là giá trị chung khi hai nền tảng giống nhau. Máy build tự thêm Associated Domains `applinks:` cho iOS và bộ lọc App Links `autoVerify` cho Android; link mở app được chuyển cho Adjust (đọc chiến dịch, reattribution) và cho game như deep link thường (`path` là phần đường dẫn: `https://mygame.go.link/shop/gems`: `shop/gems`). Link rút gọn của Adjust (`https://mygame.go.link/abc1`, webgame 0.88.1): Adjust đổi ra link đầy đủ (`processAndResolve`, theo tài liệu Adjust mới) và game nhận link đầy đủ đó; nếu game đã nhận link ngắn thì có thêm sự kiện `link` với `short` = link ngắn, nên game bỏ qua `path` lạ thay vì báo lỗi. Bên Adjust: Campaign Lab > Links > tên miền `go.link` của app, điền Team ID + bundle iOS và package Android + SHA-256 của khoá ký app (Play Console > App integrity) để Adjust phục vụ `apple-app-site-association` và `assetlinks.json`. Tên miền riêng của studio thì studio tự đặt hai file đó. Những mục khác của Adjust Settings bên Unity Horus SDK đã tự làm: câu hỏi ATT (`ios.attText`, có câu mặc định), framework AdSupport / AdServices / AppTrackingTransparency / StoreKit, quyền INTERNET / install referrer / AD_ID / ACCESS_NETWORK_STATE, URL scheme (`urlScheme`); Custom Activity và Broadcast Receiver không cần.

**Báo lỗi lên Crashlytics.** Lỗi JavaScript không tự lên Crashlytics; game bắt và gửi dạng non-fatal, kèm vài key giúp tìm lỗi:

```js
addEventListener('error', (e) => platform.crash(String(e.message), e.error?.stack));
addEventListener('unhandledrejection', (e) => platform.crash(String(e.reason?.message || e.reason), e.reason?.stack));
platform.crashKeys({ level: S.level, screen: 'shop' });   // hiện trên mỗi báo lỗi; app đã tự gắn phiên bản app, module, kích thước save và mọi user property
```

Đọc và sửa crash, ANR sau khi ra mắt (đếm người chơi thật, bỏ robot, `renderer_gone` ở nền không phải crash, các lỗi đã gặp và cách sửa): `GAME-GUIDE.md` mục 21. Luật hiệu năng cho máy yếu (WebView cũ, độ nét tự động, máy ấm, nhẹ khi quảng cáo, mỗi lúc một quảng cáo): mục 5 và 8.

## 12. Build ra app (Build online)

Anh/chị không build app trên máy mình. `horus-build.mjs` gửi bản build web lên máy build của Horus; máy đó gắn gamekit, ký app và trả về APK (cài thử) hoặc AAB, hoặc đưa thẳng lên **Google Play (internal)** hay **TestFlight** (iOS build trên Mac của Horus). Cần Node 18 trở lên, không cần cài gì thêm. Các lệnh dưới đây coi như gói SDK được chép vào thư mục `horus-sdk/` trong repo game.

**Một lần:** điền `horus-game.json` ở gốc thư mục game (chép từ gói SDK), xin Horus một **mã build** cho team rồi lưu lại:

```
node horus-sdk/horus-build.mjs --key <mã build>
```

**Ở văn phòng Horus (mạng LAN):** bản web đi thẳng tới máy build qua LAN, nhanh và không bị router giới hạn upload (log có dòng `LAN: web build sent to ...`). Ngoài văn phòng thì tự đi qua Cloudflare như cũ. Muốn tắt LAN: `HORUS_LAN_BUILDERS=off`.

Mã được lưu trong thư mục người dùng (`~/.webgame/build-key`), không nằm trong repo. Máy CI thì đặt biến môi trường `HORUS_BUILD_KEY` thay vì lưu file. Không commit mã build, không gửi nó cho người ngoài team.

**Cách dễ nhất: trang build trên trình duyệt**

```
node horus-sdk/horus-build.mjs ui          # mở trang build của game ở thư mục hiện tại
```

Trên Windows: bấm đúp **`horus-sdk\HorusBuild.cmd`** (cùng trang đó, không cần mở terminal). Nó mở game ở thư mục ngay trên `horus-sdk\` (nơi có `horus-game.json`); kéo thả một thư mục game vào file để mở game khác; chưa có game thì mở game thử `example`. Đóng cửa sổ đen là tắt trang.

Có `"build"` trong `horus-game.json` (lệnh build bản web của game, ví dụ `"npm run build"`) thì trang build lại bản web trước mỗi lần gửi (ô **build lại trước khi gửi**, bật sẵn); bằng lệnh là `--build-web`.

Trang có: ô lưu mã build, các trường của `horus-game.json` (tên, appId, version, versionCode, thư mục web, icon, hướng, màu nền), nút **Kiểm tra bản web**, ô **Làm gì** (APK cài thử, AAB, Lên Google Play, iOS lên TestFlight), nút **Gửi build**, thanh tiến độ với từng bước và %, log, nút **Dừng** (máy build của Horus dừng job theo), và danh sách job gần đây (theo dõi lại, tải lại, dừng). Trang chỉ chạy trên máy anh/chị (127.0.0.1), mở bằng đường link lệnh in ra.

**Hoặc bằng lệnh, mỗi lần build:**

```
npm run build                                  # build web của game như thường lệ (ra dist/)
node horus-sdk/horus-build.mjs                 # gửi, chờ, tải APK về build-online/
node horus-sdk/horus-build.mjs --aab           # bản AAB, tải về
node horus-sdk/horus-build.mjs --play          # AAB rồi máy Horus đưa lên Google Play, track internal
node horus-sdk/horus-build.mjs --ios           # iOS: build trên Mac của Horus rồi lên TestFlight
node horus-sdk/horus-build.mjs --firebase      # (0.38.21) APK release gửi tester qua Firebase App Distribution
```

Lệnh in từng bước: `[1/N] đóng gói`, rồi các bước trên máy build của Horus (chuẩn bị game, kiểm tra, Gradle, lên Google Play; iOS: gửi sang Mac, build và TestFlight) kèm %, rồi `[N/N] tải app`. File để ở `build-online/<tên game>-<mã job>.zip` (trong zip là `app-release.apk` hoặc `.aab`). Thêm `build-online/` vào `.gitignore`. Ctrl+C lúc đang chờ thì **dừng job trên máy build** (bản lên Play làm dở được xoá, bản iOS trên Mac dừng theo).

**Luật version khi lên store** (webgame 0.86.10, anh 19/11/2026): bản đầu tiên Android `0.0.1.0`, iOS `0.1.0`; sau khi lên production, bản sau lấy version production tăng 1 ở số cuối (Android 0.0.1.1, iOS 0.1.1; tới 9 thì nhớ sang số trước: 0.0.1.9 -> 0.0.2.0, iOS 0.1.9 -> 0.2.0). Máy build đọc version production trên Google Play / App Store và dừng job sai version với `VERSION_RULE` (lỗi ghi version đúng). Không chừa game nào: version sai dạng (Android 4 số, hoặc 3 số như Crash Ramp; iOS 3 số; mỗi số sau số đầu 0-9) bị chặn; game Android cũ quay về 0.0.1.0 (Crystal Fill 0.9.179; Crash Ramp 0.1.8 đúng dạng 3 số nên lên 0.1.9); iOS không lùi được nên lấy version đúng dạng nhỏ nhất lớn hơn bản trên App Store. iOS đang chờ duyệt: được build lại version đó hoặc version kế tiếp. Android lên internal / alpha / beta được giữ nguyên version đang trên production (chỉ versionCode tăng); bản sẽ lên production mới cần +1. iOS thì Apple không nhận build mới cho version đã lên App Store nên vẫn phải +1. Bản Lên Firebase không bị luật này.

**Không tải APK / AAB về nữa** (webgame 0.86.9, anh 19/11/2026): máy build chỉ đưa bản lên Google Play (internal) hoặc Firebase App Distribution (APK cho tester), iOS lên TestFlight; job tải về dừng với `DOWNLOAD_OFF`, mọi team.

**Lên Firebase App Distribution** (webgame 0.86.8): ô **Làm gì** > "Lên Firebase App Distribution", hoặc `--firebase`. Máy build làm APK release (ký bằng key của app khi Horus cho team release game đó, không thì key test) rồi gửi lên Firebase App Distribution của game, bằng key Firebase của Horus trên máy build (dev không cầm key). Tester nhận email để cài. Danh sách tester trong horus-game.json: `"appDistribution": { "groups": ["qa"], "testers": ["a@horusvn.com"] }` (nhóm phải có sẵn trong Firebase > App Distribution > Testers & Groups). Đây là bản thử, không phải bản lên store: được để Adjust `environment: "sandbox"` (đơn mua thử lên sandbox Adjust), không qua kiểm `STORE_SETUP_MISSING`. Cần `google-services.json` của game có đúng package. Lỗi `FIREBASE_DIST` ghi rõ thiếu gì.

Không khai nhóm/tester trong `horus-game.json` (`appDistribution`) thì máy build tự gửi cho tất cả nhóm tester của project Firebase của game (log ghi tên nhóm). Khoá cần quyền Firebase App Distribution Admin.

**Lên store phải đủ setup** (webgame 0.85.8): job **Lên Google Play** và **iOS lên TestFlight** dừng với lỗi `STORE_SETUP_MISSING` khi thiếu Adjust (`sdk.adjust.appToken`, thêm `purchaseEvent` nếu bán IAP), MAX (`sdk.applovin.sdkKey` và ít nhất một ad unit rewarded hoặc interstitial), `privacyUrl` (https) hoặc tắt màn consent (`consentFlow: false`), hoặc Adjust còn `environment: "sandbox"` (sandbox chỉ cho APK cài thử: cài đặt và mua hàng, cả giao dịch test, lên sandbox của Adjust). Game không có quảng cáo: `store.noAds: true`. Game có server riêng: `store.ownServer: true` và `sdk.billing.verifyUrl` là link kiểm giao dịch trên server đó. Firebase và cloud save (khi bán IAP) cũng bắt buộc như trước. Lỗi kể từng mục thiếu; APK cài thử vẫn build được khi chưa đủ. Dev không tải AAB về để up tay được (lỗi `AAB_STORE_ONLY`): AAB chỉ lên Google Play qua máy build.

**Lên store:**
- `--play`: version code tự lấy cao hơn bản trên Play, không phải tăng tay. Track `internal`; `alpha` / `beta` chỉ khi Horus cho (`--track beta`). Production do Horus phát hành trong Play Console, không bao giờ từ lệnh này.
- `--ios`: số build tự lấy cao hơn bản trên TestFlight; Apple xử lý 5 đến 30 phút rồi hiện cho tester. Không có file tải về (bản App Store chỉ cài qua TestFlight). Một lần build iOS mất khoảng 15 đến 25 phút.
- Cả hai chỉ chạy khi Horus đã cài đặt game cho team (`appId` Horus cấp; iOS thêm bundle id). Team Apple: Horus khai, hoặc bạn ghi `"ios": { "teamId": "XXXXXXXXXX" }` trong `horus-game.json` (Team ID 10 ký tự, developer.apple.com > Membership) khi Horus chưa khai; team của Horus luôn được ưu tiên, và máy build chỉ đẩy lên TestFlight cho tài khoản Apple Horus đã cài khoá. Chưa cài thì lệnh báo lý do. (webgame 0.86.14) Bundle id iOS: bạn ghi `"ios": { "bundleId": "com.horusent.<game>" }` cùng `teamId`; máy build dùng khi Horus chưa khai iOS cho app.

Các tuỳ chọn khác:
- `node horus-sdk/horus-build.mjs <thư mục game>`: chạy từ chỗ khác.
- `--dry-run`: chỉ đóng gói và kiểm tra, không gửi. Nên chạy trước lần gửi đầu.
- `--no-wait`: gửi xong thoát và in mã job; theo dõi và lấy app sau bằng `--job <mã>`.
- `--cancel <mã>`: dừng một job đang chờ hoặc đang build.
- `--out <thư mục>`: chỗ để file tải về.
- (0.30.0) Job đang xếp hàng hiện vị trí: "đang xếp hàng (thứ 3 trong hàng, 2 job đứng trước)".
- (0.30.0) Làm công cụ riêng (bot báo build, CI, trang theo dõi): API của máy chủ build ở `horus-sdk/BUILD-API.md` (trang tài liệu: mục "API máy chủ build"), gồm `GET /jobs/<id>` với `status`, `progress`, `queuePosition`, `jobsAhead`.

**Link repo:** mỗi lần gửi, lệnh gửi kèm link repo git của game (`git remote get-url origin`, không gửi tên đăng nhập hay token), nhánh và commit. Horus giữ link này cho từng game và có thể build bản mới nhất từ repo (nhớ cho tài khoản Horus quyền đọc repo). Game chưa có remote thì đặt `repo` trong `horus-game.json`; thiếu link thì máy build của Horus có thể từ chối job. Nhân viên Horus (mã build gắn mail @horusvn.com) phải dùng repo trên git công ty `http://git.horusent.com/`; link ở chỗ khác (GitHub...) hay không có link thì job bị từ chối, lỗi ghi rõ cách sửa (trừ khi Horus đặt "Không bắt buộc" cho mã build đó).

**SDK luôn mới:** mỗi lần gửi build, lệnh hỏi máy chủ build của Horus (bằng mã build) có Horus SDK mới không. Có bản mới cùng major thì lệnh tự thay các file của SDK trong `horus-sdk/` (và các bản sao `horus-sdk.js` / `horus-sdk.mjs` / `horus-logic.mjs` khác trong game, trừ `node_modules`), cùng thư mục `horus-sdk/video/` (bộ quay cho video editor và hướng dẫn, từ 0.46.0) và `horus-sdk/godot/`, giữ bản cũ ở `horus-sdk/.old/<phiên bản>/`, rồi mới build và gửi. Bản đổi lớn (major) chỉ báo: đọc CHANGELOG rồi chạy `node horus-sdk/horus-build.mjs update --major`. Cập nhật không cần gửi build: `node horus-sdk/horus-build.mjs update`. Không muốn tự cập nhật: `--no-update` cho một lần, hoặc `"sdkUpdate": false` trong `horus-game.json` (khi đó lệnh chỉ báo có bản mới). Bản web build bằng bundler thì build lại sau khi SDK đổi (`--build-web` làm việc đó trong cùng lệnh).

**Bắt buộc SDK mới nhất (từ 13/11/2026):** máy chủ build chỉ nhận job dùng bản Horus SDK mới nhất (bản trên trang tài liệu). Gửi bằng bản cũ hơn (kể cả khi dùng `--no-update` hay `"sdkUpdate": false`) thì job bị từ chối với lời báo: chạy `node horus-sdk/horus-build.mjs update` (bản đổi major thêm `--major`), build lại bản web, rồi gửi lại.

**Những gì được gửi:** `horus-game.json`, thư mục web (`web` trong `horus-game.json`; không ghi thì lấy `dist`, `build`, `www` hay `public` có `index.html`), icon (`icon`, mặc định `icon.png`; cùng các icon phụ `iosIcons`) và file Firebase của game (`google-services.json`, `GoogleService-Info.plist`). Không gửi source game, `node_modules` hay file `.map`.

**Game Godot** (`"engine": "godot"`): lệnh gửi file `.pck` export từ Godot thay cho thư mục web (`pck` trong `horus-game.json`: file hay thư mục chứa nó; không ghi thì lấy file `.pck` duy nhất trong `build`, `export`, `dist` hay thư mục game), cùng `horus-game.json` và icon. Export trong Godot: **Project > Export > Android > Export PCK/ZIP**, chọn đuôi `.pck`. File phải làm bằng Godot 4.7 (app của Horus chạy Godot 4.7.2); bản Godot khác bị từ chối ngay trên máy anh/chị, không tốn lượt build. `--build-web` khi không có `"build"` thì gọi Godot của máy export file `.pck` (Godot ở `"godot"` trong `horus-game.json`, biến `GODOT_BIN`, hay `godot` trong PATH; preset `"exportPreset"`, mặc định `Android`). Bản iOS cho game Godot là bản thử từ 12/11/2026 (`--ios`, cùng file `.pck`); cập nhật nóng cho Godot chưa có.

**`horus-game.json`:**

| Khoá | Ý nghĩa |
| --- | --- |
| `name` | Tên game (bắt buộc), cũng là tên hiện dưới icon trên Android và iOS (tối đa 50 ký tự; màn hình chính thường chỉ hiện 12 đến 14 ký tự đầu) |
| `version`, `versionCode` | Phiên bản hiện cho người chơi (`1.2.0`) và số build Google Play (tăng mỗi lần lên store) |
| `appId` | Package name Horus cấp, ví dụ `com.horus.mygame`. Để trống: app thử `com.horus.buildtest.<tên>` |
| `web` | Thư mục bản build web, tương đối với thư mục game |
| `engine`, `pck`, `godot`, `exportPreset` | (0.26.0) Game Godot: `"engine": "godot"`, file `.pck` (hay thư mục chứa nó), đường dẫn tới Godot của máy để `--build-web` export, preset export (mặc định `Android`) |
| `repo` | Link repo git của game (để trống: lấy `git remote origin`). Horus lưu link repo của mỗi game và có thể tự build từ source mới nhất |
| `build` | Lệnh build web (mặc định `npm run build`), Horus dùng khi build từ source |
| `play` | (0.46.0) Bản cho Horus Play (`--web`) khi khác bản trong app: `{ "web": "dist", "build": "node build.mjs --target=web" }` thay `web` / `build` cho riêng `--web`. Cần khi `web` / `build` làm trang cho app (game tự tắt phần chỉ có trên web, như bảng VIDEO, khi build cho Android). Lệnh build lúc đó có biến môi trường `HORUS_PLAY=1` |
| `icon` | Icon PNG 1024×1024 không bo góc |
| `iosIcons` | (SDK 0.8.0) Icon phụ của app iOS để thử bằng Product Page Optimization: `{ "tên": "file.png" }`, PNG 1024×1024 không trong suốt; tên gồm chữ, số, `-`, `_`. Apple chỉ thử icon có sẵn trong bản build, nên thêm trước khi gửi bản lên TestFlight |
| `orientation`, `colors.background` | Hướng màn hình, màu nền lúc mở app |
| `notif` | (0.34.0) Âm thanh riêng của thông báo nhắc: `{ "sound": "sfx/notify.wav", "headsUp": true }`. `sound` là file `.wav` ngắn trong bản build web (đường dẫn tính từ thư mục `web`), dùng cho cả Android và iOS; `headsUp` (Android) cho thông báo trồi xuống đầu màn hình. (0.48.1) Android: `"icon": "brand/ic_stat_game.xml"` (VectorDrawable trắng trên nền trong suốt, 24dp) hoặc thư mục PNG theo mật độ (`drawable-mdpi` … `drawable-xxxhdpi`, mỗi thư mục một file .png), làm icon nhỏ của thông báo nhắc và push Firebase; `"color": "#4DE6FF"` là màu nhấn. Không khai báo: ngôi sao của kit, màu `colors.accent` |
| `android.baselineProfile` | (webgame 0.85.0) `true`: bản AAB có Baseline Profile ghi trên máy chạy thử của máy build. Mặc định tắt: game WebView đo chưa thấy nhanh hơn (cold start 831-859 ms so với 842-848 ms); chỉ bật khi đo được lợi. Máy build không có máy chạy thử thì job lỗi `BASELINE_PROFILE`; profile không vào được bản release thì job cảnh báo `[BASELINE_PROFILE]` và cổng kiểm tra chặn (webgame 0.85.3) |
| `sdk`, `android.sdk`, `ios.sdk` | (SDK 0.27.0) Id của app anh/chị tự điền: ad unit MAX, Adjust, Facebook, licence key Play... (xem "Id của app" ngay dưới) |
| `privacyUrl`, `termsUrl` | (SDK 0.28.0) Link `https://` trang chính sách quyền riêng tư và điều khoản của game, đúng link khai trên store. Game có quảng cáo MAX bắt buộc có `privacyUrl`: bảng xin đồng ý ở vùng GDPR (châu Âu) dẫn tới link này, thiếu thì máy build từ chối bản có quảng cáo. Link chỉ gồm chữ ASCII (tên miền tiếng Việt có dấu, dấu cách thì mã hoá `%XX`), không có dấu nháy, `<` `>` hay `\`; link sai thì lệnh gửi build và máy build đều dừng, không lặng lẽ dùng link khác |
| `urlScheme` | (SDK 0.30.0) Scheme riêng của app cho deep link (mục 11), ví dụ `mygame`: link `mygame://event` mở game, dùng cho "Event deep link" của In-App Event trên App Store. Chữ thường, 2 đến 32 ký tự (chữ, số, `+ - .`), bắt đầu bằng chữ, không phải `http`, `https`, `file` hay `fb...`; sai thì lệnh gửi build và máy build đều dừng. Để trống: không có deep link |
| `linkDomains` | (SDK 0.40.0) Tên miền Universal Links / App Links, ví dụ `["mygame.go.link"]` (link Adjust): link https của các tên miền này mở game (mục 11). Tối đa 4; `ios.linkDomains` / `android.linkDomains` ghi đè cho từng nền tảng |
| `android.playAccount` | (SDK 0.30.3, tuỳ chọn) Tên tài khoản Google Play của Horus chứa app (Horus cho biết, ví dụ `hk`, `Sing`). Không ghi: máy build tự tìm tài khoản sở hữu `appId` |
| (máy build, SDK 0.30.4) Khoá Firebase | Không cần ghi gì: khi gửi APK cho tester qua Firebase App Distribution, máy build tự chọn khoá Firebase của Horus theo `project_id` trong google-services.json của game. Project Firebase mới: báo Horus thêm khoá admin của project |
| `firebase` | (SDK 0.27.0) `{ "android": "google-services.json", "ios": "GoogleService-Info.plist" }`: đường dẫn tới hai file Firebase trong thư mục game (không ghi thì lấy hai tên đó ở gốc thư mục game) |
| `ads`, `products`, `remoteConfig`, `events`, `languages`, `support`, `notes` | Danh sách placement, SKU, khoá Remote Config, sự kiện của game (để đối chiếu với code và cài store) |

**Id của app (anh/chị tự điền, từ SDK 0.27.0, máy build từ webgame 0.55.0).** Ad unit, token, file Firebase là của app của anh/chị: anh/chị tạo app trên MAX, Adjust, Facebook, Firebase (mỗi nền tảng một app) rồi điền id vào `horus-game.json`. Horus chỉ tích hợp SDK và build. Cách đặt giống `webgame.config.json` của Horus: id dùng chung cho mọi nền tảng ở `"sdk"`, id riêng từng app ở `"android": { "sdk" }` và `"ios": { "sdk" }`. iOS không bao giờ dùng id của Android: app iOS trên MAX, Adjust là một app khác, có ad unit và token riêng.

```jsonc
"privacyUrl": "https://studio.com/privacy",   // bắt buộc khi có quảng cáo MAX (bảng xin đồng ý GDPR dẫn tới đây)
"termsUrl": "https://studio.com/terms",
"sdk": {
  "applovin": { "sdkKey": "<SDK key của tài khoản MAX>" },
  "facebook": { "appId": "<id app Facebook>", "clientToken": "<client token>" }
},
"android": { "sdk": {
  "applovin": { "rewarded": "<16 ký tự hex>", "interstitial": "<16 ký tự hex>", "admobAppId": "ca-app-pub-...~..." },
  "adjust": { "appToken": "<12 ký tự>", "purchaseEvent": "<6 ký tự>", "events": { "level_end": "<6 ký tự>" } },
  "billing": { "licenseKey": "<Play Console > Monetization setup > Licensing>" }
} },
"ios": { "sdk": {
  "applovin": { "rewarded": "...", "interstitial": "...", "admobAppId": "..." },
  "adjust": { "appToken": "...", "purchaseEvent": "...", "events": {} }
} },
"firebase": { "android": "google-services.json", "ios": "GoogleService-Info.plist" }   // không ghi: hai tên này ở gốc thư mục game
```

| Module | Các khoá anh/chị điền |
| --- | --- |
| `applovin` | `sdkKey` (ở `"sdk"`); `rewarded`, `interstitial`, `admobAppId`, `rewardedExtra` / `interstitialExtra` (`[{ "id": "...", "tag": "hi" }]`, ad unit phụ), `testDeviceIds`, `adReview`, `adReviewKey` (ở `android.sdk` / `ios.sdk`). (0.29.0) Lựa chọn: `consentFlow` (bảng xin đồng ý GDPR, luôn bật: chỉ nhận `true`), `showTermsInGdpr`, `debugUserGeography` (`gdpr` / `other`: giả vùng để thử bảng đồng ý, chỉ bản debug) |
| `adjust` | `appToken`, `purchaseEvent`, `purchaseTestEvent`, `events` (`{ "tên sự kiện game": "token" }`). (0.29.0) `environment` (`""` hay `production`; `sandbox` cho APK cài thử: cài đặt, mua hàng, cả giao dịch test, lên sandbox của Adjust; bản lên store bị chặn khi còn `sandbox`), `logLevel` (`info`, `warn`, `error`, `assert`, `suppress`; không có `verbose` / `debug` trên bản lên store) |
| `facebook` | `appId`, `clientToken`, `events`. (0.29.0) Bật / tắt: `autoLogAppEvents`, `advertiserId`, `purchases`, `adRevenue` |
| `appmetrica` | (SDK 0.53.0) AppMetrica của Yandex, **mặc định tắt**: ghi `apiKey` (AppMetrica > app > Settings > API key, ở `"sdk"` cho cả hai nền tảng, hoặc `ios.sdk` nếu app iOS có key riêng) là bật. Bật / tắt: `gameEvents` (event game, tên như Firebase), `purchases`, `adRevenue` (mặc định bật cả ba); `eventList` (danh sách tên event gửi sang AppMetrica, mặc định bộ chính của sheet; `[]` = mọi event; gói Free giới hạn 3,25 triệu event mỗi ngày cho cả công ty) |
| `billing` | `licenseKey` (Android) |
| `games` | `projectId`, `leaderboards`, `achievements` (Play Games, Android). (0.29.0) `suppressProfileCreation` |
| `integrity` | `cloudProjectNumber` (Android). `onTamper` do Horus đặt (cần chứng chỉ ký app chỉ Horus giữ) |
| `firebase-analytics`, `firebase-crashlytics`, `firebase-remoteconfig`, `firebase-messaging` | không có id: file Firebase bật ba module đầu; `firebase-messaging` bật bằng `"enabled": true` (thêm `topics`). (0.29.0) `firebase-crashlytics`: `ndk` (báo crash code native, mặc định bật) |
| `review`, `update` | (0.29.0) không có id: `"enabled": true / false` bật / tắt hỏi đánh giá trong app và nhắc cập nhật bản mới (Android) |
| `ios` (ở gốc khối `"ios"`, không phải `ios.sdk`) | (0.29.0) `attText`: câu hỏi cho phép theo dõi (ATT) của iOS, một dòng (tới 300 ký tự, không xuống dòng, không ký tự điều khiển) hoặc `{ "en": "...", "vi": "..." }` (phải có `en`); `devices`: `iphone` (mặc định) hoặc `universal` (cả iPad); `languages`: các ngôn ngữ app khai với App Store (`["en", "vi"]`); `teamId`: Team ID Apple, chỉ dùng khi Horus chưa khai team cho app  (SDK 0.40.0, anh 20/11/2026) Không ghi `attText` thì app dùng câu mặc định đã dịch sẵn cho mọi ngôn ngữ game khai trong `ios.languages` (hơn 30 ngôn ngữ: vi, zh-Hans, zh-Hant, ja, ko, fr, de, es, pt-BR, it, ru, tr, ar, th, id...), tiếng Anh cho phần còn lại; ghi `attText` thì câu của game thay hẳn.|

- `privacyUrl` (và `termsUrl`) là link của anh/chị, đặt ở gốc `horus-game.json`, thay link Horus có cho game (nếu có). Game có quảng cáo MAX mà không có `privacyUrl` thì MAX không hiện bảng xin đồng ý ở châu Âu, nên máy build từ chối bản có quảng cáo (lỗi `privacyUrl is empty`). Lệnh gửi build báo trước khi gửi.
- Lựa chọn (bật / tắt, `environment`, `logLevel`...) không tự bật module: chỉ id mới bật. Giá trị sai (không đúng kiểu, ngoài danh sách) bị bỏ qua và dùng của Horus; lệnh gửi build cảnh báo trước.
- Module nào có id thì được bật; `"enabled": false` tắt một module (ví dụ `"sdk": { "facebook": { "enabled": false } }`).
- File Firebase phải là của đúng app: `google-services.json` có app Android trùng `appId`, `GoogleService-Info.plist` có bundle id của app iOS. Sai thì lệnh gửi build dừng ngay trên máy anh/chị (Android) hoặc máy build báo lỗi (iOS).
- Lệnh gửi build kiểm trước khi gửi: ad unit MAX là 16 ký tự hex, rewarded và interstitial không trùng nhau, iOS không dùng ad unit của Android, id riêng của app không đặt nhầm ở `"sdk"`. Máy build kiểm lại đầy đủ (`doctor`); bản AAB và bản lên store dừng khi sai.
- Chưa có `appId` (APK thử `com.horus.buildtest.<tên>`): file Firebase không được dùng. Id quảng cáo vẫn được gắn, nhưng MAX gắn ad unit với package của app nên APK thử thường không ra quảng cáo; điền `appId` thật để thử quảng cáo, và chỉ bấm quảng cáo trên máy có trong `testDeviceIds` hay test device của MAX.
- Chỉ các khoá trong bảng được nhận. Horus vẫn giữ: mạng quảng cáo (adapter MAX, và bật từng mạng với id của nó trong ad unit MAX: Horus kiểm bằng `npx webgame ads check`; khi setup, công cụ của Horus chỉ thêm mạng còn thiếu cho đúng app của game, không xoá và không sửa mạng đã có id), máy chủ (cloud save, kiểm giao dịch `verifyUrl`, hot update), khoá ký app và vân tay của nó (`integrity.certSha256`), tài khoản store, bundle id và team iOS. Game dùng kiểm giao dịch hay cloud save của Horus thì báo Horus thêm `appId` vào máy chủ.
- **Khoá ký (keystore).** Mặc định máy build tự tạo khoá upload cho mỗi app và giữ nó; studio không cần làm gì. Game đã lên Google Play bằng keystore của studio: gửi nó một lần cùng bản phát hành, `node horus-build.mjs --aab --keystore game.jks --key-alias <alias>` với mật khẩu trong biến `HORUS_KEYSTORE_PASSWORD` (và `HORUS_KEY_PASSWORD` nếu khác). Máy build chỉ nhận khi app chưa có khoá, mở thử rồi giữ làm khoá của app: không thay được, không trả lại. Đừng commit file .jks hay mật khẩu vào repo.
- Game Horus đã có cấu hình trên máy build: id anh/chị điền thay id của Horus, từng khoá một; khoá không điền thì giữ của Horus.

**Bản thử và bản phát hành.** Khi Horus chưa duyệt team cho `appId` (hoặc chưa có `appId`), anh/chị nhận APK thử ký bằng khoá thử: chạy được để xem game trong app, với quảng cáo và Firebase theo id anh/chị điền (mục "Id của app"). Khi Horus đã cài đặt game, cùng lệnh đó ra app đầy đủ, `--aab` ra bản AAB, `--play` đưa lên Google Play internal và `--ios` đưa bản iOS lên TestFlight.

**Cổng kiểm tra bản release (máy build từ webgame 0.72.0).** Trước khi đưa lên store, `--aab`, `--play` và `--ios` đọc lại chính file AAB / .ipa và chặn upload nếu có lỗi. Mỗi lỗi kèm nguyên nhân và cách sửa, có trong log và trong `release-report.md` của file zip tải về. Nó kiểm:
- icon là icon của game (so với `icon`), không phải icon mẫu;
- id quảng cáo, Firebase, Adjust đúng `horus-game.json`, không có id test;
- bản web trong app trùng bản gửi lên;
- không có địa chỉ `localhost` / IP mạng nội bộ;
- id sản phẩm mua trong app có trong bản web;
- mọi thứ khác (quyền, activity, thư viện, khoá ký, dung lượng) so với bản upload trước.

Đổi những thứ đó có chủ ý thì khai báo trong `horus-game.json`:

```json
"release": {
  "expect": ["www/*", "manifest/permission/+android.permission.POST_NOTIFICATIONS"],
  "allow": [{ "check": "no MAX test devices", "why": "bản QA nội bộ" }],
  "products": ["remove_ads"]
}
```

- `expect`: thay đổi dự kiến của bản này (dòng lỗi "undeclared ... changes" in sẵn id cần ghi). Bản đầu tiên lên store qua cổng thì ghi `"first"`.
- `allow`: mục kiểm hay cảnh báo được cho qua, **bắt buộc có lý do**.
- `products`: id sản phẩm phải có trong game. Không cần ghi lại nếu đã có danh sách `products` (`sku`) ở đầu `horus-game.json`: máy build dùng id của dev, không dùng `remove_ads` mẫu. Gói có `"consumable": false` tự thành gói mua một lần của cloud save (khôi phục khi cài lại); lần đầu đổi, Horus bấm "Cập nhật cloud save" một lần. Danh sách này lấy từ bản build Android (webgame 0.87.1): game có cả iOS dùng chung máy chủ cloud save, mã App Store khai ở nhánh iOS không ghi đè danh sách của Android (Apple tự báo gói nào mua một lần). `appId` trong `horus-game.json` luôn là id Horus cấp (id Android), kể cả khi build iOS: bundle iOS khai ở `ios.bundleId`; đổi `appId` thành bundle iOS thì máy build không thấy cấu hình của game (báo `NO_CLOUD_SAVE`).

Chi tiết: `packages/webgame/RELEASE-GATE.md` trong gamekit (Horus giữ).

**Thử ngay với game mẫu** (không cần sửa gì):

```
node horus-build.mjs example --dry-run     # xem sẽ gửi gì
node horus-build.mjs example               # build thật, APK ở example/build-online/
```

**Khi lỗi:** lệnh in lý do bằng tiếng Việt. Các lỗi hay gặp: chưa build web (không thấy `index.html`), chưa điền `name`, mã build sai hay hết hạn (xin Horus mã mới), `--aab` khi game chưa được cài đặt. Lỗi trong lúc build trên máy Horus được in kèm log; gửi mã job cho Horus nếu cần hỗ trợ.

Kiểm tra trước khi gửi:
- Game mở được trên trình duyệt điện thoại, không lỗi trong Console.
- `index.html` ở gốc thư mục web, đường dẫn tương đối, không tải gì từ CDN (app chạy được khi không có mạng). Có `horus-sdk.js` trong bản build.
- Có gọi `HorusSDK.start()` và `platform.ready()`.
- Rewarded chỉ thưởng khi `ok`; mua hàng lưu trước, `finish` sau, có xử lý `pending()` lúc mở game.
- Tắt nhạc khi `pause`.
- Không tự chèn mã quảng cáo, analytics hay thanh toán khác.


### Bản web chơi thử (Horus Play)

`node horus-sdk/horus-build.mjs --web` gửi thư mục build web của game (`"web"`, ví dụ `dist`; thêm `--build-web` để chạy `"build"` trước) lên Horus Play, trang chơi thử nội bộ chỉ email @horusvn.com mở được (game có `"play"` trong `horus-game.json` thì dùng thư mục và lệnh build trong đó: bản web thật, không phải trang của app), và in link `https://horus-play.horus-production.workers.dev/<appId>/`. Trên trang này SDK chạy như trên trình duyệt thường: quảng cáo, mua hàng là giả lập. `--web --serve` chỉ mở trên máy này. Game Godot: `godot/README.md` (GODOT.md) mục 9.

### Bản cho video editor (mặc định trên Horus Play)

Mọi trang game trên Horus Play là bản cho đội làm video quảng cáo: Horus Play tự gắn bảng công cụ vào trang, game không chứa nó (bản store, playable ad không mang thêm gì). `--web --serve` mở trên máy cũng có bảng.

- Nút **VIDEO** ở cạnh phải màn (dọc, hơi trên giữa), phím **E**: bảng với các tab Góc máy & cảnh (dừng hình F, tốc độ 0.1x-2x, ẩn toàn bộ UI; góc máy, kịch bản có sẵn và công tắc nếu game khai báo), Quay (quay tab ra file, trình duyệt hỏi quyền một lần; trong link claude.ai file lưu qua hộp "Lưu" của claude.ai), Chỉnh UI (chọn trong danh sách hoặc bật "Chạm chọn, kéo trên màn"; kéo, lăn chuột / chụm hai ngón đổi cỡ, thanh trượt, nút nhích 1 / 10 px, "Giữa ngang", ẩn từng phần; bố cục tự lưu, lưu theo tên, Copy mã / Nhập, Lưu / Nhập file .json), Mở khoá, Hướng dẫn (cách dùng cho người, cộng phần game viết), Cho AI. **R** ẩn mọi công cụ để quay, **E** hoặc chạm 3 ngón hiện lại. Trên điện thoại bảng nằm ở nửa dưới màn.
- **Khung máy** (tab Góc máy & cảnh, hoặc link `?frame=iphone`, `iphone-l`, `ipad`, `ipad-l`, `9x16`, `16x9`, `full`): game chạy trong khung đúng tỉ lệ iPhone / iPad, dọc hoặc ngang, hay 9:16 / 16:9; thanh trên đầu trang đổi khung. Trang chính dừng tải game và mở lại nó trong iframe cùng trang cỡ đúng khung, nên game thấy cửa sổ cỡ đó (`innerWidth` / `innerHeight`, `resize`); game không cần làm gì. Chọn một lần là nhớ cho mọi game trên Horus Play trong trình duyệt đó. Quay trong khung (Chrome / Edge) chỉ lấy phần game. Khung không giả tai thỏ (`env(safe-area-inset-*)` vẫn là 0).
- Tốc độ và dừng hình đổi đồng hồ của trang (`performance.now`, thời gian truyền vào `requestAnimationFrame`): vòng lặp game tính `dt` từ đó (cả `THREE.Clock`) tự chậm theo. Game tính thời gian bằng `Date.now()` hay `setTimeout` thì đọc `platform.video.speed` (0 khi dừng), hoặc `platform.video.onSpeed(fn)` cho nhạc.
- Game khai báo sau `HorusSDK.start()` (game mẫu `example/index.html`):

```js
platform.video.cheat('Mở hết map', () => game.unlockAllMaps());               // một nút
platform.video.number('Xu', () => S.coins, (v) => { S.coins = v; save(); }, { min: 0, step: 1000 });   // - / + / max / gõ số
platform.video.watch('Map', () => S.map);                                    // agent đọc để canh thời điểm
platform.video.ui('#hud-coins', 'Xu');                                        // tuỳ chọn: phần UI liệt kê đầu
```

  Game muốn đủ bộ đạo diễn (như Crash Ramp) khai báo thêm, bảng tự hiện ở tab Góc máy & cảnh:

```js
platform.video.cameras({ chase: { name: 'Bám sau', desc: 'Sau lưng xe', back: 9, up: 3.2, fov: 58 }, side: { ... } },
  (id, nums) => myCam.set(id, nums),                            // id null = trả camera gốc của game
  { fields: { back: ['Lùi sau xe (m)', -30, 40, 0.5], fov: ['FOV (độ)', 20, 110, 1] } });   // nhãn, min, max, bước của từng số
platform.video.shot('lava', { name: 'Xe qua dung nham', seconds: 11 }, () => director.play('lava'), () => director.stop());   // ▶ chạy, ● quay luôn
platform.video.toggle('Hiện HUD ở menu', () => hudOn, (on) => setHud(on));                        // một công tắc
platform.video.guide('Cảnh nhảy sông: map 0, xuất phát mét 478...');                               // thêm vào tab Hướng dẫn
```

  Số trong mỗi góc máy là số người dùng sửa được (ô số, đổi là thấy ngay; "Về số gốc", "Copy góc máy" ra JSON cho kịch bản). Kịch bản chạy bằng hàm của game (đổi map, xe, góc máy, quay chậm theo thời gian); ● bắt đầu quay tab, chạy kịch bản rồi tự dừng sau `seconds` giây (độ dài clip, đã tính cả đoạn quay chậm).

  Mỗi cheat làm như người chơi đạt được thật (ghi save, vẽ lại UI). Danh sách Chỉnh UI tự lấy các phần HTML không chứa canvas; đặt `id` cho phần UI chính để danh sách dễ đọc. UI vẽ trong canvas không chỉnh được ở bảng: thêm cheat cho nó. Trong app các lệnh này chỉ giữ lại, không làm gì.
- Agent làm bản cho video editor của một game, đủ như Crash Ramp: `horus-sdk/video/GAME-SETUP.md` (kê khai game, mở khoá, UI, góc máy, kịch bản, công tắc, kiểm, giao).
- Agent quay clip khớp từng khung (1080x1920, 60 khung/giây) bằng `horus-sdk/video/rec.mjs`: `horus-sdk/video/AGENTS.md`. Game Godot: cùng bảng trong addon, GODOT.md mục 10.

## 13. Logic game và công cụ three.js

SDK có sẵn các phần logic Horus dùng trong game của mình (ví dụ Crash Ramp). Chúng là hàm thuần trên các object nhỏ mà game giữ trong save, không tự gọi quảng cáo hay store: game vẫn gọi `platform.*`. Dùng qua `HorusSDK.<tên>` (thẻ script) hoặc `import { monetize, app } from './horus-sdk.mjs'`. Từng hàm có mô tả và tham số trong `horus-sdk.d.ts` (editor hiện gợi ý) và ở trang Tham chiếu API của trang tài liệu.

| Tên | Có gì |
| --- | --- |
| `monetize` | Khi nào được hiện interstitial (`interDue`, `noteInter`), chờ rewarded đang load (`waitRewarded`), các bước khi thiếu xu (`createShortLadder`: ads free, rồi 1, 2… gem hoặc chừng ấy ads), offer có hạn giờ (`offerState`, `due` chọn offer theo trigger, `shown`, `bought`, `openOffers`, `expired`: trang Làm game bước 13), ghi đè bằng Remote Config (`applyConfig`) |
| `liveops` | Đồng hồ và ngày lịch (`clock`, `dayKey`, `msToMidnight`, `fmtLeft`), A/B (`assignAB`), phiên và ngày quay lại, thu nhập khi vắng, quà 7 ngày, rương theo giờ, nhiệm vụ ngày (kèm thưởng xong hết: `claimMissionBonus`), lịch thông báo local theo giờ chơi (`planNotifications`), analytics có phễu FTUE (`createAnalytics`), ghi đè bằng Remote Config (`applyConfig`) |
| `economy` | Đường giá có làm tròn kiểu shop (`priceCurve`, `roundPrice`, `growthFor`: hệ số tăng để đi từ giá này tới giá kia sau n cấp), chọn BEST BUY (`bestBuy`), mô phỏng kinh tế cho 3 kiểu người chơi (`simulateEconomy`, `playProfile`) |
| `app` | Vỏ game three.js chỉnh cho điện thoại (`createApp`: renderer, viewport, vòng lặp tick cố định, mất context WebGL, governor chất lượng; hoặc từng phần `GameLoop`, `Viewport`, `Overlay`). Mượt hơn: `precompile` (dựng shader trước, khỏi giật lần đầu), `ShadowGate` (chỉ vẽ lại bóng khi có vật di chuyển), `createWorldUpdater` (chỉ tính lại ma trận vật đã đổi), `IdleScheduler` / `pointerIdle` (việc nặng chạy lúc người chơi không chạm). Hậu kỳ `createPost` (bloom, chớp màn, tint, vignette). Toast và tip `createPrompts` / `PromptQueue` / `PromptView`. Ghép mesh `mergeParts` / `mergePartsAsync` (trên worker). Cảnh vật chia đoạn dọc đường vẽ một lệnh mỗi loại: `InstanceWindow`. Chụp ảnh ra PNG `readPixelsAsync`, `trimAlpha`, `encodePng` |
| `fx` | Hiệu ứng GPU: tia lửa, khói, vòng, vết, số bay lên, xu bay về ví (`Fx`, `createCoinFly`, sprite `coinSprites` / `gemSprite`), tối đa 4 draw call; `formatNumber` (123K, 4M) |
| `perf` | Governor chất lượng (`QualityGovernor`), giới hạn khung cho màn 90/120 Hz (`FramePacer`), thống kê khung (`FrameStats`) và đo từng đoạn code (`SectionTimer`), thông tin máy (`deviceInfo`). iOS chạy 30 fps khi game nằm trong khung nhúng hoặc máy đang tiết kiệm pin: `embedded`, `tapWatch`, `capCause` cho biết lý do để game báo người chơi |

Vài cách dùng `liveops` hay gặp:

```js
const { liveops: LO } = HorusSDK;
// A/B: Firebase A/B Testing trên tham số Remote Config ab_price (mục Remote Config); game chỉ đọc nhánh
const arm = ['a', 'b'].includes(platform.rc.values.ab_price) ? platform.rc.values.ab_price : 'a';
// rương theo giờ: mở miễn phí mỗi 4 giờ, thêm 3 lần/ngày bằng quảng cáo
const CHEST = { every: 4 * LO.HOUR, adOpens: 3, reward: () => ({ coins: 200 }) };
const c = LO.chestInfo(S.chest, CHEST);              // { ready, left, adLeft, readyAt }
label.textContent = c.ready ? 'MỞ' : LO.fmtLeft(c.left);
const got = LO.openChest(S.chest, CHEST);            // phần thưởng, hoặc null khi chưa tới giờ
const more = LO.openChest(S.chest, CHEST, { viaAd: true });   // mở thêm sau khi xem hết rewarded (tối đa adOpens lần/ngày)
// thử giờ khi test: dời đồng hồ của mọi hàm liveops 1 ngày
LO.clock.shift += LO.DAY;
```

Trong Web Worker (ví dụ worker tính trước kết quả nâng cấp bằng luật của game) hay Node (mô phỏng kinh tế) dùng `horus-logic.mjs`: cùng `monetize`, `liveops`, `economy`, không có platform nên chạy được ở nơi không có `window`.

three.js không nằm trong SDK: game dùng bản three.js của mình và truyền nó vào (`THREE`), nên không bị hai bản.

```js
import * as THREE from 'three';
import { platform, start, monetize, app as A, fx as F } from './horus-sdk.mjs';

await start();
const scene = new THREE.Scene(), camera = new THREE.PerspectiveCamera(60, 1, 0.1, 500);
const fx = new F.Fx(THREE, scene);
const app = A.createApp({
  THREE, canvas: document.querySelector('canvas'),
  onResize: (w, h) => { camera.aspect = w / h; camera.updateProjectionMatrix(); },   // thiếu: hình bị kéo giãn
  onFrame: (now) => { fx.update(now / 1000); app.render(scene, camera); },
});
// app.live = false khi đang tải, tạm dừng, dưới quảng cáo; true khi chơi: governor chỉ đếm khung lúc live (không thì hạ độ nét oan)
app.start();

// rời bảng kết quả: interstitial khi luật cho phép
const ADS = { ...monetize.INTER_DEFAULTS };
monetize.applyConfig({ ads: ADS }, platform.rc.values);
// ctx đủ khoá: thiếu sinceStart thì luôn 'warmup', thiếu x2Skipped (interOnX2Skip = 1) thì luôn 'x2_taken', không bao giờ due
const { due, why } = monetize.interDue(S.ads, ADS, {
  now: Date.now(), runs: S.runs, noAds: S.noAds, x2Skipped: x2Offered && !x2Taken, sinceStart: (Date.now() - sessionStart) / 1000,
});
if (due && !platform.ads.busy() && platform.ads.ready().inter) { monetize.noteInter(S.ads, S.runs, Date.now()); await platform.ads.inter('result_exit'); }
```
