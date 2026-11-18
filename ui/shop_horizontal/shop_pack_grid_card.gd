class_name ShopPackGridCard
extends PanelContainer

signal info_pressed

const DESIGN_SIZE := Vector2(420, 414)
const ShopSkin = preload("res://ui/shop_demo_skin.gd")
const DISABLED_TEXT := Color(0.4, 0.43, 0.5, 1)
const OUTLINE := Color(0.25, 0.1, 0.45, 1)
const NAVY := Color(0.05, 0.14, 0.38, 1)

var art_rect: TextureRect
var title_label: Label
var subtitle_label: Label
var info: Button
var buttons_box: VBoxContainer


func _init() -> void:
	theme_type_variation = &"ShopCard"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	art_rect = TextureRect.new()
	art_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(art_rect)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 8)
	box.add_child(title_row)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", NAVY)
	title_row.add_child(title_label)
	info = Button.new()
	info.text = "i"
	info.custom_minimum_size = Vector2(40, 40)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_font_size_override("font_size", 26)
	info.add_theme_color_override("font_color", Color.WHITE)
	var dot := StyleBoxFlat.new()
	dot.bg_color = Color(0.07, 0.2, 0.48, 1)
	dot.set_corner_radius_all(20)
	for state in ["normal", "hover", "pressed", "focus"]:
		info.add_theme_stylebox_override(state, dot)
	info.pressed.connect(info_pressed.emit)
	title_row.add_child(info)

	var pill := PanelContainer.new()
	pill.theme_type_variation = &"Pill"
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pill)
	subtitle_label = Label.new()
	subtitle_label.add_theme_font_size_override("font_size", 26)
	subtitle_label.add_theme_color_override("font_color", Color(0.33, 0.38, 0.47, 1))
	pill.add_child(subtitle_label)

	buttons_box = VBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 8)
	box.add_child(buttons_box)


func setup(art: Texture2D, title: String, subtitle: String) -> void:
	art_rect.texture = art
	title_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.get_parent().visible = subtitle != ""


func add_open_button(count: int, currency: Texture2D, cost: String, disabled: bool) -> Button:
	var button := Button.new()
	ShopSkin.set_kind(button, "gem")
	button.custom_minimum_size = Vector2(230, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.disabled = disabled
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(row)
	for part in ["×%d" % count, currency, cost]:
		if part is Texture2D:
			var icon := TextureRect.new()
			icon.texture = part
			icon.custom_minimum_size = Vector2(30, 30)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		else:
			var label := Label.new()
			label.text = String(part)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 30)
			label.add_theme_color_override("font_color", DISABLED_TEXT if disabled else Color.WHITE)
			label.add_theme_color_override("font_outline_color", OUTLINE)
			label.add_theme_constant_override("outline_size", 0 if disabled else 5)
			row.add_child(label)
	buttons_box.add_child(button)
	return button
