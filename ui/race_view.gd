class_name RaceView
extends Control
const RaceArt = preload("res://ui/race_hud_art.gd")
const CleanArt = preload("res://ui/clean_modern_art.gd")
const Diorama = preload("res://ui/race_diorama.gd")
const Circuit3D = preload("res://ui/race_world_3d.gd")
signal view_rotated
var _world_3d: RefCounted = null
var _use_3d := false
var _rotation_pointer := -2
var _rotation_hint: Label
const Car3D = preload("res://ui/race_car_3d.gd")
var _car_models: Dictionary = {}
## Shared 3D circuit with an orbiting orthographic camera; TrafficSim remains authoritative.
## Đường vẽ dựng từ hình học track (TrackLayout) ở cùng tỉ lệ với quãng đường sim,
## Giữ quãng đường và hình học sim; phóng đại chiều ngang đường/làn để dễ đọc trên mobile.
## Xe đồ chơi quay theo tiếp tuyến đường, giữ nguyên vị trí và làn của TrafficSim.
## Phía trên là HUD lớn (hạng, đồng hồ, vòng, khoảng cách xe trước) và thanh tiến trình trải thẳng một vòng đường.
## Sa bàn, cây, hồ và khu pit được cache cùng mặt đường; chỉ xe và hiệu ứng vẽ mỗi khung.

## Màu thân xe theo id (khớp ui/leaderboard.gd): người chơi cam, rồi graphite, trắng, xanh, đỏ, vàng, ngọc, tím.
const CAR_COLORS := [Color("ffad40"), Color("3b3e44"), Color("ffffff"), Color("3a78d6"), Color("d1423b"), Color("f2c230"), Color("2aa5a0"), Color("8a5bd0")]
const C_HUD := Color("eff8fb")
const C_HUD_PANEL := Color("ffffff")
const C_HUD_TEXT := Color("23394a")
const C_HUD_MUTED := Color("768ca0")
const HUD_H := 44.0       # chiều cao dải HUD (px)
const C_INCOME := Color("2e9e2e")
const C_GROUND := Color("c6e7e7")
const C_RUNOFF := Color("bde1af")
const C_ASPHALT := Color("7d8b94")
const C_ASPHALT2 := Color("7d8b94")
const C_LINE := Color("ffffff")
const C_KERB_A := Color("f48a78")
const C_KERB_B := Color("fff8e9")
const C_MARK := Color("ffad40")
const MARGIN := 22.0       # lề quanh đường (đơn vị sim)
const ROAD_WIDTH_SCALE := 1.55  # Presentation only: road and lateral positions scale together.
const STEP := 2.0          # bước lấy mẫu khi vẽ (đơn vị sim)

var sim: TrafficSim = null
var player_paint_id: String = ""   # ngoại hình xe người chơi (snapshot lượt đang đua); rỗng = màu mặc định
var player_decal_id: String = "none"
var alpha: float = 0.0
## Chữ lớn giữa khung (countdown 3-2-1, "ĐUA!"); rỗng = không vẽ.
var overlay_text: String = ""
var power_value: float = 0.0  # ĐỘI CỦA BẠN: tổng 11 chỉ số xe + tay đua (HUD bên trái); 0 = chưa có
var overlay_sub: String = ""

# Dải khán giả ba hàng phía dưới HUD; mật độ theo Parking và phản ứng vui/buồn.
const STAND_H := 16.0
const STAND_ROWS := 1
const C_STAND := Color("a9b8d0")
const C_STAND_LINE := Color("8fa0bb")
const C_FAN := Color("3a78d6")
const BLUE_SHARE := 0.7    # tỉ lệ khán giả mặc áo xanh của đội
const FILL_CURVE := 0.8    # <1: cấp thấp tăng nhanh, cấp cao tăng chậm nhưng không bao giờ phẳng
const FILL_MIN := 0.12
const FACE_LIFE := 1.2     # giây tồn tại của một icon mặt
const FACE_MAX := 10
const FACE_R := 10.0      # bong bóng B: 20 px gồm đuôi, phần mặt khoảng 16 px
const C_FACE_HAPPY := Color("f6c933")
const C_FACE_SAD := Color("8fb8f0")
const C_FACE_INK := Color("2a2f3a")
static var _face_textures: Dictionary = {}
static var _face_textures_loaded: bool = false

const FX_PASS := 1.1       # giây (giờ sim) hiệu ứng vượt
const FX_ERROR := 1.6      # giây hiệu ứng lỗi

