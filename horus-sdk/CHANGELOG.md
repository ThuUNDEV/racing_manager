# CHANGELOG của Horus SDK (@horus/sdk)

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), phiên bản theo semver.

## [Unreleased]

## [0.21.1] - 2026-10-27

### Sửa

- `@horus/webgame` ^0.46.1: nhịp hot update gửi tới khi vỏ tính lần mở là chạy được (không còn dừng sau 30 giây); lỗi JS chưa bắt báo vỏ `ok: false`.

## [0.21.0] - 2026-10-27

### Đổi

- `@horus/webgame` ^0.46.0: hot update không còn bỏ bản tốt khi người chơi mở rồi tắt nhanh (nhịp `app.hot.beat` sau `app.ready`); APK thử của game bật MAX Ad Review build được trở lại. Bản hot build từ SDK này mới gửi nhịp.

## [0.20.6] - 2026-10-27

### Đổi

- `@horus/webgame` ^0.45.2: APK test của Build online không còn gửi mapping R8 và native symbols lên Crashlytics của app thật.

## [0.20.5] - 2026-10-27

### Thêm

- `KIT`: bản horus-gamekit mà SDK này build ra (ghi lúc build). SDK Status có dòng `Horus SDK: <phiên bản> (kit <phiên bản>)` ngay dưới `Shell:`, trong email hỗ trợ và màn Tools của game. Gói kèm `@horus/webgame` 0.45.1 (sửa build TestFlight có MAX Ad Review hỏng ở bước archive).

## [0.20.4] - 2026-10-27

### Đổi

- Gói kèm `@horus/webgame` 0.45.0 (Ad Review cùng R8 và luật giữ subscriber Moloco, phía build Android; client JS không đổi).

## [0.20.3] - 2026-10-26

### Đổi

- Gói kèm `@horus/webgame` 0.44.0 (MAX Ad Review không cần dán key, phía build; client không đổi).

## [0.20.2] - 2026-10-26

### Đổi

- Gói kèm `@horus/webgame` 0.43.0 (hàng chờ build online nhẹ, phía server; client không đổi).

## [0.20.1] - 2026-10-26

### Sửa

- Thẻ Cập nhật nóng: ô bản store ghi một versionCode Android mỗi lần phát (webgame 0.42.0 từ chối danh sách nhiều bản); gói kèm webgame 0.42.0 (cập nhật nóng chắc hơn: bản hỏng sau `app.ready` tự quay về, `seq` chống phát lại bản cũ, giới hạn kích thước, renderer chết ở nền không tính lỗi).

## [0.20.0] - 2026-10-26

### Thêm

- Trang build (`HorusBuild.cmd`, `horus-build.mjs ui`) có thẻ **Cập nhật nóng** trên máy build của Horus: trạng thái, Phát bản nóng (build lại bản web trước), Lên %, Rút lại, Tắt / Bật, mỗi nút một lượt chạy có bước, % và nút Dừng. Máy của studio không có thẻ này, trang build của studio không đổi gì (cần webgame 0.41.0). Gợi ý: minor (0.20.0).
- `dev/GAME-GUIDE.md`: bài học Crash Ramp v87–v90 (60 khung/giây, nhạc .mp3, thông báo, mã quà, tham số `build`, robot, GAME_BUILD và cập nhật nóng); gói kèm `@horus/liveops` 1.1.0 (mã quà có trần `redeemCode`, tham số `build` trên mọi event, quay lại sau thông báo tính là phản hồi).

## [0.19.0] - 2026-10-26

### Thêm

- **Cập nhật nóng** (`platform.hot`, app build từ webgame 0.40.0): Horus phát bản web mới của game, app tải, kiểm chữ ký và chạy nó từ lần mở sau, không cần bản store; mặc định tắt, Horus bật cho từng game. `platform.hot.active` / `pending` / `check()` / `apply()`. Hướng dẫn: README mục 11.

## [0.18.1] - 2026-10-25

### Sửa

- Bản Android (webgame 0.39.0): file mapping R8 gửi Play kèm mỗi bản, stack trace crash/ANR đọc được trong Play Console; androidx.fragment 1.8.9 (Play hết cảnh báo thư viện fragment cũ).

