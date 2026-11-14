extends SceneTree
## Phần C của hướng dẫn: mẹo theo tình huống (Design/23 §6). Điều kiện từng mẹo, mỗi lượt một mẹo, tắt/bật,
## lưu và tải lại, hiển thị qua callout của Linh, ưu tiên sau hướng dẫn mở khóa. Dùng save riêng.
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


func fresh(state: Node) -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["state"] = "done"  # đã qua Phần A


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_tips_test.json"
	state.BAK_PATH = "user://tutorial_tips_test.bak"
	state.TMP_PATH = "user://tutorial_tips_test.tmp"
	GameData.reload()
	Tutorial.reload()

	print("== Dữ liệu ==")
	check(Tutorial.validate_tips().is_empty() and Tutorial.tips().size() == 5, "5 mẹo hợp lệ: %s" % str(Tutorial.validate_tips()))

	print("== Điều kiện từng mẹo ==")
	fresh(state)
	check(Tutorial.tips_allowed(state) and Tutorial.next_tip(state, "race").is_empty(), "mới vào: chưa có mẹo nào")
	state.levels["ticket"] = 23
	var tip := Tutorial.next_tip(state, "race")
	check(tip.get("id", "") == "C4_star" and tip["target"] == "tile:ticket" and String(tip["text"]).contains("cấp 25"), "C4: Ticket còn 2 cấp tới cấp 25 (%s)" % str(tip.get("text", "")))
	check(Tutorial.next_tip(state, "bag").is_empty(), "C4 chỉ hiện ở tab Đua")
	state.levels["ticket"] = 21
	check(Tutorial.next_tip(state, "race").is_empty(), "C4: còn 4 cấp thì chưa nhắc")
	state.levels["ticket"] = 0
	state.levels["parking"] = 24
	check(Tutorial.next_tip(state, "race").get("target", "") == "tile:parking", "C4: chọn mục gần mốc nhất")
	state.levels["parking"] = 0

	state.tutorial["offline_shown"] = true
	tip = Tutorial.next_tip(state, "")
	check(tip.get("id", "") == "C1_offline" and String(tip["text"]).contains("50%") and String(tip["text"]).contains("2 giờ"), "C1: nhắc thu nhập vắng mặt, số lấy từ dữ liệu")
	check(Tutorial.next_tip(state, "bag").get("id", "") == "C1_offline", "C1 hiện được ở mọi tab")
	state.tutorial["offline_shown"] = false

	state.trophies = 500
	tip = Tutorial.next_tip(state, "")
	check(tip.get("id", "") == "C2_trophy" and String(tip["text"]).contains("500"), "C2: đủ cúp nâng cấp")
	state.trophies = 0

	var gid: String = GameData.gear_items()[0]["id"]
	state.gear_owned[gid] = {"level": 0, "shards": 0}
	var need: int = state.gear_upgrade_cost(gid)
	check(need > 0 and Tutorial.next_tip(state, "bag").is_empty(), "C5: chưa đủ mảnh thì không nhắc")
	state.gear_owned[gid]["shards"] = need
	tip = Tutorial.next_tip(state, "bag")
	check(tip.get("id", "") == "C5_shards" and tip["target"] == "node:Upgrade_%s" % gid, "C5: đủ mảnh, trỏ tới nút nâng")
	state.gear_owned.erase(gid)

	var best := ""
	var best_score: float = Tutorial._driver_score(state, "driver_an")
	for d: Dictionary in GameData.drivers():
		if Tutorial._driver_score(state, d["id"]) > best_score + 0.5:
			best = d["id"]
			best_score = Tutorial._driver_score(state, best)
	check(best != "" and Tutorial.next_tip(state, "team").is_empty(), "C6: chỉ có 1 tay đua thì không nhắc")
	state.owned_drivers = ["driver_an", best]
	tip = Tutorial.next_tip(state, "team")
	check(tip.get("id", "") == "C6_weaker", "C6: có tay đua mạnh hơn đang không dùng")
	state.active_driver_id = best
	check(Tutorial.next_tip(state, "team").is_empty(), "C6: đã dùng tay đua mạnh nhất thì hết nhắc")
	state.active_driver_id = "driver_an"
	state.owned_drivers = ["driver_an"]

	print("== Tần suất, bật/tắt, bối cảnh ==")
	state.levels["ticket"] = 23
	state.completed_races = 4
	state.mark_tip_seen("C4_star")
	check(Tutorial.tip_seen(state, "C4_star") and not Tutorial.tips_allowed(state), "vừa hiện một mẹo: lượt này không thêm mẹo")
	state.completed_races = 5
	check(Tutorial.tips_allowed(state) and Tutorial.next_tip(state, "race").is_empty(), "sang lượt mới được phép lại, nhưng C4 đã xem")
	state.set_tips_enabled(false)
	state.tutorial["offline_shown"] = true
	check(not Tutorial.tips_allowed(state) and Tutorial.next_tip(state, "").is_empty(), "tắt mẹo: không hiện nữa")
	state.set_tips_enabled(true)
	state.tutorial["state"] = "active"
	check(Tutorial.next_tip(state, "") .is_empty(), "đang chạy Phần A: không có mẹo")
	state.tutorial["state"] = "new"
	check(not Tutorial.tips_allowed(state), "chưa bắt đầu hướng dẫn: không có mẹo")
	state.tutorial["state"] = "skipped"
	check(Tutorial.tips_allowed(state), "bỏ qua hướng dẫn vẫn nhận mẹo")

	print("== Lưu và tải lại ==")
	fresh(state)
	state.active = true
	state.completed_races = 3
	state.note_offline_shown()
	state.mark_tip_seen("C1_offline")
	state.set_tips_enabled(false)
	check(state.save_game(), "lưu")
	state.init_new_game()
	check(state.load_game() == "ok" and Tutorial.tip_seen(state, "C1_offline") and not state.tips_enabled(), "tải lại: mẹo đã xem + công tắc tắt")
	check(int(state.tutorial["tips_last"]) == 3 and bool(state.tutorial["offline_shown"]), "tải lại: mốc lượt và cờ offline")
	var raw: Dictionary = state._save_data()
	raw["tutorial"]["tips_seen"] = ["C1_offline", "khong_co", "C1_offline"]
	check(state.save_game(raw), "ghi save có id mẹo lạ")
	state.init_new_game()
	state.load_game()
	check((state.tutorial["tips_seen"] as Array) == ["C1_offline"], "id lạ và trùng bị làm sạch")
	var bad: Dictionary = state._save_data()
	bad["tutorial"]["tips_off"] = "no"
	check(not state.save_game(bad), "tips_off sai kiểu bị từ chối")
	bad = state._save_data()
	bad["tutorial"]["tips_last"] = 1.5
	check(not state.save_game(bad), "tips_last không nguyên bị từ chối")
	state.init_new_game()
	state.completed_races = 2
	var legacy: Dictionary = state._save_data()
	legacy["tutorial"] = {"state": "done", "step": ""}
	check(state.save_game(legacy), "ghi save không có trường mẹo")
	state.init_new_game()
	check(state.load_game() == "ok" and state.tips_enabled() and int(state.tutorial["tips_last"]) == -1, "save cũ: mẹo bật, chưa có mốc")

	print("== UI ==")
	fresh(state)
	state.active = false
	state.begin_countdown()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main_script = load("res://ui/main.gd")
	if not main_script.can_instantiate():
		check(false, "main UI biên dịch được")
		_end()
		return
	var main = main_script.new()
	main._shot_prefix = "tips-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	main._active = true
	var tut = main._tutorial
	tut.set_process(false)
	state.tutorial["state"] = "done"
	state.levels["ticket"] = 23
	main._select_tab(main.Tab.RACE)
	main._pump_intro()
	check(tut.intro == "C4_star" and tut.tip_mode, "tab Đua: hiện mẹo C4")
	tut.blocked = false
	tut._process(0.1)
	check(tut._panel.visible and tut._text.text.contains("Ticket Marketing") and tut._target.has("rect"), "callout + spotlight ô Ticket")
	check(not tut._skip.visible and tut._primary.text == "Đã hiểu", "chỉ có nút Đã hiểu, không có nút Tắt mẹo")
	check(tut._panel.get_rect().end.x <= tut.size.x and tut._panel.position.x >= 0.0, "callout vừa màn 390")
	state.levels["ticket"] = 30
	tut._process(0.1)
	check(tut.intro == "" and Tutorial.tip_seen(state, "C4_star"), "tình huống hết đúng (đã nâng qua mốc): mẹo tự đóng")
	state.levels["ticket"] = 23
	state.completed_races = 1
	state.tutorial["tips_seen"] = []
	state.tutorial["tips_last"] = -1
	main._pump_intro()
	check(tut.intro == "C4_star", "hiện lại để thử Đã hiểu")
	tut._on_primary()
	check(tut.intro == "" and int(state.tutorial["tips_last"]) == 1, "Đã hiểu: đóng, ghi mốc lượt")
	state.tutorial["offline_shown"] = true
	main._pump_intro()
	check(tut.intro == "", "cùng lượt: không hiện mẹo thứ hai")
	state.completed_races = 2
	main._select_tab(main.Tab.RACE)
	main._pump_intro()
	check(tut.intro == "C1_offline", "lượt mới: mẹo C1 (offline) hiện ở bất kỳ tab nào")
	tut._on_primary()
	state.set_tips_enabled(false)
	check(tut.intro == "" and not state.tips_enabled(), "Đã hiểu, rồi tắt mẹo trong Cài đặt")
	state.set_tips_enabled(true)

	print("== Ưu tiên và cài đặt ==")
	state.tutorial["tips_seen"] = []
	state.tutorial["tips_last"] = -1
	state.tutorial["offline_shown"] = false  # để C4 là mẹo duy nhất đủ điều kiện
	state.tutorial["gated"] = true
	state.completed_races = 10
	main._lock_sig = ""
	main._refresh_light()
	main._pump_intro()
	check(tut.intro == "U7_class" and not tut.tip_mode, "hướng dẫn mở khóa được ưu tiên trước mẹo")
	tut._on_primary()
	main._pump_intro()
	check(tut.intro == "C4_star" and tut.tip_mode, "xong hướng dẫn mở khóa mới tới mẹo")
	tut._on_primary()
	state.tutorial["gated"] = false
	state.tutorial["tips_seen"] = []
	main._show_settings()
	check(main._overlay_box.find_child("TipsToggle", true, false) == null, "Cài đặt không còn công tắc mẹo")
	var lang_btn := main._overlay_box.find_child("LanguageButton", true, false) as Button
	check(lang_btn != null, "Cài đặt có nút ngôn ngữ")
	lang_btn.pressed.emit()
	check(main._overlay_box.find_child("Lang_en", true, false) != null and main._overlay_box.find_child("Lang_vi", true, false) != null, "popup liệt kê các ngôn ngữ")
	main._overlay.hide()
	main.queue_free()
	await settle()
	_end()


func _end() -> void:
	var state := root.get_node("GameState")
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_tips_test: %d failures" % failures)
	quit(1 if failures else 0)