var _fx: Array = []        # {type, id, other, t}
var _fx_sim: TrafficSim = null
var _fx_cursor: int = 0
var _layout: TrackLayout = null
var _L: float = 10.0       # chiều dài xe (đơn vị sim)
var _W: float = 5.5        # bề ngang xe
var _k: float = 1.0        # px / đơn vị sim
var _top: float = HUD_H + STAND_H  # Đường đua nằm dưới HUD và dải khán giả.
var _origin := Vector2.ZERO
var _left := PackedVector2Array()
var _right := PackedVector2Array()
var _mid := PackedVector2Array()
var _kerb_l := PackedVector2Array()
var _kerb_r := PackedVector2Array()
var _track_layer: TrackLayer = null
# Toàn bộ phần tĩnh gộp thành một mảng tam giác (một lệnh vẽ), dựng lại khi đổi kích thước/track.
var _static_pts := PackedVector2Array()
var _static_cols := PackedColorArray()
var _static_idx := PackedInt32Array()
var _scenery: Array = []
var _car_outline := StyleBoxFlat.new()
var _crowd_salt: int = 0
var _crowd_frac: float = 0.0         # cấp Parking / cấp tối đa, 0..1
var _seats := PackedVector2Array()
var _seat_r := PackedFloat32Array()
var _seat_cols := PackedColorArray()
var _seat_rank := PackedInt32Array()  # thứ tự lấp chỗ: seat có rank < số hiện = có người
var _faces: Array = []                # {x, y, t (ms), happy}
var _rng := RandomNumberGenerator.new()
# Vào lưới: lượt mới bắt đầu, xe lăn từ phía sau vạch vào ô xuất phát thay vì hiện ngay một cụm ở lưới.
const ARRIVE_MS := 2200.0
const ARRIVE_LEAD := 140.0   # đơn vị sim: điểm xe bắt đầu lăn vào, phía sau ô xuất phát
const ARRIVE_STAGGER := 0.05 # xe ở ô sau vào trễ thêm (tỉ lệ thời gian) theo từng ô
var _arrive_sim: TrafficSim = null
var _arrive_start_ms: int = 0


## Lớp nền + mặt đường tĩnh, vẽ sau lưng RaceView (show_behind_parent) và chỉ vẽ lại khi đổi kích thước/track.
## Trước đây phần này vẽ lại mỗi khung (hàng nghìn lệnh vẽ từ GDScript), chiếm gần hết thời gian khung trên bản Web
## (Design/25 §7.5).
class TrackLayer extends Control:
	var view: RaceView = null

	func _draw() -> void:
		view._draw_static(self)


func _ready() -> void:
	clip_contents = true
	_build_rotation_controls()
	_car_outline.bg_color = Color(1, 1, 1, 0.12)
	_car_outline.border_color = Color("fff3d7")
	_car_outline.set_border_width_all(1)
	_car_outline.set_corner_radius_all(4)
	_cache_face_textures()
	var sm := GameData.sim()
	_L = float(sm["car_length"])
	_W = float(sm["car_width"])
	_ensure_track_layer()
	resized.connect(_on_resized)


func _build_rotation_controls() -> void:
	_rotation_hint = Label.new()
	_rotation_hint.text = "Kéo để xoay" if I18n.lang() == "vi" else "Drag to rotate"
	_rotation_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotation_hint.add_theme_font_size_override("font_size", 10)
	_rotation_hint.add_theme_color_override("font_color", Color("174e66"))
	_rotation_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_rotation_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_rotation_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_rotation_hint.position = Vector2(size.x*0.44-45, size.y-18)
	_rotation_hint.size = Vector2(90,16)
	_rotation_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotation_hint.visible = _use_3d
	add_child(_rotation_hint)

func reset_circuit_view() -> void:
	if _use_3d and _world_3d != null:
		_world_3d.reset_view()
		queue_redraw()
		view_rotated.emit()

func rotate_circuit_view(horizontal_delta: float) -> void:
	if _use_3d and _world_3d != null:
		_world_3d.rotate_view(-horizontal_delta / maxf(size.x,1.0) * TAU)
		queue_redraw()
		view_rotated.emit()

## Vị trí màn hình của mái nhà để xe 3D (hoặc khán đài nếu không có nhà để xe), null khi ở chế độ 2D / không có cả hai.
func grandstand_screen_point() -> Variant:
	if _use_3d and _world_3d != null and (_world_3d.has_garage or _world_3d.has_grandstand):
		return _world_3d.screen_anchor()
	return null

func grandstand_view_rect() -> Rect2:
	return _world_3d.view_rect if _world_3d != null else Rect2()

func _gui_input(event: InputEvent) -> void:
	if not _use_3d or _world_3d == null:
		return
	# Handle native mouse/touch once; Godot may also emit an emulated copy.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _world_3d.view_rect.has_point(event.position):
			if event.double_click:
				reset_circuit_view()
				_rotation_pointer = -2
			else:
				_rotation_pointer = -1
			accept_event()
		elif not event.pressed and _rotation_pointer == -1:
			_rotation_pointer = -2
			accept_event()
	elif event is InputEventMouseMotion and _rotation_pointer == -1:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			rotate_circuit_view(event.relative.x)
			accept_event()
		else:
			_rotation_pointer = -2
	elif event is InputEventScreenTouch:
		if event.pressed and _rotation_pointer == -2 and _world_3d.view_rect.has_point(event.position):
			_rotation_pointer = event.index
			accept_event()
		elif not event.pressed and _rotation_pointer == event.index:
			_rotation_pointer = -2
			accept_event()
	elif event is InputEventScreenDrag and _rotation_pointer == event.index:
		rotate_circuit_view(event.relative.x)
		accept_event()


func _ensure_track_layer() -> void:
	if _track_layer != null:
		return
	_track_layer = TrackLayer.new()
	_track_layer.view = self
	_track_layer.show_behind_parent = true
	_track_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_track_layer, false, Node.INTERNAL_MODE_FRONT)


## Chọn track cần vẽ (phải có hình học: mọi sector cua có "turn").
func set_track(track_id: String) -> void:
	_use_3d = true
	_rotation_pointer = -2
	if _rotation_hint != null:
		_rotation_hint.visible = _use_3d
	_crowd_salt = absi(track_id.hash()) & 0xffff
	_layout = TrackLayout.build(track_id)
	if not _layout.valid:
		push_error("Track has no geometry to draw: " + track_id)
	_on_resized()


