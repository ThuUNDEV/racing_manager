class_name TrafficSim
extends RefCounted
## Mô phỏng đua kiểu bảng xếp hạng có hình ảnh (Design/08 §10): xe KHÔNG cản nhau.
## Tốc độ mỗi xe chỉ do chỉ số, form và lỗi quyết định; thứ hạng là thứ tự tới vạch đích chung.
## Độ lệch ngang y chỉ để vẽ: bộ chọn làn tách các xe sát nhau, không phản hồi vào tốc độ hay quãng đường.
## Fixed tick 10 Hz, xác định theo seed (RNG chỉ dùng cho grid, form và lỗi); không dùng thời gian thực.
## Hai chế độ kết thúc: theo số vòng (mặc định, tham chiếu v1.0) hoặc THEO THỜI GIAN khi opts["duration"] > 0
## (Design/10): mọi xe chạy đến cùng một mốc, hạng = tổng tiến trình dọc đường `s` giảm dần, id tăng dần khi hòa.
## Công thức tốc độ thẳng/cua/lỗi giữ nguyên v1.0 (Design/04 §2); hệ số làn ở data/sim.json["traffic"].


class Car:
	var id: int = 0
	var number: int = 1
	var driver_name: String = ""
	var is_player: bool = false
	var trait_id: String = ""
	var dS: float = 0.0
	var dH: float = 0.0
	var dB: float = 0.0
	var dA: float = 0.0
	var dP: float = 0.0
	var dT: float = 0.0
	var dC: float = 0.0
	var dL: float = 0.0          # launch: gia tốc thoát cua (tay đua)
	var dR: float = 0.0          # braking: phanh muộn, tốc độ vào cua
	var dK: float = 0.0          # racecraft: độ mạnh thế vượt/giữ
	var dE: float = 0.0          # endurance: tốc độ hao stamina
	var style_id: String = ""    # phong cách đua (data/sim.json["styles"])
	var stamina: float = 100.0
	var mode: String = "balanced"  # "push" | "balanced" | "conserve"
	var mode_since: float = -100.0
	var form: float = 1.0
	var grid_slot: int = 0
	var s: float = 0.0           # vị trí dọc đường tính từ vạch (grid < 0)
	var start_s: float = 0.0     # vị trí ô xuất phát (để tính quãng đường đã chạy)
	var prev_s: float = 0.0
	var y: float = 0.0           # độ lệch ngang (đơn vị sim, dương = trái chiều chạy); chỉ để vẽ
	var prev_y: float = 0.0
	var vy: float = 0.0
	var ty: float = 0.0          # vị trí ngang mục tiêu theo làn
	var lane: int = 0            # làn đang nhắm tới: -1, 0, +1
	var home_lane: int = 0       # làn ưa thích khi không bị xe khác ép
	var speed: float = 0.0
	var free_speed: float = 0.0  # tốc độ mục tiêu sau mọi hiệu chỉnh (chỉ số, form, lỗi, đặc tính)
	var err_timer: float = 0.0
	var drift_until: float = -1.0
	var drift_dir: float = 0.0   # hướng dạt khi lỗi (dấu của y: ra phía ngoài cua vừa qua)
	var drift_pending: bool = false
	var recover_until: float = -1.0
	var last_error_lap: int = -999
	var laps_done: int = 0
	var lap_cum: float = 0.0
	var finished: bool = false
	var finish_time: float = 0.0
	var finish_tick: int = -1    # tick cán vạch (xe không lăn thêm trong chính tick đó)
	var errors: int = 0
	var error_loss: float = 0.0
	var overtakes: int = 0
	var lap_times: Array = []
	var passed: Dictionary = {}  # id xe đã vượt (mỗi cặp một lần)


