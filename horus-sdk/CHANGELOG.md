# CHANGELOG của Horus SDK (@horus/sdk)

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), phiên bản theo semver.

## [Unreleased]

## [0.56.1] - 2026-11-27

- Dùng @horus/webgame 0.103.1 (từ chối .pck Godot có script C#). GODOT-AGENTS.md: game Godot chỉ dùng GDScript.

## [0.56.0] - 2026-11-27

- Dùng @horus/webgame 0.103.0 (Adjust tự gửi mốc `mkt_ad_impression_*`); ANALYTICS.md §10, AGENTS.md, GODOT-AGENTS.md.

## [0.55.1] - 2026-11-26

- Dùng @horus/webgame 0.102.1 (cổng policy Android biết thêm đồ của adapter MAX).

## [0.55.0] - 2026-11-26

- Dùng @horus/webgame 0.102.0 (cổng bảo mật Android trong cổng release; cổng policy iOS nhận AdsGlobalSDK, TikTokBusinessSDK, UnityCoherenceLib).

## [0.54.0] - 2026-11-26

- Dùng @horus/webgame 0.101.0 (cổng policy store Android + iOS trong cổng release, báo cáo release-report.md).

## [0.53.2] - 2026-11-26

- Dùng @horus/webgame 0.100.2 (mạng MAX đã gỡ như yandex: cảnh báo và bỏ qua, không dừng build).

## [0.53.1] - 2026-11-26

- Dùng @horus/webgame 0.100.1 (sửa lỗi build Android).

## [0.53.0] - 2026-11-26

- Dùng @horus/webgame 0.100.0 (module AppMetrica mặc định tắt, bỏ Yandex Ads, ironSource thôi mặc định).

- (khi gộp cùng @horus/webgame 0.100.0) `horus-build.mjs` nhận `gameEvents` là lựa chọn bật / tắt (`DEV_BOOL`) cho module mới `appmetrica`; README mục 12 thêm dòng `appmetrica` (mặc định tắt, ghi `apiKey` là bật), ANALYTICS.md thêm AppMetrica ở bảng nơi nhận; AGENTS.md, GODOT-AGENTS.md (quy tắc analytics, id của app) và GAME-GUIDE mục 16 / 17 dạy agent: AppMetrica chỉ bật khi người dùng đưa key, không gọi API AppMetrica, `eventList` và giới hạn gói Free.

## [0.52.2] - 2026-11-26

- Dùng @horus/webgame 0.99.2 (lý do lỗi mua iOS, `app.fps` không xin chế độ nhanh hơn) và @horus/cloudsave 1.18.0 (trang admin xem save dạng cây).

- Tài liệu (GAME-GUIDE): khoá 30 khung/giây lúc máy ấm chỉ khi Android báo ấm (`light` hoặc headroom ≥ 0,83, mở sau 20 s dưới 0,75; số đo Galaxy A16) và gửi lý do khoá kèm sự kiện fps; màn 90 Hz: bỏ khung theo đồng hồ, tối đa 60 khung/giây (Crash Ramp v107j / v107l, 25/11/2026).

## [0.52.1] - 2026-11-25

- Dùng @horus/webgame 0.99.1 (sửa lỗi Gradle của icon thông báo).

## [0.52.0] - 2026-11-25

- `notif.icon` / `notif.color` trong horus-game.json (icon nhỏ + màu thông báo Android), kiểm trước khi gửi; xem README mục 12.

## [0.51.0] - 2026-11-25

- Dùng @horus/webgame 0.98.0 (ad_stuck / ad crash keys / ad_creative, launch screen iOS Godot, đo thời gian khởi động iOS).

### Thêm

- Docs `ANALYTICS.md`: event tự động `ad_stuck` (webgame 0.98.0): app chết khi quảng cáo còn mở (kẹt, crash, ANR), kèm mã để chặn trong MAX Ad Review; Crashlytics key `ad_open` / `ad_last`; `renderer_gone` thêm `creative`.

- GODOT.md mục 5: màn chờ lúc mở app iOS của game Godot là nền `colors.background` và icon (webgame 0.98.0 sửa màn trắng khi engine nạp game).

## [0.50.0] - 2026-11-25

- Dùng @horus/webgame 0.97.0. ANALYTICS.md: `app_exit` do app gửi, game thôi tự gửi; `ad_clicked` một lần mỗi quảng cáo. GAME-GUIDE 18: chạy lại theo seed, kiểm chữ đè / chữ nhỏ. AGENTS.md: dòng `APP_NOT_SET_UP`.

## [0.49.0] - 2026-11-25

- Dùng @horus/webgame 0.96.0 (Horus Play có `ALLOW_EMAILS`).

## [0.48.0] - 2026-11-23

- GAME-GUIDE: chế độ an toàn GPU từ lần mở đầu cho GPU lỗi nhiều, boot hỏng vì WebGL thì hiện thẻ và tự tải lại (Crash Ramp v106o / v106p).

- Dùng @horus/webgame 0.95.0 (giá store hỏi lại khi chưa có, `iap.buy` Android hỏi lại sản phẩm sau 1 s, robot của Google Play không tracking).

## [0.47.0] - 2026-11-22

- Dùng @horus/webgame 0.94.0 (khung máy iPhone / iPad trên Horus Play, sửa tab VIDEO không hiện, Android gửi `installedAt` khi kiểm tra đơn) và @horus/cloudsave 1.17.0 (horus-iap tính phí Google theo luật mới).

## [0.46.0] - 2026-11-21

- `horus-build.mjs update` (và lúc build tự cập nhật) thay cả thư mục `horus-sdk/video/` (rec.mjs, AGENTS.md, GAME-SETUP.md), bản cũ ở `.old/<phiên bản>/video/`; thêm ANALYTICS.md, BUILD-API.md vào các file được thay. Trước đây chỉ 10 file lõi, game không nhận bộ quay mới.
- `--web`: khối `"play": { "web", "build" }` trong `horus-game.json` thay `web` / `build` cho riêng Horus Play, lệnh build có `HORUS_PLAY=1`. Game có `web` / `build` làm trang cho app (Crash Ramp: `"web": "www"`, build Android) gửi được bản web thật có bảng VIDEO mà không sửa `web` / `build` của app. README (bảng horus-game.json, mục Bản web chơi thử, SDK luôn mới), `video/GAME-SETUP.md`.

## [0.45.1] - 2026-11-21

- GAME-GUIDE (bài học Crash Ramp, chỉ tài liệu): ngôn ngữ đọc phải sang trái (tiếng Ả Rập, v105s); thêm thứ vẽ mới mà không thêm shader program (vệt bánh, v105w); popup che cảnh đứng yên thì không vẽ lại cảnh 3D (v106b); màn tải đứng mãi trước khi map nạp: canh giờ lúc khởi động (`boot_stuck`).

## [0.45.0] - 2026-11-21

- Big ad offer (webgame 0.93.0, Godot addon): `platform.ads.bigAd()` / `showBig()` (Godot `Horus.ads.big_ad()` / `show_big()`), mặc định tắt. Tài liệu: README mục 3, GAME-GUIDE mục 8 (thẻ, đếm ngược, phần thưởng theo gói IAP, người đã mua / chưa mua), AGENTS, GODOT, GODOT-AGENTS, ANALYTICS (`bigad_*`).
- horus-sdk.js 173 KB (bảng VIDEO + big ad offer): giới hạn kích thước trong test nâng từ 168 lên 176 KB.

## [0.44.0] - 2026-11-21

- `video/rec.mjs`: bước `camera`, `toggle`, `shot` và khoá `"shot": "<id>"` ở gốc kịch bản (game dựng kịch bản có sẵn của nó trước, clip bắt đầu ở khung đầu kịch bản chạy thật, độ dài theo game) cho game khai báo góc máy / kịch bản (`platform.video.cameras` / `shot` / `toggle`, webgame Unreleased); tên sai thì dừng, báo tên đúng xem ở `state`. README mục 12 và `video/AGENTS.md` có cách khai báo, nút VIDEO ở cạnh phải.
- `video/GAME-SETUP.md` mới: agent làm bản cho video editor của một game đủ như Crash Ramp, từng bước (kê khai khoảnh khắc quảng cáo, mở khoá, UI, góc máy, kịch bản dạng dữ liệu, yên lặng / HUD ở menu, hướng dẫn, kiểm bằng chuột thật và `rec.mjs --preview`, giao); AGENTS.md, README mục 12, GAME-GUIDE bước 19, `video/AGENTS.md` trỏ tới nó.

## [0.43.0] - 2026-11-21

- Game web (three.js) trên Horus Play mặc định là bản cho video editor (webgame 0.91.0): bảng VIDEO tự gắn vào trang, game khai báo mục mở khoá bằng `platform.video.cheat / number / watch / ui`; `--web --serve` cho xem giống vậy trên máy. `video/rec.mjs` quay cả game web (chụp cả UI HTML), `video/horus-video.js` cho `--dir` với game web. Game mẫu (`example/`) có hình vuông quay theo thời gian và khai báo "+1000 xu", "Xu".
- Dùng @horus/webgame 0.91.0.

## [0.42.0] - 2026-11-21

- rv swap mặc định bật (@horus/webgame 0.90.0, addon Godot): nút rewarded hiện interstitial đã load khi MAX định giá cao hơn hoặc khi không có rewarded, thưởng như nhau. `dev/README.md` mục 3, `dev/AGENTS.md`, `dev/GAME-GUIDE.md` mục 8, `dev/GODOT.md`, `dev/GODOT-AGENTS.md`, `dev/ANALYTICS.md` (`rv_swap`, tham số `swap`).

## [0.41.0] - 2026-11-21

- `horus-build.mjs --web`: bản web chơi thử trên Horus Play, chỉ email @horusvn.com mở được, in link. Game Godot: tự thêm preset Web, Godot của máy export `.pck`, gắn engine web chính thức của Godot (không cần cài export template); game web gửi thư mục build. `--web --serve` mở trên máy này (http://localhost:8060). Trang build có lựa chọn "Web chơi thử (Horus Play)". GODOT.md mục 9, GODOT-AGENTS.md, README mục 12, BUILD-API.md ("Trang web chơi thử").
- Dùng @horus/webgame 0.89.0.

## [0.40.2] - 2026-11-20

- Dùng @horus/webgame 0.88.2: game Godot Android không còn crash lúc engine tự dọn khi màn game bị huỷ.

## [0.40.1] - 2026-11-20

- README mục 11: khai riêng từng nền tảng (`ios.urlScheme`, `ios.urlIdentifier`, `ios.linkDomains`, `android.urlScheme`, `android.linkDomains`) như Adjust Settings bên Unity; link rút gọn Adjust được đổi ra link đầy đủ (`processAndResolve`), sự kiện `link` có `short`.
- Dùng @horus/webgame 0.88.1.

## [0.40.0] - 2026-11-20

- `linkDomains` (Universal Links / App Links, như link Adjust `mygame.go.link`): README mục 11 và bảng khoá; `horus-build.mjs` kiểm tên miền trước khi gửi. Những mục khác của Adjust Settings bên Unity SDK đã tự làm (README).
- Câu ATT mặc định dịch sẵn cho các ngôn ngữ game khai (`ios.languages`).
- Dùng @horus/webgame 0.88.0.

## [0.39.2] - 2026-11-20

- Dùng @horus/webgame 0.87.2: `ad_clicked`, `ad_complete`, `ad_display_failed` có `placement` (trước đó trống).

## [0.39.1] - 2026-11-20

- README: danh sách gói mua một lần của cloud save lấy từ bản build Android; `appId` luôn là id Horus cấp kể cả khi build iOS (Idle Jump Ball đổi `appId` thành bundle iOS, job báo `NO_CLOUD_SAVE`). Dùng @horus/webgame 0.87.1.
- `horus-build.mjs`: `appId` bắt đầu bằng `com.horusent.` (bundle iOS của Horus) là lỗi `STUDIO_IDS` trước khi gửi. AGENTS.md: lỗi job `APPID_IS_IOS_BUNDLE`, `APP_NOT_SET_UP`.

## [0.39.0] - 2026-11-20

- `dev/ANALYTICS.md`: chuẩn chính là sheet "Tracking plan base - Puzzle" (mục 0 mới: `game_start` / `game_end`, tham số `stage_*`, `loading_*`, `tut_step`, `iap_*`, event quảng cáo app gửi, user property mới). Bộ cũ giữ ở mục 4-8; game đã lên store gửi song song (mục 14). `platform.an.context` (README, GODOT.md). Dùng @horus/webgame 0.87.0.

## [0.38.25] - 2026-11-19

- Luật version: Android lên Play internal / alpha / beta được giữ version production, chỉ production cần +1 (@horus/webgame 0.86.13).

## [0.38.24] - 2026-11-19

- Đi cùng @horus/webgame 0.86.12 (sửa máy build treo khi đổi gói mua một lần).

## [0.38.23] - 2026-11-19

- Tài liệu luật version: Android 3 số hợp lệ; game cũ sai dạng: Android 0.0.1.0, iOS version đúng dạng kế tiếp (@horus/webgame 0.86.11).

## [0.38.22] - 2026-11-19
- Docs: luật version lên store (`VERSION_RULE`, webgame 0.86.10).
- Trang Build bỏ "APK cài thử" và "AAB (tải về)": chỉ còn Lên Google Play, Lên Firebase, iOS lên TestFlight (webgame 0.86.9, lỗi `DOWNLOAD_OFF`).

## [Unreleased]

## [0.39.0] - 2026-11-20

- `dev/ANALYTICS.md`: chuẩn chính là sheet "Tracking plan base - Puzzle" (mục 0 mới: `game_start` / `game_end`, tham số `stage_*`, `loading_*`, `tut_step`, `iap_*`, event quảng cáo app gửi, user property mới). Bộ cũ giữ ở mục 4-8; game đã lên store gửi song song (mục 14). Dùng @horus/webgame 0.87.0.

### Đổi

- `horus-build.mjs` nhận `sdk.adjust.environment: "sandbox"` (trước đây chỉ `""` / `production`): APK cài thử báo cài đặt và mua hàng sang sandbox của Adjust, giao dịch test (license tester) cũng lên `purchaseEvent` khi không có `purchaseTestEvent`. Job Lên Google Play, AAB và TestFlight dừng với `[STORE_SETUP_MISSING]` (Adjust production) khi còn `sandbox`: đổi lại `""` trước khi lên store. Cần @horus/webgame bản kế sau 0.86.4.

## [0.38.21] - 2026-11-19

### Thêm
- `video/` (bộ quay cho video editor và agent, game Godot có addon 0.7.0): `node video/rec.mjs kịch-bản.json` mở bản web trên Horus Play (hoặc `--dir` thư mục bản web), chạy game trên đồng hồ ảo và quay khớp từng khung ra mp4 (mặc định 1080x1920, 60 khung/giây); `--preview` cho ảnh mỗi 0.5 giây và trạng thái game; `login` lưu đăng nhập Access một lần; `state` liệt kê mục mở khoá và phần UI. Hướng dẫn cho agent: `video/AGENTS.md`.

- `horus-build.mjs --firebase` và lựa chọn "Lên Firebase App Distribution" trên trang build (webgame 0.86.8): APK release gửi tester Firebase, được để Adjust sandbox. README, AGENTS.md (`FIREBASE_DIST`).
## [0.38.20] - 2026-11-19

- Đi cùng @horus/webgame 0.86.6 (máy build tự cập nhật danh sách món mua một lần lên cloud save).

## [0.38.19] - 2026-11-19

- Dùng @horus/webgame 0.86.5: APK cài thử chạy Adjust sandbox được (bản lên store vẫn phải production), giao dịch test gửi lên sandbox.

## [0.38.18] - 2026-11-19

### Docs

- Xoá tài khoản / xoá dữ liệu như Crash Ramp (dev Godot hỏi 19/11/2026: xoá local rồi `quit()` thì bản cloud cũ quay lại): `wipe` → giữ ngôn ngữ (Xoá tài khoản xoá cả món đã mua, Restore vẫn trả món mua một lần; Xoá tiến độ giữ chúng) → `save` → `cloud.sync` → chờ `synced` → chơi lại trong app, không thoát ngay. README mục 7, AGENTS.md, GODOT.md (mẫu GDScript), GODOT-AGENTS.md. Xoá hẳn ô cloud: Horus dùng `op delete` của server.

## [0.38.17] - 2026-11-18

- Đi cùng @horus/webgame 0.86.3 (iOS build được với Xcode 27).

## [0.38.16] - 2026-11-18

- Đi cùng @horus/webgame 0.86.2 (Build online chia job theo app).

## [0.38.15] - 2026-11-18

### Đổi

- Dùng @horus/webgame 0.86.1: game không quảng cáo đặt `store.noAds: true`, game có server mua hàng riêng đặt `store.ownServer: true` + `sdk.billing.verifyUrl`, để bản lên store không bị chặn nhầm (README, AGENTS).

## [0.38.14] - 2026-11-18

### Đổi

- Dùng @horus/webgame 0.86.0 (trần doanh thu quảng cáo 5 USD, kiểm cá mập/hack, chặn gian lận doanh thu; gói thuê bao `iap.product`, `iap.manage`) và @horus/cloudsave 1.16.0 (horus-iap kiểm gói thuê bao).

## [0.38.13] - 2026-11-18

### Đổi

- Dùng @horus/webgame 0.85.8: bản lên store (Google Play / TestFlight) và mọi AAB bị chặn khi thiếu Adjust, MAX, privacyUrl hoặc consent (`[STORE_SETUP_MISSING]`); team ngoài Horus không tải AAB về để up tay (`[AAB_STORE_ONLY]`).

## [0.38.12] - 2026-11-17

### Đổi

- Dùng @horus/webgame 0.85.7: Remote Config cho bản web (`rcWeb`, tắt mặc định), Android `iap.buy` báo lý do khi lỗi.

### Sửa (doc)

- A/B chạy bằng Firebase A/B Testing trên Remote Config, không chia trong code, không làm user property `ab_<tên>`; ngân sách user property 21 (Firebase bỏ im lặng tên thứ 26 trở đi); số dư và chuỗi thắng/thua chuyển vào `session_begin` (ANALYTICS mục 7, 10; README mục Remote Config; GAME-GUIDE). Bài học Crash Ramp 0.1.6: 553/575 máy đã đủ 25 user property, hai A/B mất dữ liệu.

## [0.38.11] - 2026-11-16

### Sửa (doc)

- `GAME-GUIDE.md` mục 19: bài học build 14-16/11/2026 (tên app và build lại, job từ chối "SDK cũ" sau khi tự cập nhật, Baseline Profile có lúc không vào bản release, đọc đoạn "What went wrong" của Gradle). `README.md` dòng `android.baselineProfile` thêm cảnh báo của job.

## [0.38.10] - 2026-11-16

### Đổi

- Dùng @horus/webgame 0.85.6 (job lỗi Gradle báo đúng đoạn "What went wrong").

## [0.38.9] - 2026-11-16

### Đổi

- Dùng @horus/webgame 0.85.5 (tên app trong horus-game.json luôn được dùng, kể cả khi Horus đã có cấu hình cho app).

## [0.38.8] - 2026-11-15

### Đổi

- Dùng @horus/webgame 0.85.4 (job Build online trên Windows build trong thư mục ngắn).

## [0.38.7] - 2026-11-15

### Sửa (doc)

- Rà lại doc studio theo code SDK + bài học Crash Ramp/Ashlar để agent làm đúng cho cả three.js và Godot:
  - `README.md`: `HorusSDK.target` / `platform.kind`, `HorusSDK.start({perfEvent:false})`, mẫu `interDue` đủ ctx (`sinceStart`, `x2Skipped`), quảng cáo sẵn sau `ready()`, RC áp dụng từ phiên sau, `buys` cần `t`, `platform.share.open`, cảnh báo doanh thu đếm hai lần Adjust/AppLovin, dòng `android.baselineProfile`.
  - `GAME-GUIDE.md`: mẫu horus-game.json đủ privacyUrl/termsUrl/urlScheme, bài học driver PowerVR, âm thanh iOS sau quảng cáo, không trả hai lần giữa lost và memo, mẫu offer đúng ctx, cách đọc A/B, phát hành từng phần, bảng lỗi PairIP/PowerVR.
  - `ANALYTICS.md`: mẫu Godot dùng `Horus.liveops.create_analytics` (không có `HorusLogic`), bỏ `screen_view`/`ad_impression` khỏi danh sách tên cấm, thêm `app_start_sdk`, `crashKeys({game_build})`.
  - `AGENTS.md`: luật quảng cáo/RC/cloud sync/mkt, grep API mới rộng hơn, bảng mã lỗi thêm RELEASE_GATE, PREFLIGHT, BASELINE_PROFILE, NEWER_API, KEYCHAIN.
  - `GODOT.md`, `GODOT-AGENTS.md` (godot/README.md, godot/AGENTS.md): quick start đủ `conflict_rules` (further, merge + `credit`, mirror, flush), `settle_at_boot`, `crash_keys`, tín hiệu `purchase`, bảng API khớp addon, kiểu GDScript, danh sách "chưa có trong Godot", bước `horus-build.mjs check`, giới hạn gói 200 MB.
  - `example/index.html`: `ready()` trong finally, `ads.busy()`, lost trả rồi mới `lostDone`, SKU lạ không trao, `cloud?.sync()` sau khi mua.

## [0.38.6] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.85.3 (Build online giữ cả log Gradle, báo khi bản release thiếu Baseline Profile đã ghi).

## [0.38.5] - 2026-11-14

### Sửa

- `horus-build.mjs`: khi lệnh build tự cập nhật SDK của game, job giờ báo phiên bản SDK MỚI cho máy chủ (trước đây vẫn báo bản cũ đã đọc trước khi cập nhật, nên hàng chờ từ chối là "SDK cũ" và phải gửi lại với `--no-update`; gặp với Crash Ramp 0.37.7 -> 0.38.4 ngày 14/11/2026).

## [0.38.4] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.85.2 (Startup Profile dưới Ad Review không còn im lặng, D8 từ chối thì không chặn bản release).

## [0.38.3] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.85.1 (Startup Profile giữ bố cục DEX khi có MAX Ad Review).

## [0.38.2] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.85.0: `android.baselineProfile` trong `horus-game.json` (mặc định tắt) cho app mở nhanh hơn.

## [0.38.1] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.84.0: app Android mở nhanh hơn theo Play vitals (activity vẽ ngay, lớp che giống splash tới khi trang vẽ), sự kiện `app_start_sdk` (chỉ Firebase).

## [0.38.0] - 2026-11-14

### Đổi

- Dùng @horus/webgame 0.83.0: `horus-build.mjs` ở văn phòng gửi bản web qua LAN tới máy build (lỗi gì cũng quay về Cloudflare), gói trên 5 MB đi theo phần 5 MB; bản lên store của game bán IAP bị chặn khi chưa có cloud save (`[NO_CLOUD_SAVE]`).

## [0.37.7] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.82.0 (máy build Horus chạy được nhiều job cùng lúc).

## [0.37.6] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.81.1 (job iOS trên Mac không còn dừng vì "Directory not empty").

## [0.37.5] - 2026-11-13

### Đổi

- Máy build chỉ nhận job dùng Horus SDK mới nhất (dev/README, AGENTS quy tắc 10, BUILD-API). Dùng @horus/webgame 0.81.0.

## [0.37.4] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.80.0 (máy build: cổng release dùng SKU dev khai; gói mua một lần tự vào config cloud save). Tài liệu dev/README cập nhật.

## [0.37.3] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.79.2 (máy build: bước chạy thử cho qua game không có Game Loop riêng).

## [0.37.2] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.79.1. README mục Link repo: mã build Horus đặt "Không bắt buộc" không phải theo luật git.horusent.com.

## [0.37.1] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.79.0 (Android vào game nhanh hơn: game Godot không khởi động WebView, MAX khởi động sau app.ready).

## [0.37.0] - 2026-11-13

### Thêm

- `ANALYTICS.md` (trang /analytics của doc): analytics chuẩn Horus, bộ event chung cho mọi game lấy theo Crash Ramp 0.1.5: quy tắc tên (giới hạn Firebase, tên giữ riêng), 6 tham số chung, event bắt buộc / nên có theo nhóm (phiên, lỗi, FTUE, vòng chơi, kinh tế, quảng cáo, shop, IAP, offer, giữ chân), giá trị chung của `pl` / `source` / `trigger`, user property, bốn mốc Adjust, event app tự gửi (kể cả `webview_missing`, `adjust_attribution`), danh sách kiểm tra trước khi lên store, cách team data đọc số. README mục 5, GAME-GUIDE mục 16, AGENTS.md, godot/README.md và godot/AGENTS.md trỏ tới file này.
- Dùng @horus/webgame 0.78.0 / @horus/godot 0.5.0: `platform.an.log` chặn tên Firebase giữ riêng và tên sai dạng, báo `console.error` và `wg_bad_event`.

### Sửa (doc)

- Rà doc cho AI agent làm đúng:
  - Mua hàng (AGENTS, GODOT-AGENTS, README, GAME-GUIDE mục 2 và 12, GODOT.md): đơn `state: 'pending'` không giao, không finish (mẫu cũ giao cả đơn chưa trả); nghe `'purchase'`; `consumable` / `usd` theo bảng sản phẩm; SKU lạ không giao; không mua khi mất mạng; `cloud.sync()` sau khi mua.
  - Cloud save: thứ tự `restoreBackup` → `settleAtBoot` → `load`; xử lý `'cloud'` `conflict`; `key` / `version` không đổi sau khi lên store.
  - Quảng cáo: interstitial cũng kiểm `busy()` (mẫu GAME-GUIDE mục 10, README); mẫu rewarded mục 8 bọc `adLightOff`, mọi đường ra xoá `adPend` và lưu, hẹn giờ 2 phút; README thêm `reason` `'busy'`; thưởng bù chỉ từ `ads.lost`; Godot có `Horus.ads.lost` / `lost_done()`.
  - `ready()` cả khi khởi động lỗi, `gameState('play'/'menu')`; Remote Config kẹp min/max; giới hạn Firebase và `build` mỗi bản trong quy tắc analytics; esbuild `chrome80` + grep trước khi báo xong; máy tester (`an.block`, `testDeviceIds`), Test Lab chỉ quota miễn phí.
  - Godot iOS: GODOT-AGENTS và README thôi nói "chưa có iOS" (có bản thử từ 12/11/2026, như GODOT.md).
  - GAME-GUIDE: prompt nói đúng "bước 0 đến 21". ANALYTICS.md thêm 9 bước cho AI agent ở đầu file.
- horus-sdk.js 160 KB (thêm kiểm tên event của webgame 0.78.0): giới hạn kích thước trong test nâng từ 160 lên 168 KB.

## [0.36.6] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.77.0. Tài liệu: AGENTS.md có dòng xử lý job bị từ chối vì thiếu link repo, và luật mail @horusvn.com phải dùng repo trên http://git.horusent.com/ (cả README mục Link repo).

## [0.36.5] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.76.0.

## [0.36.4] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.75.3 (release gate chạy thử được game Godot).

## [0.36.3] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.75.2 (máy không có WebView không còn văng sau 20 s).

## [0.36.2] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.75.1 (nút màn báo thiếu WebView màu xanh lá).

## [0.36.1] - 2026-11-13

### Đổi

- Dùng @horus/webgame 0.75.0: sửa văng Android 8-9 (PairIP); máy không có WebView có nút mở Google Play và tự vào lại game.

## [0.36.0] - 2026-11-12

### Đổi

- Dùng @horus/webgame 0.74.0: chi phí lượt cài từ Adjust (`ua_cost`, `ua_cost_type`, event `adjust_attribution`, `platform.ua.cost`), dev/README cập nhật.

## [0.35.2] - 2026-11-12

### Đổi

- Dùng @horus/webgame 0.73.0 (iOS: sự kiện `sheet` {open:false} khi sheet mua App Store đóng mà StoreKit chưa trả lời).

## [0.35.1] - 2026-11-12

### Đổi

- GAME-GUIDE.md (bài học Crash Ramp 9-12/11): mục mới "Giao diện thẳng hàng" (hàng nút thẳng 1 px, pop-up cùng bề rộng, header 76 px, chia khoảng trống đều, đo bằng tool, 10 cỡ màn); mục 12 khoá nút mua khi mất mạng; mục 16 luật đọc A/B (D1 và D3 không giảm) và mở dần hệ thống phụ.

## [0.35.0] - 2026-11-12

### Tài liệu

- README mục 12, AGENTS, GAME-GUIDE mục 19, GODOT, GODOT-AGENTS: cổng kiểm tra bản release của máy build (webgame 0.72.0). Bản `--aab` / `--play` / `--ios` bị chặn khi icon, id, www sai hay có thay đổi chưa khai báo so với bản trước. Khai báo bằng `horus-game.json` `release.expect` / `allow` / `products`. Bài học Crash Ramp 0.1.5 (38): icon mẫu lên Play vì máy build thiếu `sharp`.

### Thêm

- Game Godot build được iOS (`horus-build.mjs --ios`, bản thử: cùng file `.pck` của Android, Horus build trên Mac với @horus/webgame 0.72.0). Bỏ lỗi `GODOT_IOS`. GODOT.md, GODOT-AGENTS.md và AGENTS.md đã cập nhật.

## [0.34.4] - 2026-11-11

### Tài liệu

- GAME-GUIDE, Mở game nhanh: không dựng map trong một việc đồng bộ dài (nhường khung mỗi ~50 ms), `compileAsync` không có `KHR_parallel_shader_compile` chỉ xếp hàng, tìm khung dài bằng trace Chrome qua USB (Crash Ramp v102v).

### Đổi

- Dùng @horus/cloudsave 1.15.0.

## [0.34.3] - 2026-11-11

### Đổi

- Dùng @horus/webgame 0.71.0 (job cloud save bật Level online từ trang Build admin).

## [0.34.2] - 2026-11-11

### Tài liệu

- `dev/README.md` mục 8, Level online: tải và cache trên máy, các bước cho PM trên trang Level online (lần đầu, sửa, thêm, xem thay đổi, phát máy thử / % / tất cả, rút lại, nhật ký), cài Firebase để xem tỉ lệ qua màn.
- `dev/AGENTS.md` quy tắc 15 chặt như bản Godot: không tự dựng server hay tự tải level, không ghi URL server, `builtin` luôn đủ, `validate`, tổng số màn từ `levels.count`, `format` khi level cần code mới.

## [0.34.1] - 2026-11-11

### Tài liệu

- `dev/README.md` mục 5: các event app tự gửi lên Firebase (`ad_impression`, `in_app_purchase`) để game không gửi trùng, và khi nào dùng `login` (câu hỏi của studio 11/11).
- Cùng luật trong `dev/AGENTS.md` (quy tắc 8), `dev/GODOT-AGENTS.md` (quy tắc 9) và `dev/GODOT.md`; Android: `in_app_purchase` chỉ có khi Firebase đã liên kết Google Play.

## [0.34.0] - 2026-11-11

### Thêm

- `device_perf` (webgame 0.70.0, godot 0.4.0): sự kiện hiệu năng máy mỗi phiên, tự có. Tài liệu: `dev/README.md` mục 5 (bảng tham số), `dev/GAME-GUIDE.md` mục 16, `dev/GODOT.md` mục 3. `horus-sdk.d.ts` có `platform.perf`, `init({ perfEvent })` (lấy từ webgame). Gợi ý: minor (0.34.0).

### Đổi

- GAME-GUIDE.md mục hiệu năng máy yếu (shader): dựng sẵn và giữ vật liệu của món mua sau (Crash Ramp v102u, Test Lab: thêm mảnh ná A03s 499 → 283 ms, A10 667 → 300 ms); gói shader làm nóng lúc mở game chỉ kịp 0-1 program trên điện thoại thật (PC 27-30).

## [0.33.0] - 2026-11-10

### Thêm

- `horus-build.mjs --aab|--play --keystore <file.jks> --key-alias <alias>` (mật khẩu: `HORUS_KEYSTORE_PASSWORD`, `HORUS_KEY_PASSWORD`): studio gửi keystore riêng của game một lần; máy build giữ làm khoá của app khi app chưa có khoá (webgame 0.68.0). Mã lỗi `KEYSTORE_BAD`, `KEYSTORE_EXISTS`, `KEYSTORE_NOT_ALLOWED`. Tài liệu: `dev/AGENTS.md`, `dev/README.md` mục 12.

## [0.32.2] - 2026-11-10

### Đổi

- GAME-GUIDE bước 19: hai mục mới "Bản cho video editor" (bắt buộc: game cộng bảng công cụ quay cho đội video) và "Bản playable cho marketing"; prompt "Bắt đầu game mới" và "Xong khi" bước 19 đòi link của cả hai; AGENTS.md thêm dòng kiểm trước khi báo xong.

## [0.32.1] - 2026-11-10

### Sửa

- Theo webgame bản tới: Android mở app không còn ANR vì WebView khởi động trên luồng chính, hay vì đọc cờ Test Lab (`isRobot`) trên luồng chính. GAME-GUIDE.md mục 21 thêm hai dòng vào bảng lỗi đã gặp. Gợi ý: patch.
- GAME-GUIDE.md "Nhẹ khi quảng cáo che game": nhạc phải nhả thật (`stop()` + `disconnect()` + `buffer = null`; chỉ `stop()` trên AudioContext đã suspend giữ cả bài nhạc suốt quảng cáo; đo LDPlayer bằng memory-infra), âm lặp lúc chơi nhả luôn, cách đo renderer dưới quảng cáo. Chỉ tài liệu.
- Theo webgame (Unreleased): adapter Mintegral Android mặc định 17.2.21.0. GAME-GUIDE.md mục 21 thêm hai dòng ANR Mintegral (một kiểu đã sửa ở 17.2.21, một kiểu chưa).
- Theo i18n (Unreleased): `autoFit` bỏ qua nhãn chưa đổi và đo các nhãn của một khung cùng nhau (`fitAll`). GAME-GUIDE.md:
  - "Bớt việc CPU mỗi khung" thêm phần giao diện DOM: co chữ, vẽ lại một lần khi dữ liệu nền về đủ, popup chờ hiệu ứng thưởng xong;
  - "Đo cho đúng" thêm Samsung Game Booster khoá xung CPU ở menu, đo khung kẹt bằng `long-animation-frame` trên Chrome của điện thoại, đo bằng save thật;
  - luật cho mọi game có giao diện DOM (đọc rồi mới ghi, co chữ chỉ nhãn đổi, không dựng lại cả màn cho một con số, không popup khi hiệu ứng còn chạy), gate khung hình trước khi đưa vào nhánh chính, và chạy trên điện thoại thật trước mỗi lần upload store. Có trong AGENTS.md (luật 10a), GODOT.md mục 7 và GODOT-AGENTS.md (luật 6b).
- GAME-GUIDE.md mục 5 "Tối ưu GPU máy yếu": menu chậm vì animation CSS đổi `box-shadow` (Crash Ramp v102m: 40 % GPU của Galaxy A16 ở menu); cách sửa giữ hình (glow vẽ sẵn trên lớp riêng, chỉ đổi `opacity`), gate menu đứng yên 10 s. Luật vào danh sách giao diện DOM, AGENTS.md 10a, GODOT.md, GODOT-AGENTS.md 6b. Chỉ tài liệu.

### Tài liệu

- GAME-GUIDE mục 6: "Ba ván đầu: dạy ít, chờ ít" (Crash Ramp v102p: tối đa 3 bài ở ván 1-3, câu hỏi thông báo cùng lời hứa quà, màn bắn tự diễn khi đứng yên, xe dừng tới thẻ kết quả 2,0 -> 1,1 s, ván mất thành thẻ); mục "Đo cho đúng": Edge 157 headless trên Windows cần `--no-sandbox`, tự mở rồi connect.

### Doc

- `platform.device.relaunch` (webgame 0.68.0, Android: trang mở lại vì renderer chết, `{ why, state, net, ram, at }`); `renderer_gone` có `net` và `ram`; GAME-GUIDE mục 5 "Nhẹ khi quảng cáo che game": trang quảng cáo chạy chung renderer, số đo Crash Ramp v102o và những gì game còn nhả được.
- `platform.device.keepFrame()` (webgame 0.68.0, Android 8+): app giữ khung đang hiện để che trang mở lại sau khi renderer chết, tới `app.ready`; GAME-GUIDE mục 5: gọi trước khi nhẹ đi cho quảng cáo, "Quay lại êm sau khi renderer chết".
- `platform.device.loading(pct)` (webgame 0.68.0): % màn tải lên thanh của ảnh che trang mở lại; trang mới chờ quảng cáo của trang cũ trả lời trước (thưởng không mất). GAME-GUIDE mục 5 cập nhật, số đo Galaxy A16.

## [0.32.0] - 2026-11-09

### Thêm

- `HorusSDK.levels` (`@horus/levels` 1.0.0): level online cho game puzzle, `createLevels({ app, count, builtin, platform, validate })`, `levelsUrl`, và luật chung (`makeSet`, `patchSet`, `diff`…). Server mặc định là cloud save của game (`platform.cloud.url`, `@horus/cloudsave` 1.14.0); `level_start` / `level_end` để đo tỉ lệ qua màn. `horus-sdk.d.ts` có namespace `levels`. README mục 8 "Level online", AGENTS quy tắc 15, GAME-GUIDE mục 6 "Game nhiều màn (puzzle): level online".

## [0.31.0] - 2026-11-09

### Thêm

- `node horus-build.mjs check [--play | --ios]`: kiểm tra setup trước khi build, mỗi mục thiếu có mã cố định (`APP_ID`, `IOS_TEAM`, `FIREBASE_IOS`...) và cách sửa, ghi rõ phần nào cần Horus. Lệnh build tự chạy bước này và dừng trước khi gửi khi còn lỗi; nút "Kiểm tra" trên trang HorusBuild hiện cùng danh sách. Lỗi job từ máy build mở đầu bằng mã (`[PLAY_KEY]`, `[IOS_STORE_KEY]`...). Bảng mã: `dev/AGENTS.md` "Kiểm tra setup và mã lỗi".
- (review trước khi ra bản) `APP_ID` chỉ là lỗi khi gửi store; build AAB không gửi store mà thiếu `appId` chỉ là cảnh báo (game Horus lấy appId từ cấu hình trên máy build).
- `platform.an.userId(id)` (Godot `Horus.an.user_id`): user_id của Firebase Analytics và Crashlytics (webgame 0.67.0). Tài liệu: `dev/README.md` mục 5.

## [0.30.11] - 2026-11-09

### Đổi

- Theo webgame 0.66.1 (cài tác vụ máy build qua SSH).

## [0.30.10] - 2026-11-09

### Đổi

- README mục 12: Horus kiểm tra và setup mạng MAX của game (webgame 0.66.0). GAME-GUIDE: mạng có adapter trong build chưa đủ (mục 18), bài học Crash Ramp v102k-v102l (đường lòng chảo, cú bắn trượt chạy ra cỏ).

## [0.30.9] - 2026-11-09

### Đổi

- Tài liệu: `ios.teamId` trong `horus-game.json` (Team ID Apple, dùng khi Horus chưa khai team cho app; team của Horus luôn được ưu tiên).

## [0.30.8] - 2026-11-09

### Đổi

- GAME-GUIDE.md mục 6: bài học Crash Ramp v102g (watchdog tiến độ, đo model lúc đứng yên trước khi gắn đồ) và v102i (ngắm bắn là kỹ năng, cờ kỷ lục, vạch không đẩy xe); GODOT.md trỏ tới.

## [0.30.7] - 2026-11-08

### Sửa

- Theo webgame 0.65.1: R8 không dừng vì Unity LevelPlay khi app có Moloco.

## [0.30.6] - 2026-11-08

### Thêm

- Theo webgame 0.65.0: Firebase Analytics Android nhận câu trả lời consent của UMP (GA4 consent mode); `sdk.applovin.consentCountries` hiện form consent cho nước ngoài GDPR (ví dụ Brazil).

## [0.30.5] - 2026-11-08

### Sửa

- Theo webgame 0.64.1: Firebase chạy cả ở lần mở đầu tiên sau khi Play tự cập nhật (Automatic protection). AGENTS.md, GODOT-AGENTS.md, GAME-GUIDE.md mục 21 thêm luật cho Activity/receiver riêng của game.

## [0.30.4] - 2026-11-08

### Thêm (gợi ý 0.30.4)

- Build online tự chọn khoá Firebase theo `project_id` của google-services.json (`play.json` `firebaseKeysDir`, webgame 0.64.0).

## [0.30.3] - 2026-11-06

### Thêm

- `horus-game.json` `android.playAccount` (tuỳ chọn): tên tài khoản Google Play của Horus chứa app. Không ghi thì máy build tự tìm tài khoản sở hữu app (`@horus/webgame` 0.63.0). Tài liệu: `dev/README.md` mục 12.

### Thêm

- Máy build tự chọn khoá Firebase App Distribution theo `project_id` trong google-services.json (`@horus/webgame` 0.64.0). Tài liệu: `dev/README.md` mục 12.

## [0.30.2] - 2026-11-05

### Đổi

- `AGENTS.md`, `GODOT-AGENTS.md`: người dùng muốn trang build thì mở HorusBuild.cmd / `horus-build.mjs ui`; agent không tự làm trang build riêng. `BUILD-API.md` mở đầu bằng trang build có sẵn, API chỉ cho bot báo tin, CI.

## [0.30.1] - 2026-11-05

### Đổi

- `@horus/webgame` ^0.62.0: tin báo build lên store vào nhóm của từng game (trang admin build), không vào nhóm của game khác. SDK không đổi API.

## [0.30.0] - 2026-11-05

### Thêm

- Deep link: `urlScheme` trong `horus-game.json` (ví dụ `mygame`) cho app một scheme riêng, `mygame://event` mở game; App Store Connect cần nó làm "Event deep link" khi nộp In-App Event. Trong game: `platform.link.opened` (`{ url, path, query, openedAt }`, app mở bằng link) và sự kiện `'link'` (link mở lúc game đang chạy); app tự ghi `link_open { path }`. Lệnh gửi build kiểm scheme theo đúng luật của máy build (chữ thường, 2-32 ký tự, không `http` / `https` / `file` / `fb...`) và dừng khi sai. Cần máy build `@horus/webgame` 0.61.0. Tài liệu: `dev/README.md` mục 11 và 12, `AGENTS.md` quy tắc 14, `GAME-GUIDE.md` mục 20, `dev/horus-game.json` mẫu.
- `BUILD-API.md` trong gói SDK (và trang "API máy chủ build" trên trang tài liệu): các API của máy chủ build (gửi, theo dõi, dừng, tải app, bản SDK mới nhất) để studio làm công cụ riêng hay cho AI agent đọc. `AGENTS.md`, `godot/AGENTS.md` chỉ agent tới file này.
- `GET /jobs/<id>` có `queuePosition` (1 = job kế tiếp) và `jobsAhead` (số job chờ gửi trước, mọi team, cả Android và iOS) khi job đang xếp hàng, `null` khi không. `horus-build.mjs` và trang HorusBuild hiện "thứ N trong hàng, M job đứng trước" và báo lại khi vị trí đổi. Cần máy chủ build từ `@horus/webgame` 0.61.0.

## [0.29.1] - 2026-11-05

### Đổi

- Tài liệu (bài học Crash Ramp v101c): `GAME-GUIDE.md` mục 8 thêm "Quảng cáo thưởng xong thì Android tắt luôn cả app" (ghi nhớ thưởng vào save, trả khi `platform.device.exits` có lần hệ thống tắt app, không bao giờ trả gem kiểu này); mục 5 "Nhẹ khi quảng cáo che game" nhả thêm bản GPU của hình khối / texture trên máy 4 GB trở xuống; "Mở game nhanh": không có `KHR_parallel_shader_compile` thì mỗi khung dịch một program (8,3 giây một khung trên máy 2 GB, ANR PowerVR). `AGENTS.md` và `GODOT-AGENTS.md` thêm luật tương ứng.

## [0.29.0] - 2026-11-05

### Thêm

- `horus-game.json`: studio điền nốt các lựa chọn của module (MAX `consentFlow`, `showTermsInGdpr`, `debugUserGeography`; Adjust `environment`, `logLevel`; Facebook `autoLogAppEvents`, `advertiserId`, `purchases`, `adRevenue`; Crashlytics `ndk`; Play Games `suppressProfileCreation`; Play Integrity `onTamper`; bật / tắt `review`, `update`) và cài đặt app iOS (`ios.attText`, `ios.devices`, `ios.languages`). Horus chỉ còn giữ khoá ký, tài khoản store, mạng quảng cáo và máy chủ. Cần máy build `@horus/webgame` 0.60.0. Tài liệu: `dev/README.md` mục 12 ("Id của app").

### Sửa

- (review) Lựa chọn studio điền: `horus-build.mjs` cảnh báo trước khi gửi giá trị máy build sẽ bỏ qua (không đúng kiểu, ngoài danh sách, `attText` sai, `devices`, `languages`); lựa chọn của MAX (`consentFlow`...) không còn tính là có MAX khi cảnh báo thiếu `privacyUrl`. Danh sách giống hệt máy build: `consentFlow` chỉ `true`, Adjust `environment` chỉ `production`, `logLevel` không có `verbose` / `debug`, `onTamper` do Horus đặt.

- `privacyUrl` / `termsUrl`: `horus-build.mjs` và trang HorusBuild dùng đúng luật của máy build (chữ ASCII, không dấu cách, dấu nháy, `<` `>` hay `\`); trước đây lệnh gửi build cho qua link có dấu nháy hay chữ có dấu mà máy build bỏ đi không báo. Trang HorusBuild nhận link dài tới 498 ký tự (trước là 190). Giá trị không phải chữ báo lỗi, không phải "chưa có".

## [0.28.0] - 2026-11-05

### Thêm

- `horus-game.json` có `privacyUrl` và `termsUrl` (link `https://`): studio tự điền trang chính sách quyền riêng tư của game. Game có quảng cáo MAX cần `privacyUrl` (bảng xin đồng ý GDPR của MAX dẫn tới đó; thiếu thì máy build từ chối bản có quảng cáo, lỗi `privacyUrl is empty`). Lệnh gửi build báo khi thiếu và dừng khi link không phải `https://`. Trang build (`horus-build.mjs ui`, HorusBuild.cmd) có ô `privacyUrl`. Cần máy build `@horus/webgame` 0.59.0. Tài liệu: `dev/README.md` mục 12 (bảng `horus-game.json`, "Id của app"), `GAME-GUIDE.md` (link Privacy Policy), `dev/horus-game.json` mẫu.

## [0.27.3] - 2026-11-04

### Đổi

- Theo `@horus/webgame` 0.58.0 và `@horus/cloudsave` 1.13.0 (máy build tự kiểm tra cloud save sau khi cập nhật, tự quay lại bản cũ khi hỏng). API của SDK không đổi.

## [0.27.2] - 2026-11-04

### Đổi

- `dev/README.md` mục 8: Horus cập nhật server cloud save của các game lên bản mới trên trang admin build (nút "Cập nhật tất cả cloud save"), game không phải build lại. Chỉ tài liệu.

## [0.27.1] - 2026-11-04

### Doc

- Doc `README.md` mục 8: server cloud save của từng game do Horus tạo trên trang admin build (một nút), studio không điền gì.

## [0.27.0] - 2026-11-04

### Thêm

- Studio tự điền id của app trong `horus-game.json`: `sdk`, `android.sdk`, `ios.sdk` (ad unit MAX, Adjust, Facebook, licence key Play...) và `firebase` (hai file Firebase, mặc định `google-services.json` / `GoogleService-Info.plist` ở gốc game). Horus chỉ tích hợp SDK và build. `horus-build.mjs` gửi kèm file Firebase và kiểm trước khi gửi (`checkStudioIds`): ad unit 16 ký tự hex, rewarded khác interstitial, iOS không dùng ad unit của Android, file Firebase đúng `appId`, id riêng của app không đặt nhầm ở `sdk`. Cần máy build từ webgame 0.55.0.
- Doc: `README.md` mục 12 "Id của app" (bảng khoá từng module), mục 1, 3 (nhiều ad unit), 6 (Remote Config), thông báo push; `AGENTS.md`, `GODOT.md`, `GODOT-AGENTS.md`; mẫu `horus-game.json` có sẵn các khối id để điền.

### Doc

- `GAME-GUIDE.md` mục 5: hủy Web Animation không có `fill` khi xong (`onfinish` gọi `cancel()`); còn gắn thì CSS animation của phần tử không chạy trên compositor (Crash Ramp v101b).

## [0.26.10] - 2026-11-04

### Thêm

- `GAME-GUIDE.md` mục 5: game three.js có đường vẽ thẳng ra màn và đường HDR: `ShaderMaterial` tự viết kết thúc bằng `#include <tonemapping_fragment>` + `#include <colorspace_fragment>`; dịch shader trước với target giống đầu ra thật (Crash Ramp v100x).
- `GAME-GUIDE.md` mục 5: số đo trên máy rất yếu (OPPO A15, PowerVR GE8320): Crash Ramp 2x 10 fps đến 1x 20 fps, JS 21 ms mỗi khung, HUD DOM 10-12 ms; khung 1x chia theo phần (mặt đất 13 ms, cây cỏ 13, trời 5, xe 5, trang 20); cấu hình máy yếu (bỏ bóng, bỏ HDR, nửa cây cỏ) 22,9 fps, ẩn thêm HUD 32,1; bản v100v có cờ máy rất yếu 26,4 fps, ẩn HUD 39,2; v100w ghi số HUD 3 khung một lần: 28,2 fps (HUD từ 14 còn 10-11 ms); v100x: khung đầu lượt 119-135 ms thay vì 175-185 ms, không biên dịch shader trong lượt; chia phần HUD: nhịp gợi ý nút tên lửa (animate `filter: drop-shadow`) tốn 10-14 ms, các phần khác khoảng 0, gộp một lớp chậm hơn; luật mới: phần tử HUD có lớp ghép riêng không mang filter, kể cả filter tĩnh (v100y: filter tĩnh + scale vẫn tốn 10 ms, bỏ filter thì hết), glow vẽ bằng box-shadow tĩnh hoặc radial-gradient, animation chỉ dùng transform và opacity (v100z làm vậy: 42,9 ms thay vì 56,3 ms khi gợi ý bật); một game Unity thủ thành 58 fps cùng máy; đo fps app bất kỳ bằng `dumpsys SurfaceFlinger --latency`.

## [0.26.9] - 2026-11-03

### Doc

- `GAME-GUIDE.md` mục 17: "Số liệu UA sau consent": tổng lượt cài và doanh thu không lệch; chỉ camp Google ở EEA lệch (người không đồng ý hiện là Organic trên Adjust, Google ước lượng phần thiếu nhờ cờ DMA); cách đọc camp, tăng tỷ lệ đồng ý qua form AdMob, không bao giờ gửi `ad_user_data=1` cho người từ chối. Cùng ý trong `GODOT.md` mục 6.
- `GAME-GUIDE.md` mục 17: hộp CONTINUE của MAX ngoài GDPR cũng giữ lượt cài Adjust tới khi bấm (đúng doc MAX và Adjust; lựa chọn của studio 3/11/2026); so lượt cài Adjust với Play sau bản phát hành.
- `GAME-GUIDE.md` mục 5, "Game online": đòn đánh của chính mình thấy nhanh (Ashlar): độ trễ đến từ đâu (RTT, đồng hồ vẽ trễ, server chờ input, nhịp gửi) và các cách bớt giữ nguyên luật (đọc socket mỗi khung, đòn của mình theo snapshot, đạn vẽ ngay khung bắn 712 xuống 340 ms, đi tới đoán trước 529 xuống 145 ms, dự phòng input 0-1 tick, một tick châm chước cho cú vung).
- `GAME-GUIDE.md` mục 5, "Bớt việc CPU": gộp sẵn vật nhỏ nhiều mảnh đứng yên (Crash Ramp v100u bệ tên lửa 17 xuống 6 lệnh vẽ).
- `GAME-GUIDE.md` mục 19: ảnh UI nướng sẵn dùng WebP chất lượng 0,9 + alpha lossless, bỏ ICCP, đo bằng so từng file AAB (Crash Ramp v100t 36 thumbnail 1,64 xuống 0,36 MB).
- `GAME-GUIDE.md` mục 5: số đo máy rất yếu PowerVR GE8320 (OPPO A15) từ máy build: chia khung 1x, các profile máy yếu, HUD DOM là phần tốn kế tiếp.
- `GODOT.md` mục 7: gộp MeshInstance đứng yên, ảnh UI WebP.

## [0.26.8] - 2026-11-03

### Thêm

- `GAME-GUIDE.md` mục 17 "Quyền riêng tư: consent, Google DMA, Privacy Policy ở mọi vùng": lựa chọn của studio (3/11/2026) là mọi SDK tiếp tục đo và chia sẻ; app (webgame 0.54.0) gắn consent DMA của Google từ câu trả lời UMP vào lượt cài và mọi event của Adjust; Facebook không chờ consent (đánh đổi GDPR đã biết, do publisher chọn; game sau có thể quyết khác); game không phải viết gì. Settings luôn có link Privacy Policy cho mọi người chơi, không chỉ nút "Privacy settings" ở vùng GDPR (chính sách User Data của Google Play muốn link cả trong Play Console lẫn trong app; Crash Ramp v100s). Cùng luật trong `AGENTS.md` (luật 12, kiểm trước khi báo xong), `README.md` (phần quảng cáo), `GODOT.md` mục 6 và `GODOT-AGENTS.md` (luật 14). Game chưa có link Privacy Policy trong Settings thì thêm.

## [0.26.7] - 2026-11-03

### Thêm

- `GAME-GUIDE.md` mục 5, "Game online": vật thể rời tầm nhìn rồi quay lại là object mới cùng id, phải gắn lại hình (Ashlar: bóng ma đứng yên, quái thật vô hình); không dùng mốc thời gian âm như `time - 40`; cách kiểm.

## [0.26.6] - 2026-11-03

### Thêm

- `GAME-GUIDE.md` mục 5: cách sửa HUD bằng DOM giữ nguyên hình (Crash Ramp v100r: mỗi widget đổi mỗi khung một lớp ghép riêng với `will-change: transform`, ẩn canvas cả màn đang rảnh; A16 3x trên đường 31,6 lên 38,4 fps; kiểm bằng CDP `LayerTree`). "Đo cho đúng": Chrome headless trên Windows bị power throttling hạ xung sau khoảng một phút (Ashlar), cách tắt cho riêng cây tiến trình của trình duyệt test.
- `GAME-GUIDE.md` mục 17, cờ nước trong 3D: hai mặt cùng lấy mép trong ở phía cột (v100e), chỉ một lá cờ nước, sóng vải chạy từ cột ra (v100q), và A/B `nat_flag` đo D1 / D3 / D7.
- `GAME-GUIDE.md` mục 6: lượt hướng dẫn chỉ cho thấy những gì game thật có (Crash Ramp v100m: bỏ bức tường phuy nổ ở lượt đầu, lượt đầu hết đà như mọi lượt); bỏ một cái kết dựng sẵn thì đo lại bằng máy tự lái để lượt 2 đã nâng cấp vẫn đi xa hơn (tên lửa hướng dẫn 0,6 s thay vì 1 s).
- `GAME-GUIDE.md` mục 5: bảng "Một khung 3x đi vào đâu" của Crash Ramp trên Galaxy A16 (Mali-G68): bầu trời 4,4 ms, bloom 4,3 (pass lọc sáng 3,1), mặt đất 3,7, cây 3,4, hậu kỳ 2,0, bóng xe 1,2 trên khoảng 25 ms; đổi target gần như không tốn. Bài học varying của three trong `onBeforeCompile` (vẫn là `#include`, phải viết chunk ra trước) và kết quả varying 16 bit (2%, không đáng kể). "Đo cho đúng": cách đo GPU trên khung đứng yên (lượt A/A, xoay thứ tự, không đặt lượt rỗng trước lượt đo vì GPU hạ xung), và ba lỗi bench vẽ khác game.
- `GAME-GUIDE.md` mục 5: tách tiếp khung 3x của Crash Ramp v100j trên A16: bầu trời khoảng 29 chu kỳ mỗi điểm ảnh; cây tốn ở đỉnh (tắt ghi màu vẫn còn 3,0 trong 3,4 ms); pass lọc sáng của bloom nghẽn ở đọc texture half float có lọc (cảnh 8 bit: 0,3 thay vì 3,0 ms).
- `GAME-GUIDE.md` mục 5: số đo v100k (chỉ vẽ instance trong tầm nhìn, 0,7 ms) và v100l (nhiễu mây đọc qua bộ lọc texture, 1,2 ms), khung 3x còn khoảng 21 ms; quy đổi 1 chu kỳ mỗi điểm ảnh cả màn 3x khoảng 1,1 ms trên G68 MP2; gấp nhánh của map khác trước khi đọc đường dài nhất của malioc.
- `GAME-GUIDE.md` mục 5: sàn của khung khi không vẽ gì qua target HDR là 3,6 ms ở 3x (xoá canvas thẳng 0,5 ms); núi, ná, xu, hạt, chim khoảng 0; bóng xe 0,6 vẽ + 0,4 lấy mẫu; trời chiếm 42% điểm ảnh; bớt từng phần không cộng dồn.
- `GAME-GUIDE.md` mục 5: GPU mỗi khung theo độ nét trên A16 (3x 21,4 ms đến 2x 12,4 ms, bloom bật; trên đường 3x 33,8 fps, 2,5x 44,8 fps) và target cảnh R11F_G11F_B10F (nhanh hơn 2,1 ms nhưng lệch tối đa 6/255, trời thành bậc: đổi hình).
- `GAME-GUIDE.md` mục 5: HUD bằng DOM đổi mỗi khung là khoảng 8 ms mỗi khung trên A16 ở 3x khi đang chạy (ẩn HUD: 34,3 lên 48,7 fps, khung dài 27% xuống 3%); đọc xung và độ bận GPU Exynos qua `/sys/kernel/gpu` không cần root.

## [0.26.5] - 2026-11-02

### Thêm

- `GAME-GUIDE.md` mục 5: số đo nóng máy 10 phút của Crash Ramp trên Galaxy A16 (3x, 3x khoá 30, 2x, 2x khoá 30). Vẽ ít điểm ảnh hơn thì vừa mượt vừa mát hơn; khoá khung trong trang Chrome không làm mát, nên phải đo khoá khung trong app. "Đo cho đúng" có thêm cách đo nóng máy qua `adb shell dumpsys thermalservice`. Game không phải sửa gì.
- `GAME-GUIDE.md` mục 5, "Tìm phần nặng trong một shader": cách làm bản chẩn đoán cho Mali Offline Compiler, kèm số đo mặt đất Map 1 của Crash Ramp v100c trên Mali-G52 / G68 (phần màu đường khoảng một phần ba đường dài nhất, khối đá khoảng một phần sáu, nhiễu chi tiết và bóng nướng ít). Game không phải sửa gì.

## [0.26.4] - 2026-11-02

### Đổi

- GAME-GUIDE mục 17: bài học "Quốc gia của người chơi khi không có mạng" (Crash Ramp v100d, cờ nước ở vạch xuất phát): múi giờ trước, ngôn ngữ sau, múi giờ Windows dùng chung, cờ WebP xếp nối giải mã từng cờ, cờ hai mặt trong 3D. GODOT.md mục 7: cách làm trong Godot (`Time.get_time_zone_from_system()`, `OS.get_locale()`).

## [0.26.3] - 2026-11-02

### Thêm

- `godot/AGENTS.md` (từ `dev/GODOT-AGENTS.md`): quy tắc cho AI agent làm game Godot, cùng loại với `AGENTS.md` của game three.js: addon, `get_sdk()` cho kiểu chặt, mua hàng, lưu, `.pck`, hiệu năng, crash, build.
- `GAME-GUIDE.md` mục 21 "Crash và ANR sau khi ra mắt": app tự bắt gì, đọc cho đúng (người chơi thật, bản, robot, `renderer_gone` ở nền không phải crash, analytics lặp), bảng lỗi đã gặp và cách sửa, các bước cho mỗi lỗi mới. Thêm hai prompt cho agent: game chậm trên máy yếu, có crash mới.
- `GAME-GUIDE.md` mục 5: "Bớt việc CPU mỗi khung" (Crash Ramp v99c, v99d: `forceSinglePass` cho vật liệu cộng sáng hai mặt, `customDepthMaterial` dùng chung, sắp vật đặc theo program, camera bóng bao vật đang thấy; không bật tắt bóng giữa lượt); độ nét tự động tách đoạn khi nghỉ quá 5 giây (v99v); mở game nhanh đo từng bước và hiện menu trước (v98b, v98d); đo cho đúng (xen kẽ nhiều vòng, cảnh chậm dần, máy đo yên, `Math.random` lệch giữa hai bản, dòng crash lúc Test Lab dọn máy).
- `AGENTS.md` (game three.js) có mục "Hiệu năng và crash" (11 luật), kiểm thêm quảng cáo và Chrome 81 trước khi báo xong. `dev/GODOT.md` (`godot/README.md`) có mục 7 "Hiệu năng và lỗi" với số đo Butcher Defense (`.pck` 269 MB so với giới hạn 200 MB của Play, 11 giây nạp shader, RAM 1,44 GB).

### Đổi

- `@horus/godot` có `Horus.ads.busy()` (mỗi lúc một quảng cáo, như SDK web 0.26.1); ví dụ trong `godot/README.md` kiểm nó trước khi gọi rewarded.

## [0.26.2] - 2026-11-02

### Sửa

- `horus-build.mjs` gửi game trên 64 MB theo từng phần (`@horus/webgame` build-client): game Godot có `.pck` lớn build online được, trước đây Cloudflare từ chối mọi lần gửi trên 100 MB (HTTP 413). Khi gửi in `   gửi: NN%` cho thanh tiến trình của trang Build. Cần Worker `horus-build` mới (deploy cùng kit này).

## [0.26.1] - 2026-11-02

### Sửa

- `@horus/webgame` 0.52.1: mỗi lúc chỉ một quảng cáo. Bấm nút xem quảng cáo nhiều lần liền chỉ mở một quảng cáo; lần sau trả `reason: 'busy'` (rewarded) hoặc `busy: true` (inter). Có `platform.ads.busy()`. Cách viết nút quảng cáo: GAME-GUIDE đoạn "Mỗi lúc một quảng cáo".

### Thêm

- File SDK tự nạp vá cho WebView cũ (`.at()`, `replaceChildren`, `roundRect`, `animate()` keyframe thiếu đầu cuối, `getAnimations`) trước mọi thứ khác, nên game dùng SDK chạy được trên Chrome 80-86 mà không phải viết gì.

## [0.26.0] - 2026-11-02

### Thêm

- `horus-build.mjs` build được game Godot: `horus-game.json` có `"engine": "godot"` thì gửi file `.pck` đã export (`"pck"`: file hay thư mục chứa nó, không ghi thì tìm trong `build`, `export`, `dist` hay thư mục game). `--build-web` không có `"build"` thì gọi Godot của máy export bản `.pck` (preset `"exportPreset"`, mặc định `Android`). File `.pck` làm bằng Godot khác 4.7 bị từ chối ngay trên máy studio. Bản iOS cho game Godot chưa có.
- Gói SDK có thư mục `godot/` cho game Godot 4.7: `godot/addons/horus_sdk` (addon Horus SDK, `@horus/godot`, bỏ ghi chú như `horus-sdk.js` đã nén), `godot/example` (game mẫu Godot đủ project, có sẵn addon), `godot/README.md` (hướng dẫn tiếng Việt, `dev/GODOT.md`: cài, API so với SDK web, chạy thử trong editor, export `.pck`, gửi build, kiểm tra).
- SDK tự cập nhật (`horus-build.mjs` trước mỗi lần gửi, `update`) thay cả `horus-sdk/godot/` và addon `addons/horus_sdk` của game Godot khi `plugin.cfg` của gói mới hơn, cả thư mục một lần (ghi bên cạnh rồi đổi chỗ), bản cũ ở `horus-sdk/.old/<phiên bản>/`. Addon mới hơn của game thì để nguyên.

## [0.25.2] - 2026-11-02

### Đổi

- `dev/GAME-GUIDE.md` mục 5 thêm các bài học tối ưu từ Crash Ramp v98w đến v99n và Ashlar: "Độ nét tự động: bắt đầu nét nhất, chỉ hạ khi chậm thật", "Máy nóng khi chơi lâu" (giới hạn 30 khung/giây khi máy ấm, giữ nét; code mẫu chạy cả Android và iOS), "Mở game nhanh", "Đo cho đúng", "Game online: tải và mạng yếu"; ánh sáng theo đỉnh (A10 nhanh hơn 24%) chuyển từ "đã thử" sang "làm được"; bỏ lệnh vẽ rỗng.
- `dev/README.md`: luật nhiệt độ máy theo mục trên; iOS cũng báo nhiệt.

## [0.25.1] - 2026-11-01

### Đổi

- `@horus/webgame` ^0.51.0: iOS báo nhiệt độ máy (`platform.device.thermal`, sự kiện `'thermal'`) như Android, để game hạ tải khi iPhone ấm.

## [0.25.0] - 2026-10-29

### Thêm

- `app.InstanceWindow` (`@horus/app` ^1.4.0): một lệnh vẽ cho cả bộ cảnh vật chia đoạn dọc đường, chỉ các đoạn đang hiện nằm trong buffer (Crash Ramp v98o: Map 1 từ 104 xuống 76 draw call, cùng ảnh).
- `dev/GAME-GUIDE.md` mục 5: "Tối ưu GPU máy yếu, không đổi hình" (đo trên Test Lab, việc làm được, việc đã thử không ăn thua, cách kiểm chứng) và ngân sách draw call máy yếu dưới 80.

## [0.24.1] - 2026-10-29

### Đổi

- `@horus/webgame` ^0.50.0: lần mở đầu sau khi cài, Remote Config lấy và áp giá trị server trước khi `rc.values` trả lời (tối đa 2 giây); Android không còn bảng "Create a Play Games profile" che game lúc mở (`sdk.games.suppressProfileCreation`, mặc định bật).

## [0.24.0] - 2026-10-28

### Đổi

- `@horus/webgame` ^0.49.0: app Android có WebView cũ hơn `android.minWebView` (mặc định 80) hiện màn "cần cập nhật WebView" có nút mở Play thay vì chạy game; sự kiện `webview_old`, `webview_old_tap`, `webview_updated`.

### Tài liệu

- GAME-GUIDE: app Android của `@horus/webgame` 0.49.0 tự kiểm bản WebView (`android.minWebView`, mặc định 80): máy cũ hơn thấy màn cập nhật WebView có nút mở Play Store thay vì game đứng ở màn tải, và gửi `webview_old` để đếm số máy như vậy.

## [0.23.3] - 2026-10-28

### Tài liệu

- GAME-GUIDE: watchdog 30 giây của bộ nạp map không tính thời gian app ở nền (Crash Ramp v97g tải lại game khi người chơi chuyển app lúc mở lần đầu chậm); gọi `adLightOff` trong try/catch trước khi trao thưởng (một lỗi lúc vẽ lại đã làm mất thưởng ở v97g). Rút từ Crash Ramp v98a.

## [0.23.2] - 2026-10-28

### Tài liệu

- GAME-GUIDE: máy yếu và WebView cũ (build cho Chrome 80, polyfill tới Chrome 81, nạp map có giới hạn chờ và watchdog tải lại), game nhẹ khi quảng cáo che (bộ đệm vẽ 1x1, trả đúng pixel ratio cũ), trao lại thưởng `platform.ads.lost` lúc mở game, sự kiện chẩn đoán máy yếu, Firebase Test Lab trong mức miễn phí. Rút từ Crash Ramp v97d đến v97g.

## [0.23.1] - 2026-10-28

### Đổi

- `@horus/webgame` ^0.48.1: bản TestFlight gửi doanh thu quảng cáo như Play internal testing; iOS chỉ còn chặn bản Xcode và AppTransaction không xác minh được.

## [0.23.0] - 2026-10-28

### Đổi

- `@horus/webgame` ^0.48.0: doanh thu quảng cáo giả không còn tới Adjust, Firebase, Facebook: lượt hiển thị từ 1 USD trở lên (cả `adpaid` của trang), máy không cài từ Google Play (trừ bản debug, Play Games trên PC), APK ký lại, bản TestFlight / không phải App Store. Sự kiện `ad_revenue_blocked` ghi lý do. APK thử cài tay (LDPlayer) không còn gửi doanh thu: muốn thấy doanh thu thì cài qua Play internal testing.

## [0.22.1] - 2026-10-28

### Sửa

- `@horus/webgame` ^0.47.1: iOS cũng giữ thưởng quảng cáo khi tiến trình web bị tắt dưới quảng cáo (`platform.ads.lost`, `lostDone()`), và tiến trình web bị tắt lúc app ở nền chỉ còn sự kiện `renderer_gone`, không còn non-fatal.

## [0.22.0] - 2026-10-28

### Thêm

- `@horus/webgame` ^0.47.0: `platform.ads.lost` (`[{ pl, at }]`) và `platform.ads.lostDone()`. Android tắt renderer WebView trong lúc quảng cáo thưởng chạy thì người chơi xem hết vẫn được giữ thưởng: game mở lại đọc `ads.lost`, trao thưởng của từng placement rồi gọi `lostDone()`. Trong lúc quảng cáo che game, renderer giữ mức ưu tiên nên ít bị tắt hơn. Web và iOS: `[]`.

## [0.21.3] - 2026-10-28

### Sửa

- `@horus/webgame` ^0.46.3: renderer WebView bị Android tắt lúc app ở nền không còn là lỗi Crashlytics; mọi lần đều có sự kiện `renderer_gone` (`state` fg/bg, `crashed`).

## [0.21.2] - 2026-10-28

### Sửa

- `@horus/webgame` ^0.46.2: trên máy robot (Firebase Test Lab, Play pre-launch) Play Games không bật nên không còn bảng "Create a Play Games profile" che game; console của trang vào logcat. `@horus/app` ^1.3.2: màn phủ tải/lỗi phủ kín màn hình trên WebView cũ (Chrome dưới 87).

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
