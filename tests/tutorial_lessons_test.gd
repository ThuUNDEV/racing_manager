extends SceneTree
## Independent lesson definitions, checkpoints, real actions and legacy progress.
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("  ok   " if ok else "  FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in range(6):
		await process_frame


func build_main():
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "lesson-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	main._tutorial.set_process(false)
	return main


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_lessons_test.json"
	state.BAK_PATH = "user://tutorial_lessons_test.bak"
	state.TMP_PATH = "user://tutorial_lessons_test.tmp"
	GameData.reload()
	Tutorial.reload()
	check(Tutorial.validate().is_empty(), "all lesson definitions are valid")
	check(Tutorial.Catalog.group("onboarding").size() == 6 and Tutorial.features().size() == 6 and Tutorial.tips().size() == 5, "six onboarding lessons, six feature lessons and five contextual tips")
	for group in ["onboarding", "features", "tips"]:
		for item: Dictionary in Tutorial.Catalog.group(group):
			check(FileAccess.file_exists(item["source"]) and not String(item["purpose"]).is_empty(), "%s owns its source and purpose" % item["id"])
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	state.init_new_game()
	state.active = false
	state.completed_races = 3
	state.tutorial = {"state": "done", "step": "", "gated": true}
	state.gear_coupons["standard"] = 1
	var main = await build_main()
	main._select_tab(main.Tab.SHOP)
	await settle()
	var tut = main._tutorial
	check(tut.start_lesson("U4_shop"), "start the gear-pack lesson independently")
	tut.blocked = false
	tut._process(0.1)
	check(not Tutorial.intro_seen(state, "U4_shop") and Tutorial.lesson_progress("U4_shop", state)["status"] == "active", "showing the purpose does not complete the lesson")
	tut._on_primary()
	check(tut._page == 1 and tut._hand.visible, "read the purpose before the action")
	check(state.save_game(), "save an active lesson checkpoint")
	main.queue_free()
	await settle()
	state.init_new_game()
	state.active = false
	check(state.load_game() == "ok", "reload the checkpoint")
	main = await build_main()
	main._select_tab(main.Tab.SHOP)
	await settle()
	tut = main._tutorial
	check(tut.show_intro("U4_shop"), "resume only the pending gear lesson")
	tut.blocked = false
	tut._process(0.1)
	check(tut.intro_sub == 0 and tut._page == 1 and tut._hand.visible, "resume at the action without replaying the purpose")
	var gems_before: int = state.gems
	check(not state.open_gear_pack("standard", 1).is_empty(), "perform the actual coupon purchase")
	tut._process(0.1)
	check(tut.intro_sub == 1 and tut._target.is_empty() and not tut._hand.visible and state.gems == gems_before, "completion explains the reward without asking for another purchase")
	check(not Tutorial.intro_seen(state, "U4_shop") and state.save_game(), "reward explanation is still a pending checkpoint")
	main.queue_free()
	await settle()
	state.init_new_game()
	state.active = false
	check(state.load_game() == "ok", "reload after opening the pack")
	main = await build_main()
	main._select_tab(main.Tab.SHOP)
	await settle()
	tut = main._tutorial
	tut.show_intro("U4_shop")
	tut.blocked = false
	tut._process(0.1)
	check(tut.intro_sub == 1 and tut._target.is_empty() and int(state.gear_coupons["standard"]) == 0, "resume the reward explanation without spending again")
	tut._on_primary()
	check(Tutorial.intro_seen(state, "U4_shop") and Tutorial.lesson_progress("U4_shop", state)["status"] == "done", "acknowledgement completes only the gear lesson")
	check(Tutorial.lesson_progress("U5_drivers", state)["status"] == "new", "driver recruitment remains independent")
	check(tut.start_lesson("A3_income"), "preview just the income lesson")
	tut._process(0.1)
	tut._on_primary()
	tut._process(0.1)
	tut._on_primary()
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 2 and state.buy("ticket"), "income preview requires a real revenue purchase")
	tut._process(0.1)
	tut._on_primary()
	tut._on_primary()
	check(not tut.running and Tutorial.lesson_progress("A3_income", state)["status"] == "done", "one-lesson preview stops without starting the engine tutorial")
	state.tutorial = {"state": "active", "step": "A4_engine", "intro_seen": ["U2_league"]}
	check(Tutorial.lesson_progress("A3_income", state)["status"] == "done" and not Tutorial.intro_seen(state, "U2_league"), "legacy onboarding is preserved while the old text-only trophy intro remains eligible for the practical lesson")
	state.tutorial = {"state": "active", "step": "A3_income", "lessons": {"A3_income": {"status": "done"}}}
	check(Tutorial.resume_step(state) == "A4_engine", "completed checkpoint advances even if the old scheduler pointer was saved")
	state.tutorial["lessons"]["U4_shop"] = {"status": "done"}
	check(Tutorial.intro_seen(state, "U4_shop"), "completion checkpoint prevents replay before the legacy seen flag is written")
	var cleaned: Dictionary = state._clean_lesson_progress({"U4_shop": {"status": "active", "sub": 999, "page": 999}, "unknown": {"status": "done"}})
	check(not cleaned.has("unknown") and cleaned["U4_shop"]["sub"] == 0 and cleaned["U4_shop"]["page"] == 1, "unknown lessons are ignored and obsolete stages are clamped")
	var bad: Dictionary = state._save_data()
	bad["tutorial"]["lessons"] = {"U4_shop": {"status": "active", "page": "bad"}}
	check(not state.save_game(bad), "reject a malformed lesson checkpoint")
	main.queue_free()
	await settle()
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_lessons_test: %d failures" % failures)
	quit(1 if failures else 0)
