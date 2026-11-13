extends ProgressBar
## Thanh tốc độ cyan: các đoạn nghiêng được tô liên tục theo giá trị thật.

const SEGMENTS := 21


func _ready() -> void:
	show_percentage = false
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	value_changed.connect(func(_v: float) -> void: queue_redraw())


func _draw() -> void:
	var w := size.x
	var h := size.y
	var slant := h * 0.60
	var frame := PackedVector2Array([
		Vector2(slant, 1), Vector2(w - 1, 1),
		Vector2(w - slant, h - 1), Vector2(1, h - 1)])
	draw_colored_polygon(frame, Color("071b46"))
	var outline := frame.duplicate()
	outline.append(frame[0])
	draw_polyline(outline, Color("5886d5"), 1.5, true)
	var inset := 5.0
	var segment_h := h - inset * 2.0
	var skew := segment_h * 0.60
	var start := inset + skew
	var pitch := (w - inset * 2.0 - skew) / SEGMENTS
	var segment_w := pitch - 3.0
	var progress := get_as_ratio() * SEGMENTS
	for i in range(SEGMENTS):
		var x := start + i * pitch
		var points := PackedVector2Array([
			Vector2(x, inset), Vector2(x + segment_w, inset),
			Vector2(x + segment_w - skew, h - inset), Vector2(x - skew, h - inset)])
		draw_colored_polygon(points, Color("294d87"))
		var amount := clampf(progress - i, 0.0, 1.0)
		if amount > 0.0:
			var lit := PackedVector2Array([
				points[0], points[0].lerp(points[1], amount),
				points[3].lerp(points[2], amount), points[3]])
			draw_colored_polygon(lit, Color("12e5f4"))
			draw_line(lit[0], lit[1], Color("a2ffff"), 2.0, true)
