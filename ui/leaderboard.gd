class_name Leaderboard
extends Control
## Bảng xếp hạng trực tiếp: 8 hàng trượt mượt theo thứ hạng thật của TrafficSim.
## Hàng đổi chỗ thì trượt sang vị trí mới, hiện mũi tên lên/xuống và nháy sáng ngắn; xe người chơi được tô nổi bật.
## Chỉ vẽ trạng thái sim (không chứa logic đua).

const ROW_H := 26.0
const PAD := 8.0
const SLIDE := 14.0          # tốc độ trượt hàng (hàng/giây, hàm mũ)
const FLASH_TIME := 2.2      # thời gian giữ mũi tên + nháy sau khi đổi hạng (giây)
const C_BG := Color("eef5ff")
const C_ROW_ME := Color("f47510", 0.18)
const C_TEXT := Color("23394a")
const C_MUTED := Color("768ca0")
const C_UP := Color("2e9b5a")
const C_DOWN := Color("d1423b")
const C_LINE := Color("c6d8f2")
## Màu chấm khớp thứ tự CAR_COLORS của RaceView (id xe -> màu thân xe).
const DOT_COLORS := [Color("f47510"), Color("3b3e44"), Color("ffffff"), Color("3a78d6"), Color("d1423b"), Color("f2c230"), Color("2aa5a0"), Color("8a5bd0")]

var sim: TrafficSim = null

var _row_y: Dictionary = {}       # id xe -> y hiển thị (đơn vị hàng)
var _rank: Dictionary = {}        # id xe -> hạng ở lần cập nhật trước
var _moved_at: Dictionary = {}    # id xe -> thời điểm đổi hạng (giờ sim)
var _moved_dir: Dictionary = {}   # id xe -> +1 lên hạng, -1 xuống hạng


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, ROW_H * 8.0 + PAD * 2.0)
	clip_contents = true


## Đặt lại khi bắt đầu race mới hoặc khi bỏ sim.
func reset() -> void:
	_row_y.clear()
	_rank.clear()
	_moved_at.clear()
	_moved_dir.clear()
	queue_redraw()


## Gọi mỗi frame: cập nhật hạng, hướng đổi và vị trí trượt.
func update_board(delta: float) -> void:
	if sim == null:
		return
	var rk := sim.ranking()
	for i in rk.size():
		var c: TrafficSim.Car = rk[i]
		if _rank.has(c.id) and int(_rank[c.id]) != i:
			_moved_at[c.id] = sim.time
			_moved_dir[c.id] = 1 if i < int(_rank[c.id]) else -1
		_rank[c.id] = i
		if not _row_y.has(c.id):
			_row_y[c.id] = float(i)
		else:
			_row_y[c.id] = lerpf(float(_row_y[c.id]), float(i), 1.0 - exp(-SLIDE * delta))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_BG)
	if sim == null:
		return
	var font := get_theme_default_font()
	var fs := 13
	var w := size.x
	var leader: TrafficSim.Car = sim.ranking()[0]
	# Vẽ xe người chơi sau cùng để hàng nổi bật không bị hàng khác đè khi đang trượt.
	var order: Array = sim.cars.duplicate()
	order.sort_custom(func(a: TrafficSim.Car, b: TrafficSim.Car) -> bool: return int(a.is_player) < int(b.is_player))
	for c: TrafficSim.Car in order:
		if not _row_y.has(c.id):
			continue
		var y: float = PAD + float(_row_y[c.id]) * ROW_H
		var rank: int = int(_rank[c.id])
		var mid := y + ROW_H * 0.5
		var age: float = sim.time - float(_moved_at.get(c.id, -999.0))
		var fresh := clampf(1.0 - age / FLASH_TIME, 0.0, 1.0)
		if c.is_player:
			draw_rect(Rect2(4.0, y + 1.0, w - 8.0, ROW_H - 2.0), C_ROW_ME)
		if fresh > 0.0:
			var up: bool = int(_moved_dir[c.id]) > 0
			draw_rect(Rect2(4.0, y + 1.0, w - 8.0, ROW_H - 2.0), Color(C_UP if up else C_DOWN, 0.16 * fresh))
		else:
			draw_line(Vector2(10.0, y + ROW_H), Vector2(w - 10.0, y + ROW_H), Color(C_LINE, 0.7), 1.0)
		var ty := mid + fs * 0.36
		# Hạng
		draw_string(font, Vector2(12.0, ty), str(rank + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, C_TEXT)
		# Chấm màu xe
		var col: Color = DOT_COLORS[clampi(c.id, 0, DOT_COLORS.size() - 1)]
		draw_circle(Vector2(44.0, mid), 7.0, col)
		draw_arc(Vector2(44.0, mid), 7.0, 0.0, TAU, 20, Color(C_TEXT, 0.5), 1.0, true)
		# Tên
		draw_string(font, Vector2(60.0, ty), c.driver_name, HORIZONTAL_ALIGNMENT_LEFT, w * 0.4, fs, C_TEXT)
		# Khoảng cách tới xe dẫn đầu / thời gian về đích
		var gap_txt := ""
		if c.finished:
			gap_txt = Balance.fmt_time(c.finish_time)
		elif c == leader:
			gap_txt = I18n.t("race.leader")
		else:
			gap_txt = I18n.t("race.car_lengths") % Balance.fmt_rate(snappedf((leader.s - c.s) / sim.L, 0.1))
		var gw := w * 0.42
		draw_string(font, Vector2(w - 34.0 - gw, ty), gap_txt, HORIZONTAL_ALIGNMENT_RIGHT, gw, fs, C_MUTED if not c.is_player else C_TEXT)
		# Mũi tên đổi hạng
		if fresh > 0.0:
			var up2: bool = int(_moved_dir[c.id]) > 0
			var ax := w - 22.0
			var pts := PackedVector2Array()
			if up2:
				pts = PackedVector2Array([Vector2(ax, mid - 6.0), Vector2(ax + 7.0, mid + 5.0), Vector2(ax - 7.0, mid + 5.0)])
			else:
				pts = PackedVector2Array([Vector2(ax, mid + 6.0), Vector2(ax + 7.0, mid - 5.0), Vector2(ax - 7.0, mid - 5.0)])
			draw_colored_polygon(pts, Color(C_UP if up2 else C_DOWN, 0.4 + 0.6 * fresh))
