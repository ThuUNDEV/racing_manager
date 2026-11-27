extends SceneTree
## Geometry/scenery integration and optional real-render captures: -- --capture
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 6:
		await process_frame

func capture(id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://Design/Previews/Race_Diorama")
	root.get_texture().get_image().save_png("res://Design/Previews/Race_Diorama/%s.png" % id)

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "isolated player save")
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var view := RaceView.new()
	root.add_child(view)
	var stats := {"S": 40.0, "H": 40.0, "B": 40.0, "A": 40.0, "P": 40.0, "T": 40.0, "C": 40.0}
	for width in [320, 390, 412]:
		view.size = Vector2(width - 40, 320)
		for track in ["track_circuit_a", "track_circuit_b", "track_circuit_c", "track_circuit_d", "track_circuit_e", "track_circuit_f", "track_circuit_g", "track_circuit_h", "track_circuit_i", "track_circuit_j", "track_circuit_k"]:
			view.set_track(track)
			check(not view._static_idx.is_empty(), "cached road exists %s/%d" % [track, width])
			var widest_road := 0.0
			for sample in view._left.size():
				widest_road = maxf(widest_road, view._left[sample].distance_to(view._right[sample]))
			if view._layout.shape != "figure_eight":  # figure eight crosses itself by design
				check(view._layout.min_clearance() * view._k > widest_road, "wider asphalt keeps separate circuit sections apart")
			var props: Array = view._scenery.duplicate(true)
			view._on_resized()
			check(props == view._scenery, "seeded scenery stable %s/%d" % [track, width])
			for prop: Dictionary in props:
				check(view._board_rect().has_point(prop.p), "scenery stays on board")
				check(view.Diorama.clearance(prop.p, view._mid, view._left) >= float(prop.radius), "scenery clears variable-width road")
			var sim := TrafficSim.new()
			sim.setup(444, stats, 0, track, {"duration": 40.0})
			view.sim = sim
			view.alpha = 0.5
			var before := sim.player_car().s
			var marker := view.player_marker()
			check((marker.pos as Vector2).is_equal_approx(view._car_position(sim.render_pos(sim.player_car(), 0.5), sim.render_lat(sim.player_car(), 0.5))), "tutorial marker follows exact sim position")
			check(float(marker.r) >= view._car_half_length(true), "spotlight contains toy car")
			check(view._car_half_length(false) * 2.0 >= 14.0, "cars have a readable minimum length")
			view.queue_redraw()
			await process_frame
			check(sim.player_car().s == before, "render does not advance simulation")
	view.queue_free()
	await settle()
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	state.begin_countdown()
	state._start_race()
	state.active = false
	# Fixed real simulation state, spread around the actual circuit for visual review.
	state.sim.run_to_end()
	state.sim.time = 17.0
	state.sim.finished = false
	state.sim.events.clear()
	for i in state.sim.cars.size():
		var c: TrafficSim.Car = state.sim.cars[i]
		c.s = state.sim.lap_length * (0.22 + float(i) * 0.085)
		c.prev_s = c.s
	main._sync_sim()
	main._update_race_ui()
	main._race_view.overlay_text = ""
	main._race_view.alpha = 1.0
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		main._race_view.queue_redraw()
		check(main._race_view._top == RaceView.HUD_H + RaceView.STAND_H, "HUD and audience keep their space")
		check(absf(main._race_view.size.y - (main.size.x - 8.0) * 0.75) <= 1.0 and main._race_view._board_rect().size.y > 100, "race height follows screen width and keeps a readable board")
		var chip: Rect2 = main._ads_controls._chip.get_global_rect()
		check(main._ads_controls._chip.is_visible_in_tree() and chip.position.y >= main._race_view.get_global_rect().end.y and chip.position.x >= 0.0 and chip.end.x <= width, "boost button sits in the row under the race view")
		await capture("race_%d" % width)
	root.size = Vector2i(320, 568)
	await settle()
	check(main._race_view.custom_minimum_size.y <= 250.0, "short phones use compact race height")
	check(main._pages_root.size.y >= 50.0, "upgrades remain scrollable on short phones")
	main._race_view.queue_redraw()
	await capture("race_320_short")
	root.size = Vector2i(390, 844)
	main._race_view.pump_events()
	state.sim.events.append({"type": "pass", "id": 0, "other": 1, "t": state.sim.time - 0.15})
	main._race_view.pump_events()
	main._race_view.queue_redraw()
	await settle()
	await capture("overtake_390")
	for decal: String in ["double_stripe", "lightning", "checker"]:
		main._race_view.player_decal_id = decal
		main._race_view.queue_redraw()
		await settle()
	main._race_view.sim = null
	main._race_view.pump_events()
	check(main._race_view._fx.is_empty(), "new race clears old comic effect")
	main._race_view.queue_redraw()
	await settle()
	await capture("grid_390")
	main.queue_free()
	await settle()
	print("RACE_DIORAMA_TEST failures=", failures)
	quit(1 if failures else 0)
