extends SceneTree
## Chạy: godot --headless --path . -s res://tests/sim_test.gd
## Kiểm tra mô phỏng đua v1.0: công thức, xác định, toàn vẹn, chống treo, đặc tính, cân bằng.

var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


## Chỉ số tuyệt đối ở giải 0 (nền 40) từ độ lệch.
func _stats(dS: float = 0.0, dH: float = 0.0, dB: float = 0.0, dA: float = 0.0, dP: float = 0.0, dT: float = 0.0, dC: float = 0.0) -> Dictionary:
	return {"S": 40.0 + dS, "H": 40.0 + dH, "B": 40.0 + dB, "A": 40.0 + dA, "P": 40.0 + dP, "T": 40.0 + dT, "C": 40.0 + dC}


func _run(seed_value: int, stats: Dictionary, league: int = 0, track: String = "track_harbor", opts: Dictionary = {}) -> RaceSim:
	var sim := RaceSim.new()
	sim.setup(seed_value, stats, league, track, opts)
	sim.run_to_end()
	return sim


func _pos(sim: RaceSim) -> int:
	return sim.ranking().find(sim.player_car()) + 1


func _avg_time(track: String, stats: Dictionary, n: int, seed0: int) -> float:
	var t := 0.0
	for i in n:
		t += _run(seed0 + i, stats, 0, track).player_car().finish_time
	return t / n


