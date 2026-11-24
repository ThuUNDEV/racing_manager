extends SceneTree
## Income tutorial: a real upgrade, insufficient funds, failed saves and resumption.
const BigNumber = preload("res://core/math/big_number.gd")
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
	main._shot_prefix = "income-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._overlay.hide()
	main._tutorial.set_process(false)
	return main


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_income_test.json"
	state.BAK_PATH = "user://tutorial_income_test.bak"
	state.TMP_PATH = "user://tutorial_income_test.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.levels["ticket"] = 2  # Existing upgrades must not bypass the exercise.
	state.income_boost_left = 30.0
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = await build_main()
	var tut = main._tutorial
	check(tut.start_lesson("A3_income"), "start income lesson independently")
	tut.blocked = false
	tut._process(Tutorial.RUN_BEFORE_A3_SEC)
	tut._process(0.1)
	var before := Balance.fmt_rate(state.total_online_rate().multiply_ratio(state.income_multiplier(), 1))
	check(tut._text.text.contains(before) and not Tutorial.action_done("A3_income", state), "show actual boosted income, require another purchase even when ticket is already upgraded")
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 1 and tut._target.has("rect"), "point to Revenue before explaining its modifiers")
	await settle()
	tut._process(0.1)
	var revenue_view: Rect2 = main._upgrade_scroll.get_global_rect()
	for kind: String in Balance.REVENUE:
		var tile: Control = main._row_of(kind)["tile"]
		check(revenue_view.encloses(tile.get_global_rect()), "Giới thiệu Thu nhập: ô %s hiện trọn trong vùng cuộn" % kind)
		check(not tut._panel.get_global_rect().intersects(tile.get_global_rect()), "Thoại không che ô nâng cấp %s" % kind)
	tut._on_primary()
	tut._on_primary()
	tut._process(0.1)
	check(tut.sub == 2 and tut._hand.visible and not tut._primary.visible, "reach the real purchase step")
	state.coins = BigNumber.zero()
	tut._process(0.1)
	check(not tut._panel.visible and not tut.wants_pause(), "insufficient funds: hide the disabled action and allow earnings")
	tut._process(Tutorial.MONEY_WAIT_SEC + 0.1)
	check(tut.sub == 4 and tut._panel.visible and not tut.wants_pause(), "one waiting reminder does not pause earnings")
	tut._process(Tutorial.AFTER_SEC + 2.0)
	tut._process(0.1)
	check(tut.sub == 2 and not tut._panel.visible, "return to silent waiting")
	state.coins = BigNumber.from_int(10000)
	tut._process(0.1)
	check(tut._panel.visible and tut.wants_pause(), "resume the exercise when affordable")
	tut._on_primary()
	check(tut.sub == 2, "Next cannot complete the purchase step")
	state.simulate_write_failure = true
	check(not state.buy("ticket"), "failed purchase save reports failure")
	state.simulate_write_failure = false
	tut._process(0.1)
	check(tut.sub == 2 and not Tutorial.action_done("A3_income", state), "rolled-back purchase does not complete the exercise")
	check(state.buy("ticket"), "perform a successful revenue upgrade")
	var coins_after: Dictionary = state.coins.to_save()
	# The purchase transaction includes the checkpoint. Simulate quitting before overlay notices it.
	main.queue_free()
	await settle()
	state.init_new_game()
	state.active = false
	check(state.load_game() == "ok", "reload immediately after the successful purchase")
	main = await build_main()
	tut = main._tutorial
	check(tut.start(), "resume the saved onboarding lesson")
	tut.blocked = false
	tut._process(0.1)
	var after := Balance.fmt_rate(state.total_online_rate().multiply_ratio(state.income_multiplier(), 1))
	check(tut.step == "A3_income" and tut.sub == 3 and state.level_of("ticket") == 3, "resume at the observed result without another purchase")
	check(tut._text.text.contains(before + " → " + after) and before != after and state.coins.to_save() == coins_after, "compare real before/after rates and preserve the purchase balance")
	var pill := main.find_child("IncomePill", true, false) as Control
	check((tut._target["rect"] as Rect2).is_equal_approx(pill.get_global_rect()) and not tut._hand.visible, "show the changed income indicator instead of the purchase button")
	tut._on_primary()
	tut._on_primary()
	check(tut.step == "A6_result" and Tutorial.lesson_progress("A3_income", state)["status"] == "done", "complete only after the upgrade and result acknowledgement")
	main.queue_free()
	await settle()
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_income_test: %d failures" % failures)
	quit(1 if failures else 0)
