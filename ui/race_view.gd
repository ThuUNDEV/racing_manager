class_name RaceView
extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Khung đua 2D nhìn từ trên xuống. Chỉ vẽ trạng thái của TrafficSim, không chứa logic.
## Đường vẽ dựng từ hình học track (TrackLayout) ở cùng tỉ lệ với quãng đường sim,
## nên vị trí, bề rộng mặt đường và độ lệch ngang của xe khớp với mô phỏng (Design/08 §3, §6).
## Mỗi xe là một chấm tròn màu (có thể chồng lên nhau khi vượt, như bảng xếp hạng có hình ảnh); xe người chơi to hơn, viền trắng.
## Phía trên là HUD lớn (hạng, đồng hồ, vòng, khoảng cách xe trước) và thanh tiến trình trải thẳng một vòng đường.
## Nền và mặt đường vẽ bằng code theo bảng màu Racing UI HD (cỏ xanh, nhựa xanh than, lề đỏ-trắng, HUD xanh đậm).

## Màu chấm theo id xe (khớp ui/leaderboard.gd): người chơi cam, rồi graphite, trắng, xanh, đỏ, vàng, ngọc, tím.
const DOT_COLORS := [Color("f47510"), Color("3b3e44"), Color("ffffff"), Color("3a78d6"), Color("d1423b"), Color("f2c230"), Color("2aa5a0"), Color("8a5bd0")]
const C_HUD := Color("f1f7fc")
const C_HUD_PANEL := Color("ffffff")
const C_HUD_TEXT := Color("23394a")
const C_HUD_MUTED := Color("768ca0")
const C_DOT_EDGE := Color("1d1f24")
var income_text: String = ""   # "11,5K/s", do Main cập nhật
const HUD_H := 78.0       # chiều cao dải HUD (px)
const DOT_TRAIL := 4.0     # khoảng cách các chấm mờ phía sau xe (đơn vị sim)
const C_INCOME := Color("2e9e2e")
const C_GROUND :=Color("8fd16a")
const C_RUNOFF := Color("72bb52")
const C_ASPHALT := Color("3a4254")
const C_ASPHALT2 := Color("3f4659")
const C_LINE := Color("ffffff")
const C_KERB_A := Color("e53935")
const C_KERB_B := Color("ffffff")
const C_RING := Color("ffffff")
const C_MARK := Color("f47510")
const MARGIN := 22.0       # lề quanh đường (đơn vị sim)
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
const STAND_H := 44.0
const STAND_ROWS := 3
const C_STAND := Color("a9b8d0")
const C_STAND_LINE := Color("8fa0bb")
const C_FAN := Color("3a78d6")
const BLUE_SHARE := 0.7    # tỉ lệ khán giả mặc áo xanh của đội
const CAP_FULL_LOG := 3.0  # log10(1 + chỗ ngồi Parking) để kín khán đài
const FILL_MIN := 0.12
const FACE_LIFE := 1.2     # giây tồn tại của một icon mặt
const FACE_MAX := 10
const FACE_R := 10.0      # bong bóng B: 20 px gồm đuôi, phần mặt khoảng 16 px
const C_FACE_HAPPY := Color("f6c933")
const C_FACE_SAD := Color("8fb8f0")
const C_FACE_INK := Color("2a2f3a")
static var _face_textures: Dictionary = {}
static var _face_textures_loaded: bool = false

const C_GOOD := Color("2e9b5a")
const C_BAD := Color("d1423b")
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
var _hud_box: StyleBoxFlat = null
var _crowd_salt: int = 0
var _crowd_log: float = 0.0          # log10(1 + Parking) gần nhất
var _seats := PackedVector2Array()
var _seat_r := PackedFloat32Array()
var _seat_cols := PackedColorArray()
var _seat_rank := PackedInt32Array()  # thứ tự lấp chỗ: seat có rank < số hiện = có người
var _faces: Array = []                # {x, y, t (ms), happy}
var _rng := RandomNumberGenerator.new()