func _project(p: Vector2) -> Vector2:
	# The same affine projection is used by the asphalt, cars, effects and tutorial markers.
	var oriented := Vector2(p.y, -p.x) if _layout != null and _layout.bounds.size.y > _layout.bounds.size.x else p
	return Vector2(oriented.x + oriented.y * 0.22, oriented.y * 0.48 - oriented.x * 0.08)

func _projected_bounds() -> Rect2:
	var bounds := _layout.bounds.grow(MARGIN)
	var projected := Rect2(_project(bounds.position), Vector2.ZERO)
	for p: Vector2 in [Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
		projected = projected.expand(_project(p))
	return projected

func _frame_units() -> Vector2:
	return _projected_bounds().size


func _on_resized() -> void:
	if _rotation_hint != null:
		_rotation_hint.position = Vector2(size.x*0.44-45, size.y-18)
	if _layout == null or not _layout.valid or size.x < 8.0:
		return
	if _use_3d:
		if _world_3d == null:
			_world_3d = Circuit3D.new(self)
		_world_3d.viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		_world_3d.rebuild(_layout, size, _W)
	elif _world_3d != null:
		_world_3d.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for model in _car_models.values():
		model.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if _use_3d else SubViewport.UPDATE_WHEN_VISIBLE
	var fu := _frame_units()
	# Khung do cha cấp (co giãn theo màn): đường vừa với cả chiều rộng lẫn phần cao còn lại, căn giữa.
	var avail := Vector2(maxf(size.x - 22.0, 8.0), maxf(size.y - _top - 23.0, 20.0))
	_k = minf(avail.x / fu.x, avail.y / fu.y)
	var drawn := fu * _k
	var off := Vector2((avail.x - drawn.x) * 0.5 + 11.0, (avail.y - drawn.y) * 0.5 + 8.0)
	_origin = off + Vector2(0.0, _top) - _projected_bounds().position * _k
	_left = PackedVector2Array()
	_right = PackedVector2Array()
	_mid = PackedVector2Array()
	_kerb_l = PackedVector2Array()
	_kerb_r = PackedVector2Array()
	var s := 0.0
	while s <= _layout.lap_length + 0.001:
		var half := _road_half_at(s)
		_mid.append(_to_px(_layout.pos_at(s)))
		_left.append(_to_px(_layout.point_at(s, half)))
		_right.append(_to_px(_layout.point_at(s, -half)))
		_kerb_l.append(_to_px(_layout.point_at(s, half + 1.4)))
		_kerb_r.append(_to_px(_layout.point_at(s, -half - 0.9)))
		s += STEP
	_build_static_mesh()
	_scenery = Diorama.build(_mid, _left, _board_rect(), _crowd_salt)
	_build_crowd()
	_ensure_track_layer()
	_track_layer.queue_redraw()
	queue_redraw()


# ---------------------------------------------------------------- Khán đài

## Số học băm ổn định (không dùng RNG toàn cục): cùng track + chỗ ngồi cho cùng kết quả mỗi lần.
func _hash01(i: int, salt: int) -> float:
	var x: int = ((i + 1) * 73856093) ^ ((_crowd_salt + 1) * 19349663) ^ (salt * 83492791)
	x = (x ^ (x >> 13)) * 1274126177
	x = (x ^ (x >> 16)) & 0x7fffffff
	return float(x % 10000) / 10000.0


## Dựng chỗ ngồi một lần khi đổi kích thước/track. Thứ tự lấp chỗ cố định: giữa ra hai bên, nên lên cấp chỉ thêm chấm.
func _build_crowd() -> void:
	_seats = PackedVector2Array()
	_seat_r = PackedFloat32Array()
	_seat_cols = PackedColorArray()
	_seat_rank = PackedInt32Array()
	var per_row := maxi(int(size.x / 9.0), 8)
	var gap := size.x / float(per_row)
	var prio: Array = []
	for row in STAND_ROWS:
		for i in per_row:
			var idx := row * per_row + i
			var x := gap * (float(i) + 0.5) + (_hash01(idx, 1) - 0.5) * gap * 0.5
			var y := HUD_H + STAND_H * 0.5 + 13.0 * float(row) + (_hash01(idx, 2) - 0.5) * 3.0
			_seats.append(Vector2(x, y))
			_seat_r.append(2.6 + 0.4 * float(row))
			_seat_cols.append(C_FAN if _hash01(idx, 3) < BLUE_SHARE else CAR_COLORS[1 + int(_hash01(idx, 5) * 7.0) % 7])
			prio.append([absf(x - size.x * 0.5) / maxf(size.x * 0.5, 1.0) * 0.6 + _hash01(idx, 4) * 0.4 + float(STAND_ROWS - 1 - row) * 0.03, idx])
	prio.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_seat_rank.resize(_seats.size())
	for r in prio.size():
		_seat_rank[int(prio[r][1])] = r


## Số chỗ có người theo chỗ ngồi Parking (thang lôga; giá trị là BigNumber có thể rất lớn).
func _seat_count() -> int:
	var fill := clampf(pow(_crowd_frac, FILL_CURVE), FILL_MIN, 1.0)
	return int(round(float(_seats.size()) * fill))


## Cập nhật mật độ khi cấp Parking đổi: kín khán đài đúng ở cấp tối đa, mỗi cấp thêm vài chỗ.
func set_parking_level(level: int, max_level: int) -> void:
	var f := clampf(float(level) / float(maxi(max_level, 1)), 0.0, 1.0)
	if is_equal_approx(f, _crowd_frac):
		return
	_crowd_frac = f
	if _track_layer != null:
		_track_layer.queue_redraw()


static func big_log10(b: BigNumber) -> float:
	var digits: String = b._coefficient
	if b.is_zero() or digits == "":
		return 0.0
	var head := float(digits.substr(0, mini(6, digits.length()))) / pow(10.0, float(mini(6, digits.length()) - 1))
	return float(b.exponent + digits.length() - 1) + log(maxf(head, 1.0)) / log(10.0)


func _draw_stand(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0.0, HUD_H, size.x, STAND_H), C_STAND)
	for row in range(1, STAND_ROWS):
		var ly := HUD_H + 3.0 + 13.0 * float(row) + 0.5
		ci.draw_line(Vector2(0.0, ly), Vector2(size.x, ly), C_STAND_LINE, 1.0)
	ci.draw_line(Vector2(0.0, HUD_H + STAND_H - 0.5), Vector2(size.x, HUD_H + STAND_H - 0.5), C_STAND_LINE, 2.0)
	var count := _seat_count()
	for i in _seats.size():
		if _seat_rank[i] < count:
			ci.draw_circle(_seats[i], _seat_r[i], _seat_cols[i])