var T: Dictionary = {}
var TR: Dictionary = {}
var traits: Dictionary = {}
var styles: Dictionary = {}
var DS: Dictionary = {}          # data/sim.json["driver_stats"]
var STA: Dictionary = {}         # data/sim.json["stamina"]
var track_id: String = ""
var defs: Array = []
var cars: Array = []
var rng := RandomNumberGenerator.new()
var time: float = 0.0
var tick_count: int = 0
var finished: bool = false
var finish_order: Array = []
var race_seed: int = 0
var duration: float = 0.0        # > 0: đua theo thời gian (giây sim); 0: đua theo số vòng
var sprint_window: float = 0.0   # thời gian hiệu lực của "nước rút" ở cuối lượt (đã giới hạn bằng duration)
var forced_finish: bool = false
var laps: int = 3
var lap_length: float = 400.0
var race_length: float = 1200.0
var tick: float = 0.1
## Hệ số tốc độ hiển thị (data/sim.json["traffic"]["speed_scale"]): nhân đều tốc độ, gia tốc, phanh và tốc độ ngang
## nên thứ hạng tương đối giữa các xe không đổi, chỉ nhịp đua nhanh hơn. RaceSim v1.0 không dùng.
var speed_scale: float = 1.0
## Hút gió (data/sim.json["traffic"]["draft_bonus"], "draft_len"): xe có xe khác phía trước trong draft_len thân xe
## được +draft_bonus tốc độ. Mặc định 0 = tắt (giữ nguyên tắc "tốc độ chỉ do chỉ số/form/lỗi" của Design/08 §10).
var draft_bonus: float = 0.0
var draft_len: float = 0.0
var L: float = 10.0             # chiều dài thân xe
var W: float = 5.5               # bề ngang thân xe
var _starts: PackedFloat32Array = PackedFloat32Array()
var _corner_ends: Array = []
var _corner_dirs: Array = []
var _order_ids: Array = []       # thứ tự xe ở tick trước (để đếm lượt vượt)
## Sự kiện để UI hiển thị (không ảnh hưởng mô phỏng, không dùng RNG): mỗi phần tử
## {"t": giờ sim, "type": "pass"|"error", "id": xe chính, "other": xe bị vượt (-1 nếu lỗi)}.
var events: Array = []
var _pair_cooldown: Dictionary = {}  # khóa cặp "a>b" -> giờ sim được báo lại (tránh nháy khi hai xe song song)


