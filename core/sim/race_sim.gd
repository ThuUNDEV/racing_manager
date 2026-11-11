class_name RaceSim
extends RefCounted
## Mô phỏng cuộc đua thuần logic (không phụ thuộc UI/FPS), fixed tick 10 Hz.
## Công thức v1.0 (Design/04 §2): mọi chỉ số tính theo độ lệch Δ so với nền của giải.
## Mọi hệ số đọc từ data/sim.json; cùng seed + cùng chỉ số + cùng track => cùng kết quả.


class Car:
	var id: int = 0
	var number: int = 1
	var driver_name: String = ""
	var is_player: bool = false
	var trait_id: String = ""
	# Độ lệch so với nền giải: xe (Speed/Handling/Stability/Acceleration), tay đua (Pace/Technique/Composure).
	var dS: float = 0.0
	var dH: float = 0.0
	var dB: float = 0.0
	var dA: float = 0.0
	var dP: float = 0.0
	var dT: float = 0.0
	var dC: float = 0.0
	var form: float = 1.0
	var grid_slot: int = 0
	var gp: float = 0.0          # offset xuất phát (<= 0)
	var travel: float = 0.0      # quãng đường đã chạy từ vị trí xuất phát
	var prev_travel: float = 0.0
	var speed: float = 0.0
	var shadow: float = 0.0      # tốc độ nếu không bị cản (đo thời gian mất do bám xe)
	var blocked: float = 0.0
	var last_move: float = 0.0
	var free_speed: float = 0.0
	var err_timer: float = 0.0
	var recover_until: float = -1.0
	var last_error_lap: int = -999
	var pass_target: int = -1
	var pass_until: float = -1.0
	var pass_extra: float = 0.0
	var laps_done: int = 0
	var lap_cum: float = 0.0
	var finished: bool = false
	var finish_time: float = 0.0
	# Log giải thích kết quả
	var errors: int = 0
	var error_loss: float = 0.0   # giây ước tính mất do lỗi
	var follow_loss: float = 0.0  # giây ước tính mất do bám xe
	var overtakes: int = 0
	var lap_times: Array = []


var T: Dictionary = {}           # sim.json (đã áp ghi đè nếu có)
var traits: Dictionary = {}
var track_id: String = ""
var sectors: Array = []
var cars: Array = []
var rng := RandomNumberGenerator.new()
var time: float = 0.0
var tick_count: int = 0
var finished: bool = false
var finish_order: Array = []
var race_seed: int = 0
var forced_finish: bool = false  # true nếu phải chốt cưỡng bức (lỗi mô phỏng)
var laps: int = 3
var lap_length: float = 400.0
var race_length: float = 1200.0
var tick: float = 0.1
var pass_time: float = 1.5
var _corner_ends: Array = []
var _ahead_gap: float = 0.0


## player_stats: S/H/B/A (xe) và P/T/C (tay đua) dạng tuyệt đối.
## opts: "driver_id" (đặc tính của người chơi), "tuning" (ghi đè sim.json cho lab).
func setup(p_seed: int, player_stats: Dictionary, league: int = 0, p_track_id: String = "track_harbor", opts: Dictionary = {}) -> void:
	race_seed = p_seed
	rng.seed = p_seed
	T = GameData.sim().duplicate(true)
	for k in opts.get("tuning", {}):
		T[k] = opts["tuning"][k]
	traits = T["traits"]
	laps = int(T["laps"])
	lap_length = float(T["lap_length"])
	race_length = lap_length * laps
	tick = float(T["tick"])
	pass_time = float(T["pass_time"])
	track_id = p_track_id
	sectors = GameData.sectors_of(track_id)
	_corner_ends.clear()
	var acc := 0.0
	for s: Array in sectors:
		acc += float(s[0])
		if bool(s[1]):
			_corner_ends.append(acc)

	var lg := GameData.league(league)
	var base_car := float(lg["car_base"])
	var base_drv := float(lg["driver_base"])

	cars.clear()
	var player := Car.new()
	player.id = 0
	player.number = 1
	player.driver_name = "Bạn"
	player.is_player = true
	player.dS = float(player_stats["S"]) - base_car
	player.dH = float(player_stats["H"]) - base_car
	player.dB = float(player_stats["B"]) - base_car
	player.dA = float(player_stats["A"]) - base_car
	player.dP = float(player_stats["P"]) - base_drv
	player.dT = float(player_stats["T"]) - base_drv
	player.dC = float(player_stats["C"]) - base_drv
	var drv_id: String = opts.get("driver_id", "")
	if drv_id != "":
		player.trait_id = String(GameData.driver(drv_id).get("trait", ""))
	cars.append(player)

	var offsets: Array = T["ai_offsets"]
	var names: Array = T["ai_names"]
	for i in offsets.size():
		var off := float(offsets[i])
		var c := Car.new()
		c.id = i + 1
		c.number = i + 2
		c.driver_name = String(names[i])
		c.dS = off
		c.dH = off
		c.dB = off
		c.dA = off
		c.dP = off
		c.dT = off
		c.dC = off
		cars.append(c)

	# Grid do seed xáo trộn; mọi xe vẫn chạy đủ race_length từ vị trí của mình.
	var slots: Array = range(cars.size())
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: int = slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	for k in cars.size():
		var c: Car = cars[k]
		c.grid_slot = slots[k]
		c.gp = -float(T["grid_gap"]) * float(c.grid_slot)
	# race_form: lấy đúng một lần mỗi xe trước xuất phát, giữ nguyên cả race.
	for c: Car in cars:
		var lo := float(T["form_min"])
		if c.trait_id == "golden":
			lo = float(traits["golden"]["form_min"])
		c.form = rng.randf_range(lo, float(T["form_max"]))


