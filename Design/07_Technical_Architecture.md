# Racing Manager — Thiết kế v1.0: Kiến trúc kỹ thuật và phát hành

> **Economy v2 — 10/11/2026:** [12 §8–11](12_BigNumber_Economy.md#8-đặc-tả-bignumber) quy định kiểu BigNumber 24 chữ số có nghĩa, đường tính coins, serialization và migration v3→v4 dự kiến. Lõi runtime đã triển khai theo [biên bản 13](13_Economy_v2_Implementation.md), thay cách lưu/tính coins bằng số nguyên thông thường ở thiết kế cũ.

> **Cập nhật nhịp đua 09/11/2026:** [10 — Đua liên tục theo thời gian](10_Continuous_Race_Loop.md) định nghĩa điều phối `Countdown → Racing → Resolving → Countdown`, kết thúc theo thời lượng cấu hình, snapshot đội và migration/checkpoint. Đây là đặc tả mới chưa triển khai, thay luồng Ready/nút bấm/đủ 3 vòng/chờ panel trước đây; các ghi nhận triển khai bên dưới vẫn mô tả mã hiện có.

Ngày: 09/11/2026. Trạng thái: đề xuất để duyệt. Đi cùng [03](03_Release_Overview.md)–[06](06_UI_UX_Release.md). Project hiện có: Godot 4.7, GDScript, prototype tại `scripts/`, `scenes/`, `tests/`.

## 0. Trạng thái triển khai M1 (09/11/2026)

Đã làm: git khởi tạo (chưa commit); cấu trúc `core/`, `game/`, `ui/`, `data/`, `tools/`, `tests/`; `data/*.json` (sim, tracks, leagues, cars, drivers, economy) cùng `GameData` (nạp + `validate()`) và `Pricing`; mô phỏng v1.0 đọc toàn bộ hệ số từ dữ liệu, có đặc tính tay đua; 4 bộ test headless (dữ liệu, golden, mô phỏng, giao dịch) chạy bằng `tools/run_tests.sh` hoặc `tools/run_tests.ps1`; workflow `.github/workflows/ci.yml`.

Cập nhật sau Design/08: thêm mô phỏng có chiều ngang `TrafficSim` (`core/sim/traffic_sim.gd`) và hình học đường đua `TrackLayout` (`core/sim/track_layout.gd`); `data/tracks.json` có thêm `Circuit A` (sector có `width`, `width_end`, `zone`, `turn`), `data/sim.json` có thêm nhóm `traffic` cùng `car_length`/`car_width`. `RaceSim` v1.0 giữ làm chuẩn tham chiếu (golden và lab so sánh); `GameState` và `RaceView` đã chạy bằng `TrafficSim` trên Circuit A. Test mới: `tests/traffic_test.gd`, golden `tests/golden/traffic_golden.json`; lab: `tests/lab/traffic_lab.gd`, `traffic_promo.gd`, `traffic_tune.gd`, `traffic_probe.gd`.

Chưa làm / giới hạn: workflow CI chưa chạy trên GitHub (chưa có remote); chưa xác minh plugin quảng cáo/IAP với Godot 4.7; chưa có `Clock` tách riêng; save vẫn schema prototype (đổi ở M4); UI chỉ vẽ được track có hình học (hiện chỉ Circuit A; 10 track còn lại cần `turn` và nền riêng, đến M3); hằng số cấu trúc (số vòng, độ dài vòng, tick) còn nhân đôi trong `Balance` và được `data_test` kiểm tra khớp `sim.json`; cân bằng thăng giải với `TrafficSim` mới đo sơ bộ (xem Design/08 §10).

## 1. Nền tảng và công cụ

| Hạng mục | Lựa chọn đề xuất | Ghi chú |
|---|---|---|
| Engine | Godot 4.7.x (D6) | Giữ version khóa theo mốc; nâng cấp engine chỉ ở đầu mốc, không giữa mốc |
| Ngôn ngữ | GDScript có kiểu | Mô phỏng và kinh tế thuần logic, không phụ thuộc node |
| Nền tảng | Android (AAB), iOS | iOS cần máy macOS và tài khoản nhà phát triển để build/ký |
| Quảng cáo | SDK qua plugin Godot | **Xác minh plugin hỗ trợ đúng phiên bản Godot** trước M5 (rủi ro tích hợp) |
| IAP | Plugin Google Play Billing + StoreKit | Cùng điều kiện xác minh |
| Đám mây | Google Play Games Services / iCloud-GameCenter | Dùng dịch vụ nền tảng, không tự dựng backend |
| Analytics/Crash | Firebase (Analytics, Crashlytics) hoặc tương đương | Chỉ sau consent; bản chưa consent chỉ ghi crash ẩn danh nếu luật khu vực cho phép |
| Quản lý mã | Git; nhánh `main` luôn build được | Repo hiện chưa phải git: khởi tạo ở M1 |
| CI | Chạy Godot headless: kiểm tra cú pháp, test, lab cân bằng | Không phụ thuộc phiên bản máy dev |

## 2. Cấu trúc thư mục (đề xuất)

```text
res://
  data/                 # JSON/Resource cấu hình, có schema_version
    tracks.json  leagues.json  cars.json  drivers.json
    economy.json missions.json achievements.json  strings/ (vi.csv, en.csv)
  core/                 # logic thuần, không UI, không singleton engine
    sim/    race_sim.gd, track.gd, car_state.gd, rng.gd
    economy/ economy.gd, pricing.gd, offline.gd
    progression/ season.gd, league.gd, unlocks.gd, missions.gd
    save/   save_model.gd, save_io.gd, migrations/
  services/             # giao diện + triển khai; có bản giả cho desktop/test
    ads_service.gd  iap_service.gd  cloud_service.gd  analytics.gd  consent.gd
    platform/  (adapter thật theo nền tảng)
  game/                 # autoload mỏng điều phối: GameSession, SaveService, Clock
  ui/                   # scene, theme, component dùng lại
    screens/  components/  theme/
  tests/                # unit, integration, golden, lab
```

Quy tắc phụ thuộc: `ui → game → core`; `services` được tiêm vào `game`; `core` không import `ui` hay `services`. Một hằng số cân bằng chỉ nằm ở `data/` (không rải trong code hoặc scene).

## 3. Dữ liệu và cấu hình

- Định dạng JSON (đọc/ghi diff được), nạp thành đối tượng có kiểu khi khởi động; kiểm tra schema bằng script chạy trong CI (thiếu trường, khóa trùng, track không cộng đủ 400 đơn vị mỗi vòng, tham chiếu id sai).
- **ID ổn định** (`car_pine_s`, `driver_an`, `league_2`, `track_harbor`) không đổi giữa phiên bản; save chỉ lưu ID và cấp.
- **Remote config** chỉ cho phép ghi đè một danh sách trắng khóa kinh tế (hệ số, tỷ lệ offline, trần, thưởng, giá) và công tắc (ads/IAP/thử thách ngày). Không cho ghi đè công thức mô phỏng đua trong bản phát hành để giữ lặp lại theo seed.
- Mọi cấu hình có số phiên bản; bản phát hành giữ bản dự phòng nhúng khi mạng không có.

## 4. Mô phỏng đua

- Fixed tick 10 Hz, độc lập FPS; render nội suy. Kết quả chỉ phụ thuộc seed + chỉ số + định nghĩa track.
- RNG: `RandomNumberGenerator` có seed riêng cho từng race (không dùng RNG toàn cục); lưu `state` khi checkpoint.
- Quy tắc đã chốt từ lab cân bằng và sửa lỗi prototype (xem 04 §2–3): xử lý xe từ trước ra sau; trùng vị trí → xe có `id` nhỏ được coi là ở trước (tránh khóa chéo); xe đứng yên quá 2 giây thì bỏ qua cản trong lượt đó; cưỡng bức chốt race nếu vượt 1.200 giây (không kỳ vọng xảy ra, ghi sự kiện `race_forced_finish`).
- **Golden test:** danh sách (seed, cấu hình xe, track) → băm của thời gian về đích; thay đổi băm yêu cầu cập nhật có chủ đích khi đổi công thức.
- **Chống hồi quy:** test hàng trăm race với build ngẫu nhiên, khẳng định không race nào phải chốt cưỡng bức và mọi xe có thời gian > 0 (đã có trong `tests/sim_test.gd`).
- Checkpoint mỗi 5 giây mô phỏng, khi app ra nền và trước/sau kết quả; snapshot gồm RNG state, thời gian, từng xe (quãng đường, tốc độ, bộ đếm lỗi/vượt, cờ lỗi vòng).
- Dữ liệu giải thích kết quả (thời gian vòng, số lỗi, giây mất do lỗi, giây mất do bám xe, vượt thành công) được ghi trong race log và lưu cùng kết quả.

## 5. Save, migration và đám mây

### 5.1. Save cục bộ

- Một tệp save chính, `schema_version` và `save_revision` tăng mỗi lần ghi; tệp phụ `.bak` là bản hợp lệ trước đó.
- **Ghi nguyên tử:** ghi tệp tạm → đọc lại và xác thực → sao lưu bản hiện tại → thay thế. Mất điện giữa chừng không để lại save hỏng.
- Có hash toàn vẹn. Lỗi đọc → thử `.bak` → nếu cả hai hỏng, khóa ghi, hiện UI-21; không tự ghi đè bằng save trắng.
- Danh sách ID thưởng đã xử lý được giữ theo cửa sổ gần đây (race, mùa, offline, quảng cáo, IAP) và nén khi quá dài; ID duy nhất theo mẫu `race/<mùa>/<chặng>`, `offline/<save_revision>`, `ad/<transaction>`, `iap/<order>`.
- Giao dịch quan trọng (mua, thưởng, kết quả) ghi ngay; cập nhật thường xuyên gom theo chu kỳ ≤ 10 giây.

### 5.2. Migration

- Mỗi thay đổi schema có `migrations/vN_to_vN+1.gd` thuần hàm; test migration bằng bộ save mẫu của mọi phiên bản phát hành trước.
- Phiên bản mới đọc được mọi save cũ; save mới hơn phiên bản app (hạ cấp) → từ chối ghi và hướng dẫn cập nhật.
- Save mẫu từ prototype 0.2 (`user://save.json`) được di chuyển ở 0.5.

### 5.3. Đám mây (D5)

- Tùy chọn, đăng nhập qua tài khoản nền tảng. Đồng bộ khi: mở app, sau thưởng quan trọng, khi ra nền.
- Xung đột (hai thiết bị lệch nhau): so `save_revision` và tổng tiến trình; nếu khác nhau rõ ràng, UI-22 cho người chơi chọn, **không tự động ghi đè**. Không gộp từng trường (tránh nhân đôi thưởng).
- Chỉ đồng bộ dữ liệu tiến trình, không đồng bộ mốc offline (thiết bị nào mở lại thì tự tính).
- Có thể tắt; tắt không ảnh hưởng chơi offline.

## 6. Dịch vụ nền tảng (giao diện)

```text
AdsService:    is_ready(placement) / show_rewarded(placement) -> {ok, transaction_id}
IapService:    products() / purchase(id) / restore() / owned()
CloudService:  sign_in() / pull() / push(save)
Analytics:     log(event, params)         # chỉ sau consent
Consent:       status() / request()
Clock:         now_utc()                  # tách để test và chống chỉnh giờ
```

Mỗi dịch vụ có bản `Null/Mock` cho desktop và test. Bản phát hành chọn triển khai theo nền tảng và theo kết quả consent. Gọi lỗi/hết giờ luôn trả kết quả rõ ràng, UI không bị treo.

Bảng xếp hạng Thử thách ngày dùng bảng xếp hạng của nền tảng (Play Games / Game Center) với điểm đã tính từ seed theo ngày UTC; xác minh phía server chỉ cần nếu sau này có phần thưởng giá trị cao.

## 7. Đo lường

Sự kiện tối thiểu (mọi sự kiện có `app_version`, `save_revision`, `league`, `session_index`):

| Nhóm | Sự kiện |
|---|---|
| Phiên | `session_start`, `session_end`, `offline_claim` |
| Tiến trình | `race_start`, `race_finish` (vị trí, thời gian, lỗi, bám xe), `season_complete`, `league_unlock` |
| Kinh tế | `purchase_upgrade`, `purchase_car`, `scout_driver`, `currency_snapshot` |
| Thương mại | `ad_offered`, `ad_completed`, `iap_started`, `iap_completed` |
| FTUE | `tutorial_step`, `tutorial_skip` |
| Chất lượng | `save_recovered`, `race_forced_finish`, lỗi dịch vụ |

Không ghi dữ liệu cá nhân trực tiếp; ID thiết bị/quảng cáo chỉ dùng khi người chơi đồng ý. Mỗi sự kiện có tài liệu tham số và kiểm tra trong CI (không để tham số tự do làm bùng nổ phương thức).

## 8. Hiệu năng và kích thước

| Chỉ tiêu | Ngân sách (giả định, đo trên máy thật) |
|---|---|
| Khung hình khi đua | ≥ 55 FPS trên Android tầm trung 3 GB RAM và iPhone đời cũ vài năm |
| Khởi động nguội | ≤ 4 giây |
| Bộ nhớ | ≤ 250 MB |
| Dung lượng cài đặt | ≤ 80 MB |
| Pin | Không chạy nền khi ra khỏi app; khung đua giảm FPS khi tab khác |

Khung đua dùng vẽ 2D đơn giản (vài chục đối tượng), không physics engine. Ưu tiên bộ nhớ tập trung: atlas texture, một font, âm thanh nén.

## 9. QA và kiểm thử

| Loại | Phạm vi | Công cụ |
|---|---|---|
| Unit | Công thức giá, rate, thưởng, offline, điểm mùa | GDScript headless (`tests/*.gd`) |
| Mô phỏng | Xác định, toàn vẹn, chống treo, golden | `tests/sim_test.gd` + bộ golden |
| Cân bằng | Tác động từng chỉ số trên từng track, phân phối vị trí | `tests/lab/balance_lab.gd`, chạy theo tuần |
| Giao dịch | Khóa nâng cấp khi đua, thưởng không trùng, chốt mùa | `tests/state_test.gd` |
| Save | Mất điện giữa ghi, tệp hỏng, migration, nhiều lần mở/đóng | Kịch bản có công cụ phá hỏng tệp |
| Thời gian | Giờ lùi/tiến, vắng 1/8 giờ, đổi múi giờ, qua nửa đêm UTC | Clock giả |
| UI | Mọi màn ở 6 kích thước, cỡ chữ 130%, giả bản địa hóa | Chụp ảnh tự động + duyệt tay |
| Thiết bị | Ma trận Android (hãng/Android/RAM) và iOS | Thiết bị thật |
| Dịch vụ | Ads/IAP/cloud thành công, hủy, lỗi, mất mạng | Tài khoản thử của store |
| Trải nghiệm | Thử người dùng FTUE, playtest 15 phút / 1 giờ / 8 giờ vắng | Có ghi chép |

Cổng chất lượng mỗi mốc: tất cả test tự động qua; không lỗi mức nghiêm trọng mở; crash-free sessions đạt ngưỡng (03 §4).

## 10. Build và phát hành

- Phiên bản `MAJOR.MINOR.PATCH` + số build tăng dần; ghi vào save và analytics.
- Pipeline: commit → CI (kiểm tra, test, lab nhanh) → build Android AAB ký bằng khóa trong kho bí mật → phân phối thử (nhánh thử nội bộ) → duyệt tay → phát hành theo giai đoạn (ví dụ tăng dần phần trăm người dùng, theo dõi crash).
- iOS: build trên macOS, TestFlight cho beta; xử lý yêu cầu review (khôi phục mua, privacy labels).
- Công tắc từ xa (remote config) để tắt quảng cáo/IAP/Thử thách ngày khi có sự cố mà không cần phát hành lại.
- Kế hoạch hotfix: lỗi gây mất tiền/thưởng trùng được ưu tiên cao nhất; có kịch bản thu hồi (đối chiếu ID thưởng) nếu thưởng trùng đã xảy ra.
- Store listing: tiêu đề, mô tả, ảnh chụp, video ngắn, phân loại độ tuổi, chính sách riêng tư, hỗ trợ; chuẩn bị ở M7–M8.

## 11. Bảo mật và quyền riêng tư

- Không thu thập dữ liệu cá nhân ngoài định danh bắt buộc của dịch vụ nền tảng; analytics/quảng cáo chỉ sau consent.
- Save mã hóa nhẹ + hash toàn vẹn để ngăn chỉnh sửa vô ý, không coi là chống gian lận mạnh (xem 05 §9).
- Khóa ký, khóa API trong kho bí mật, không nằm trong repo.
- Tuân thủ chính sách của store (xem 05 §8); rà soát SDK bên thứ ba khi thêm.

## 12. Rủi ro kỹ thuật

| Rủi ro | Giảm thiểu |
|---|---|
| Plugin ads/IAP chưa tương thích Godot 4.7 | Xác minh sớm bằng bản thử ở M1; phương án: khóa phiên bản Godot đã được hỗ trợ hoặc tự viết wrapper mỏng |
| Khác biệt dấu phẩy động giữa nền tảng | Mô phỏng chỉ dùng phép tính cơ bản và số kiểu double của Godot; golden test chạy trên cả hai nền tảng |
| Save hỏng/cloud xung đột | Ghi nguyên tử, bản sao, UI chọn thủ công, test phá hỏng |
| Thưởng quảng cáo/IAP trùng | ID duy nhất + chỉ phát sau callback + test ép hủy/lặp |
| Hiệu năng máy yếu | Đo ở M3 trên máy thấp; có chế độ hiệu ứng giảm |
| Nợ cân bằng (bug như deadlock đã tìm ra ở prototype) | Chạy lab và hồi quy trên CI; bất kỳ race nào chốt cưỡng bức là lỗi |