## Phản ứng của khán giả: chỉ với xe người chơi (vượt = vui; bị vượt/lỗi = buồn).
func _react(e: Dictionary) -> void:
	if sim == null or _seats.is_empty():
		return
	var who: TrafficSim.Car = sim.cars[int(e["id"])]
	var happy := false
	var n := 0
	if String(e["type"]) == "pass":
		if who.is_player:
			happy = true
			n = 3
		elif int(e["other"]) == 0:
			n = 2
	elif who.is_player:
		n = 3
	for k in n:
		_faces.append({"x": _rng.randf_range(size.x * 0.1, size.x * 0.9), "y": HUD_H + STAND_H * 0.5,
			"t": Time.get_ticks_msec(), "happy": happy})
	while _faces.size() > FACE_MAX:
		_faces.pop_front()


## Cache once; optional art must never make a missing file a parse-time failure.
static func _cache_face_textures() -> void:
	if _face_textures_loaded:
		return
	_face_textures_loaded = true
	for mood: String in ["happy", "sad"]:
		var path := "res://assets/racing_ui_hd/icons/reactions/face_%s.png" % mood
		if ResourceLoader.exists(path, "Texture2D"):
			_face_textures[mood] = CleanArt.asset(path) as Texture2D


func _draw_faces() -> void:
	var now := Time.get_ticks_msec()
	var keep: Array = []
	for f: Dictionary in _faces:
		var age := float(now - int(f["t"])) / 1000.0
		if age >= FACE_LIFE:
			continue
		keep.append(f)
		var k := age / FACE_LIFE
		var pop := 0.5 + 0.5 * minf(k * 6.0, 1.0) + 0.25 * sin(minf(k * 6.0, 1.0) * PI)
		var a := 1.0 - maxf(0.0, (k - 0.6) / 0.4)
		var happy: bool = f["happy"]
		var r := FACE_R * pop
		var p := Vector2(float(f["x"]), float(f["y"]) - 5.0 * k)
		var texture: Texture2D = _face_textures.get("happy" if happy else "sad")
		if texture != null:
			draw_texture_rect(texture, Rect2(p - Vector2.ONE * r, Vector2.ONE * r * 2.0), false, Color(1.0, 1.0, 1.0, a))
			continue
		# Preserve the procedural face when its optional texture is unavailable.
		draw_circle(p, r, Color(C_FACE_HAPPY if happy else C_FACE_SAD, a))
		draw_arc(p, r, 0.0, TAU, 20, Color(C_FACE_INK, a), 1.4, true)
		var ink := Color(C_FACE_INK, a)
		draw_circle(p + Vector2(-r * 0.36, -r * 0.2), maxf(r * 0.12, 0.9), ink)
		draw_circle(p + Vector2(r * 0.36, -r * 0.2), maxf(r * 0.12, 0.9), ink)
		if happy:
			draw_arc(p + Vector2(0.0, r * 0.05), r * 0.5, 0.15 * PI, 0.85 * PI, 10, ink, 1.4, true)
		else:
			draw_arc(p + Vector2(0.0, r * 0.7), r * 0.42, 1.15 * PI, 1.85 * PI, 10, ink, 1.4, true)
			draw_circle(p + Vector2(r * 0.62, r * 0.12), maxf(r * 0.14, 1.0), Color(0.45, 0.7, 1.0, a))
	_faces = keep


## Hình chữ nhật dải khán đài (tọa độ cục bộ), dùng cho spotlight hướng dẫn.
func stand_rect() -> Rect2:
	return Rect2(0.0, HUD_H, size.x, STAND_H)


func _to_px(p: Vector2) -> Vector2:
	if _use_3d and _world_3d != null:
		return _world_3d.screen_point(p)
	return _project(p) * _k + _origin


func _road_half_at(s: float) -> float:
	return _layout.width_at(s) * _W * 0.5 * ROAD_WIDTH_SCALE


