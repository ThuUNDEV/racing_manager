extends SceneTree


func _initialize() -> void:
	await process_frame
	var entry: String = ProjectSettings.get_setting("application/run/main_scene")
	if entry != "res://scenes/splash.tscn":
		push_error("Splash must be the startup scene")
		quit(1)
		return
	change_scene_to_file(entry)
	await process_frame
	var splash := current_scene
	var logo: TextureRect = splash.get("_logo")
	var previous := logo.modulate.a
	var rose := false
	var peaked := false
	var fell := false
	var started := Time.get_ticks_msec()
	while is_instance_valid(splash) and Time.get_ticks_msec() - started < 10000:
		var alpha := logo.modulate.a
		rose = rose or (alpha > previous and alpha < 0.9)
		peaked = peaked or alpha >= 0.999
		fell = fell or (peaked and alpha < previous and alpha < 0.5)
		previous = alpha
		if root.get_node("GameState").active:
			push_error("Gameplay activated during splash")
			quit(1)
			return
		await process_frame
	await process_frame
	if not rose or not peaked or not fell or current_scene == null or current_scene.scene_file_path != "res://scenes/loading.tscn":
		push_error("Expected fade in -> full logo -> fade out -> loading")
		quit(1)
		return
	print("PASS splash fades in, holds, fades out, then opens loading")
	current_scene.queue_free()
	await process_frame
	quit(0)
