extends SceneTree
## Exercise the real main-screen sim handoff, race snapshot and Garage preview.
const Appearance = preload("res://ui/car_appearance.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func settle() -> void:
	for frame in 4:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	state.init_new_game()
	state.set_process(false)
	state.first_class_pending = false
	state.gate_first_class = false
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390,844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	state.begin_countdown()
	await settle()
	var ids := ["racing","rally","stock","bike","speed","monster"]
	for index in ids.size():
		var id: String = ids[index]
		check(state.dev_switch_class(id), "Chuyển class " + id)
		main._sync_sim()
		await settle()
		var view: RaceView = main._race_view
		var world = view._world_3d
		check(view.sim.track_id == GameData.class_track(id), "Sim dùng đường của " + id)
		check(view._layout.track_id == view.sim.track_id, "Đường hiển thị khớp sim " + id)
		check(world.vehicle_class == id and world.cars.size() == Balance.CAR_COUNT, "Cả đoàn xe theo class " + id)
		for car_index in world.cars:
			var car: Node3D = world.cars[car_index]
			check(car.scene_file_path == Appearance.model_for_class(id,1).resource_path, "Model đúng %s xe %d" % [id,car_index])
			check(car.has_node("Body") and car.has_node("Roof"), "Model hỗ trợ sơn/decal %s xe %d" % [id,car_index])
		var wheel_count := 0
		for child in world.cars[0].get_children():
			if String(child.name).ends_with("Wheel"):
				wheel_count += 1
		if id != "racing":
			check(wheel_count == (2 if id == "bike" else 4), "Số bánh đúng " + id)
			var meshes: Array[Node] = world.cars[0].find_children("*","MeshInstance3D",true,false)
			check(meshes.size() <= 32, "Model chi tiết được gộp để giảm số mesh " + id)
			for child in world.cars[0].get_children():
				if String(child.name).ends_with("Wheel"):
					check(float(child.get_meta("radius",0.0)) > 0.0, "Bánh có bán kính để quay đúng " + id)
		var preview := CarPreview.new()
		preview.race_class_id = id
		preview.paint_id = "blue"
		preview.decal_id = "double_stripe"
		root.add_child(preview)
		preview.size = Vector2(200,130)
		check(preview._car.scene_file_path == Appearance.model_for_class(id).resource_path, "Garage dùng đúng dáng " + id)
		preview.queue_free()
		state._start_race()
		main._sync_sim()
		await settle()
		var next: String = ids[(index+1)%ids.size()]
		var checkpoint: Dictionary = state._checkpoint()
		check(state._restore_checkpoint(checkpoint), "Khôi phục lượt đang đua " + id)
		main._sync_sim()
		await settle()
		check(view._world_3d.vehicle_class == id and view.sim.track_id == GameData.class_track(id), "Khôi phục đúng xe/đường " + id)
		var old_sim = state.sim
		check(state.dev_switch_class(next), "Xếp hàng đổi sang " + next)
		main._sync_sim()
		await settle()
		check(state.pending_class == next and state.race_class_id == id, "Đang đua giữ class " + id)
		check(state.sim == old_sim and world.vehicle_class == id and view._layout.track_id == GameData.class_track(id), "Không đổi xe/đường giữa lượt " + id)
		# Resolve the actual race, so the next loop also tests the boundary handoff.
		while not state.sim.finished:
			state.sim.step()
		state._resolve()
		main._sync_sim()
		await settle()
		check(state.race_class_id == next and view._world_3d.vehicle_class == next, "Lượt kế đổi xe và đường cùng nhau " + next)
	main.queue_free()
	await settle()
	print("CLASS_VEHICLE_TEST failures=", failures)
	quit(1 if failures else 0)
