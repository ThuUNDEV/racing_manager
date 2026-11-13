extends Control
## Thông báo Power theo thời gian thật; không sửa dữ liệu hoặc snapshot cuộc đua.
const DURATION := 2.0
const ENTER := 0.22
const EXIT := 0.18
const GREEN := Color("55eb97")

var total_power := 0.0
var gain := 0.0
var _initialized := false
var _burst_base := 0.0
var _has_burst := false
var _suspended := true
var _age := 0.0


func _ready() -> void:
	name = "PowerIncreaseBanner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	get_parent().resized.connect(_layout)
	_layout()


func _layout() -> void:
	var width := minf(310.0, maxf(get_parent().size.x - 32.0, 0.0))
	size = Vector2(width, 62.0)
	position = Vector2((get_parent().size.x - width) * 0.5, RaceView.HUD_H + 12.0)
	queue_redraw()


## Khởi tạo mốc sau load; không phát thông báo lần đầu.
func reset_power(value: float) -> void:
	total_power = value
	_burst_base = value
	gain = 0.0
	_initialized = true
	_has_burst = false
	hide()


func observe_power(value: float) -> void:
	if not _initialized:
		reset_power(value)
		return
	var difference := snappedf(value - total_power, 0.1)
	var previous := total_power
	total_power = value
	if difference < 0.0:
		reset_power(value)
		return
	if difference < 0.1:
		return
	# Khi đã bắt đầu fade-out, một lần tăng mới bắt đầu chuỗi mới.
	if not _has_burst or _age >= DURATION - EXIT:
		_burst_base = previous
	gain = snappedf(value - _burst_base, 0.1)
	_has_burst = true
	_age = 0.0
	visible = not _suspended
	queue_redraw()


## Một thông báo tổng hợp chờ khi popup che đường đua hoặc đang ở tab khác.
func set_suspended(value: bool) -> void:
	if _suspended == value:
		return
	_suspended = value
	if not value and _has_burst:
		_age = 0.0
	visible = _has_burst and not value


func _process(delta: float) -> void:
	if not _has_burst or _suspended:
		return
	_age += delta
	if _age >= DURATION:
		_has_burst = false
		hide()
		return
	modulate.a = minf(clampf(_age / ENTER, 0.0, 1.0), clampf((DURATION - _age) / EXIT, 0.0, 1.0))
	var enter := 1.0 - pow(1.0 - clampf(_age / ENTER, 0.0, 1.0), 3.0)
	position.y = RaceView.HUD_H + 12.0 + 8.0 * (1.0 - enter)
	queue_redraw()


func _box(rect: Rect2, color: Color, edge: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)


func _draw() -> void:
	_box(Rect2(0, 3, size.x, 62), Color("061a39"), Color("061a39"), 15)
	_box(Rect2(Vector2.ZERO, size), Color("102b4f"), Color("79a4ed"), 15)
	_box(Rect2(12, 11, 40, 40), Color("2c77e9"), Color("94c1ff"), 11)
	# Icon đội hai người, không có nhãn chữ.
	draw_arc(Vector2(29, 25), 4, 0, TAU, 20, Color.WHITE, 1.8, true)
	draw_arc(Vector2(29, 40), 7, PI, TAU, 20, Color.WHITE, 1.8, true)
	draw_line(Vector2(22, 40), Vector2(22, 43), Color.WHITE, 1.8, true)
	draw_line(Vector2(36, 40), Vector2(36, 43), Color.WHITE, 1.8, true)
	draw_arc(Vector2(39, 25), 4, -PI * 0.5, PI * 0.5, 12, Color.WHITE, 1.8, true)
	draw_arc(Vector2(38, 40), 7, -PI * 0.5, 0.0, 12, Color.WHITE, 1.8, true)
	var font := get_theme_default_font()
	var total := RaceView.format_team_power(total_power)
	var delta_text := "+" + RaceView.format_team_power(gain)
	var font_size := 25 if size.x >= 290 else 22
	# Giữ icon và mũi tên; giảm chữ chỉ khi số dài cần thêm chỗ.
	while font_size > 12 and font.get_string_size(total + delta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 110.0 > size.x:
		font_size -= 1
	var delta_width := font.get_string_size(delta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var delta_x := size.x - 12.0 - delta_width
	var baseline := (size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	draw_string(font, Vector2(64, baseline), total, HORIZONTAL_ALIGNMENT_LEFT, delta_x - 90.0, font_size, Color.WHITE)
	draw_string(font, Vector2(delta_x, baseline), delta_text, HORIZONTAL_ALIGNMENT_LEFT, delta_width + 1.0, font_size, GREEN)
	for y: float in [25.0, 34.0]:
		draw_polyline(PackedVector2Array([Vector2(delta_x - 23, y + 5), Vector2(delta_x - 17, y - 1), Vector2(delta_x - 11, y + 5)]), GREEN, 2.5, true)