## Lớp nền + mặt đường tĩnh, vẽ sau lưng RaceView (show_behind_parent) và chỉ vẽ lại khi đổi kích thước/track.
## Trước đây phần này vẽ lại mỗi khung (hàng nghìn lệnh vẽ từ GDScript), chiếm gần hết thời gian khung trên bản Web
## (Design/25 §7.5).
class TrackLayer extends Control:
	var view: RaceView = null

	func _draw() -> void:
		view._draw_static(self)


func _ready() -> void:
	clip_contents = true
	_cache_face_textures()
	var sm := GameData.sim()
	_L = float(sm["car_length"])
	_W = float(sm["car_width"])
	_ensure_track_layer()
	resized.connect(_on_resized)


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
	_crowd_salt = absi(track_id.hash()) & 0xffff
	_layout = TrackLayout.build(track_id)
	if not _layout.valid:
		push_error("Track has no geometry to draw: " + track_id)
	_on_resized()


func _frame_units() -> Vector2:
	var b := _layout.bounds
	return b.size + Vector2.ONE * MARGIN * 2.0


func _on_resized() -> void:
	if _layout == null or not _layout.valid or size.x < 8.0:
		return
	var fu := _frame_units()
	# Khung do cha cấp (co giãn theo màn): đường vừa với cả chiều rộng lẫn phần cao còn lại, căn giữa.
	var avail := Vector2(size.x, maxf(size.y - _top, 40.0))
	_k = minf(avail.x / fu.x, avail.y / fu.y)
	var drawn := fu * _k
	var off := Vector2((avail.x - drawn.x) * 0.5, (avail.y - drawn.y) * 0.5)
	_origin = Vector2(MARGIN * _k, MARGIN * _k) + off + Vector2(0.0, _top) - _layout.bounds.position * _k
	_left = PackedVector2Array()
	_right = PackedVector2Array()
	_mid = PackedVector2Array()
	_kerb_l = PackedVector2Array()
	_kerb_r = PackedVector2Array()
	var s := 0.0
	while s <= _layout.lap_length + 0.001:
		var half := _layout.width_at(s) * _W * 0.5
		_mid.append(_to_px(_layout.pos_at(s)))
		_left.append(_to_px(_layout.point_at(s, half)))
		_right.append(_to_px(_layout.point_at(s, -half)))
		_kerb_l.append(_to_px(_layout.point_at(s, half + 0.9)))
		_kerb_r.append(_to_px(_layout.point_at(s, -half - 0.9)))
		s += STEP
	_build_static_mesh()
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
			var y := HUD_H + 9.0 + 13.0 * float(row) + (_hash01(idx, 2) - 0.5) * 3.0
			_seats.append(Vector2(x, y))
			_seat_r.append(2.6 + 0.4 * float(row))
			_seat_cols.append(C_FAN if _hash01(idx, 3) < BLUE_SHARE else DOT_COLORS[1 + int(_hash01(idx, 5) * 7.0) % 7])
			prio.append([absf(x - size.x * 0.5) / maxf(size.x * 0.5, 1.0) * 0.6 + _hash01(idx, 4) * 0.4 + float(STAND_ROWS - 1 - row) * 0.03, idx])
	prio.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_seat_rank.resize(_seats.size())
	for r in prio.size():
		_seat_rank[int(prio[r][1])] = r


## Số chỗ có người theo chỗ ngồi Parking (thang lôga; giá trị là BigNumber có thể rất lớn).
func _seat_count() -> int:
	var fill := clampf(_crowd_log / CAP_FULL_LOG, FILL_MIN, 1.0)
	return int(round(float(_seats.size()) * fill))


