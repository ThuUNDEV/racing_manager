---
name: setup-ui-from-demo
description: "Dựng hoặc sửa một màn hình/popup trong Racing Manager cho giống ảnh demo/concept. Dùng khi người dùng đưa ảnh demo và nói 'setup giống demo', 'làm UI theo ảnh này', 'sửa cho khớp concept'. Lập bảng đối chiếu từng phần và chờ duyệt trước khi code, không thay asset gần giống, so ảnh và sửa lặp đến khi khớp."
---

# Setup UI theo demo

Mục tiêu: màn hình trong game nhìn giống demo, nhưng vẫn dùng dữ liệu thật và tương tác thật của game.

Lỗi hay gặp nhất, cần tránh:
- Dùng lại helper của màn khác (header pack, nút CTA, ribbon card) nên mang theo giao diện của màn đó.
- Thiếu asset thì lặng lẽ dùng icon "gần giống".
- Dựng xong không so lại với demo.
- Demo vẽ một thứ mà game không có (ví dụ xe vẽ tay khác với model 3D).

## Bước 1: Chốt đầu vào

Cần đủ 4 thứ, thiếu thì hỏi người dùng:
1. Ảnh demo chuẩn (đường dẫn). Nhiều bản thì hỏi bản nào.
2. Màn/popup cần làm và trạng thái (sản phẩm nào, tab nào, ngôn ngữ vi).
3. File code dựng màn đó trong `ui/` (tìm bằng grep tên node hoặc khóa i18n).
4. Demo quyết định những gì: chỉ phong cách, hay cả bố cục. Nếu người dùng không nói, mặc định demo quyết định cả bố cục lẫn hình ảnh của màn đó, nhưng **không** đổi giá, phần thưởng, số liệu hay luồng game.

Mở ảnh demo và xem thật (Read ảnh), không chỉ đọc tên file hay prompt. Đọc file code, `Design/34_Layer_Layout_Spec.md` phần liên quan, `CLAUDE.md`. Ghi chú `git status` của các file sẽ sửa để không ghi đè việc đang dở.

## Bước 2: Chụp hiện trạng

- Tìm script chụp sẵn có cho màn đó: `grep -l "<tên màn>" tests/*capture*.gd tests/*preview*.gd tests/*ui_test.gd tools/capture_all_screens.gd`. Ảnh cũ trong `Design/Previews/` chỉ dùng tham khảo, luôn chụp lại.
- Không có thì viết `tests/<ten>_capture.gd` theo mẫu `tests/ads_ticket_ui_test.gd` (lưu `root.get_texture().get_image()` ở rộng 320/390/412).
- Chạy an toàn theo CLAUDE.md: `XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy -s res://tests/<ten>_capture.gd`. Ảnh lưu ở `Design/Previews/<ten>/`.
- Ghép so sánh:
  `python3 tools/compare_ui.py <demo.png> Design/Previews/<ten>/<anh_390>.png Design/Previews/<ten>/compare_before.png --width 390 [--crop x,y,w,h]`
  Dùng `--crop` khi demo chỉ có popup còn ảnh game có cả màn phía sau. Lưới có số toạ độ logical.

## Bước 3: Bảng đối chiếu (bắt buộc, chờ duyệt)

Chia demo thành từng phần từ trên xuống (khung, header, nút đóng, ảnh chính, nhãn, tiêu đề, chip, ô lợi ích, nút mua, nút phụ...). Ghi vào `Design/Previews/<ten>/plan.md`:

| # | Phần | Demo | Game hiện tại | Cách làm | Ghi chú |
|---|---|---|---|---|---|
| 1 | Header | Thanh xanh rộng đè mép trên, icon quà trái, nút X ở đầu phải | Ribbon nhỏ trong panel | CODE + ASSET MỚI `header_gift` | Không dùng `PromoUi.header_space` vì khác demo |

Cột "Cách làm" chỉ được chọn một trong:
- **CODE**: vẽ bằng StyleBox/container. Ghi màu hex lấy từ demo, bo góc, viền, kích thước logical.
- **ASSET CÓ SẴN `<id>`**: chỉ khi asset đó giống demo thật sự (mở ảnh asset ra xem). Ghi id trong manifest.
- **ASSET MỚI `<tên>`**: chưa có asset đúng. Sẽ cắt từ demo theo quy trình trong CLAUDE.md.
- **GIỮ NHƯ GAME**: có lý do (dữ liệu thật khác chữ trong ảnh, định dạng giá theo locale, vùng chạm 44x44, model 3D...). Ghi lý do.

