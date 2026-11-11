extends SceneTree
## Chạy: godot --headless --path . -s res://tests/golden_test.gd
## Cập nhật golden có chủ đích sau khi đổi công thức: ... -s res://tests/golden_test.gd -- --update
## Thời gian về đích của cả 8 xe cho một danh sách (seed, giải, track, build) phải khớp tệp golden.
## Hai bộ: RaceSim v1.0 (mô phỏng một chiều, giữ làm chuẩn tham chiếu) và TrafficSim (Design/08).

const GOLDEN_PATH := "res://tests/golden/sim_golden.json"
const TRAFFIC_GOLDEN_PATH := "res://tests/golden/traffic_golden.json"

const CASES := [
	{"name": "harbor_base", "seed": 1001, "league": 0, "track": "track_harbor", "d": [0, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "pine_base", "seed": 1002, "league": 0, "track": "track_pine", "d": [0, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "city_base", "seed": 1003, "league": 0, "track": "track_city", "d": [0, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "desert_engine", "seed": 1004, "league": 0, "track": "track_desert", "d": [20, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "oldtown_tyre", "seed": 1005, "league": 1, "track": "track_oldtown", "d": [0, 20, 0, 0, 5, 5, 5], "driver": "driver_chi"},
	{"name": "neon_balanced", "seed": 1006, "league": 2, "track": "track_neon", "d": [8, 8, 8, 8, 4, 4, 4], "driver": "driver_binh"},
	{"name": "speedway_traits", "seed": 1007, "league": 3, "track": "track_speedway", "d": [4, 4, 4, 4, 2, 2, 2], "driver": "driver_my"},
	{"name": "mountain_hard", "seed": 1008, "league": 5, "track": "track_mountain", "d": [-10, -10, -10, -10, -5, -5, -5], "driver": "driver_son"},
]

const TRAFFIC_CASES := [
	{"name": "circuit_a_base", "seed": 2001, "league": 0, "track": "track_circuit_a", "d": [0, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "circuit_a_strong", "seed": 2002, "league": 0, "track": "track_circuit_a", "d": [12, 12, 12, 12, 6, 6, 6], "driver": "driver_an"},
	{"name": "harbor_base", "seed": 2003, "league": 0, "track": "track_harbor", "d": [0, 0, 0, 0, 0, 0, 0], "driver": ""},
	{"name": "city_tyre", "seed": 2004, "league": 0, "track": "track_city", "d": [0, 20, 0, 0, 5, 5, 5], "driver": ""},
	{"name": "desert_engine", "seed": 2005, "league": 1, "track": "track_desert", "d": [20, 0, 0, 0, 0, 0, 0], "driver": "driver_chi"},
	{"name": "mountain_hard", "seed": 2006, "league": 5, "track": "track_mountain", "d": [-10, -10, -10, -10, -5, -5, -5], "driver": "driver_son"},
]


func _stats_of(cs: Dictionary) -> Dictionary:
	var lg := GameData.league(int(cs["league"]))
	var cb := float(lg["car_base"])
	var db := float(lg["driver_base"])
	var d: Array = cs["d"]
	return {
		"S": cb + d[0], "H": cb + d[1], "B": cb + d[2], "A": cb + d[3],
		"P": db + d[4], "T": db + d[5], "C": db + d[6],
	}


func _compute() -> Dictionary:
	var out := {}
	for cs: Dictionary in CASES:
		var sim := RaceSim.new()
		sim.setup(int(cs["seed"]), _stats_of(cs), int(cs["league"]), String(cs["track"]), {"driver_id": String(cs["driver"])})
		sim.run_to_end()
		var times: Array = []
		for c: RaceSim.Car in sim.cars:
			times.append(snappedf(c.finish_time, 0.001))
		out[cs["name"]] = times
	return out


func _compute_traffic() -> Dictionary:
	var out := {}
	for cs: Dictionary in TRAFFIC_CASES:
		var sim := TrafficSim.new()
		sim.setup(int(cs["seed"]), _stats_of(cs), int(cs["league"]), String(cs["track"]), {"driver_id": String(cs["driver"])})
		sim.run_to_end()
		var times: Array = []
		for c: TrafficSim.Car in sim.cars:
			times.append(snappedf(c.finish_time, 0.001))
		out[cs["name"]] = times
	return out


## So kết quả với tệp golden (hoặc ghi lại khi có cờ --update). Trả về số lỗi.
func _compare(label: String, path: String, now: Dictionary) -> int:
	if OS.get_cmdline_user_args().has("--update"):
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(now, "\t"))
		f.close()
		print("Đã ghi golden %s: %s" % [label, path])
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		print("  FAIL thiếu tệp golden %s; chạy với -- --update" % label)
		return 1
	var fails := 0
	for name in now:
		var exp: Array = (parsed as Dictionary).get(name, [])
		var got: Array = now[name]
		var ok := exp.size() == got.size()
		if ok:
			for i in got.size():
				if absf(float(exp[i]) - float(got[i])) > 0.0015:
					ok = false
		print(("  ok   " if ok else "  FAIL "), "golden ", label, " ", name)
		if not ok:
			fails += 1
			print("       mong đợi ", exp)
			print("       nhận được ", got)
	return fails


func _initialize() -> void:
	var fails := _compare("v1", GOLDEN_PATH, _compute())
	fails += _compare("traffic", TRAFFIC_GOLDEN_PATH, _compute_traffic())
	print("== Kết thúc: %d lỗi ==" % fails)
	quit(1 if fails > 0 else 0)
