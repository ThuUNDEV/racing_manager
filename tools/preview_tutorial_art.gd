extends SceneTree
## Native preview, isolated from the player's save. Run with --script res://tools/preview_tutorial_art.gd.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var output_dir := "res://Design/Previews"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
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
	var failures := 0
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		for i in range(8):
			await process_frame
		for expression in ["smile", "point", "excited", "confirm", "unlock", "hand", "tab"]:
			tut.intro = ""
			tut.nav = ""
			tut.running = true
			tut._enter("A1_welcome" if expression == "smile" else "A4_engine")
			if expression == "unlock":
				tut.running = false
				tut.intro = "U2_league"
			if expression == "tab":
				tut.running = false
				tut.nav = "U3_bag"
				tut._nav_force = true
				tut._page = 1
			if expression == "confirm":
				tut._on_skip()
			if expression == "excited":
				tut.sub = 1
			for i in range(5):
				if expression == "unlock" or expression == "tab":
					tut._set_shown(true)
					tut._update_view()
					tut.queue_redraw()
				elif expression == "hand":
					tut._process(0.01)
					if tut._target.has("rect"):
						tut._target["hand"] = (tut._target["rect"] as Rect2).get_center()
						tut._place_panel()
				else:
					tut._process(0.01)
				await process_frame
			await RenderingServer.frame_post_draw
			var screen := Rect2(Vector2.ZERO, Vector2(root.size))
			for node: Control in [tut._panel, tut._portrait, tut._text, tut._progress]:
				if not screen.encloses(node.get_global_rect()):
					push_error("Tutorial outside viewport: %s at %d/%s" % [node.name, width, expression])
					failures += 1
			root.get_texture().get_image().save_png(output_dir.path_join("tutorial_linh_%d_%s.png" % [width, expression]))
	main.queue_free()
	await process_frame
	print("tutorial_art_preview: %d layout failures" % failures)
	quit(1 if failures else 0)
