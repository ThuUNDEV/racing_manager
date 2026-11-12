extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Garage (Design/15): ngoại hình từng xe, lưu/tải, nâng cấp xe dự bị theo car_id, snapshot lượt đua.
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	print(("  ok   " if ok else "  FAIL "), msg)
	if not ok:
		_fails += 1


func _initialize() -> void:
	await process_frame
	GameData.reload()
	var gs: Node = root.get_node("GameState")
	gs.reset_progress()
	var a: String = gs.active_car_id
	var b := "car_pico_bam_duong"

	print("== Danh mục ngoại hình ==")
	_check(GameData.paints().size() == 8 and GameData.decals().size() == 4, "8 màu và 4 decal")
	for p: Dictionary in GameData.paints():
		_check(ResourceLoader.exists("res://assets/workshop_gp/" + String(p["texture"])), "có texture màu " + String(p["id"]))

	print("== Ngoại hình lưu theo xe ==")
	_check(gs.cosmetics_of(a) == {"paint_id": "orange", "decal_id": "none"}, "xe mới dùng cam/trống")
	var stats_before: Dictionary = gs.player_stats()
	_check(not gs.set_cosmetics(b, "red", "none"), "không chỉnh xe chưa sở hữu")
	_check(not gs.set_cosmetics(a, "pink", "none") and not gs.set_cosmetics(a, "red", "zebra"), "từ chối id lạ")
	_check(gs.set_cosmetics(a, "blue", "lightning"), "lưu màu/decal cho xe đang dùng")
	_check(gs.player_stats() == stats_before, "ngoại hình không đổi chỉ số")
	gs.coins = BigNumber.from_int(1000000)
	_check(gs.buy_car(b) and gs.active_car_id == a, "mua xe mới không tự chọn")
	_check(gs.cosmetics_of(b)["paint_id"] == "orange", "xe mua mới có ngoại hình mặc định")
	_check(gs.set_cosmetics(b, "teal", "checker") and gs.cosmetics_of(a)["paint_id"] == "blue", "mỗi xe giữ ngoại hình riêng")
	gs.simulate_write_failure = true
	_check(not gs.set_cosmetics(a, "red", "none") and gs.cosmetics_of(a)["paint_id"] == "blue", "lỗi ghi: hoàn tác ngoại hình")
	gs.simulate_write_failure = false
	var saved: Dictionary = gs._save_data()
	gs.init_new_game()
	gs._apply(saved)
	_check(gs.cosmetics_of(a)["decal_id"] == "lightning" and gs.cosmetics_of(b)["paint_id"] == "teal", "tải lại giữ ngoại hình từng xe")
	var old := saved.duplicate(true)
	old.erase("garage_cosmetics")
	old["schema_version"] = 5
	gs.init_new_game()
	gs._apply(old)
	_check(gs.cosmetics_of(a) == {"paint_id": "orange", "decal_id": "none"}, "save v5 không có ngoại hình dùng mặc định")
	var bad := saved.duplicate(true)
	bad["garage_cosmetics"] = {a: {"paint_id": "nope", "decal_id": 5}, "car_khong_co": {"paint_id": "red", "decal_id": "none"}}
	gs.init_new_game()
	gs._apply(bad)
	_check(gs.cosmetics_of(a) == {"paint_id": "orange", "decal_id": "none"} and not gs.garage_cosmetics.has("car_khong_co"), "id hỏng/xe lạ rơi về mặc định")

	print("== Nâng cấp xe dự bị theo car_id ==")
	gs.reset_progress()
	gs.coins = BigNumber.from_int(1000000)
	_check(gs.buy_car(b), "mua xe thứ hai")
	var lv_a: int = gs.level_of("engine")
	var coins0: BigNumber = gs.coins
	var plan: Dictionary = gs.plan_buy("engine", 10, b)
	_check(int(plan["count"]) == 10, "kế hoạch ×10 cho xe dự bị")
	_check(gs.buy_many_for(b, "engine", 10), "nâng ×10 xe dự bị")
	_check(gs.active_car_id == a and gs.level_of("engine") == lv_a, "xe đang dùng không đổi")
	_check(gs.car_level(b, "engine") == 10 and int(gs.car_levels[b]["engine"]) == 10, "cấp ghi vào đúng xe dự bị")
	_check(gs.coins.equals(coins0.subtract_checked(plan["cost"])), "trừ đúng tổng giá")
	gs.simulate_write_failure = true
	var coins1: BigNumber = gs.coins
	_check(not gs.buy_many_for(b, "engine", 1) and gs.coins.equals(coins1) and gs.car_level(b, "engine") == 10, "lỗi ghi: hoàn tác tiền và cấp")
	gs.simulate_write_failure = false
	gs.coins = BigNumber.zero()
	_check(gs.car_upgrade_state(b, "engine") == "short" and not gs.buy_many_for(b, "engine", 1), "thiếu tiền thì không mua")
	gs.coins = BigNumber.from_int(1000000)
	_check(not gs.buy_many_for("car_nova_tia_chop", "engine", 1), "không nâng xe chưa sở hữu")
	_check(gs.buy_many_for(a, "tyre", 1) and gs.level_of("tyre") == 1 and int(gs.car_levels[a]["tyre"]) == 1, "xe đang dùng đi qua giao dịch cũ")
	_check(is_equal_approx(gs.car_part_stat(b, "engine", 10), 38.0 + 2.5), "chỉ số xe dự bị = nền + 0,25 (động cơ) × cấp")
	var ids: Array = GameData.cars().map(func(c: Dictionary) -> String: return String(c["id"]))
	gs.car_levels[b]["engine"] = Balance.max_level() - 3
	_check(gs.plan_buy("engine", 10, b)["count"] == 3, "×10 gần trần chỉ mua phần còn lại")
	_check(ids.size() == 15, "15 xe")

	print("== Snapshot lượt đua giữ ngoại hình ==")
	gs.reset_progress()
	gs.set_cosmetics(a, "red", "double_stripe")
	gs.begin_countdown()
	gs.advance(float(Balance.COUNTDOWN_SECONDS) + 0.1)
	_check(gs.phase == "racing" and gs.race_snapshot["paint_id"] == "red", "snapshot ghi màu lúc xuất phát")
	gs.set_cosmetics(a, "blue", "checker")
	_check(gs.race_cosmetics() == {"paint_id": "red", "decal_id": "double_stripe"}, "đang đua vẫn hiện ngoại hình snapshot")
	_check(gs.cosmetics_of(a)["paint_id"] == "blue", "ngoại hình mới đã lưu cho lượt sau")
	var cp: Dictionary = gs._checkpoint()
	_check(String(cp["snapshot"]["paint_id"]) == "red", "checkpoint chứa ngoại hình snapshot")

	print("== Kết quả: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)