func setup(p_seed: int, player_stats: Dictionary, league: int = 0, p_track_id: String = "track_circuit_a", opts: Dictionary = {}) -> void:
	race_seed = p_seed
	rng.seed = p_seed
	T = GameData.sim().duplicate(true)
	for k in opts.get("tuning", {}):
		T[k] = opts["tuning"][k]
	TR = T["traffic"]
	for k in opts.get("traffic_tuning", {}):
		TR[k] = opts["traffic_tuning"][k]
	traits = T["traits"]
	styles = T.get("styles", {})
	DS = T.get("driver_stats", {})
	STA = T.get("stamina", {})
	speed_scale = float(TR.get("speed_scale", 1.0))
	draft_bonus = float(TR.get("draft_bonus", 0.0))
	draft_len = float(TR.get("draft_len", 0.0))
	laps = int(T["laps"])
	lap_length = GameData.lap_length_of(p_track_id)
	race_length = lap_length * laps
	tick = float(T["tick"])
	duration = float(opts.get("duration", 0.0))
	sprint_window = minf(float(opts.get("sprint_duration", 0.0)), duration) if duration > 0.0 else 0.0
	L = float(T["car_length"])
	W = float(T["car_width"])
	track_id = p_track_id
	defs = GameData.sector_defs(track_id)
	_starts = PackedFloat32Array()
	_corner_ends.clear()
	_corner_dirs.clear()
	var acc := 0.0
	for d: Dictionary in defs:
		_starts.append(acc)
		acc += float(d["len"])
		if bool(d["corner"]):
			_corner_ends.append(acc)
			_corner_dirs.append(float(d["dir"]))

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
	# 4 chỉ số tay đua mới: thiếu khóa (dữ liệu/checkpoint cũ) thì coi như bằng chuẩn giải.
	player.dL = float(player_stats.get("L", base_drv)) - base_drv
	player.dR = float(player_stats.get("R", base_drv)) - base_drv
	player.dK = float(player_stats.get("K", base_drv)) - base_drv
	player.dE = float(player_stats.get("E", base_drv)) - base_drv
	var drv_id: String = opts.get("driver_id", "")
	if drv_id != "":
		player.trait_id = String(GameData.driver(drv_id).get("trait", ""))
		player.style_id = String(GameData.driver(drv_id).get("style", ""))
	cars.append(player)

	# Bot: danh sách ai_cars (toàn cục, kịch bản) nếu có; không thì suy ra từ ai_offsets/ai_names (v1.0).
	var ai_specs: Array = _ai_specs()
	for i in ai_specs.size():
		var spec: Dictionary = ai_specs[i]
		var off := float(spec.get("offset", 0.0))
		var st: Dictionary = spec.get("stats", {})
		var c := Car.new()
		c.id = i + 1
		c.number = i + 2
		c.driver_name = String(spec["name"])
		c.trait_id = String(spec.get("trait", ""))
		c.dS = float(st.get("S", off))
		c.dH = float(st.get("H", off))
		c.dB = float(st.get("B", off))
		c.dA = float(st.get("A", off))
		c.dP = float(st.get("P", off))
		c.dT = float(st.get("T", off))
		c.dC = float(st.get("C", off))
		c.dL = float(st.get("L", off))
		c.dR = float(st.get("R", off))
		c.dK = float(st.get("K", off))
		c.dE = float(st.get("E", off))
		c.style_id = String(spec.get("style", ""))
		cars.append(c)

	# race_form: lấy đúng một lần mỗi xe trước xuất phát, giữ nguyên cả race.
	for c: Car in cars:
		c.stamina = float(STA.get("start", 100.0))
		var lo := float(T["form_min"])
		if c.trait_id == "golden":
			lo = float(traits["golden"]["form_min"])
		c.form = rng.randf_range(lo, float(T["form_max"]))
		# Giãn đoàn: khuếch đại độ lệch form quanh 1,0 (chỉ TrafficSim; RaceSim v1.0 giữ nguyên làm chuẩn).
		c.form = 1.0 + (c.form - 1.0) * float(TR.get("form_spread", 1.0))
		# Kịch bản: bot có "form" cố định thì ghi đè (vẫn bốc RNG ở trên để các xe khác không đổi).
		if c.id > 0 and ai_specs[c.id - 1].has("form"):
			c.form = float(ai_specs[c.id - 1]["form"])

	# Grid hai cột so le theo thời gian vòng phân hạng (ước tính từ chỉ số + nhiễu theo seed): xe mạnh xuất phát trước.
	var quali: Array = []
	for c: Car in cars:
		quali.append([_est_lap_time(c) + rng.randfn(0.0, float(TR["grid_noise"])), c.id])
	quali.sort()
	# Kịch bản: bot có "grid_slot" cố định nằm đúng ô đó (gỡ khỏi thứ tự phân hạng rồi chèn lại theo ô tăng dần;
	# ô là duy nhất nhờ kiểm tra dữ liệu). Các xe còn lại giữ thứ tự phân hạng của mình quanh các ô cố định.
	var pinned: Array = []
	for c: Car in cars:
		if c.id > 0 and ai_specs[c.id - 1].has("grid_slot"):
			pinned.append([int(ai_specs[c.id - 1]["grid_slot"]), c.id])
	if not pinned.is_empty():
		pinned.sort()
		for pin: Array in pinned:
			for qi in quali.size():
				if int(quali[qi][1]) == int(pin[1]):
					quali.remove_at(qi)
					break
		var pin_items: Dictionary = {}
		for c: Car in cars:
			pin_items[c.id] = [_est_lap_time(c), c.id]
		for pin: Array in pinned:
			quali.insert(clampi(int(pin[0]), 0, quali.size()), pin_items[int(pin[1])])
	if opts.has("player_slot"):
		# Dùng cho test/lab: đặt xe người chơi ở ô xuất phát cố định.
		var at := int(opts["player_slot"])
		for qi in quali.size():
			if int(quali[qi][1]) == 0:
				var item: Array = quali[qi]
				quali.remove_at(qi)
				quali.insert(clampi(at, 0, quali.size()), item)
				break
	for k in cars.size():
		var c: Car = cars[quali[k][1]]
		c.grid_slot = k
		var row: int = k / 2
		var col: int = k % 2
		c.s = -(float(row) * float(TR["grid_row_len"]) + float(col) * float(TR["grid_col_offset_len"])) * L
		c.prev_s = c.s
		c.start_s = c.s
		c.lane = 1 if col == 0 else -1
		c.home_lane = c.lane
		c.y = float(c.lane) * float(TR["grid_col_width"]) * W
		c.prev_y = c.y
		c.ty = c.y
	_order_ids = _rank_ids()


## Danh sách bot dùng cho cuộc đua: sim.json["ai_cars"] nếu có, không thì ghép ai_offsets + ai_names (mỗi bot một mức lệch chung).
## Mỗi phần tử: {"name", "offset"?, "stats"? {S,H,B,A,P,T,C: lệch so với chuẩn giải}, "trait"?, "form"?, "grid_slot"?}.
func _ai_specs() -> Array:
	var cfg: Variant = T.get("ai_cars", [])
	if typeof(cfg) == TYPE_ARRAY and not (cfg as Array).is_empty():
		return cfg
	var out: Array = []
	var offsets: Array = T["ai_offsets"]
	var names: Array = T["ai_names"]
	for i in offsets.size():
		out.append({"name": String(names[i]), "offset": float(offsets[i])})
	return out


