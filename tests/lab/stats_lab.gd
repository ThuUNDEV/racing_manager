extends SceneTree
## Lab: 7 chỉ số tay đua, 4 phong cách và stamina (Design/16). Không ghi save.
## Chạy: godot --headless --path . -s res://tests/lab/stats_lab.gd
## In: (1) thử nước rút từng seed, (2) hạng trung bình + số lần đổi chế độ theo tay đua trên cùng đoàn bot.


func _stats(league: int, drv: Dictionary) -> Dictionary:
	var lg := GameData.league(league)
	var cb := float(lg["car_base"])
	return {
		"S": cb, "H": cb, "B": cb, "A": cb,
		"P": float(drv["pace"]), "T": float(drv["technique"]), "C": float(drv["composure"]),
		"L": float(drv["launch"]), "R": float(drv["braking"]), "K": float(drv["racecraft"]), "E": float(drv["endurance"]),
	}


func _run(seed_v: int, drv: Dictionary, dur: float, spr: float) -> TrafficSim:
	var t := TrafficSim.new()
	t.setup(seed_v, _stats(0, drv), 0, "track_circuit_a", {"driver_id": String(drv["id"]), "duration": dur, "sprint_duration": spr})
	t.run_to_end()
	return t


func _init() -> void:
	var spr: Dictionary = {}
	for d: Dictionary in GameData.drivers():
		if String(d["trait"]) == "sprint":
			spr = d
	print("== nước rút từng seed (Hà) ==")
	for s in 10:
		var a1 := _run(400 + s, spr, 60.0, 10.0)
		var a0 := _run(400 + s, spr, 60.0, 0.0)
		print("  seed %d: %.2f vs %.2f  chênh %+.2f  stamina %.1f/%.1f" % [400 + s,
			a1.distance_of(a1.cars[0]), a0.distance_of(a0.cars[0]), a1.distance_of(a1.cars[0]) - a0.distance_of(a0.cars[0]),
			a1.cars[0].stamina, a0.cars[0].stamina])
	print("== hạng trung bình theo tay đua (40 seed, 40 giây, giải 0) ==")
	for d: Dictionary in GameData.drivers():
		var sum_pos := 0.0
		var sum_sta := 0.0
		for s in 40:
			var t := _run(900 + s, d, 40.0, 10.0)
			var rk := t.ranking()
			for i in rk.size():
				if rk[i].is_player:
					sum_pos += i + 1
			sum_sta += t.cars[0].stamina
		print("  %-8s %-9s hạng TB %.2f · stamina cuối TB %.1f" % [d["name"], d["style"], sum_pos / 40.0, sum_sta / 40.0])
	quit()
