extends SceneTree
## Phần B của hướng dẫn: mở khóa tính năng dần theo số lượt (Design/23 §5).
## Kiểm tra dữ liệu, chặn ở tầng game, quà mở khóa đúng một lần, save/migration và UI khóa + hướng dẫn ngắn.
## Dùng save riêng, không đụng save người chơi.
const BigNumber = preload("res://core/math/big_number.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("  ok   " if ok else "  FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in range(4):
		await process_frame


## Chạy một lượt đua tới khi chốt kết quả; trả về kết quả của lượt đó.
func race(state: Node) -> Dictionary:
	var target: int = state.completed_races + 1
	var guard := 0
	while state.completed_races < target and guard < 20000:
		state.advance(0.5)
		guard += 1
	return state.last_result


func fresh(state: Node, gated: bool) -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = gated
	state.begin_countdown()


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_unlock_test.json"
	state.BAK_PATH = "user://tutorial_unlock_test.bak"
	state.TMP_PATH = "user://tutorial_unlock_test.tmp"
	GameData.reload()
	Tutorial.reload()

	print("== Dữ liệu ==")
	var errs := Tutorial.validate()
	check(errs.is_empty(), "tutorial.json hợp lệ %s" % str(errs))
	var order: Array = []
	for f: Dictionary in Tutorial.features():
		order.append(int(f["races"]))
	check(order == [2, 3, 4, 5, 7, 10], "lịch mở: lượt 2/3/4/5/7/10 (%s)" % str(order))
	check(Tutorial.next_feature(0)["id"] == "U2_league" and Tutorial.next_feature(10).is_empty(), "tính năng sắp mở")

	print("== Không gated (save cũ/test): mở hết ==")
	fresh(state, false)
	state.coins = BigNumber.from_int(1000000)
	check(state.feature_unlocked("U7_class") and state.upgrade_state("tyre") != "locked", "không gated: mọi thứ mở")

	print("== Gated: chặn ở tầng game ==")
	fresh(state, true)
	state.coins = BigNumber.from_int(1000000)
	state.gems = 1000
	check(state.upgrade_state("tyre") != "locked" and state.upgrade_state("grandstands") != "locked", "lượt 0: mọi ô nâng cấp đều mua được")
	check(state.open_gear_pack("standard", 1).is_empty() and state.gems == 1000, "Túi khóa: không mở gói, không trừ gem")
	check(state.open_driver_pack("pro", 1).is_empty() and state.gems == 1000, "Tay đua khóa: không mở gói")
	check(not state.claim_daily() and not state.buy_car(GameData.cars()[1]["id"]), "Shop/Garage khóa")
	check(not state.set_player_team_name("Đội thử") and not state.select_class("racing"), "Hồ sơ/Class khóa")
	check(state.buy("engine") and state.buy("tyre") and state.buy("parking"), "mua nâng cấp ngay từ đầu")

	print("== Mở khóa theo lượt, quà đúng một lần ==")
	var seen: Array = []
	for n in range(1, 11):
		var res := race(state)
		var u: Array = res.get("unlocked", [])
		check(u.size() <= 1, "lượt %d: tối đa một mở khóa" % n)
		for e: Dictionary in u:
			seen.append(e["id"])
		if n == 1:
			check(u.is_empty(), "lượt 1: chưa mở gì")
		if n == 2:
			check(state.feature_unlocked("U2_league") and state.set_player_team_name("Đội thử"), "lượt 2: Giải/Hồ sơ mở")
		if n == 3:
			check(state.feature_unlocked("U4_shop"), "lượt 3: Shop mở")
		if n == 4:
			check(int(state.gear_coupons["standard"]) == 1 and u[0]["gift"] != "", "lượt 4: tặng 1 coupon Standard Gear")
			var out: Dictionary = state.open_gear_pack("standard", 1)
			check(not out.is_empty() and int(state.gear_coupons["standard"]) == 0, "mở gói bằng coupon vừa tặng")
		if n == 5:
			check(int(state.driver_coupons["pro"]) == 1, "lượt 5: tặng 1 coupon Pro Pack")
		if n == 6:
			check(not state.feature_unlocked("U6_garage"), "lượt 6: Garage còn khóa")
		if n == 7:
			check(state.feature_unlocked("U6_garage"), "lượt 7: Garage mở")
		if n == 9:
			check(not state.feature_unlocked("U7_class"), "lượt 9: Class còn khóa")
	check(seen == ["U2_league", "U4_shop", "U3_bag", "U5_drivers", "U6_garage", "U7_class"], "đủ sáu lần mở khóa theo thứ tự")
	check(state.feature_unlocked("U7_class") and state.processed_rewards.has("unlock/U3_bag"), "lượt 10: Class mở, đã ghi reward id")
	check(Tutorial.next_feature(state.completed_races).is_empty(), "hết tính năng sắp mở")

	print("== Lưu, tải lại, thử lưu lại không phát quà hai lần ==")
	state.active = true
	check(state.save_game(), "lưu")
	var coupons_pro: int = state.driver_coupons["pro"]
	state.init_new_game()
	check(state.load_game() == "ok" and state.gating_on() and state.completed_races == 10, "tải lại: vẫn gated, đủ 10 lượt")
	check(int(state.driver_coupons["pro"]) == coupons_pro and state.feature_unlocked("U7_class"), "tải lại: quà không phát lại")
	fresh(state, true)
	state.active = true
	for i in 3:
		race(state)
	state.simulate_write_failure = true
	var guard := 0
	while state.phase != "save_error" and guard < 20000:
		state.advance(0.5)
		guard += 1
	check(state.phase == "save_error", "lượt 4 chốt nhưng lưu lỗi")
	check(int(state.gear_coupons["standard"]) == 0, "lưu lỗi: quà chưa phát")
	for i in 20:
		state.advance(0.5)
	state.simulate_write_failure = false
	check(state.retry_save() and int(state.gear_coupons["standard"]) == 1, "thử lại thành công: đúng 1 coupon")
	state.retry_save()
	check(int(state.gear_coupons["standard"]) == 1 and state.completed_races == 4, "không phát lần hai")

	print("== Hướng dẫn đã xem, save cũ ==")
	state.mark_intro_seen("U3_bag")
	state.mark_intro_seen("U3_bag")
	state.mark_intro_seen("khong_co")
	check((state.tutorial["intro_seen"] as Array).count("U3_bag") == 1, "đánh dấu đã xem, không trùng")
	var legacy: Dictionary = state._save_data()
	legacy["tutorial"] = {"state": "done", "step": ""}
	legacy["completed_races"] = 1
	check(state.save_game(legacy), "ghi save không có trường gated")
	state.init_new_game()
	check(state.load_game() == "ok" and not state.gating_on() and state.feature_unlocked("U7_class"), "save cũ: không khóa gì")
	var bad: Dictionary = state._save_data()
	bad["tutorial"] = {"state": "done", "step": "", "gated": "yes"}
	check(not state.save_game(bad), "gated sai kiểu bị từ chối")

	print("== UI ==")
	fresh(state, true)
	state.active = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main_script = load("res://ui/main.gd")
	if not main_script.can_instantiate():
		check(false, "main UI biên dịch được")
		_end()
		return
	var main = main_script.new()
	main._shot_prefix = "unlock-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	var tut = main._tutorial
	tut.set_process(false)
	main._active = true
	main._refresh_light()
	main._refresh_rows()
	var bag_item: Control = main._nav_items[main.Tab.BAG]
	check((bag_item.get_node("NavLock") as Control).visible and (main._nav_items[main.Tab.SHOP].get_node("NavLock") as Control).visible, "tab Túi/Shop có ổ khóa")
	check(not (main._nav_items[main.Tab.RACE].get_node("NavLock") as Control).visible, "tab Đua không khóa")
	check(main._toast.text.begins_with("Sắp mở: Tab Giải"), "popup 'Sắp mở': %s" % main._toast.text)
	main._select_tab(main.Tab.BAG)
	var lock_texts := ""
	for ch in main._overlay_box.get_children():
		if ch is Label:
			lock_texts += (ch as Label).text + "|"
	check(main._tab == main.Tab.RACE and main._overlay.visible and lock_texts.contains("Mở sau lượt 4"), "bấm tab khóa: ở lại tab Đua, popup nói rõ điều kiện: %s" % lock_texts)
	main._close_overlay()
	main._overlay.hide()
	var engine: Dictionary = main._row_of("engine")
	check((engine["tile"] as Control).modulate == Color.WHITE and not (engine["eff"] as Label).text.begins_with("Mở sau"), "ô nâng cấp không bị khóa")
	main._show_profile()
	check(not main._profile.visible, "hồ sơ khóa")
	main._show_classes()
	check(not main._class_page.visible, "trang Class khóa")

	state.completed_races = 4
	main._lock_sig = ""
	main._refresh_light()
	check(not (bag_item.get_node("NavLock") as Control).visible and (bag_item.get_node("NavDot") as Control).visible, "lượt 4: Túi mở, có chấm 'mới'")
	check(not (main._nav_items[main.Tab.SHOP].get_node("NavLock") as Control).visible, "Shop đã mở từ lượt 3")

	print("== Hướng dẫn ngắn ==")
	main._select_tab(main.Tab.RACE)
	main._pump_intro()
	main._pump_intro()
	check(tut.intro == "", "đứng ở tab Đua: không còn hướng dẫn nào chờ (U2/U3 cần đúng tab)")
	main._select_tab(main.Tab.LEAGUE)
	main._pump_intro()
	check(tut.intro == "U2_league", "sang tab Giải: hướng dẫn U2")
	tut._on_primary()
	state.mark_intro_seen("U4_shop")
	main._select_tab(main.Tab.SHOP)
	main._pump_intro()
	tut.blocked = false
	tut._process(0.1)
	check(tut.intro == "U3_bag" and tut._hand.visible and tut._target.has("rect"), "tab Shop: U3 có bàn tay chỉ nút mở gói")
	check(tut.wants_pause(), "U3 câu đầu đang chờ thao tác: dừng game")
	main._select_tab(main.Tab.RACE)
	check(main._tutorial.intro == "U3_bag", "rời tab: hướng dẫn chờ, chưa bị hủy")
	tut.blocked = true  # main không chạy _process trong test
	tut._process(0.1)
	check(not tut.wants_pause(), "rời tab: callout ẩn, game chạy lại")
	main._select_tab(main.Tab.SHOP)
	tut.blocked = false
	state.gear_open_count = 1
	tut._process(0.1)
	check(not tut.wants_pause(), "câu phụ sau thao tác không dừng game")
	check(tut.intro_sub == 1 and tut._text.text.contains("Power"), "mở gói xong: câu thứ hai nói Power đội tăng")
	tut._process(3.1)
	check(tut.intro == "" and Tutorial.intro_seen(state, "U3_bag"), "tự đóng sau 3 giây")
	main._select_tab(main.Tab.RACE)
	state.tutorial["state"] = "active"
	tut.running = true
	main._pump_intro()
	check(tut.intro == "", "đang chạy Phần A: không chen hướng dẫn ngắn")
	tut.running = false

	print("== Bảng kết quả có dòng mở khóa ==")
	var res: Dictionary = {"position": 2, "points": 8, "money": BigNumber.from_int(100), "trophies": 0,
		"unlocked": [{"id": "U3_bag", "name": "Túi phụ kiện", "gift": "Standard Gear ×1"}]}
	main._show_race_result(res)
	var texts := PackedStringArray()
	for l in main._result_box.find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	check("Mở khóa" in texts and "Túi phụ kiện" in texts and "Standard Gear ×1" in texts, "kết quả: Mở khóa + tên + quà")
	for width in [320, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		var card: Control = main._result_box.get_parent()
		check(card.get_global_rect().end.x <= root.size.x + 0.5 and card.get_global_rect().position.x >= -0.5, "bảng kết quả vừa màn %d" % width)
	main.queue_free()
	await settle()
	_end()


func _end() -> void:
	var state := root.get_node("GameState")
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_unlock_test: %d failures" % failures)
	quit(1 if failures else 0)
