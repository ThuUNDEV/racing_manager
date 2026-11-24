extends SceneTree
## Preview the Vietnamese story using an isolated save.
## godot --path . -s res://tools/preview_tutorial_story.gd
## Add -- --capture for screenshots and layout validation at three widths.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	I18n.set_lang("vi")
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_story_preview.json"
	state.BAK_PATH = "user://tutorial_story_preview.bak"
	state.TMP_PATH = "user://tutorial_story_preview.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.begin_countdown()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	root.title = "Racing Manager — Thử kịch bản Linh"
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(8):
		await process_frame
	main._overlay.hide()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lesson="):
			await preview_lesson(main, state, argument.substr(9))
			return
	if "--capture-trophy" in OS.get_cmdline_user_args():
		await capture_trophy(main, state)
		return
	if "--capture-income" in OS.get_cmdline_user_args():
		await capture_income(main, state)
		return
	if "--capture-shop" in OS.get_cmdline_user_args():
		await capture_shop(main, state)
		return
	if not "--capture" in OS.get_cmdline_user_args():
		state.active = true
		main.activate()
		return
	main.set_process(false)
	main._sync_sim()
	var tut = main._tutorial
	tut.set_process(false)
	tut.start()
	var failures := 0
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for step in ["A1_welcome", "A3_income", "A4_engine"]:
			tut._enter(step)
			if step == "A3_income":
				tut._process(Tutorial.RUN_BEFORE_A3_SEC)
			for page in range(2):
				tut._page = page
				for i in range(8):
					tut._process(0.01)
					await process_frame
				await RenderingServer.frame_post_draw
				var panel: Rect2 = tut._panel.get_rect()
				if panel.position.x < 0 or panel.position.y < 0 or panel.end.x > width + 1 or panel.end.y > root.size.y + 1:
					push_error("Story callout outside screen: %s/%s/%s" % [width, step, page])
					failures += 1
				root.get_texture().get_image().save_png("res://Design/Previews/tutorial_story_%d_%s_%d.png" % [width, step, page])
	print("tutorial_story_preview: %d layout failures" % failures)
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)


func capture_shop(main: Control, state: Node) -> void:
	main.set_process(false)
	var tut = main._tutorial
	tut.set_process(false)
	state.completed_races = 3
	state.tutorial = {"state": "done", "step": "", "gated": true}
	state.grant_gear_coupons("standard", 1)
	main._select_tab(main.Tab.SHOP)
	main._shop_content.update_packs()
	for i in range(8):
		await process_frame
	tut.show_intro("U4_shop")
	tut.blocked = false
	tut._process(0.01)
	tut._on_primary()
	for stage in ["coupon", "complete"]:
		if stage == "complete":
			state.open_gear_pack("standard", 1)
		for i in range(10):
			tut._process(0.01)
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/tutorial_shop_%s_fixed.png" % stage)
	main.queue_free()
	await process_frame
	quit()


## Isolated fixtures for any one of the seventeen lessons.
func preview_lesson(main: Control, state: Node, id: String) -> void:
	var lesson := Tutorial.lesson(id)
	if lesson.is_empty():
		push_error("Unknown tutorial: " + id)
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--from="):
			await preview_route(main, state, id, argument.substr(7))
			return
	state.tutorial = {"state": "done", "step": "", "gated": false, "tips_off": true}
	state.completed_races = int(lesson.get("races", 10))
	state.trophies = 1 if id == "U2_league" else 500
	state.trophies_earned = state.trophies
	state.gear_coupons["standard"] = 1
	state.driver_coupons["pro"] = 1
	state.tutorial["offline_shown"] = true
	if id == "C4_star":
		state.levels["ticket"] = 23
	if id == "C5_shards":
		state.gear_owned[String(GameData.gear_items()[0]["id"])] = {"level": 0, "shards": 1000}
	if id == "C6_weaker":
		state.owned_drivers.clear()
		for driver: Dictionary in GameData.drivers():
			state.owned_drivers.append(String(driver["id"]))
		state.active_driver_id = "driver_an"
	if id == "A7_race2":
		state.tutorial["power_before"] = state.team_power()
		state.buy("engine")
		state._start_race()
	if id == "A6_result":
		state._start_race()
		var guard := 0
		while state.phase == "racing" and guard < 2000:
			state.advance(0.5)
			guard += 1
	main.activate()
	main._overlay.hide()
	var tab: String = lesson.get("tab", "race")
	main._select_tab({"race": main.Tab.RACE, "any": main.Tab.RACE, "shop": main.Tab.SHOP, "bag": main.Tab.BAG, "team": main.Tab.TEAM, "garage": main.Tab.TEAM, "league": main.Tab.LEAGUE}.get(tab, main.Tab.RACE))
	if tab == "garage":
		main._select_team_sub(1)
	for i in range(8):
		await process_frame
	var tut = main._tutorial
	if not tut.start_lesson(id):
		push_error("Tutorial fixture does not satisfy entry conditions: " + id)
		quit(1)
		return
	if id == "A6_result":
		main._show_race_result(state.last_result)
	state.active = true
	root.title = "Racing Manager — Tutorial " + id
	if "--capture-lesson" in OS.get_cmdline_user_args() or "--check-lesson" in OS.get_cmdline_user_args():
		for i in range(12):
			await process_frame
		if not tut._panel.visible:
			push_error("Tutorial did not show: " + id)
			quit(1)
			return
		if "--capture-lesson" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/tutorial_lesson_%s.png" % id)
		print("Previewed lesson: " + id)
		main.queue_free()
		await process_frame
		quit()


