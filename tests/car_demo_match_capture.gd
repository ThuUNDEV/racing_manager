extends SceneTree
## Demo-match material/family regression plus an optional real-render contact sheet.
const OUT := "res://Design/Previews/Car_Demo_Match_v5/"
const World = preload("res://ui/race_world_3d.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "Save kiểm tra phải được cách ly")
	state.init_new_game()
	state.active = false
	state.set_process(false)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1200, 780)
	RenderingServer.set_default_clear_color(Color("fff4e5"))
	var sheet := Control.new()
	root.add_child(sheet)
	var families := ["pico", "nova", "apex", "titan", "zenith", "pico", "pico", "pico"]
	var paints := ["epic_sapphire", "epic_jade", "epic_ruby", "epic_aurum", "epic_amethyst", "epic_aurora", "epic_solar", "epic_midnight"]
	for i in 8:
		var preview := CarPreview.new()
		preview.car_id = "car_" + families[i] + "_epic"
		preview.paint_id = paints[i]
		preview.show_floor = false
		preview.position = Vector2((i%4)*300, (i/4)*390+20)
		preview.size = Vector2(300, 320)
		sheet.add_child(preview)
		check(preview._car.get_meta("body_class") == int(GameData.car(preview.car_id)["class"]), "Đúng model từng hạng")
		check(preview._car.get_node("Body").material_override.next_pass != null, "Sơn Epic có finish")
		check(not preview._car.has_node("RaceNumberBadge_Left"), "Xe Epic không có huy hiệu che thân")
		var label := Label.new()
		label.text = families[i].to_upper() if i < 5 else paints[i].trim_prefix("epic_").to_upper()
		label.position = preview.position+Vector2(0,320)
		label.size = Vector2(300,40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",24)
		label.add_theme_color_override("font_color",Color("0e2b5c"))
		sheet.add_child(label)
	# Race integration: all five families, reuse on unchanged identity, snapshot isolation.
	var world = World.new(sheet)
	world.world = Node3D.new()
	world.viewport.add_child(world.world)
	var initial: Node3D = CarPreview.MODELS[0].instantiate()
	initial.scale = Vector3.ONE * 0.55
	world.world.add_child(initial)
	world.cars[0] = initial
	state.phase = "racing"
	for i in 5:
		state.race_snapshot = {"car_id": "car_"+families[i]+"_epic", "paint_id": paints[i], "decal_id": "double_stripe"}
		world._sync_player_car()
		check(world.cars[0].get_meta("body_class") == i+1, "Đua dùng đúng thân xe snapshot")
		check(world.cars[0].get_node("Body").material_override.next_pass != null, "Đua giữ finish Epic")
		check(world.cars[0].has_node("Livery_Body"), "Đua giữ decal đã chọn")
		var same: Node3D = world.cars[0]
		world._sync_player_car()
		check(world.cars[0] == same, "Không tạo lại mesh mỗi frame")
	state.active_car_id = "car_pico_tia_chop"
	world._sync_player_car()
	check(world.cars[0].get_meta("body_class") == 5, "Đổi xe garage không đổi snapshot đang đua")
	state.phase = "idle"
	world._sync_player_car()
	check(world.cars[0].get_meta("body_class") == 1, "Hết đua áp dụng xe đang chọn")
	check(world.cars[0].get_node("Body").material_override.next_pass == null, "Sơn thường không giữ finish Epic cũ")
	world.viewport.queue_free()
	world = null
	for i in 20:
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(OUT)
		root.get_texture().get_image().save_png(OUT+"cars_and_finishes.png")
	sheet.queue_free()
	for i in 4:
		await process_frame
	print("CAR_DEMO_MATCH failures=", failures)
	quit(1 if failures else 0)