## Cập nhật mật độ khi cấp Parking đổi (gọi mỗi khung cũng được: không làm gì nếu không đổi).
func set_seats(seats: BigNumber) -> void:
	var lg := big_log10(seats.add(BigNumber.from_int(1)))
	if is_equal_approx(lg, _crowd_log):
		return
	_crowd_log = lg
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
		_faces.append({"x": _rng.randf_range(size.x * 0.1, size.x * 0.9), "y": HUD_H + _rng.randf_range(FACE_R + 3.0, STAND_H - FACE_R - 3.0),
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
	return p * _k + _origin


## Phần tĩnh (gọi từ TrackLayer): nền cỏ, vùng thoát, mặt đường, lề, vạch xuất phát.
func _draw_static(ci: CanvasItem) -> void:
	for row in 32:
		var t := float(row) / 31.0
		ci.draw_rect(Rect2(0, size.y * row / 32.0, size.x, size.y / 32.0 + 1), Color("86da19").lerp(Color("54b800"), t))
	for corner in [Vector2(18, 18), Vector2(size.x - 18, 18), Vector2(18, size.y - 22), Vector2(size.x - 18, size.y - 22)]:
		ci.draw_circle(corner + Vector2(0, 4), 11, Color("398c0c"))
		ci.draw_circle(corner + Vector2(-6, 0), 6, Color("70ce08"))
		ci.draw_circle(corner + Vector2(4, -4), 8, Color("b2eb20"))
		ci.draw_circle(corner + Vector2(9, 3), 5, Color("84d70e"))
	_draw_stand(ci)
	if _layout == null or not _layout.valid or _left.size() < 3 or _static_idx.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _static_idx, _static_pts, _static_cols)


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
	var max_w := 0.0
	for w in _layout.widths:
		max_w = maxf(max_w, w)
	var run_half := (max_w * _W + 12.0) * 0.5
	var s := 0.0
	var prev_l := Vector2.ZERO
	var prev_r := Vector2.ZERO
	for i in n:
		var l := _to_px(_layout.point_at(s, run_half))
		var r := _to_px(_layout.point_at(s, -run_half))
		if i > 0:
			_add_quad(prev_l, l, r, prev_r, C_RUNOFF)
		prev_l = l
		prev_r = r
		s += STEP
	for i in n - 1:
		_add_quad(_left[i], _left[i + 1], _right[i + 1], _right[i], C_ASPHALT if (i / 6) % 2 == 0 else C_ASPHALT2)
	for i in n - 1:
		var col := C_KERB_A if (i / 2) % 2 == 0 else C_KERB_B
		_add_line(_left[i], _left[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		_add_line(_right[i], _right[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		_add_line(_kerb_l[i], _kerb_l[i + 1], col, maxf(2.0, 1.4 * _k))
		_add_line(_kerb_r[i], _kerb_r[i + 1], col, maxf(2.0, 1.4 * _k))
	for i in range(0, n - 1, 4):
		_add_line(_mid[i], _mid[i + 1], Color(C_LINE, 0.55), maxf(1.0, 0.3 * _k))
	var half := _layout.width_at(0.0) * _W * 0.5
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
		return
	_draw_faces()
	# Từ xe cuối lên xe đầu: xe dẫn đầu nằm trên khi chồng nhau; xe người chơi luôn trên cùng.
	var order := sim.ranking()
	order.reverse()
	for c: TrafficSim.Car in order:
		if not c.is_player:
			_draw_dot(sim.render_pos(c, alpha), sim.render_lat(c, alpha), c.id, false)
	var me := sim.player_car()
	_draw_dot(sim.render_pos(me, alpha), sim.render_lat(me, alpha), 0, true)
	_draw_fx()
	_draw_hud()
	_draw_overlay_text()


## Tâm và bán kính chấm xe người chơi (tọa độ cục bộ) cho spotlight hướng dẫn; r = 0 khi chưa có sim/track.
func player_marker() -> Dictionary:
	if sim == null or _layout == null or not _layout.valid:
		return {"pos": size * 0.5, "r": 0.0}
	var me := sim.player_car()
	return {"pos": _to_px(_layout.point_at(sim.render_pos(me, alpha), sim.render_lat(me, alpha))), "r": _dot_radius(true)}


## Ô hạng + đồng hồ giữa HUD (tọa độ cục bộ), cùng công thức với _draw_hud.
func hud_rank_rect() -> Rect2:
	var pw := minf(170.0, size.x * 0.42)
	var x := (size.x - pw) * 0.5
	var right := hud_boost_rect_for_width(size.x).position.x - 8.0
	return Rect2(x, 6.0, maxf(1.0, right - x), HUD_H - 12.0)


## Shared bounds keep the boost and rank aligned, including on narrow phones.
static func hud_boost_rect_for_width(width: float) -> Rect2:
	var button_width := clampf(width * 0.27, 80.0, 100.0)
	return Rect2(width - button_width - 8.0, (HUD_H - 48.0) * 0.5, button_width, 48.0)


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
	for e: Dictionary in _fx:
		var age: float = sim.time - float(e["t"])
		var c: TrafficSim.Car = sim.cars[int(e["id"])]
		var p := _to_px(_layout.point_at(sim.render_pos(c, alpha), sim.render_lat(c, alpha)))
		if String(e["type"]) == "pass":
			if age > FX_PASS:
				continue
			var f := age / FX_PASS
			var col := C_GOOD if c.is_player else (C_BAD if int(e["other"]) == 0 else C_RING)
			draw_arc(p, _L * _k * (0.7 + 0.9 * f), 0.0, TAU, 28, Color(col, 1.0 - f), maxf(2.0, 0.55 * _k), true)
			var up := p + Vector2(0, -_L * _k * (1.0 + 0.5 * f))
			var u := _k * 0.8
			draw_colored_polygon(PackedVector2Array([up + Vector2(0, -3.0) * u, up + Vector2(3.0, 2.0) * u, up + Vector2(-3.0, 2.0) * u]), Color(col, 1.0 - f))
		else:
			var f2 := age / FX_ERROR
			var blink := 0.55 + 0.45 * sin(age * 18.0)
			draw_arc(p, _L * _k * 0.8, 0.0, TAU, 28, Color(C_BAD, (1.0 - f2) * blink), maxf(2.0, 0.6 * _k), true)


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
		_draw_dot(s, y, i, i == 0)


func _dot_radius(is_player: bool) -> float:
	return maxf(6.0, _W * _k * 1.2) * (1.4 if is_player else 1.0)


## Một xe = một chấm tròn màu có viền tối và vài chấm mờ phía sau để thấy hướng chạy / tốc độ.
func _draw_dot(s: float, y: float, id: int, is_player: bool) -> void:
	var col: Color = DOT_COLORS[clampi(id, 0, DOT_COLORS.size() - 1)]
	if is_player and player_paint_id != "":
		var pd := GameData.paint(player_paint_id)
		if not pd.is_empty():
			col = Color(String(pd["color"]))
	var r := _dot_radius(is_player)
	var p := _to_px(_layout.point_at(s, y))
	for i in range(3, 0, -1):
		var q := _to_px(_layout.point_at(s - DOT_TRAIL * float(i), y))
		draw_circle(q, r * (1.0 - 0.17 * float(i)), Color(col, 0.30 - 0.07 * float(i)))
	if is_player:
		var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
		draw_arc(p, r + 3.0 + 1.5 * pulse, 0.0, TAU, 32, Color(C_RING, 0.55 + 0.45 * pulse), 2.5, true)
	draw_circle(p, r, col)
	if is_player:
		_draw_dot_decal(p, r, CarPreview.contrast_for(player_paint_id))
	draw_arc(p, r, 0.0, TAU, 24, C_DOT_EDGE, 1.6 if not is_player else 2.2, true)
	if is_player:
		var mark := p + Vector2(0, -r - 11.0)
		draw_colored_polygon(PackedVector2Array([mark + Vector2(-5.5, -4.0), mark + Vector2(5.5, -4.0), mark + Vector2(0, 5.0)]), C_MARK)


# ---------------------------------------------------------------- HUD

func _draw_hud() -> void:
	var font := get_theme_default_font()
	var w := size.x
	draw_rect(Rect2(0, 0, w, HUD_H), C_HUD)
	var rk := sim.ranking()
	var me := sim.player_car()
	var idx := rk.find(me)
	# Giữa: hạng và đồng hồ.
	var panel := hud_rank_rect()
	var pw := panel.size.x
	if _hud_box == null:
		_hud_box = StyleBoxFlat.new()
		_hud_box.bg_color = C_HUD_PANEL
		_hud_box.set_corner_radius_all(12)
		_hud_box.set_border_width_all(2)
	var sb := _hud_box
	sb.border_color = C_MARK if idx == 0 else Color("46607a")
	draw_style_box(sb, panel)
	var rank_txt := "P%d/%d" % [idx + 1, rk.size()]
	draw_string(font, Vector2(panel.position.x, panel.position.y + 27.0), rank_txt, HORIZONTAL_ALIGNMENT_CENTER, pw, 28, C_HUD_TEXT)
	var clock := Balance.fmt_clock(ceil(sim.time_left())) if sim.is_timed() else I18n.t("race.lap") % sim.lap_of(me)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 44.0), clock, HORIZONTAL_ALIGNMENT_CENTER, pw, 14, C_HUD_MUTED)
	if income_text != "":
		# Icon tiền + "12,6K/s": cả cụm căn giữa trong ô hạng.
		var icon := HdUi.tex("icons/cash.png")
		var icon_s := 16.0
		var gap := 3.0
		var inc_font := 13
		while inc_font > 9 and font.get_string_size(income_text, HORIZONTAL_ALIGNMENT_LEFT, -1, inc_font).x + icon_s + gap > pw - 8.0:
			inc_font -= 1
		var tw := font.get_string_size(income_text, HORIZONTAL_ALIGNMENT_LEFT, -1, inc_font).x
		var x0 := panel.position.x + (pw - (tw + icon_s + gap)) * 0.5
		var base_y := panel.position.y + 61.0
		if icon != null:
			draw_texture_rect(icon, Rect2(x0, base_y - icon_s + 3.0, icon_s, icon_s), false)
		draw_string(font, Vector2(x0 + icon_s + gap, base_y), income_text, HORIZONTAL_ALIGNMENT_LEFT, -1, inc_font, C_INCOME)
	# Trái: ĐỘI CỦA BẠN = tổng 11 chỉ số xe + tay đua (chỉ số đã chốt lúc xuất phát khi đang đua).
	var side := panel.position.x - 8.0
	draw_string(font, Vector2(10.0, 22.0), I18n.t("race.team"), HORIZONTAL_ALIGNMENT_LEFT, side, 11, C_HUD_MUTED)
	if power_value > 0.0:
		_draw_team_icon(Vector2(18.0, 38.0))
		var power_text := format_team_power(power_value)
		var power_width := maxf(panel.position.x - 40.0, 24.0)
		var power_font := 22
		while power_font > 12 and font.get_string_size(power_text, HORIZONTAL_ALIGNMENT_LEFT, -1, power_font).x > power_width:
			power_font -= 1
		draw_string(font, Vector2(34.0, 46.0), power_text, HORIZONTAL_ALIGNMENT_LEFT, power_width, power_font, C_HUD_TEXT)



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



## Decal thu gọn trên chấm xe người chơi (chỉ nhận ra hình dạng, không phải bản chi tiết ở Garage).
func _draw_dot_decal(p: Vector2, r: float, c: Color) -> void:
	match player_decal_id:
		"double_stripe":
			var w := maxf(1.6, r * 0.2)
			for sx: float in [-0.38, 0.38]:
				var h := sqrt(maxf(1.0 - sx * sx, 0.0)) * r * 0.92
				draw_line(p + Vector2(sx * r, -h), p + Vector2(sx * r, h), c, w)
		"lightning":
			var u := r * 0.9
			draw_colored_polygon(PackedVector2Array([p + Vector2(0.25, -1.0) * u, p + Vector2(-0.55, 0.1) * u, p + Vector2(-0.05, 0.1) * u,
				p + Vector2(-0.3, 1.0) * u, p + Vector2(0.6, -0.2) * u, p + Vector2(0.08, -0.2) * u]), c)
		"checker":
			var q := r * 0.5
			draw_rect(Rect2(p + Vector2(-q, -q), Vector2(q, q)), c)
			draw_rect(Rect2(p, Vector2(q, q)), c)
