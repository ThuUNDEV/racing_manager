extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(886,550)
	var view := RaceView.new()
	root.add_child(view)
	view.size = Vector2(886,550)
	var stats := {"S":40.0,"H":40.0,"B":40.0,"A":40.0,"P":40.0,"T":40.0,"C":40.0}
	for track in [GameData.class_track(GameData.default_class_id())]:
		view.set_track(track)
		var sim := TrafficSim.new()
		sim.setup(444,stats,0,track,{"duration":40.0})
		sim.tick_count = 1
		view.sim = sim
		view.alpha = 1.0
		for i in sim.cars.size():
			sim.cars[i].s = sim.lap_length*(0.12+i*0.105)
			sim.cars[i].prev_s = sim.cars[i].s
		view.queue_redraw()
		for i in 5: await process_frame
		check(view._world_3d.cars.size()==Balance.CAR_COUNT,"all cars share one viewport")
		check(view._world_3d.world.has_node("RoadKerbsAndFinish"),"3D road exists")
		var car: Node3D = view._world_3d.cars[0]
		check(car.position.is_equal_approx(view._world_3d.at(sim.player_car().s,sim.render_lat(sim.player_car(),1.0)*1.55,0.11)),"3D car follows authoritative sim position")
		check(view._car_position(sim.player_car().s,0).is_equal_approx(view._world_3d.screen_at(sim.player_car().s,0)),"overlays use camera projection")
		check(view._layout.shape == "figure_eight", "Racing uses figure eight geometry")
		var upper: Vector3 = view._world_3d.at(sim.lap_length*0.25)
		var lower: Vector3 = view._world_3d.at(sim.lap_length*0.75)
		check(Vector2(upper.x,upper.z).distance_to(Vector2(lower.x,lower.z)) < 0.1, "two branches cross at the center")
		check(upper.y-lower.y > 2.0, "bridge clears cars on the lower branch")
		check(view._world_3d.world.has_node("BridgeDeck"), "bridge has a structural deck")
		var before_rotation := sim.player_car().s
		var original_yaw: float = view._world_3d.camera_yaw
		var original_marker := view._car_position(sim.player_car().s,0)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = Vector2(450,150)
		view._gui_input(press)
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(100,0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		view._gui_input(motion)
		press.pressed = false
		view._gui_input(press)
		check(not is_equal_approx(view._world_3d.camera_yaw,original_yaw), "mouse drag rotates circuit camera")
		check(not original_marker.is_equal_approx(view._car_position(sim.player_car().s,0)), "HUD projection follows orbit")
		check(sim.player_car().s == before_rotation, "rotation leaves simulation untouched")
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = Vector2(450,150)
		touch.pressed = true
		view._gui_input(touch)
		var touch_yaw: float = view._world_3d.camera_yaw
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.relative = Vector2(50,0)
		view._gui_input(drag)
		touch.pressed = false
		view._gui_input(touch)
		check(not is_equal_approx(view._world_3d.camera_yaw,touch_yaw), "touch drag rotates circuit")
		for angle in [0.0, PI*0.5, PI, PI*1.5]:
			view._world_3d.camera_yaw = angle
			view._world_3d.fit_camera(Vector2.ZERO)
			var world_3d = view._world_3d
			for corner: Vector3 in world_3d._frame_corners:
				var screen: Vector2 = world_3d.camera.unproject_position(corner)*0.5
				check(Rect2(Vector2.ZERO,world_3d.view_rect.size).has_point(screen), "scenery fits camera at all orbit quadrants")
		view.reset_circuit_view()
		check(is_equal_approx(view._world_3d.camera_yaw,original_yaw), "reset returns to isometric angle")
		var before := sim.player_car().s
		view.size = Vector2(390,250)
		for i in 3: await process_frame
		check(sim.player_car().s==before,"resize does not advance simulation")
		view.size = Vector2(886,550)
		for i in 3: await process_frame
		if "--capture" in OS.get_cmdline_user_args() and track in ["track_circuit_a", "track_circuit_b"]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://output/"+track+"_3d.png")
	view.set_track("track_circuit_c")
	check(view._use_3d and view._world_3d.viewport.render_target_update_mode == SubViewport.UPDATE_WHEN_VISIBLE, "every circuit uses the 3D world")
	view.set_track(GameData.class_track(GameData.default_class_id()))
	view.sim = null
	root.size = Vector2i(390,242)
	view.size = Vector2(390,242)
	view.queue_redraw()
	for i in 5: await process_frame
	var viewport_count := 0
	for child in view.get_children():
		if child is SubViewport:
			viewport_count += 1
	check(viewport_count == 1, "one shared viewport survives track switches and resizes")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/race_3d_mobile.png")
	view.queue_free()
	await process_frame
	# Verify the actual main screen routes its default race through the 3D world.
	var state := root.get_node("GameState")
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	root.size = Vector2i(390,844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 10: await process_frame
	check(main._race_view._use_3d, "real game main screen enables 3D for Racing")
	check(main._race_view._world_3d != null, "real game constructs shared 3D scene")
	# Dispatch through the new UI tree, including its scroll containers and overlays.
	var real_view: RaceView = main._race_view
	var initial_yaw: float = real_view._world_3d.camera_yaw
	var start := real_view.get_global_rect().get_center()
	var hover := InputEventMouseMotion.new()
	hover.position = start
	Input.parse_input_event(hover)
	await process_frame
	var real_press := InputEventMouseButton.new()
	real_press.button_index = MOUSE_BUTTON_LEFT
	real_press.pressed = true
	real_press.position = start
	Input.parse_input_event(real_press)
	await process_frame
	var real_drag := InputEventMouseMotion.new()
	real_drag.position = start + Vector2(45,0)
	real_drag.relative = Vector2(45,0)
	real_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(real_drag)
	await process_frame
	real_press.pressed = false
	real_press.position = real_drag.position
	Input.parse_input_event(real_press)
	await process_frame
	check(not is_equal_approx(initial_yaw, real_view._world_3d.camera_yaw), "drag reaches circuit through refreshed main UI")
	real_view.reset_circuit_view()
	await process_frame

	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/game_racing_3d.png")
	main.queue_free()
	await process_frame
	print("RACE_WORLD_3D_TEST failures=",failures)
	quit(1 if failures else 0)
