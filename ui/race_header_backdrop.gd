extends Control
## Sky behind the live HUD; drawn at demo proportions so no baked-in labels appear.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var k := size.x / 887.0
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * k)
	for y in 260:
		var color := Color("4ba8e9").lerp(Color("b9e6f5"), float(y) / 260.0)
		if y < 101:
			color = Color("55b5ee").lerp(Color("3798dc"), float(y) / 220.0)
		draw_line(Vector2(0, y), Vector2(887, y), color, 1.5)
	for cloud: Vector3 in [Vector3(12, 177, 0.75), Vector3(467, 206, 1.0), Vector3(714, 203, 0.8), Vector3(865, 191, 0.95)]:
		var p := Vector2(cloud.x, cloud.y)
		var r := 15.0 * cloud.z
		var white := Color(1, 1, 1, 0.65)
		draw_circle(p, r, white)
		draw_circle(p + Vector2(r, -r * 0.5), r * 1.2, white)
		draw_circle(p + Vector2(r * 2.1, 0), r * 0.85, white)
		draw_style_box(_cloud_base(), Rect2(p + Vector2(-r, 0), Vector2(r * 4, r * 0.8)))

func _cloud_base() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.65)
	box.set_corner_radius_all(8)
	return box
