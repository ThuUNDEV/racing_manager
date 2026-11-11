class_name RaceView
extends Control
## Khung đua 2D nhìn từ trên xuống. Chỉ vẽ trạng thái của TrafficSim, không chứa logic.
## Đường vẽ dựng từ hình học track (TrackLayout) ở cùng tỉ lệ với quãng đường sim,
## nên vị trí, bề rộng mặt đường và độ lệch ngang của xe khớp với mô phỏng (Design/08 §3, §6).
## Mỗi xe là một chấm tròn màu (có thể chồng lên nhau khi vượt, như bảng xếp hạng có hình ảnh); xe người chơi to hơn, viền trắng.
## Phía trên là HUD lớn (hạng, đồng hồ, vòng, khoảng cách xe trước) và thanh tiến trình trải thẳng một vòng đường.
## Nền và mặt đường vẽ bằng code theo bảng màu Racing UI HD (cỏ xanh, nhựa xanh than, lề đỏ-trắng, HUD xanh đậm).

## Màu chấm theo id xe (khớp ui/leaderboard.gd): người chơi cam, rồi graphite, trắng, xanh, đỏ, vàng, ngọc, tím.
const DOT_COLORS := [Color("f47510"), Color("3b3e44"), Color("ffffff"), Color("3a78d6"), Color("d1423b"), Color("f2c230"), Color("2aa5a0"), Color("8a5bd0")]
const C_HUD := Color("0f2a52")
const C_HUD_PANEL := Color("1b4380")
const C_HUD_TEXT := Color("ffffff")
const C_HUD_MUTED := Color("a9c4ef")
const C_DOT_EDGE := Color("1d1f24")
const HUD_H := 60.0        # chiều cao dải HUD (px)
const DOT_TRAIL := 4.0     # khoảng cách các chấm mờ phía sau xe (đơn vị sim)
const C_GROUND := Color("8fd16a")
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
var _top: float = HUD_H  # đỉnh vùng đường đua (dưới HUD)
var _origin := Vector2.ZERO
var _left := PackedVector2Array()
var _right := PackedVector2Array()
var _mid := PackedVector2Array()
var _kerb_l := PackedVector2Array()
var _kerb_r := PackedVector2Array()


func _ready() -> void:
	clip_contents = true
	var sm := GameData.sim()
	_L = float(sm["car_length"])
	_W = float(sm["car_width"])
	resized.connect(_on_resized)


## Chọn track cần vẽ (phải có hình học: mọi sector cua có "turn").
func set_track(track_id: String) -> void:
	_layout = TrackLayout.build(track_id)
	if not _layout.valid:
		push_error("Track không có hình học để vẽ: " + track_id)
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
	queue_redraw()


func _to_px(p: Vector2) -> Vector2:
	return p * _k + _origin


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_GROUND)
	if _layout == null or not _layout.valid or _left.size() < 3:
		return
	_draw_track()
	if sim == null:
		_draw_grid()
		_draw_overlay_text()
		return
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


