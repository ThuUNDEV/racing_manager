# Racing Tycoon (racing_manager)

Game idle/manager đua xe, Godot 4.7 (GDScript, Forward Plus), màn dọc 886x1920 (logical 390x845). Đua tự lặp liên tục, không có nút "Đua". Phát hành web/mobile qua Horus SDK.

## Cấu trúc

- `game/`: autoload (`GameState`, `Ads`, `Iap`, `Horus`), tiến trình, tutorial, daily rewards.
- `core/`: logic thuần (economy, sim, math, save, i18n, balance). Không phụ thuộc UI.
- `ui/`: trang và popup. `ui/main.gd` là khung 5 tab Race/Gear/Team/Leagues/Shop.
- `scenes/`: `splash` (scene khởi động) -> `loading` -> `main`.
- `data/*.json`: dữ liệu cân bằng (economy, cars, drivers, gear, tracks, leagues, sim, ads, iap...). Chỉnh số ở đây, không hardcode trong code.
- `i18n/*.json`: 8 ngôn ngữ (en gốc, vi, id, ms, th, ja, ko, zh_Hans). Quy ước chi tiết: `docs/i18n.md`.
- `Design/`: tài liệu thiết kế đánh số (`01..34_*.md`), asset pack, demo, mockup.
- `tests/`: test headless `*_test.gd`. `tools/`: script Python/PowerShell (build web, kiểm i18n, đóng gói asset).
- `horus-game.json`: metadata phát hành (appId, repo, languages, ads, products). `appId` và `repo` còn trống.
- `export_presets.cfg`, `export/web`: xuất bản.

## Lệnh thường dùng

- Chạy toàn bộ test: `tools/run_tests.sh` (đặt `GODOT=<đường dẫn godot>` nếu không có trong PATH; script tự đặt `RM_LANG=vi`).
- Chạy một test: `RM_LANG=vi godot --headless --path . -s res://tests/<tên>_test.gd`
- Kiểm i18n: `python -X utf8 tools/i18n_check.py` (`--missing ja` để liệt kê khóa còn thiếu).
- Build web: `tools/build_web.ps1`.
- Godot thoát mã 0 kể cả khi script lỗi cú pháp: dùng công cụ MCP `script_check` hoặc grep `SCRIPT ERROR|Parse Error`.

## Chạy game an toàn

- Mọi lần chạy game hoặc test có cửa sổ (không `--headless`) phải mở ở màn hình phụ và tắt tiếng: `godot --path . --screen 1 --audio-driver Dummy ...`. Ví dụ chạy một test có cửa sổ: `XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy -s res://tests/<tên>_test.gd`.
- Test thường và script dump/layout chạy `--headless` (không cửa sổ, không tiếng), như `tools/run_tests.sh`. Chỉ bỏ `--headless` khi cần thấy hoặc chụp màn hình thật.
- `game_run` của Godot MCP chỉ truyền được tham số người dùng (sau `--`), không truyền được `--screen` hay `--audio-driver`. Nên khi cần chạy có cửa sổ, chạy `godot` trực tiếp bằng Bash với các cờ trên, không dùng `game_run` không-headless.
- Các cờ CLI như `--races=N`, `--gated`, `--tutorial-done` ghi vào `save.json` thật. Luôn đặt `XDG_DATA_HOME=<thư mục tạm>` khi chạy game/test có cờ này.
- Không chạy `--reset` nếu chưa hỏi người dùng.

## Quy ước code

- Mọi chuỗi hiển thị qua `I18n.t("khu.ten")`. Thêm khóa vào `en.json` và `vi.json` trước, rồi chạy `tools/i18n_check.py`, rồi điền các ngôn ngữ còn lại. Giữ thứ tự placeholder `%s/%d` đúng như bản en.
- Chuỗi trong data JSON viết dạng `"@data.<tệp>.<id>"`. Lỗi, log, `push_error` viết tiếng Anh thường, không dịch.
- Không so sánh chữ đã dịch trong logic (dùng id hoặc cờ). Số định dạng bằng `Balance.fmt_*` hoặc `I18n.dec()`.
- Test assert dùng câu tiếng Việt, nên chạy với `RM_LANG=vi`.
- Không sửa tay file `.tscn` khi Godot editor đang mở.
- Không commit `output/`, `.godot/`, `export/`, khóa ký, `.env` (xem `.gitignore`).

## Thiết kế và UI

