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

- Xem/chụp game: `--screen 1` (màn hình phụ) và `--audio-driver Dummy` (tắt tiếng). Script dump/layout dùng `--headless`.
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
- Nếu chất lượng thấp, **sinh lại icon** bằng `gpt-image-2.5-flare`, `--quality low`, dùng sprite đã cắt hoặc crop concept làm `--ref`. Chỉ tăng lên `high` khi `low` vẫn không đạt và phải hỏi người dùng trước.

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
- Daily Gift v3 và Race UI v3 đang sửa dở (nhiều file đang thay đổi chưa commit): hỏi người dùng trước khi động vào `ui/daily_rewards_popup.gd`, `ui/race_view.gd`, `ui/race_world_3d.gd`.
