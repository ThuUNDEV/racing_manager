extends SceneTree

## Nâng cấp bằng cúp: dữ liệu, nhận cúp theo hạng, trần, mua nâng cấp, hiệu ứng, save/load, hoàn tác.
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	print(("  ok   " if ok else "  FAIL "), msg)
	if not ok:
		_fails += 1


func _initialize() -> void:
	await process_frame
	GameData.reload()
	var gs: Node = root.get_node("GameState")
	gs.init_new_game()  # không dùng reset_progress(): giữ save thật của người dùng
	gs.SAVE_PATH = "user://trophy_test_save.json"
	gs.BAK_PATH = "user://trophy_test_save.bak"
	gs.TMP_PATH = "user://trophy_test_save.tmp"

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	_check(GameData.trophy_upgrades().size() == 8, "8 nâng cấp cúp")
	_check(GameData.trophy_cap_base() == 100, "trần gốc 100 cúp")
	var caps := []
	for l in 6:
		caps.append(GameData.trophy_cap_for_league(l))
	_check(caps == [100, 160, 230, 300, 365, 420], "trần theo giải: %s" % str(caps))
	_check(GameData.trophy_cap_for_league(99) == 420 and GameData.trophy_cap_for_league(-1) == 100, "giải ngoài bảng được chặn")
	_check(GameData.trophy_reward(1, 0) == 3 and GameData.trophy_reward(2, 0) == 2 and GameData.trophy_reward(3, 0) == 1, "P1/P2/P3 = 3/2/1 ở giải 0")
	_check(GameData.trophy_reward(4, 0) == 0 and GameData.trophy_reward(8, 5) == 0, "từ P4 trở xuống không có cúp")
	_check(GameData.trophy_reward(1, 3) == 12, "hệ số giải: P1 giải 3 = 3 × 4")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trophy_upgrades.json"))
	var bad := raw.duplicate(true)
	(bad["upgrades"][0]["cost_by_level"] as Array).pop_back()
	GameData.set_override("trophy_upgrades", bad)
	_check(not GameData.validate().is_empty(), "bảng giá thiếu bị từ chối")
	bad = raw.duplicate(true)
	bad["upgrades"][0]["effect_by_level"][1] = {"X": 1}
	GameData.set_override("trophy_upgrades", bad)
	_check(not GameData.validate().is_empty(), "khóa hiệu ứng lạ bị từ chối")
	GameData.reload()

	print("== Nhận cúp ==")
	gs.init_new_game()
	gs.save_blocked = false
	_check(gs._award_trophies(1) == 3 and gs.trophies == 3 and gs.trophies_earned == 3, "P1 nhận 3 cúp")
	_check(gs._award_trophies(3) == 1 and gs.trophies == 4, "P3 nhận 1 cúp")
	_check(gs._award_trophies(4) == 0 and gs._award_trophies(8) == 0 and gs.trophies == 4, "P4 và P8 không nhận cúp")
	gs.trophies_earned = 99
	_check(gs._award_trophies(1) == 1 and gs.trophies_earned == 100, "chạm trần: nhận phần còn lại (cắt theo trần)")
	_check(gs._award_trophies(1) == 0 and gs.trophies_earned == 100, "đã chạm trần thì không nhận thêm")
	gs.trophy_cap_bonus = 10
	_check(gs.trophy_cap() == 110 and gs._award_trophies(1) == 3, "nâng trần cho phép nhận tiếp")

	gs.init_new_game()
	gs.business_tier = 2
	_check(gs.trophy_cap() == 230, "giải 2: trần 230")
	gs.trophies_earned = 100
	_check(gs._award_trophies(1) == 9, "lên giải: nhận tiếp, không reset tổng đã kiếm")
	gs.business_tier = 5
	gs.trophy_cap_bonus = 10
	_check(gs.trophy_cap() == 430, "trần giải + trophy_cap_bonus")
	var nb: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trophy_upgrades.json"))
	nb["cap"].erase("by_league")
	GameData.set_override("trophy_upgrades", nb)
	_check(GameData.trophy_cap_for_league(4) == 100, "thiếu by_league thì dùng trần gốc")
	nb["cap"]["by_league"] = [100, 90, 230, 300, 365, 420]
	GameData.set_override("trophy_upgrades", nb)
	_check(not GameData.validate().is_empty(), "by_league giảm bị từ chối")
	GameData.reload()

	print("== Mua nâng cấp ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.trophies = 6
	gs.trophies_earned = 6
	_check(gs.trophy_cost("speed_tune") == 1, "cấp 0 → 1 giá 1 cúp")
	_check(gs.buy_trophy_upgrade("speed_tune") and gs.trophy_level("speed_tune") == 1 and gs.trophies == 5, "mua cấp 1 trừ 1 cúp")
	_check(gs.trophy_cost("speed_tune") == 2 and gs.buy_trophy_upgrade("speed_tune") and gs.trophies == 3, "cấp 2 giá 2 cúp")
	_check(gs.trophy_cost("speed_tune") == 3 and gs.buy_trophy_upgrade("speed_tune") and gs.trophies == 0, "cấp 3 giá 3 cúp")
	_check(not gs.buy_trophy_upgrade("speed_tune") and gs.trophy_level("speed_tune") == 3, "thiếu cúp không mua được")
	_check(not gs.buy_trophy_upgrade("race_chassis"), "nâng cấp mở từ giải 2 bị khóa ở giải 0")
	_check(not gs.buy_trophy_upgrade("khong_ton_tai"), "id lạ bị từ chối")
	gs.trophies = 9999
	for i in 7:
		gs.buy_trophy_upgrade("speed_tune")
	_check(gs.trophy_level("speed_tune") == 10 and gs.trophy_cost("speed_tune") == -1, "dừng ở cấp tối đa")
	_check(not gs.buy_trophy_upgrade("speed_tune"), "không mua vượt cấp tối đa")

	print("== Hiệu ứng ==")
	gs.init_new_game()
	gs.save_blocked = false
	var base_stats: Dictionary = gs.player_stats()
	gs.trophy_levels = {"speed_tune": 3, "corner_grip": 2}
	var st: Dictionary = gs.player_stats()
	_check(is_equal_approx(float(st["S"]) - float(base_stats["S"]), 3.0), "Động cơ đua cấp 3: Tốc độ +3")
	_check(is_equal_approx(float(st["H"]) - float(base_stats["H"]), 2.0), "Bám cua cấp 2: Bám cua +2")
	_check(st["A"] == base_stats["A"] and st["B"] == base_stats["B"] and st["P"] == base_stats["P"], "chỉ số khác không đổi")
	gs.trophy_levels = {"launch_boost": 4, "overtake_kit": 2}
	gs.business_tier = 2
	gs.unlocked_tier = 2
	var bonus: Dictionary = gs.trophy_bonus()
	_check(float(bonus["A"]) == 6.0 and float(bonus["S"]) == 2.0, "Đà vượt xe cộng nhiều chỉ số, gộp với nâng cấp khác")
	gs.business_tier = 0
	gs.unlocked_tier = 0
	gs.trophy_levels = {"sponsor": 5, "grandstand": 4}
	var rate: BigNumber = gs.online_rate()
	_check(gs.daily_gift_amount().equals(Pricing.daily_gift(rate).add(rate.multiply_ratio(120, 1).floor_number())), "Khán đài đông: quà ngày + 120 giây thu nhập")
	gs.trophy_levels = {}
	_check(gs.daily_gift_amount().equals(Pricing.daily_gift(rate)), "không nâng cấp thì quà ngày giữ nguyên")

	print("== Chốt lượt đua ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.begin_countdown()
	var sim: TrafficSim = gs.sim
	var res: Dictionary = gs._compute_result(sim)
	var pos := int(res["position"])
	_check(int(res["trophies"]) == GameData.trophy_reward(pos, 0), "kết quả lượt có số cúp đúng theo hạng P%d" % pos)
	_check(gs.trophies == int(res["trophies"]) and gs.trophies_earned == int(res["trophies"]), "cúp cộng vào ví đúng một lần")
	var again: Dictionary = gs._compute_result(sim)
	_check(int(again["trophies"]) == 0 and gs.trophies == int(res["trophies"]), "chốt lại cùng lượt không cộng trùng")

	print("== Save/load ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.trophies = 7
	gs.trophies_earned = 42
	gs.trophy_cap_bonus = 5
	gs.trophy_levels = {"speed_tune": 2, "sponsor": 1}
	_check(gs.save_game(), "lưu được")
	gs.init_new_game()
	gs.save_blocked = false
	_check(gs.load_game() == "ok", "tải được")
	_check(gs.trophies == 7 and gs.trophies_earned == 42 and gs.trophy_cap_bonus == 5, "cúp, tổng đã kiếm, nâng trần giữ nguyên")
	_check(gs.trophy_level("speed_tune") == 2 and gs.trophy_level("sponsor") == 1, "cấp nâng cấp giữ nguyên")
	var dirty := {"trophies": -5, "trophies_earned": 1, "trophy_levels": {"speed_tune": 99, "xxx": 3, "sponsor": -2}}
	gs._apply_trophies(dirty)
	_check(gs.trophies == 0 and gs.trophies_earned == 1, "số âm bị làm sạch, tổng đã kiếm không nhỏ hơn số đang có")
	_check(gs.trophy_level("speed_tune") == 10 and gs.trophy_level("xxx") == 0 and gs.trophy_level("sponsor") == 0, "cấp ngoài cấu hình bị chặn, id lạ bị bỏ")

	print("== Hoàn tác khi lưu lỗi ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.trophies = 3
	gs.simulate_write_failure = true
	_check(not gs.buy_trophy_upgrade("speed_tune"), "lưu lỗi thì mua thất bại")
	gs.simulate_write_failure = false
	_check(gs.trophies == 3 and gs.trophy_level("speed_tune") == 0, "trạng thái được hoàn tác")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://trophy_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://trophy_test_save.bak"))
	print("")
	print("trophy_test: %s" % ("ĐẠT" if _fails == 0 else "%d LỖI" % _fails))
	quit(0 if _fails == 0 else 1)
