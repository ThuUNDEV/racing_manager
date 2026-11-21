extends Control
## Sky behind the live HUD; drawn at demo proportions so no baked-in labels appear.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	resized.connect(func() -> void: offset_bottom = 101.0 * size.x / 887.0 + 1.0)

func _draw() -> void:
	# Chỉ tô nền xanh sau thanh tài nguyên (101 đơn vị demo); không còn trời/mây bên dưới.
	var k := size.x / 887.0
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * k)
	for y in 101:
		draw_line(Vector2(0, y), Vector2(887, y), Color("55b5ee").lerp(Color("3798dc"), float(y) / 220.0), 1.5)

func _cloud_base() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.65)
	box.set_corner_radius_all(8)
	return box
