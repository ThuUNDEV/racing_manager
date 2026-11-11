extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/promotion_lab.gd
## Tỉ lệ đạt 36 điểm/mùa theo độ lệch chỉ số xe (Δ) so với nền giải; tay đua lệch một nửa Δxe.
## Lịch mùa lấy từ giải 0 trong data/leagues.json.

const PTS := [10, 8, 6, 5, 4, 3, 2, 1]


func _initialize() -> void:
	var lg := GameData.league(0)
	var cb := float(lg["car_base"])
	var db := float(lg["driver_base"])
	for d in [-14, -8, 0, 4, 8, 12, 16, 24]:
		var ok := 0
		var seasons := 60
		var avg_pts := 0.0
		for s in seasons:
			var pts := 0
			for stage in 5:
				var tid: String = lg["schedule"][stage]
				var dr: float = db + float(d) / 2.0
				var sim := RaceSim.new()
				sim.setup(900 + s * 10 + stage, {"S": cb + d, "H": cb + d, "B": cb + d, "A": cb + d, "P": dr, "T": dr, "C": dr}, 0, tid)
				sim.run_to_end()
				pts += PTS[sim.ranking().find(sim.player_car())]
			avg_pts += pts
			if pts >= 36:
				ok += 1
		print("Δxe=%+d (Δtay đua=%+.0f): điểm mùa TB %.1f · đạt ≥36: %d%%" % [d, d / 2.0, avg_pts / seasons, ok * 100 / seasons])
	quit()
