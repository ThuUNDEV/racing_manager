extends SceneTree
## Chạy: godot --headless --path . -s res://tests/facility_test.gd
## Cơ sở độc lập (Design/26 F0–F1): mỗi cơ sở có nâng cấp/giải/xe/cúp riêng, một ví chung, đổi Quản lý tức thì, thưởng vào đúng cơ sở.

const BigNumber = preload("res://core/math/big_number.gd")
const MoneyCodec = preload("res://core/save/money_codec.gd")
var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _roundtrip(gs: Node) -> Dictionary:
	return MoneyCodec.parse(JSON.stringify(MoneyCodec.encode(gs._save_data())))


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	GameData.reload()
	_check(gs.SAVE_PATH.contains("/tests/"), "save cô lập khi chạy test")
	gs.init_new_game()

	print("== F0: một cơ sở, save cũ ==")
	_check(gs.managed_class == "racing" and gs.businesses.is_empty(), "mới vào: quản lý Racing, chưa có cơ sở khác")
	var snap: Dictionary = gs._business_snapshot()
	_check(int(snap["business_tier"]) == 0 and snap["owned_cars"].size() == 1, "snapshot cơ sở có giải 0 và 1 xe")
	var old: Dictionary = _roundtrip(gs)
	old.erase("businesses")
	old.erase("managed_class")
	_check(gs._valid_save(old), "save không có businesses vẫn hợp lệ")
	gs.coins = BigNumber.from_int(777)
	gs._apply(old)
	_check(gs.managed_class == "racing" and gs.businesses.is_empty(), "migration: chỉ cơ sở Racing")

	print("== F1: mở cơ sở thứ hai ==")
	gs.coins = BigNumber.from_int(1000000000000)
	gs.coins = gs.coins.multiply(BigNumber.from_int(1000000))
	var gems_before: int = gs.gems
	_check(gs.buy_facility() and gs.facilities == ["racing", ""], "mở cơ sở: chờ chọn loại")
	_check(gs.assign_facility("rally") and gs.managed_class == "rally", "chọn Rally: tự chuyển sang quản lý Rally")
	_check(gs.gems == gems_before + int(GameData.economy()["rewards"]["first_league_gems"]), "thưởng gem mở cơ sở một lần")
	_check(gs.business_tier == 0 and gs.level_of("ticket") == 0 and gs.owned_cars.size() == 1 and gs.trophies == 0, "Rally mới: giải 0, cấp 0, 1 xe, 0 cúp")
	_check(gs.businesses.has("racing") and not gs.businesses.has("rally"), "Racing được cất vào businesses")
	_check(gs.has_business("racing") and gs.has_business("rally"), "has_business đúng")

	print("== Độc lập giữa các cơ sở ==")
	var coins_a: BigNumber = gs.coins
	_check(gs.buy_many("ticket", 5) and gs.level_of("ticket") == 5, "nâng Ticket ở Rally lên 5")
	var racing_levels: Dictionary = gs.businesses["racing"]["levels"]
	_check(int(racing_levels["ticket"]) == 0, "Racing không đổi")
	_check(gs.coins.compare(coins_a) < 0, "tiền trừ từ ví chung")
	_check(gs.manage_class("racing") and gs.managed_class == "racing" and gs.level_of("ticket") == 0, "đổi sang Racing: Ticket cấp 0")
	_check(gs.buy_many("ticket", 8) and gs.level_of("ticket") == 8, "nâng Ticket ở Racing lên 8")
	_check(gs.manage_class("rally") and gs.level_of("ticket") == 5, "quay lại Rally: Ticket vẫn cấp 5")
	_check(not gs.manage_class("stock") and gs.managed_class == "rally", "không quản lý được class chưa có cơ sở")

	print("== Một ví chung ==")
	var r_rally: BigNumber = gs.facility_rate("rally")
	var r_racing: BigNumber = gs.facility_rate("racing")
	_check(r_racing.compare(BigNumber.zero()) > 0 and r_rally.compare(BigNumber.zero()) > 0, "mỗi cơ sở có thu nhập riêng")
	_check(gs.total_online_rate().equals(r_rally.add(r_racing)), "tổng thu nhập = cộng các cơ sở")
	gs.active = true
	gs.suspended = false
	var c0: BigNumber = gs.coins
	gs.tick_income(10.0)
	var gained: BigNumber = gs.coins.subtract_checked(c0)
	_check(gained.compare(r_rally.multiply_ratio(10, 1)) > 0, "tick cộng cả thu nhập cơ sở không quản lý")
	_check(gs.total_online_rate().compare(gs.online_rate()) > 0, "tổng lớn hơn thu nhập cơ sở đang quản lý")

	print("== Giá mở cơ sở theo giải cao nhất ==")
	var p_now: BigNumber = gs.facility_price()
	gs.businesses["racing"]["business_tier"] = 1
	gs.businesses["racing"]["unlocked_tier"] = 2
	gs._total_key = ""
	_check(gs.max_facility_tier() == 1, "giải cao nhất = 1 dù đang quản lý Rally giải 0")
	_check(gs.facility_price().compare(p_now) > 0, "giá cơ sở kế tăng theo giải cao nhất")
	gs.businesses["racing"]["business_tier"] = 0
	gs.businesses["racing"]["unlocked_tier"] = 1
	gs._total_key = ""

	print("== Save và nạp lại ==")
	var saved: Dictionary = _roundtrip(gs)
	_check(gs._valid_save(saved), "save nhiều cơ sở hợp lệ")
	var before_rally := int(gs.level_of("ticket"))
	gs.init_new_game()
	_check(gs.businesses.is_empty() and gs.managed_class == "racing", "init xóa cơ sở phụ")
	gs._apply(saved)
	_check(gs.managed_class == "rally" and gs.level_of("ticket") == before_rally and int(gs.businesses["racing"]["levels"]["ticket"]) == 8, "nạp lại: Rally đang quản lý, Racing còn Ticket 8")
	var bad: Dictionary = _roundtrip(gs)
	bad["businesses"]["racing"]["levels"]["ticket"] = 99999
	_check(not gs._valid_save(bad), "cơ sở có cấp vượt trần bị từ chối")
	bad = _roundtrip(gs)
	bad["businesses"]["ghost"] = {}
	_check(not gs._valid_save(bad), "cơ sở class lạ bị từ chối")

	print("== Đua ở cơ sở khác cơ sở đang quản lý ==")
	gs.init_new_game()
	gs.coins = BigNumber.from_int(1000000000000).multiply(BigNumber.from_int(1000000))
	gs.buy_facility()
	gs.assign_facility("rally")
	gs.manage_class("racing")
	gs.active = false
	gs.phase = "idle"
	gs.activate()
	_check(gs.phase == "countdown" and gs.race_class_id == "racing", "đua Racing")
	for i in 31:
		gs.advance(0.1)
	_check(gs.phase == "racing", "đang đua Racing")
	_check(gs.manage_class("rally") and gs.managed_class == "rally" and gs.phase == "racing" and gs.race_class_id == "racing", "đang đua: đổi Quản lý sang Rally tức thì, cuộc đua không đổi")
	_check(gs.buy_many("ticket", 3) and gs.level_of("ticket") == 3, "nâng cấp Rally giữa lượt đua")
	var racing_trophies_before: int = int(gs.businesses["racing"]["trophies_earned"])
	var racing_results_before: int = (gs.businesses["racing"]["recent_results"] as Array).size()
	var rally_results_before: int = gs.recent_results.size()
	var coins_race: BigNumber = gs.coins
	var races_before: int = gs.completed_races
	var guard := 0
	while gs.phase == "racing" and guard < 5000:
		gs.advance(1.0)
		guard += 1
	_check(gs.completed_races == races_before + 1, "đua xong: tính một lượt")
	_check(gs.managed_class == "rally", "đua xong: vẫn quản lý Rally")
	_check((gs.businesses["racing"]["recent_results"] as Array).size() == racing_results_before + 1, "kết quả lượt ghi vào Racing")
	_check(gs.recent_results.size() == rally_results_before, "Rally (đang quản lý) không có kết quả mới")
	_check(gs.coins.compare(coins_race) > 0, "thưởng vào ví chung")
	_check(gs.level_of("ticket") == 3, "nâng cấp Rally giữa lượt không mất")
	_check(int(gs.businesses["racing"]["trophies_earned"]) >= racing_trophies_before, "cúp thuộc Racing")
	_check(gs.phase == "countdown" or gs.phase == "idle" or gs.phase == "racing", "vòng lặp tiếp tục")

	print("== Chuyển cơ sở đang đua và khôi phục checkpoint ==")
	gs.select_class("rally")
	_check(gs.active_class == "rally" or gs.pending_class == "rally", "đặt Rally làm cơ sở đua")
	guard = 0
	while gs.race_class_id != "rally" and guard < 5000:
		gs.advance(1.0)
		guard += 1
	_check(gs.race_class_id == "rally", "lượt kế dùng Rally")
	gs.manage_class("racing")
	for i in 31:
		gs.advance(0.1)
	var cp_saved: Dictionary = _roundtrip(gs)
	_check(String(cp_saved["checkpoint"].get("class_id", "")) == "rally" and cp_saved["managed_class"] == "racing", "checkpoint ghi Rally, đang quản lý Racing")
	var ticks: int = gs.sim.tick_count
	gs.active = false
	gs.phase = "idle"
	gs._apply(cp_saved)
	gs.activate()
	_check(gs.phase == "racing" and gs.race_class_id == "rally" and gs.managed_class == "racing", "khôi phục: đua Rally, quản lý Racing")
	_check(gs.sim.tick_count >= ticks - 1, "khôi phục đúng số tick")

	print("== Khóa khi lỗi lưu ==")
	gs.simulate_write_failure = true
	_check(not gs.manage_class("rally") and gs.managed_class == "racing", "lỗi ghi save: không đổi Quản lý")
	gs.simulate_write_failure = false

	print("\nKết quả: %s" % ("ĐẠT" if _fails == 0 else "%d lỗi" % _fails))
	quit(1 if _fails > 0 else 0)