## [0.18.0] - 2026-10-25

### Thêm

- `platform.share.open({ title, text, url, image })`: bảng chia sẻ của máy (ảnh, chữ, link) cho thẻ kết quả, thách đấu, mời bạn; web dùng `navigator.share` hoặc chép vào clipboard (webgame 0.38.0). Kiểu `ShareContent`, `ShareResult`.

## [0.17.0] - 2026-10-25

### Thêm

- Bắt crash rõ hơn (webgame 0.37.0): Android báo cả crash trong thư viện native (Crashlytics NDK, symbol tự gửi Firebase khi build); iOS báo treo máy, CPU quá tải và app bị hệ thống tắt (MetricKit) lên Crashlytics. Tắt NDK: horus-game.json / webgame.config.json `sdk.firebase-crashlytics.ndk: false`.

## [0.16.1] - 2026-10-25

### Sửa

- Debug symbols native gửi Play kèm bản Android (webgame 0.36.0): các thư viện native của SDK quảng cáo đã bị nhà cung cấp xoá symbol, nay kèm bảng symbol các hàm public của chúng để Play hết cảnh báo thiếu debug symbols.

## [0.16.0] - 2026-10-25

### Thêm

- Bản Android (AAB) có debug symbols native do Gradle đóng sẵn (webgame 0.35.0, horus-game.json `android.ndkVersion`, `android.debugSymbols`): Play hết cảnh báo "you've not uploaded debug symbols". Máy build cần NDK cài trong Android SDK.

## [0.15.0] - 2026-10-25

### Thêm

- horus-game.json `notif { sound, headsUp }`: âm thanh riêng và thông báo trồi đầu màn hình cho lời nhắc (webgame 0.34.0); lời nhắc Android chạy bằng báo thức nên đến đúng giờ hơn.

## [0.14.0] - 2026-10-25

### Thêm

- `platform.device.setFrameRate` / `display`, `platform.testLoop`, `platform.device.robot` (webgame 0.33.0, Android); README mục 9. Doanh thu IAP không mất / không tính hai lần, mã khuyến mãi và quà Play không tính là doanh thu (webgame 0.33.0, cloudsave 1.9.0).

## [0.13.1] - 2026-10-25

### Đổi

- Dùng `@horus/webgame` ^0.32.0 (debug symbols native gửi Google Play cùng AAB, bản tải Build online có `native-debug-symbols.zip`); SDK trong game không đổi.

## [0.13.0] - 2026-10-25

### Thêm

- iOS: `sdk.cloudsave.icloud` (webgame 0.31.0, cloudsave 1.8.0): mã người chơi đồng bộ qua iCloud Keychain, save theo Apple ID sang iPhone / iPad mới; README mục 8.

## [0.12.0] - 2026-10-24

### Thêm

- Play Games Recall: `platform.games.recall` / `recallSession()` (webgame 0.30.0) và cloud save tự mang save sang máy mới của cùng người chơi (cloudsave 1.7.0, xung đột có `recall: true`); README mục 8.

## [0.11.0] - 2026-10-24

### Thêm

- `platform.update` (`check`, `start`, `complete`, sự kiện `'update'`): cập nhật trong app của Google Play (module `update` của webgame 0.29.0, Android); README mục 11 có cách dùng.

## [0.10.0] - 2026-10-24

### Thêm

- `platform.device` (`gameMode`, `thermal`, `exits`), sự kiện `'gamemode'` / `'thermal'` và `platform.gameState()` (Android, webgame 0.28.0) trong `horus-sdk.d.ts`; README mục 9 có cách dùng.

## [0.9.1] - 2026-10-24

### Thêm

- Sự kiện `'trim'` (Android thiếu bộ nhớ, webgame 0.27.1) trong `horus-sdk.d.ts`; README mục 9 có cách dùng.

## [0.9.0] - 2026-10-24

### Thêm

- `platform.games.stats` và `platform.games.stat(name, props)`: Game Stats của Play Games cho chương trình Level Up (webgame 0.27.0, Android). README mục 11 có cách dùng.

