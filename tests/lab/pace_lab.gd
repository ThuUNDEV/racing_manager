extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/pace_lab.gd
## Đo nhịp đua TrafficSim theo cấu hình (tốc độ, thời lượng, hút gió): số vòng, lượt vượt, đổi hạng người chơi,
## thời gian người chơi chạy sát xe khác, và hạng trung bình khi người chơi hơn chuẩn +10 (chỉ số còn có ý nghĩa không).

const SEEDS := 200
var track := "track_circuit_b"


func _stats(delta: float) -> Dictionary:
	var lg := GameData.league(0)
	var cb := float(lg["car_base"]) + delta
	var db := float(lg["driver_base"]) + delta
	return {"S": cb, "H": cb, "B": cb, "A": cb, "P": db, "T": db, "C": db}


func _measure(label: String, duration: float, tuning: Dictionary) -> void:
	var laps_lead := 0.0
	var passes := 0.0
	var player_moves := 0.0
	var spread := 0.0
	var close_ticks := 0.0
	var ticks := 0.0
	var pos0 := 0.0
	var pos10 := 0.0
	var errs := 0.0
	for i in SEEDS:
		for delta in [0.0, 10.0]:
			var t := TrafficSim.new()
			t.setup(5000 + i, _stats(delta), 0, track, {"duration": duration, "sprint_duration": 10.0, "traffic_tuning": tuning})
			var last_rank := t.ranking().find(t.player_car())
			while not t.finished:
				t.step()
				if delta > 0.0:
					continue
				var me := t.player_car()
				var r := t.ranking().find(me)
				if r != last_rank:
					player_moves += 1.0
					last_rank = r
				ticks += 1.0
				for o: TrafficSim.Car in t.cars:
					if o != me and me.s > 0.0 and absf(o.s - me.s) <= 1.5 * t.L:
						close_ticks += 1.0
						break
			var rk := t.ranking()
			var final := rk.find(t.player_car()) + 1
			if delta > 0.0:
				pos10 += final
				continue
			pos0 += final
			laps_lead += float(rk[0].s) / t.lap_length
			for ec: TrafficSim.Car in t.cars:
				errs += float(ec.errors)
			spread += (rk[0].s - rk[rk.size() - 1].s) / t.L
			for e: Dictionary in t.events:
				if e["type"] == "pass":
					passes += 1.0
	var n := float(SEEDS)
	print("  %-30s vòng đầu %.2f · vượt/lượt %4.1f · bạn đổi hạng %4.1f · bạn sát xe khác %2.0f%% · lỗi/lượt %.1f · đầu–cuối %4.1f thân xe · hạng TB Δ0 %.2f / Δ+10 %.2f" % [
		label, laps_lead / n, passes / n, player_moves / n, 100.0 * close_ticks / ticks, errs / n, spread / n, pos0 / n, pos10 / n])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		track = args[0]
	print("== Nhịp đua TrafficSim (%d seed) · %s · vòng %.0f ==" % [SEEDS, track, GameData.lap_length_of(track)])
	var dur := Balance.race_duration(track)
	_measure("cấu hình hiện tại %ds" % int(dur), dur, {})
	for sc in [1.5, 2.0]:
		for d in [30.0, 40.0]:
			_measure("×%.1f · %ds" % [sc, int(d)], d, {"speed_scale": sc})
	quit()
