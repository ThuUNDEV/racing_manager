# Pitlane Club — Thiết kế màn Loading khởi động v0.1

Ngày: 09/11/2026. Trạng thái: **đã triển khai bản đầu** (`scenes/loading.tscn`, `ui/loading.gd`, `game/boot_flow.gd`, test `tests/boot_test.gd`); trọng số bước chưa đo trên thiết bị thật.

Phạm vi theo yêu cầu: **chỉ thiết kế và tạo asset**. Các mục tích hợp bên dưới là hướng dẫn cho bước triển khai sau; không đổi entry scene hoặc mã gameplay trong đợt này.

Yêu cầu: khi mở game, xuất hiện một scene loading; thanh tiến độ đạt 100% rồi tự chuyển sang scene gameplay. Tài liệu này bổ sung [UI/UX v1.0](06_UI_UX_Release.md) và [Kiến trúc](07_Technical_Architecture.md); không thay đổi luật đua hoặc kinh tế.

## Cập nhật giao diện 11/11/2026

Đã tích hợp bản thiết kế Racing Tycoon được duyệt: logo trên nền xanh, xe cam trước garage và đường đua; dùng `assets/startup_loading/loading_garage_background.png`. Ảnh chỉ chứa minh họa và logo; trạng thái, thanh cam, phần trăm và phiên bản do `ui/loading.gd` hiển thị lúc chạy. Bỏ hoàn toàn mẹo, dòng “Chơi offline” và khẩu hiệu “Xây đội đua của bạn”. Không dùng panel sáng hoặc xe nhỏ trên thanh tải. Vẫn giữ luồng BootFlow, thông báo tải lâu, lỗi và thử lại. Phần mô tả mỹ thuật/bố cục cũ bên dưới được thay thế bởi cập nhật này; quy tắc tiến độ và bàn giao tiếp tục áp dụng.

## 1. Trải nghiệm mục tiêu

Người chơi thấy nhận diện game ngay khi mở, biết game đang chuẩn bị gì và vào gameplay tự động khi đã sẵn sàng. Không cần chạm “Bắt đầu”, không yêu cầu mạng. Loading dùng cho khởi động nguội và mở lại sau khi ứng dụng bị hệ điều hành đóng; quay lại từ nền khi phiên còn sống không chạy lại toàn bộ loading.

Luồng bình thường:

```text
Mở ứng dụng → Splash hệ thống/engine → Loading 0–99%
→ Gameplay đã chuẩn bị xong → Loading 100%
→ Chuyển cảnh → Gameplay → Panel chờ hiện có, nếu có
```

Splash hệ thống/engine là ảnh tĩnh trước khi Godot chạy được scene, không có phần trăm. Loading là scene tương tác do game quản lý. Đồng bộ nền và màu nhận diện giữa hai màn để tránh cảm giác chớp trắng/đen. Engine có thể vẫn cần thời gian khởi tạo trước loading; không hứa loại bỏ khoảng này bằng một scene.

## 2. Bố cục UI-25 — Loading khởi động

Màn hình dọc, theo phong cách Workshop GP hiện tại. Tên tạm dùng **PITLANE CLUB**, có thể thay qua nội dung nhận diện mà không đổi bố cục.

```text
┌──────────────────────────────────┐
│             vùng an toàn          │
│                                  │
│          PITLANE CLUB            │
│       Xây đội đua của bạn         │
│                                  │
│        [xe cam trong garage]     │
│                                  │
│       Đang chuẩn bị đội đua      │
│                                  │
│  Đang tải đường đua…        68%  │
│  █████████████████░░░░░░░░░░░░  │
│                                  │
│  Mẹo: Lốp giúp giữ tốc độ ở cua.  │
│                                  │
│  v<phiên bản>      Chơi offline  │
└──────────────────────────────────┘
```

| Thành phần | Quy định |
|---|---|
| Nền | Kem `#F6F0E7`, họa tiết đường pit mờ; nền phủ toàn màn hình |
| Nhận diện | Graphite `#202B38`, ở khoảng 15–25% chiều cao vùng an toàn |
| Minh họa | Một xe cam và nền garage đơn giản; khoảng 30–55% chiều cao, không dựng toàn cảnh đua |
| Trạng thái | Một dòng, chừa chỗ cho chuỗi dài và dấu tiếng Việt; nằm trên thanh tiến độ |
| Tiến độ | Thanh cam `#D9620A`, nền thanh `#E7DFD4`, phần trăm bằng chữ graphite đặt ngoài thanh |
| Mẹo | Một mẹo mỗi lần mở, tối đa 2 dòng; không đổi liên tục trong một lần tải |
| Footer | Phiên bản từ cấu hình build, ghi “Chơi offline”; trong safe area |

