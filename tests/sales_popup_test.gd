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

var allow_timed := false


func fresh() -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	iap.session_start = T0 - 10.0
	if not allow_timed:
		for p: Dictionary in GameData.iap_products():
			if String(p["kind"]) in ["limited", "chooseone"]:
				state.iap["offers"][String(p["sku"])] = {"dropped": true}

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
	(state.iap["owned"] as Array).append("income_x2")  # gói tiện ích có popup riêng, kiểm ở khối dưới
	state.iap["offers"]["no_ads"] = {"open_t": T0, "popup_count": 3, "last_popup_day": -1}
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

	# Nhóm và điểm ưu tiên (Design/35 §5): nhóm theo popup.groups, trong nhóm theo prio giảm dần.
	fresh()
	state.business_tier = 2
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	check(iap.sales_popup_queue(T0) == ["income_x2", "offer_combo_1", "no_ads"], "income_x2 (prio 300) trước combo; no_ads (nhóm superior) cuối: %s" % [iap.sales_popup_queue(T0)])
	state.business_tier = 1
	check(iap.sales_popup_queue(T0) == ["income_x2", "no_ads"], "bậc 1: chỉ hai gói tiện ích, tiện ích đứng trước")
	state.ad_state["break"] = {"day": int(Time.get_unix_time_from_system() / 86400.0), "today": 3}
	iap.note_ad_breaks(3)
	check(iap.sales_popup_queue(T0) == ["income_x2", "offer_noads_bundle"], "gói bundle đang bán thì no_ads đơn lẻ không tự hiện: %s" % [iap.sales_popup_queue(T0)])

	# Ưu đãi xoay tuần: nhóm forced + high_priority, chỉ ô popup của vòng hiện tại (Design/35 đợt C+D).
	allow_timed = true
	fresh()
	state.business_tier = 1
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	check(not iap.sales_popup_queue(T0).has("limited_%d_2" % iap.rotation_of("limited")), "bậc 1: chưa có popup gói giới hạn")
	state.business_tier = 2
	var limited_pick := "limited_%d_2" % iap.rotation_of("limited")
	var choose_pick := "chooseone_m_%d" % iap.rotation_of("chooseone")
	var timed_queue: Array = iap.sales_popup_queue(T0)
	check(timed_queue.has(limited_pick) and timed_queue.has(choose_pick), "bậc 2: gói giới hạn và chọn một vòng hiện tại vào hàng đợi: %s" % [timed_queue])
	check(timed_queue.size() == timed_queue.filter(func(sku: String) -> bool: return not sku.begins_with("limited_") and not sku.begins_with("chooseone_")).size() + 2, "chỉ hai gói xoay tuần tự hiện (ô giữa và M)")
	check(timed_queue.find(limited_pick) < timed_queue.find("no_ads"), "nhóm forced đứng trước nhóm superior")
	iap.note_sales_popup("income_x2", T0)
	var forced_now: Array = pick(T0 + 100.0)
	check(forced_now == [limited_pick, ""], "gói giới hạn hiện dù chưa đủ gap_sec (high_priority); gói chọn một không: %s" % [forced_now])
	iap.note_sales_popup(forced_now[0], T0 + 100.0)
	check(pick(T0 + 200.0) == ["", "gap"], "sau lần đầu ưu tiên cao, gói chọn một theo gap_sec")
	allow_timed = false

	# Trạng thái dropped: gói rời hàng đợi (đã mua) trước khi hiện đủ lần.
	fresh()
	state.business_tier = 1
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	check(iap.sales_popup_queue(T0).has("income_x2") and not iap.popup_dropped("income_x2"), "income_x2 đang chờ, chưa dropped")
	(state.iap["owned"] as Array).append("income_x2")
	check(not iap.sales_popup_queue(T0).has("income_x2") and iap.popup_dropped("income_x2"), "mua xong khi chưa hiện đủ: dropped, không vào lại hàng đợi")
	check(not iap.popup_dropped("no_ads"), "gói khác không bị ảnh hưởng")

	# Lần đầu ưu tiên cao: bỏ qua gap_sec, chỉ một lần (Design/35 §5, cờ HighPriorityUsed của game gốc).
	fresh()
	state.business_tier = 1
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	GameData.iap()["products"].append({"sku": "test_forced", "kind": "offer", "usd": 1.99, "price_fallback": "$1.99", "consumable": true,
		"once": true, "auto_popup": 2, "high_priority": true, "popup_group": "forced", "grant": {"gems": 1}})
	iap.note_sales_popup("income_x2", T0)
	check(pick(T0 + 100.0) == ["test_forced", ""], "gói high_priority hiện dù chưa đủ gap_sec")
	iap.note_sales_popup("test_forced", T0 + 100.0)
	check(bool(state.iap["offers"]["test_forced"]["high_used"]), "ghi cờ high_used")
	check(pick(T0 + 200.0) == ["", "gap"], "lần sau đi hàng thường: bị gap_sec chặn")
	GameData.reload()

	# Tiện ích mới của game gốc: income_x3 / income_x3_up / offline_plus mở từ trận thứ 5, income_x3 nhường income_x3_up khi đã có ×2.
	fresh()
	state.business_tier = 1
	for sku in ["starter_1", "starter_2", "starter_3"]:
		buy(sku)
	state.completed_races = 4
	check(not iap.sales_popup_queue(T0).has("income_x3") and not iap.sales_popup_queue(T0).has("offline_plus"), "chưa đủ 5 trận: chưa có popup ×3 / offline")
	state.completed_races = 5
	check(iap.sales_popup_queue(T0) == ["income_x2", "income_x3", "offline_plus", "no_ads"], "đủ 5 trận: x2 (300), x3 (100), offline (0) rồi no_ads (superior): %s" % [iap.sales_popup_queue(T0)])
	check(iap.block_reason("income_x3_up") == "requires", "income_x3_up cần income_x2")
	(state.iap["owned"] as Array).append("income_x2")
	var queue_after_x2: Array = iap.sales_popup_queue(T0)
	check(queue_after_x2 == ["income_x3_up", "offline_plus", "no_ads"], "có ×2: income_x3_up thay income_x3: %s" % [queue_after_x2])
	check(iap.popup_dropped("income_x3") and iap.block_reason("income_x3") == "hidden", "income_x3 bị ẩn và dropped")
	(state.iap["owned"] as Array).append("income_x3")
	check(state.purchased_mult() == 3 and iap.block_reason("income_x3_up") == "owned", "đã có ×3: income_x3_up không bán nữa")

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
