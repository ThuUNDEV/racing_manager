extends SceneTree
## Hướng dẫn đầu game Phần A (Design/23 §4, Design/31): luồng 6 bước (A5 Ticket đã bỏ), tự qua khi đã làm, bỏ qua, chặn khi khác tab,
## chặn chạm ngoài vùng sáng, A4 chờ đủ tiền,
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
	check(Tutorial.next_of("A1_welcome") == "A2_car" and Tutorial.next_of("A2_car") == "A4_engine" and Tutorial.next_of("A4_engine") == "A3_income" and Tutorial.next_of("A3_income") == "A6_result" and Tutorial.next_of("A7_race2") == "", "thứ tự Xe → Power/Động cơ → Doanh thu → Kết quả → Lượt sau")
	check(not Tutorial.is_step("A5_ticket"), "A5 Ticket đã bỏ khỏi danh sách bước")
	state.init_new_game()
	state.active = false
	check(state.tutorial_state() == "new" and Tutorial.should_run(state), "save mới: cần chạy hướng dẫn")
	state.completed_races = 2
	check(not Tutorial.should_run(state), "save 'new' nhưng đã đua: không chạy")
	state.completed_races = 0

	print("== Lưu, tiếp tục, migration ==")
	state.active = true
	check(state.set_tutorial("active", "A4_engine") and state.save_game(), "lưu bước đang dở")
	state.init_new_game()
	check(state.load_game() == "ok" and state.tutorial_step() == "A4_engine" and Tutorial.resume_step(state) == "A4_engine", "tải lại: tiếp tục đúng bước")
	check(state.set_tutorial("active", "A5_ticket") and state.save_game(), "lưu bước cũ A5_ticket (save trước khi bỏ Ticket)")
	state.init_new_game()
	check(state.load_game() == "ok" and Tutorial.resume_step(state) == "A6_result", "save dừng ở A5 cũ: tiếp tục ở A6")
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
	check(tut._panel.visible and tut._text.text.contains("Tôi là Linh") and tut._primary.text == "Tiếp", "A1: Linh giới thiệu trước khi bắt đầu")
	check(tut._has_more_pages() and tut._text.text.contains("Gara"), "A1: mở đầu có bối cảnh của đội, chia nhịp thoại")
	check((tut._blockers[0] as Control).visible and (tut._blockers[0] as Control).mouse_filter == Control.MOUSE_FILTER_STOP, "A1: chặn chạm cả màn")
	tut._timer = 0.0
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	tut._on_block_input(tap)
	check(tut.step == "A1_welcome", "chạm ngay lúc vừa hiện: chưa qua (tránh lỡ tay)")
	tut._timer = 1.0
	tut._on_block_input(tap)
	check(tut.step == "A1_welcome" and tut._page == 1 and tut._primary.text == I18n.t("tutorial.start"), "A1: đọc lời giới thiệu rồi mới tới Bắt đầu")
	tut._on_primary()
	check(tut.step == "A2_car", "Bắt đầu chuyển sang A2")
	tut._enter("A1_welcome")
	tut._process(0.1)
	check(tut._panel.get_rect().end.x <= tut.size.x and tut._panel.position.x >= 0.0, "callout nằm trong màn 390")
	tut._on_primary()
	tut._on_primary()
	check(tut.step == "A2_car", "đọc hai nhịp A1 rồi sang A2")
	tut.blocked = true
	tut._process(10.0)
	check(tut.step == "A2_car" and not tut._panel.visible, "khác tab: ẩn và không tự qua")
	tut.blocked = false
	main._sync_sim()  # main không chạy _process trong test: tự gắn grid xem trước cho khung đua
	tut._process(0.1)
	check(tut._target.get("round", false), "A2: spotlight tròn quanh xe")
	check(tut.wants_pause(), "A2: dừng game chờ người chơi")
	var camera: Camera3D = main._race_view._world_3d.camera
	var normal_size := camera.size
	var normal_position := camera.position
	main._sync_tutorial_map_focus(0.1)
	check(camera.size < normal_size and camera.size > normal_size / main.TutorialMapFocus.ZOOM, "A2: map zoom vào từ từ")
	main._sync_tutorial_map_focus(0.35)
	check(is_equal_approx(camera.size, normal_size / main.TutorialMapFocus.ZOOM), "A2: map lớn hơn 1,45 lần để nhìn rõ xe")
	main._sync_tutorial_map_focus(1.0)
	check(is_equal_approx(camera.size, normal_size / main.TutorialMapFocus.ZOOM), "A2: không nhân zoom dồn qua từng frame")
	tut.blocked = true
	main._sync_tutorial_map_focus(0.35)
	check(is_equal_approx(camera.size, normal_size) and camera.position.is_equal_approx(normal_position), "Ẩn tutorial: trả camera về khung nhìn cũ")
	tut.blocked = false
	main._sync_tutorial_map_focus(0.35)
	tut._process(4.0)
	check(tut.step == "A2_car", "A2 đang dừng game: không tự qua, chờ bấm Tiếp")
	tut._on_primary()
	tut._on_primary()
	check(tut.step == "A4_engine" and tut.sub == 4, "Sau nhận diện xe: học Power trước Doanh thu")
	main._sync_tutorial_map_focus(0.35)
	check(is_equal_approx(camera.size, normal_size) and camera.position.is_equal_approx(normal_position), "Qua bước Power: khôi phục chính xác zoom và vị trí camera")
	tut._process(0.1)
	var power_target: Dictionary = main._tutorial_power_target()
	check(tut._text.text.contains("sức mạnh tổng hợp") and tut.wants_pause(), "Giải thích Power trước khi mua nâng cấp")
	check((tut._target["rect"] as Rect2).is_equal_approx(power_target["rect"]), "Giới thiệu đúng chip Power trên HUD")
	tut._on_primary()
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 0, "Đọc Power xong mới chỉ nâng Động cơ")
	check(not tut._hand.visible and tut._primary.visible and tut._block_mode() == "all", "A4: giải thích mục đích trước, chưa cho mua")
	tut._on_primary()
	check(tut._hand.visible and not tut._primary.visible, "A4: bàn tay chỉ nút mua, không có nút Tiếp")
	var hole: Rect2 = (tut._target["rect"] as Rect2).grow(6.0)
	var covered := 0
	for b: Control in tut._blockers:
		if b.visible:
			covered += 1
			check(not b.get_rect().intersects(hole.grow(-1.0)), "A4: tấm chặn không đè vùng mục tiêu")
	check(covered == 4, "A4: bốn tấm chặn quanh ô Động cơ")
	tut._on_primary()
	check(tut.step == "A4_engine", "A4 chỉ qua bằng thao tác mua thật")
	var saved_coins = state.coins
	state.coins = BigNumber.zero()
	tut._process(0.1)
	check(not tut._panel.visible and not tut.wants_pause(), "A4: chưa đủ tiền: không hiện callout, không dừng game")
	check(not (tut._blockers[0] as Control).visible, "A4: chưa đủ tiền: không chặn chạm")
	tut._money_wait = Tutorial.MONEY_WAIT_SEC - 0.5
	tut._process(1.0)
	check(tut.sub == 2 and tut._panel.visible and tut._text.text.contains("thiếu chút tiền") and not tut.wants_pause(), "A4: chờ quá lâu: nhắc một lần, không dừng game")
	tut._process(Tutorial.AFTER_SEC + 1.5)
	tut._process(0.01)
	check(tut.sub == 0 and not tut._panel.visible, "A4: hết nhắc, chờ im lặng")
	tut._process(Tutorial.MONEY_WAIT_SEC + 1.0)
	check(tut.sub == 0 and not tut._panel.visible, "A4: chỉ nhắc một lần")
	state.coins = saved_coins
	tut._process(0.1)
	check(tut._panel.visible and tut.sub == 0 and tut.wants_pause(), "A4: đủ tiền: hiện lời chỉ nút mua, dừng game")
	check(state.buy("engine"), "mua Động cơ")
	tut._process(0.1)
	check(tut.sub == 3 and tut.wants_pause() and tut._hand.visible, "Sau mua: thêm bước chờ người chơi quan sát Power tăng")
	check((tut._target["rect"] as Rect2).is_equal_approx(main._power_banner.get_global_rect()) and main._power_banner.visible, "Sau mua: spotlight thanh Power tăng thay vì chip Power nhỏ")
	var power_context: Dictionary = main._tutorial_context("A4_engine", {})
	check(power_context["before"] != power_context["after"] and tut._text.text.contains(power_context["before"] + " → " + power_context["after"]), "So sánh Power thật trước và sau nâng")
	tut._process(10.0)
	main._power_banner._process(10.0)
	check(tut.sub == 3, "Bước quan sát Power không tự biến mất")
	check(main._power_banner.visible and is_equal_approx(main._power_banner.total_power, state.team_power()), "Thanh Power giữ nguyên để người chơi đọc, không tự ẩn sau hai giây")
	var bought_coins: Dictionary = state.coins.to_save()
	check(state.save_game() and state.load_game() == "ok", "Lưu và tải lại ngay sau nâng Power")
	tut._enter("A4_engine")
	tut._process(0.1)
	check(tut.sub == 3 and state.coins.to_save() == bought_coins and main._tutorial_context("A4_engine", {})["before"] == power_context["before"], "Tiếp tục đúng bước Power, giữ số trước nâng và không mua lần nữa")
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 1 and tut._text.text.contains("lượt sau") and not tut._hand.visible, "A4: sau quan sát Power mới báo áp dụng từ lượt sau")
	check(not main._power_banner.visible, "Bấm Tiếp: thả thanh Power, không phát lại thông báo cũ")
	check(not (tut._blockers[0] as Control).visible, "A4 câu phụ: không chặn chạm")
	tut._process(10.0)
	check(tut.step == "A4_engine", "câu sau nâng không tự mất khi đang đọc")
	tut._on_primary()
	check(tut.step == "A3_income", "A4 → A3 sau khi đã nâng Power và xem kết quả")
	tut._process(0.1)
	check(not tut._panel.visible and not tut.wants_pause(), "Sau Power: game chạy lại, A3 chưa hiện lời dẫn")
	tut._process(Tutorial.RUN_BEFORE_A3_SEC)
	tut._process(0.1)
	var pill := main.find_child("IncomePill", true, false) as Control
	check(tut._target.has("rect") and (tut._target["rect"] as Rect2).is_equal_approx(pill.get_global_rect()), "A3: spotlight ô thu nhập (tiền mỗi giây)")
	await settle()
	tut._process(0.01)
	check(tut._panel.position.y >= pill.get_global_rect().end.y - 1.0, "A3: callout nằm dưới ô thu nhập, không che")
	tut._process(3.0)
	check(tut.step == "A3_income" and tut.wants_pause(), "A3 đang dừng game: không tự qua")
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 1 and tut._text.text.contains("Ticket Marketing"), "A3: chỉ nhóm Doanh thu và giải thích yếu tố tăng thu nhập")
	tut._on_primary()
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 2 and tut._hand.visible and not tut._primary.visible and tut._block_mode() == "hole", "A3: yêu cầu mua Ticket Marketing thật")
	tut._on_primary()
	check(tut.sub == 2, "A3: không thể bấm Tiếp để bỏ qua thao tác")
	var income_before := Balance.fmt_rate(state.total_online_rate())
	check(state.buy("ticket"), "A3: mua một lần Ticket Marketing")
	tut._process(0.1)
	check(tut.sub == 3 and tut._text.text.contains(income_before + " → ") and not tut._hand.visible, "A3: hiện thu nhập trước/sau sau khi nâng thành công")
	check((tut._target["rect"] as Rect2).is_equal_approx(pill.get_global_rect()), "A3: spotlight quay về ô thu nhập")
	tut._on_primary()
	tut._on_primary()
	check(tut.step == "A6_result", "A3: trải nghiệm tăng thu nhập xong mới sang kết quả")
	tut._process(0.1)
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
	check(tut._panel.visible and tut.sub == 2 and tut._target.is_empty() and not tut._text.text.contains("→"), "A7 chỉ lời kết, không lặp hướng dẫn nâng Power hay chờ lượt sau")
	check(tut.sub == 2 and tut._primary.text == "Tiếp" and not tut.wants_pause(), "A7 câu kết")
	tut._on_primary()
	tut._on_primary()
	check(not tut.running and state.tutorial_state() == "done" and not tut._panel.visible, "hoàn tất Phần A")
	check(not tut.start(), "đã xong thì không chạy lại")
	state.tutorial = {"state": "active", "step": "A7_race2", "lessons": {"A7_race2": {"status": "active", "sub": 0, "page": 0}}}
	check(tut.start(), "Tiếp tục save cũ đang ở bước Power lượt hai")
	tut._process(0.1)
	check(tut.sub == 2 and tut._target.is_empty(), "Save cũ cũng bỏ qua hướng dẫn Power lặp")
	tut._on_primary()
	tut._on_primary()

	print("== Lời thoại theo thành tích thật ==")
	var winner := Tutorial.line("A6_result", 0, {"position": 1, "money": "123"})
	var podium := Tutorial.line("A6_result", 0, {"position": 2, "money": "456"})
	var outside := Tutorial.line("A6_result", 0, {"position": 4, "money": "789"})
	check(winner.begins_with("P1") and winner.contains("123") and winner != podium, "P1 có lời mừng riêng, giữ hạng và tiền thật")
	check(podium.begins_with("P2") and podium.contains("456") and outside.begins_with("P4") and outside.contains("789"), "P2–P3 và ngoài bục có lời riêng, giữ số liệu thật")
	var saved_earned: int = state.trophies_earned
	var saved_trophies: int = state.trophies
	state.trophies_earned = 0
	state.trophies = 0
	check(Tutorial.line("A7_race2", 2, main._tutorial_context("A7_race2", {})) == I18n.t("tutorial.from_now_you_run_things"), "Chưa có cúp: Linh vẫn chờ chiếc cúp đầu tiên")
	state.trophies_earned = 1
	check(Tutorial.line("A7_race2", 2, main._tutorial_context("A7_race2", {})) == I18n.t("tutorial.story.already_has_trophy"), "Đã từng nhận cúp: nhớ thành tích kể cả khi đã tiêu hết cúp")
	state.trophies_earned = saved_earned
	state.trophies = saved_trophies

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
	check(tut.sub == 1 and tut._text.text.begins_with("Sếp quay lại"), "đã nâng Động cơ từ trước: A4 tự qua, có câu tiếp tục")
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
