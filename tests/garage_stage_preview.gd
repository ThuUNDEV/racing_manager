extends SceneTree
const OUT := "res://Design/Previews/Garage_3D_Stage_v1/"
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for frame in 16:
		await process_frame
func run() -> void:
	GameData.reload()
	var gs := root.get_node("GameState")
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["state"] = "done"
	gs.tutorial["gated"] = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390,845)
	DirAccess.make_dir_recursive_absolute(OUT)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(1)
	for width in [320,390,412]:
		root.size = Vector2i(width,roundi(width * 845.0 / 390))
		await settle()
		main._garage._sig = ""
		main._garage.refresh()
		for angle in [90.0,145.0,210.0]:
			main._garage._preview.yaw = angle
			await settle()
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.save_png(OUT + "%d_%d.png" % [width,angle])
			image.get_region(Rect2i(main._garage._preview.get_global_rect())).save_png(OUT + "showroom_%d_%d.png" % [width,angle])
	main.queue_free()
	await settle()
	print("GARAGE_STAGE_PREVIEW complete")
	quit()
