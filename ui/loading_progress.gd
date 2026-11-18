extends ProgressBar
## Soft Miniature: pill cam bóng, viền xanh đồ chơi; chỉ vẽ giá trị tiến độ thật.

@export var fill_color := Color("ff971f")
const TRACK_BORDER := 3.0


func _ready() -> void:
	show_percentage = false
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	value_changed.connect(func(_v: float) -> void: queue_redraw())


func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 12
	return style


func _draw() -> void:
	if size.x <= 6.0 or size.y <= 6.0:
		return
	var track := _rounded_box(Color("d5e9f4"), int(size.y * 0.5))
	track.border_color = Color("397da5")
	track.set_border_width_all(int(TRACK_BORDER))
	track.shadow_color = Color("173f6024")
	track.shadow_size = 3
	track.shadow_offset = Vector2(0, 2)
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2.ONE * TRACK_BORDER, size - Vector2.ONE * TRACK_BORDER * 2.0)
	var fill_width := inner.size.x * get_as_ratio()
	if fill_width > 0.0:
		var fill_rect := Rect2(inner.position, Vector2(fill_width, inner.size.y))
		var radius := int(minf(inner.size.y * 0.5, fill_width * 0.5))
		var fill := _rounded_box(fill_color, radius)
		fill.border_color = Color("e97516")
		fill.border_width_bottom = 2
		draw_style_box(fill, fill_rect)
		if fill_width > 12.0:
			var shine := Rect2(inner.position + Vector2(4, 2), Vector2(fill_width - 8, inner.size.y * 0.32))
			draw_style_box(_rounded_box(Color("fff6c477"), 5), shine)
	# Petit motif d'arrivée, toujours contenu dans le rail.
	var cell := minf(4.0, inner.size.y / 4.0)
	var origin := Vector2(size.x - TRACK_BORDER - 4.0 - cell * 3.0, (size.y - cell * 4.0) * 0.5)
	for row in range(4):
		for col in range(3):
			var color := Color("fff8eb") if (row + col) % 2 == 0 else Color("245376")
			draw_rect(Rect2(origin + Vector2(col, row) * cell, Vector2.ONE * cell), color)
