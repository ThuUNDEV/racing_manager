extends SceneTree

## Chạy: godot --headless --path . -s res://tests/daily_rewards_ui_test.gd
## UI thưởng đăng nhập (Design/30 §5, P1): ẩn trước khi mở khóa, nút Home + chấm đỏ + chấm tab Shop, dòng trong Shop,
## popup 7 ô + mốc, nhận qua nút, đếm ngược sau khi nhận, ba bề rộng điện thoại không tràn.
## Thêm `-- --daily-shots` để lưu ảnh vào Design/Previews (cần renderer cửa sổ).

var _fails := 0
const D0 := 20000
const PopupAnim = preload("res://ui/popup_anim.gd")


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _settle() -> void:
	for i in 6:
		await process_frame


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if "--daily-shots" in OS.get_cmdline_user_args():
		PopupAnim.enabled = false
	var gs := root.get_node("GameState")
	GameData.reload()
	# Tắt thẻ quảng cáo miễn phí: chấm tab Shop cũng sáng khi có video sẵn, sẽ lẫn với chấm quà.
	var ads_cfg: Dictionary = GameData.ads().duplicate(true)
	for pl in ["free_gems", "free_driver_coupon", "free_gear_coupon"]:
		(ads_cfg["placements"] as Dictionary).erase(pl)
	GameData.set_override("ads", ads_cfg)
	gs.SAVE_PATH = "user://daily_rewards_ui_test_save.json"
	gs.BAK_PATH = "user://daily_rewards_ui_test_save.bak"
	gs.TMP_PATH = "user://daily_rewards_ui_test_save.tmp"
	gs.init_new_game()
	gs.tutorial["gated"] = true
	gs.completed_races = 3
	var seen: Array = []
	for f: Dictionary in Tutorial.features():
		seen.append(String(f["id"]))
	gs.tutorial["intro_seen"] = seen  # chấm "tính năng mới" không lẫn với chấm quà
	gs.daily_device_unix = float(D0) * 86400.0 + 3600.0
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()

	print("== Trước khi mở khóa ==")
	var btn := main.find_child("DailyRewardsButton", true, false) as Button
	_check(btn != null and not btn.visible, "nút quà ẩn khi chưa mở khóa (3 lượt)")
	var nav_dot := (main._nav_items[main.Tab.SHOP] as Control).get_node("NavDot") as Control
	_check(not nav_dot.visible, "chấm tab Shop tắt")

	print("== Sau khi mở khóa ==")
	gs.completed_races = 5
	main._lock_sig = ""
	main._refresh_light()
	await _settle()
	_check(btn.visible, "đủ 5 lượt: nút quà hiện")
	_check((btn.get_node("DailyDot") as Control).visible, "chấm đỏ trên nút khi nhận được")
	_check(nav_dot.visible, "chấm đỏ tab Shop khi nhận được")
	main._select_tab(main.Tab.SHOP)
	await _settle()
	var row := main.find_child("DailyLoginRow", true, false) as Control
	var open_btn := main.find_child("OpenDailyRewards", true, false) as Button
	_check(row != null and row.visible and open_btn.text == "Nhận quà", "Shop có dòng Quà mỗi ngày, nút 'Nhận quà'")
	main._select_tab(main.Tab.RACE)
	await _settle()

	print("== Popup ==")
	btn.pressed.emit()
	await _settle()
	_check(main._overlay.visible and main._daily_popup != null, "bấm nút mở popup")
	var cells: Array = main._overlay_box.find_children("DailyCell*", "PanelContainer", true, false)
	_check(cells.size() == 7, "7 ô ngày")
	var grand := main._overlay_box.find_child("DailyCell7", true, false) as Control
	var c1 := main._overlay_box.find_child("DailyCell1", true, false) as Control
	_check(grand.size.x > c1.size.x * 2.5, "ô ngày 7 chiếm trọn hàng")
	var canvas: Control = main._daily_popup.find_child("ReferenceCanvas", true, false)
	_check(canvas != null and absf(canvas.scale.x - canvas.scale.y) < 0.001, "giữ nguyên tỷ lệ ref, không bóp chiều ngang ruy băng")
	var first_rect: Rect2 = c1.get_global_rect()
	var design_origin: Vector2 = canvas.global_position
	var design_scale: float = canvas.scale.x
	_check(first_rect.position.distance_to(design_origin + Vector2(60, 350) * design_scale) < 1.0 and absf(first_rect.size.x / design_scale - 274) < 1.0, "ô ngày giữ đúng tọa độ và kích thước ref")
	_check(main._daily_popup.find_child("DailyRow1", true, false).get_child_count() == 3 and main._daily_popup.find_child("DailyRow2", true, false).get_child_count() == 3, "ngày 1–6: bố cục 3 cột")
	_check(main._overlay_box.find_children("Milestone*", "VBoxContainer", true, false).size() == 4, "4 mốc hiển thị")
	var claim := main._overlay_box.find_child("ClaimDailyReward", true, false) as Button
	_check(claim != null and not claim.disabled and _has_text(claim, "NHẬN QUÀ"), "nút NHẬN bật")
	if "--daily-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/daily_rewards_approved_runtime_390.png")
	var pro0: int = int(gs.driver_coupons["pro"])
	claim.pressed.emit()
	await _settle()
	_check(int(gs.driver_coupons["pro"]) == pro0 + 2, "bấm NHẬN: +2 vé Pro (ngày 1)")
	claim = main._overlay_box.find_child("ClaimDailyReward", true, false) as Button
	_check(claim.disabled and claim.text.begins_with("Mở lại sau"), "sau khi nhận: nút khóa, hiện đếm ngược")
	_check(not (btn.get_node("DailyDot") as Control).visible and not nav_dot.visible, "nhận xong: tắt hai chấm đỏ")
	_check(_popup_script().reward_line(gs.last_daily_reward) == "2 vé Pro", "reward_line đúng: '%s'" % _popup_script().reward_line(gs.last_daily_reward))
	var first_cell := main._overlay_box.find_child("DailyCell1", true, false) as PanelContainer
	_check(first_cell != null and _has_text(first_cell, "ĐÃ NHẬN"), "ô ngày 1 có nhãn ĐÃ NHẬN")
	var claimed_badge := first_cell.find_child("ClaimedBadge", true, false) as Control
	var claimed_icon := first_cell.find_child("RewardIcon", true, false) as Control
	var claimed_quantity := first_cell.find_child("RewardQuantity", true, false) as Control
	_check(claimed_badge != null and first_cell.get_global_rect().encloses(claimed_badge.get_global_rect()), "nhãn xanh nằm trọn trong thẻ đã nhận")
	_check(is_equal_approx(claimed_icon.self_modulate.a, 0.25) and is_equal_approx(claimed_quantity.self_modulate.a, 0.30), "quà đã nhận: icon và số thưởng mờ rõ, nhãn giữ nguyên độ rõ")
	if "--daily-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/daily_rewards_claimed_runtime_390.png")
	var second_cell := main._overlay_box.find_child("DailyCell2", true, false) as PanelContainer
	_check(second_cell != null and _has_text(second_cell, "Ngày mai"), "ô ngày 2 là Ngày mai")

	print("== Qua ngày ==")
	gs.daily_device_unix = float(D0 + 1) * 86400.0 + 5.0
	await create_timer(0.9).timeout
	await _settle()
	claim = main._overlay_box.find_child("ClaimDailyReward", true, false) as Button
	_check(not claim.disabled and _has_text(claim, "NHẬN QUÀ"), "qua 00:00 UTC khi popup đang mở: nút tự bật lại")
	var st_cell := main._overlay_box.find_child("DailyCell2", true, false) as PanelContainer
	_check(_has_text(st_cell, "HÔM NAY"), "ô ngày 2 thành Hôm nay")
	main._daily_popup.closed.emit()
	await create_timer(PopupAnim.CLOSE_SEC + 0.05).timeout
	await _settle()
	_check(not main._overlay.visible, "nút đóng tắt popup")

	print("== Dòng Shop mở popup ==")
	main._select_tab(main.Tab.SHOP)
	await _settle()
	open_btn.pressed.emit()
	await _settle()
	_check(main._overlay.visible and main._overlay_box.find_child("DailyCell1", true, false) != null, "nút trong Shop mở cùng popup")
	main._overlay.hide()

	print("== Bề rộng điện thoại ==")
	for w in [320, 390, 412]:
		root.size = Vector2i(w, 844)
		await _settle()
		main._select_tab(main.Tab.RACE)
		btn.pressed.emit()
		await _settle()
		var panel := main._overlay_box.get_parent().get_parent() as Control
		var fit: bool = panel.get_global_rect().size.x <= float(w) and main._overlay_box.get_global_rect().end.x <= float(w) + 0.5
		_check(fit, "%d px: popup không tràn ngang (rộng %.0f)" % [w, panel.get_global_rect().size.x])
		var bounds: Rect2 = main._daily_popup.get_global_rect()
		var content_fits := bounds.position.y >= 0 and bounds.end.y <= root.size.y
		for label: Label in main._daily_popup.find_children("*", "Label", true, false):
			content_fits = content_fits and bounds.encloses(label.get_global_rect())
		_check(content_fits, "%d px: chữ và phần thưởng nằm trọn trong popup" % w)
		var head_ok := true
		for b in [btn, main._class_btn, main._sched_btn]:
			head_ok = head_ok and (b as Control).get_global_rect().end.x <= float(w) + 0.5
		_check(head_ok, "%d px: nút Lịch/Class/Quà vẫn nằm trong màn hình" % w)
		if "--daily-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/daily_rewards_%d.png" % w)
		main._overlay.hide()

	print("== Mốc hỗn hợp và chu kỳ Grand ==")
	var saved_daily: Dictionary = gs.daily_rewards.duplicate(true)
	root.size = Vector2i(320, 844)
	gs.daily_rewards["cycle_day"] = 6
	gs.daily_rewards["total_days"] = 48
	gs.daily_rewards["claimed_milestones"] = 4
	for ordinal in 7:
		gs.daily_rewards["grand_ordinal"] = ordinal
		btn.pressed.emit()
		await _settle()
		grand = main._daily_popup.find_child("DailyCell7", true, false)
		var grand_fits := true
		for label: Label in grand.find_children("*", "Label", true, false):
			grand_fits = grand_fits and grand.get_global_rect().encloses(label.get_global_rect())
		var action: Control = main._daily_popup.find_child("ClaimDailyReward", true, false)
		var sc: Control = main._overlay_box.get_parent()
		grand_fits = grand_fits and sc.get_global_rect().encloses(action.get_global_rect())
		_check(grand_fits, "320 px: Grand vòng %d hiển thị đủ phần thưởng và nút nhận" % ordinal)
		if ordinal == 6 and "--daily-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/daily_rewards_grand_runtime_320.png")
		main._overlay.hide()
	gs.daily_rewards["last_claim_day"] = gs.daily_reward_today()
	gs.daily_rewards["total_days"] = 49
	gs.daily_rewards["cycle_day"] = 0
	gs.daily_rewards["grand_ordinal"] = 0
	btn.pressed.emit()
	await _settle()
	grand = main._daily_popup.find_child("DailyCell7", true, false)
	var grand_badge := grand.find_child("ClaimedBadge", true, false) as Control
	_check(grand_badge != null and grand.get_global_rect().encloses(grand_badge.get_global_rect()) and _has_text(grand, "ĐÃ NHẬN"), "hoàn thành ngày 7: nhãn xanh nằm trọn trong thẻ")
	main._overlay.hide()
	gs.daily_rewards = saved_daily
	btn.pressed.emit()
	await _settle()
	var mixed: Node = main._daily_popup.find_child("Milestone30", true, false)
	var reward_columns: Node = mixed.find_child("MilestoneRewards", true, false)
	_check(reward_columns.get_child_count() == 2, "mốc 30: hai cột icon trên, số lượng dưới, không đường phân cách")
	main._overlay.hide()

	print("== P2: tự bật mỗi ngày (R4) ==")
	main.activate()
	main._overlay.hide()
	main._select_tab(main.Tab.RACE)
	gs.daily_device_unix = float(D0 + 10) * 86400.0 + 100.0
	gs.daily_rewards = DailyRewards.observe(gs.daily_rewards, D0 + 10)
	await _settle()
	_check(not main._overlay.visible, "vừa sang ngày mới: chưa bật ngay (có độ trễ)")
	main._tutorial.running = true
	await create_timer(1.6).timeout
	_check(not main._overlay.visible, "đang hướng dẫn: không tự bật")
	main._tutorial.running = false
	await create_timer(1.8).timeout
	_check(main._overlay.visible and main._daily_popup != null and is_instance_valid(main._daily_popup), "rảnh đủ 1.2 giây: popup tự bật")
	_check(int(gs.daily_rewards["popup_shown_day"]) == D0 + 10, "ghi popup_shown_day")
	main._daily_popup.closed.emit()
	await create_timer(1.8).timeout
	_check(not main._overlay.visible, "đóng rồi (chưa nhận): không bật lại trong ngày")
	_check(gs.daily_reward_available(), "đóng popup không làm mất quyền nhận")
	gs.daily_device_unix = float(D0 + 11) * 86400.0 + 100.0
	await create_timer(1.8).timeout
	_check(main._overlay.visible, "ngày sau: tự bật lại")
	var claim2 := main._overlay_box.find_child("ClaimDailyReward", true, false) as Button
	claim2.pressed.emit()
	await _settle()
	main._daily_popup.closed.emit()
	await create_timer(1.8).timeout
	_check(not main._overlay.visible, "đã nhận: không bật lại")
	gs.daily_device_unix = float(D0 + 12) * 86400.0 + 100.0
	main._result_timer = 100.0
	main._result_panel.show()
	await create_timer(1.8).timeout
	_check(not main._overlay.visible, "đang hiện bảng kết quả đua: không bật")
	main._result_panel.hide()

	print("")
	print("DAILY REWARDS UI TEST: " + ("ĐẠT" if _fails == 0 else "%d lỗi" % _fails))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://daily_rewards_ui_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://daily_rewards_ui_test_save.bak"))
	quit(1 if _fails > 0 else 0)


## Nạp lúc chạy: popup dùng autoload GameState, không biên dịch được khi test script còn đang nạp.
func _popup_script() -> GDScript:
	return load("res://ui/daily_rewards_popup.gd") as GDScript


func _has_text(node: Node, text: String) -> bool:
	for l in node.find_children("*", "Label", true, false):
		if (l as Label).text == text:
			return true
	return false