Quy tắc khi lập bảng:
- Đo từ ảnh demo đã scale về rộng 390: vị trí, cao, lề, cỡ chữ ước lượng, màu (lấy mẫu pixel bằng PIL).
- Helper dùng chung (`Soft`, `HdUi`, `button_skin`, `BenefitUi`, `PromoUi`, `EpicCard`) chỉ dùng khi kết quả của nó giống phần đó trong demo. Nếu khác, viết style riêng trong file của màn này. Không sửa helper dùng chung vì sẽ đổi các màn khác, trừ khi người dùng đồng ý.
- Phần mà game dựng khác bản chất (model 3D vs ảnh vẽ, cảnh nền khác) thì ghi rõ thành một quyết định cho người dùng, kèm lựa chọn (làm model mới, sprite 2D riêng cho màn này, chấp nhận khác).

**Dừng lại**: gửi bảng cho người dùng (tóm tắt trong chat + ảnh compare_before), hỏi duyệt. Chỉ code sau khi được duyệt. Người dùng sửa dòng nào thì cập nhật plan.md.

## Bước 4: Asset

Với mỗi dòng ASSET MỚI, theo mục "Tạo ảnh demo / asset" trong CLAUDE.md:
1. Crop vùng đó từ demo gốc (độ phân giải đầy đủ) vào `output/imagegen/<ten>/`.
2. `art-tools` `remove_background`, rồi mở ảnh kiểm tra viền, độ nét, màu.
3. Kém thì sinh lại bằng `tools/gen_image.py <ten> "<prompt>" --quality low --ref <crop>`.
4. Đặt vào pack (`assets/soft_miniature_ui_v1/` hoặc pack riêng), thêm vào `manifest.json` có `provenance`.

Mẫu đầy đủ: `tools/build_epic_popup_assets.py` (cắt sân khấu đục có viền hoà màu thẻ, cutout tách nền, và 9-slice ngang lấy từ hộp trong demo: nắp trái + một cột sạch + nắp phải, che phần chữ/icon). 9-slice vẽ bằng `draw_texture_rect_region` theo tỷ lệ chiều cao để giữ độ nét (xem `EpicDetail.draw_slice`); `StyleBoxTexture` vẽ texture 1:1 nên ảnh 2x sẽ to gấp đôi.

Không bỏ chữ in sẵn vào sprite; chữ luôn là Label qua `I18n.t`. Nếu không làm được asset, báo người dùng và ghi rõ dòng đó còn thiếu, không thay bằng icon khác.

## Bước 5: Dựng

Sửa code trong `ui/` (không tạo `.tscn` mới). Thứ tự:
1. Khung và bố cục: container, separation, padding, chiều cao từng khối theo bảng.
2. Ảnh/asset: kích thước theo demo, giữ tỷ lệ (`STRETCH_KEEP_ASPECT_CENTERED`).
3. Chữ: cỡ, màu, đậm, căn lề. Chuỗi mới thêm vào `en.json` + `vi.json` rồi `python -X utf8 tools/i18n_check.py`.
4. Nút và trạng thái: vùng chạm tối thiểu 44x44, nối tín hiệu cũ giữ nguyên.

Sau mỗi lần sửa: `script_check` (Godot MCP) cho file vừa sửa.

Bẫy đã gặp:
- Texture chỉ dùng trong `draw_*` phải được giữ tham chiếu (cache trong biến static). Nếu chỉ `load()` rồi vẽ, texture bị giải phóng ngay và hiện ô trắng.
- Popup căn giữa màn nên khi đổi chiều cao thì cả popup dịch lên xuống. Cho script chụp in toạ độ node (`get_global_rect()`), rồi so từng khối theo khoảng cách tới đỉnh popup thay vì toạ độ tuyệt đối.
- Font game (Nunito) cao dòng hơn chữ trong ảnh AI: đặt Label trong ô cao cố định, chữ tràn đều trên dưới, để khoảng cách khối khớp demo.
- Màn rộng hơn chuẩn: nếu khung bị giới hạn bề rộng, giới hạn luôn scale chữ (≤ 1.0), nếu không chữ to ra trong khung cũ và xuống dòng thêm.