func capture_income(main: Control, state: Node) -> void:
	main.set_process(false)
	var tut = main._tutorial
	tut.set_process(false)
	var failures := 0
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		state.init_new_game()
		state.active = false
		main._refresh()
		main._sync_sim()
		tut.start_lesson("A3_income")
		tut.blocked = false
		tut._process(Tutorial.RUN_BEFORE_A3_SEC)
		for stage in range(4):
			for i in range(10):
				tut._process(0.01)
				await process_frame
			await RenderingServer.frame_post_draw
			var panel: Rect2 = tut._panel.get_rect()
			if panel.position.y < 0 or panel.end.y > root.size.y + 1:
				failures += 1
			root.get_texture().get_image().save_png("res://Design/Previews/tutorial_income_%d_%d.png" % [width, stage])
			if stage == 2:
				if not state.buy("ticket"):
					failures += 1
			else:
				tut._on_primary()
				if stage in [1, 3]:
					tut._on_primary()
		if tut.running:
			failures += 1
	print("tutorial_income_preview: %d failures" % failures)
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)


func capture_trophy(main: Control, state: Node) -> void:
	main.set_process(false)
	var tut = main._tutorial
	tut.set_process(false)
	var failures := 0
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		state.init_new_game()
		state.active = false
		state.completed_races = 2
		state.trophies = 1
		state.trophies_earned = 1
		state.tutorial = {"state": "done", "step": "", "gated": true, "tips_off": true}
		main._select_tab(main.Tab.LEAGUE)
		main._refresh()
		for i in range(8):
			await process_frame
		tut.start_lesson("U2_league")
		tut.blocked = false
		tut._process(0.01)
		tut._on_primary()
		for stage in ["buy", "result"]:
			for i in range(10):
				tut._process(0.01)
				await process_frame
			await RenderingServer.frame_post_draw
			var panel: Rect2 = tut._panel.get_rect()
			if panel.position.y < 0 or panel.end.y > root.size.y + 1:
				failures += 1
			root.get_texture().get_image().save_png("res://Design/Previews/tutorial_trophy_%d_%s.png" % [width, stage])
			if stage == "buy":
				var button := main.find_child("Buy_speed_tune", true, false) as Button
				button.pressed.emit()
		tut._on_primary()
		if tut.intro != "" or state.trophy_level("speed_tune") != 1 or state.trophies != 0:
			failures += 1
	print("tutorial_trophy_preview: %d failures" % failures)
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)


## Exercise automatic activation while the player starts on another tab.
func preview_route(main: Control, state: Node, id: String, source: String) -> void:
	if Tutorial.feature(id).is_empty():
		push_error("Navigation preview requires a feature lesson: " + id)
		quit(1)
		return
	state.tutorial = {"state": "done", "step": "", "gated": true, "tips_off": true}
	state.completed_races = 10
	state.trophies = 1
	state.trophies_earned = 1
	state.gear_coupons["standard"] = 1
	state.driver_coupons["pro"] = 1
	for feature: Dictionary in Tutorial.features():
		if feature["id"] != id:
			state.complete_lesson(feature["id"])
	main.activate()
	main._overlay.hide()
	main._select_team_sub(0)
	main._select_tab({"race": main.Tab.RACE, "shop": main.Tab.SHOP, "bag": main.Tab.BAG, "team": main.Tab.TEAM, "league": main.Tab.LEAGUE}.get(source, main.Tab.SHOP))
	state.active = true
	root.title = "Racing Manager — Dẫn tới tutorial " + id
	if "--capture-route" in OS.get_cmdline_user_args():
		for i in range(12):
			await process_frame
		main._tutorial._on_primary()
		for i in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/tutorial_route_%s_tab.png" % id)
		if id == "U6_garage":
			main._select_tab(main.Tab.TEAM)
			for i in range(8):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/tutorial_route_%s_subtab.png" % id)
		print("Previewed automatic route: " + id)
		main.queue_free()
		await process_frame
		quit()
