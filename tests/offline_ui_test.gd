extends SceneTree
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
			check(button_skin.texture.get_width() > 3 * button_skin.texture.get_height(), "Continue uses a wide button skin")
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
	quit(1 if failures else 0)

