extends SceneTree
var failures := 0
var main: Control
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in 6:
		await process_frame
func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1
func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = down
	Input.parse_input_event(event)
func swipe(at: Vector2, direction: float = -1.0) -> void:
	touch(at, true)
	await process_frame
	for i in 8:
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = at + Vector2(0, direction * 12 * (i + 1))
		event.relative = Vector2(0, direction * 12)
		event.velocity = Vector2(0, direction * 240)
		Input.parse_input_event(event)
		await process_frame
	touch(at + Vector2(0, direction * 96), false)
	await settle()
func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.gems = 500
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	for width in [320, 390]:
		root.size = Vector2i(width, 844)
		await settle()
		for tab in [1, 2]:
			main._select_tab(tab)
			if tab == 2:
				main._select_team_sub(0)
			await settle()
			var sc: ScrollContainer = main._pages[tab]
			sc.scroll_vertical = 0
			await settle()
			var button: Button = main.find_child("Open_standard_x1" if tab == 1 else "DriverOpen_pro_x1", true, false)
			var gems: int = state.gems
			await swipe(button.get_global_rect().get_center())
			check(sc.scroll_vertical > 24, "finger swipe starting on pack button scrolls tab %d (%d)" % [tab, sc.scroll_vertical])
			check(state.gems == gems and not main._overlay.visible, "swipe does not open a pack")
			var before := sc.scroll_vertical
			await swipe(sc.get_global_rect().position + Vector2(60, 50), 1.0)
			check(sc.scroll_vertical < before, "finger swipe down reverses scroll")
	main._select_tab(2)
	main._select_team_sub(0)
	var sc: ScrollContainer = main._pages[2]
	sc._stop_scroll()
	sc.scroll_vertical = 0
	await settle()
	var info: Button = main.find_child("DriverInfo_pro", true, false)
	var position := info.get_global_rect().get_center()
	touch(position, true)
	await process_frame
	touch(position, false)
	await settle()
	check(main._overlay.visible, "short finger tap still opens pack information")
	var modal := main._overlay_box.get_parent() as ScrollContainer
	var page_before := sc.scroll_vertical
	if modal.get_v_scroll_bar().max_value > modal.get_v_scroll_bar().page:
		await swipe(modal.get_global_rect().get_center())
		check(modal.scroll_vertical > 0, "finger swipe scrolls pack information dialog")
	check(sc.scroll_vertical == page_before, "dialog gesture does not scroll page behind it")
	main._overlay.hide()
	# A real tap on a purchase button still opens exactly one pack.
	main._select_tab(1)
	var bag: ScrollContainer = main._pages[1]
	bag._stop_scroll()
	bag.scroll_vertical = 0
	await settle()
	var purchase: Button = main.find_child("Open_standard_x1", true, false)
	var gems_before: int = state.gems
	var count_before: int = state.gear_open_count
	var at := purchase.get_global_rect().get_center()
	touch(at, true)
	await process_frame
	touch(at, false)
	await settle()
	check(state.gems == gems_before - 10 and state.gear_open_count == count_before + 1, "finger tap buys exactly one gear pack")
	main.queue_free()
	await settle()
	print("TOUCH_SCROLL_TEST failures=", failures)
	quit(1 if failures else 0)