- Hướng nghệ thuật hiện hành: **Soft Miniature** (`Design/Demos/SoftMiniature/approved/`, bố cục chuẩn `layout-review.html`, kit runtime `assets/soft_miniature_ui_v1/` + `ui/soft_miniature.gd`). `Design/33_Art_Style_Guide.md` (glossy) và `shop_blue_white` đã lỗi thời. Khi nghi ngờ, xem thư mục mới nhất trong `Design/Demos` và `Design/Previews`.
- `ui/shop_page.gd` vẫn dùng skin cũ, chưa chuyển sang Soft Miniature.
- Trước khi làm mockup hay concept UI, đọc `Design/*.md` liên quan (10, 11, 14, 17, 28) và dùng số liệu thật: 8 nâng cấp (Xe + Doanh thu), 5 tab, Shop cuộn theo thứ tự cố định, gem 50/275/600/1300/3500. Giữ layout hiện tại, chỉ đổi ngôn ngữ hình ảnh.
- "Mockup layer/layout" nghĩa là tài liệu Markdown đặc tả (toạ độ, kích thước, cây node), không phải ảnh chụp hay HTML. Trích số liệu từ cây node bằng script SceneTree headless, ghi vào `Design/34_Layer_Layout_Spec.md`.

## Công cụ MCP

- `godot` (`.mcp.json`): gọi `project_info` trước; viết `.gd` rồi `script_check`; dùng `class_info` thay vì đoán API. `.mcp.json` dùng `${HOME}`, nên mỗi máy chỉ cần cài `godot-mcp` vào `~/.local/bin/`. `godot-mcp` tự tìm `project.godot` từ thư mục làm việc (hoặc `GODOT_PROJECT`), và tìm Godot qua `GODOT_PATH` hoặc PATH.
- `art-tools`: tách nền, viền, phóng to ảnh.

## Tạo ảnh demo / asset

Quy trình 2 phần:

**Phần 1: Concept (ảnh demo cả màn hình)**
- Dùng Codex model `GPT-6.1-Sol`, mức reasoning `medium`, kèm skill image gen. Giao qua `delegate_task` (provider Codex), không tự sinh bằng model khác.
- Ảnh concept lưu vào `Design/Demos/` hoặc `Design/Concepts/`. Bản được duyệt chép vào `Design/Demos/SoftMiniature/approved/`.
- Giữ đúng layout và số liệu thật của game (xem mục Thiết kế và UI).

**Phần 2: Cắt sprite từ concept đã duyệt**
- Dùng MCP `art-tools` (`http://192.168.11.181:8790/mcp`): `remove_background` để tách nền, `outline` để thêm viền/bóng/glow, `upscale` để phóng to. Ảnh vào là `file_id` (POST `/upload`) hoặc base64, kết quả tải bằng `download_url`.
- Kiểm tra chất lượng từng sprite sau khi cắt (viền răng cưa, mờ, mất chi tiết, sai màu).
- Nếu chất lượng thấp, **sinh lại icon** bằng `gpt-image-2.6-flare`, `--quality low`, dùng sprite đã cắt hoặc crop concept làm `--ref`. Chỉ tăng lên `high` khi `low` vẫn không đạt và phải hỏi người dùng trước.

Công cụ sinh lại: `tools/gen_image.py NAME "prompt" [--size 1024x1024] [--quality low|high] [--ref a.png] [--opaque] [--out DIR]`. Mặc định nền trong suốt; `--ref` dùng endpoint edits để giữ thiết kế; `--opaque` cho cảnh nền đầy khung. Đổi model chỉ qua `OPENAI_IMAGE_MODEL` và phải hỏi người dùng.

Quy tắc chung:
- Key OpenAI đọc từ file ngoài repo (`OPENAI_KEY_FILE`, mặc định trong `~/.t3/userdata/secrets/files/`). Không đưa key vào repo, prompt hay log.
- Lưu ảnh thô và prompt vào `output/imagegen/<tên>/` (kèm `prompts.json`), ghi `provenance` trong `manifest.json` của asset pack (xem `assets/soft_miniature_ui_v1/manifest.json`).
- Sprite dùng trong game đặt ở `assets/soft_miniature_ui_v1/` (hoặc pack mới), kèm README bảng file/kích thước/mode.

## Việc đang dở

