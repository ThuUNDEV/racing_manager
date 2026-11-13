# Horus SDK

Một file JavaScript cho game HTML5 (JS/TS, Phaser, Three.js, Cocos, PixiJS, Unity WebGL...) để chạy trong app Android và iOS của Horus: quảng cáo, mua trong app, analytics, Remote Config, lưu game, cloud save và thông báo; kèm logic kiếm tiền, giữ chân, kinh tế và công cụ three.js của Horus (mục 13).

Cách làm giống AppLovin MAX: anh/chị gắn SDK vào game và gọi API. Horus đóng gói app, gắn mạng quảng cáo, Firebase, Adjust, ký và đưa lên store. Anh/chị không cần Android Studio, Xcode hay tài khoản nào của Horus.

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
| `AGENTS.md` | Hướng dẫn cho AI agent (Claude Code, Cursor, Codex...) làm game với SDK |
| `GAME-GUIDE.md` | Từng bước làm một game như Crash Ramp: vòng chơi, kinh tế, quảng cáo, shop, offer, lưu, analytics, build |
| `CHANGELOG.md` | Các bản SDK |

Chạy game mẫu: mở thư mục gói bằng một web server bất kỳ (`npx serve .` hoặc Live Server của VS Code), vào `example/index.html`.

Làm game mới: đưa agent đọc `GAME-GUIDE.md` và làm từng bước (mỗi bước có mục "Xong khi").

Dùng AI agent: chép `AGENTS.md` vào gốc repo game (hoặc thêm một dòng vào `AGENTS.md` / `CLAUDE.md` sẵn có: "Đọc horus-sdk/AGENTS.md trước khi sửa phần quảng cáo, mua hàng, lưu game hay build").

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

```js
// Rewarded: chỉ thưởng khi ok = true
const r = await platform.ads.rewarded('double_coins');
if (r.ok) coins *= 2;
// r.reason khi không xem xong: 'closed' | 'not_ready' | 'error'

// Interstitial: giữa hai màn, game không cần chờ kết quả
await platform.ads.inter('level_end');

// Nút "Xem quảng cáo" chỉ sáng khi có quảng cáo
const ready = platform.ads.ready();          // { rv, inter }
platform.on('ads', (s) => { rvButton.disabled = !s.rv; });
platform.ads.load('rv');                     // sắp mời xem quảng cáo (màn kết quả, shop)
```

Tên placement là chữ thường, không dấu, ví dụ `double_coins`. Ghi đủ placement vào `horus-game.json`.

Trong khi quảng cáo chạy, app gửi `pause` (`reason: 'ad'`), xong thì `resume`: tắt nhạc và dừng game theo hai sự kiện này.

Vùng GDPR: khi `platform.ads.hasPrivacy` là true, Settings cần một nút "Privacy settings" gọi `platform.ads.privacy()`.

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

Nhiều ad unit: mặc định app chỉ chạy 1 rewarded và 1 interstitial. Khi Horus thêm ad unit phụ cho app, `platform.ads.tags` liệt kê tag của chúng; `platform.ads.units(['hi'])` (hoặc `'*'`) cho các unit đó load, mỗi lần hiện lấy quảng cáo đã load có giá cao nhất. Game mới ra nên giữ 1 unit tới khi ổn định.

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

```js
platform.an.log('level_end', { level: 12, stars: 3 });   // tên chữ thường, tham số phẳng
platform.an.result(true);                                // một lượt chơi thắng/thua
platform.an.earn('coin', 50, 'level');                   // nhận tiền trong game
platform.an.spend('coin', 120, 'upgrade_engine');        // tiêu tiền trong game
platform.an.balance('coin', game.coins);                 // số dư hiện tại
platform.an.user({ vip: 1 });                            // user property
```

Doanh thu quảng cáo, mua hàng, nguồn cài đặt (Adjust) và các user property chuẩn do app tự gửi; game không cần làm. User property có sẵn: `connection_type`, `config_version`, `purchase_count` và `ltv_revenue` (USD, không tính đơn test), `ua_network` / `ua_campaign` / `ua_adgroup` / `ua_creative`, `win_streak` / `lose_streak` (từ `an.result`), `<tên>_balance` (từ `an.balance`, gửi tối đa 2 giây một lần; app tự gửi phần còn chờ khi ra nền, muốn gửi ngay thì `platform.an.flush()`).

