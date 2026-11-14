extends SceneTree
## Integration coverage for live button faces, resize caps, palettes and purchase states.
const PopupAnim = preload("res://ui/popup_anim.gd")
var failures := 0
var checked := 0
var main: Control


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)


func settle() -> void:
	for frame in 8:
		await process_frame


func verify_visible_buttons(tag: String) -> void:
	for node in main.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree():
			continue
		var face := button.get_theme_stylebox("normal")
		# Transparent hit targets (HUD links, avatars and item cards) have no face.
		if face is StyleBoxEmpty or (face is StyleBoxFlat and face.bg_color.a == 0):
			continue
		if button.name.begins_with("ShopNav_"):
			for child in button.get_children():
				if child is TextureRect:
					check(button.get_global_rect().encloses(child.get_global_rect()), "Shop navigation icon fits button")
		for state: String in HdUi.ButtonSkin.STATES:
			var skin := button.get_theme_stylebox(state)
			check(skin.has_meta("rounded_button"), "%s %s %s shares the face" % [tag, button.get_path(), state])
			if skin is StyleBoxTexture and skin.has_meta("rounded_button"):
				var height: float = button.size.y + skin.expand_margin_top + skin.expand_margin_bottom
				check(skin.texture_margin_top + skin.texture_margin_bottom <= height + 1, "caps fit " + str(button.get_path()))
		checked += 1


func shot(tag: String) -> void:
	if not "--shots" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("BUTTON_PREVIEW_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory.path_join("buttons_%d_%s.png" % [root.size.x, tag]))


func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "isolated save")
	PopupAnim.enabled = false
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.completed_races = 5
	state.coins = BigNumber.from_int(1000000)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_factor = 1.0
	root.size = Vector2i(390, 844)
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for tab in [main.Tab.RACE, main.Tab.BAG, main.Tab.TEAM, main.Tab.LEAGUE, main.Tab.SHOP]:
			main._select_tab(tab)
			await settle()
			verify_visible_buttons("tab %d at %d" % [tab, width])
			await shot("tab_%d" % tab)
		main._show_settings()
		await settle()
		verify_visible_buttons("settings")
		main._show_language_picker()
		await settle()
		verify_visible_buttons("language")
		await shot("language")
		main._overlay.hide()
		main._select_tab(main.Tab.RACE)
		main._profile.open()
		await settle()
		verify_visible_buttons("profile")
		await shot("profile")
		main._profile._close()
		main._show_daily_rewards()
		await settle()
		verify_visible_buttons("daily")
		await shot("daily")
		main._overlay.hide()
		main._show_iap_detail("starter_1")
		await settle()
		verify_visible_buttons("IAP")
		await shot("iap")
		main._overlay.hide()
	main._select_tab(main.Tab.RACE)
	state.coins = BigNumber.zero()
	main._refresh_rows()
	check(main._rows[0]["btn"].disabled, "unaffordable upgrade remains disabled")
	state.coins = BigNumber.from_int(1000000)
	main._refresh_rows()
	check(not main._rows[0]["btn"].disabled, "affordable upgrade remains enabled")
	var upgrade: StyleBoxTexture = main._rows[0]["btn"].get_theme_stylebox("normal")
	var green: Color = upgrade.get_meta("rounded_palette")[0]
	check(green.g > green.r and green.g > green.b, "upgrade remains green")
	var profile_button: Button = main._profile._button("Close", func(): pass, true, true)
	var orange: Color = profile_button.get_theme_stylebox("normal").get_meta("rounded_palette")[0]
	check(orange.is_equal_approx(Color("d66a00")), "profile orange stays unchanged")
	profile_button.free()
	main.queue_free()
	await settle()
	print("BUTTON_SKIN_UI_TEST checked=", checked, " failures=", failures)
	quit(1 if failures else 0)