- `ui/shop_page.gd` vẫn dùng `shop_demo_skin.gd` (blue-white), chưa chuyển sang Soft Miniature. Có pack mới `Design/AssetPacks/Soft_Miniature_Shop_Horizontal_v1/` và `assets/shop_horizontal_v1/`.
- Font Noto cho th/ja/ko/zh_Hans chưa có trong `assets/fonts/`: bản web sẽ hiện ô vuông cho các ngôn ngữ này (xem `docs/i18n.md`).
- Ảnh có chữ in sẵn (asset IAP/UI) chưa có bản theo ngôn ngữ.
- `horus-game.json`: `appId` và `repo` còn trống, `languages` mới có `vi`.
- Chưa kiểm tra loading/splash trên thiết bị di động thật (xem `Design/09_Startup_Loading_Design.md`).
- Race UI v3 đang sửa dở (nhiều file đang thay đổi chưa commit): hỏi người dùng trước khi động vào `ui/race_view.gd`, `ui/race_world_3d.gd`. Chỉ popup Quà hằng ngày (`ui/daily_rewards_popup.gd`, nút ở dải chặng) bị gỡ; logic `game/daily_rewards.gd`, dữ liệu, key i18n `daily.*` và quà ngày cũ trong Shop (`claim_daily`) vẫn giữ.

## Setup và dựng UI

- UI dựng **bằng code GDScript**, không phải nhiều scene `.tscn`. `scenes/main.tscn` chỉ có một `Control` gắn `ui/main.gd`; các trang (`ui/*_page.gd`, popup) tự tạo node trong `_ready()`/`build_*`. Khi sửa UI, sửa code trong `ui/`, không tạo scene mới nếu không được yêu cầu. Khi làm UI từ concept/ảnh tham chiếu, gọi skill `godot-ui` để phân tích layout và lặp so sánh, nhưng phần "tạo scene tái dùng" của skill chỉ áp dụng khi người dùng yêu cầu; mặc định đưa kết quả vào code trong `ui/`.
- Kích thước: viewport 886x1920, stretch `canvas_items`, scale 2.2718, nên đơn vị logical là 390x845. Lề ngang 12, khoảng cách khối 6-8, vùng chạm tối thiểu 44x44. Chi tiết toạ độ và cây node: `Design/34_Layer_Layout_Spec.md`.
- Dùng container, anchor và size flags. Không đặt toạ độ tuyệt đối trừ khi layout đã chốt trong `Design/34_Layer_Layout_Spec.md`.
- Tài nguyên giao diện:
  - `ui/soft_miniature.gd` (`Soft`): màu, icon cut-out, panel; lấy texture theo id trong `assets/soft_miniature_ui_v1/manifest.json`.
  - `ui/hd_ui.gd` (`HdUi`): bảng màu và StyleBox 9-slice.
  - `ui/button_skin.gd`: nút bo tròn một mặt cho mọi palette.
  - Tái dùng những helper này trước khi tự vẽ StyleBox mới. Thiếu asset thì báo, không bịa.
- Nút, tab, chữ phải hiển thị tốt ở cả 8 ngôn ngữ (chữ Việt/Indonesia dài hơn, chữ Thái/CJK cao hơn). Bắt chữ tràn bằng `tests/league_redesign_preview_test.gd`.
- Kiểm tra bằng Godot MCP trước: `game_run` rồi `game_scene_tree`/`game_node_get` để xem cây node và kích thước thật, `game_screenshot` để chụp, `game_input` để bấm tab/nút, `game_stop` khi xong. `editor_screenshot` chỉ chụp editor. `game_run` không có tham số biến môi trường, nên không đặt được `XDG_DATA_HOME`. Luôn chạy với `args: ["--economy-test"]`: cờ này chuyển save sang `user://tests/economy_preview/` (đã kiểm ngày 18/11/2026: `save.json` thật không đổi). Chạy `game_run` không có cờ này sẽ ghi vào save thật. Các cờ như `--races=N`, `--gated`, `--tutorial-done` vẫn ghi vào save thật nếu không đi kèm `--economy-test`.
- Khi cần ảnh nhiều độ rộng cố định hoặc chạy headless: viết script test headless `root.get_texture().get_image().save_png(...)` ở các rộng 320, 390, 412 như `tests/ads_ticket_ui_test.gd`, lưu vào `Design/Previews/<tên>/`. Với ảnh chụp thật cửa sổ game, dùng `--screen 1`, `--audio-driver Dummy` và `XDG_DATA_HOME` tạm.
- Quy trình sửa UI theo concept:
  1. Đối chiếu concept đã duyệt (`Design/Demos/SoftMiniature/approved/`) và `Design/34_Layer_Layout_Spec.md`.
  2. Sprite thiếu thì làm theo mục "Tạo ảnh demo / asset", rồi thêm vào manifest của pack.
  3. Sửa code trong `ui/`, chạy `script_check`, rồi chạy test UI liên quan (`*_ui_test`).
  4. Chụp ở 320/390/412, so với concept, sửa lặp đến khi khớp.
  5. Thêm chuỗi mới qua i18n (xem Quy ước code).