## Thời gian vòng ước tính khi chạy tự do (dùng cho vòng phân hạng): tốc độ thẳng/cua theo chỉ số và form.
func _est_lap_time(c: Car) -> float:
	var straight: float = float(T["straight_base"]) + float(T["straight_per_speed"]) * c.dS + float(T["straight_per_pace"]) * c.dP
	var corner: float = minf(straight, float(T["corner_base"]) + float(T["corner_per_handling"]) * c.dH + float(T["corner_per_technique"]) * c.dT)
	var t := 0.0
	for d: Dictionary in defs:
		t += float(d["len"]) / ((corner if bool(d["corner"]) else straight) * c.form)
	return t


# ---------------------------------------------------------------- truy vấn

func render_pos(c: Car, alpha: float) -> float:
	return lerpf(c.prev_s, c.s, alpha)


func render_lat(c: Car, alpha: float) -> float:
	return lerpf(c.prev_y, c.y, alpha)


## Góc lệch của đầu xe so với tiếp tuyến đường (rad), theo hướng đang đi thật.
func render_yaw(c: Car) -> float:
	return atan2(-c.vy, maxf(c.speed, 1.0))


func player_car() -> Car:
	return cars[0]


func lap_of(c: Car) -> int:
	if duration > 0.0:
		return maxi(int(floor(c.s / lap_length)) + 1, 1)
	return clampi(int(floor(c.s / lap_length)) + 1, 1, laps)


## Quãng đường đã chạy từ ô xuất phát (đơn vị sim).
func distance_of(c: Car) -> float:
	return c.s - c.start_s


func is_timed() -> bool:
	return duration > 0.0


## Thời gian còn lại của lượt (chỉ khi đua theo thời gian).
func time_left() -> float:
	return maxf(0.0, duration - time)


func ranking() -> Array:
	if duration > 0.0:
		# Theo thời gian: tổng tiến trình `s` (đã gồm số vòng); xe xuất phát sau đã nằm sẵn ở s âm nên không cộng bù.
		var all: Array = cars.duplicate()
		all.sort_custom(func(a: Car, b: Car) -> bool:
			if is_equal_approx(a.s, b.s):
				return a.id < b.id
			return a.s > b.s)
		return all
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
		if is_equal_approx(a.s, b.s):
			return a.id < b.id
		return a.s > b.s)
	return done + running


func _rank_ids() -> Array:
	var out: Array = []
	for c: Car in ranking():
		out.append(c.id)
	return out


func sector_index(pos: float) -> int:
	var p := fposmod(pos, lap_length)
	for i in range(defs.size() - 1, -1, -1):
		if p >= _starts[i]:
			return i
	return 0


func width_at(pos: float) -> float:
	var p := fposmod(pos, lap_length)
	var i := sector_index(p)
	var d: Dictionary = defs[i]
	return lerpf(float(d["w0"]), float(d["w1"]), (p - _starts[i]) / float(d["len"]))


## Nửa khoảng ngang cho phép của tâm xe (bề rộng trừ một thân xe, chia đôi).
func half_range(pos: float) -> float:
	return maxf(0.0, width_at(pos) - 1.0) * W * 0.5


func _wrap(d: float) -> float:
	return fposmod(d + lap_length * 0.5, lap_length) - lap_length * 0.5


# ---------------------------------------------------------------- làn hiển thị

## Khoảng cách ngang giữa hai làn kề nhau tại vị trí pos (thu hẹp khi mặt đường hẹp).
func _lane_spacing(pos: float) -> float:
	return minf(float(TR["lane_spacing"]) * W, half_range(pos))


## Dịch nhẹ của đường chạy trong cua (ngoài–đỉnh–ngoài), giống nhau cho mọi làn nên không làm hai làn chạm nhau.
func _line_shift(pos: float) -> float:
	var p := fposmod(pos, lap_length)
	var i := sector_index(p)
	var d: Dictionary = defs[i]
	if not bool(d["corner"]):
		return 0.0
	var f := (p - _starts[i]) / float(d["len"])
	return -float(d["dir"]) * float(TR["line_shift"]) * W * cos(TAU * f)


## Xe o có đang chiếm làn lane (quanh xe c) không: đã nhắm làn đó hoặc đang nằm trên làn đó.
func _occupies(o: Car, lane: int, sp: float) -> bool:
	return o.lane == lane or absf(o.y - float(lane) * sp) < 0.55 * W


## Làn lane có trống quanh xe c không: không có xe nào chiếm làn đó trong cửa sổ dọc.
## Cửa sổ dài thêm theo tốc độ tiến lại gần (xe c sắp tới xe phía trước, hoặc xe phía sau sắp tới xe c).
func _lane_free(c: Car, lane: int, sp: float) -> bool:
	var base := float(TR["lane_gap_len"]) * L
	var look := float(TR["lane_look"])
	for o: Car in cars:
		if o == c or o.finished or not _occupies(o, lane, sp):
			continue
		var ds := _wrap(o.s - c.s)
		var closing := maxf(0.0, c.speed - o.speed) if ds >= 0.0 else maxf(0.0, o.speed - c.speed)
		if absf(ds) < base + closing * look:
			return false
	return true


