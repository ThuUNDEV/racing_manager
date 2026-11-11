extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/traffic_lab.gd -- [1] [2] [3]
## Bước 0 của Design/08: so TrafficSim với RaceSim v1.0. Chọn phần chạy bằng số (mặc định cả ba); chạy lâu, nên chạy nền.
##   1: phân phối vị trí ở Δ = 0   2: thời gian tiết kiệm theo chỉ số   3: tỉ lệ đạt 36 điểm/mùa

const PTS := [10, 8, 6, 5, 4, 3, 2, 1]


func _stats(cb: float, db: float, d: Array) -> Dictionary:
	return {"S": cb + d[0], "H": cb + d[1], "B": cb + d[2], "A": cb + d[3], "P": db + d[4], "T": db + d[5], "C": db + d[6]}


func _run(kind: String, seed_value: int, stats: Dictionary, track: String) -> Array:
	## Trả về [vị trí 1..8, thời gian người chơi].
	if kind == "v1":
		var a := RaceSim.new()
		a.setup(seed_value, stats, 0, track)
		a.run_to_end()
		return [a.ranking().find(a.player_car()) + 1, a.player_car().finish_time]
	var b := TrafficSim.new()
	b.setup(seed_value, stats, 0, track)
	b.run_to_end()
	return [b.ranking().find(b.player_car()) + 1, b.player_car().finish_time]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var lg := GameData.league(0)
	var cb := float(lg["car_base"])
	var db := float(lg["driver_base"])
	var zero := [0, 0, 0, 0, 0, 0, 0]

	if args.is_empty() or args.has("1"):
		print("== 1. Phân phối vị trí, Δ = 0, 100 seed ==")
		for pair in [["v1", "track_harbor"], ["v2", "track_harbor"], ["v1", "track_pine"], ["v2", "track_pine"], ["v2", "track_circuit_a"]]:
			var hist := [0, 0, 0, 0, 0, 0, 0, 0]
			var tsum := 0.0
			for s in 100:
				var r := _run(pair[0], 1000 + s, _stats(cb, db, zero), pair[1])
				hist[int(r[0]) - 1] += 1
				tsum += float(r[1])
			print("  %s %-16s P1..P8 %s · TB %.1f s" % [pair[0], pair[1], hist, tsum / 100.0])

	if args.is_empty() or args.has("2"):
		print("== 2. Thời gian tiết kiệm khi tăng chỉ số (+40 xe, +20 tay đua), 24 seed ==")
		var cases := {
			"Động cơ +40": [40, 0, 0, 0, 0, 0, 0], "Lốp +40": [0, 40, 0, 0, 0, 0, 0],
			"Khung +40": [0, 0, 40, 0, 0, 0, 0], "Hộp số +40": [0, 0, 0, 40, 0, 0, 0],
			"Pace +20": [0, 0, 0, 0, 20, 0, 0], "Technique +20": [0, 0, 0, 0, 0, 20, 0],
			"Composure +20": [0, 0, 0, 0, 0, 0, 20],
		}
		for tid in ["track_harbor", "track_city", "track_circuit_a"]:
			var base_t := 0.0
			var base_p := 0.0
			for s in 24:
				var r := _run("v2", 7000 + s, _stats(cb, db, zero), tid)
				base_t += float(r[1])
				base_p += float(r[0])
			var line := "  %s nền %.1fs P%.2f |" % [tid, base_t / 24.0, base_p / 24.0]
			for k in cases:
				var t := 0.0
				var p := 0.0
				for s in 24:
					var r := _run("v2", 7000 + s, _stats(cb, db, cases[k]), tid)
					t += float(r[1])
					p += float(r[0])
				line += " %s: %+.1fs (P%.2f)" % [k, (base_t - t) / 24.0, p / 24.0]
			print(line)

	if args.is_empty() or args.has("3"):
		print("== 3. Tỉ lệ đạt 36 điểm/mùa (lịch giải 0), 30 mùa ==")
		for d in [-14, -8, 0, 4, 8, 12, 16, 24]:
			var line := "  Δxe=%+d:" % d
			for kind in ["v1", "v2"]:
				var ok := 0
				var avg := 0.0
				for s in 30:
					var pts := 0
					for stage in 5:
						var tid: String = lg["schedule"][stage]
						var dr := float(d) / 2.0
						var r := _run(kind, 900 + s * 10 + stage, _stats(cb, db, [d, d, d, d, dr, dr, dr]), tid)
						pts += PTS[int(r[0]) - 1]
					avg += pts
					if pts >= 36:
						ok += 1
				line += "  %s: %.1f điểm, %d%%" % [kind, avg / 30.0, ok * 100 / 30]
			print(line)
	quit()
