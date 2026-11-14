extends SceneTree

## Chụp màn Cài đặt + popup ngôn ngữ: godot --path . -s res://tests/lab/settings_shot.gd -- <prefix>
func _initialize() -> void:
	var gs := root.get_node("GameState")
	gs.init_new_game()
	gs.save_blocked = true
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	var prefix := OS.get_cmdline_user_args()[0]
	main._show_settings()
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png(prefix + "_settings.png")
	main._show_language_picker()
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png(prefix + "_picker.png")
	quit()
