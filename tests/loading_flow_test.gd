extends SceneTree
## Kiểm tra loading không bàn giao sớm, kể cả khi bật giảm chuyển động.

func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.reset_progress()  # đường dẫn save được cô lập theo tên test
	var loading: Node = load("res://scenes/loading.tscn").instantiate()
	loading.set("_reduce_motion", true)
	root.add_child(loading)
	var started := Time.get_ticks_msec()
	var saw_progress := false
	var saw_full := false
	while is_instance_valid(loading) and Time.get_ticks_msec() - started < 20000:
		var shown := float(loading.get("_shown"))
		if shown > 0.0 and shown < 1.0:
			saw_progress = true
		if shown == 1.0:
			saw_full = true
		if float(loading.get("_visible_time")) < 1.2 and (shown >= 1.0 or gs.active):
			push_error("Loading handed off before minimum visibility")
			quit(1)
			return
		await process_frame
	if is_instance_valid(loading) or not gs.active or not saw_progress or not saw_full:
		push_error("Loading must show progress and 100% before activating gameplay")
		quit(1)
		return
	print("PASS loading -> progress -> 100% -> active gameplay; minimum visibility respected")
	gs.active = false
	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	await process_frame
	quit(0)
