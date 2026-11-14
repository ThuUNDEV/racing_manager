extends Control
## Slim racing ribbon with a diagonal end and pale speed stripes.

var title := ""
var icon_texture: Texture2D

func _ready() -> void:
	custom_minimum_size.y = 26
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var icon := TextureRect.new()
	# Ignore intrinsic texture dimensions before assigning the fixed icon bounds.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = icon_texture
	icon.position = Vector2(12, 3)
	icon.size = Vector2(28, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var font := preload("res://assets/clean_modern/fonts/Roboto-BlackItalic.ttf")
	var label := Label.new()
	label.text = title
	label.position = Vector2(47, 0)
	label.size.y = 26
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", Color("06428e88"))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _draw() -> void:
	var w := size.x
	var h := size.y - 2.0
	var main_end := clampf(w * 0.61, 151.0, w - 56.0)
	var pale_end := w - 43.0
	var pale := PackedVector2Array([
		Vector2(main_end + 10, 1), Vector2(pale_end + 15, 1),
		Vector2(pale_end - 6, h), Vector2(main_end - 12, h)])
	draw_polygon(pale, PackedColorArray([Color("d7edfc"), Color("c6e5fc"), Color("93c7f6"), Color("83bdf2")]))
	for i in range(2):
		var x := pale_end + 22.0 + i * 13.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 1), Vector2(x + 8, 1), Vector2(x - 13, h), Vector2(x - 21, h)]), Color("a5d5fa"))
	var points := PackedVector2Array([
		Vector2(8, 0), Vector2(main_end + 16, 0), Vector2(main_end - 6, h),
		Vector2(3, h), Vector2(0, h - 4), Vector2(4, 6)])
	var shadow := points.duplicate()
	for i in range(shadow.size()):
		shadow[i].y += 2
	draw_colored_polygon(shadow, Color("377db94d"))
	draw_polygon(points, PackedColorArray([
		Color("20cfff"), Color("028ef3"), Color("0755ba"),
		Color("0878db"), Color("078ce7"), Color("18bafb")]))
	draw_line(Vector2(10, 1), Vector2(main_end + 12, 1), Color("81e7ff"), 1.0, true)
