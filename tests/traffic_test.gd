extends SceneTree
## Chạy: godot --headless --path . -s res://tests/traffic_test.gd
## Kiểm tra TrafficSim theo Design/08 §10: xác định, vạch đích chung, xe trong mặt đường, chuyển động liên tục,
## làn hiển thị (chồng hình hiếm), xe nhanh hơn tự vượt, đặc tính lân cận, hình học track.

var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _stats(d: Array = [0, 0, 0, 0, 0, 0, 0]) -> Dictionary:
	return {"S": 40.0 + d[0], "H": 40.0 + d[1], "B": 40.0 + d[2], "A": 40.0 + d[3],
		"P": 40.0 + d[4], "T": 40.0 + d[5], "C": 40.0 + d[6]}


func _new(seed_value: int, stats: Dictionary, track: String, opts: Dictionary = {}) -> TrafficSim:
	var sim := TrafficSim.new()
	sim.setup(seed_value, stats, 0, track, opts)
	return sim


func _initialize() -> void:
	var tracks := GameData.tracks()

	print("== Hình học Circuit A ==")
	var lay := TrackLayout.build("track_circuit_a")
	_check(lay.valid, "dựng được hình học từ dữ liệu")
	_check(lay.closure_error < 0.05, "đường khép kín (sai số %.4f đơn vị)" % lay.closure_error)
	_check(absf(absf(lay.total_turn) - 360.0) < 0.001, "tổng góc rẽ 360°")
	var road: float = 4.0 * float(GameData.sim()["car_width"])
	_check(lay.min_clearance() > road * 1.3, "hai đoạn đường cách nhau %.1f > %.1f" % [lay.min_clearance(), road * 1.3])
	_check(lay.bounds.size.x > 100.0 and lay.bounds.size.y > 50.0, "kích thước %.0f × %.0f đơn vị" % [lay.bounds.size.x, lay.bounds.size.y])

	print("== Hình học Circuit B (đường dài, uốn lượn; prototype dùng) ==")
	var lb := TrackLayout.build("track_circuit_b")
	_check(lb.valid, "dựng được hình học từ dữ liệu")
	_check(is_equal_approx(lb.lap_length, 924.0) and lb.count() == 924, "vòng đường 924 đơn vị riêng của track (%d điểm)" % lb.count())
	_check(lb.closure_error < 0.05, "đường khép kín (sai số %.4f đơn vị)" % lb.closure_error)
	_check(absf(absf(lb.total_turn) - 360.0) < 0.001, "tổng góc rẽ 360°")
	_check(lb.min_clearance() > road * 1.3, "hai đoạn đường cách nhau %.1f > %.1f" % [lb.min_clearance(), road * 1.3])
	_check(lb.bounds.size.x / lb.bounds.size.y < 1.4 and lb.bounds.size.y > 150.0, "khung gần vuông, đủ cao cho màn hình dọc (%.0f × %.0f)" % [lb.bounds.size.x, lb.bounds.size.y])
	var turn_signs := 0
	var last_sign := 0.0
	for d: Dictionary in GameData.sector_defs("track_circuit_b"):
		if bool(d["corner"]) and signf(float(d["turn"])) != last_sign:
			turn_signs += 1
			last_sign = signf(float(d["turn"]))
	_check(turn_signs >= 8, "đường uốn lượn: đổi chiều cua %d lần" % (turn_signs - 1))
	var tb := _new(777, _stats(), "track_circuit_b", {"duration": 40.0, "sprint_duration": 10.0})
	tb.run_to_end()
	_check(is_equal_approx(tb.lap_length, 924.0) and tb.ranking()[0].s > 924.0 * 0.9, "lượt 40 giây chạy được khoảng một vòng 924 (xe đầu %.0f)" % tb.ranking()[0].s)

	print("== Bot kịch bản (ai_cars) ==")
	var plain_ai := _new(31, _stats(), "track_circuit_a")
	# ai_cars (dải lồi, TrafficSim) tách khỏi ai_offsets (RaceSim v1.0 giữ làm chuẩn): so với offset trong ai_cars.
	var scn_default: Array = GameData.sim()["ai_cars"]
	var legacy_ok := true
	for i in scn_default.size():
		var bc: TrafficSim.Car = plain_ai.cars[i + 1]
		var off := float(scn_default[i]["offset"])
		legacy_ok = legacy_ok and is_equal_approx(bc.dS, off) and is_equal_approx(bc.dH, off) and is_equal_approx(bc.dB, off) 			and is_equal_approx(bc.dA, off) and is_equal_approx(bc.dP, off) and is_equal_approx(bc.dT, off) and is_equal_approx(bc.dC, off) 			and bc.trait_id == "" and String(bc.driver_name) == String(GameData.sim()["ai_names"][i])
	_check(legacy_ok, "ai_cars mặc định (offset) giống hệt cách cũ: chỉ số, tên, không đặc tính")
	var scn_cfg: Array = GameData.sim()["ai_cars"].duplicate(true)
	scn_cfg[0] = {"name": "Rồng", "offset": 0, "stats": {"S": 12, "H": -9, "B": -6}, "trait": "straight_line", "form": 1.021, "grid_slot": 5}
	scn_cfg[1] = {"name": "Rùa", "stats": {"A": 7}, "grid_slot": 0}
	var scn_a := _new(31, _stats(), "track_circuit_a", {"tuning": {"ai_cars": scn_cfg}})
	var dragon: TrafficSim.Car = scn_a.cars[1]
	var turtle: TrafficSim.Car = scn_a.cars[2]
	_check(dragon.driver_name == "Rồng" and is_equal_approx(dragon.dS, 12.0) and is_equal_approx(dragon.dH, -9.0) and is_equal_approx(dragon.dB, -6.0) 		and is_equal_approx(dragon.dP, 0.0) and is_equal_approx(dragon.dT, 0.0), "bot kịch bản: tên và chỉ số riêng từng loại, chỉ số không khai báo = offset (0)")
	_check(dragon.trait_id == "straight_line" and is_equal_approx(turtle.dA, 7.0) and turtle.trait_id == "", "bot kịch bản: đặc tính riêng; bot không khai trait thì trống")
	_check(is_equal_approx(dragon.form, 1.021), "bot kịch bản: form cố định ghi đè")
	_check(dragon.grid_slot == 5 and turtle.grid_slot == 0, "bot kịch bản: ô xuất phát cố định (%d và %d)" % [dragon.grid_slot, turtle.grid_slot])
	var other_same := true
	for i in range(3, plain_ai.cars.size()):
		other_same = other_same and is_equal_approx(plain_ai.cars[i].form, scn_a.cars[i].form)
	_check(other_same, "ghi đè form một bot không làm đổi form các bot khác (RNG giữ nguyên thứ tự)")
	scn_a.run_to_end()
	var scn_b := _new(31, _stats(), "track_circuit_a", {"tuning": {"ai_cars": scn_cfg}})
	scn_b.run_to_end()
	var scn_same := true
	for i in scn_a.cars.size():
		scn_same = scn_same and is_equal_approx(scn_a.cars[i].finish_time, scn_b.cars[i].finish_time)
	_check(scn_same, "kịch bản vẫn xác định theo seed")

	print("== Xác định theo seed ==")
	var a := _new(4242, _stats(), "track_circuit_a")
	a.run_to_end()
	var b := _new(4242, _stats(), "track_circuit_a")
	b.run_to_end()
	var same := true
	for i in a.cars.size():
		var ca: TrafficSim.Car = a.cars[i]
		var cb: TrafficSim.Car = b.cars[i]
		if not (is_equal_approx(ca.finish_time, cb.finish_time) and is_equal_approx(ca.s, cb.s) and is_equal_approx(ca.y, cb.y) \
				and ca.overtakes == cb.overtakes and ca.errors == cb.errors):
			same = false
	_check(same, "cùng seed + chỉ số + dữ liệu => cùng thời gian, vị trí, quỹ đạo")
	var c := _new(4243, _stats(), "track_circuit_a")
	c.run_to_end()
	var differ := false
	for i in a.cars.size():
		if not is_equal_approx(a.cars[i].finish_time, c.cars[i].finish_time):
			differ = true
	_check(differ, "khác seed => kết quả khác")

	print("== Toàn vẹn, vạch đích chung, thời gian vòng ==")
	var integ := true
	var ordered := true
	var laps_ok := true
	var line_ok := true
	for seed_value in [11, 12, 13, 14, 15, 16]:
		var sim := _new(seed_value, _stats(), "track_circuit_a")
		var guard := 0
		while not sim.finished and guard < 5000:
			sim.step()
			guard += 1
			for car: TrafficSim.Car in sim.cars:
				if car.finish_tick == sim.tick_count - 1:
					# Tick cán vạch: trước vạch, sau vạch; thời gian nằm trong tick đó.
					if not (car.prev_s < sim.race_length + 0.0001 and car.s >= sim.race_length - 0.0001):
						line_ok = false
					if not (car.finish_time > sim.time - sim.tick - 0.0001 and car.finish_time <= sim.time + 0.0001):
						line_ok = false
		for car: TrafficSim.Car in sim.cars:
			if not car.finished or car.finish_time <= 0.0:
				integ = false
			if car.lap_times.size() != 3:
				laps_ok = false
			else:
				var sum := 0.0
				for t: float in car.lap_times:
					sum += t
				if absf(sum - car.finish_time) > 0.001:
					laps_ok = false
		var rk := sim.ranking()
		for i in range(1, rk.size()):
			if rk[i].finish_time < rk[i - 1].finish_time:
				ordered = false
		if sim.forced_finish:
			integ = false
	_check(integ, "8 xe về đích, thời gian > 0, không chốt cưỡng bức")
	_check(laps_ok, "mỗi xe có 3 thời gian vòng, cộng bằng thời gian về đích")
	_check(ordered, "xếp hạng theo thời gian cán vạch")
	_check(line_ok, "mọi xe cán đúng vạch đích chung (s ≥ 1.200 trong tick ghi thời gian)")

	print("== Từng tick: trong mặt đường, chuyển động liên tục, chồng hình hiếm ==")
	var off_road := 0
	var max_off := 0.0
	var max_decel := 0.0
	var max_accel := 0.0
	var max_dy := 0.0
	var max_jump := 0.0
	var car_ticks := 0
	var overlap_ticks := 0
	var tick_total := 0
	var probe := RandomNumberGenerator.new()
	probe.seed = 77
	var T: Dictionary = GameData.sim()
	var scale := float(T["traffic"].get("speed_scale", 1.0))  # TrafficSim nhân đều tốc độ, gia tốc, phanh, tốc độ ngang
	# Phanh tối đa gồm cả chỉ số braking của tay đua (bot lệch tối đa theo ai_cars so với chuẩn giải, tối thiểu +4).
	var max_bot_off := 4.0
	for bot: Dictionary in T["ai_cars"]:
		max_bot_off = maxf(max_bot_off, float(bot.get("offset", 0.0)))
	var brake: float = (float(T["brake"]) + float(T["driver_stats"]["braking_brake_per_point"]) * max_bot_off) * scale
	for r in 36:
		var lvl := probe.randi_range(0, 30)
		var st := _stats([probe.randi_range(-10, lvl), probe.randi_range(-10, lvl), probe.randi_range(-10, lvl),
			probe.randi_range(-10, lvl), probe.randi_range(-5, 15), probe.randi_range(-5, 15), probe.randi_range(-5, 15)])
		var tid: String = tracks[probe.randi_range(0, tracks.size() - 1)]["id"] if r >= 12 else "track_circuit_a"
		var sim := _new(3000 + r, st, tid)
		var prev := {}
		var guard := 0
		while not sim.finished and guard < 5000:
			sim.step()
			guard += 1
			tick_total += 1
			for p: TrafficSim.Car in sim.cars:
				if p.finished:
					prev.erase(p.id)
					continue
				var hr := sim.half_range(p.s)
				var over := absf(p.y) - hr
				if over > 0.01:
					off_road += 1
					max_off = maxf(max_off, over)
				if prev.has(p.id):
					var pv: Array = prev[p.id]
					max_decel = maxf(max_decel, (float(pv[0]) - p.speed) / sim.tick)
					max_accel = maxf(max_accel, (p.speed - float(pv[0])) / sim.tick)
					max_dy = maxf(max_dy, absf(p.y - float(pv[1])) / sim.tick)
					max_jump = maxf(max_jump, (p.s - float(pv[2])) / sim.tick)
				prev[p.id] = [p.speed, p.y, p.s]
				car_ticks += 1
				for q: TrafficSim.Car in sim.cars:
					if q == p or q.finished:
						continue
					var ds := absf(fposmod(q.s - p.s + sim.lap_length * 0.5, sim.lap_length) - sim.lap_length * 0.5)
					if ds < sim.L * 0.999 and absf(p.y - q.y) < sim.W * 0.999:
						overlap_ticks += 1
						break
	var overlap_share := float(overlap_ticks) / float(maxi(car_ticks, 1))
	print("  (%d tick) chồng hình %.2f%% thời gian xe · ra khỏi mặt đường %d (tối đa %.2f) · giảm tốc tối đa %.1f · tăng tốc tối đa %.1f · tốc độ ngang tối đa %.1f · bước dọc tối đa %.1f" % [
		tick_total, 100.0 * overlap_share, off_road, max_off, max_decel, max_accel, max_dy, max_jump])
	_check(overlap_share <= 0.10, "chồng hình hiếm: %.2f%% thời gian xe (≤ 10%%; mục tiêu thiết kế 5%%)" % (100.0 * overlap_share))
	_check(max_off <= 0.5, "xe nằm trong mặt đường (lệch ra tối đa %.2f đơn vị)" % max_off)
	_check(max_decel <= brake * 1.01, "giảm tốc không vượt phanh tối đa (%.1f ≤ %.1f)" % [max_decel, brake])
	_check(max_accel <= 8.0 * scale, "tăng tốc không nhảy vọt (%.1f)" % max_accel)
	_check(max_dy <= float(GameData.sim()["traffic"]["lat_speed"]) * scale + 0.01, "tốc độ ngang không vượt giới hạn (%.2f)" % max_dy)
	_check(max_jump <= 30.0 * scale, "không nhảy vị trí giữa hai tick (%.1f đơn vị/s)" % max_jump)

	print("== Mọi track, mọi build: race luôn kết thúc (150 race) ==")
	var forced := 0
	var zero_time := 0
	for s in 150:
		var lvl2 := probe.randi_range(0, 40)
		var st2 := _stats([probe.randi_range(-10, lvl2), probe.randi_range(-10, lvl2), probe.randi_range(-10, lvl2),
			probe.randi_range(-10, lvl2), probe.randi_range(-5, 20), probe.randi_range(-5, 20), probe.randi_range(-5, 20)])
		var tid2: String = tracks[probe.randi_range(0, tracks.size() - 1)]["id"]
		var sim2 := _new(50000 + s, st2, tid2)
		sim2.run_to_end()
		if sim2.forced_finish:
			forced += 1
		for car: TrafficSim.Car in sim2.cars:
			if car.finish_time <= 0.0:
				zero_time += 1
	_check(forced == 0, "không race nào phải chốt cưỡng bức")
	_check(zero_time == 0, "mọi xe đều có thời gian về đích > 0")

	print("== Vượt xe: xe nhanh hơn tự vượt (Design/08 §10.3) ==")
	var swaps_total := 0
	var base_same := 0
	var races := 30
	for s in races:
		var simb := _new(6000 + s, _stats(), "track_circuit_a")
		simb.run_to_end()
		for car: TrafficSim.Car in simb.cars:
			swaps_total += car.overtakes
		var rk2 := simb.ranking()
		for i in rk2.size():
			if rk2[i].grid_slot == i:
				base_same += 1
	var avg_swaps := float(swaps_total) / float(races)
	var avg_same := float(base_same) / float(races)
	print("  race nền: %.1f lượt đổi chỗ · %.2f/8 xe về đúng ô xuất phát" % [avg_swaps, avg_same])
	_check(avg_swaps >= 10.0, "thứ hạng thay đổi trong race (TB %.1f cặp đổi chỗ ≥ 10)" % avg_swaps)
	_check(avg_same <= 4.0, "kết quả không bị khóa theo ô xuất phát (TB %.2f/8 ≤ 4,0)" % avg_same)

	var wins := 0
	var final_pos := 0
	var strong_races := 16
	for s in strong_races:
		var sim3 := _new(8000 + s, _stats([30, 30, 30, 30, 10, 10, 10]), "track_circuit_a", {"player_slot": 7})
		sim3.run_to_end()
		final_pos += sim3.ranking().find(sim3.player_car()) + 1
		if sim3.ranking()[0] == sim3.player_car():
			wins += 1
	var avg_final := float(final_pos) / float(strong_races)
	print("  build mạnh xuất phát cuối: về hạng TB %.2f · thắng %d/%d" % [avg_final, wins, strong_races])
	_check(avg_final <= 4.0, "build mạnh hơn nhiều xuất phát cuối lên được ≥ 4 hạng (về hạng TB %.2f)" % avg_final)
	_check(wins >= strong_races / 2, "build mạnh hơn nhiều thắng ít nhất một nửa số race (%d/%d)" % [wins, strong_races])

	print("== Đặc tính tay đua ==")
	var trait_ok := true
	for d: Dictionary in GameData.drivers():
		var simd := _new(777, _stats(), "track_circuit_a", {"driver_id": d["id"]})
		simd.run_to_end()
		if simd.forced_finish or simd.player_car().finish_time <= 0.0:
			trait_ok = false
		if String(d["trait"]) != "" and simd.player_car().trait_id != String(d["trait"]):
			trait_ok = false
	_check(trait_ok, "12 tay đua chạy được trên Circuit A, đặc tính nạp đúng")
	# hunter/defender chỉ là hiệu ứng lân cận nhỏ (≤ ~1 giây/race): so với cùng seed không đặc tính.
	for tr_id in ["hunter", "defender"]:
		var drv := ""
		for d: Dictionary in GameData.drivers():
			if String(d["trait"]) == tr_id:
				drv = String(d["id"])
		var gain := 0.0
		for s in 20:
			var plain := _new(9000 + s, _stats(), "track_circuit_a")
			plain.run_to_end()
			var with_t := _new(9000 + s, _stats(), "track_circuit_a", {"driver_id": drv})
			with_t.run_to_end()
			gain += plain.player_car().finish_time - with_t.player_car().finish_time
		gain /= 20.0
		print("  %s: tiết kiệm TB %.2f s/race" % [tr_id, gain])
		_check(drv != "" and gain > -0.5 and gain <= 1.5, "%s là hiệu ứng nhỏ, không âm đáng kể (TB %.2f s)" % [tr_id, gain])

	print("== Công thức tốc độ giữ nguyên v1.0 tại nền giải ==")
	var base := _new(1, _stats(), "track_harbor")
	var me: TrafficSim.Car = base.player_car()
	_check(me.dS == 0.0 and me.dH == 0.0 and me.dP == 0.0, "chỉ số bằng nền giải => Δ = 0")
	var solo := _new(5, _stats(), "track_circuit_a")
	solo.run_to_end()
	var avg := 0.0
	for car: TrafficSim.Car in solo.cars:
		avg += car.finish_time
	avg /= solo.cars.size()
	var sc := float(GameData.sim()["traffic"].get("speed_scale", 1.0))
	_check(avg > 60.0 / sc and avg < 115.0 / sc, "race nền 3 vòng dài %.0f–%.0f giây (TB %.1f)" % [60.0 / sc, 115.0 / sc, avg])

	print("== Đua theo thời gian (Design/10) ==")
	for dur in [30.0, 60.0, 90.0, 60.05]:
		var ts := _new(2024, _stats(), "track_circuit_a", {"duration": dur, "sprint_duration": 10.0})
		var steps := 0
		while not ts.finished and steps < 5000:
			ts.step()
			steps += 1
		var any_finished := false
		var most_laps := 0
		var ordered_by_s := true
		var rk3 := ts.ranking()
		for i in range(1, rk3.size()):
			if rk3[i].s > rk3[i - 1].s + 0.0001:
				ordered_by_s = false
		for car: TrafficSim.Car in ts.cars:
			any_finished = any_finished or car.finished
			most_laps = maxi(most_laps, car.laps_done)
		_check(ts.finished and is_equal_approx(ts.time, dur), "lượt %.2f giây: kết thúc đúng mốc cho mọi xe (time=%.4f, %d tick)" % [dur, ts.time, steps])
		_check(steps == int(ceil(dur / 0.1 - 0.000001)), "lượt %.2f giây: số tick = ceil(duration/tick) (%d)" % [dur, steps])
		_check(not any_finished and not ts.forced_finish, "không xe nào bị chốt riêng theo vòng/cưỡng bức")
		_check(ordered_by_s, "hạng theo tổng tiến trình s giảm dần")
		if dur >= 90.0:
			_check(most_laps >= 3, "lượt %.0f giây: xe vẫn chạy tiếp sau vòng 3 (nhiều nhất %d vòng)" % [dur, most_laps])
	var lap_lead := _new(5, _stats(), "track_circuit_a", {"duration": 90.0, "sprint_duration": 10.0})
	lap_lead.run_to_end()
	var rk4 := lap_lead.ranking()
	var lap_ok := true
	for i in range(1, rk4.size()):
		if rk4[i].laps_done > rk4[i - 1].laps_done:
			lap_ok = false
	_check(lap_ok, "xe nhiều vòng hơn không bao giờ xếp dưới xe ít vòng hơn")
	var t1 := _new(31, _stats(), "track_circuit_a", {"duration": 60.0, "sprint_duration": 10.0})
	t1.run_to_end()
	var t2 := _new(31, _stats(), "track_circuit_a", {"duration": 60.0, "sprint_duration": 10.0})
	t2.run_to_end()
	var det := true
	for i in 8:
		det = det and is_equal_approx(t1.cars[i].s, t2.cars[i].s) and t1.cars[i].errors == t2.cars[i].errors
	_check(det, "cùng seed + cấu hình => cùng tiến trình mọi xe")
	var tie := _new(1, _stats(), "track_circuit_a", {"duration": 10.0})
	for car: TrafficSim.Car in tie.cars:
		car.s = 100.0
	var tr_rk := tie.ranking()
	_check(tr_rk[0].id == 0 and tr_rk[7].id == 7, "hòa tiến trình: id tăng dần")
	var clamp_s := _new(1, _stats(), "track_circuit_a", {"duration": 4.0, "sprint_duration": 10.0})
	_check(is_equal_approx(clamp_s.sprint_window, 4.0), "nước rút giới hạn bằng thời lượng lượt ngắn")
	var legacy := _new(1, _stats(), "track_circuit_a")
	_check(not legacy.is_timed(), "không truyền duration => vẫn đua theo vòng (tham chiếu v1.0)")
	# Nước rút: tay đua sprint nhanh hơn ở 10 giây cuối.
	var spr_drv := ""
	for d: Dictionary in GameData.drivers():
		if String(d["trait"]) == "sprint":
			spr_drv = String(d["id"])
	var gain_sp := 0.0
	var gains: Array = []
	for s2 in 15:
		var a1 := _new(400 + s2, _stats(), "track_circuit_a", {"duration": 60.0, "sprint_duration": 10.0, "driver_id": spr_drv})
		a1.run_to_end()
		var a0 := _new(400 + s2, _stats(), "track_circuit_a", {"duration": 60.0, "sprint_duration": 0.0, "driver_id": spr_drv})
		a0.run_to_end()
		gains.append(a1.distance_of(a1.cars[0]) - a0.distance_of(a0.cars[0]))
	# Dùng trung vị: một seed có thể lệch do chuỗi RNG lỗi dịch chuyển khi tốc độ đổi (hỗn loạn), không phải do nước rút.
	gains.sort()
	gain_sp = float(gains[gains.size() / 2])
	_check(gain_sp > 0.0, "nước rút 10 giây cuối cho thêm quãng đường (trung vị +%.2f)" % gain_sp)

	_test_driver_stats()

	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)


