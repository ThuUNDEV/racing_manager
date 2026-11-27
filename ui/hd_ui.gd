class_name HdUi
extends RefCounted
const CleanArt = preload("res://ui/clean_modern_art.gd")
const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
## Soft Miniature: approved clay cutouts, warm ivory panels and orange actions.
## Mọi PNG gốc khá lớn (~300–700 px) nên được thu nhỏ một lần khi chạy rồi dùng làm StyleBoxTexture 9-slice
## (viền/bo góc giữ nguyên kích thước, phần giữa co giãn). Màn hình logic của dự án rộng ~390 đơn vị.

const ROOT := "res://assets/racing_ui_hd/"

# Bảng màu (chữ trên nền xanh nhạt phải đọc được; màu nhấn lấy từ art direction).
const C_NAVY := Color("0e2b5c")
const C_TEXT := Color("0e2b5c")
const C_MUTED := Color("5f7391")
const C_BLUE := Color("62b8e5")
const C_ORANGE := Color("ff913f")
const C_GOLD := Color("aa762a")
const C_GREEN := Color("31835d")
const C_RED := Color("c85555")
const C_PANEL := Color("fffdf7")
const C_PANEL_HI := Color("ecf7fa")
const C_LINE := Color("d8e2df")
const C_OUTLINE := Color("0e2b5c")

static var _tex_cache: Dictionary = {}
static var _box_cache: Dictionary = {}
static var _font: Font = null

## Dedicated square artwork includes the X so its alignment never depends on fonts or theme padding.
static func close_button(action: Callable, node_name: String = "PopupClose", visual_scale: float = 1.0) -> Button:
	var button := Button.new()
	button.name = node_name
	button.accessibility_name = I18n.t("common.close")
	button.custom_minimum_size = Vector2(48, 48) * visual_scale
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var skin := StyleBoxTexture.new()
		skin.texture = preload("res://assets/racing_ui_hd/icons/popup_close_x.svg")
		skin.set_content_margin_all(0)
		# Preserve this dedicated artwork when generic button styling runs.
		skin.set_meta("rounded_button", true)
		if state == "hover":
			skin.modulate_color = Color(1.0, 0.94, 0.94)
		elif state in ["pressed", "hover_pressed"]:
			skin.modulate_color = Color(0.85, 0.85, 0.85)
		elif state == "disabled":
			skin.modulate_color = Color(0.65, 0.65, 0.65, 0.65)
		button.add_theme_stylebox_override(state, skin)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = C_BLUE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(roundi(16 * visual_scale))
	button.add_theme_stylebox_override("focus", focus)
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


## Thu cỡ chữ của nhãn một dòng (clip_text) cho vừa bề rộng hiện có, không nhỏ hơn `smallest`.
static func fit_font(label: Label, largest: int, smallest: int) -> void:
	var font := label.get_theme_font("font")
	var wanted := largest
	while wanted > smallest and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, wanted).x > label.size.x:
		wanted -= 1
	label.add_theme_font_size_override("font_size", wanted)


## Texture gốc (đầy đủ độ phân giải).
static func tex(rel: String) -> Texture2D:
	var aliases := {"cash": "cash", "coins": "coins", "gem": "gem", "energy": "engine", "gear": "settings", "crane": "chassis", "research": "gearbox", "gift": "gift", "flag": "flag", "tools": "bag", "staff": "team", "trophy": "trophy", "crown": "trophy", "shop": "shop", "garage": "garage", "avatar": "avatar", "seats": "ticket", "car_red": "car_showroom"}
	if rel.begins_with("icons/"):
		var clay := Soft.icon(aliases.get(rel.get_file().get_basename(), ""))
		if clay != null: return clay
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
	return Soft.surface("panel", Vector4(10 + pad, 8 + pad, 10 + pad, 10 + pad)) as StyleBoxTexture


## Compact rows need a smaller source, not cuts through the full-size panel's corners.
static func coupon() -> StyleBoxTexture:
	return Soft.surface("panel", Vector4(6, 3, 6, 5)) as StyleBoxTexture


static func pack_header(_hue: float) -> StyleBox:
	return Soft.surface("section", Vector4(6, 3, 6, 5))


## Biến thể panel bằng cách hoán kênh màu của chính asset (không cần ảnh mới):
## selected/pass = cam (đổi R<->B), reward = xanh lá (xoay G,B,R), locked = xám. Còn lại = xanh mặc định.
static func card_style(style_name: String) -> StyleBoxTexture:
	match style_name:
		"card_selected", "pass", "selected":
			return _variant("selected")
		"reward":
			return _variant("reward")
		"card_locked", "locked":
			return Soft.surface("inventory") as StyleBoxTexture
		"modal":
			return panel(6.0)
	return panel()


static func _variant(mode: String) -> StyleBoxTexture:
	return Soft.surface(mode) as StyleBoxTexture


