extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/traffic_promo.gd -- [số mùa]
## Tỉ lệ đạt 36 điểm/mùa theo Δ chỉ số (lịch giải 0) với TrafficSim; so với v1.0: Δ+4 ≈ 40%, Δ+8 ≈ 92–98% (Design/04 §3).

const PTS := [10, 8, 6, 5, 4, 3, 2, 1]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seasons := 40 if args.size() < 1 else int(args[0])
	var tuning := {}
	for a in args:
		if a.contains("="):
			tuning[a.split("=")[0]] = float(a.split("=")[1])
	var lg := GameData.league(0)
	var cb := float(lg["car_base"])
	var db := float(lg["driver_base"])
	for d in [0, 4, 8, 12]:
		var ok := 0
		var avg := 0.0
		for s in seasons:
			var pts := 0
			for stage in 5:
				var tid: String = lg["schedule"][stage]
				var dr := float(d) / 2.0
				var sim := TrafficSim.new()
				sim.setup(900 + s * 10 + stage, {"S": cb + d, "H": cb + d, "B": cb + d, "A": cb + d, "P": db + dr, "T": db + dr, "C": db + dr}, 0, tid, {"traffic_tuning": tuning})
				sim.run_to_end()
				pts += PTS[sim.ranking().find(sim.player_car())]
			avg += pts
			if pts >= 36:
				ok += 1
		print("Δxe=%+d: %.1f điểm, đạt ≥36: %d%%" % [d, avg / seasons, ok * 100 / seasons])
	quit()
