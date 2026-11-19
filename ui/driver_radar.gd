class_name DriverRadar
extends Control
## Biểu đồ mạng nhện cho chỉ số tay đua. `values` vẽ đặc; `ref_values` (tuỳ chọn) vẽ nét đứt mảnh để so sánh.
## Trục bắt đầu ở `floor_value` (không phải 0) để các chỉ số 34-65 của game vẫn tách được hình dạng.

var labels: PackedStringArray = PackedStringArray()
var values: Array = []
var ref_values: Array = []
var floor_value := 20.0
var max_value := 70.0
var fill_color := Color("f2790a")
var ref_color := Color("0e2b5c")
var text_color := Color("0e2b5c")
var grid_color := Color("c3d6f2")
var font_size := 12
var radius_px := 92.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 250)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _norm(v: float) -> float:
	return clampf((v - floor_value) / maxf(max_value - floor_value, 1.0), 0.0, 1.0)


func _point(i: int, n: int, r: float, centre: Vector2) -> Vector2:
	var a := -PI / 2.0 + TAU * float(i) / float(n)
	return centre + Vector2(cos(a), sin(a)) * r


func _draw() -> void:
	var n := values.size()
	if n < 3:
		return
	var font := get_theme_font("font", "Label")
	var centre := size * 0.5
	var radius := minf(radius_px, minf(size.x * 0.5 - 62.0, size.y * 0.5 - 24.0))
	radius = maxf(radius, 30.0)
	for ring in range(1, 5):
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_point(i, n, radius * float(ring) / 4.0, centre))
		pts.append(pts[0])
		draw_polyline(pts, grid_color, 1.0 if ring < 4 else 1.5, true)
	for i in n:
		draw_line(centre, _point(i, n, radius, centre), grid_color, 1.0, true)
	if ref_values.size() == n:
		var rp := PackedVector2Array()
		for i in n:
			rp.append(_point(i, n, radius * _norm(float(ref_values[i])), centre))
		rp.append(rp[0])
		draw_polyline(rp, ref_color, 1.5, true)
	var poly := PackedVector2Array()
	for i in n:
		poly.append(_point(i, n, radius * _norm(float(values[i])), centre))
	var fill := fill_color
	fill.a = 0.35
	draw_colored_polygon(poly, fill)
	var outline := poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, fill_color, 2.5, true)
	for p in poly:
		draw_circle(p, 3.5, fill_color)
	for i in n:
		var text := "%s %d" % [labels[i] if i < labels.size() else "", int(round(float(values[i])))]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var anchor := _point(i, n, radius + 12.0, centre)
		var dx := anchor.x - centre.x
		var x := anchor.x - tw * 0.5
		if dx > 6.0:
			x = anchor.x
		elif dx < -6.0:
			x = anchor.x - tw
		var y := anchor.y + float(font_size) * 0.35
		x = clampf(x, 0.0, maxf(size.x - tw, 0.0))
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