## Xe c đang bị xe phía trước cùng làn ở quá gần (xe sau là bên phải nhường làn).
func _lane_conflict(c: Car, sp: float) -> bool:
	var base := float(TR["lane_gap_len"]) * L
	var look := float(TR["lane_look"])
	for o: Car in cars:
		if o == c or o.finished or not _occupies(o, c.lane, sp):
			continue
		var ds := _wrap(o.s - c.s)
		var ahead := ds > 0.0005 or (absf(ds) <= 0.0005 and o.id < c.id)
		if ahead and ds < base + maxf(0.0, c.speed - o.speed) * look:
			return true
	return false


func _plan_lane(c: Car) -> void:
	var sp := _lane_spacing(c.s)
	var decide: bool = (tick_count + c.id) % int(TR["decision_ticks"]) == 0
	var home := c.home_lane if c.s < float(TR["lane_home_fade"]) else 0
	if decide and not c.finished:
		if _lane_conflict(c, sp):
			# Nhường làn: sang làn kề còn trống, ưu tiên phía làn ưa thích rồi phía còn nhiều chỗ.
			var first := signi(home - c.lane)
			if first == 0:
				first = 1 if c.y <= 0.0 else -1
			for step_dir in [first, -first]:
				var cand: int = c.lane + int(step_dir)
				if absi(cand) <= 1 and _lane_free(c, cand, sp):
					c.lane = cand
					break
		elif c.lane != home and time >= c.drift_until:
			# Không bị ép: quay dần về làn ưa thích khi làn kề trống.
			var cand2: int = c.lane + signi(home - c.lane)
			if _lane_free(c, cand2, sp):
				c.lane = cand2
	# Lỗi: dạt sang làn kề phía ngoài cua vừa qua nếu làn đó trống (chỉ hình ảnh; không dạt vào xe khác).
	if c.drift_pending and decide:
		c.drift_pending = false
		if time < c.drift_until:
			var out_lane: int = clampi(c.lane + int(signf(c.drift_dir)), -1, 1)
			if out_lane != c.lane and _lane_free(c, out_lane, sp):
				c.lane = out_lane
	var hr := half_range(c.s)
	c.ty = clampf(float(c.lane) * sp + _line_shift(c.s), -hr, hr)


# ---------------------------------------------------------------- mô phỏng

## Hiệu ứng cục bộ của đặc tính theo xe lân cận (tính từ vị trí đầu tick, trước khi ai di chuyển).
func _neighbour_mult(c: Car) -> float:
	return _trait_mult(c) * _draft_mult(c) * _style_mult(c)


## Hệ số racecraft: nhân độ mạnh của mọi thế vượt/giữ (chase/defend) theo chỉ số racecraft.
func _racecraft_scale(c: Car) -> float:
	if DS.is_empty():
		return 1.0
	return clampf(1.0 + c.dK * float(DS["racecraft_bonus_per_point"]), float(DS["racecraft_scale_min"]), float(DS["racecraft_scale_max"]))


## Có xe nào đang chạy trong khoảng reach phía trước (ahead) hoặc phía sau (not ahead) c.
func _car_within(c: Car, reach: float, ahead: bool) -> bool:
	for o: Car in cars:
		if o == c or o.finished:
			continue
		var ds := _wrap(o.s - c.s)
		if ahead and ds > 0.0 and ds <= reach:
			return true
		if not ahead and ds < 0.0 and ds >= -reach:
			return true
	return false


## Phong cách đua (Late-brake attacker, Counterpuncher, Tactical defender): thưởng khi có xe sát trước/sau,
## nhân theo racecraft. Momentum rider chỉ tác động trong cua (xem _corner_style_mult).
func _style_mult(c: Car) -> float:
	var sd: Dictionary = styles.get(c.style_id, {})
	if sd.is_empty():
		return 1.0
	var reach := float(sd.get("range_len", 3.0)) * L
	var rc := _racecraft_scale(c)
	var m := 1.0
	if sd.has("chase_bonus") and _car_within(c, reach, true):
		m += float(sd["chase_bonus"]) * rc
	if sd.has("defend_bonus") and _car_within(c, reach, false):
		m += float(sd["defend_bonus"]) * rc
	return m


