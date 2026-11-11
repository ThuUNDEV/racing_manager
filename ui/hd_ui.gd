class_name HdUi
extends RefCounted
## Bộ dựng UI cho gói asset `racing_ui_hd` (cartoon hiện đại: xanh UI, cam hành động, vàng thưởng, lá nhận).
## Mọi PNG gốc khá lớn (~300–700 px) nên được thu nhỏ một lần khi chạy rồi dùng làm StyleBoxTexture 9-slice
## (viền/bo góc giữ nguyên kích thước, phần giữa co giãn). Màn hình logic của dự án rộng ~390 đơn vị.

const ROOT := "res://assets/racing_ui_hd/"

# Bảng màu (chữ trên nền xanh nhạt phải đọc được; màu nhấn lấy từ art direction).
const C_NAVY := Color("16355c")
const C_TEXT := Color("16355c")
const C_MUTED := Color("5a7294")
const C_BLUE := Color("2f6fe0")
const C_ORANGE := Color("d96a00")
const C_GOLD := Color("b27300")
const C_GREEN := Color("15803d")
const C_RED := Color("c62828")
const C_PANEL := Color("e4efff")
const C_PANEL_HI := Color("cfe0fb")
const C_LINE := Color("9db9e3")
const C_OUTLINE := Color("0f2a52")

static var _tex_cache: Dictionary = {}
static var _box_cache: Dictionary = {}
static var _font: Font = null


## Texture gốc (đầy đủ độ phân giải).
static func tex(rel: String) -> Texture2D:
	return load(ROOT + rel) as Texture2D


## Texture thu nhỏ theo hệ số `f` (lọc Lanczos), có cache. Dùng cho 9-slice, nơi viền không được tự co.
static func scaled(rel: String, f: float) -> Texture2D:
	var key := "%s@%.3f" % [rel, f]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := tex(rel).get_image()
	if img.is_compressed():
		img.decompress()
	img.resize(maxi(1, roundi(img.get_width() * f)), maxi(1, roundi(img.get_height() * f)), Image.INTERPOLATE_LANCZOS)
	var t := ImageTexture.create_from_image(img)
	_tex_cache[key] = t
	return t


