extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/scenario_lab.gd
## Kịch bản "xe người chơi chậm nhất rồi nâng cấp dần": với mỗi cấu hình bot (offset chung), đo hạng TB, % về bét, % top 3
## theo tổng số cấp nâng cấp đã mua (chia đều vòng tròn Động cơ → Lốp → Khung → Hộp số, mỗi cấp +2 chỉ số).
## Xe gốc Pico Tia chớp (S46 H38 B38 A38) + tay đua An (40/40/40) trên Circuit B, lượt theo cấu hình hiện tại.

const SEEDS := 200
const LEVELS := [0, 1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 24]
const CONFIGS := {
	"A: +4..+10": [4, 5, 6, 7, 8, 9, 10],
	"B: +6..+12": [6, 7, 8, 9, 10, 11, 12],
	"C: +8..+14": [8, 9, 10, 11, 12, 13, 14],
}


func _stats(u: int) -> Dictionary:
	var lv := [0, 0, 0, 0]
	for i in u:
		lv[i % 4] += 1
	return {"S": 46.0 + 2.0 * lv[0], "H": 38.0 + 2.0 * lv[1], "B": 38.0 + 2.0 * lv[2], "A": 38.0 + 2.0 * lv[3],
		"P": 40.0, "T": 40.0, "C": 40.0}


func _ai(offsets: Array) -> Array:
	var names: Array = GameData.sim()["ai_names"]
	var out: Array = []
	for i in offsets.size():
		out.append({"name": String(names[i]), "offset": float(offsets[i])})
	return out


func _initialize() -> void:
	var dur := Balance.race_duration("track_circuit_b")
	print("== Kịch bản xe chậm nhất → nâng cấp (Circuit B, %d seed, lượt %.0f s) ==" % [SEEDS, dur])
	for label: String in CONFIGS:
		print(label)
		print("  cấp | hạng TB | về bét | top 3 | về nhất")
		for u: int in LEVELS:
			var sum := 0.0
			var last := 0
			var top3 := 0
			var win := 0
			for i in SEEDS:
				var t := TrafficSim.new()
				t.setup(9000 + i, _stats(u), 0, "track_circuit_b", {"duration": dur, "sprint_duration": 10.0, "tuning": {"ai_cars": _ai(CONFIGS[label])}})
				t.run_to_end()
				var pos: int = t.ranking().find(t.player_car()) + 1
				sum += pos
				last += int(pos == 8)
				top3 += int(pos <= 3)
				win += int(pos == 1)
			var n := float(SEEDS)
			print("  %3d | %.2f    | %3.0f%%   | %3.0f%% | %3.0f%%" % [u, sum / n, 100.0 * last / n, 100.0 * top3 / n, 100.0 * win / n])
	quit()