## Bước 6: Đo điểm giống, so và sửa lặp

**Mục tiêu mặc định: điểm giống ≥ 90%** (người dùng có thể đặt mức khác).

Đo bằng `tools/ui_similarity.py`:
```
python3 tools/ui_similarity.py <demo.png> <anh_game_390.png> Design/Previews/<ten>/score_<n> \
  --demo-crop x,y,w,h --game-crop x,y,w,h
```
- Crop hai ảnh đúng cùng một vùng (ví dụ mép ngoài popup, từ đỉnh header đến đáy panel), toạ độ logical ở rộng 390. Ghi hai crop vào `plan.md` và **giữ nguyên crop cho mọi lần đo**, không đổi crop để tăng điểm. Popup căn giữa thì neo crop game theo đỉnh node đầu tiên (ví dụ `EpicHeader` y từ dump `RECT`), giữ nguyên kích thước crop. Script cảnh báo nếu hai crop khác tỷ lệ quá 3%.
- Điểm = trung bình từng ô 24 px của màu (đã làm mờ) và đường nét (vị trí và lượng cạnh), mỗi ô được phép lệch 4 px. Ra `score_<n>_heatmap.png` (ô đỏ = khác) và `score_<n>_score.json` (các ô tệ nhất).
- Hiệu chỉnh (popup Epic, 27/11/2026): chính demo dịch 3 px = 95%, dịch 6 px = 92%, dịch 12 px = 79%; popup khác hẳn = 40-52%. Nên 90% nghĩa là mọi phần đúng chỗ trong khoảng 6 px và đúng màu.

Vòng lặp:
1. Đo `score_before` trước khi sửa, ghi vào `plan.md`.
2. Sau mỗi lượt sửa: chụp lại (bước 2), đo `score_<n>`, mở heatmap ra xem.
3. Sửa các vùng đỏ nhất trước (theo `worst_cells`), đối chiếu với dòng tương ứng trong bảng. Lệch lớn (bố cục, asset) trước, chi tiết (chữ, màu, bóng) sau.
4. Đánh dấu từng dòng bảng: KHỚP / CÒN LỆCH (lệch gì, toạ độ theo lưới) / CHƯA LÀM.
5. Dừng khi ≥ 90% **và** không dòng nào còn lệch rõ bằng mắt. Tối đa 5 vòng; hết vòng mà chưa đạt thì báo điểm hiện tại, các vùng đỏ còn lại và lý do (thường là asset còn thiếu hoặc dòng GIỮ NHƯ GAME).

Điểm chỉ là thước đo hỗ trợ, không thay mắt nhìn: điểm cao mà chữ sai, icon sai vẫn là chưa đạt. Dòng GIỮ NHƯ GAME (ví dụ model 3D khác ảnh vẽ) làm điểm thấp ở vùng đó; nếu vì vậy không thể đạt 90%, nói ngay từ bước 3 để người dùng quyết.

Không chỉnh ảnh chụp game, không crop che phần lệch, không đổi tham số script để tăng điểm.

## Bước 7: Kiểm tra cuối

- Chụp 320/390/412: không tràn, không cắt chữ.
- Chữ dài: chạy `tests/league_redesign_preview_test.gd` hoặc chụp thêm ngôn ngữ `id` và `ja` (`RM_LANG=id`).
- Chạy test UI liên quan đến màn đó (chỉ test liên quan, không chạy cả bộ nếu chưa hỏi).
- Kiểm tra log có `SCRIPT ERROR|Parse Error` (Godot thoát mã 0 kể cả khi lỗi).

## Báo cáo

- Điểm giống trước và sau (ví dụ 66,5% → 91,2%), kèm heatmap cuối.
- Ảnh `compare_before.png` và `compare_after_<n>.png` cuối cùng.
- Bảng đối chiếu với trạng thái từng dòng.
- Asset mới đã thêm, file đã sửa, test đã chạy.
- Phần còn lệch và quyết định đang chờ người dùng. Không nói "đã giống demo" nếu bảng còn dòng chưa khớp.
