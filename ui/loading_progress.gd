extends ProgressBar
## Thanh trắng bạc, xe công thức đỏ và khói nhẹ theo tiến độ thật.

const CAR_TEXTURE = preload("res://assets/startup_loading/loading_progress_car_formula_red.png")
# Tight region around the selected Formula icon, excluding transparent canvas padding.
const CAR_REGION := Rect2(46, 132, 1706, 658)
const CAR_WIDTH := 78.0
const TRACK_BORDER := 2.0

@export var fill_color := Color("d3e8f4")

var _smoke: Array[Dictionary] = []
var _last_ratio := 0.0
var _smoke_clock := 0.0
var _reduce_motion := false


func _ready() -> void:
	show_percentage = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	value_changed.connect(func(_v: float) -> void: queue_redraw())
	_reduce_motion = "--reduce-motion" in OS.get_cmdline_user_args()
	_last_ratio = get_as_ratio()


func _process(delta: float) -> void:
	var needs_redraw := not _smoke.is_empty()
	for i in range(_smoke.size() - 1, -1, -1):
		_smoke[i]["age"] += delta
		_smoke[i]["position"] += _smoke[i]["velocity"] * delta
		if _smoke[i]["age"] >= 0.5:
			_smoke.remove_at(i)
	var ratio := get_as_ratio()
	if ratio > _last_ratio and ratio < 1.0 and not _reduce_motion and is_visible_in_tree():
		_smoke_clock += delta
		if _smoke_clock >= 0.045:
			_smoke_clock = fmod(_smoke_clock, 0.045)
			var half_width := minf(CAR_WIDTH, size.x) * 0.5
			var car_x := clampf(TRACK_BORDER + (size.x - TRACK_BORDER * 2.0) * ratio, half_width, size.x - half_width)
			for puff in range(2):
				_smoke.append({"age": 0.0,
					"position": Vector2(car_x - half_width + 6.0, -4.0 + puff * 2.0),
					"velocity": Vector2(-24.0 - puff * 9.0, -7.0 + puff * 6.0)})
			needs_redraw = true
	else:
		_smoke_clock = 0.0
	_last_ratio = ratio
	if needs_redraw:
		queue_redraw()


func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 12
	return style


func _draw() -> void:
	if size.x <= 6.0 or size.y <= 6.0:
		return
	var track := _rounded_box(Color("102c47"), int(size.y * 0.5))
	track.border_color = Color("aec8dc")
	track.set_border_width_all(int(TRACK_BORDER))
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	# Match the border's inner contour so no navy seam remains around the silver fill.
	var inner := Rect2(Vector2.ONE * TRACK_BORDER, size - Vector2.ONE * TRACK_BORDER * 2.0)
	var fill_width := inner.size.x * get_as_ratio()
	if fill_width <= 0.0:
		_draw_finish()
		_draw_car(inner.position.x)
		return
	var fill_rect := Rect2(inner.position, Vector2(fill_width, inner.size.y))
	var radius := int(minf(inner.size.y * 0.5, fill_width * 0.5))
	draw_style_box(_rounded_box(fill_color, radius), fill_rect)
	# Short lane markings make the silver fill read as a little racing track.
	var x := inner.position.x + 9.0
	while x + 8.0 < fill_rect.end.x - 6.0:
		draw_line(Vector2(x, size.y * 0.55), Vector2(x + 8, size.y * 0.55), Color("668ca440"), 2.0, true)
		x += 19.0
	_draw_finish()
	_draw_smoke()
	_draw_car(fill_rect.end.x)


func _draw_finish() -> void:
	# A small chequered finish strip stays inside the track at every progress value.
	var cell := 4.0
	var origin := Vector2(size.x - 22.0, (size.y - cell * 4.0) * 0.5)
	for row in range(4):
		for col in range(3):
			var color := Color("edf6fc") if (row + col) % 2 == 0 else Color("18354c")
			draw_rect(Rect2(origin + Vector2(col, row) * cell, Vector2.ONE * cell), color)


func _draw_smoke() -> void:
	for puff in _smoke:
		var life := float(puff["age"]) / 0.5
		var radius := lerpf(2.5, 7.0, life)
		var center: Vector2 = puff["position"]
		draw_circle(center, radius, Color(0.72, 0.86, 0.96, (1.0 - life) * 0.14), true, -1.0, true)
		draw_circle(center, radius * 0.65, Color(0.93, 0.98, 1.0, (1.0 - life) * 0.35), true, -1.0, true)


func _draw_car(progress_x: float) -> void:
	# Keep the whole car visible at both ends; its center follows the fill edge.
	var car_width := minf(CAR_WIDTH, size.x)
	var car_size := Vector2(car_width, car_width * CAR_REGION.size.y / CAR_REGION.size.x)
	var half_width := car_width * 0.5
	var car_x := clampf(progress_x, half_width, size.x - half_width)
	var car_pos := Vector2(car_x - half_width, 3.0 - car_size.y)
	draw_texture_rect_region(CAR_TEXTURE, Rect2(car_pos, car_size), CAR_REGION)