## StyleBoxTexture 9-slice từ ảnh thu nhỏ. `m` = viền cắt (trái, trên, phải, dưới) theo pixel đã thu nhỏ;
## `c` = lề nội dung cùng thứ tự.
static func box(rel: String, f: float, m: Vector4, c: Vector4, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var key := "%s@%.3f/%s/%s/%s" % [rel, f, m, c, tint]
	if _box_cache.has(key):
		return _box_cache[key]
	var sb := StyleBoxTexture.new()
	sb.texture = scaled(rel, f)
	sb.texture_margin_left = m.x
	sb.texture_margin_top = m.y
	sb.texture_margin_right = m.z
	sb.texture_margin_bottom = m.w
	sb.content_margin_left = c.x
	sb.content_margin_top = c.y
	sb.content_margin_right = c.z
	sb.content_margin_bottom = c.w
	sb.modulate_color = tint
	_box_cache[key] = sb
	return sb


## Panel xanh nhạt có viền xanh đậm và bóng đáy (thẻ, ô nâng cấp, khung nội dung).
static func panel(pad: float = 0.0) -> StyleBoxTexture:
	return box("surfaces/panel_body.png", 0.34, Vector4(15, 14, 15, 17), Vector4(11 + pad, 8 + pad, 11 + pad, 12 + pad))


## Biến thể panel bằng cách hoán kênh màu của chính asset (không cần ảnh mới):
## selected/pass = cam (đổi R<->B), reward = xanh lá (xoay G,B,R), locked = xám. Còn lại = xanh mặc định.
static func card_style(style_name: String) -> StyleBoxTexture:
	match style_name:
		"card_selected", "pass", "selected":
			return _variant("selected")
		"reward":
			return _variant("reward")
		"card_locked", "locked":
			return _variant("locked")
		"modal":
			return panel(6.0)
	return panel()


static func _variant(mode: String) -> StyleBoxTexture:
	var key := "variant/" + mode
	if _box_cache.has(key):
		return _box_cache[key]
	var base := panel()
	var img := (base.texture as Texture2D).get_image()
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			match mode:
				"selected":
					c = Color(c.b, c.g, c.r, c.a)
				"reward":
					c = Color(c.g, c.b, c.r, c.a)
				"locked":
					var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
					c = Color(lerpf(l, c.r, 0.15), lerpf(l, c.g, 0.15), lerpf(l, c.b, 0.2) + 0.02, c.a)
			img.set_pixel(x, y, c)
	var sb := base.duplicate() as StyleBoxTexture
	sb.texture = ImageTexture.create_from_image(img)
	_box_cache[key] = sb
	return sb


## Theme dùng chung cho thẻ/dialog của gói cũ (đã gồm font đậm, nút xanh, panel xanh); tạo một lần.
static var _theme: Theme = null
static func theme() -> Theme:
	if _theme == null:
		_theme = make_theme(load("res://assets/workshop_gp/theme.tres") as Theme)
	return _theme


## Thanh tài nguyên xanh đậm dạng viên thuốc (tiền, gem).
static func hud_bar() -> StyleBoxTexture:
	return box("surfaces/hud_bar.png", 0.26, Vector4(20, 20, 20, 20), Vector4(30, 4, 14, 6))


## Nút hành động. kind: upgrade (xanh), race (cam/vàng), claim (xanh lá), cancel (xám), nav (xanh nghiêng), menu (vuông xanh).
## state: normal | hover | pressed | disabled.
static func button(kind: String, state: String = "normal") -> StyleBoxTexture:
	# Nút bị khóa (hết tiền, chờ lưu...) luôn dùng nền xám thay vì làm mờ nền màu.
	var art := "cancel" if state == "disabled" and kind in ["upgrade", "race", "claim"] else kind
	var swap := kind == "menu_on"  # nút vuông cam = nút vuông xanh hoán kênh R<->B
	if swap:
		art = "menu"
	elif kind == "tab":
		art = "nav"
	elif kind == "tab_on":
		art = "race"
	var rel := "surfaces/button_%s.png" % art
	var f := 0.23
	var m := Vector4(22, 20, 22, 20)
	var c := Vector4(12, 4, 12, 7)
	match kind:
		"race", "nav":
			f = 0.2
			m = Vector4(24, 20, 24, 20)
			c = Vector4(14, 4, 14, 7)
		"tab", "tab_on":
			# Nút tứ giác nghiêng của thanh dưới: hai nắp trái/phải ôm trọn cạnh xiên, chiều cao đúng bằng ảnh
			# thu nhỏ (55 px) nên không có vùng giữa bị kéo dọc làm cạnh xiên gãy.
			f = 0.25
			m = Vector4(32, 27, 35, 28)
			c = Vector4(8, 4, 8, 4)
		"menu", "menu_on":
			f = 0.22
			m = Vector4(17, 17, 17, 17)
			c = Vector4(4, 3, 4, 5)
	var tint := Color.WHITE
	match state:
		"hover":
			tint = Color(1.08, 1.08, 1.08)
		"pressed":
			tint = Color(0.84, 0.84, 0.9)
			c.y += 2.0
			c.w -= 2.0
		"disabled":
			tint = Color(1, 1, 1, 0.95)
	if swap:
		return _swapped_box(rel, f, m, c, tint)
	return box(rel, f, m, c, tint)


static func _swapped_box(rel: String, f: float, m: Vector4, c: Vector4, tint: Color) -> StyleBoxTexture:
	var key := "swap/%s@%.3f/%s" % [rel, f, tint]
	if _box_cache.has(key):
		return _box_cache[key]
	var img := scaled(rel, f).get_image()
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(px.b, px.g, px.r, px.a))
	var sb := box(rel, f, m, c, tint).duplicate() as StyleBoxTexture
	sb.texture = ImageTexture.create_from_image(img)
	_box_cache[key] = sb
	return sb