**Nguồn cài đặt.** `platform.ua` là `{ network, campaign, adgroup, creative }` của Adjust, hoặc `null` khi Adjust chưa biết (có thể tới trong phiên đầu: `platform.on('ua', ...)`). App cũng đặt user property `ua_campaign`..., nên Remote Config có thể đổi giá trị theo chiến dịch (điều kiện trên `ua_campaign`; phiên đầu dùng giá trị mặc định, lần mở sau mới theo chiến dịch).

**Máy tester.** `platform.an.block?.(true)` tắt mọi tracking trên máy đó (Firebase, Adjust, Facebook, kể cả doanh thu quảng cáo và mua hàng) và giữ qua các lần mở app. Gọi từ menu ẩn của tester để số liệu thật không lẫn số thử.

## 6. Remote Config

```js
const every = Number(platform.rc.values.inter_every ?? 2);
```

Giá trị luôn là chuỗi. Ghi các khóa và giá trị mặc định vào `horus-game.json`; Horus đặt chúng trên Firebase và đổi được mà không cần bản mới.

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

Game đã có cách lưu riêng thì chỉ cần gọi `platform.save.mirror(JSON.stringify(state))` mỗi lần lưu và đọc lại `platform.save.backup` khi localStorage trống.

## 8. Cloud save

Bật sẵn trong `start()`. Mỗi bản `mirror` được app đưa lên server khi có mạng; người chơi đổi máy hoặc cài lại vẫn giữ tiến độ.

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

Để `mergePurchases` làm được việc, mỗi đơn đã giao được ghi vào `buys` của bản lưu: `{ sku, token, t: Date.now() }`.

`settleAtBoot` tự quyết xung đột lúc mở và trả `null` (không có gì), hoặc `{ took: 'cloud' | 'local', forced, added }`. Khi `took === 'cloud'` hay `added > 0`, báo người chơi một dòng ("Đã lấy tiến độ từ cloud", "Đã trả lại 3 món đã mua").

**Save theo người chơi sang máy mới (Android, Play Games Recall, từ SDK 0.12.0).** Cloud save giữ save theo từng máy. Khi người chơi đã đăng nhập Play Games, SDK tự gắn save với tài khoản Play Games đó; lần đầu cài game trên máy mới mà chưa có gì, SDK hỏi server save của máy cũ và báo bằng xung đột như mọi xung đột khác (`e.recall` là true): game chọn bản đi xa hơn như bình thường. Game không phải gọi gì thêm; cần app build có module `games` và server cloud save của game bản mới (Horus deploy).

**Save theo Apple ID sang iPhone mới (iOS, iCloud Keychain, từ SDK 0.13.0).** Bật `"icloud": true` trong `sdk.cloudsave` của phần `ios` trong webgame.config.json: mã người chơi có thêm một bản trong iCloud Keychain, nên mọi iPhone / iPad cùng Apple ID là cùng một người chơi, kể cả máy mới cài từ đầu không khôi phục sao lưu. Máy đã có mã riêng sẽ đổi sang mã chung ở lần mở sau: cloud save gặp save của máy kia thành xung đột, game chọn bản đi xa hơn như bình thường, và Support ID của máy đó đổi. Mặc định tắt; game không phải gọi gì thêm.

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

**Chế độ game và nhiệt độ máy (Android, từ SDK 0.10.0, app build từ webgame 0.28.0).** `platform.device.gameMode` là lựa chọn của người chơi trong Game Dashboard (`'battery'`: giới hạn fps, bỏ bớt hiệu ứng; `'performance'`: bậc chất lượng cao nhất; `'standard'`, `'custom'`, `'unsupported'`), đổi thì có sự kiện `'gamemode'`. `platform.device.thermal` `{ status, headroom }` cho biết máy nóng tới đâu (sự kiện `'thermal'`; từ `'moderate'` hoặc headroom ≥ 0,8 thì hạ một bậc hiệu ứng / fps). `platform.gameState('play')` khi vào lượt chơi, `'menu'` khi ra, `'content'` khi có quảng cáo. `platform.device.exits` là các lần trước Android tắt game (hết bộ nhớ, ANR...), gửi vào analytics lúc mở game. Trên iOS và trình duyệt các giá trị là `'unsupported'` / `'unknown'` / `[]`.

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

**Thông tin app.** `platform.info`: `{ name, version, build, lang, debug, modules, tampered }`. `lang` là ngôn ngữ của máy (chọn ngôn ngữ mặc định cho game), `modules` là các module có trong bản build (ví dụ `'review'`), `tampered` là bản app bị sửa và ký lại. `platform.target` là `'web'`, `'android'` hay `'ios'`. `platform.exit()` đưa app ra nền (ví dụ nút "Thoát" của hộp hỏi khi bấm Back).