Tham chiếu kích thước logic 390 × 844, kiểm tra thêm 320 × 568, 360 × 800, 412 × 915 và viewport dự án 886 × 1920. Nội dung có lề ngang tối thiểu 24 ở kích thước tham chiếu. Co minh họa trước khi giảm cỡ chữ; không để loading phải cuộn. Chữ trạng thái 14–16, phần trăm 16–18, mẹo/footer tối thiểu 12 ở kích thước tham chiếu. Kiểm tra tương phản chữ trên màu thực tế, font phải hỗ trợ đủ dấu tiếng Việt.

Chuyển động chỉ gồm thanh tiến độ và một điểm sáng nhẹ trên xe; không cho xe chạy vòng vô hạn. Giảm chuyển động: xe đứng yên, cập nhật thanh trực tiếp và bỏ hiệu ứng chuyển cảnh. Không phát nhạc/tiếng máy trong loading; gameplay tiếp nhận cài đặt âm thanh rồi mới phát.

Asset có thể tái sử dụng: xe cam trong `assets/workshop_gp/cars/`, theme hiện tại, icon loading và `branding/splash_background.svg`. Splash hiện có nền graphite; cần tạo biến thể kem hoặc chỉnh nhận diện khi tích hợp, không mặc định asset này đã khớp thiết kế. Minh họa garage mới là hạng mục art cần chuẩn bị; fallback là xe cam trên nền kem, vẫn đọc đủ trạng thái và tiến độ.

## 3. Tiến độ loading

Phần trăm là **tiến độ chuẩn bị theo trọng số**, không phải phần trăm dung lượng tải từ mạng và không phải đồng hồ đếm giả. Các trọng số ban đầu dưới đây cần hiệu chỉnh bằng đo thực tế trên thiết bị.

| Bước | Khoảng | Công việc bắt buộc | Chữ hiển thị |
|---|---:|---|---|
| A | 0–10% | Vẽ loading tối giản ít nhất một frame, đọc cài đặt khởi động nhẹ | Đang khởi động… |
| B | 10–25% | Nạp cấu hình gameplay, kiểm tra schema và tham chiếu bắt buộc | Đang tải dữ liệu game… |
| C | 25–45% | Đọc/kiểm tra save; thử backup nếu cần; chuẩn bị trạng thái người chơi | Đang khôi phục đội đua… |
| D | 45–85% | Nạp tài nguyên scene gameplay và tài nguyên bắt buộc của màn đầu tiên | Đang tải đường đua… |
| E | 85–99% | Khởi tạo UI, gắn trạng thái, chốt offline đúng một lần, xác nhận gameplay sẵn sàng | Đang hoàn tất… |
| F | 100% | Tất cả điều kiện hoàn tất đều đạt; chuẩn bị bàn giao scene | Sẵn sàng! |

Quy tắc:

- Bước có tiến độ nội bộ đáng tin cậy thì dùng tiến độ đó; bước không đo được chỉ hoàn tất trọng số khi tác vụ thành công. Không dùng timer để tự tăng target.
- `target = tổng trọng số đã xong + trọng số bước hiện tại × tiến độ nội bộ`. Giá trị hiển thị có thể nội suy trong khoảng 150–250 ms nhưng không vượt target, không lùi trong cùng một lần thử.
- Giữ tối đa 99% cho đến khi nhận xác nhận gameplay sẵn sàng. Sau đó đưa thanh đến đúng 100%, đảm bảo đã vẽ ít nhất một frame 100%, giữ khoảng 150 ms rồi chuyển cảnh khoảng 200 ms.
- Không đặt thời gian loading tối thiểu vài giây. Máy nhanh được vào ngay sau nhịp 100% ngắn; máy chậm giữ đúng tiến độ, không báo xong trước.
- Nếu retry tạo lần thử mới, cho phép trở về 0% với trạng thái “Đang thử lại…”. Đây không phải thanh bị lùi trong cùng lần tải.
- Ads, IAP, analytics, remote config và cloud không thuộc điều kiện hoàn tất. Bản đầu vào game bằng save local; đồng bộ cloud về sau dùng luồng riêng, không ghi đè phiên đang chơi.

