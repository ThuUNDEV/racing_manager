extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/duration_lab.gd
## So thời lượng cấu hình (Balance.race_duration) với thời gian thật để cả đoàn xe chạy đủ số vòng (đua theo vòng).

func _initialize() -> void:
	var track := "track_circuit_b"
	var lg := GameData.league(0)
	var cb := float(lg["car_base"])
	var st := {"S": cb, "H": cb, "B": cb, "A": cb, "P": cb, "T": cb, "C": cb}
	print("race_laps=%d  race_duration=%.2f  ref_lap=%.2f" % [Balance.race_laps(), Balance.race_duration(track), Balance.reference_lap_time(track)])
	var n := 100
	var tot_first := 0.0; var tot_last := 0.0; var tot_me := 0.0
	for i in n:
		var t := TrafficSim.new()
		t.setup(5000 + i, st, 0, track, {})
		t.run_to_end()
		var ft: Array = []
		for c: TrafficSim.Car in t.cars:
			ft.append(c.finish_time)
		ft.sort()
		tot_first += ft[0]; tot_last += ft[ft.size() - 1]; tot_me += t.player_car().finish_time
	print("đua theo vòng: nhất %.2f · bét %.2f · người chơi %.2f (giây sim)" % [tot_first / n, tot_last / n, tot_me / n])
	quit()
