extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var gs := root.get_node("GameState")
	assert(gs.SAVE_PATH.contains("/tests/"))
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["gated"] = false
	gs.tutorial["state"] = "done"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.TEAM)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for selected in [0, 1]:
			main._select_team_sub(selected)
			for frame in 8:
				await process_frame
			var a: Button = main._team_sub_buttons[0]
			var b: Button = main._team_sub_buttons[1]
			assert(absf(a.size.x - b.size.x) <= 1.0)
			assert(a.size.y >= 44 and b.size.y >= 44)
			assert(a.button_pressed == (selected == 0))
			assert(b.button_pressed == (selected == 1))
			assert(main._garage.visible == (selected == 1))
			assert(b.get_global_rect().end.x <= width)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.save_png("res://Design/Previews/team_tabs_%d_%d.png" % [width, selected])
			if width == 390:
				var rect: Rect2 = a.get_parent().get_parent().get_global_rect()
				image.get_region(Rect2i(rect)).save_png("res://Design/Previews/team_tabs_detail_%d.png" % selected)
			print("PASS team tabs ", width, " selected=", selected)
	main.queue_free()
	await process_frame
	quit()
