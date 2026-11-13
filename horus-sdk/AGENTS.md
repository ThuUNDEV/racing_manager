# AGENTS.md: game HTML5 dùng Horus SDK

Dành cho AI agent (Claude Code, Cursor, Codex, Copilot...) làm việc trong repo một game phát hành cùng Horus. Người đọc cũng dùng được như một checklist. Hướng dẫn đầy đủ cho người: `README.md` cạnh file này. API và chú thích từng hàm: `horus-sdk.d.ts`.

Đặt file này ở gốc repo game, hoặc thêm vào `AGENTS.md` / `CLAUDE.md` sẵn có một dòng: "Đọc horus-sdk/AGENTS.md trước khi sửa quảng cáo, mua hàng, analytics, lưu game hay build app."

## Bối cảnh

- Game là web (HTML5). Horus bọc nó thành app Android/iOS. Repo này không có và không cần code Android/iOS, Gradle, Xcode hay khoá ký.
- `horus-sdk.js` (global `HorusSDK`) hoặc `horus-sdk.mjs` là cầu nối duy nhất tới quảng cáo, mua hàng, analytics, Remote Config, cloud save. Trên trình duyệt, SDK giả lập quảng cáo và mua hàng. Trong app, nó dùng thật. Không cần nhánh code riêng cho hai nơi.
- `horus-build.mjs` gửi bản build web cho Horus và tải về APK/AAB (Build online). Đó là cách duy nhất ra app.

## Quy tắc khi sửa code

1. Gọi `await HorusSDK.start({ skus: [...] })` một lần trước khung hình đầu, rồi `platform.ready()` khi màn đầu đã vẽ.
2. Rewarded: chỉ thưởng khi `(await platform.ads.rewarded('<placement>')).ok === true`. Placement viết chữ thường, không dấu, và có trong `horus-game.json` (`ads.rewarded` / `ads.inter`).
3. Mua hàng: cộng hàng vào bản lưu và lưu ngay (`store.save`), **sau đó** mới `platform.iap.finish(...)`. Mỗi `token` giao một lần (ghi vào `buys`). Lúc mở game, giao hết `await platform.iap.pending()`. Món mua một lần dùng `consumable: false` và có nút Restore khi `platform.iap.restorable`. `status: 'invalid'` là đơn giả: không thưởng.
4. Lưu game qua `HorusSDK.save.createSaveStore` với `mirror: (json) => platform.save.mirror(json)`, hoặc gọi `platform.save.mirror` mỗi lần game tự lưu. Chỉ dùng localStorage thì người chơi mất tiến độ khi cài lại.
5. `platform.on('pause')` thì dừng game và tắt nhạc (quảng cáo đang chạy hoặc app ra nền); `resume` thì chạy lại.
6. Không thêm SDK quảng cáo, analytics, thanh toán hay tracking khác (Google Analytics, gtag, AdSense, Firebase JS, Stripe...). Horus đã gắn trong app; thêm vào sẽ trùng số liệu hoặc bị store từ chối.
7. Không tải gì từ CDN hay Internet lúc chạy: font, thư viện, ảnh đều nằm trong bản build, đường dẫn tương đối. App phải mở được khi không có mạng.
8. Tên sự kiện analytics và tham số: chữ thường, `snake_case`, giá trị phẳng (số, chuỗi). Ghi sự kiện mới vào `events` của `horus-game.json`.
9. Remote Config: `platform.rc.values.<khoá>` luôn là chuỗi, luôn có giá trị mặc định trong code. Khoá mới ghi vào `remoteConfig` của `horus-game.json`.
10. Không sửa, format lại hay bọc lại `horus-sdk.js` / `.mjs` / `horus-build.mjs`. Bản mới lấy từ Horus và thay nguyên file.
11. Trước khi tự viết luật interstitial, bậc thiếu xu, quà ngày, nhiệm vụ, lịch thông báo, đường giá, vỏ renderer three.js hay hiệu ứng hạt: dùng `monetize`, `liveops`, `economy`, `app`, `fx`, `perf` của SDK (README mục 13, kiểu trong `horus-sdk.d.ts`). three.js truyền vào (`THREE`), không lấy từ SDK.
12. Cập nhật nóng (README mục 11): không gọi `platform.hot.apply()` giữa lúc chơi (trang tải lại), chỉ ở menu. Thay đổi cần SDK, quyền hay cấu hình app mới thì nói với người dùng là phải ra bản store, không chỉ cập nhật nóng.

## Làm game mới

