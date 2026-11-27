extends SceneTree
## Popup bán hàng tự hiện (Design/28 §5b): thứ tự hàng đợi, giới hạn, và việc giữ vòng đua trong main.
const PopupAnim = preload("res://ui/popup_anim.gd")
const DAY := 86400.0
const T0 := 20000.0 * DAY + 3600.0
var failures := 0
var state: Node
var iap: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func fresh() -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	iap.session_start = T0 - 10.0

func buy(sku: String) -> void:
	(state.iap["buys"] as Array).append({"sku": sku, "token": "t_" + sku, "order": "", "t": 0})

func pick(now: float) -> Array:
	var r: Dictionary = iap.next_sales_popup(now)
	return [r["sku"], r["why"]]

func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	iap = root.get_node("Iap")
	state.SAVE_PATH = "user://tests/sales_popup.json"
	state.BAK_PATH = "user://tests/sales_popup.bak"
	state.TMP_PATH = "user://tests/sales_popup.tmp"
	DirAccess.make_dir_recursive_absolute("user://tests")
	GameData.reload()
	state.set_process(false)
	check(GameData.validate().is_empty(), "data hợp lệ: %s" % [GameData.validate()])

	fresh()
	check(iap.sales_popup_queue(T0) == ["starter_1", "starter_2"], "chưa lên bậc: chỉ chuỗi starter vào hàng đợi, đúng thứ tự data")
	check(pick(T0) == ["starter_1", ""], "starter_1 hiện đầu tiên")
	iap.note_sales_popup("starter_1", T0)
	check(iap.sales_popup_queue(T0) == ["starter_2"], "mỗi gói chỉ tự hiện một lần")
	check(pick(T0 + 100.0) == ["", "gap"], "chưa đủ gap_sec")
	check(pick(T0 + 2000.0) == ["", "session"], "starter_2 chờ phiên sau")
	iap.session_start = T0 + 3000.0
	check(pick(T0 + 4000.0) == ["", "gap"], "starter_2 cách popup trước chưa đủ 24 giờ")
	check(pick(T0 + DAY + 10.0) == ["starter_2", ""], "starter_2 hiện ở phiên sau, sau 24 giờ")

	fresh()
	state.business_tier = 4
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	var now := T0
	for expected in ["offer_combo_1", "offer_combo_2"]:
		check(pick(now) == [expected, ""], "lần lượt hiện %s" % expected)
		iap.note_sales_popup(expected, now)
		now += 2000.0
	state.ad_state["break"] = {"day": int(Time.get_unix_time_from_system() / 86400.0), "today": 3}
	check(pick(now) == ["offer_noads_bundle", ""], "gói no_ads hiện khi đủ 3 Ads Break")
	iap.note_sales_popup("offer_noads_bundle", now)
	check(pick(now + 2000.0) == ["", "day_cap"], "tối đa 3 popup mỗi ngày")
	check(pick(now + DAY) == ["offer_noads_bundle", ""], "no_ads tự hiện lại ngày sau")
	iap.note_sales_popup("offer_noads_bundle", now + DAY)
	check(pick(now + DAY + 2000.0) == ["", "day_cap"], "no_ads tối đa 1 lần/ngày")
	iap.note_sales_popup("offer_noads_bundle", now + 2.0 * DAY)
	check(iap.sales_popup_queue(now + 3.0 * DAY).is_empty(), "no_ads tối đa 3 lần tổng")

	state.business_tier = 0  # bậc ép tay ở trên không đi kèm trạng thái cơ sở nên save từ chối
	check(state.save_game(), "lưu được")
	state._apply_iap(JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)))
	check(iap.sales_popup_queue(now + 3.0 * DAY).is_empty(), "trạng thái còn nguyên sau khi nạp save")

	# Giao diện: sau bảng kết quả, popup mở và giữ vòng đua tới khi đóng.
	fresh()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 778)
	var main: Control = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._select_tab(0)
	main._close_overlay()
	await settle()

	state.result_hold = true
	main._sales_position = 6
	check(not main._hold_for_sales_popup() and not main._overlay.visible, "về P5 trở xuống: không popup")
	main._sales_position = 1
	main._sales_tutorial_hit = true
	check(not main._hold_for_sales_popup(), "lượt có hướng dẫn: không popup")
	main._sales_tutorial_hit = false
	main._select_tab(1)
	main._sales_position = 1
	check(not main._hold_for_sales_popup(), "đang ở tab khác: không popup")
	main._select_tab(0)
	await settle()
	main._sales_position = 1
	check(main._hold_for_sales_popup(), "đủ điều kiện: giữ vòng đua")
	await settle()
	check(main._overlay.visible and main._sales_sku == "starter_1", "popup starter_1 đang mở")
	check(main._hold_for_sales_popup(), "vẫn giữ khi popup còn mở")
	main._close_overlay()
	await settle()
	check(not main._hold_for_sales_popup(), "đóng popup thì chạy tiếp")

	print("SALES_POPUP_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