Mẹo khởi đầu: “Động cơ tăng tốc độ trên đoạn thẳng”, “Lốp giúp giữ tốc độ qua cua”, “Nâng cơ sở để tăng thu nhập”, “Không cần mạng để tiếp tục quản lý đội đua”. Không quảng bá tính năng chưa có trong bản build.

## 4. Điều kiện chuyển sang gameplay

Chỉ đạt 100% khi cùng thỏa:

1. Cấu hình bắt buộc hợp lệ; có xe, tay đua và track đang dùng.
2. Save hợp lệ đã được áp dụng, hoặc xác nhận chưa từng có save và đã tạo trạng thái mới hợp lệ.
3. Tài nguyên bắt buộc của scene gameplay đã tải xong; scene khởi tạo thành công, UI đã gắn dữ liệu và hoàn tất một lượt bố trí/vẽ phía sau lớp loading.
4. Thu nhập offline đã được chốt đúng một lần vào save và báo cáo chờ; nếu thao tác ghi bắt buộc thất bại thì chưa đạt điều kiện.
5. Không còn lỗi chặn hoặc hộp thoại cần người chơi xử lý; có quyền bàn giao duy nhất cho lần thử hiện hành.

Trong lúc chuẩn bị, gameplay chưa nhận input, chưa chạy race, chưa phát nhạc, chưa mở panel và chưa cộng thu nhập online. Bàn giao xong mới bật các hoạt động này. Thời gian từ mốc save đến bàn giao được quyết toán một lần theo quy tắc offline hiện hành, rồi đặt mốc online mới; không vừa tính offline vừa cộng online cho cùng khoảng thời gian. Thời gian hiệu ứng 100%/chuyển cảnh rất ngắn thuộc phiên online mới, không tính lại offline.

Scene loading giữ che kín màn trong toàn bộ quá trình khởi tạo gameplay. Sau 100%, fade lớp loading ra để lộ gameplay đã sẵn sàng, rồi giải phóng loading. Không có frame rỗng ở giữa. Không có nút “Chạm để tiếp tục” trong luồng bình thường.

Sau bàn giao, chuyển về tab Đua mặc định. Các panel offline/kết quả/tổng kết đang chờ do một bộ điều phối gameplay mở lần lượt theo thứ tự ưu tiên hiện hành; loading không tự nhận thưởng hoặc tự đóng các panel này. Hướng dẫn đầu game, nếu triển khai, bắt đầu sau các panel bắt buộc. Không thêm onboarding vào phạm vi loading.

## 5. Lỗi, tải lâu và vòng đời ứng dụng

| Trường hợp | Hành vi |
|---|---|
| Chưa có save | Tạo người chơi mới, tiếp tục loading; không báo lỗi |
| Save chính lỗi, backup hợp lệ | Khôi phục backup, tiếp tục; gameplay hiện thông báo một lần |
| Cả save chính và backup lỗi | Dừng trước 100%, hiện “Không thể đọc tiến trình đã lưu”; có “Thử lại”; giữ nguyên cả hai file. Không tự reset. Hướng dẫn liên hệ hỗ trợ nếu tiếp tục thất bại |
| Save từ phiên bản mới hơn | Giữ dữ liệu; báo cần phiên bản game phù hợp, không hạ schema hoặc tạo save trắng |
| Lỗi ghi save bắt buộc | Dừng trước 100%, báo “Chưa lưu được tiến trình. Hãy kiểm tra dung lượng trống rồi thử lại”; không cộng thưởng lần hai khi retry |
| Thiếu asset trang trí | Bỏ minh họa/hiệu ứng đó, tiếp tục nếu gameplay vẫn đủ tài nguyên bắt buộc |
| Thiếu/hỏng asset gameplay hoặc dữ liệu bắt buộc | Dừng, báo lỗi dễ hiểu và mã hỗ trợ; cho thử lại. Không vào scene lỗi |
| Không có mạng | Vào gameplay local bình thường; không dựng hộp thoại lỗi mạng |
| 10 giây foreground chưa có tiến triển | Giữ % hiện tại, đổi dòng phụ thành “Lần khởi động này đang mất nhiều thời gian hơn…” |
| 30 giây foreground chưa có tiến triển | Giữ loading và hiện “Thử lại”; không chuyển thành lỗi nếu tác vụ vẫn chạy. Kết quả đến trước khi bấm thì tiếp tục bình thường |
| App ra nền | Dừng hiệu ứng và bộ đếm tải lâu. Tác vụ được phép hoàn tất nhưng không tự bàn giao khi ứng dụng chưa foreground |
| Quay lại từ nền | Tiếp tục cùng lần thử, kiểm tra tác vụ đã hoàn tất; không đọc save/chốt offline lần hai |
| Bị hệ điều hành đóng giữa loading | Lần mở sau chạy lại từ đầu bằng save đã commit gần nhất; thưởng offline không phát trùng |