## [0.8.0] - 2026-10-24

### Thêm

- horus-game.json `"iosIcons": { "tên": "file.png" }`: icon phụ của app iOS (PNG 1024×1024, không trong suốt) được gửi cùng bản build (`files/ios/AppIcon-<tên>.png`), để thử icon bằng Product Page Optimization của App Store.
- `platform.games.social`, `challenge()`, `activity()`, `play`, `takePlay()` và sự kiện `'gamesPlay'` (Game Center Challenges + Activities trên iOS 26, webgame 0.26.0) trong `horus-sdk.d.ts`.
- README mục 11: thách đấu và hoạt động Game Center; mục 12: khoá `iosIcons`.

## [0.7.0] - 2026-10-24

### Thêm

- `platform.games` (Game Center / Play Games, module `games` của @horus/webgame 0.25.0) và `platform.info.fontScale` trong `horus-sdk.d.ts` (từ `js/index.d.ts` của webgame khi build).
- README mục 11 (đổi tên "Đánh giá, bảng xếp hạng, shortcut, báo lỗi"): cách dùng `platform.games` và `platform.info.fontScale`.
- GAME-GUIDE bước 20 "Để được store feature": trợ năng (Reduce motion, Larger text, vùng chạm 48px), Game Center / Play Games, sự kiện mùa, việc trên App Store Connect và Play Console, đề cử.

## [0.6.4] - 2026-10-24

### Tài liệu

- README mục 13: bảng công cụ nêu đủ các phần của `app` (precompile, ShadowGate, createWorldUpdater, IdleScheduler, createPost, createPrompts, mergeParts, chụp PNG, GameLoop / Viewport / Overlay), `perf` (QualityGovernor, FramePacer, FrameStats, SectionTimer, deviceInfo, embedded / tapWatch / capCause), offer của `monetize`, `liveops.applyConfig`, `economy.growthFor` / `playProfile`, `fx.formatNumber` và sprite. Thêm `start({ cloudWait })`, `ads.simulate(fn, { loadMs })`, `usd` của `iap.finish` và `ltv_revenue`, danh sách user property có sẵn và `an.flush()`, `support.diag` / `report` / `mail`, dịch dòng trạng thái cloud (`STATUS_WORDS`, `ago`). Code không đổi.

## [0.6.3] - 2026-10-24

### Tài liệu

- README: mục 4 sự kiện `'purchase'` (đơn tới khi game đang chạy), `'prices'`, đơn `state: 'pending'` chưa giao (ví dụ cũ giao cả đơn pending từ `pending()`), đơn test (`test: true`); mục 7 `before` / `after` / `economy` / `version` / `omit` / `seal` / `fitArray` của kho lưu và nút xoá tiến độ (`wipe` + `save`); mục 8 kết quả `settleAtBoot`, xung đột giữa lúc chơi (sự kiện `'cloud'`, `takeCloud`, `keepLocal`), `cloud.sync()`, `cloud.enabled`; mục 13 ví dụ `liveops` (A/B, rương theo giờ, dời đồng hồ khi test). Code không đổi.

## [0.6.2] - 2026-10-24

### Tài liệu

- README bổ sung những tính năng chỉ có trong `horus-sdk.d.ts`: mục 3 giá trị quảng cáo (`ready()` `rvValue` / `interValue`, sự kiện `'adpaid'`), segment MAX (`ads.setSegments`), ad unit phụ (`ads.tags` / `ads.units`), `ads.mediationDebugger()`; mục 5 nguồn cài đặt (`platform.ua`, sự kiện `'ua'`) và `an.block` cho máy tester; mục 9 vùng an toàn (`--sat` / `--sab` / `--sal` / `--sar`, sự kiện `'insets'`), `platform.info`, `platform.target`, `platform.exit()`, `contact` khi không có mạng; mục 11 mới "Đánh giá, shortcut trên icon, báo lỗi" (`platform.review()`, `platform.shortcuts`, `platform.crash` / `crashKeys`). Build ra app thành mục 12, Logic game thành mục 13. Code không đổi.

## [0.6.1] - 2026-10-24

### Tài liệu

