# Daily Gift asset kit v3

Bộ asset để setup popup Daily Gift theo concept soft miniature. Chưa thay popup hoặc logic thưởng của game hiện tại.

## Nội dung

- **32 asset khác nhau**: 16 skin gốc + 6 trạng thái bổ sung cho nút nhận/nút đóng + 10 icon (4 loại coupon, gem, gift, grand gift, đội đua, túi gear, tick trắng).
- `skins/`: 22 PNG nguồn HD, đã upscale bằng MCP art-tools.
- `icons/`: 9 icon thưởng HD, cạnh dài 638–802 px; tick trắng 132×112 px. Mỗi loại thưởng dùng một icon chung cho mọi vị trí, không lặp ảnh theo ngày.
- `runtime/`: 22 bản skin theo kích thước logic để lề StyleBoxTexture giữ đúng độ cong ở màn nhỏ. Đây là bản density khác của skin, không tính là asset mới.
- `styles/`: 16 StyleBoxTexture có lề 9-slice đã điều chỉnh trên render Godot.
- `themes/claim_button.tres`: normal, hover, pressed, hover_pressed, disabled.
- `daily_gift_assets.gd`: adapter lấy icon đúng loại, thiết lập nút nhận/nút đóng và định dạng đếm ngược.
- `manifest.json`: đường dẫn, kích thước HD/runtime, lề 9-slice, nguồn và mapping coupon.

## Coupon

Theo concept demo, popup dùng chung icon cho mọi hạng; hạng vé hiển thị bằng chữ I18n (`1 vé All-Star`, `1 vé Elite`...).

| Reward kind / tier | PNG dùng trong popup |
|---|---|
| driver / pro | `coupon_driver_pro.png` (tem xanh bạc, mũ bảo hiểm) |
| driver / allstar | `coupon_driver_allstar.png` (tem tím vàng, mũ bảo hiểm) |
| gear / standard | `coupon_gear_standard.png` (tem xanh bạc, bánh răng cờ lê) |
| gear / elite | `coupon_gear_elite.png` (tem tím vàng, bánh răng cờ lê) |

`drivers.png` và `gear_bag.png` không còn dùng cho vé (giữ làm art dự phòng). Ô Ngày 7 dùng `gift.png` kèm `glow_soft.png`; `checker_flag.png` là họa tiết cờ caro ở header và góc ô Ngày 7.

## Dùng trong Godot

Giữ thư mục tại `res://assets/daily_gift_v3/`; các resource tham chiếu đường dẫn này. Chọn `styles/*.tres` cho theme override của Panel/PanelContainer. Icon dùng TextureRect, Expand Mode = Ignore Size, Stretch Mode = Keep Aspect Centered.

```gdscript
const DailyGiftArt = preload("res://assets/daily_gift_v3/daily_gift_assets.gd")

DailyGiftArt.setup_claim_button(claim_button)
DailyGiftArt.set_claim_state(claim_button, can_claim, seconds_left)
DailyGiftArt.setup_close_button(close_button)
pro_icon.texture = DailyGiftArt.reward_texture("driver", "pro")
```

Mỗi giây, caller truyền `seconds_left` mới vào `set_claim_state`. Khi đã nhận, nút disabled và hiển thị `Mở lại sau HH:MM:SS`; chỉ trạng thái hợp lệ từ game mới bật lại nút. Adapter không tự cộng thưởng, lưu game hay quyết định lịch reset.

Chữ/số không gắn vào art. Khi tích hợp, thay text của adapter bằng I18n hiện có nếu cần các ngôn ngữ khác. Touch target nút nhận/đóng tối thiểu 48px. Các mốc hỗn hợp và các vòng grand dùng lại icon gem/coupon theo dữ liệu, không cần sprite riêng cho từng số lượng.

Đối với 9-slice, margin trong manifest/style là **pixel của ảnh runtime**, không phải pixel HD. Bản runtime của badge cao 16px, pill cao 20px, progress cao 8px; nếu cần hiển thị lớn hơn nhiều hãy tạo thêm density từ nguồn HD và hiệu chỉnh lề tương ứng.

## Kiểm tra đã thực hiện

Godot 4.7.2, OpenGL compatibility; fixture riêng, không dùng save/autoload game chính:

- 320×568, 390×778, 412×915.
- Load 32 asset, kiểm tra đường dẫn resource và PNG alpha.
- Bounds, độ rộng chữ, dòng thưởng không đè badge, vùng bấm 48px.
- Input hover/pressed/nhận; nút nhận disabled và hiển thị countdown; disabled chặn nhận lần nữa.
- Countdown 0, giá trị âm và 24h; mapping 4 coupon.

Kết quả chi tiết, ảnh render 12 trường hợp và script kiểm tra nằm trong `output/imagegen/daily_gift/setup_v3/validation/`. Đây là QA bộ art/adapter, không thay thế kiểm thử popup khi tích hợp vào gameplay hoặc trên điện thoại thật.

## Nguồn

Khung trống được ImageGen tái tạo từ concept; icon vé và art HD mới cũng dùng ImageGen với concept làm tham chiếu. MCP art-tools `remove_background(refine=true)` tách nền và `upscale` nâng độ phân giải; alpha được làm sạch và cắt lề. Màu hover/pressed/disabled được biến đổi xác định từ skin gốc. Prompt được lưu trong thư mục output setup_v3.