## Thanh nhỏ trong ô (tiến độ): dùng lại hud_bar làm máng.
static func trough() -> StyleBoxTexture:
	return box("surfaces/hud_bar.png", 0.12, Vector4(10, 10, 10, 10), Vector4(0, 0, 0, 0))


## Font đậm (sans-serif) dựng từ font mặc định bằng variation, hỗ trợ đủ dấu tiếng Việt.
static func font() -> Font:
	if _font == null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.5
		_font = fv
	return _font


## Đặt kiểu cho một Button theo loại (dùng cho nút dựng bằng code).
static func style_button(b: Button, kind: String) -> void:
	for st: String in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, button(kind, st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var col := Color.WHITE if kind != "cancel" else C_NAVY
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, col)
	b.add_theme_color_override("font_disabled_color", Color("7a8aa6") if kind != "cancel" else Color("6b7a93"))
	b.add_theme_color_override("font_outline_color", C_OUTLINE if kind != "cancel" else Color(1, 1, 1, 0))
	b.add_theme_constant_override("outline_size", 3 if kind != "cancel" else 0)


## Theme toàn ứng dụng: lấy theme cũ làm nền (giữ các control chưa đổi) rồi thay Button/Panel/Label/CheckButton.
static func make_theme(base: Theme) -> Theme:
	var th: Theme = base.duplicate() as Theme if base != null else Theme.new()
	th.default_font = font()
	th.default_font_size = 14
	th.set_color("font_color", "Label", C_TEXT)
	th.set_stylebox("panel", "PanelContainer", panel())
	th.set_stylebox("panel", "Panel", panel())
	# Nút mặc định = xanh "upgrade"; nút chính (cam) và nút phụ (xám) gán riêng trong code.
	for st: String in ["normal", "hover", "pressed", "disabled"]:
		th.set_stylebox(st, "Button", button("upgrade", st))
		th.set_stylebox(st, "CheckButton", StyleBoxEmpty.new())
		th.set_stylebox(st, "CheckBox", StyleBoxEmpty.new())
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(k, "Button", Color.WHITE)
		th.set_color(k, "CheckButton", C_TEXT)
		th.set_color(k, "CheckBox", C_TEXT)
	th.set_color("font_disabled_color", "Button", Color("8fa0bd"))
	th.set_icon("checked", "CheckButton", scaled("controls/toggle_on.png", 0.2))
	th.set_icon("unchecked", "CheckButton", scaled("controls/toggle_off.png", 0.2))
	th.set_icon("checked_disabled", "CheckButton", scaled("controls/toggle_on.png", 0.2))
	th.set_icon("unchecked_disabled", "CheckButton", scaled("controls/toggle_off.png", 0.2))
	th.set_icon("checked", "CheckBox", scaled("controls/checkbox_on.png", 0.12))
	th.set_icon("unchecked", "CheckBox", scaled("controls/checkbox_off.png", 0.12))
	return th


## TextureRect giữ tỉ lệ từ ảnh gốc của gói (dùng trong HBox/VBox).
static func icon(rel: String, extent: Vector2 = Vector2(32, 32)) -> TextureRect:
	var t := TextureRect.new()
	# PNG gốc không có mipmap: thu nhỏ trước (~2x kích thước hiển thị, vì màn hình thật là 2,27x) để khỏi răng cưa.
	var src := tex(rel)
	var f := minf(1.0, 2.4 * maxf(extent.x, extent.y) / float(maxi(src.get_width(), src.get_height())))
	f = roundf(f * 40.0) / 40.0  # gom hệ số để dùng chung cache giữa các nơi
	t.texture = scaled(rel, f) if f < 1.0 else src
	t.custom_minimum_size = extent
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t
