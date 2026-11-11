extends SceneTree

## Gacha tay đua: dữ liệu, thanh toán, mới/trùng, bảo đảm, mảnh riêng, nâng level, chỉ số, save/load, hoàn tác.
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	print(("  ok   " if ok else "  FAIL "), msg)
	if not ok:
		_fails += 1


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _initialize() -> void:
	await process_frame
	GameData.reload()
	var gs: Node = root.get_node("GameState")
	gs.init_new_game()  # không dùng reset_progress(): giữ save thật của người dùng
	gs.SAVE_PATH = "user://driver_gacha_test_save.json"
	gs.BAK_PATH = "user://driver_gacha_test_save.bak"
	gs.TMP_PATH = "user://driver_gacha_test_save.tmp"

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	var pro := GameData.driver_pack("pro")
	var allstar := GameData.driver_pack("allstar")
	_check(int(pro["price_x1"]) == 10 and int(pro["price_x10"]) == 100, "Pro 10/100 gem")
	_check(int(allstar["price_x1"]) == 30 and int(allstar["price_x10"]) == 300, "All-Star 30/300 gem")
	_check(int(pro["pity_draws"]) == 13 and int(allstar["pity_draws"]) == 10, "bảo đảm 13 và 10 lượt")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/driver_gacha.json"))
	var bad := raw.duplicate(true)
	bad["packs"][0]["tiers"] = {"rookie": 50, "pro": 33, "elite": 7}
	GameData.set_override("driver_gacha", bad)
	_check(not GameData.validate().is_empty(), "tỉ lệ không đủ 100% bị từ chối")
	bad = raw.duplicate(true)
	(bad["tier_defaults"]["pro"]["level_up_shards"] as Array).pop_back()
	GameData.set_override("driver_gacha", bad)
	_check(not GameData.validate().is_empty(), "bảng ngưỡng thiếu bị từ chối")
	GameData.reload()

	print("== Thanh toán ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 1000
	_check(gs.driver_payment("pro", 1) == {"method": "gem", "amount": 10}, "x1 không coupon dùng gem")
	_check(gs.driver_payment("allstar", 10) == {"method": "gem", "amount": 300}, "All-Star x10 = 300 gem")
	_check(gs.driver_payment("pro", 5).is_empty() and gs.driver_payment("nope", 1).is_empty(), "số lượt/gói lạ bị từ chối")
	gs.grant_driver_coupons("pro", 2)
	_check(gs.driver_payment("pro", 1)["method"] == "coupon", "có coupon đúng loại thì dùng coupon")
	_check(gs.driver_payment("allstar", 1)["method"] == "gem", "coupon Pro không dùng cho All-Star")
	_check(gs.driver_payment("pro", 10)["method"] == "gem", "x10 thiếu coupon thì trả bằng gem, không trộn")
	gs.gems = 5
	_check(not gs.driver_can_afford("allstar", 1) and gs.driver_can_afford("pro", 1), "thiếu gem khóa; coupon vẫn mở được")
	_check(gs.open_driver_pack("allstar", 1).is_empty() and gs.gems == 5, "mở khi thiếu gem: không đổi gì")

	print("== Mở gói: mới / trùng ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 1000
	var before_owned: int = gs.owned_drivers.size()
	var out: Dictionary = gs.open_driver_pack("pro", 1, _rng(1))
	_check(not out.is_empty() and gs.gems == 990, "x1 trừ đúng 10 gem")
	var first: Dictionary = out["results"][0]
	_check(first["is_new"] == (before_owned + 1 == gs.owned_drivers.size()), "tay đua mới được thêm vào đội đúng một lần")
	_check(gs.active_driver_id == "driver_an", "nhận tay đua mới không tự chọn")
	# An đã sở hữu: ép trùng bằng cách mở nhiều lần, đếm mảnh
	var total_shards := 0
	var seen_new := {}
	for i in 40:
		gs.gems = 1000
		var o: Dictionary = gs.open_driver_pack("pro", 1, _rng(100 + i))
		var e: Dictionary = o["results"][0]
		if e["is_new"]:
			_check(not seen_new.has(e["id"]), "mới chỉ xuất hiện một lần: " + String(e["id"]))
			seen_new[e["id"]] = true
		else:
			total_shards += int(e["shards"])
	_check(gs.owned_drivers.size() == (gs.owned_drivers as Array).duplicate().size(), "danh sách sở hữu hợp lệ")
	var uniq := {}
	for id in gs.owned_drivers:
		uniq[id] = true
	_check(uniq.size() == gs.owned_drivers.size(), "không có tay đua trùng trong danh sách sở hữu")
	var shard_sum := 0
	for id in gs.owned_drivers:
		shard_sum += gs.driver_shards(id)
	_check(shard_sum == total_shards + (0 if first["is_new"] else int(first["shards"])), "mảnh chỉ cộng vào đúng tay đua trùng")

	print("== Bảo đảm ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 100000
	var worst := 0
	for pack_id in ["pro", "allstar"]:
		var pk := GameData.driver_pack(pack_id)
		var tier_idx := GameData.driver_tier_ids().find(pk["pity_tier"])
		var miss := 0
		var max_miss := 0
		for i in 400:
			var o2: Dictionary = gs.open_driver_pack(pack_id, 1, _rng(5000 + i * 7))
			var got: int = int(GameData.driver(o2["results"][0]["id"])["tier"])
			if got >= tier_idx:
				miss = 0
			else:
				miss += 1
				max_miss = maxi(max_miss, miss)
		_check(max_miss <= int(pk["pity_draws"]) - 1, "%s: không quá %d lượt liên tiếp trượt bậc bảo đảm (thực tế %d)" % [pack_id, int(pk["pity_draws"]) - 1, max_miss])
		worst = maxi(worst, max_miss)
	# Ép bảo đảm: đặt đếm sát ngưỡng thì lượt kế chắc chắn ra bậc mục tiêu
	gs.driver_pity["pro"] = 12
	var forced: Dictionary = gs.open_driver_pack("pro", 1, _rng(9))
	_check(int(GameData.driver(forced["results"][0]["id"])["tier"]) >= 2 and gs.driver_pity_count("pro") == 0, "lượt thứ 13 chắc chắn ra Elite và đặt lại đếm")

	print("== x10 trong một giao dịch ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 100
	var o10: Dictionary = gs.open_driver_pack("pro", 10, _rng(3))
	_check(not o10.is_empty() and gs.gems == 0 and o10["results"].size() == 10, "x10 trừ đúng 100 gem, ra 10 kết quả")
	var news := 0
	var seen := {}
	var ok_dup := true
	for e: Dictionary in o10["results"]:
		if e["is_new"]:
			news += 1
			if seen.has(e["id"]):
				ok_dup = false
		else:
			if not (seen.has(e["id"]) or e["id"] == "driver_an"):
				ok_dup = false
		seen[e["id"]] = true
	_check(ok_dup, "mới rồi lặp lại trong cùng x10 thì lần sau là trùng")
	_check(gs.owned_drivers.size() == 1 + news and gs.driver_pack_new == news, "bộ đếm sở hữu tăng đúng số mẫu mới")
	_check(gs.recruit_index() == 0, "tay đua nhận từ gói không làm đắt thêm giá tuyển bằng SP")

	print("== Nâng level chỉ tốn mảnh ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 50
	gs.coins = BigNumber_zero()
	var an := "driver_an"
	var base_stats: Dictionary = gs.player_stats()
	_check(gs.driver_upgrade_cost(an) == 10 and gs.driver_level(an) == 0, "level 0 cần 10 mảnh")
	_check(not gs.upgrade_driver(an), "thiếu mảnh không nâng được")
	gs.driver_progress[an] = {"level": 0, "shards": 25}
	var gems_before: int = gs.gems
	_check(gs.upgrade_driver(an) and gs.driver_level(an) == 1 and gs.driver_shards(an) == 15, "nâng trừ đúng 10 mảnh, giữ phần dư")
	_check(gs.gems == gems_before, "nâng không đụng gem")
	var lv_stats: Dictionary = gs.player_stats()
	_check(is_equal_approx(float(lv_stats["P"]) - float(base_stats["P"]), 1.0) and is_equal_approx(float(lv_stats["E"]) - float(base_stats["E"]), 1.0), "level 1 cộng +1 mọi chỉ số tay đua")
	_check(is_equal_approx(float(lv_stats["S"]), float(base_stats["S"])), "không đổi chỉ số xe")
	gs.driver_progress[an] = {"level": 5, "shards": 999}
	_check(gs.driver_upgrade_cost(an) == -1 and not gs.upgrade_driver(an), "đạt trần: Cấp tối đa, không nâng thêm")

	print("== Save / load ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 100
	gs.open_driver_pack("pro", 10, _rng(21))
	var owned_snapshot: Array = gs.owned_drivers.duplicate()
	var prog_snapshot: Dictionary = gs.driver_progress.duplicate(true)
	var pity_snapshot: int = gs.driver_pity_count("pro")
	var raw_save: Dictionary = gs._save_data()
	gs.init_new_game()
	gs._apply(raw_save)
	_check(gs.owned_drivers == owned_snapshot and str(gs.driver_progress) == str(prog_snapshot) and gs.driver_pity_count("pro") == pity_snapshot, "tải lại giữ tay đua, mảnh, level và bộ đếm bảo đảm")
	var dirty := raw_save.duplicate(true)
	dirty["driver_progress"]["driver_khong_ton_tai"] = {"level": 3, "shards": 4}
	dirty["driver_progress"]["driver_an"] = {"level": 99, "shards": -5}
	gs.init_new_game()
	gs._apply(dirty)
	_check(not gs.driver_progress.has("driver_khong_ton_tai") and gs.driver_level("driver_an") == 5 and gs.driver_shards("driver_an") == 0, "id lạ bị bỏ; level/mảnh ngoài cấu hình bị chặn")
	gs.init_new_game()
	gs._apply({"coins": 0, "schema_version": 1})
	_check(gs.driver_coupons == {"pro": 0, "allstar": 0} and gs.driver_progress.is_empty(), "save cũ không có trường gacha vẫn nạp được")

	print("== Hoàn tác khi lưu lỗi ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 100
	gs.simulate_write_failure = true
	var gems_b: int = gs.gems
	var owned_b: int = gs.owned_drivers.size()
	_check(gs.open_driver_pack("pro", 10, _rng(4)).is_empty() and gs.gems == gems_b and gs.owned_drivers.size() == owned_b and gs.driver_pity_count("pro") == 0, "mở gói lỗi lưu: hoàn tác gem, tay đua, bảo đảm")
	gs.driver_progress["driver_an"] = {"level": 0, "shards": 30}
	_check(not gs.upgrade_driver("driver_an") and gs.driver_level("driver_an") == 0 and gs.driver_shards("driver_an") == 30, "nâng lỗi lưu: hoàn tác")
	gs.simulate_write_failure = false

	print("driver_gacha_test: %d lỗi" % _fails)
	quit(1 if _fails > 0 else 0)


func BigNumber_zero() -> Variant:
	return preload("res://core/math/big_number.gd").zero()