Màn lỗi dùng lại bố cục loading: tiêu đề, giải thích tối đa 2–3 dòng, mã lỗi nhỏ và nút “Thử lại” cao tối thiểu 48. Ví dụ mã: `BOOT_DATA`, `BOOT_SAVE`, `BOOT_RESOURCE`, `BOOT_WRITE`. Không đưa stack trace hoặc đường dẫn file vào thông báo người chơi.

Retry không tạo hai luồng ghi save: mỗi lần thử có token riêng; callback cũ không được đổi UI, ghi dữ liệu hoặc chuyển scene. Tác vụ ghi đã bắt đầu phải được chờ hoàn tất/đối soát trước khi lần thử mới đi vào bước commit. Tài nguyên đang tải có thể được dùng lại sau khi xác minh; không khởi động hai yêu cầu trùng và không dừng main thread để chờ.

## 6. Điểm tích hợp với project hiện tại

Hiện `project.godot` mở trực tiếp `scenes/main.tscn`. `GameState` là autoload: một số biến khởi tạo đã gọi `Balance`/`GameData`, `_ready()` gọi `load_game()` và `_settle_offline()`, `_process()` tự cộng tiền/lưu. `ui/main.gd::_ready()` dựng UI, mở panel chờ và phát nhạc ngay. Vì vậy chỉ thêm scene loading phía trước chưa đủ để loading quản lý toàn bộ khởi tạo.

Thiết kế trách nhiệm khi triển khai:

| Thành phần đề xuất | Trách nhiệm |
|---|---|
| `scenes/loading.tscn` | Scene khởi động, giao diện nhẹ và lớp che chuyển cảnh |
| `ui/loading.gd` | Hiển thị %/trạng thái/lỗi, phát yêu cầu thử lại; không xử lý kinh tế |
| `game/boot_flow.gd` | Điều phối các bước, trọng số, token lần thử, readiness và bàn giao scene |
| `GameData` | Nạp/kiểm tra cấu hình theo bước B; trả lỗi có cấu trúc trước khi đọc chỉ số |
| `GameState` | Khởi tạo trạng thái rõ ràng, kiểm tra schema/save, quyết toán offline một lần, chỉ bật runtime khi bàn giao |
| `ui/main.gd` | Tách chuẩn bị UI khỏi kích hoạt phiên; báo sẵn sàng sau layout/vẽ, chỉ mở panel/phát âm thanh khi bàn giao |

Khi triển khai, autoload phải nhẹ: bỏ việc nạp dữ liệu khỏi khởi tạo trường và không tự đọc save trong `_ready()`. Dùng trạng thái mặc định chưa khởi tạo an toàn, sau đó BootFlow gọi khởi tạo theo thứ tự. Mọi tác vụ `_process()`/autosave/lifecycle save đều được chặn cho tới khi trạng thái hợp lệ. Đọc cài đặt nhẹ trước chỉ cần ngôn ngữ/giảm chuyển động; nếu chưa có hệ thống cài đặt thì dùng mặc định, không giả vờ đã lưu tùy chọn.

Nạp scene/tài nguyên nặng bất đồng bộ bằng cơ chế Godot phù hợp với phiên bản engine đã khóa. Tạo node và sửa SceneTree trên main thread; chia việc dựng UI thành các đợt nhỏ nếu đo thấy giật. Chỉ đưa phần sẵn sàng đầu tiên vào đường tải bắt buộc; asset của màn chưa mở có thể tải sau. Không gọi hàm chờ kết quả đồng bộ trước khi tác vụ tải báo hoàn tất.

Máy trạng thái khởi động độc lập với `ready/racing/resolved/summary` của gameplay:

```text
Boot → Data → Save → Resources → PrepareGameplay → Ready100 → Transition → Gameplay
Lỗi ở bước bắt buộc → Error → Retry → Boot (lần thử mới)
```

Retry quay về bước khởi tạo của lần thử mới. App ra nền là cờ vòng đời, không tự reset máy trạng thái. Mỗi lần mở chỉ có một lần bàn giao thành công.

## 7. Phạm vi và thứ tự triển khai

