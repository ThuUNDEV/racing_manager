extends SceneTree
const PopupAnim = preload("res://ui/popup_anim.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1
func settle() -> void:
	for i in range(8):
		await process_frame
func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.save_blocked = true
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "offline-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var coins_before = state.coins.to_save()
	for capped in [false, true]:
		var elapsed := 861.0 * 60.0 if capped else 15.0 * 60.0
		state.offline_report = {"elapsed": elapsed, "eligible": minf(elapsed, Balance.offline_cap_sec()), "rate": 8.0, "ratio": 0.5, "reward": BigNumber.from_int(28800 if capped else 3600), "capped": capped}
		main._show_offline()
		await settle()
		var initial_button = main._overlay_box.find_child("OfflineContinue", true, false)
		var initial_panel = main._overlay_box.get_parent().get_parent()
		check(initial_panel.get_global_rect().end.y - initial_button.get_global_rect().end.y < 35.0, "First-open panel hugs content")
		for width in [320, 390, 412]:
			root.size = Vector2i(width, 844)
			await settle()
			var box: VBoxContainer = main._overlay_box
			check(box.get_global_rect().end.x <= width, "Popup fits width %d capped=%s" % [width, capped])
			var button = box.find_child("OfflineContinue", true, false)
			var button_skin := button.get_theme_stylebox("normal") as StyleBoxTexture
			check(button.size.x > 3 * button.size.y and button_skin.texture_margin_left + button_skin.texture_margin_right < button.size.x, "Continue stays wide with intact nine-slice caps")
			check(button.get_global_rect().end.y < root.size.y, "Continue visible at %d" % width)
			var panel: PanelContainer = box.get_parent().get_parent()
			check(panel.get_global_rect().end.y - button.get_global_rect().end.y < 35.0, "No empty panel below Continue at %d" % width)
			if "--offline-shots" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://Design/Previews/offline_%d_%s.png" % [width, "capped" if capped else "short"])
		check(main._overlay_box.find_child("OfflineInfo", true, false) == null, "No info icon")
		var progress = main._overlay_box.find_child("OfflineProgress", true, false)
		check(is_equal_approx(progress.value, minf(elapsed, Balance.offline_cap_sec())), "Progress uses eligible duration")
		check(state.coins.to_save() == coins_before, "Opening report does not award money again")
		main._overlay_box.find_child("OfflineContinue", true, false).pressed.emit()
		await settle()
		check(state.offline_report.is_empty(), "Continue clears report")
	check(main._offline_duration(7200.0) == "2 giờ", "Whole hours formatted")
	check(main._offline_duration(51660.0) == "14 giờ 21 phút", "Mixed duration formatted")
	main.queue_free()
	await settle()
	await check_tutorial_order()
	quit(1 if failures else 0)


func check_tutorial_order() -> void:
	var state := root.get_node("GameState")
	state.init_new_game()
	state.active = false
	state.save_blocked = true
	state.tutorial = {"state": "active", "step": "A7_race2", "gated": true}
	state.offline_report = {"elapsed": 120.0, "eligible": 120.0, "reward": BigNumber.from_int(666), "capped": false}
	var report: Dictionary = state.offline_report.duplicate(true)
	var coins_before: Dictionary = state.coins.to_save()
	var animation_enabled := PopupAnim.enabled
	PopupAnim.enabled = false
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "offline-tutorial-order"
	main._cli_tutorial = true
	root.add_child(main)
	await settle()
	main.set_process(false)
	main._tutorial.set_process(false)
	main.activate()
	var tut = main._tutorial
	tut.blocked = false
	tut._process(0.1)
	check(tut.running and tut.step == "A7_race2" and not main._overlay.visible, "Vào game: A7 hiện trước popup offline")
	check(main._offline_popup_pending and state.offline_report == report and not bool(state.tutorial.get("offline_shown", false)), "Báo cáo offline được giữ nguyên và chưa tính là đã xem")
	main._pump_offline_popup()
	tut._on_primary()
	main._pump_offline_popup()
	check(tut.running and not main._overlay.visible, "Chưa đọc hết A7: offline tiếp tục chờ")
	tut._on_primary()
	check(not tut.running and state.tutorial_state() == "done", "Xác nhận xong lời kết A7")
	main._pump_offline_popup()
	await settle()
	check(main._overlay.visible and not main._offline_popup_pending and main._overlay_box.find_child("OfflineContinue", true, false) != null, "A7 hoàn tất: popup offline mới xuất hiện")
	check(state.offline_report == report and state.coins.to_save() == coins_before, "Trì hoãn popup không cộng thưởng lần hai hoặc đổi báo cáo")
	var frame = main._overlay_box.find_child("OfflineFrame", true, false)
	main._pump_offline_popup()
	check(frame == main._overlay_box.find_child("OfflineFrame", true, false), "Popup offline chỉ mở một lần sau A7")
	main._overlay_box.find_child("OfflineContinue", true, false).pressed.emit()
	check(state.offline_report.is_empty(), "Tiếp tục: xóa báo cáo sau khi đã xem")
	state.offline_report = report.duplicate(true)
	main._open_next_overlay()
	check(main._overlay.visible and not main._offline_popup_pending, "Save đã xong tutorial: offline vẫn mở ngay")
	main.queue_free()
	await settle()
	PopupAnim.enabled = animation_enabled