func _car_position(s: float, lateral: float) -> Vector2:
	if _use_3d:
		return _world_3d.screen_at(s, lateral * ROAD_WIDTH_SCALE)
	var points := PackedVector2Array([Vector2(1075,210), Vector2(1160,270), Vector2(1166,350), Vector2(1090,441), Vector2(945,510), Vector2(735,572), Vector2(535,571), Vector2(370,540), Vector2(300,477), Vector2(320,405), Vector2(439,321), Vector2(650,251), Vector2(870,206)])
	var u := fposmod(s / _layout.lap_length, 1.0) * points.size()
	var i := int(u)
	var t := u - i
	var n := points.size()
	var a := points[(i + n - 1) % n]
	var b := points[i % n]
	var c := points[(i + 1) % n]
	var d := points[(i + 2) % n]
	var position := 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t)
	var tangent := (c - b).normalized()
	position += Vector2(-tangent.y, tangent.x) * lateral * 1.4
	return position * Vector2(size.x / 1536.0, size.y / 864.0)


func _bend_at(s: float) -> float:
	return absf(angle_difference(_layout.heading_at(s - 5.0), _layout.heading_at(s + 5.0)))


func _board_rect() -> Rect2:
	return Rect2(5.0, _top + 3.0, maxf(size.x - 10.0, 1.0), maxf(size.y - _top - 12.0, 1.0))


## Static scenery shares the existing cached track layer, never the per-frame car draw.
func _draw_static(ci: CanvasItem) -> void:
	var sea := HdUi.Soft.flat(Color("47bfd4"), 0, 14)
	sea.border_color = Color("fff8e9")
	sea.set_border_width_all(2)
	ci.draw_style_box(sea, Rect2(Vector2.ZERO, size))
	# Small sky accents share the continuous sea, behind live controls and the 3D circuit.
	for cloud: Vector3 in [Vector3(0.61, 0.18, 1.0), Vector3(0.73, 0.25, 0.7), Vector3(0.93, 0.17, 0.55)]:
		var center := Vector2(size.x * cloud.x, size.y * cloud.y)
		var r := size.x * 0.018 * cloud.z
		var white := Color("e9f8f8")
		ci.draw_circle(center, r, white)
		ci.draw_circle(center + Vector2(r * 0.8, -r * 0.6), r * 1.15, white)
		ci.draw_circle(center + Vector2(r * 1.8, 0), r * 0.9, white)
		ci.draw_style_box(HdUi.Soft.flat(white, 0, 4), Rect2(center + Vector2(-r, 0), Vector2(r * 3.7, r * 0.8)))
	if _use_3d and _world_3d != null:
		ci.draw_texture_rect(_world_3d.viewport.get_texture(), _world_3d.view_rect, false)
	else:
		var backdrop := HdUi.Soft.texture("harbor_island")
		if backdrop != null:
			ci.draw_texture_rect(backdrop, Rect2(Vector2.ZERO, size), false)


func _add_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	var i := _static_pts.size()
	_static_pts.append_array(PackedVector2Array([a, b, c, d]))
	_static_cols.append_array(PackedColorArray([col, col, col, col]))
	_static_idx.append_array(PackedInt32Array([i, i + 1, i + 2, i, i + 2, i + 3]))


## Đoạn thẳng dày w (đầu bằng, như draw_line) thành một tứ giác.
func _add_line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var dir := b - a
	if dir.length_squared() < 0.000001:
		return
	var n := dir.normalized().orthogonal() * (w * 0.5)
	_add_quad(a + n, b + n, b - n, a - n, col)


