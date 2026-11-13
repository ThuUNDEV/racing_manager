extends SceneTree
var failures := 0

func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	GameData.reload()
	var state := root.get_node("GameState")
	state.init_new_game()
	state.save_blocked = true
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 8:
		await process_frame
	main._auto_race = true
	main._music_on = false
	main._sfx_on = false
	for screen in ["race", "profile", "settings", "shop"]:
		main._profile.hide()
		main._overlay.hide()
		main._select_tab(0)
		if screen == "profile":
			main._show_profile()
		elif screen == "settings":
			main._show_settings()
		elif screen == "shop":
			main._select_tab(4)
		main._on_race_finished({})
		var flash: Node2D = main._race_view.get_child(0)
		check(flash.name == "FinishFlash", "Flash belongs to race view on " + screen)
		check(main._race_view.clip_contents and flash.z_index == 0, "Flash clipped without global Z override on " + screen)
		check(flash.get_index() < main._result_panel.get_index(), "Result panel draws above flash on " + screen)
		check(flash.position.is_equal_approx(main._race_view.size * 0.5), "Flash uses race-local coordinates on " + screen)
		if screen == "shop":
			check(not flash.is_visible_in_tree(), "Hidden race also hides flash")
		flash.free()
	main.queue_free()
	for i in 8:
		await process_frame
	quit(1 if failures else 0)
