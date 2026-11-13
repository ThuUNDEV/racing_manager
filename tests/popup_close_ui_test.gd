extends SceneTree
## Verify close actions and narrow-screen layout without touching the player save.
var failures := 0
var main: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func verify(control: Control, button_name: String, tag: String) -> void:
	await settle()
	var button := control.find_child(button_name, true, false) as Button
	check(button != null, tag + " has close button")
	if button == null:
		return
	var rect := button.get_global_rect()
	check(rect.size.x >= 48 and rect.size.y >= 48, tag + " touch target")
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(rect), tag + " close fits viewport")
	var header := button.get_parent() as Control
	for child in header.get_children():
		if child is Label:
			check(child.get_global_rect().end.x <= rect.position.x - 7, tag + " title clears X")
	if "--popup-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var directory := OS.get_environment("TEMP").replace("\\", "/") + "/racing_popup_close"
		DirAccess.make_dir_recursive_absolute(directory)
		root.get_texture().get_image().save_png(directory + "/%d_%s.png" % [root.size.x, tag])
	button.pressed.emit()
	await settle()
	check(not control.visible, tag + " closes")

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "Save isolation")
	GameData.reload()
	state.init_new_game()
	state.active = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	var coins_before = state.coins.to_save()
	var gems_before: int = state.gems
	var name_before: String = state.player_team_name
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		main._show_settings()
		await verify(main._overlay, "SettingsClose", "settings")
		main._show_gear_info("standard")
		await verify(main._overlay, "PopupClose", "gear_info")
		main._show_driver_info("pro")
		await verify(main._overlay, "PopupClose", "driver_info")
		main._show_shop_offer("PASS THÁNG", "Nhận thưởng mỗi ngày.")
		await verify(main._overlay, "PopupClose", "shop_offer")
		main._profile.open()
		main._profile._show_edit()
		main._profile._name_input.text = "Unsaved draft"
		await verify(main._profile._dialog, "PopupClose", "edit_name")
		check(state.player_team_name == name_before, "X discards name draft")
		main._profile._close()
		main._class_page.open()
		await verify(main._class_page, "ClassClose", "classes")
		main._select_tab(main.Tab.TEAM)
		main._select_team_sub(0)
		main._roster._open_sheet(state.active_driver_id)
		await verify(main._roster.sheet, "DriverDetailClose", "driver_detail")
	check(state.coins.to_save() == coins_before and state.gems == gems_before, "Closing does not spend currency")
	state.offline_report = {"elapsed": 540.0, "eligible": 540.0, "rate": 8.0, "ratio": 0.5, "reward": BigNumber.from_int(2160), "capped": false}
	main._show_offline()
	await settle()
	check(main._overlay.find_child("PopupClose", true, false) == null, "Offline keeps Continue without X")
	main._show_gear_result({"payment": {"method": "coupon", "amount": 1}, "results": []})
	await settle()
	check(main._overlay.find_child("PopupClose", true, false) == null, "Pack result keeps Done without X")
	main.queue_free()
	await settle()
	print("POPUP_CLOSE_UI_TEST failures=", failures)
	quit(1 if failures else 0)
