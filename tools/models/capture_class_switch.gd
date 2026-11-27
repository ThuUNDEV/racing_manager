extends SceneTree
const OUT := "res://Design/Previews/Class_Vehicles_v2/"

func settle() -> void:
	for i in 8:
		await process_frame

func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	state.init_new_game()
	state.set_process(false)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390,844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._class_page.open_first_choice()
	for width in [320,390,412]:
		root.size = Vector2i(width,844)
		await shot("picker_%d" % width)
	state.first_class_pending = false
	state.gate_first_class = false
	state.tutorial["state"] = "done"
	state.tutorial["gated"] = false
	main._class_page.hide()
	root.size = Vector2i(390,844)
	state.begin_countdown()
	for id in ["racing","rally","stock","bike","speed","monster"]:
		state.dev_switch_class(id)
		main._sync_sim()
		for i in state.sim.cars.size():
			state.sim.cars[i].s = state.sim.lap_length * (0.05+i*0.11)
			state.sim.cars[i].prev_s = state.sim.cars[i].s
		main._race_view.alpha = 1.0
		main._race_view.queue_redraw()
		await shot("race_"+id)
		main._select_tab(main.Tab.TEAM)
		main._select_team_sub(1)
		main._garage.refresh()
		await shot("garage_"+id)
		main._select_tab(main.Tab.RACE)
	main.queue_free()
	await settle()
	quit()
