extends SceneTree
## Hướng dẫn đầu game Phần A (Design/23 §4): luồng A1–A7, tự qua khi đã làm, bỏ qua, chặn khi khác tab,
## giữ bảng kết quả ở A6, lưu/tiếp tục và migration save cũ. Dùng save riêng, không đụng save người chơi.
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


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_test.json"
	state.BAK_PATH = "user://tutorial_test.bak"
	state.TMP_PATH = "user://tutorial_test.tmp"
	GameData.reload()

	print("== Logic bước ==")
	check(Tutorial.next_of("A1_welcome") == "A2_car" and Tutorial.next_of("A7_race2") == "", "thứ tự bước A1 → A7")
	state.init_new_game()
	state.active = false
	check(state.tutorial_state() == "new" and Tutorial.should_run(state), "save mới: cần chạy hướng dẫn")
	state.completed_races = 2
	check(not Tutorial.should_run(state), "save 'new' nhưng đã đua: không chạy")
	state.completed_races = 0

	print("== Lưu, tiếp tục, migration ==")
	state.active = true
	check(state.set_tutorial("active", "A5_ticket") and state.save_game(), "lưu bước đang dở")
	state.init_new_game()
	check(state.load_game() == "ok" and state.tutorial_step() == "A5_ticket" and Tutorial.resume_step(state) == "A5_ticket", "tải lại: tiếp tục đúng bước")
	var legacy: Dictionary = state._save_data()
	legacy.erase("tutorial")
	legacy["completed_races"] = 3
	check(state.save_game(legacy), "ghi save cũ không có trường tutorial")
	state.init_new_game()
	check(state.load_game() == "ok" and state.tutorial_state() == "done", "save cũ đã đua: coi như xong hướng dẫn")
	legacy["completed_races"] = 0
	state.save_game(legacy)
	state.init_new_game()
	check(state.load_game() == "ok" and state.tutorial_state() == "new", "save cũ chưa đua: vẫn hướng dẫn")
	var bad: Dictionary = state._save_data()
	bad["tutorial"] = {"state": "xyz", "step": ""}
	check(not state.save_game(bad), "trạng thái tutorial lạ bị từ chối khi ghi")

	print("== Luồng A1–A7 trên UI ==")
	state.init_new_game()
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
	main._shot_prefix = "tutorial-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	var tut = main._tutorial  # không khai báo kiểu: tránh biên dịch overlay trước khi có autoload GameState
	tut.set_process(false)
	check(not tut.running, "chế độ chụp ảnh không tự bật hướng dẫn")
	tut.blocked = false
	check(tut.start() and tut.step == "A1_welcome" and state.tutorial_state() == "active", "bắt đầu ở A1")
	tut._process(0.1)
	check(tut._panel.visible and tut._text.text.begins_with("Chào Sếp") and tut._primary.text == "Bắt đầu", "A1: callout chào + nút Bắt đầu")
	check(tut._panel.get_rect().end.x <= tut.size.x and tut._panel.position.x >= 0.0, "callout nằm trong màn 390")
	tut._on_primary()
	check(tut.step == "A2_car", "Bắt đầu → A2")
	tut.blocked = true
	tut._process(10.0)
	check(tut.step == "A2_car" and not tut._panel.visible, "khác tab: ẩn và không tự qua")
	tut.blocked = false
	main._sync_sim()  # main không chạy _process trong test: tự gắn grid xem trước cho khung đua
	tut._process(0.1)
	check(tut._target.get("round", false), "A2: spotlight tròn quanh xe")
	tut._process(4.0)
	check(tut.step == "A3_income", "A2 tự qua sau 4 giây")
	tut._process(0.1)
	check(tut._target.has("rect") and (tut._target["rect"] as Rect2).is_equal_approx(main._coin_bar.get_global_rect()), "A3: spotlight thanh tiền")
	tut._process(3.0)
	check(tut.step == "A4_engine", "A3 tự qua sau 3 giây")
	tut._process(0.1)
	check(tut._hand.visible and not tut._primary.visible, "A4: bàn tay chỉ nút mua, không có nút Tiếp")
	tut._on_primary()
	check(tut.step == "A4_engine", "A4 chỉ qua bằng thao tác mua thật")
	check(state.buy("engine"), "mua Động cơ")
	tut._process(0.1)
	check(tut.sub == 1 and tut._text.text.contains("lượt sau") and not tut._hand.visible, "A4: báo áp dụng từ lượt sau")
	tut._process(3.0)
	check(tut.step == "A5_ticket", "A4 → A5")
	check(state.buy("ticket"), "mua Ticket Marketing")
	tut._process(0.1)
	check(tut.sub == 1 and tut._text.text.contains("ngay"), "A5: doanh thu có hiệu lực ngay")
	tut._process(3.0)
	check(tut.step == "A6_result", "A5 → A6")
	tut._process(0.1)
	check(not tut._panel.visible, "A6 chờ kết quả lượt, không hiện callout")

	state._start_race()
	var guard := 0
	while state.phase == "racing" and guard < 5000:
		state.advance(0.1)
		guard += 1
	check(not state.last_result.is_empty(), "lượt 1 kết thúc")
	main._active = true
	main._shot_prefix = ""  # để main._process không chụp ảnh trong test headless
	main._show_race_result(state.last_result)
	check(tut.holds_result(), "A6 giữ bảng kết quả")
	main._process(5.0)
	check(main._result_panel.visible, "bảng kết quả không tự tắt khi Linh đang giải thích")
	tut._process(0.1)
	check(tut._panel.visible and tut._text.text.contains("P%d" % int(state.last_result["position"])), "A6 câu 1 dùng hạng thật")
	tut._on_primary()
	tut._process(0.1)
	check(tut._text.text.contains("cúp"), "A6 câu 2: nhắc nhận cúp ở top 3")
	tut._on_primary()
	check(not main._result_panel.visible and not tut.holds_result() and tut.step == "A7_race2", "đọc xong: ẩn bảng, sang A7")
	tut._process(0.1)
	check(not tut._panel.visible, "A7 chờ lượt 2 xuất phát")
	state.result_hold = false
	guard = 0
	while state.phase != "racing" and guard < 100:
		state.advance(0.1)
		guard += 1
	tut._process(0.1)
	check(tut._panel.visible and tut._text.text.contains("→"), "A7: Power trước → sau")
	tut._process(3.0)
	check(tut.sub == 1 and tut._primary.text == "Rõ rồi!", "A7 câu kết")
	tut._on_primary()
	check(not tut.running and state.tutorial_state() == "done" and not tut._panel.visible, "hoàn tất Phần A")
	check(not tut.start(), "đã xong thì không chạy lại")

	print("== Bỏ qua và tự qua khi đã làm trước ==")
	state.tutorial = {"state": "new", "step": "", "power_before": 0.0}
	state.completed_races = 0
	check(tut.start(), "bắt đầu lại để thử bỏ qua")
	tut._on_skip()
	tut._process(0.1)
	check(tut._confirm and tut._primary.text == "Tiếp tục", "Bỏ qua: hỏi xác nhận")
	tut._on_primary()
	check(not tut._confirm and tut.running, "Tiếp tục hướng dẫn: quay lại bước cũ")
	tut._on_skip()
	tut._on_skip()
	check(not tut.running and state.tutorial_state() == "skipped", "xác nhận bỏ qua")
	state.tutorial = {"state": "active", "step": "A4_engine", "power_before": 0.0}
	check(tut.start() and tut._resumed, "tiếp tục bước dở")
	tut._process(0.1)
	check(tut.sub == 1 and tut._text.text.begins_with("Mình tiếp tục"), "đã nâng Động cơ từ trước: A4 tự qua, có câu tiếp tục")
	for width in [320, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		tut._process(0.01)
		check(tut._panel.position.x >= 0.0 and tut._panel.get_rect().end.x <= tut.size.x + 0.5 and tut._panel.get_rect().end.y <= tut.size.y + 0.5, "callout vừa màn %d" % width)
	tut.skip_all()
	main.queue_free()
	await settle()
	_end()


func _end() -> void:
	var state := root.get_node("GameState")
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_test: %d failures" % failures)
	quit(1 if failures else 0)
