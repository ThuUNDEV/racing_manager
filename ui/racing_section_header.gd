extends PanelContainer
## Shared soft blue section ribbon; containers handle long localized titles.
var title := ""
var icon_texture: Texture2D
var compact := false
func _ready() -> void:
	custom_minimum_size.y = 34
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HdUi.Soft.surface("section", Vector4(8, 2, 8, 2) if compact else Vector4(8, 3, 8, 5)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(32, 26) if compact else Vector2(50, 30)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20 if compact else 22)
	label.add_theme_font_override("font", HdUi.font())
	# Như demo v2: chữ navy đặc, không viền, không đổ bóng (viền trên font đậm 950 gây gợn mép).
	label.add_theme_color_override("font_color", Color("0e2b5c"))
	label.clip_text = true
	row.add_child(label)
