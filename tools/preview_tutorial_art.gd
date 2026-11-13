extends SceneTree
## Native preview, isolated from the player's save. Run with --script res://tools/preview_tutorial_art.gd.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tutorial_art_preview.json"
	state.BAK_PATH = "user://tutorial_art_preview.bak"
	state.TMP_PATH = "user://tutorial_art_preview.tmp"
	state.init_new_game()
	state.active = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var main = load("res://ui/main.gd").new()
	main._shot_prefix = "tutorial-art-preview"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(5):
		await process_frame
	main.set_process(false)
	main._overlay.hide()
	var tut = main._tutorial
	tut.set_process(false)
	tut.start()
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for i in range(8):
			await process_frame
		for expression in ["smile", "point", "excited", "confirm", "unlock"]:
			tut.intro = ""
			tut.running = true
			tut._enter("A1_welcome" if expression == "smile" else "A4_engine")
			if expression == "unlock":
				tut.running = false
				tut.intro = "U2_league"
			if expression == "confirm":
				tut._on_skip()
			if expression == "excited":
				tut.sub = 1
			for i in range(5):
				if expression == "unlock":
					tut._set_shown(true)
					tut._update_view()
					tut.queue_redraw()
				else:
					tut._process(0.01)
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/tutorial_linh_%d_%s.png" % [width, expression])
	main.queue_free()
	await process_frame
	quit()
