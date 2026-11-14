extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	print("PASS " if value else "FAIL ", message)
	if not value:
		failures += 1


func settle() -> void:
	for frame in 10:
		await process_frame


func run() -> void:
	var gs := root.get_node("GameState")
	assert(gs.SAVE_PATH.contains("/tests/"))
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["gated"] = false
	gs.tutorial["state"] = "done"
	gs.trophies = 3
	gs.trophies_earned = 3
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.LEAGUE)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for group in ["offense", "defense", "income"]:
			main._set_trophy_group(group)
			await settle()
			var box: Control = main._league_box
			check(box.get_combined_minimum_size().x <= box.size.x + 1, "%d %s fits page" % [width, group])
			var tabs: Array[Button] = []
			for id in ["offense", "defense", "income"]:
				var tab: Button = box.find_child("Group_" + id, true, false)
				tabs.append(tab)
				check(tab.size.y >= 44 and tab.button_pressed == (id == group), "%d %s tab %s state/touch target" % [width, group, id])
			check(absf(tabs[0].size.x - tabs[1].size.x) <= 1 and absf(tabs[1].size.x - tabs[2].size.x) <= 1, "tabs have equal widths")
			for data: Dictionary in GameData.trophy_upgrades():
				if data["group"] != group:
					continue
				var card: Control = box.find_child("Upgrade_" + String(data["id"]), true, false)
				var button: Button = card.find_child("Buy_" + String(data["id"]), true, false)
				if button != null:
					check(card.get_global_rect().encloses(button.get_global_rect()), "%d %s purchase button inside card" % [width, data["id"]])
				var segments: HBoxContainer = card.find_child("LevelSegments", true, false)
				check(segments.get_child_count() == int(data["max_level"]), "level segments match configured max")
			if "--league-shots" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://Design/Previews/league_redesign_%d_%s.png" % [width, group])
	# Check all upgraded / unlocked content and translated strings at the narrow width.
	root.size = Vector2i(320, 844)
	gs.business_tier = 5
	gs.trophies = 420
	gs.trophies_earned = 420
	for data: Dictionary in GameData.trophy_upgrades():
		gs.trophy_levels[data["id"]] = int(data["max_level"])
	for language: String in I18n.codes():
		I18n.set_lang(language)
		GameData.reload()
		for group in ["offense", "defense", "income"]:
			main._set_trophy_group(group)
			await settle()
			check(main._league_box.get_combined_minimum_size().x <= main._league_box.size.x + 1, "320 %s %s maxed and capped fits" % [language, group])
	I18n.set_lang("vi")
	GameData.reload()
	main.queue_free()
	await process_frame
	print("LEAGUE_REDESIGN_TEST failures=%d" % failures)
	quit(0 if failures == 0 else 1)
