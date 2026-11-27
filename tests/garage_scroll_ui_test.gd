extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for frame in 8:
		await process_frame
func run() -> void:
	GameData.reload()
	var gs := root.get_node("GameState")
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["state"] = "done"
	gs.tutorial["gated"] = false
	check(gs.SAVE_PATH.contains("/tests/"), "Save cách ly")
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390,845)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(1)
	await settle()
	var garage = main._garage
	for width in [320,390,412]:
		root.size = Vector2i(width,roundi(width * 845.0 / 390))
		garage._sig = ""
		garage.refresh()
		await settle()
		for id in ["car_apex_bam_duong", "car_titan_bam_duong", "car_zenith_ben_bi"]:
			var scroll: ScrollContainer = garage.get_node("GarageContent")
			var card: Button = garage.find_child("Collection_" + id, true, false)
			scroll.scroll_vertical += roundi(card.global_position.y - scroll.global_position.y - 40)
			await settle()
			check(scroll.scroll_vertical > 0, "Fixture có cuộn %d %s" % [width,id])
			var before := card.global_position.y
			if "--click-input" in OS.get_cmdline_user_args():
				var point := card.get_global_rect().get_center()
				var motion := InputEventMouseMotion.new()
				motion.position = point
				root.push_input(motion, true)
				var press := InputEventMouseButton.new()
				press.position = point
				press.button_index = MOUSE_BUTTON_LEFT
				press.pressed = true
				root.push_input(press, true)
				await process_frame
				var release := InputEventMouseButton.new()
				release.position = point
				release.button_index = MOUSE_BUTTON_LEFT
				root.push_input(release, true)
			else:
				card.pressed.emit()
			await settle()
			scroll = garage.get_node("GarageContent")
			card = garage.find_child("Collection_" + id, true, false)
			check(garage._viewed == id, "Chọn xe hoạt động")
			check(scroll.scroll_vertical > 0, "Không nhảy lên đầu %d %s" % [width,id])
			check(absf(card.global_position.y - before) <= 1.0, "Thẻ giữ vị trí dù summary đổi chiều cao %d %s" % [width,id])
			before = card.global_position.y
			garage._sig = ""
			garage.refresh()
			await settle()
			card = garage.find_child("Collection_" + id, true, false)
			check(absf(card.global_position.y - before) <= 1.0, "Refresh giữ vị trí %d" % width)
		garage._set_section(1)
		await settle()
		check(garage.get_node("GarageContent").scroll_vertical == 0, "Mục khác bắt đầu từ đầu")
		garage._set_section(0)
		await settle()
	main.queue_free()
	await settle()
	print("GARAGE_SCROLL_UI_TEST failures=", failures)
	quit(1 if failures else 0)