## Theme dùng chung cho thẻ/dialog của gói cũ (đã gồm font đậm, nút xanh, panel xanh); tạo một lần.
static var _theme: Theme = null
static func theme() -> Theme:
	if _theme == null:
		_theme = make_theme(CleanArt.asset("res://assets/workshop_gp/theme.tres") as Theme)
	return _theme


## Thanh tài nguyên xanh đậm dạng viên thuốc (tiền, gem).
static func hud_bar() -> StyleBoxTexture:
	return Soft.surface("hud", Vector4(24, 3, 8, 5)) as StyleBoxTexture


## Nút hành động. kind: upgrade (xanh), amber (nâng cấp hổ phách), race (cam/vàng), claim (xanh lá), cancel (xám), nav (xanh nghiêng), menu (vuông xanh).
## state: normal | hover | pressed | disabled.
static func button(kind: String, state: String = "normal") -> StyleBoxTexture:
	var face := "disabled" if state == "disabled" else kind
	if face == "nav": face = "blue"
	var skin := Soft.surface(face, Vector4(10, 4, 10, 6)) as StyleBoxTexture
	if state == "hover": skin.modulate_color = Color(1.03, 1.03, 1.03)
	elif state in ["pressed", "hover_pressed"]: skin.modulate_color = Color("e6e9e8")
	return skin


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
	return Soft.surface("trough", Vector4.ZERO) as StyleBoxTexture


## Bundled typography: real bold outlines and Vietnamese glyphs, independent of OS fonts.
static func font() -> Font:
	if _font == null:
		var rounded := FontVariation.new()
		rounded.base_font = preload("res://assets/soft_miniature_ui_v1/fonts/Nunito.ttf")
		rounded.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 950.0}
		_font = rounded
	return _font


## Small contrasting outlines and an offset shadow keep text readable over artwork.
static func text_depth(node: Control, light_text: bool = false) -> void:
	node.add_theme_color_override("font_outline_color", Color("47748d55") if light_text else Color.TRANSPARENT)
	node.add_theme_constant_override("outline_size", 1 if light_text else 0)
	node.add_theme_color_override("font_shadow_color", Color("36566d22") if light_text else Color.TRANSPARENT)
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 1 if light_text else 0)


## Đặt kiểu cho một Button theo loại (dùng cho nút dựng bằng code).
static func style_button(b: Button, kind: String) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new() if kind == "tab" else button(kind, state))
	var focus := Soft.flat(Color.TRANSPARENT, 0, 14)
	focus.border_color = C_BLUE
	focus.shadow_size = 0
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus)
	var col := C_TEXT if kind in ["cancel", "tab", "nav", "menu", "info", "claim"] else Color.WHITE
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, col)
	b.add_theme_color_override("font_disabled_color", C_MUTED)
	text_depth(b, col == Color.WHITE)
	if col == Color.WHITE:
		# Chữ nút kẹo như demo: trắng, viền đậm cùng tông nút, đổ bóng nhẹ.
		var rim := Color("8a3a05") if kind in ["race", "orange", "upgrade", "buy", "action", "amber"] else Color("14407c")
		b.add_theme_color_override("font_outline_color", rim)
		b.add_theme_constant_override("outline_size", 4)
		b.add_theme_color_override("font_shadow_color", Color(rim, 0.45))
		b.add_theme_constant_override("shadow_offset_y", 1)
	ButtonSkin.apply(b)


## Theme toàn ứng dụng: lấy theme cũ làm nền (giữ các control chưa đổi) rồi thay Button/Panel/Label/CheckButton.
static func make_theme(base: Theme) -> Theme:
	var th: Theme = base.duplicate() as Theme if base != null else Theme.new()
	th.default_font = font()
	th.default_font_size = 14
	th.set_color("font_color", "Label", C_TEXT)
	th.set_color("font_outline_color", "Label", Color("ffffffd9"))
	th.set_constant("outline_size", "Label", 0)
	th.set_color("font_shadow_color", "Label", Color("0e2b5c33"))
	th.set_constant("shadow_offset_x", "Label", 0)
	th.set_constant("shadow_offset_y", "Label", 0)
	th.set_color("font_outline_color", "Button", Color("173b59dd"))
	th.set_constant("outline_size", "Button", 0)
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
	th.set_stylebox("normal", "LineEdit", Soft.surface("cancel"))
	th.set_color("font_color", "LineEdit", C_TEXT)
	th.set_stylebox("background", "ProgressBar", Soft.flat(Color("e2ece8"), 0, 6))
	th.set_stylebox("fill", "ProgressBar", Soft.flat(Color("a1d7b0"), 0, 6))
	var scroll := Soft.flat(Color("b1d8e4"), 0, 3)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		th.set_stylebox(state, "VScrollBar", scroll)
	th.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
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
