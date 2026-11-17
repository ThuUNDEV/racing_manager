extends SceneTree
## Trophy lesson: eligibility, real purchase, migration and save/resume.
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("  ok   " if ok else "  FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in range(8):
		await process_frame


func build_main():
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "trophy-lesson-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	main._tutorial.set_process(false)
	return main


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_trophy_lesson_test.json"
	state.BAK_PATH = "user://tutorial_trophy_lesson_test.bak"
	state.TMP_PATH = "user://tutorial_trophy_lesson_test.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.completed_races = 2
	state.tutorial = {"state": "done", "step": "", "gated": true, "tips_off": true, "intro_seen": ["U2_league"], "lessons": {"U2_league": {"status": "done", "sub": 0, "page": 0}}}
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = await build_main()
	main._select_tab(main.Tab.LEAGUE)
	main._pump_intro()
	var tut = main._tutorial
	check(not Tutorial.intro_seen(state, "U2_league"), "old text-only intro does not suppress the practical lesson")
	check(tut.intro == "" and not tut.wants_pause(), "no trophies: do not start an impossible exercise")
	state.trophies = 1
	main._refresh()
	main._set_trophy_group("defense")
	main._pump_intro()
	check(tut.intro == "U2_league", "one earned trophy makes the lesson eligible")
	tut.blocked = false
	tut._process(0.1)
	await settle()
	tut._process(0.1)
	check(main._trophy_group == "offense" and not tut._hand.visible and tut._primary.visible, "show the right upgrade group and explain the purpose first")
	tut._on_primary()
	check(tut._hand.visible and not tut._primary.visible and tut._block_mode() == "hole", "point to the actual trophy purchase button")
	tut._on_primary()
	check(tut.intro_sub == 0 and state.trophy_level("speed_tune") == 0, "Next cannot replace the purchase")
	state.simulate_write_failure = true
	check(not state.buy_trophy_upgrade("speed_tune"), "failed purchase save returns failure")
	state.simulate_write_failure = false
	tut._process(0.1)
	check(tut.intro_sub == 0 and state.trophies == 1, "failed purchase keeps both the exercise and trophy")
	var button := main.find_child("Buy_speed_tune", true, false) as Button
	check(button != null and not button.disabled, "the highlighted button is enabled")
	button.pressed.emit()
	check(state.trophy_level("speed_tune") == 1 and state.trophies == 0, "clicking the button buys exactly one real upgrade")
	# Reopen immediately after purchase, before the overlay changes stages.
	main.queue_free()
	await settle()
	state.init_new_game()
	state.active = false
	check(state.load_game() == "ok", "reload after the purchase transaction")
	check(not Tutorial.intro_seen(state, "U2_league"), "the active v2 lesson is not skipped by the old seen flag")
	main = await build_main()
	main._select_tab(main.Tab.LEAGUE)
	await settle()
	main._pump_intro()
	tut = main._tutorial
	tut.blocked = false
	tut._process(0.1)
	await settle()
	tut._process(0.1)
	check(tut.intro_sub == 1 and tut._text.text.contains("+0 → +1"), "resume at the actual stat change without buying again")
	check(not tut._hand.visible and tut._primary.visible and tut._block_mode() == "", "reward stage has acknowledgement, no purchase hand or input trap")
	var level := main.find_child("TrophyLevel_speed_tune", true, false) as Control
	check(level != null and (tut._target["rect"] as Rect2).is_equal_approx(level.get_global_rect()), "highlight the new upgrade level instead of another purchase")
	tut._on_primary()
	check(tut.intro == "" and Tutorial.intro_seen(state, "U2_league") and int(state.tutorial["lessons"]["U2_league"]["script_version"]) == 2, "acknowledgement completes the current practical lesson")
	state.tutorial = {"state": "done", "step": "", "intro_seen": ["U2_league"]}
	check(Tutorial.intro_seen(state, "U2_league"), "experienced old saves with a real trophy upgrade are not forced to buy again")
	main.queue_free()
	await settle()
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_trophy_lesson_test: %d failures" % failures)
	quit(1 if failures else 0)
