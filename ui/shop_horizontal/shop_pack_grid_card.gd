class_name ShopPackGridCard
extends PanelContainer
## Native 2-column pack grid matching the approved Shop; payments remain catalog-driven.
signal info_pressed
const DemoSkin = preload("res://ui/shop_demo_theme.gd")
var art_rect: TextureRect
var title_label: Label
var info: Button
var buttons_box: HBoxContainer

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", DemoSkin.card(false, 5))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	add_child(box)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 0)
	heading.custom_minimum_size.y = 24
	box.add_child(heading)
	title_label = DemoSkin.label("", 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(title_label)
	var reserve := Control.new()
	reserve.custom_minimum_size.x = 36
	reserve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(reserve)
	info = Button.new()
	info.custom_minimum_size = Vector2(44, 44)
	info.flat = true
	for state in ["normal", "hover", "pressed", "focus"]:
		info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var dot := PanelContainer.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", DemoSkin.Soft.flat(Color("09aae4"), 0, 7))
	info.add_child(dot)
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dot.offset_left = -10; dot.offset_top = -10; dot.offset_right = 10; dot.offset_bottom = 10
	var text := DemoSkin.label("i", 14)
	text.add_theme_color_override("font_color", Color.WHITE)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.add_child(text)
	info.pressed.connect(info_pressed.emit)
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.add_child(info)
	info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	info.offset_left = -44; info.offset_right = 0; info.offset_top = 0; info.offset_bottom = 44
	art_rect = DemoSkin.picture(null, Vector2(0, 52))
	box.add_child(art_rect)
	buttons_box = HBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 4)
	box.add_child(buttons_box)

func set_palette(_base: Color, _light: Color) -> void:
	pass # Pack identity is the object artwork; backgrounds share the approved ivory.

func setup(art: Texture2D, title: String, _subtitle: String = "") -> void:
	art_rect.texture = art
	title_label.text = title
	title_label.tooltip_text = title

func add_open_button(count: int, currency: Texture2D, cost: String, disabled: bool) -> Button:
	var button := Button.new()
	DemoSkin.action(button, "buy", 11)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	button.disabled = disabled
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 1)
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for part in ["×%d" % count, currency, cost]:
		if part is Texture2D:
			var icon := DemoSkin.picture(part, Vector2(14, 14))
			icon.name = "PaymentIcon"
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		else:
			var label := DemoSkin.label(String(part), 11)
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.add_theme_color_override("font_color", Color("77756e") if disabled else Color.WHITE)
			row.add_child(label)
	buttons_box.add_child(button)
	return button
