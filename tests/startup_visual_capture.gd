extends SceneTree
## Capture the actual splash -> BootFlow -> loading at native logical mobile sizes.
## Use --screen 1 --audio-driver Dummy and an isolated XDG_DATA_HOME.

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var dimensions := Vector2i(390, 844)
	var prefix := "res://Design/Previews/Startup_Flare_v2/390x844"
	for arg in OS.get_cmdline_user_args():
		if arg == "--small":
			dimensions = Vector2i(320, 568)
			prefix = "res://Design/Previews/Startup_Flare_v2/320x568"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = dimensions
	change_scene_to_file("res://scenes/splash.tscn")
	await create_timer(0.85).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(prefix + "_splash.png")
	var frames := 0
	while not root.get_node("GameState").active and frames < 1800:
		await process_frame
		frames += 1
	if not root.get_node("GameState").active:
		push_error("Startup capture did not reach gameplay")
		quit(1)
		return
	# Let the real loading fade finish before checking its exceptional layouts separately.
	await create_timer(0.3).timeout
	# Render the production UI builders, without running another BootFlow or modifying saves.
	var ui := Node.new()
	root.add_child(ui)
	ui.set_script(load("res://ui/loading.gd"))
	ui.set_process(false)
	ui.call("_build_ui")
	ui.set("_shown", 0.6)
	ui.call("_update_bar")
	ui.call("_on_status", "Đang tải đường đua…")
	await _shot(prefix + "_layout.png")
	ui.get("_slow_note").show()
	ui.get("_stall_retry").show()
	ui.get("_progress_card").anchor_top = 0.67
	await _shot(prefix + "_slow_retry.png")
	ui.call("_on_failed", "BOOT_SAVE", "Không thể đọc tiến trình đã lưu. Hãy thử lại.")
	await _shot(prefix + "_error.png")
	print("PASS startup visual capture ", dimensions)
	quit(0)


func _shot(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
