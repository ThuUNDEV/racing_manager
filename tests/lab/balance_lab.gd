extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/balance_lab.gd -- [--tracks=track_harbor,...] [--n=80]
## Phòng thí nghiệm cân bằng: giây tiết kiệm của mỗi chỉ số (từ nền lên +40) trên từng track của data/tracks.json.
## Chạy lâu (hàng nghìn race); nên chạy nền. Có thể ghi đè hệ số bằng GameData.set_override trong chính script này.

var N := 80


func _stats(delta: Dictionary) -> Dictionary:
	var d := {"S": 40.0, "H": 40.0, "B": 40.0, "A": 40.0, "P": 40.0, "T": 40.0, "C": 40.0}
	for k in delta:
		d[k] = 40.0 + float(delta[k])
	return d


func _measure(track: String, stats: Dictionary) -> Array:
	var t := 0.0
	var pos := 0.0
	for i in N:
		var sim := RaceSim.new()
		sim.setup(7000 + i, stats, 0, track)
		sim.run_to_end()
		t += sim.player_car().finish_time
		pos += sim.ranking().find(sim.player_car()) + 1
	return [t / N, pos / N]


func _initialize() -> void:
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tracks="):
			only = a.substr(9).split(",")
		elif a.begins_with("--n="):
			N = int(a.substr(4))
	var labels := [["S", "Động cơ"], ["H", "Lốp"], ["B", "Khung"], ["A", "Hộp số"], ["P", "Pace"], ["T", "Tech"], ["C", "Compo"]]
	for t: Dictionary in GameData.tracks():
		if not only.is_empty() and not only.has(t["id"]):
			continue
		var base := _measure(t["id"], _stats({}))
		var line := "%-16s nền %.1fs P%.2f | " % [t["name"], base[0], base[1]]
		for lbl in labels:
			var m := _measure(t["id"], _stats({lbl[0]: 40}))
			line += "%s %.1fs(P%.1f)  " % [lbl[1], base[0] - m[0], m[1]]
		print(line)
	quit()