## Momentum rider: cua thoáng thì nhanh hơn, cua bị kẹp xe thì chậm hơn.
func _corner_style_mult(c: Car) -> float:
	var sd: Dictionary = styles.get(c.style_id, {})
	if sd.is_empty():
		return 1.0
	var m := float(sd.get("corner_mult", 1.0))
	if sd.has("clear_corner_bonus"):
		var reach := float(sd.get("clear_len", 4.0)) * L
		if _car_within(c, reach, true) or _car_within(c, reach, false):
			m *= 1.0 - float(sd.get("crowded_corner_penalty", 0.0))
		else:
			m *= 1.0 + float(sd["clear_corner_bonus"])
	return m


# ---------------------------------------------------------------- stamina

## Đang ở giai đoạn cuối cuộc đua (nước rút): được phép dồn sức.
func _in_final(c: Car, prev_time: float) -> bool:
	if duration > 0.0:
		return prev_time >= duration * (1.0 - float(STA.get("final_fraction", 0.2)))
	return c.laps_done >= laps - 1


## Chọn chế độ ga theo stamina và áp lực xung quanh; giữ tối thiểu mode_hold giây (composure càng cao càng giữ lâu).
func _update_mode(c: Car, prev_time: float) -> void:
	if STA.is_empty():
		return
	var pressure := _car_within(c, float(STA["pressure_len"]) * L, true) or _car_within(c, float(STA["pressure_len"]) * L, false)
	var final_lap := _in_final(c, prev_time)
	var want := "balanced"
	if c.stamina < float(STA["conserve_below"]) and not final_lap:
		want = "conserve"
	elif (pressure or final_lap) and c.stamina > float(STA["push_min"]):
		want = "push"
	if want == c.mode:
		return
	var hold := float(STA["mode_hold_base"]) * (1.0 + c.dC * float(STA["mode_hold_per_composure"]))
	hold *= float((styles.get(c.style_id, {}) as Dictionary).get("mode_hold_mult", 1.0))
	hold = clampf(hold, float(STA["mode_hold_min"]), float(STA["mode_hold_max"]))
	if c.stamina <= 0.0 or time - c.mode_since >= hold:
		c.mode = want
		c.mode_since = time


## Hao/hồi stamina trong dt giây theo chế độ ga; endurance giảm tốc độ hao.
func _drain_stamina(c: Car, dt: float) -> void:
	if STA.is_empty():
		return
	var drain_mult := 1.0
	if not DS.is_empty():
		drain_mult = clampf(1.0 - c.dE * float(DS["endurance_drain_per_point"]), float(DS["endurance_drain_min"]), float(DS["endurance_drain_max"]))
	match c.mode:
		"push":
			c.stamina -= float(STA["drain_push"]) * drain_mult * dt
		"conserve":
			c.stamina += float(STA["regen_conserve"]) * dt
		_:
			c.stamina -= float(STA["drain_balanced"]) * drain_mult * dt
	c.stamina = clampf(c.stamina, 0.0, float(STA.get("start", 100.0)))


func _stamina_mult(c: Car) -> float:
	if STA.is_empty():
		return 1.0
	var m := 1.0
	if c.mode == "push":
		m = float(STA["push_speed_mult"])
	elif c.mode == "conserve":
		m = float(STA["conserve_speed_mult"])
	var low := float(STA["fatigue_below"])
	if c.stamina < low:
		m *= 1.0 - float(STA["fatigue_max_penalty"]) * (low - c.stamina) / low
	return m


## Hút gió: có xe đang chạy phía trước trong draft_len thân xe (không tính trước khi qua vạch xuất phát).
func _draft_mult(c: Car) -> float:
	if draft_bonus <= 0.0 or c.s < 0.0:
		return 1.0
	var reach := draft_len * L
	for o: Car in cars:
		if o == c or o.finished:
			continue
		var ds := o.s - c.s
		if ds > 0.0 and ds <= reach:
			var dm := float((styles.get(c.style_id, {}) as Dictionary).get("draft_mult", 1.0))
			return 1.0 + draft_bonus * dm
	return 1.0


func _trait_mult(c: Car) -> float:
	if c.trait_id != "hunter" and c.trait_id != "defender":
		return 1.0
	var key := "range_len"
	var reach := float(traits[c.trait_id][key]) * L
	for o: Car in cars:
		if o == c or o.finished:
			continue
		var ds := _wrap(o.s - c.s)
		if c.trait_id == "hunter" and ds > 0.0 and ds <= reach:
			return 1.0 + float(traits["hunter"]["chase_bonus"])
		if c.trait_id == "defender" and ds < 0.0 and ds >= -reach:
			return 1.0 + float(traits["defender"]["defend_bonus"])
	return 1.0