- README mục 10 mới "Thông báo (nhắc chơi và push)": xin quyền, đặt lịch khi ra nền và xoá khi quay lại, kênh `rewards` / `comeback` / `news`, số trên icon, mở đúng màn khi bấm (`notif.opened`, sự kiện `'notif'`), công tắc trong Settings (`notif.state()` / `settings()`), lịch có sẵn `liveops.planNotifications`, push Firebase, `notif_shown` / `notif_open`. Build ra app thành mục 11, Logic game thành mục 12. Code không đổi.

## [0.6.0] - 2026-10-24

### Thêm

- `platform.ads.ready()` có `rvValue` / `interValue` (giá ước tính USD một lượt của ad đã load) và `rvNet` / `interNet`; sự kiện `'adpaid'` mỗi lượt hiện MAX trả tiền; `platform.ads.setSegments({...})` (segment MAX từ lần mở app sau); `platform.ads.units(tags | '*')` + `platform.ads.tags` cho ad unit phụ (`rewardedExtra` / `interstitialExtra` trong cấu hình app, mặc định không dùng: 1 rewarded + 1 interstitial như cũ). Game cũ không đổi gì vẫn chạy y như trước; game mới nên kiểm tra hàm có không (`platform.ads.setSegments?.(...)`) để chạy được với app build trước 0.24.0.
- `platform.review()`: hộp đánh giá của Google Play / App Store ngay trong game, `{ shown }` (`shown: true` là đã hỏi store, không có nghĩa hộp thoại đã hiện), có trong `horus-sdk.d.ts`. Bản build của game cần bật đánh giá trong cài đặt trên máy build Horus; không bật và trên trình duyệt: `{ shown: false }`. Cần `@horus/webgame` 0.24.0.

### Đổi

- Đi kèm `@horus/webgame` ^0.24.0.

## [0.5.0] - 2026-10-23

### Thêm

- SDK tự cập nhật: mỗi lần gửi build, `horus-build.mjs` (và trang build) hỏi máy chủ build của Horus bằng mã build; có bản mới cùng major thì thay các file SDK trong `horus-sdk/` và các bản sao `horus-sdk.js` / `.mjs` / `horus-logic.mjs` khác của game, giữ bản cũ ở `horus-sdk/.old/<phiên bản>/`, trước khi build và gửi. Bản đổi lớn chỉ báo. `node horus-build.mjs update [--major]` cập nhật không cần build; `--no-update` hoặc `"sdkUpdate": false` trong `horus-game.json` để chỉ báo. README mục 10, AGENTS.md.
- `build.mjs`: `pack()` (và `--zip <file>`) ra đúng zip studio nhận (file dưới `horus-sdk/`, cùng SDK thì cùng byte).

### Đổi

- Đi kèm `@horus/webgame` ^0.23.0.

## [0.4.4] - 2026-10-23

### Đổi

- `GAME-GUIDE.md` (trong gói): từng bước làm một game như Crash Ramp, mỗi bước có "Xong khi"; AGENTS.md có mục "Làm game mới" trỏ tới nó.
- README mục 11: `fx.update(now / 1000)` (thời gian tính bằng giây, không phải dt).
- README bỏ mục Điều khoản; dòng đầu các file SDK chỉ còn `Horus SDK <phiên bản> | (c) Horus Entertainment`.

## [0.4.3] - 2026-10-23

### Sửa

- `horus-build.mjs` / trang build: mất mạng một lúc khi chờ máy build không còn làm dừng theo dõi job (dòng "mất kết nối tới máy chủ build, đang thử lại", rồi "đã kết nối lại"); chỉ dừng sau 15 phút không có câu trả lời. Đi kèm `@horus/webgame` 0.22.1.

## [0.4.2] - 2026-10-23

### Đổi

- Phụ thuộc `@horus/webgame` ^0.22.0.

## [0.4.1] - 2026-10-23

### Đổi

- Phụ thuộc `@horus/webgame` ^0.21.0.

## [0.4.0] - 2026-10-23

### Thêm

