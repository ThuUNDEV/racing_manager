extends SceneTree
## Chạy: godot --headless --path . -s res://tests/class_test.gd
## Class đua (Design/22): dữ liệu, giá, mua, đổi class ở ranh giới lượt, save/checkpoint, Racing không đổi.

const BigNumber = preload("res://core/math/big_number.gd")
const MoneyCodec = preload("res://core/save/money_codec.gd")
var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	GameData.reload()
	_check(gs.SAVE_PATH.contains("/tests/"), "save cô lập khi chạy test")
	gs.init_new_game()

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "GameData.validate() sạch: %s" % str(GameData.validate()))
	_check(GameData.race_classes().size() == 6, "có 6 class")
	var racing_opts := GameData.class_opts("racing")
	_check((racing_opts["tuning"] as Dictionary).is_empty() and (racing_opts["traffic_tuning"] as Dictionary).is_empty(), "Racing không ghi đè gì (giữ nguyên kết quả)")
	var rally := GameData.class_opts("rally")
	_check(is_equal_approx(float(rally["tuning"]["corner_per_handling"]), 0.045 * 1.2), "Rally: corner_per_handling = 0,045 × 1,2")
	_check(is_equal_approx(float(rally["tuning"]["error_base"]), 0.35 * 1.2), "Rally: error_base nhân 1,2")
	_check(is_equal_approx(float(GameData.class_opts("monster")["traffic_tuning"]["draft_bonus"]), 0.0), "Monster Truck: hết hút gió")

	print("== Mới vào game ==")
	_check(gs.class_owned == ["racing"] and gs.active_class == "racing" and gs.pending_class == "", "chỉ có Racing, đang dùng Racing")
	_check(gs.facilities == ["racing"] and gs.facility_limit() == 6, "1 cơ sở (Racing), tối đa 6")
	var p2: BigNumber = gs.facility_price()
	_check(p2.equals(Pricing.expansion_cost(0).multiply_ratio(50, 100)), "cơ sở thứ 2 = 0,5× phí mở rộng giải")
	gs.facilities.append("")
	var p3: BigNumber = gs.facility_price()
	gs.facilities.append("")
	var p4: BigNumber = gs.facility_price()
	gs.facilities = ["racing"]
	_check(p3.compare(p2) > 0 and p4.compare(p3) > 0, "giá cơ sở tăng dần theo số cơ sở đã mở")

	print("== Mở cơ sở rồi chọn class ==")
	gs.coins = BigNumber.zero()
	_check(gs.facility_state() == "short" and not gs.buy_facility() and gs.facilities.size() == 1, "thiếu tiền: không mở, không trừ")
	_check(not gs.assign_facility("rally"), "chưa có cơ sở trống thì không chọn được class")
	_check(not gs.select_class("rally"), "class chưa có cơ sở thì không chọn được")
	gs.coins = p2.add(BigNumber.from_int(5))
	_check(gs.facility_state() == "ok" and gs.buy_facility(), "đủ tiền: mở được cơ sở")
	_check(gs.coins.equals(5) and gs.facilities == ["racing", ""] and gs.facility_unassigned() == 1, "trừ đúng giá, cơ sở chờ chọn class")
	_check(gs.facility_state() == "unassigned" and not gs.buy_facility(), "phải chọn class cho cơ sở đang chờ trước khi mở thêm")
	_check(not gs.assign_facility("racing"), "không chọn class đã có cơ sở")
	_check(not gs.assign_facility("ghost"), "không chọn class lạ")
	gs.simulate_write_failure = true
	_check(not gs.assign_facility("rally") and gs.facilities == ["racing", ""] and not gs.class_has("rally"), "lỗi ghi save: hoàn nguyên việc chọn class")
	gs.simulate_write_failure = false
	_check(gs.assign_facility("rally") and gs.class_has("rally") and gs.facilities == ["racing", "rally"], "chọn Rally cho cơ sở mới")
	_check(gs.active_class == "racing" and gs.facility_unassigned() == -1, "chọn xong không tự đổi Active")
	_check(not gs.assign_facility("stock"), "không còn cơ sở trống để chọn")
	gs.coins = BigNumber.from_int(1000000000)
	gs.simulate_write_failure = true
	_check(not gs.buy_facility() and gs.facilities.size() == 2 and gs.coins.equals(1000000000), "lỗi ghi save: hoàn nguyên tiền và cơ sở")
	gs.simulate_write_failure = false
	gs.coins = BigNumber.from_int(1000)
	gs.activate()
	_check(gs.phase == "countdown" and gs.race_class_id == "racing", "countdown ban đầu dùng Racing")

	print("== Đổi class ==")
	_check(gs.select_class("rally") and gs.active_class == "rally" and gs.race_class_id == "rally" and gs.pending_class == "", "đang countdown: áp dụng ngay")
	_check(gs.sim.cars.size() > 0, "grid xem trước dựng lại")
	for i in 31:
		gs.advance(0.1)
	_check(gs.phase == "racing" and String(gs.race_snapshot["class_id"]) == "rally", "xuất phát với snapshot class Rally")
	_check(gs.select_class("racing") and gs.active_class == "rally" and gs.pending_class == "racing" and gs.race_class_id == "rally", "đang đua: chỉ đặt pending, lượt hiện tại giữ Rally")
	_check(gs.select_class("rally") and gs.pending_class == "", "chọn lại class đang đua hủy pending")
	gs.select_class("racing")
	var cp: Dictionary = gs._checkpoint()
	_check(String(cp.get("class_id", "")) == "rally", "checkpoint ghi class của lượt")
	var ticks_before: int = gs.sim.tick_count
	var saved: Dictionary = gs._save_data()
	_check(saved["pending_class"] == "racing" and saved["active_class"] == "rally" and (saved["facilities"] as Array).has("rally"), "save có facilities/active/pending")

	print("== Khôi phục từ save ==")
	var raw := JSON.stringify(MoneyCodec.encode(saved))
	var parsed: Variant = MoneyCodec.parse(raw)
	_check(gs._valid_save(parsed), "save v9 hợp lệ")
	gs.init_new_game()
	_check(gs.class_owned == ["racing"], "init_new_game xóa class đã mua")
	gs._apply(parsed)
	gs.active = false
	gs.phase = "idle"
	_check(gs.class_has("rally") and gs.active_class == "rally" and gs.pending_class == "racing", "nạp lại giữ class và pending")
	gs.activate()
	_check(gs.phase == "racing" and gs.race_class_id == "rally" and gs.sim.tick_count >= ticks_before - 1, "checkpoint khôi phục đúng class của lượt")
	while gs.phase == "racing":
		gs.advance(1.0)
	for i in 5:
		gs.advance(0.5)
	_check(gs.active_class == "racing" and gs.pending_class == "" and gs.race_class_id == "racing", "sau lượt chốt: pending được áp dụng ở countdown kế")

	print("== Save cũ (không có class) ==")
	var old: Dictionary = gs._save_data()
	for k in ["facilities", "class_owned", "active_class", "pending_class"]:
		old.erase(k)
	old["schema_version"] = 8
	gs.init_new_game()
	_check(gs._valid_save(MoneyCodec.parse(JSON.stringify(MoneyCodec.encode(old)))), "save v8 vẫn hợp lệ")
	gs._apply(MoneyCodec.parse(JSON.stringify(MoneyCodec.encode(old))))
	_check(gs.class_owned == ["racing"] and gs.active_class == "racing", "migration: chỉ Racing")
	var v9: Dictionary = old.duplicate(true)
	v9["class_owned"] = ["racing", "stock"]
	gs.init_new_game()
	gs._apply(MoneyCodec.parse(JSON.stringify(MoneyCodec.encode(v9))))
	_check(gs.facilities == ["racing", "stock"] and gs.class_has("stock"), "migration save v9 dev: class đã mua thành cơ sở đã chọn class")
	var bad: Dictionary = old.duplicate(true)
	bad["facilities"] = ["ghost", "rally", "racing", "rally"]
	bad["active_class"] = "ghost"
	bad["pending_class"] = "ghost"
	gs.init_new_game()
	gs._apply(MoneyCodec.parse(JSON.stringify(MoneyCodec.encode(bad))))
	_check(gs.class_owned == ["racing", "rally"] and gs.active_class == "racing" and gs.pending_class == "", "dữ liệu lạ bị lọc, active/pending về mặc định")

	print("== Racing giữ nguyên kết quả ==")
	GameData.reload()
	var a := TrafficSim.new()
	a.setup(12345, {"S": 40, "H": 40, "B": 40, "A": 40, "P": 40, "T": 40, "C": 40}, 0, GameState.PROTOTYPE_TRACK, {"duration": 30.0, "sprint_duration": 0.0})
	var b := TrafficSim.new()
	var co := GameData.class_opts("racing")
	b.setup(12345, {"S": 40, "H": 40, "B": 40, "A": 40, "P": 40, "T": 40, "C": 40}, 0, GameState.PROTOTYPE_TRACK, {"duration": 30.0, "sprint_duration": 0.0, "tuning": co["tuning"], "traffic_tuning": co["traffic_tuning"]})
	for i in 300:
		a.step()
		b.step()
	var same := true
	for i in a.cars.size():
		if a.cars[i].s != b.cars[i].s:
			same = false
	_check(same, "Racing có tuning rỗng cho cùng vị trí xe từng bit")
	var r := TrafficSim.new()
	var ro := GameData.class_opts("speed")
	r.setup(12345, {"S": 40, "H": 40, "B": 40, "A": 40, "P": 40, "T": 40, "C": 40}, 0, GameState.PROTOTYPE_TRACK, {"duration": 30.0, "sprint_duration": 0.0, "tuning": ro["tuning"], "traffic_tuning": ro["traffic_tuning"]})
	for i in 300:
		r.step()
	var differs := false
	for i in a.cars.size():
		if a.cars[i].s != r.cars[i].s:
			differs = true
	_check(differs, "Speedster cho kết quả khác Racing")

	print("\nKết quả: %s" % ("ĐẠT" if _fails == 0 else "%d lỗi" % _fails))
	quit(1 if _fails > 0 else 0)