func step() -> void:
	if finished:
		return
	var dt := tick
	if duration > 0.0:
		dt = minf(tick, duration - time)  # bước cuối đúng mốc hết giờ, kể cả khi không chia hết cho tick
	var prev_time := time
	time += dt

	# Hiệu ứng lân cận tính từ vị trí đầu tick cho mọi xe, để kết quả không phụ thuộc thứ tự xử lý.
	var near: Dictionary = {}
	for c: Car in cars:
		if not c.finished:
			near[c.id] = _neighbour_mult(c)

	var moved: Array = []
	for c: Car in cars:
		if c.finished:
			continue
		c.prev_s = c.s
		c.prev_y = c.y
		if c.s >= 0.0:  # stamina chỉ hao khi đã qua vạch xuất phát
			_update_mode(c, prev_time)
			_drain_stamina(c, dt)
		var pos := fposmod(c.s, lap_length)
		var si := sector_index(pos)
		var in_corner: bool = defs[si]["corner"]

		var straight: float = float(T["straight_base"]) + float(T["straight_per_speed"]) * c.dS \
			+ float(T["straight_per_pace"]) * c.dP
		if c.trait_id == "straight_line":
			straight *= float(traits["straight_line"]["straight_mult"])
		var target: float = straight
		if in_corner:
			target = minf(straight, float(T["corner_base"]) + float(T["corner_per_handling"]) * c.dH \
				+ float(T["corner_per_technique"]) * c.dT)
			if c.trait_id == "smooth_corners":
				target *= float(traits["smooth_corners"]["corner_mult"])
			if not DS.is_empty():
				target *= 1.0 + c.dR * float(DS["braking_corner_per_point"])
			target *= _corner_style_mult(c)
		target *= c.form * float(near[c.id]) * _stamina_mult(c) * speed_scale
		if c.trait_id == "sprint":
			var sprinting: bool = c.laps_done >= laps - 1
			if duration > 0.0:  # theo thời gian: nước rút ở những giây cuối lượt
				sprinting = sprint_window > 0.0 and prev_time >= duration - sprint_window
			if sprinting:
				target *= float(traits["sprint"]["last_lap_speed_mult"])
		var unfaulted := target
		if c.err_timer > 0.0:
			target *= float(T["error_speed_factor"])
			c.err_timer = maxf(0.0, c.err_timer - dt)
		c.free_speed = target

		var accel_stat: float = float(T["accel_per_accel"]) * c.dA
		if not DS.is_empty():
			accel_stat += float(DS["launch_accel_per_point"]) * c.dL
		var accel := maxf(float(T["accel_min"]), float(T["accel_base"]) + accel_stat) * speed_scale
		accel *= float((styles.get(c.style_id, {}) as Dictionary).get("accel_mult", 1.0))
		if c.trait_id == "fast_start" and time <= float(traits["fast_start"]["duration"]):
			accel *= float(traits["fast_start"]["accel_mult"])
		if c.trait_id == "recovery" and prev_time < c.recover_until:
			accel *= float(traits["recovery"]["accel_mult"])
		var brake_rate: float = float(T["brake"])
		if not DS.is_empty():
			brake_rate = maxf(1.0, brake_rate + float(DS["braking_brake_per_point"]) * c.dR)
		var rate := accel if target > c.speed else brake_rate * speed_scale
		c.speed = move_toward(c.speed, target, rate * dt)

		var move := c.speed * dt
		if unfaulted > target:
			c.error_loss += (unfaulted * dt - move) / unfaulted

		# Kiểm tra lỗi một lần tại cuối mỗi sector cua; tối đa 1 lỗi mỗi vòng (giữ nguyên v1.0).
		var old_abs: float = c.s + lap_length
		var first_lap: bool = c.laps_done == 0
		c.s += move
		var new_abs: float = old_abs + move
		for ei in _corner_ends.size():
			var e: float = _corner_ends[ei]
			var k_new := int(floor((new_abs - e) / lap_length))
			var k_old := int(floor((old_abs - e) / lap_length))
			if k_new > k_old:
				var cross_d: float = e + lap_length * k_new
				var lap_idx := int(floor((cross_d - 0.001) / lap_length))
				if lap_idx == c.last_error_lap:
					continue
				if first_lap and c.trait_id == "discipline":
					continue
				var p_error := float(T["error_base"]) - float(T["error_per_stability"]) * c.dB \
					- float(T["error_per_composure"]) * c.dC
				if c.trait_id == "steady":
					p_error *= float(traits["steady"]["error_prob_mult"])
				p_error = clampf(p_error, float(T["error_min"]), float(T["error_max"]))
				if rng.randf() < p_error:
					var dur := float(T["error_duration"])
					if c.trait_id == "calm":
						dur *= float(traits["calm"]["error_duration_mult"])
					c.err_timer = dur
					c.errors += 1
					c.last_error_lap = lap_idx
					events.append({"t": time, "type": "error", "id": c.id, "other": -1})
					# Lỗi nhỏ: lệch ra phía ngoài cua vừa qua, thấy được nguyên nhân mất hạng.
					c.drift_until = prev_time + dur
					c.drift_dir = -float(_corner_dirs[ei])
					c.drift_pending = true
					if c.trait_id == "recovery":
						c.recover_until = prev_time + dur + float(traits["recovery"]["duration"])

		# Mốc vòng và vạch đích chung (nội suy thời gian cán vạch).
		while (duration > 0.0 or c.laps_done < laps) and c.s >= float(c.laps_done + 1) * lap_length:
			var boundary: float = float(c.laps_done + 1) * lap_length
			var frac := 1.0
			if c.s > c.prev_s:
				frac = clampf((boundary - c.prev_s) / (c.s - c.prev_s), 0.0, 1.0)
			var t := prev_time + dt * frac
			c.lap_times.append(t - c.lap_cum)
			c.lap_cum = t
			c.laps_done += 1
		if duration <= 0.0 and c.laps_done >= laps:
			c.finished = true
			c.finish_time = c.lap_cum
			c.finish_tick = tick_count
			finish_order.append(c.id)
		else:
			moved.append(c)

	# Làn hiển thị: xử lý theo id (cars đã theo id) để mỗi xe thấy lựa chọn của xe trước nó trong cùng tick.
	var step_y := float(TR["lat_speed"]) * speed_scale * dt
	for c: Car in moved:
		_plan_lane(c)
		var ny := c.y + clampf(c.ty - c.y, -step_y, step_y)
		c.vy = (ny - c.y) / dt
		c.y = ny

	_roll_out_finished(dt)
	_count_overtakes()

	tick_count += 1
	if duration > 0.0:
		# Hết giờ: khóa kết quả mọi xe cùng thời điểm, không đợi xe nào cán vạch.
		if duration - time < 0.000001:
			time = duration
			finished = true
		return
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
				c.finish_time = time + (race_length - c.s) / float(T["straight_base"])
				finish_order.append(c.id)
		all_done = true
		forced_finish = true
	if all_done:
		finished = true