- Logic game và công cụ three.js của Horus trong SDK, dạng namespace: `monetize` (interstitial, chờ rewarded, bậc thiếu xu, Remote Config), `liveops` (ngày, quà, nhiệm vụ, thu nhập khi vắng, lịch thông báo, analytics phễu FTUE), `economy` (đường giá, BEST BUY, mô phỏng), `app` (vỏ game three.js), `fx` (hiệu ứng GPU), `perf` (governor chất lượng, khung hình). three.js không nằm trong SDK: game truyền `THREE` vào. README mục 11. `horus-sdk.js` lớn lên khoảng 117 KB.
- `horus-logic.mjs`: chỉ `monetize`, `liveops`, `economy`, không có platform: dùng trong Web Worker hay Node.
- Trang build và lệnh: `--build-web` / ô "build lại trước khi gửi" chạy `build` của `horus-game.json` (ví dụ `npm run build`) trên máy mình trước khi đóng gói, log hiện từng dòng, Dừng thì dừng luôn lệnh đó. Có `build` thì ô này bật sẵn.
- `HorusBuild.cmd` (Windows): bấm đúp là mở trang build. Game là thư mục kéo thả vào file, hoặc thư mục ngay trên `horus-sdk\` khi có `horus-game.json`, không thì game thử `example`. Báo khi chưa có Node 18+.

## [0.3.0] - 2026-10-23

### Thêm

- `node horus-build.mjs ui`: trang build trên trình duyệt, giống trang `npx webgame ui` của Horus: lưu mã build, sửa `horus-game.json`, kiểm tra bản web, gửi build (APK, AAB, lên Google Play, iOS lên TestFlight), từng bước và %, log, nút Dừng, job gần đây.
- `--play [--track internal|alpha|beta]`: máy build của Horus build AAB rồi đưa lên Google Play (version code tự tăng). `--ios`: build iOS trên Mac của Horus rồi lên TestFlight (số build tự tăng). Production không bao giờ từ đây.
- Mỗi lần gửi kèm link repo git của game (lấy từ `git remote origin`, không gửi user hay token), nhánh và commit. Horus có thể bắt buộc link repo: không có thì job bị từ chối. `horus-game.json` thêm `repo` (khi git không có remote) và `build` (lệnh build web, Horus dùng khi tự build từ source).
- Lúc chờ in các bước trên máy build của Horus kèm %. Ctrl+C dừng cả job trên máy build; `--cancel <mã>` dừng một job.

## [0.2.0] - 2026-10-22

### Thêm

- `horus-build.mjs`: build app không cần Android Studio. `node horus-build.mjs` gửi bản build web + `horus-game.json` + icon cho Horus và tải về APK (cài thử) hoặc AAB (`--aab`, lên Google Play). `--key` lưu mã build của team, `--dry-run` chỉ kiểm tra, `--no-wait` / `--job` gửi trước lấy sau. Cần Node 18+.
- `horus-game.json` có thêm `appId` (Horus cấp), `versionCode`, `web` (thư mục bản build), `icon`.
- `AGENTS.md`: quy tắc và lệnh cho AI agent (Claude Code, Cursor, Codex...) làm game với SDK.
- `example/` là một game đủ thư mục (có `horus-game.json` và `horus-sdk.js`): `node horus-build.mjs example` build thử được ngay.
- README mục 10 viết lại: Build online thay cho gửi zip bằng tay.

## [0.1.2] - 2026-10-22

### Sửa

- Dựng trên `@horus/webgame` 0.18.0. API và file SDK không đổi.

## [0.1.1] - 2026-10-22

### Sửa

- Dựng trên `@horus/webgame` 0.17.0. API và file SDK không đổi.

## [0.1.0] - 2026-10-22

### Thêm

- Bản đầu tiên: `horus-sdk.js` (global `HorusSDK`), `horus-sdk.mjs`, `horus-sdk.d.ts`. `start()`, `platform` (quảng cáo, mua hàng, analytics, Remote Config, vòng đời app, hỗ trợ, nhắc nhở, shortcut), `cloud` (cloud save), `save` (lưu game có phiên bản). Cùng một file chạy trên trình duyệt (quảng cáo và mua hàng giả lập) và trong app Horus build.