Thông báo nhắc chơi và push: mục 10. Đánh giá trong app, bảng xếp hạng và thành tích, shortcut trên icon, báo lỗi Crashlytics: mục 11. Toàn bộ API có trong `horus-sdk.d.ts`, mỗi hàm có chú thích.

## 10. Thông báo (nhắc chơi và push)

Có hai loại, cùng chạy trên Android và iOS:

- **Thông báo nhắc (local):** game tự đặt lịch trên máy, không cần server. Dùng để báo quà đã sẵn, nâng cấp mua được, gọi người chơi quay lại.
- **Push từ Firebase:** gửi từ Firebase console tới mọi máy (topic, ví dụ `all`), hiện khi app ở nền. Horus bật module `firebase-messaging` trong cấu hình app của game; trên iOS cần thêm khoá APNs (.p8) trên Firebase. Game không phải gọi gì.

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

**Báo lỗi lên Crashlytics.** Lỗi JavaScript không tự lên Crashlytics; game bắt và gửi dạng non-fatal, kèm vài key giúp tìm lỗi:

```js
addEventListener('error', (e) => platform.crash(String(e.message), e.error?.stack));
addEventListener('unhandledrejection', (e) => platform.crash(String(e.reason?.message || e.reason), e.reason?.stack));
platform.crashKeys({ level: S.level, screen: 'shop' });   // hiện trên mỗi báo lỗi; app đã tự gắn phiên bản app, module, kích thước save và mọi user property
```

## 12. Build ra app (Build online)

Anh/chị không build app trên máy mình. `horus-build.mjs` gửi bản build web lên máy build của Horus; máy đó gắn gamekit, ký app và trả về APK (cài thử) hoặc AAB, hoặc đưa thẳng lên **Google Play (internal)** hay **TestFlight** (iOS build trên Mac của Horus). Cần Node 18 trở lên, không cần cài gì thêm. Các lệnh dưới đây coi như gói SDK được chép vào thư mục `horus-sdk/` trong repo game.

**Một lần:** điền `horus-game.json` ở gốc thư mục game (chép từ gói SDK), xin Horus một **mã build** cho team rồi lưu lại:

