extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print("OK " if ok else "FAIL ", message)
func settle() -> void:
	for i in 10:
		await process_frame
func shot(id: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Design/Previews/clean_modern_demo_%d_%s.png" % [root.size.x, id])
func run() -> void:
	var font := HdUi.font()
	check(font.resource_path == "res://assets/clean_modern/fonts/Roboto-Bold.ttf", "bundled real bold font")
	for character in "ĐđĂăÂâÊêÔôƠơƯưẮằẶẫễộớựỷỹ":
		check(font.has_char(character.unicode_at(0)), "Vietnamese glyph " + character)
	var gs := root.get_node("GameState")
	check(gs.SAVE_PATH.contains("/tests/"), "isolated save")
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["gated"] = false
	gs.tutorial["state"] = "done"
	var ads := root.get_node("Ads")
	var provider := MockAdsProvider.new()
	provider.tree = self
	ads.provider = provider
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		main._select_tab(main.Tab.RACE)
		main._race_view.overlay_text = "3"
		main._race_view.queue_redraw()
		main._status_label.text = "Xuất phát sau 3 giây · 8 xe trên grid"
		await settle()
		check(main._race_view.stand_rect() == Rect2(0, RaceView.HUD_H, main._race_view.size.x, RaceView.STAND_H), "audience retains original band below HUD")
		check(main._race_view._top == RaceView.HUD_H + RaceView.STAND_H, "track reserves space for original audience layout")
		var chip: Button = main._ads_controls._chip
		check(chip.is_visible_in_tree() and not chip.disabled, "x2 available at %d" % width)
		check(main._race_view.get_global_rect().encloses(chip.get_global_rect()), "x2 target inside race frame")
		var point := chip.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		root.push_input(motion, true)
		await settle()
		check(root.gui_get_hovered_control() == chip, "x2 receives pointer events")
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = point
			click.global_position = point
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			root.push_input(click, true)
		await settle()
		check(main._ads_controls._popup.visible, "x2 opens reward popup")
		main._ads_controls._on_later()
		await shot("race")
		main._select_tab(main.Tab.TEAM)
		main._race_view.overlay_text = ""
		main._race_view.queue_redraw()
		main._select_team_sub(0)
		await shot("drivers")
		main._select_tab(main.Tab.SHOP)
		await shot("shop")
		check(main._shop_content.size.x <= width - 24, "Shop remains inside viewport at %d" % width)
		main._select_tab(main.Tab.RACE)
		main._show_classes()
		await shot("classes")
		main._class_page._close()
	root.size = Vector2i(390, 844)
	gs.begin_countdown()
	gs._start_race()
	gs.active = false
	main._sync_sim()
	main._update_race_ui()
	main._race_view.overlay_text = ""
	main._race_view.queue_redraw()
	await shot("live_race")
	# Unavailable offers remain discoverable and explain why they cannot play yet.
	gs.ad_state["day"] = int(floor(Time.get_unix_time_from_system() / 86400.0))
	gs.ad_state["by"] = {"income_boost": 3}
	main._ads_controls._refresh_chip()
	check(main._ads_controls._chip.visible and main._ads_controls._chip.disabled and main._ads_controls._chip_time.text == "Hết lượt ngày", "daily limit keeps x2 visible with reason")
	gs.ad_state["by"] = {}
	gs.tutorial["gated"] = true
	gs.tutorial["intro_seen"] = []
	main._ads_controls._refresh_chip()
	check(main._ads_controls._chip.visible and main._ads_controls._chip.disabled and main._ads_controls._chip_time.text == "Mở Shop", "locked boost explains unlock")
	main.queue_free()
	await settle()
	print("CLEAN_MODERN_DEMO_TEST failures=", failures)
	quit(1 if failures else 0)
