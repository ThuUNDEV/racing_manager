extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var state=root.get_node("GameState")
	state.SAVE_PATH="user://tests/concept_v3.json"
	GameData.reload()
	state.init_new_game()
	state.active=false
	root.content_scale_factor=1.0
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(390,844)
	var main=load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 15: await process_frame
	main._show_race_result({"position":2,"money":100,"points":8,"trophies":2})
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Design/Previews/concept_v3_race_result.png")
	quit()
