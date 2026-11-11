class_name TrackLayout
extends RefCounted
## Hình học đường đua dựng từ dữ liệu track: mỗi sector cua có "turn" (độ, dương = rẽ trái).
## Đơn vị là đơn vị sim; toạ độ màn hình (trục y hướng xuống), xuất phát hướng sang phải.
## Quãng đường s trên đường vẽ chính là quãng đường sim, nên không còn ánh xạ theo sector (Design/08 §3).

const STEP := 1.0

var track_id: String = ""
var valid: bool = false
var lap_length: float = 400.0
var points: PackedVector2Array = PackedVector2Array()   # điểm tại s = i * STEP
var headings: PackedFloat32Array = PackedFloat32Array() # góc hướng đi (rad, toạ độ màn hình)
var widths: PackedFloat32Array = PackedFloat32Array()   # bề rộng (bề ngang xe) tại điểm
var closure_error: float = 0.0
var total_turn: float = 0.0
var bounds: Rect2 = Rect2()


static func build(p_track_id: String) -> TrackLayout:
	var lay := TrackLayout.new()
	lay.track_id = p_track_id
	lay.lap_length = GameData.lap_length_of(p_track_id)
	var defs: Array = GameData.sector_defs(p_track_id)
	for d: Dictionary in defs:
		if bool(d["corner"]) and not d["has_turn"]:
			return lay  # thiếu hình học: không dựng được
	var x := 0.0
	var y := 0.0
	var h := 0.0
	for d: Dictionary in defs:
		var ln: float = d["len"]
		var n := int(round(ln / STEP))
		var turn_rad := deg_to_rad(float(d["turn"]))
		lay.total_turn += float(d["turn"])
		for i in n:
			lay.points.append(Vector2(x, -y))
			lay.headings.append(-h)
			lay.widths.append(lerpf(float(d["w0"]), float(d["w1"]), float(i) / float(n)))
			var dh := turn_rad / float(n)
			var hm := h + dh * 0.5
			x += STEP * cos(hm)
			y += STEP * sin(hm)
			h += dh
	lay.closure_error = Vector2(x, y).length()
	lay.bounds = Rect2(lay.points[0], Vector2.ZERO)
	for p in lay.points:
		lay.bounds = lay.bounds.expand(p)
	lay.valid = true
	return lay


func count() -> int:
	return points.size()


func pos_at(s: float) -> Vector2:
	var u := fposmod(s, lap_length) / STEP
	var i := int(u) % points.size()
	return points[i].lerp(points[(i + 1) % points.size()], u - floorf(u))


func heading_at(s: float) -> float:
	var u := fposmod(s, lap_length) / STEP
	var i := int(u) % points.size()
	return lerp_angle(headings[i], headings[(i + 1) % points.size()], u - floorf(u))


func width_at(s: float) -> float:
	var u := fposmod(s, lap_length) / STEP
	var i := int(u) % points.size()
	return lerpf(widths[i], widths[(i + 1) % points.size()], u - floorf(u))


## Vectơ pháp tuyến hướng sang TRÁI của chiều chạy (toạ độ màn hình).
func left_at(s: float) -> Vector2:
	var a := heading_at(s)
	return Vector2(sin(a), -cos(a))


## Điểm ở độ lệch ngang y (đơn vị sim, dương = trái) so với đường giữa tại s.
func point_at(s: float, y: float) -> Vector2:
	return pos_at(s) + left_at(s) * y


## Khoảng cách tối thiểu giữa hai đoạn đường giữa cách nhau > min_sep đơn vị dọc đường.
func min_clearance(min_sep: float = 45.0) -> float:
	var n := points.size()
	var best := INF
	for i in range(0, n, 2):
		for j in range(i + 1, n, 2):
			var sep := float(j - i) * STEP
			sep = minf(sep, lap_length - sep)
			if sep > min_sep:
				best = minf(best, points[i].distance_to(points[j]))
	return best