## Dựng hình học tĩnh theo đúng thứ tự vẽ cũ: vùng thoát, mặt đường, mép trắng + lề, vạch giữa, vạch xuất phát.
func _build_static_mesh() -> void:
	_static_pts = PackedVector2Array()
	_static_cols = PackedColorArray()
	_static_idx = PackedInt32Array()
	var n := _mid.size()
	if n < 3:
		return
	var s := 0.0
	var prev_l := Vector2.ZERO
	var prev_r := Vector2.ZERO
	for i in n:
		var bend := _bend_at(s)
		var run_half := _road_half_at(s) + 6.0 + minf(bend * 16.0, 5.0)
		var l := _to_px(_layout.point_at(s, run_half))
		var r := _to_px(_layout.point_at(s, -run_half))
		if i > 0:
			_add_quad(prev_l, l, r, prev_r, Color("cfbf96") if bend > 0.13 else C_RUNOFF)
		prev_l = l
		prev_r = r
		s += STEP
	for i in n - 1:
		_add_quad(_kerb_l[i] + Vector2(0, 1.5), _kerb_l[i + 1] + Vector2(0, 1.5), _kerb_r[i + 1] + Vector2(0, 1.5), _kerb_r[i] + Vector2(0, 1.5), Color("899780"))
	for i in n - 1:
		_add_quad(_left[i], _left[i + 1], _right[i + 1], _right[i], C_ASPHALT if (i / 6) % 2 == 0 else C_ASPHALT2)
	for i in n - 1:
		var col := C_KERB_A if (i / 4) % 2 == 0 else C_KERB_B
		_add_line(_left[i], _left[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		_add_line(_right[i], _right[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		_add_line(_kerb_l[i], _kerb_l[i + 1], col, maxf(2.8, 2.6 * _k))
		_add_line(_kerb_r[i], _kerb_r[i + 1], col, maxf(2.8, 2.6 * _k))
	# Paired rubber lines follow the turn, instead of a dotted centerline everywhere.
	for i in n - 1:
		var distance := float(i) * STEP
		if _bend_at(distance) > 0.13:
			var direction := signf(angle_difference(_layout.heading_at(distance - 5.0), _layout.heading_at(distance + 5.0)))
			for tire: float in [-0.9, 0.9]:
				var offset := direction * _road_half_at(distance) * 0.24 + tire
				_add_line(_to_px(_layout.point_at(distance, offset)), _to_px(_layout.point_at(distance + STEP, offset)), Color("32414b"), maxf(0.65, _k * 0.6))
	for i in range(0, n - 3, 9):
		if _bend_at(float(i) * STEP) < 0.05:
			_add_line(_mid[i], _mid[i + 2], Color(C_LINE, 0.48), maxf(1.0, 0.5 * _k))
	# Starting slots follow the same grid positions as the simulated cars.
	var traffic: Dictionary = GameData.sim()["traffic"]
	for slot in Balance.CAR_COUNT:
		var row: int = slot / 2
		var column: int = slot % 2
		var grid_s := -(float(row) * float(traffic["grid_row_len"]) + float(column) * float(traffic["grid_col_offset_len"])) * _L
		var grid_y := (1.0 if column == 0 else -1.0) * float(traffic["grid_col_width"]) * _W * ROAD_WIDTH_SCALE
		var a := _to_px(_layout.point_at(grid_s - 5.0, grid_y + 2.8))
		var b := _to_px(_layout.point_at(grid_s + 5.0, grid_y + 2.8))
		var c := _to_px(_layout.point_at(grid_s + 5.0, grid_y - 2.8))
		var d := _to_px(_layout.point_at(grid_s - 5.0, grid_y - 2.8))
		for edge in [[a, b], [b, c], [c, d]]:
			_add_line(edge[0], edge[1], Color("a7b4b5"), 0.8)
	var half := _road_half_at(0.0)
	var cols := int(ceil(half * 2.0 / 2.4))
	var cell := half * 2.0 / float(cols)
	for row in 2:
		for c in cols:
			var y0 := half - cell * float(c)
			var s0 := -1.2 + 1.2 * float(row)
			_add_quad(_to_px(_layout.point_at(s0, y0)), _to_px(_layout.point_at(s0 + 1.2, y0)),
				_to_px(_layout.point_at(s0 + 1.2, y0 - cell)), _to_px(_layout.point_at(s0, y0 - cell)),
				Color.WHITE if (row + c) % 2 == 0 else Color("1d1f24"))


## Phần động, vẽ mỗi khung: xe, hiệu ứng, HUD, chữ lớn. Nền và đường nằm ở TrackLayer phía sau.
func _draw() -> void:
	if _layout == null or not _layout.valid or _left.size() < 3:
		return
	if sim == null:
		_draw_grid()
		_draw_overlay_text()
		_draw_power_chip()
		return
	# Spectators are rendered in the shared 3D world.
	if sim != _arrive_sim:
		_arrive_sim = sim
		_arrive_start_ms = Time.get_ticks_msec()
	# Từ xe cuối lên xe đầu: xe dẫn đầu nằm trên khi chồng nhau; xe người chơi luôn trên cùng.
	var order := sim.ranking()
	order.reverse()
	for c: TrafficSim.Car in order:
		if not c.is_player:
			_draw_car(sim.render_pos(c, alpha) - _arrive_offset(c), sim.render_lat(c, alpha), c.id, false)
	var me := sim.player_car()
	_draw_car(sim.render_pos(me, alpha) - _arrive_offset(me), sim.render_lat(me, alpha), 0, true)
	_draw_fx()
	_draw_hud()
	_draw_overlay_text()


## Quãng xe còn phải lăn để tới ô xuất phát (đơn vị sim, ≥ 0): giảm dần theo hàm bậc hai nên xe chậm lại khi vào ô.
func _arrive_offset(c: TrafficSim.Car) -> float:
	if sim == null or sim.tick_count > 0:
		return 0.0
	var t := float(Time.get_ticks_msec() - _arrive_start_ms) / ARRIVE_MS
	var span := 1.0 - ARRIVE_STAGGER * float(Balance.CAR_COUNT - 1)
	var u := clampf((t - ARRIVE_STAGGER * float(c.grid_slot)) / span, 0.0, 1.0)
	return ARRIVE_LEAD * (1.0 - u) * (1.0 - u)


## Tâm và bán kính bao xe người chơi (tọa độ cục bộ) cho spotlight hướng dẫn; r = 0 khi chưa có sim/track.
func player_marker() -> Dictionary:
	if sim == null or _layout == null or not _layout.valid:
		return {"pos": size * 0.5, "r": 0.0}
	var me := sim.player_car()
	return {"pos": _car_position(sim.render_pos(me, alpha), sim.render_lat(me, alpha)), "r": _car_marker_radius(true)}


## Ô hạng + đồng hồ giữa HUD (tọa độ cục bộ), cùng công thức với _draw_hud.
func hud_rank_rect() -> Rect2:
	var available := size.x - 24.0
	var team_width := available * 0.28
	var rank_width := available * 0.40
	return Rect2(12.0 + team_width, (HUD_H - 36.0) * 0.5, rank_width - 10.0, 36.0)


## The reward tile sits below Daily Gift on the right of the fixed cluster.
static func hud_boost_rect_for_width(width: float) -> Rect2:
	return Rect2(Vector2(1145, 450) * width / 1448.0, Vector2(260, 205) * width / 1448.0)


func _hud_baseline(font: Font, font_size: int, row_top: float, row_height: float) -> float:
	return row_top + (row_height - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)



## Nhận sự kiện mới từ sim (gọi mỗi frame). Trả về các sự kiện mới để lớp trên phát âm thanh / bảng tin.
func pump_events() -> Array:
	var fresh: Array = []
	if sim != _fx_sim:
		_fx_sim = sim
		_fx_cursor = 0
		_fx.clear()
	if sim == null:
		return fresh
	while _fx_cursor < sim.events.size():
		var e: Dictionary = sim.events[_fx_cursor]
		_fx_cursor += 1
		_fx.append(e)
		fresh.append(e)
		_react(e)
	var keep: Array = []
	for e: Dictionary in _fx:
		if sim.time - float(e["t"]) < FX_ERROR:
			keep.append(e)
	_fx = keep
	return fresh


func _draw_fx() -> void:
	var player_pass: Dictionary = {}
	for event: Dictionary in _fx:
		if String(event["type"]) == "pass" and int(event["id"]) == 0:
			player_pass = event
	if player_pass.is_empty():
		return
	var age: float = sim.time - float(player_pass["t"])
	if age > FX_PASS:
		return
	var c: TrafficSim.Car = sim.cars[0]
	_draw_comic_pass(_car_position(sim.render_pos(c, alpha), sim.render_lat(c, alpha)), age / FX_PASS)


## One compact callout for the latest player overtake; no invented gameplay boosts.
func _draw_comic_pass(car_pos: Vector2, progress: float) -> void:
	var text := I18n.t("race.overtake")
	var font := get_theme_default_font()
	var fs := 12
	var half := Vector2(minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5 + 12.0, size.x * 0.42), 17.0)
	var center := car_pos + Vector2(0, -35.0 - progress * 6.0)
	center.x = clampf(center.x, half.x + 8.0, size.x - half.x - 8.0)
	center.y = clampf(center.y, _top + half.y + 5.0, size.y - half.y - 8.0)
	var opacity := clampf((1.0 - progress) * 3.0, 0.0, 1.0)
	var polygon := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		polygon.append(center + Vector2(cos(a), sin(a)) * half * (1.0 if i % 2 == 0 else 0.78))
	draw_colored_polygon(polygon, Color(Color("ffe28a"), opacity))
	var border := polygon.duplicate()
	border.append(polygon[0])
	draw_polyline(border, Color(Color("586153"), opacity), 1.0, true)
	draw_string(font, Vector2(center.x - half.x, center.y + 4), text, HORIZONTAL_ALIGNMENT_CENTER, half.x * 2, fs, Color(Color("31494c"), opacity))
	var heading := _layout.heading_at(sim.render_pos(sim.player_car(), alpha))
	var forward := Vector2.from_angle(heading)
	for i in 3:
		var tail := car_pos - forward * (10.0 + float(i) * 3.0) + forward.orthogonal() * (float(i) - 1.0) * 3.0
		draw_line(tail, tail - forward * 6.0, Color(Color("fff1ba"), opacity), 1.5, true)


func _draw_overlay_text() -> void:
	if overlay_text == "":
		return
	var font := get_theme_default_font()
	var fs := int(clampf(size.x * 0.28, 48.0, 140.0))
	var mid := Vector2(size.x * 0.5, _top + (size.y - _top) * 0.5)
	var w := size.x
	var base := Vector2(0.0, mid.y + fs * 0.34)
	draw_string(font, base + Vector2(3, 3), overlay_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(0, 0, 0, 0.35))
	draw_string(font, base, overlay_text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color("fff8e7"))
	if overlay_sub != "":
		var sfs := 15
		draw_string(font, Vector2(1, base.y + fs * 0.42 + 1), overlay_sub, HORIZONTAL_ALIGNMENT_CENTER, w, sfs, Color(0, 0, 0, 0.45))
		draw_string(font, Vector2(0, base.y + fs * 0.42), overlay_sub, HORIZONTAL_ALIGNMENT_CENTER, w, sfs, Color("fff8e7"))


## Trước khi đua: tám xe ở ô xuất phát (hai cột so le, hàng đầu sau vạch).
func _draw_grid() -> void:
	var tr: Dictionary = GameData.sim()["traffic"]
	for i in range(Balance.CAR_COUNT - 1, -1, -1):
		var row: int = i / 2
		var col: int = i % 2
		var s := -(float(row) * float(tr["grid_row_len"]) + float(col) * float(tr["grid_col_offset_len"])) * _L
		var y := (1.0 if col == 0 else -1.0) * float(tr["grid_col_width"]) * _W
		_draw_car(s, y, i, i == 0)


func _car_half_length(is_player: bool) -> float:
	return clampf(_L * _k * 0.9, 7.0, 10.0) * (1.12 if is_player else 1.0)


func _car_marker_radius(is_player: bool) -> float:
	# Circumscribed car body plus the player outline, also used by tutorial spotlight.
	return _car_half_length(is_player) * 1.25 + (2.0 if is_player else 0.0)


## Tiny cars face the actual track tangent, including reverse bends and lane changes.
func _draw_car(s: float, y: float, id: int, is_player: bool) -> void:
	var col: Color = CAR_COLORS[clampi(id, 0, CAR_COLORS.size() - 1)]
	if is_player and player_paint_id != "":
		var pd := GameData.paint(player_paint_id)
		if not pd.is_empty():
			col = Color(String(pd["color"]))
	var p := _car_position(s, y)
	var yaw := 0.0
	if sim != null and id < sim.cars.size():
		yaw = sim.render_yaw(sim.cars[id])
	var half_length := _car_half_length(is_player)
	if _use_3d:
		_world_3d.update_car(id, s, y, yaw, col)
	else:
		if not _car_models.has(id):
			_car_models[id] = Car3D.new(self)
		var heading := (_car_position(s + 1.0, y) - p).angle() + yaw
		var texture: Texture2D = _car_models[id].update(heading, col)
		var extent := Vector2.ONE * size.x * 0.032 * 3.15
		Diorama.oval(self, p + Vector2(1, 2), Vector2(half_length, half_length * 0.45), Color(0.08, 0.16, 0.20, 0.22))
		draw_texture_rect(texture, Rect2(p - extent * 0.5, extent), false)

	if is_player:
		var mark := p + Vector2(0, -half_length - 6.0)
		draw_colored_polygon(PackedVector2Array([mark + Vector2(-3.5, -2.0), mark + Vector2(3.5, -2.0), mark + Vector2(0, 3.0)]), C_MARK)


# ---------------------------------------------------------------- HUD

## Chip power của đội, dưới ô hạng; vẽ cả khi chưa có cuộc đua.
func _draw_power_chip() -> void:
	if power_value <= 0.0:
		return
	var font := get_theme_default_font()
	var k := size.x / 1448.0
	var scale_ui := size.x / 390.0
	var power_canvas := Rect2(30, 146, 330, 100)
	var power_rect := Rect2(power_canvas.position * k, power_canvas.size * k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	RaceArt.hud_skin("lap_teal").draw(get_canvas_item(), power_canvas)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var icon_side := power_rect.size.y * 0.72
	draw_texture_rect(HdUi.Soft.texture("speedometer"), Rect2(power_rect.position + Vector2(power_rect.size.y * 0.3, (power_rect.size.y - icon_side) * 0.5), Vector2.ONE * icon_side), false)
	var text_x := power_rect.position.x + power_rect.size.y * 1.1
	_draw_centered_text(font, Rect2(text_x, power_rect.position.y, power_rect.end.x - text_x - 4.0 * scale_ui, power_rect.size.y), format_team_power(power_value), int(17 * scale_ui), Color.WHITE)


func _draw_hud() -> void:
	_draw_power_chip()
	var font := get_theme_default_font()
	var scale_ui := size.x / 390.0
	var rk := sim.ranking()
	var me := sim.player_car()
	var lap := "%d/%d" % [sim.lap_of(me), sim.laps]
	# Cùng toạ độ canvas 1448 với rank/income/facilities (y=20, cao 111) và cùng margin bo góc 9-slice.
	var k := size.x / 1448.0
	var lap_canvas := Rect2(710, 20, 230, 111)
	var lap_rect := Rect2(lap_canvas.position * k, lap_canvas.size * k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	RaceArt.hud_skin("lap_teal").draw(get_canvas_item(), lap_canvas)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_centered_text(font, lap_rect, lap, int(22 * scale_ui), Color.WHITE)
	var marker := _car_position(sim.render_pos(me, alpha), sim.render_lat(me, alpha)) - Vector2(24, 33) * scale_ui
	var marker_rect := Rect2(marker, Vector2(48, 29) * scale_ui)
	draw_texture_rect(RaceArt.texture("skins/position_teal"), marker_rect, false)
	var text_rect := Rect2(marker_rect.position, Vector2(marker_rect.size.x, marker_rect.size.y - 6 * scale_ui))
	_draw_centered_text(font, text_rect, "P%d/%d" % [rk.find(me) + 1, rk.size()], int(13 * scale_ui), Color("ffda36"))


func _draw_centered_text(font: Font, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var baseline := rect.position.y + (rect.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(rect.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)



## Số đội hiển thị: một chữ số thập phân, dấu phẩy Việt; số lớn rút gọn cùng banner.
static func format_team_power(v: float) -> String:
	var suffixes := ["", "K", "M", "B", "T", "AA", "AB", "AC"]
	var scaled := v
	var tier := 0
	while scaled >= 1000.0 and tier < suffixes.size() - 1:
		scaled /= 1000.0
		tier += 1
	if tier > 0:
		# Không hiển thị 1000,00K tại ranh giới do làm tròn.
		if snappedf(scaled, 0.01) >= 1000.0 and tier < suffixes.size() - 1:
			scaled /= 1000.0
			tier += 1
		return ("%.2f%s" % [scaled, suffixes[tier]]).replace(".", I18n.dec())
	return ("%.1f" % v).replace(".", I18n.dec())


## Biểu tượng đội: hai người (đầu tròn + vai cong).
func _draw_team_icon(c: Vector2) -> void:
	for dx: float in [-4.0, 5.0]:
		draw_circle(c + Vector2(dx, -4.0), 3.0, C_HUD_MUTED)
		draw_arc(c + Vector2(dx, 7.0), 5.0, PI, TAU, 10, C_HUD_MUTED, 2.0)