## Xe đã cán vạch tiếp tục lăn ra mép đường rồi chậm dần; không ảnh hưởng xe chưa xong.
func _roll_out_finished(dt: float) -> void:
	for c: Car in cars:
		if not c.finished or c.finish_tick == tick_count:
			continue
		c.prev_s = c.s
		c.prev_y = c.y
		if c.s >= race_length + 60.0:
			c.speed = 0.0
			c.vy = 0.0
			continue
		c.speed = move_toward(c.speed, float(TR["exit_speed"]) * speed_scale, float(TR["exit_decel"]) * speed_scale * dt)
		c.s += c.speed * dt
		var hr := half_range(c.s)
		var lat := float(TR["lat_speed"]) * speed_scale * dt
		var ny := c.y + clampf(-hr - c.y, -lat, lat)
		c.vy = (ny - c.y) / dt
		c.y = ny


## Chỉ ghi nhận lượt vượt khi thứ hạng thực sự đổi (mỗi cặp một lần mỗi cuộc).
func _count_overtakes() -> void:
	var now := _rank_ids()
	for i in now.size():
		var a: Car = cars[now[i]]
		var was_i: int = _order_ids.find(a.id)
		for j in range(i + 1, now.size()):
			var b: Car = cars[now[j]]
			var was_j: int = _order_ids.find(b.id)
			if was_i > was_j:
				if not a.passed.has(b.id):
					a.passed[b.id] = true
					a.overtakes += 1
				# Báo sự kiện cho mỗi lần đổi chỗ thật giữa hai xe còn đang chạy, có thời gian chờ theo cặp.
				if not a.finished and not b.finished:
					var key := "%d>%d" % [a.id, b.id]
					if time >= float(_pair_cooldown.get(key, -1.0)):
						_pair_cooldown[key] = time + 4.0
						_pair_cooldown["%d>%d" % [b.id, a.id]] = time + 4.0
						events.append({"t": time, "type": "pass", "id": a.id, "other": b.id})
	_order_ids = now


func run_to_end() -> void:
	var guard := 0
	while not finished and guard < 100000:
		step()
		guard += 1