func abs_pos(c: Car) -> float:
	return c.gp + c.travel


func render_pos(c: Car, alpha: float) -> float:
	return c.gp + lerpf(c.prev_travel, c.travel, alpha)


func sector_at(pos: float) -> Array:
	var p := fposmod(pos, lap_length)
	var acc := 0.0
	for s: Array in sectors:
		acc += float(s[0])
		if p < acc:
			return s
	return sectors[sectors.size() - 1]


func _nearest_ahead(c: Car, exclude_id: int) -> Car:
	var best: Car = null
	var best_gap: float = INF
	var mine: float = c.gp + c.travel
	for o: Car in cars:
		if o == c or o.finished or o.id == exclude_id:
			continue
		var gap: float = fposmod(o.gp + o.travel - mine, lap_length)
		if gap < 0.0005 and o.id > c.id:
			# Hai xe trùng vị trí: xe id nhỏ hơn được coi là ở trước, tránh khóa chéo lẫn nhau.
			gap = lap_length
		if gap < best_gap:
			best_gap = gap
			best = o
	_ahead_gap = best_gap
	return best


func _has(c: Car, trait_name: String) -> bool:
	return c.trait_id == trait_name


func step() -> void:
	if finished:
		return
	var dt := tick
	var prev_time := time
	time += dt
	var follow_gap := float(T["follow_gap"])
	var min_gap := float(T["min_gap"])

	# Xử lý từ trước ra sau để không xuyên xe.
	var order: Array = []
	for c: Car in cars:
		if not c.finished:
			order.append(c)
	order.sort_custom(func(a: Car, b: Car) -> bool:
		var da: float = a.gp + a.travel
		var db: float = b.gp + b.travel
		if is_equal_approx(da, db):
			return a.id < b.id
		return da > db)

	var pass_targets := {}
	for c: Car in cars:
		if c.pass_target >= 0 and prev_time < c.pass_until:
			pass_targets[c.pass_target] = true
	var check_overtake: bool = (tick_count % int(T["overtake_interval_ticks"]) == 0)

	for c: Car in order:
		c.prev_travel = c.travel
		var pos := fposmod(c.gp + c.travel, lap_length)
		var sector: Array = sector_at(pos)
		var in_corner: bool = sector[1]
		var can_overtake_here: bool = sector[2]

		var straight: float = float(T["straight_base"]) + float(T["straight_per_speed"]) * c.dS \
			+ float(T["straight_per_pace"]) * c.dP
		if _has(c, "straight_line"):
			straight *= float(traits["straight_line"]["straight_mult"])
		var target: float = straight
		if in_corner:
			target = minf(straight, float(T["corner_base"]) + float(T["corner_per_handling"]) * c.dH \
				+ float(T["corner_per_technique"]) * c.dT)
			if _has(c, "smooth_corners"):
				target *= float(traits["smooth_corners"]["corner_mult"])
		target *= c.form
		if _has(c, "sprint") and c.laps_done >= laps - 1:
			target *= float(traits["sprint"]["last_lap_speed_mult"])
		var unfaulted := target
		if c.err_timer > 0.0:
			target *= float(T["error_speed_factor"])
			c.err_timer = maxf(0.0, c.err_timer - dt)
		c.free_speed = target

		var accel := maxf(float(T["accel_min"]), float(T["accel_base"]) + float(T["accel_per_accel"]) * c.dA)
		if _has(c, "fast_start") and time <= float(traits["fast_start"]["duration"]):
			accel *= float(traits["fast_start"]["accel_mult"])
		if _has(c, "recovery") and prev_time < c.recover_until:
			accel *= float(traits["recovery"]["accel_mult"])
		var rate := accel if target > c.speed else float(T["brake"])
		c.speed = move_toward(c.speed, target, rate * dt)
		c.shadow = move_toward(c.shadow, target, rate * dt)

		var passing: bool = prev_time < c.pass_until
		if not passing:
			c.pass_target = -1
		var front: Car = _nearest_ahead(c, c.pass_target if passing else -1)
		var gap: float = _ahead_gap

		# Thử vượt: trong vùng vượt, gap < follow_gap, nhanh hơn xe trước >= overtake_min_diff.
		if check_overtake and not passing and front != null and gap < follow_gap \
				and can_overtake_here and (c.free_speed - front.speed) >= float(T["overtake_min_diff"]) \
				and not pass_targets.has(front.id):
			var p := float(T["overtake_base"]) + float(T["overtake_per_technique"]) * (c.dT - front.dT)
			if _has(c, "hunter"):
				p += float(traits["hunter"]["overtake_bonus"])
			if _has(front, "defender"):
				p -= float(traits["defender"]["defend_bonus"])
			p = clampf(p, float(T["overtake_min"]), float(T["overtake_max"]))
			if rng.randf() < p:
				c.pass_target = front.id
				c.pass_until = prev_time + pass_time
				c.pass_extra = (gap + float(T["pass_lead"])) / pass_time
				c.overtakes += 1
				pass_targets[front.id] = true
				passing = true
				front = _nearest_ahead(c, c.pass_target)
				gap = _ahead_gap

		var move := (c.speed + (c.pass_extra if passing else 0.0)) * dt
		if front != null and gap < follow_gap and c.blocked < float(T["block_failsafe"]):
			var max_move := maxf(0.0, gap - min_gap + front.last_move)
			if move > max_move:
				move = max_move
				c.speed = minf(c.speed, move / dt)
		# Chốt an toàn: xe đứng yên quá lâu thì bỏ qua cản trong lượt này (không để race treo).
		if move <= 0.0001:
			c.blocked += dt
		else:
			c.blocked = 0.0
		c.follow_loss += maxf(0.0, c.shadow - c.speed) * dt / maxf(c.free_speed, 1.0)
		if unfaulted > target:
			c.error_loss += (unfaulted * dt - move) / unfaulted
		c.last_move = move

		# Kiểm tra lỗi một lần tại cuối mỗi sector cua; tối đa 1 lỗi mỗi vòng.
		var old_abs: float = c.gp + c.travel + lap_length
		var first_lap: bool = c.laps_done == 0
		c.travel += move
		var new_abs: float = old_abs + move
		for e: float in _corner_ends:
			var k_new := int(floor((new_abs - e) / lap_length))
			var k_old := int(floor((old_abs - e) / lap_length))
			if k_new > k_old:
				var cross_d: float = e + lap_length * k_new
				var lap_idx := int(floor((cross_d - 0.001) / lap_length))
				if lap_idx == c.last_error_lap:
					continue
				if first_lap and _has(c, "discipline"):
					continue
				var p_error := float(T["error_base"]) - float(T["error_per_stability"]) * c.dB \
					- float(T["error_per_composure"]) * c.dC
				if _has(c, "steady"):
					p_error *= float(traits["steady"]["error_prob_mult"])
				p_error = clampf(p_error, float(T["error_min"]), float(T["error_max"]))
				if rng.randf() < p_error:
					var dur := float(T["error_duration"])
					if _has(c, "calm"):
						dur *= float(traits["calm"]["error_duration_mult"])
					c.err_timer = dur
					c.errors += 1
					c.last_error_lap = lap_idx
					if _has(c, "recovery"):
						c.recover_until = prev_time + dur + float(traits["recovery"]["duration"])

		# Vòng đua và về đích (nội suy thời gian vượt mốc).
		while c.laps_done < laps and c.travel >= float(c.laps_done + 1) * lap_length:
			var boundary: float = float(c.laps_done + 1) * lap_length
			var frac := 1.0
			if c.travel > c.prev_travel:
				frac = clampf((boundary - c.prev_travel) / (c.travel - c.prev_travel), 0.0, 1.0)
			var t := prev_time + dt * frac
			c.lap_times.append(t - c.lap_cum)
			c.lap_cum = t
			c.laps_done += 1
		if c.laps_done >= laps:
			c.finished = true
			c.finish_time = c.lap_cum
			c.travel = race_length
			finish_order.append(c.id)

	tick_count += 1
	var all_done := true
	for c: Car in cars:
		if not c.finished:
			all_done = false
			break
	if time >= float(T["max_time"]) and not all_done:
		# Không kỳ vọng xảy ra: chốt cưỡng bức để cuộc đua luôn kết thúc.
		for c: Car in cars:
			if not c.finished:
				c.finished = true
				c.finish_time = time + (race_length - c.travel) / float(T["straight_base"])
				c.travel = race_length
				finish_order.append(c.id)
		all_done = true
		forced_finish = true
	if all_done:
		finished = true


## Chạy tới khi xong (dùng cho test, lab, công cụ debug).
func run_to_end() -> void:
	var guard := 0
	while not finished and guard < 100000:
		step()
		guard += 1


## Thứ hạng hiện tại: xe đã về đích theo thời gian, còn lại theo tổng quãng đường.
func ranking() -> Array:
	var done: Array = []
	var running: Array = []
	for c: Car in cars:
		if c.finished:
			done.append(c)
		else:
			running.append(c)
	done.sort_custom(func(a: Car, b: Car) -> bool:
		if is_equal_approx(a.finish_time, b.finish_time):
			return a.id < b.id
		return a.finish_time < b.finish_time)
	running.sort_custom(func(a: Car, b: Car) -> bool:
		var da: float = a.gp + a.travel
		var db: float = b.gp + b.travel
		if is_equal_approx(da, db):
			return a.id < b.id
		return da > db)
	return done + running


func player_car() -> Car:
	return cars[0]