func _draw_track() -> void:
	var n := _mid.size()
	# Vùng thoát quanh đường.
	var max_w := 0.0
	for w in _layout.widths:
		max_w = maxf(max_w, w)
	draw_polyline(_mid, C_RUNOFF, (max_w * _W + 12.0) * _k, true)
	# Mặt đường: từng đoạn tứ giác theo bề rộng thực.
	for i in n - 1:
		var quad := PackedVector2Array([_left[i], _left[i + 1], _right[i + 1], _right[i]])
		draw_colored_polygon(quad, C_ASPHALT if (i / 6) % 2 == 0 else C_ASPHALT2)
	# Lề sọc cam/trắng và vạch mép đường.
	for i in n - 1:
		var col := C_KERB_A if (i / 2) % 2 == 0 else C_KERB_B
		draw_line(_left[i], _left[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		draw_line(_right[i], _right[i + 1], C_LINE, maxf(1.0, 0.35 * _k))
		draw_line(_kerb_l[i], _kerb_l[i + 1], col, maxf(2.0, 1.4 * _k))
		draw_line(_kerb_r[i], _kerb_r[i + 1], col, maxf(2.0, 1.4 * _k))
	# Vạch giữa đứt nét.
	for i in range(0, n - 1, 4):
		draw_line(_mid[i], _mid[i + 1], Color(C_LINE, 0.55), maxf(1.0, 0.3 * _k))
	_draw_start_line()


func _draw_start_line() -> void:
	var half := _layout.width_at(0.0) * _W * 0.5
	var rows := 2
	var cols := int(ceil(half * 2.0 / 2.4))
	var cell := half * 2.0 / float(cols)
	for r in rows:
		for c in cols:
			var y0 := half - cell * float(c)
			var s0 := -1.2 + 1.2 * float(r)
			var a := _to_px(_layout.point_at(s0, y0))
			var b := _to_px(_layout.point_at(s0 + 1.2, y0))
			var d := _to_px(_layout.point_at(s0 + 1.2, y0 - cell))
			var e := _to_px(_layout.point_at(s0, y0 - cell))
			draw_colored_polygon(PackedVector2Array([a, b, d, e]), Color.WHITE if (r + c) % 2 == 0 else Color("1d1f24"))


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
	var pw := minf(170.0, w * 0.42)
	var panel := Rect2((w - pw) * 0.5, 6.0, pw, HUD_H - 12.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_HUD_PANEL
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = C_MARK if idx == 0 else Color("46607a")
	draw_style_box(sb, panel)
	var rank_txt := "P%d/%d" % [idx + 1, rk.size()]
	draw_string(font, Vector2(panel.position.x, panel.position.y + 27.0), rank_txt, HORIZONTAL_ALIGNMENT_CENTER, pw, 28, C_HUD_TEXT)
	var clock := Balance.fmt_clock(ceil(sim.time_left())) if sim.is_timed() else "Vòng %d" % sim.lap_of(me)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 44.0), clock, HORIZONTAL_ALIGNMENT_CENTER, pw, 14, C_HUD_MUTED)
	# Trái: ĐỘI CỦA BẠN = tổng 11 chỉ số xe + tay đua (chỉ số đã chốt lúc xuất phát khi đang đua).
	var side := (w - pw) * 0.5 - 8.0
	draw_string(font, Vector2(10.0, 22.0), "ĐỘI CỦA BẠN", HORIZONTAL_ALIGNMENT_LEFT, side, 11, C_HUD_MUTED)
	if power_value > 0.0:
		_draw_team_icon(Vector2(18.0, 38.0))
		draw_string(font, Vector2(34.0, 46.0), format_team_power(power_value), HORIZONTAL_ALIGNMENT_LEFT, maxf(side - 24.0, 24.0), 22, C_HUD_TEXT)
	# Phải: stamina và chế độ ga hiện tại của người chơi (Design/16).
	var rx := panel.end.x + 10.0
	var rw := maxf(w - rx - 10.0, 24.0)
	var mode_txt := {"push": "DỒN SỨC", "balanced": "CÂN BẰNG", "conserve": "GIỮ SỨC"}.get(me.mode, "") as String
	draw_string(font, Vector2(rx, 22.0), mode_txt, HORIZONTAL_ALIGNMENT_LEFT, rw, 11, C_HUD_MUTED)
	var bar := Rect2(rx, 30.0, rw, 8.0)
	draw_rect(bar, Color(1, 1, 1, 0.12))
	var frac := clampf(me.stamina / 100.0, 0.0, 1.0)
	var bar_col := C_MARK if me.mode == "push" else (Color("e0643c") if frac < 0.25 else C_HUD_TEXT)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), bar_col)
	draw_string(font, Vector2(rx, 55.0), "VÒNG %d" % maxi(sim.lap_of(me), 1), HORIZONTAL_ALIGNMENT_LEFT, rw, 12, C_HUD_TEXT)


## Số đội hiển thị: một chữ số thập phân, dấu phẩy Việt; từ 1.000 trở lên rút gọn K.
static func format_team_power(v: float) -> String:
	if v >= 1000.0:
		return ("%.2fK" % (v / 1000.0)).replace(".", ",")
	return ("%.1f" % v).replace(".", ",")


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
