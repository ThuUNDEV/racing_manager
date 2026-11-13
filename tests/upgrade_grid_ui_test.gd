extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in range(8):
		await process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print("OK " if ok else "FAIL ", message)
func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.save_blocked = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "grid-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._overlay.hide()
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		for id in ["CarUpgradeGrid", "RevenueUpgradeGrid"]:
			var grid = main.find_child(id, true, false)
			check(grid.columns == 2 and grid.get_child_count() == 4, "%s is 2x2" % id)
			check(grid.size.x <= main._pages[0].size.x + 1, "%s fits %d" % [id, width])
			for tile in grid.get_children():
				check(tile.get_global_rect().end.x <= width, "Tile fits viewport")
			for pair in [[0, 1], [2, 3]]:
				var left = grid.get_child(pair[0])
				var right = grid.get_child(pair[1])
				for field in ["level", "eff", "next", "btn"]:
					var controls: Array = []
					for entry in main._rows:
						if entry["tile"] == left or entry["tile"] == right:
							controls.append(entry[field])
					check(absf(controls[0].global_position.y - controls[1].global_position.y) < 1.0, "%s %s aligned at %d" % [id, field, width])
			var scroll = main._pages[0]
			scroll.scroll_vertical = int(grid.position.y) - 48
			await settle()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/upgrades_%d_%s.png" % [width, id])
	# Enable one affordable purchase without touching the user's save file.
	state.save_blocked = false
	state.coins = BigNumber.from_int(1000000)
	main._refresh_rows()
	check(not main._rows[0]["btn"].disabled, "Affordable upgrade enabled")
	state.coins = BigNumber.zero()
	main._refresh_rows()
	check(main._rows[0]["btn"].disabled, "Unaffordable upgrade disabled")
	state.save_blocked = true
	main.queue_free()
	await settle()
	print("GRID failures=", failures)
	quit(1 if failures else 0)
