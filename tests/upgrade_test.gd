extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Kiểm tra tám nâng cấp, công thức doanh thu, lưu và chuyển save cũ.
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
	_check(gs.levels.size() == 8, "đúng 8 chỉ số nâng cấp")
	_check(not gs.buy("driver") and not gs.buy("venue") and not gs.buy("unknown"), "từ chối nâng cấp đã bỏ / không hợp lệ")
	_check(gs.online_rate().equals(8), "thu nhập nền giữ 8/giây")
	gs.coins = BigNumber.from_int(1000000)
	for kind in Balance.REVENUE:
		var before: BigNumber = gs.online_rate()
		var coins_before: BigNumber = gs.coins
		var cost: BigNumber = gs.cost_of(kind)
		_check(gs.buy(kind) and gs.coins.equals(coins_before.subtract_checked(cost)) and gs.level_of(kind) == 1, "mua và trừ đúng giá: " + kind)
		_check(gs.online_rate().compare(before) > 0, "tăng thu nhập: " + kind)
	_check(gs.online_rate().equals("10.7695875"), "ba nguồn cộng (cấp 1 = per_level x 1,003), sức chứa 10,5/10 tuyến tính")
	var before_tick: BigNumber = gs.coins
	gs.tick_income(2.0)
	_check(gs.coins.subtract_checked(before_tick).equals(21) and gs.income_remainder.equals("0.539175"), "thu nhập thực có giữ phần lẻ")
	gs.begin_countdown()
	gs.advance(3.0)
	var snapshot: Dictionary = gs.race_snapshot.duplicate(true)
	var before_rate: BigNumber = gs.online_rate()
	gs.buy("parking")
	_check(gs.online_rate().compare(before_rate) > 0 and not gs.applies_next_race("parking") and gs.race_snapshot == snapshot, "doanh thu áp dụng ngay, không đổi cuộc đua")
	var saved_levels: Dictionary = gs.levels.duplicate(true)
	var saved_coins: BigNumber = gs.coins
	_check(gs.save_game(), "lưu tám cấp")
	gs.init_new_game()
	gs.load_game()
	_check(gs.levels == saved_levels and gs.coins.equals(saved_coins), "khôi phục đủ tám cấp và tiền")
	gs.coins = BigNumber.from_int(0)
	gs.last_accrual_utc = Time.get_unix_time_from_system() - 100.0
	var expected := Pricing.offline_reward(gs.saved_online_rate, 100.0)
	gs.settle_offline()
	_check(gs.coins.compare(expected) >= 0 and gs.coins.compare(expected.add(BigNumber.from_int(2))) <= 0, "offline dùng doanh thu đã nâng cấp")
	gs.init_new_game()
	gs._apply({"schema_version": 2, "coins": 17, "venue_level": 3, "driver_level": 2, "levels": {"engine": 4}})
	_check(gs.level_of("ticket") == 30 and gs.level_of("engine") == 40 and gs.level_of("parking") == 0, "save v2 nhân cấp ×10 sang thang 200, Cơ sở thành Ticket Marketing")
	_check(gs.coins.equals(235), "hoàn đúng tiền huấn luyện đã bỏ")
	gs.save_game()
	var migrated_coins: BigNumber = gs.coins
	gs.init_new_game()
	gs.load_game()
	_check(gs.coins.equals(migrated_coins), "nạp save v3 không hoàn tiền lần hai")
	for kind in Balance.REVENUE:
		gs.levels[kind] = Balance.max_level()
		_check(gs.upgrade_state(kind) == "maxed" and not gs.buy(kind), "giới hạn cấp: " + kind)
	# Thang 200 cấp (Design/13): giá, mua nhiều cấp, migration v4 → v5.
	gs.init_new_game()
	gs.save_blocked = true
	_check(Balance.max_level() == 200 and absf(Pricing.part_stat_per_level() - 0.2) < 1e-9, "max_level 200, mặc định +0,2 chỉ số mỗi cấp")
	_check(absf(Pricing.part_stat_per_level("engine") - 0.25) < 1e-9 and absf(Pricing.part_stat_per_level("tyre") - 0.15) < 1e-9, "mỗi bộ phận có hệ số riêng")
	_check(absf((gs.part_stat("engine", 10) - gs.part_stat("engine", 0)) - 2.5) < 1e-6, "động cơ 10 cấp = +2,5 chỉ số")
	_check(absf((gs.part_stat("tyre", 10) - gs.part_stat("tyre", 0)) - 1.5) < 1e-6, "lốp 10 cấp = +1,5 chỉ số")
	var ten_sum := BigNumber.zero()
	for m in 10:
		ten_sum = ten_sum.add(Pricing.part_cost(0, m))
	var one_old := 120 * 3  # base × D (D = 3), cấp cũ 0
	_check(ten_sum.compare(BigNumber.from_int(one_old)) >= 0 and ten_sum.compare(BigNumber.from_int(one_old + 10)) <= 0, "tổng giá 10 cấp nhỏ ≈ giá một cấp cũ × D")
	var monotonic := true
	for m in 199:
		if Pricing.part_cost(0, m + 1).compare(Pricing.part_cost(0, m)) < 0:
			monotonic = false
	_check(monotonic and Pricing.part_cost(0, 199).compare(Pricing.part_cost(0, 0)) > 0, "giá không giảm đến cấp 199")
	gs.coins = BigNumber.from_int(100000000)
	var plan10: Dictionary = gs.plan_buy("engine", 10)
	var manual := BigNumber.zero()
	for m in 10:
		manual = manual.add(Pricing.part_cost(0, m, "engine"))
	_check(int(plan10["count"]) == 10 and plan10["cost"].equals(manual), "plan ×10 bằng cộng từng cấp")
	var coins0: BigNumber = gs.coins
	var tyre_sum := BigNumber.zero()
	for m in 10:
		tyre_sum = tyre_sum.add(Pricing.part_cost(0, m, "tyre"))
	gs.save_blocked = false
	gs.levels = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0, "ticket": 0, "celebration": 0, "parking": 0, "grandstands": 0}
	_check(gs.buy_many("tyre", 10) and gs.level_of("tyre") == 10 and gs.coins.equals(coins0.subtract_checked(tyre_sum)), "mua ×10 trừ đúng tổng")
	gs.coins = BigNumber.from_int(1000000000)
	_check(gs.buy_many("chassis", 0) and gs.level_of("chassis") == 200 and not gs.buy_many("chassis", 10), "×Max lên cấp 200 rồi dừng")
	gs.coins = BigNumber.from_int(1)
	_check(not gs.buy_many("engine", 10) and gs.level_of("engine") == 0, "thiếu tiền thì không mua")
	gs.init_new_game()
	gs._apply({"schema_version": 4, "coins": "5", "levels": {"engine": 7, "ticket": 20}, "car_levels": {"car_pico_tia_chop": {"engine": 7}}})
	_check(gs.level_of("engine") == 70 and gs.level_of("ticket") == 200, "save v4 nhân cấp ×10")
	gs.init_new_game()
	gs._apply({"schema_version": 5, "coins": "5", "levels": {"engine": 7}})
	_check(gs.level_of("engine") == 7, "save v5 giữ nguyên cấp")
	gs.reset_progress()
	var scene: PackedScene = load("res://scenes/main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	await process_frame
	var found: Dictionary = {}
	for row in ui._rows:
		found[row["kind"]] = true
	_check(found.size() == 8 and not found.has("driver") and not found.has("venue"), "UI có đủ tám loại nâng cấp")
	ui._select_tab(2)  # Tab.TEAM
	ui._select_team_sub(1)  # Garage
	_check(ui._garage.visible, "mở Garage")
	gs.coins = BigNumber.zero()
	ui._garage._view_car("car_pico_bam_duong")
	var buy_button := _find_button(ui._garage, "Thiếu")
	_check(buy_button != null and buy_button.disabled, "nút mua xe bị khóa khi thiếu tiền")
	gs.coins = BigNumber.from_int(2500)
	ui._garage.refresh()
	buy_button = _find_button(ui._garage, "Mua ·")
	_check(buy_button != null and not buy_button.disabled, "đủ tiền thì nút mua xe sáng ngay, không đợi chặng kế")
	ui.queue_free()
	await process_frame
	gs.reset_progress()
	print("upgrade_test: %d lỗi" % _fails)
	quit(1 if _fails > 0 else 0)


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _find_button(child, prefix)
		if found != null:
			return found
	return null
