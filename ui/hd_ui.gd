class_name HdUi
extends RefCounted
const CleanArt = preload("res://ui/clean_modern_art.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
## F Clean Modern: nền trắng xanh, nhận diện xanh dương, nút mua/nâng cấp xanh lá.
## Mọi PNG gốc khá lớn (~300–700 px) nên được thu nhỏ một lần khi chạy rồi dùng làm StyleBoxTexture 9-slice
## (viền/bo góc giữ nguyên kích thước, phần giữa co giãn). Màn hình logic của dự án rộng ~390 đơn vị.

const ROOT := "res://assets/racing_ui_hd/"

# Bảng màu (chữ trên nền xanh nhạt phải đọc được; màu nhấn lấy từ art direction).
const C_NAVY := Color("23394a")
const C_TEXT := Color("23394a")
const C_MUTED := Color("768ca0")
const C_BLUE := Color("087ee6")
const C_ORANGE := Color("087ee6")
const C_GOLD := Color("b27300")
const C_GREEN := Color("358a12")
const C_RED := Color("c62828")
const C_PANEL := Color("ffffff")
const C_PANEL_HI := Color("e6f2fc")
const C_LINE := Color("adc9de")
const C_OUTLINE := Color("23394a")

static var _tex_cache: Dictionary = {}
static var _box_cache: Dictionary = {}
static var _font: Font = null

## Shared close control uses the same rounded face as the action buttons.
static func close_button(action: Callable, node_name: String = "PopupClose") -> Button:
	var button := Button.new()
	button.name = node_name
	button.accessibility_name = I18n.t("common.close")
	button.custom_minimum_size = Vector2(48, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = "×"
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := ButtonSkin.palette(Color("ff6655"), Color("e82922"), Color("a81713"))
		skin.set_content_margin_all(0)
		if state == "hover":
			skin.modulate_color = Color(1.0, 0.92, 0.88)
		elif state == "pressed":
			skin.modulate_color = Color(0.8, 0.8, 0.8)
		elif state == "disabled":
			skin.modulate_color = Color(0.65, 0.65, 0.65, 0.65)
		button.add_theme_stylebox_override(state, skin)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = C_BLUE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(24)
	button.add_theme_stylebox_override("focus", focus)
	ButtonSkin.apply(button)
	button.pressed.connect(action)
	return button


static func close_header(title: String, action: Callable, font_size: int = 18) -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "PopupHeader"
	header.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", C_TEXT)
	header.add_child(label)
	header.add_child(close_button(action))
	return header


## Texture gốc (đầy đủ độ phân giải).
static func tex(rel: String) -> Texture2D:
	return CleanArt.asset(ROOT + rel) as Texture2D


## Texture thu nhỏ theo hệ số `f` (lọc Lanczos), có cache. Dùng cho 9-slice, nơi viền không được tự co.
static func scaled(rel: String, f: float) -> Texture2D:
	var key := "%s@%.3f" % [rel, f]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := tex(rel).get_image()
	if img.is_compressed():
		img.decompress()
	# Skins retain their logical size and nine-slice caps despite new atlas dimensions.
	var dimensions := Vector2i(img.get_width(), img.get_height())
	if rel.begins_with("surfaces/"):
		dimensions = CleanArt.source_size(ROOT + rel, dimensions)
		if rel.begins_with("surfaces/button_"):
			# Preserve the new skin's aspect ratio. Only its logical height comes
			# from the old asset; stretching it to the old width deforms the caps.
			dimensions.x = roundi(float(img.get_width()) * dimensions.y / img.get_height())
	img.resize(maxi(1, roundi(dimensions.x * f)), maxi(1, roundi(dimensions.y * f)), Image.INTERPOLATE_LANCZOS)
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


## Compact rows need a smaller source, not cuts through the full-size panel's corners.
static func coupon() -> StyleBoxTexture:
	return box("surfaces/panel_body.png", 0.20, Vector4(9, 9, 9, 10), Vector4(6, 3, 6, 5))


static func pack_header(hue: float) -> StyleBoxTexture:
	var key := "pack_header/%.2f" % hue
	if _box_cache.has(key):
		return _box_cache[key]
	# Leave a real center strip between the top and bottom slices (source height = 40).
	var skin := box("surfaces/button_amber.png", 0.055, Vector4(21, 18, 21, 20), Vector4(5, 3, 4, 5)).duplicate() as StyleBoxTexture
	# Keep the generated cream/gold header; item rarity is conveyed by its own icon.
	_box_cache[key] = skin
	return skin


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
	var sb := panel().duplicate() as StyleBoxTexture
	match mode:
		"selected": sb.modulate_color = Color("d8edff")
		"reward": sb.modulate_color = Color("efffe4")
		"locked": sb.modulate_color = Color("dce3eb")
	_box_cache[key] = sb
	return sb


## Theme dùng chung cho thẻ/dialog của gói cũ (đã gồm font đậm, nút xanh, panel xanh); tạo một lần.
static var _theme: Theme = null
static func theme() -> Theme:
	if _theme == null:
		_theme = make_theme(CleanArt.asset("res://assets/workshop_gp/theme.tres") as Theme)
	return _theme


## Thanh tài nguyên xanh đậm dạng viên thuốc (tiền, gem).
static func hud_bar() -> StyleBoxTexture:
	return box("surfaces/hud_bar.png", 0.26, Vector4(20, 20, 20, 20), Vector4(30, 4, 14, 6))


## Nút hành động. kind: upgrade (xanh), amber (nâng cấp hổ phách), race (cam/vàng), claim (xanh lá), cancel (xám), nav (xanh nghiêng), menu (vuông xanh).
## state: normal | hover | pressed | disabled.
static func button(kind: String, state: String = "normal") -> StyleBoxTexture:
	if kind == "race" and state != "disabled":
		var raised := StyleBoxTexture.new()
		raised.texture = load("res://assets/clean_modern/icons/button_raised_blue.svg")
		raised.texture_margin_left = 14
		raised.texture_margin_right = 14
		raised.texture_margin_top = 14
		raised.texture_margin_bottom = 14
		raised.content_margin_left = 10
		raised.content_margin_right = 10
		raised.content_margin_top = 3 if state == "pressed" else 1
		raised.content_margin_bottom = 3 if state == "pressed" else 5
		raised.modulate_color = Color(0.84, 0.9, 1.0) if state == "pressed" else Color(1.08, 1.08, 1.08) if state == "hover" else Color.WHITE
		return ButtonSkin.rounded(raised) as StyleBoxTexture
	# Nút bị khóa (hết tiền, chờ lưu...) luôn dùng nền xám thay vì làm mờ nền màu.
	var art := "cancel" if state == "disabled" and kind in ["upgrade", "amber", "race", "claim"] else kind
	var swap := false
	if kind in ["menu_on", "tab_on"]:
		art = "menu"
	if swap:
		art = "menu"
	elif kind == "tab":
		art = "nav"
	elif kind == "tab_on":
		art = "menu"
	elif kind == "info":
		art = "menu"
	var rel := "surfaces/button_%s.png" % art
	var f := 0.23
	var m := Vector4(22, 20, 22, 20)
	var c := Vector4(12, 4, 12, 7)
	match kind:
		"info":
			# The 28px info button must not squeeze the large menu skin's center into a sliver.
			f = 0.10
			m = Vector4(13, 11, 13, 12)
			c = Vector4(3, 2, 3, 3)
		"amber":
			# Asset hổ phách 2172x724: thu nhỏ về chiều cao nút, giữ trọn bo góc ở hai nắp.
			if art == "amber":
				f = 0.08
				m = Vector4(20, 20, 20, 20)
		"race", "nav":
			f = 0.2
			m = Vector4(33, 18, 33, 18)
			c = Vector4(14, 4, 14, 7)
		"tab_on":
			# A narrow navigation tab needs a square skin, not a compressed wide pill.
			f = 0.23
			m = Vector4(14, 14, 14, 14)
			c = Vector4(4, 4, 4, 4)
		"tab":
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
		return ButtonSkin.rounded(_swapped_box(rel, f, m, c, tint)) as StyleBoxTexture
	return ButtonSkin.rounded(box(rel, f, m, c, tint)) as StyleBoxTexture


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


## Bundled typography: real bold outlines and Vietnamese glyphs, independent of OS fonts.
static func font() -> Font:
	if _font == null:
		_font = preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf")
	return _font


## Small contrasting outlines and an offset shadow keep text readable over artwork.
static func text_depth(node: Control, light_text: bool = false) -> void:
	node.add_theme_color_override("font_outline_color", Color("173b59dd") if light_text else Color("ffffffd9"))
	node.add_theme_constant_override("outline_size", 2 if light_text else 1)
	node.add_theme_color_override("font_shadow_color", Color("102e5480") if light_text else Color("203e5733"))
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 1)


## Đặt kiểu cho một Button theo loại (dùng cho nút dựng bằng code).
static func style_button(b: Button, kind: String) -> void:
	if kind == "cancel":
		for state in ["normal", "hover", "pressed", "disabled"]:
			var skin := StyleBoxFlat.new()
			skin.bg_color = Color("e8f3fd") if state != "pressed" else Color("cfe6fa")
			skin.border_color = Color("adc9de")
			skin.set_border_width_all(1)
			skin.set_corner_radius_all(18)
			skin.content_margin_left = 10
			skin.content_margin_right = 10
			skin.shadow_color = Color("82a3bd66")
			skin.shadow_size = 2
			skin.shadow_offset = Vector2(0, 2)
			b.add_theme_stylebox_override(state, skin)
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(color, C_TEXT)
		text_depth(b)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		ButtonSkin.apply(b)
		return
	for st: String in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new() if kind == "tab" else button(kind, st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var col := C_TEXT if kind in ["cancel", "tab", "nav", "amber"] else Color.WHITE
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, col)
	b.add_theme_color_override("font_disabled_color", Color("7a8aa6") if kind != "cancel" else Color("6b7a93"))
	b.add_theme_color_override("font_outline_color", C_OUTLINE if kind != "cancel" else Color(1, 1, 1, 0))
	text_depth(b, col == Color.WHITE)
	ButtonSkin.apply(b)


## Theme toàn ứng dụng: lấy theme cũ làm nền (giữ các control chưa đổi) rồi thay Button/Panel/Label/CheckButton.
static func make_theme(base: Theme) -> Theme:
	var th: Theme = base.duplicate() as Theme if base != null else Theme.new()
	th.default_font = font()
	th.default_font_size = 14
	th.set_color("font_color", "Label", C_TEXT)
	th.set_color("font_outline_color", "Label", Color("ffffffd9"))
	th.set_constant("outline_size", "Label", 1)
	th.set_color("font_shadow_color", "Label", Color("203e5733"))
	th.set_constant("shadow_offset_x", "Label", 0)
	th.set_constant("shadow_offset_y", "Label", 1)
	th.set_color("font_outline_color", "Button", Color("173b59dd"))
	th.set_constant("outline_size", "Button", 2)
	th.set_color("font_shadow_color", "Button", Color("102e5480"))
	th.set_constant("shadow_offset_x", "Button", 0)
	th.set_constant("shadow_offset_y", "Button", 1)
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
