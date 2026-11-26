extends SceneTree
## Feature tutorials activate from any tab and own their complete navigation route.
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


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_navigation_test.json"
	state.BAK_PATH = "user://tutorial_navigation_test.bak"
	state.TMP_PATH = "user://tutorial_navigation_test.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "navigation-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._active = true
	main._shot_prefix = ""
	var tut = main._tutorial
	tut.set_process(false)
	var scenarios := [
		["U2_league", main.Tab.SHOP, main.Tab.LEAGUE],
		["U4_shop", main.Tab.BAG, main.Tab.SHOP],
		["U3_bag", main.Tab.SHOP, main.Tab.BAG],
		["U5_drivers", main.Tab.LEAGUE, main.Tab.SHOP],
		["U7_class", main.Tab.BAG, main.Tab.RACE],
	]
	for scenario in scenarios:
		var id := String(scenario[0])
		tut.nav = ""
		tut.intro = ""
		tut.running = false
		tut.tip_mode = false
		tut._explained_nav.clear()
		tut._set_shown(false)
		state.init_new_game()
		state.active = false
		state.completed_races = 10
		state.trophies = 1
		state.tutorial = {"state": "done", "step": "", "gated": true, "tips_off": true, "nav_seen": [id]}
		for feature: Dictionary in Tutorial.features():
			if feature["id"] != id:
				state.complete_lesson(feature["id"])
		main._select_team_sub(0)
		main._select_tab(scenario[1])
		main._overlay.hide()
		main._class_page.hide()
		main._result_panel.hide()
		main._refresh()
		await settle()
		main._overlay.show()
		main._process(0.01)
		check(tut.nav == "" and tut.intro == "", id + ": modal defers activation")
		main._overlay.hide()
		main._process(0.01)
		tut._process(0.01)
		check(tut.nav == id and tut._panel.visible and tut._nav_force and not tut.blocked, id + ": guides from a non-race tab despite an old nav_seen flag")
		check(main._tab == scenario[1], id + ": player performs the tab change")
		tut._on_primary()
		check(tut._hand.visible and not tut._primary.visible and tut._block_mode() == "hole", id + ": navigation points to an actionable tab")
		tut._on_primary()
		check(tut.nav == id, id + ": Next cannot dismiss an unfinished forced route")
		var wrong = main.Tab.BAG if scenario[2] == main.Tab.SHOP else main.Tab.SHOP
		main._select_tab(wrong)
		main._sync_tutorial_nav()
		check(tut.nav == id, id + ": wrong tab does not finish navigation")
		main._select_tab(scenario[2])
		main._sync_tutorial_nav()
		main._process(0.01)
		tut._process(0.01)
		check(tut.nav == "" and tut.intro == id and tut._panel.visible, id + ": destination immediately starts the lesson")
		check(tut._page == 1, id + ": purpose is not repeated on arrival")
		main._select_tab(wrong)
		main._process(0.01)
		tut._process(0.01)
		check(tut.nav == id and tut.intro == "" and Tutorial.lesson_progress(id, state)["status"] == "active", id + ": leaving a pending lesson guides back without losing progress")
	main.queue_free()
	await settle()
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("tutorial_navigation_test: %d failures" % failures)
	quit(1 if failures else 0)