1. Tách khởi tạo `GameState` khỏi autoload và tách chuẩn bị/kích hoạt gameplay; bổ sung readiness và kết quả lỗi rõ ràng.
2. Dựng loading tối giản, đổi entry scene, nối nạp dữ liệu/save/tài nguyên và tiến độ có trọng số.
3. Nối 100%, giữ một frame, chuyển cảnh, mở đúng panel chờ; chặn phát thưởng/khởi tạo/bàn giao trùng.
4. Bổ sung lỗi/retry, resume, tương thích save, fallback art.
5. Tích hợp minh họa, safe area, bản địa hóa; đo trên thiết bị rồi điều chỉnh trọng số và tối ưu tác vụ chậm.

Không bao gồm tải nội dung từ server, đăng nhập, cloud conflict, tích hợp SDK, thay cơ chế đua hoặc làm toàn bộ hệ thống cài đặt. Các nội dung này có thiết kế riêng.

## 8. Tiêu chí nghiệm thu

- Cold start hiển thị loading trước khi dựng gameplay nặng; không đọc cấu hình/save nặng từ autoload trước frame loading đầu tiên.
- Mô phỏng thiết bị chậm: phần trăm không lùi, không vượt công việc đã hoàn tất; không bao giờ 100% trước readiness.
- Có ít nhất một frame nhìn thấy 100%, sau đó tự chuyển đúng một lần; không chạm thêm, không chớp màn rỗng, không tương tác xuyên lớp loading.
- Máy nhanh không bị giữ bởi đồng hồ giả; mục tiêu tổng cold start tới gameplay tương tác ≤ 4 giây trên thiết bị tầm trung theo 03, cần đo thực tế trước khi khẳng định đạt.
- Không save: tạo mới; có save: đúng tiền, cấp, mùa, chặng và panel đang chờ.
- Save lỗi: thử backup; cả hai lỗi hoặc schema mới hơn: bảo toàn file, không ghi save trắng.
- Offline trong giới hạn/trên trần/giờ lùi đúng luật hiện có; retry, pause/resume và đóng app sau commit không nhân đôi thưởng.
- Bật giả lập lỗi ghi: không bàn giao; retry không ghi chồng hoặc phát thưởng lại.
- Tác vụ cũ trả về sau retry không đổi scene/UI/save; bấm retry nhiều lần chỉ có một lần thử đang điều phối.
- Offline hoàn toàn vẫn vào được; dịch vụ tùy chọn chậm/lỗi không giữ thanh loading.
- Lỗi asset trang trí dùng fallback; lỗi asset bắt buộc dừng với thông báo và retry.
- Test bố cục ở các kích thước §2, safe area/notch, tiếng Việt/Anh, giảm chuyển động và chữ lớn.
- Smoke test trực quan trên desktop và thiết bị Android/iOS mục tiêu trước khi đánh dấu tính năng hoàn thành.

Bản xem thử trong chat chỉ minh họa bố cục và các trạng thái; thời gian và phần trăm trong bản đó là mô phỏng, không phải số đo loading thực tế.

## 9. Asset đã tạo

Bộ art nằm ở [Assets/StartupLoading](Assets/StartupLoading/README.md):

- [Nền loading](Assets/StartupLoading/loading_background.png): PNG dọc, nền garage không xe, không chữ và không thanh tiến độ; để trống khu vực nhận diện và loading.
- [Xe cam tách nền](Assets/StartupLoading/loading_car.png): PNG RGBA; đã kiểm tra alpha bằng 0 tại góc và giữa cạnh trái. Có bóng/ánh sáng mềm quanh xe, cần duyệt trên nền thực tế khi tích hợp.
- [Concept màn hoàn chỉnh](Assets/StartupLoading/loading_screen_concept.png): ảnh tham khảo bố cục, có tên game, xe, thanh tiến độ và chữ; không dùng ảnh concept làm UI runtime.

Concept là bố cục đề xuất để xem, chưa phải screenshot game đang chạy. Khi dùng art đã tạo, cho garage chiếm khoảng 32–68% chiều cao thay cho minh họa nhỏ ban đầu; giữ khu vực tiêu đề phía trên và trạng thái/thanh/mẹo ở phía dưới. Vị trí xe và typography cần căn lại theo safe area; thông số bố trí ban đầu nằm trong README của bộ asset. Logo/tên, trạng thái, %, thanh tiến độ, mẹo và phiên bản vẫn là lớp UI riêng khi triển khai.