Người dùng nhờ làm một game mới (hoặc "game như Crash Ramp"): đọc `horus-sdk/GAME-GUIDE.md` từ đầu tới cuối trước khi viết code, rồi làm lần lượt từ bước 0.

1. Bước 0: viết `docs/design.md` (vòng chơi, tiền theo gì, nâng cấp, map) và hỏi người dùng những gì chưa rõ. Chưa được đồng ý thì không dựng cảnh 3D.
2. Mỗi bước: làm xong, kiểm đủ mục **Xong khi** của bước đó trên trình duyệt, báo người dùng một dòng, rồi mới sang bước sau.
3. Con số (giá, tiền, luật quảng cáo, offer, thông báo) để trong `src/config.js`, ghi đè được bằng Remote Config (`monetize.applyConfig`). Bắt đầu từ số của Crash Ramp trong hướng dẫn; đổi số kinh tế thì chạy lại mô phỏng (`economy.simulateEconomy`) và cho người dùng xem bảng.
4. Mỗi nút mời xem quảng cáo gửi `rv_offer` khi hiện ra, `rv_start` / `rv_done` khi xem; mọi lần nhận hay tiêu tiền gọi `platform.an.earn` / `spend`.
5. Không đổi luật đã chốt (kinh tế, quảng cáo, offer) mà không hỏi người dùng; ghi mỗi quyết định vào `docs/design.md` kèm ngày.
6. Hiệu năng: thử ở chế độ thiết bị của Chrome với CPU chậm 4 lần sau mỗi bước có đồ hoạ mới (ngân sách ở bước 5 của hướng dẫn).

## Build và gửi

```
npm run build                                  # build web của game (ra thư mục trong "web" của horus-game.json)
node horus-sdk/horus-build.mjs --dry-run       # kiểm tra gói gửi đi, không gửi
node horus-sdk/horus-build.mjs                 # APK cài thử, về build-online/
node horus-sdk/horus-build.mjs --aab           # AAB tải về (chỉ khi Horus đã cài đặt game)
node horus-sdk/horus-build.mjs --play          # AAB lên Google Play internal (chỉ khi người dùng yêu cầu)
node horus-sdk/horus-build.mjs --ios           # iOS lên TestFlight (chỉ khi người dùng yêu cầu)
node horus-sdk/horus-build.mjs ui              # trang build cho người dùng (họ bấm, không phải agent)
```

- `--play` và `--ios` đưa app lên store: agent chỉ chạy khi người dùng yêu cầu rõ trong lượt đó. Không có production; không thử track khác ngoài `internal` nếu Horus chưa cho.
- Mã build: người dùng chạy `node horus-sdk/horus-build.mjs --key <mã>` một lần, hoặc đặt `HORUS_BUILD_KEY`. Agent không tự tạo, không in, không ghi mã vào repo, log hay commit. Thiếu mã thì dừng và nhắc người dùng xin Horus.
- SDK tự cập nhật khi gửi build (dòng "Đã cập nhật Horus SDK ..."): đọc CHANGELOG.md mới, sửa game nếu API đổi, build lại bản web rồi gửi lại. Dòng "Có Horus SDK ... (đổi lớn)": báo người dùng, không tự chạy `update --major`. Không sửa file trong `horus-sdk/` và không commit `horus-sdk/.old/`.
- Chạy `--dry-run` trước và xử lý mọi dòng `chú ý:` (thiếu SDK trong bản build, tải từ CDN, thiếu icon).
- Build lâu vài phút: dùng `--no-wait` rồi `--job <mã>` nếu công cụ của agent có giới hạn thời gian cho một lệnh.
- `build-online/` là file tải về: để trong `.gitignore`.
- Lỗi "Horus has not set this app up for release builds" khi `--aab`: game chưa được Horus cài đặt cho team. Báo người dùng; APK thử vẫn build được.

## Kiểm tra trước khi báo xong

- Mở game trên trình duyệt (cỡ màn điện thoại): không lỗi Console; nút xem quảng cáo, mua hàng chạy với quảng cáo/mua giả lập.
- Mua hàng rồi tải lại trang: hàng vẫn còn, không giao hai lần.
- `horus-game.json` khớp code: mọi placement, SKU (giá USD, consumable), khoá Remote Config, sự kiện đều có.
- `node horus-sdk/horus-build.mjs --dry-run` không còn `chú ý:`.

## Ví dụ

`example/` trong gói SDK là một game đủ: `index.html` (start, rewarded, mua hàng, lưu, pending), `horus-game.json`, `horus-sdk.js`. Build thử: `node horus-build.mjs example`.