func _initialize() -> void:
	var T: Dictionary = GameData.sim()

	print("== Công thức tại nền giải (Δ = 0) ==")
	var base := RaceSim.new()
	base.setup(1, _stats(), 0)
	var me: RaceSim.Car = base.player_car()
	_check(me.dS == 0.0 and me.dH == 0.0 and me.dP == 0.0, "chỉ số bằng nền giải => Δ = 0")
	var straight: float = T["straight_base"] + T["straight_per_speed"] * me.dS + T["straight_per_pace"] * me.dP
	var corner: float = minf(straight, T["corner_base"] + T["corner_per_handling"] * me.dH + T["corner_per_technique"] * me.dT)
	var perr: float = clampf(T["error_base"] - T["error_per_stability"] * me.dB - T["error_per_composure"] * me.dC, T["error_min"], T["error_max"])
	_check(is_equal_approx(straight, 20.0), "straight_speed = 20")
	_check(is_equal_approx(corner, 18.0), "corner_speed = 18")
	_check(is_equal_approx(perr, 0.35), "p_error = 35% mỗi lần kiểm tra")
	var lg3 := RaceSim.new()
	lg3.setup(1, {"S": 86.0, "H": 86.0, "B": 86.0, "A": 86.0, "P": 56.0, "T": 56.0, "C": 56.0}, 3)
	_check(lg3.player_car().dS == 0.0 and lg3.player_car().dP == 0.0, "giải 3: chỉ số bằng nền giải 3 cũng cho Δ = 0")

	print("== Xác định theo seed ==")
	var a := _run(12345, _stats(), 0)
	var b := _run(12345, _stats(), 0)
	var same := true
	for i in a.cars.size():
		if not is_equal_approx(a.cars[i].finish_time, b.cars[i].finish_time):
			same = false
	_check(same, "cùng seed + chỉ số => cùng thời gian về đích")
	var c := _run(54321, _stats(), 0)
	var differ := false
	for i in a.cars.size():
		if not is_equal_approx(a.cars[i].finish_time, c.cars[i].finish_time):
			differ = true
	_check(differ, "khác seed => kết quả khác")

	print("== Toàn vẹn cuộc đua ==")
	var all_done := true
	var laps_ok := true
	for car: RaceSim.Car in a.cars:
		if not car.finished:
			all_done = false
		if car.lap_times.size() != 3:
			laps_ok = false
	_check(a.finished and all_done and laps_ok, "8 xe về đích, mỗi xe có 3 thời gian vòng")
	var rk := a.ranking()
	var sorted_ok := true
	for i in range(1, rk.size()):
		if rk[i].finish_time < rk[i - 1].finish_time:
			sorted_ok = false
	_check(sorted_ok, "xếp hạng theo thời gian về đích")

	print("== Chống treo (600 race: mọi track, mọi giải, build ngẫu nhiên) ==")
	var stuck := 0
	var zero_time := 0
	var probe := RandomNumberGenerator.new()
	probe.seed = 99
	var tracks := GameData.tracks()
	for s in 600:
		var lvl := probe.randi_range(0, 40)
		var st := _stats(probe.randi_range(-10, lvl), probe.randi_range(-10, lvl), probe.randi_range(-10, lvl),
			probe.randi_range(-10, lvl), probe.randi_range(-5, 20), probe.randi_range(-5, 20), probe.randi_range(-5, 20))
		var tid: String = tracks[probe.randi_range(0, tracks.size() - 1)]["id"]
		var sim2 := _run(50000 + s, st, 0, tid)
		if sim2.forced_finish:
			stuck += 1
		for car: RaceSim.Car in sim2.cars:
			if car.finish_time <= 0.0:
				zero_time += 1
	_check(stuck == 0, "không race nào phải chốt cưỡng bức")
	_check(zero_time == 0, "mọi xe đều có thời gian về đích > 0")

	print("== Đặc tính tay đua ==")
	var trait_ok := true
	for d: Dictionary in GameData.drivers():
		var sim3 := _run(777, _stats(), 0, "track_pine", {"driver_id": d["id"]})
		if sim3.forced_finish or sim3.player_car().finish_time <= 0.0:
			trait_ok = false
		if String(d["trait"]) != "" and sim3.player_car().trait_id != String(d["trait"]):
			trait_ok = false
	_check(trait_ok, "12 tay đua chạy được, đặc tính nạp đúng")

	print("== Phân phối (200 seed, nền giải 0, Harbor) ==")
	var hist := [0, 0, 0, 0, 0, 0, 0, 0]
	var total_time := 0.0
	for s in 200:
		var sim4 := _run(1000 + s, _stats(), 0)
		hist[_pos(sim4) - 1] += 1
		total_time += sim4.player_car().finish_time
	print("  vị trí P1..P8: ", hist, " · thời gian TB %.1f giây" % (total_time / 200.0))
	_check(total_time / 200.0 > 60.0 and total_time / 200.0 < 90.0, "race nền dài 60–90 giây")

	print("== Cân bằng: mỗi chỉ số xe +40 tiết kiệm ≥ 1,5 giây (Design/04 §3.1) ==")
	for tid in ["track_harbor", "track_pine", "track_city"]:
		var base_t := _avg_time(tid, _stats(), 30, 7000)
		var line := "  %s nền %.1fs |" % [tid, base_t]
		var worst := 99.0
		var deltas := {"Động cơ": _stats(40), "Lốp": _stats(0, 40), "Khung": _stats(0, 0, 40), "Hộp số": _stats(0, 0, 0, 40)}
		for k in deltas:
			var saved := base_t - _avg_time(tid, deltas[k], 30, 7000)
			worst = minf(worst, saved)
			line += " %s %.1fs" % [k, saved]
		print(line)
		_check(worst >= 1.5, "%s: chỉ số xe yếu nhất vẫn tiết kiệm ≥ 1,5 giây" % tid)
	var eng_h := _avg_time("track_harbor", _stats(), 30, 7000) - _avg_time("track_harbor", _stats(40), 30, 7000)
	var tyre_h := _avg_time("track_harbor", _stats(), 30, 7000) - _avg_time("track_harbor", _stats(0, 40), 30, 7000)
	var eng_c := _avg_time("track_city", _stats(), 30, 7000) - _avg_time("track_city", _stats(40), 30, 7000)
	var tyre_c := _avg_time("track_city", _stats(), 30, 7000) - _avg_time("track_city", _stats(0, 40), 30, 7000)
	_check(eng_h > tyre_h, "Harbor (75% thẳng): Động cơ có lợi hơn Lốp")
	_check(tyre_c > eng_c, "City (70% cua): Lốp có lợi hơn Động cơ")

	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)