```
node horus-sdk/horus-build.mjs --key <mã build>
```

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
```

Lệnh in từng bước: `[1/N] đóng gói`, rồi các bước trên máy build của Horus (chuẩn bị game, kiểm tra, Gradle, lên Google Play; iOS: gửi sang Mac, build và TestFlight) kèm %, rồi `[N/N] tải app`. File để ở `build-online/<tên game>-<mã job>.zip` (trong zip là `app-release.apk` hoặc `.aab`). Thêm `build-online/` vào `.gitignore`. Ctrl+C lúc đang chờ thì **dừng job trên máy build** (bản lên Play làm dở được xoá, bản iOS trên Mac dừng theo).

**Lên store:**
- `--play`: version code tự lấy cao hơn bản trên Play, không phải tăng tay. Track `internal`; `alpha` / `beta` chỉ khi Horus cho (`--track beta`). Production do Horus phát hành trong Play Console, không bao giờ từ lệnh này.
- `--ios`: số build tự lấy cao hơn bản trên TestFlight; Apple xử lý 5 đến 30 phút rồi hiện cho tester. Không có file tải về (bản App Store chỉ cài qua TestFlight). Một lần build iOS mất khoảng 15 đến 25 phút.
- Cả hai chỉ chạy khi Horus đã cài đặt game cho team (`appId` Horus cấp; iOS thêm bundle id và team Apple). Chưa cài thì lệnh báo lý do.

Các tuỳ chọn khác:
- `node horus-sdk/horus-build.mjs <thư mục game>`: chạy từ chỗ khác.
- `--dry-run`: chỉ đóng gói và kiểm tra, không gửi. Nên chạy trước lần gửi đầu.
- `--no-wait`: gửi xong thoát và in mã job; theo dõi và lấy app sau bằng `--job <mã>`.
- `--cancel <mã>`: dừng một job đang chờ hoặc đang build.
- `--out <thư mục>`: chỗ để file tải về.

**Link repo:** mỗi lần gửi, lệnh gửi kèm link repo git của game (`git remote get-url origin`, không gửi tên đăng nhập hay token), nhánh và commit. Horus giữ link này cho từng game và có thể build bản mới nhất từ repo (nhớ cho tài khoản Horus quyền đọc repo). Game chưa có remote thì đặt `repo` trong `horus-game.json`; thiếu link thì máy build của Horus có thể từ chối job.

**SDK luôn mới:** mỗi lần gửi build, lệnh hỏi máy chủ build của Horus (bằng mã build) có Horus SDK mới không. Có bản mới cùng major thì lệnh tự thay các file của SDK trong `horus-sdk/` (và các bản sao `horus-sdk.js` / `horus-sdk.mjs` / `horus-logic.mjs` khác trong game, trừ `node_modules`), giữ bản cũ ở `horus-sdk/.old/<phiên bản>/`, rồi mới build và gửi. Bản đổi lớn (major) chỉ báo: đọc CHANGELOG rồi chạy `node horus-sdk/horus-build.mjs update --major`. Cập nhật không cần gửi build: `node horus-sdk/horus-build.mjs update`. Không muốn tự cập nhật: `--no-update` cho một lần, hoặc `"sdkUpdate": false` trong `horus-game.json` (khi đó lệnh chỉ báo có bản mới). Bản web build bằng bundler thì build lại sau khi SDK đổi (`--build-web` làm việc đó trong cùng lệnh).

**Những gì được gửi:** `horus-game.json`, thư mục web (`web` trong `horus-game.json`; không ghi thì lấy `dist`, `build`, `www` hay `public` có `index.html`) và icon (`icon`, mặc định `icon.png`; cùng các icon phụ `iosIcons`). Không gửi source game, `node_modules` hay file `.map`.

**`horus-game.json`:**

| Khoá | Ý nghĩa |
| --- | --- |
| `name` | Tên game (bắt buộc) |
| `version`, `versionCode` | Phiên bản hiện cho người chơi (`1.2.0`) và số build Google Play (tăng mỗi lần lên store) |
| `appId` | Package name Horus cấp, ví dụ `com.horus.mygame`. Để trống: app thử `com.horus.buildtest.<tên>` |
| `web` | Thư mục bản build web, tương đối với thư mục game |
| `repo` | Link repo git của game (để trống: lấy `git remote origin`). Horus lưu link repo của mỗi game và có thể tự build từ source mới nhất |
| `build` | Lệnh build web (mặc định `npm run build`), Horus dùng khi build từ source |
| `icon` | Icon PNG 1024×1024 không bo góc |
| `iosIcons` | (SDK 0.8.0) Icon phụ của app iOS để thử bằng Product Page Optimization: `{ "tên": "file.png" }`, PNG 1024×1024 không trong suốt; tên gồm chữ, số, `-`, `_`. Apple chỉ thử icon có sẵn trong bản build, nên thêm trước khi gửi bản lên TestFlight |
| `orientation`, `colors.background` | Hướng màn hình, màu nền lúc mở app |
| `notif` | (0.34.0) Âm thanh riêng của thông báo nhắc: `{ "sound": "sfx/notify.wav", "headsUp": true }`. `sound` là file `.wav` ngắn trong bản build web (đường dẫn tính từ thư mục `web`), dùng cho cả Android và iOS; `headsUp` (Android) cho thông báo trồi xuống đầu màn hình |
| `ads`, `products`, `remoteConfig`, `events`, `languages`, `support`, `notes` | Để Horus cài quảng cáo, store, Firebase cho game |

**Bản thử và bản phát hành.** Khi Horus chưa cài đặt game (chưa có `appId` hoặc team chưa được duyệt cho `appId` đó), anh/chị nhận APK thử: chạy được để xem game trong app, nhưng chưa có quảng cáo, mua hàng và analytics thật. Khi Horus đã cài đặt game, cùng lệnh đó ra app đầy đủ, `--aab` ra bản AAB, `--play` đưa lên Google Play internal và `--ios` đưa bản iOS lên TestFlight.

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

## 13. Logic game và công cụ three.js

SDK có sẵn các phần logic Horus dùng trong game của mình (ví dụ Crash Ramp). Chúng là hàm thuần trên các object nhỏ mà game giữ trong save, không tự gọi quảng cáo hay store: game vẫn gọi `platform.*`. Dùng qua `HorusSDK.<tên>` (thẻ script) hoặc `import { monetize, app } from './horus-sdk.mjs'`. Từng hàm có mô tả và tham số trong `horus-sdk.d.ts` (editor hiện gợi ý) và ở trang Tham chiếu API của trang tài liệu.

| Tên | Có gì |
| --- | --- |
| `monetize` | Khi nào được hiện interstitial (`interDue`, `noteInter`), chờ rewarded đang load (`waitRewarded`), các bước khi thiếu xu (`createShortLadder`: ads free, rồi 1, 2… gem hoặc chừng ấy ads), offer có hạn giờ (`offerState`, `due` chọn offer theo trigger, `shown`, `bought`, `openOffers`, `expired`: trang Làm game bước 13), ghi đè bằng Remote Config (`applyConfig`) |
| `liveops` | Đồng hồ và ngày lịch (`clock`, `dayKey`, `msToMidnight`, `fmtLeft`), A/B (`assignAB`), phiên và ngày quay lại, thu nhập khi vắng, quà 7 ngày, rương theo giờ, nhiệm vụ ngày (kèm thưởng xong hết: `claimMissionBonus`), lịch thông báo local theo giờ chơi (`planNotifications`), analytics có phễu FTUE (`createAnalytics`), ghi đè bằng Remote Config (`applyConfig`) |
| `economy` | Đường giá có làm tròn kiểu shop (`priceCurve`, `roundPrice`, `growthFor`: hệ số tăng để đi từ giá này tới giá kia sau n cấp), chọn BEST BUY (`bestBuy`), mô phỏng kinh tế cho 3 kiểu người chơi (`simulateEconomy`, `playProfile`) |
| `app` | Vỏ game three.js chỉnh cho điện thoại (`createApp`: renderer, viewport, vòng lặp tick cố định, mất context WebGL, governor chất lượng; hoặc từng phần `GameLoop`, `Viewport`, `Overlay`). Mượt hơn: `precompile` (dựng shader trước, khỏi giật lần đầu), `ShadowGate` (chỉ vẽ lại bóng khi có vật di chuyển), `createWorldUpdater` (chỉ tính lại ma trận vật đã đổi), `IdleScheduler` / `pointerIdle` (việc nặng chạy lúc người chơi không chạm). Hậu kỳ `createPost` (bloom, chớp màn, tint, vignette). Toast và tip `createPrompts` / `PromptQueue` / `PromptView`. Ghép mesh `mergeParts` / `mergePartsAsync` (trên worker). Chụp ảnh ra PNG `readPixelsAsync`, `trimAlpha`, `encodePng` |
| `fx` | Hiệu ứng GPU: tia lửa, khói, vòng, vết, số bay lên, xu bay về ví (`Fx`, `createCoinFly`, sprite `coinSprites` / `gemSprite`), tối đa 4 draw call; `formatNumber` (123K, 4M) |
| `perf` | Governor chất lượng (`QualityGovernor`), giới hạn khung cho màn 90/120 Hz (`FramePacer`), thống kê khung (`FrameStats`) và đo từng đoạn code (`SectionTimer`), thông tin máy (`deviceInfo`). iOS chạy 30 fps khi game nằm trong khung nhúng hoặc máy đang tiết kiệm pin: `embedded`, `tapWatch`, `capCause` cho biết lý do để game báo người chơi |

Vài cách dùng `liveops` hay gặp:

```js
const { liveops: LO } = HorusSDK;
// A/B: chia một lần, giữ trong save; gửi nhóm làm user property để so trên Firebase
const fresh = LO.assignAB(S.ab, { price_test: { variants: ['a', 'b'], weights: [1, 1] } });
if (fresh.length) platform.an.user({ ab_price: S.ab.price_test });
// rương theo giờ: mở miễn phí mỗi 4 giờ, thêm 3 lần/ngày bằng quảng cáo
const CHEST = { every: 4 * LO.HOUR, adOpens: 3, reward: () => ({ coins: 200 }) };
const c = LO.chestInfo(S.chest, CHEST);              // { ready, left, adLeft, readyAt }
label.textContent = c.ready ? 'MỞ' : LO.fmtLeft(c.left);
const got = LO.openChest(S.chest, CHEST);            // null khi chưa tới giờ; { viaAd: true } sau khi xem rewarded
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
const app = A.createApp({ THREE, canvas: document.querySelector('canvas'), onFrame: (now) => { fx.update(now / 1000); app.render(scene, camera); } });
app.start();

// rời bảng kết quả: interstitial khi luật cho phép
const ADS = { ...monetize.INTER_DEFAULTS };
monetize.applyConfig({ ads: ADS }, platform.rc.values);
const { due } = monetize.interDue(S.ads, ADS, { now: Date.now(), runs: S.runs, noAds: S.noAds });
if (due && platform.ads.ready().inter) { monetize.noteInter(S.ads, S.runs, Date.now()); await platform.ads.inter('result_exit'); }
```
