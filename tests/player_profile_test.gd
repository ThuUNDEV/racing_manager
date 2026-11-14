extends SceneTree
var failures := 0

func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func settle() -> void:
	for i in 10:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	check(state.SAVE_PATH.contains("/tests/"), "Save isolation")
	var starting_gems: int = state.gems
	check(state.set_player_team_name(state.player_team_name) and state.team_name_changes == 0, "Saving unchanged name preserves free change")
	check(state.set_player_team_name("  Đội Việt Nam  "), "Save trimmed Vietnamese name")
	check(state.gems == starting_gems and state.team_name_changes == 1, "First change is free")
	check(state.player_team_name == "Đội Việt Nam", "Name published after save")
	check(not state.set_player_team_name(" "), "Reject empty name")
	check(not state.set_player_team_name("A".repeat(25)), "Reject oversized name")
	check(not state.set_player_team_name("A\nB"), "Reject control characters")
	check(state.valid_team_name("a\u0301".repeat(24)), "Combining accents count as displayed characters")
	state.simulate_write_failure = true
	check(not state.set_player_team_name("Tên khác") and state.player_team_name == "Đội Việt Nam", "Failed save preserves published name")
	check(state.gems == starting_gems and state.team_name_changes == 1, "Failed paid save preserves gems and change count")
	state.simulate_write_failure = false
	state.player_team_name = "Temporary"
	check(state.load_game() == "ok" and state.player_team_name == "Đội Việt Nam", "Name survives reload")
	check(state.team_name_change_cost() == 50, "Reload preserves used free change")
	check(state.set_player_team_name("Đội Hai") and state.gems == starting_gems - 50, "Second change costs 50 gems")
	check(state.set_player_team_name("Đội Ba") and state.gems == starting_gems - 100, "Every subsequent change costs 50 gems")
	check(not state.set_player_team_name("Đội Bốn") and state.player_team_name == "Đội Ba" and state.team_name_changes == 3, "Insufficient gems preserve name and change count")
	check(state.set_player_team_name("  Đội Ba  ") and state.gems == 0 and state.team_name_changes == 3, "Unchanged trimmed name never costs gems")
	var legacy: Dictionary = state._save_data()
	legacy.erase("team_name_changes")
	state._apply(legacy)
	check(state.team_name_changes == 1 and state.team_name_change_cost() == 50, "Existing custom-name save has used free change")
	for key in ["player_team_name", "completed_races", "race_history_complete", "team_name_changes"]:
		legacy.erase(key)
	legacy["schema_version"] = 7
	state._apply(legacy)
	check(state.player_team_name == "Đội của bạn" and not state.race_history_complete, "Legacy defaults and partial history")
	check(state.team_name_changes == 0 and state.team_name_change_cost() == 0, "Untouched legacy profile keeps free change")
	state.init_new_game()
	state.begin_countdown()
	state.advance(3.1)
	state.simulate_write_failure = true
	var guard := 0
	while state.phase == "racing" and guard < 2000:
		state.advance(0.1)
		guard += 1
	check(state.phase == "save_error" and state.completed_races == 0, "Failed result save does not publish race count")
	state.simulate_write_failure = false
	check(state.retry_save() and state.completed_races == 1, "Retry publishes one completed race")
	check(not state.retry_save() and state.completed_races == 1, "Repeated retry cannot duplicate count")
	state.active = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var avatar: TextureRect = main._header_avatar.get_node("PlayerAvatarIcon")
	check(avatar.texture.get_width() >= 52 and avatar.texture.get_height() >= 52, "HUD avatar retains a readable texture")
	check(avatar.is_visible_in_tree() and avatar.size.x >= 44 and avatar.size.y >= 44, "HUD avatar has visible bounds")
	if "--profile-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/main_avatar_fixed.png")
	main._header_avatar.pressed.emit()
	await settle()
	var profile = main._profile
	check(profile.visible, "Avatar opens profile")
	for dimensions in [Vector2i(320, 568), Vector2i(360, 800), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = dimensions
		await settle()
		var popup_rect: Rect2 = profile._popup.get_global_rect()
		check(popup_rect.position.x >= 15 and popup_rect.end.x <= dimensions.x - 15, "Popup has side gutters %s" % dimensions)
		check(popup_rect.position.y >= 31 and popup_rect.end.y <= dimensions.y - 31, "Popup has top and bottom gutters %s" % dimensions)
		check(popup_rect.get_center().is_equal_approx(Vector2(dimensions) * 0.5), "Popup centered %s" % dimensions)
		var footer: Button = profile.find_child("ProfileClose", true, false)
		check(footer.get_global_rect().end.y <= dimensions.y and footer.get_global_rect().size.y >= 44, "Footer fits %s" % dimensions)
		check(profile._scroll.get_h_scroll_bar().max_value <= profile._scroll.size.x + 1, "No horizontal overflow %s" % dimensions)
		var saved_name: String = state.player_team_name
		state.player_team_name = "W".repeat(24)
		profile.refresh()
		await settle()
		check(profile._scroll.get_h_scroll_bar().max_value <= profile._scroll.size.x + 1, "Long name wraps %s" % dimensions)
		state.player_team_name = saved_name
		profile.refresh()
		await settle()
		if "--profile-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/profile_native_%d.png" % dimensions.x)
	profile._show_edit()
	await settle()
	if "--profile-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/profile_native_edit.png")
	profile._name_input.text = ""
	profile._save_name()
	check(profile._dialog.visible and not profile._error.text.is_empty(), "Invalid edit stays open with error")
	state.simulate_write_failure = true
	profile._name_input.text = "Đội Mới"
	profile._update_rename_cost()
	check(profile._rename_save.text == "Miễn phí", "Editor labels free first change")
	profile._save_name()
	check(profile._dialog.visible and state.player_team_name != "Đội Mới", "Save failure keeps editor open")
	state.simulate_write_failure = false
	profile._save_name()
	check(not profile._dialog.visible and state.player_team_name == "Đội Mới", "Valid editor saves real profile")
	profile._show_edit()
	profile._name_input.text = "Đội Có Phí"
	profile._update_rename_cost()
	check(profile._rename_save.text == "Đổi · 50 gem", "Editor discloses paid change before submission")
	if "--profile-shots" in OS.get_cmdline_user_args():
		root.size = Vector2i(320, 568)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/profile_rename_paid_320.png")
	state.gems = 49
	profile._save_name()
	check(profile._dialog.visible and profile._error.text.contains("Không đủ gem") and state.gems == 49, "Editor explains insufficient gems without charging")
	profile._dialog.hide()
	check(profile.find_child("ProfileSettings", true, false) == null, "Profile has no settings button")
	profile.find_child("ProfileClose", true, false).pressed.emit()
	check(not profile.visible, "Close returns to previous page")
	main.queue_free()
	await settle()
	quit(1 if failures else 0)
