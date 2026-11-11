extends SceneTree

## Trang bị (Design/14): dữ liệu, mở gói, mới/trùng, mảnh riêng, nâng level, coupon, save/load, hoàn tác.
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
	gs.SAVE_PATH = "user://gear_test_save.json"
	gs.BAK_PATH = "user://gear_test_save.bak"
	gs.TMP_PATH = "user://gear_test_save.tmp"

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	_check(GameData.gear_items().size() == 30, "30 phụ kiện")
	var std := GameData.gear_pack("standard")
	var elite := GameData.gear_pack("elite")
	_check(int(std["price_x1"]) == 10 and int(std["price_x10"]) == 100, "Standard 10/100 gem")
	_check(int(elite["price_x1"]) == 30 and int(elite["price_x10"]) == 300, "Elite 30/300 gem")
	_check(is_equal_approx(float(std["tiers"]["rare"]), 85.0) and is_equal_approx(float(std["tiers"]["epic"]), 15.0)
		and is_equal_approx(float(elite["tiers"]["epic"]), 85.0) and is_equal_approx(float(elite["tiers"]["legendary"]), 15.0)
		and std["tiers"].size() == 2 and elite["tiers"].size() == 2, "tỉ lệ bậc đúng ảnh tham chiếu")
	_check(not GameData.gear_item("gear_balaclava").is_empty(), "có Balaclava")

	print("== Validate cấu hình ==")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/gear.json"))
	var bad := raw.duplicate(true)
	bad["packs"][0]["tiers"] = {"rare": 80, "epic": 15}
	GameData.set_override("gear", bad)
	_check(not GameData.validate().is_empty(), "tỉ lệ không đủ 100% bị từ chối")
	bad = raw.duplicate(true)
	(bad["rarity_defaults"]["rare"]["level_up_shards"] as Array).pop_back()
	GameData.set_override("gear", bad)
	_check(not GameData.validate().is_empty(), "bảng ngưỡng thiếu bị từ chối")
	bad = raw.duplicate(true)
	bad["rarity_defaults"]["rare"]["level_up_shards"][1] = 0
	GameData.set_override("gear", bad)
	_check(not GameData.validate().is_empty(), "ngưỡng không dương bị từ chối")
	GameData.reload()

	print("== Thanh toán ==")
	gs.init_new_game()
	gs.save_blocked = false
	gs.gems = 1000
	_check(gs.gear_payment("standard", 1) == {"method": "gem", "amount": 10}, "x1 không coupon dùng gem")
	_check(gs.gear_payment("elite", 10) == {"method": "gem", "amount": 300}, "x10 Elite 300 gem")
	_check(gs.grant_gear_coupons("standard", 3), "cấp coupon Standard")
	_check(gs.gear_payment("standard", 1)["method"] == "coupon", "có coupon thì dùng coupon trước gem")
	_check(gs.gear_payment("elite", 1)["method"] == "gem", "coupon Standard không dùng cho Elite")
	_check(gs.gear_payment("standard", 10)["method"] == "gem", "x10 với 3 coupon: trả gem, không trộn")
	var gems_before: int = gs.gems
	var res: Dictionary = gs.open_gear_pack("standard", 1, _rng(1))
	_check(not res.is_empty() and gs.gems == gems_before and gs.gear_coupons["standard"] == 2, "x1 bằng coupon: -1 coupon, không đổi gem")
	_check(gs.gear_coupons["elite"] == 0, "không đụng coupon Elite")
	gs.gems = 5
	_check(gs.open_gear_pack("elite", 1, _rng(2)).is_empty() and gs.gems == 5, "thiếu gem: từ chối, không đổi gì")

	print("== Mới / trùng, mảnh riêng ==")
	gs.init_new_game()
	gs.gems = 100000
	var ids_seen := {}
	var dup_total := 0
	var double_new := false
	var r := _rng(42)
	for i in 40:
		var out: Dictionary = gs.open_gear_pack("standard", 10, r)
		for e: Dictionary in out["results"]:
			if e["is_new"]:
				if ids_seen.has(e["id"]):
					double_new = true
				ids_seen[e["id"]] = true
			else:
				dup_total += int(e["shards"])
	_check(not double_new, "mẫu mới chỉ được thêm một lần")
	_check(gs.gear_owned_count() == ids_seen.size(), "bộ đếm sở hữu = số mẫu khác nhau, không theo số lần roll")
	_check(gs.gear_owned_count() <= 30 and gs.gear_open_count == 400, "đếm lượt mở 400")
	var shard_sum := 0
	for id: String in gs.gear_owned.keys():
		shard_sum += gs.gear_shards(id)
	_check(shard_sum == dup_total, "tổng mảnh = tổng mảnh nhận từ bản trùng")
	var rarities := {}
	for id: String in gs.gear_owned.keys():
		rarities[GameData.gear_item(id)["rarity"]] = true
	_check(not rarities.has("legendary"), "Standard không ra Legendary")
	var out10: Dictionary = gs.open_gear_pack("standard", 10, _rng(7))
	_check((out10["results"] as Array).size() == 10 and gs.gems == 100000 - 40 * 100 - 100, "x10 đúng 10 lượt, đúng giá")

	print("== Trùng trong cùng một x10 ==")
	gs.init_new_game()
	gs.gems = 1000
	# Ép mọi lượt ra cùng một mẫu bằng pool một phần tử.
	var single: Dictionary = raw.duplicate(true)
	single["items"] = [{"id": "only", "name": "Only", "rarity": "rare"}, {"id": "only_e", "name": "OnlyE", "rarity": "epic"}]
	single["packs"][0]["tiers"] = {"rare": 100}
	single["packs"][1]["tiers"] = {"epic": 100}
	GameData.set_override("gear", single)
	var o: Dictionary = gs.open_gear_pack("standard", 10, _rng(5))
	var news := 0
	for e: Dictionary in o["results"]:
		if e["is_new"]:
			news += 1
	_check(news == 1 and gs.gear_owned_count() == 1, "mẫu lặp trong x10: 1 mới, 9 trùng")
	_check(gs.gear_shards("only") == 9 * 5, "9 bản trùng cộng 45 mảnh (rare duplicate_shards = 5)")

	print("== Nâng level ==")
	var coins_before: Variant = gs.coins
	var gems_b: int = gs.gems
	_check(gs.gear_upgrade_cost("only") == 10 and gs.gear_level("only") == 0, "level 0, cần 10 mảnh")
	gs.gear_owned["only_e"] = {"level": 0, "shards": 3}
	_check(gs.upgrade_gear("only") and gs.gear_level("only") == 1 and gs.gear_shards("only") == 35, "nâng trừ đúng ngưỡng, giữ mảnh dư")
	_check(gs.gear_shards("only_e") == 3 and gs.gems == gems_b and gs.coins == coins_before, "không đụng mảnh món khác, gem, coins")
	_check(not gs.upgrade_gear("only_e"), "thiếu mảnh không nâng được")
	gs.gear_owned["only"]["shards"] = 10000
	while gs.upgrade_gear("only"):
		pass
	_check(gs.gear_level("only") == gs.gear_max_level("only") and gs.gear_upgrade_cost("only") == -1, "khóa ở level tối đa")
	var st: Dictionary = gs.gear_stats_at("only", gs.gear_level("only"))
	_check(st == {"attack": 70, "defense": 70}, "chỉ số theo bảng cấu hình ở max")
	_check(gs.gear_bonus()["attack"] == 70 + 40, "bonus toàn đội = tổng các mẫu theo level")
	GameData.reload()

	print("== Save / load / hoàn tác ==")
	gs.init_new_game()
	gs.gems = 1000
	gs.open_gear_pack("elite", 10, _rng(9))
	var snap: Dictionary = gs._save_data()
	var owned_n: int = gs.gear_owned_count()
	gs.init_new_game()
	gs._apply(snap)
	_check(gs.gear_owned_count() == owned_n and gs.gear_open_count == 10 and gs.last_gear_result.size() == 10, "tải lại giữ sở hữu và kết quả")
	var old := snap.duplicate(true)
	for k in ["gear_owned", "gear_coupons", "gear_open_count", "last_gear_result"]:
		old.erase(k)
	old["schema_version"] = 6
	gs.init_new_game()
	gs._apply(old)
	_check(gs.gear_owned_count() == 0 and gs.gear_coupons["elite"] == 0, "save v6 không có phụ kiện: bắt đầu rỗng")
	var corrupt := snap.duplicate(true)
	corrupt["gear_owned"] = {"khong_co": {"level": 1, "shards": 1}}
	for id: String in snap["gear_owned"].keys():
		corrupt["gear_owned"][id] = {"level": 99, "shards": -5}
	gs.init_new_game()
	gs._apply(corrupt)
	_check(not gs.gear_owned.has("khong_co"), "id lạ bị bỏ")
	var any_id: String = gs.gear_owned.keys()[0]
	_check(gs.gear_level(any_id) == gs.gear_max_level(any_id) and gs.gear_shards(any_id) == 0, "level/mảnh hỏng bị chặn trong cấu hình")
	gs.init_new_game()
	gs.gems = 1000
	gs.simulate_write_failure = true
	var f: Dictionary = gs.open_gear_pack("standard", 10, _rng(3))
	_check(f.is_empty() and gs.gems == 1000 and gs.gear_owned_count() == 0 and gs.gear_open_count == 0, "lỗi lưu: hoàn tác gem, sở hữu, đếm")
	gs.simulate_write_failure = false
	gs.open_gear_pack("standard", 1, _rng(4))
	var owned_id: String = gs.gear_owned.keys()[0]
	gs.gear_owned[owned_id]["shards"] = 100
	gs.simulate_write_failure = true
	_check(not gs.upgrade_gear(owned_id) and gs.gear_level(owned_id) == 0 and gs.gear_shards(owned_id) == 100, "lỗi lưu: hoàn tác nâng level và mảnh")
	gs.simulate_write_failure = false

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gear_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gear_test_save.bak"))
	print("")
	print("GEAR TEST: %s" % ("ĐẠT" if _fails == 0 else "%d LỖI" % _fails))
	quit(1 if _fails > 0 else 0)