## 7 chỉ số tay đua, 4 phong cách và stamina (Design/16).
func _test_driver_stats() -> void:
	print("== Chỉ số tay đua, phong cách, stamina ==")
	var base := _new(5, _stats(), "track_circuit_a", {"duration": 40.0, "sprint_duration": 10.0})
	base.run_to_end()
	var p0: TrafficSim.Car = base.cars[0]
	_check(p0.stamina < 100.0 and p0.stamina >= 0.0, "stamina hao trong lượt (cuối %.1f)" % p0.stamina)
	var styles_ok := true
	for c: TrafficSim.Car in base.cars:
		styles_ok = styles_ok and (c.is_player or c.style_id != "") and c.stamina >= 0.0 and c.stamina <= 100.0
	_check(styles_ok, "mọi bot có phong cách, stamina mọi xe nằm trong [0, 100]")
	# Endurance cao hao chậm hơn: cùng seed, chỉ khác endurance của người chơi.
	var lo := _stats()
	lo["E"] = 30.0
	var hi := _stats()
	hi["E"] = 60.0
	var a := _new(9, lo, "track_circuit_a", {"duration": 40.0, "sprint_duration": 10.0})
	var b := _new(9, hi, "track_circuit_a", {"duration": 40.0, "sprint_duration": 10.0})
	for i in 200:
		a.step()
		b.step()
	_check(b.cars[0].stamina > a.cars[0].stamina, "endurance cao giữ nhiều stamina hơn (%.1f > %.1f)" % [b.cars[0].stamina, a.cars[0].stamina])
	# Launch cao tăng tốc nhanh hơn ngay sau xuất phát.
	var ll := _stats()
	ll["L"] = 30.0
	var lh := _stats()
	lh["L"] = 60.0
	var s_lo := _new(11, ll, "track_circuit_a", {"duration": 40.0})
	var s_hi := _new(11, lh, "track_circuit_a", {"duration": 40.0})
	for i in 20:  # trước lỗi đầu tiên (lỗi dịch chuyển tốc độ ngẫu nhiên)
		s_lo.step()
		s_hi.step()
	_check(s_hi.cars[0].speed > s_lo.cars[0].speed, "launch cao tăng tốc nhanh hơn (%.1f > %.1f)" % [s_hi.cars[0].speed, s_lo.cars[0].speed])
	# Composure cao giữ chế độ ga lâu hơn (đổi chế độ ít hơn).
	var switches := [0, 0]
	for k in 2:
		var st := _stats()
		st["C"] = 20.0 if k == 0 else 80.0
		var sm := _new(21, st, "track_circuit_a", {"duration": 60.0, "sprint_duration": 10.0})
		var last := "balanced"
		while not sm.finished:
			sm.step()
			if sm.cars[0].mode != last:
				switches[k] += 1
				last = sm.cars[0].mode
	_check(switches[1] <= switches[0], "composure cao đổi chế độ ga không nhiều hơn (%d ≤ %d lần)" % [switches[1], switches[0]])
	# Thiếu khóa chỉ số mới (checkpoint cũ) vẫn chạy, bằng chuẩn giải.
	var legacy_stats := _stats()
	var lg := _new(3, legacy_stats, "track_circuit_a", {"duration": 10.0})
	lg.run_to_end()
	_check(lg.finished and lg.cars[0].dL == 0.0 and lg.cars[0].dE == 0.0, "thiếu L/R/K/E => mặc định bằng chuẩn giải")
