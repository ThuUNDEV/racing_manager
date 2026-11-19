class_name ShopPackGridCard
extends PanelContainer
## Thẻ mở gói (Pro Pack, All-Star Pack, Standard/Elite Gear): pack nổi trên nền tia sáng theo màu gói,
## nhãn tên + nút "i" ở góc trên trái, hai nút mở ×1 / ×10 nằm cạnh nhau bên dưới.

signal info_pressed

const ShopSkin = preload("res://ui/shop_demo_skin.gd")
const Soft = preload("res://ui/soft_miniature.gd")
const DISABLED_TEXT := Color("6a645b")
const OUTLINE := Color(0.25, 0.1, 0.45, 1)
const NAVY := Color("12334c")
const RAYS := 12
static var _cache: Dictionary = {}

var art_rect: TextureRect
var title_label: Label
var subtitle_label: Label  # giữ cho tương thích, không hiển thị
var info: Button
var buttons_box: HBoxContainer
var _scene: TextureRect
var _stage: Panel


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("fff4e4")
	skin.border_color = Color("e8d5bc")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(20)
	skin.set_content_margin_all(3)
	skin.shadow_color = Color("79593633")
	skin.shadow_size = 4
	skin.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("panel", skin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	add_child(box)

	_stage = Panel.new()
	_stage.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_stage.custom_minimum_size = Vector2(0, 116)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stage_skin := StyleBoxFlat.new()
	stage_skin.bg_color = Color("ffd1c4")
	stage_skin.set_corner_radius_all(17)
	_stage.add_theme_stylebox_override("panel", stage_skin)
	box.add_child(_stage)
	_scene = TextureRect.new()
	_scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene.stretch_mode = TextureRect.STRETCH_SCALE
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_scene)
	_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_rect = TextureRect.new()
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(art_rect)
	art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_rect.offset_top = 26
	art_rect.offset_bottom = -4
	art_rect.offset_left = 8
	art_rect.offset_right = -8

	var pill := PanelContainer.new()
	var pill_skin := Soft.flat(Color(1.0, 0.973, 0.925, 0.95), 3, 12)
	pill_skin.content_margin_left = 8
	pill_skin.content_margin_right = 3
	pill_skin.shadow_color = Color("79593622")
	pill_skin.shadow_size = 2
	pill.add_theme_stylebox_override("panel", pill_skin)
	_stage.add_child(pill)
	pill.position = Vector2(6, 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	pill.add_child(row)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", NAVY)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title_label)
	info = Button.new()
	info.text = "i"
	info.custom_minimum_size = Vector2(22, 22)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color.WHITE)
	var dot := StyleBoxFlat.new()
	dot.bg_color = Color("12338a")
	dot.set_corner_radius_all(11)
	for state in ["normal", "hover", "pressed", "focus"]:
		info.add_theme_stylebox_override(state, dot)
	info.pressed.connect(info_pressed.emit)
	row.add_child(info)

	var button_margin := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		button_margin.add_theme_constant_override("margin_" + side, 4)
	box.add_child(button_margin)
	buttons_box = HBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 5)
	button_margin.add_child(buttons_box)


## base/light: màu nền tia sáng (đậm ở rìa, nhạt ở tâm).
func set_palette(base: Color, light: Color) -> void:
	var key := "%s%s" % [base.to_html(), light.to_html()]
	if not _cache.has(key):
		var image := Image.new()
		image.load_svg_from_string(_burst_svg(base, light), 2.0)
		_cache[key] = ImageTexture.create_from_image(image)
	_scene.texture = _cache[key]


static func _burst_svg(base: Color, light: Color) -> String:
	var rays := ""
	for i in RAYS:
		var a0 := deg_to_rad(i * 360.0 / RAYS)
		var a1 := a0 + deg_to_rad(360.0 / RAYS * 0.4)
		rays += '<path d="M100 82 L%.1f %.1f L%.1f %.1f Z"/>' % [100 + cos(a0) * 260, 82 + sin(a0) * 260, 100 + cos(a1) * 260, 82 + sin(a1) * 260]
	return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 140" preserveAspectRatio="none"><defs><radialGradient id="g" cx="0.5" cy="0.58" r="0.75"><stop offset="0" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></radialGradient></defs><rect width="200" height="140" fill="url(#g)"/><g fill="#fff" opacity="0.3">%s</g><path d="M158 14 l2 6 6 2 -6 2 -2 6 -2 -6 -6 -2 6 -2z" fill="#fff" opacity="0.85"/><path d="M30 24 l1.5 4 4 1.5 -4 1.5 -1.5 4 -1.5 -4 -4 -1.5 4 -1.5z" fill="#fff" opacity="0.7"/></svg>' % [light.to_html(false), base.to_html(false), rays]


func setup(art: Texture2D, title: String, _subtitle: String = "") -> void:
	art_rect.texture = art
	title_label.text = title


func add_open_button(count: int, currency: Texture2D, cost: String, disabled: bool) -> Button:
	var button := Button.new()
	ShopSkin.set_kind(button, "gem")
	button.custom_minimum_size = Vector2(0, 38)
	button.clip_contents = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = disabled
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(row)
	for part in ["×%d" % count, currency, cost]:
		if part is Texture2D:
			var icon := TextureRect.new()
			icon.texture = part
			icon.name = "PaymentIcon"
			icon.custom_minimum_size = Vector2(16, 16)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		else:
			var label := Label.new()
			label.text = String(part)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", DISABLED_TEXT if disabled else Color.WHITE)
			label.add_theme_color_override("font_outline_color", OUTLINE)
			label.add_theme_constant_override("outline_size", 0 if disabled else 3)
			row.add_child(label)
	buttons_box.add_child(button)
	return button
