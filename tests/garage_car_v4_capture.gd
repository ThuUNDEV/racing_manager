extends SceneTree
## Isolated Garage captures plus body selection / cosmetics regression coverage.
const OUT := "res://Design/Previews/Garage_Car_v4/round3/"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 12:
		await process_frame

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+path)

func run() -> void:
	var gs := root.get_node("GameState")
	check(gs.SAVE_PATH.contains("/tests/"), "Save kiểm tra phải được cách ly")
	gs.init_new_game()
	gs.set_cosmetics(gs.active_car_id,"white","double_stripe")
	gs.active = false
	gs.set_process(false)
	gs.tutorial["state"] = "done"
	gs.tutorial["gated"] = false
	DirAccess.make_dir_recursive_absolute(OUT)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390,844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(1)
	await settle()
	for width in [320,390,412]:
		root.size = Vector2i(width,roundi(width*844.0/390))
		await settle()
		await capture("%d_car.png" % width)
		check(main._garage._preview.size.x <= width,"Preview nằm trong khung %d" % width)
	root.size = Vector2i(390,844)
	var preview: CarPreview = main._garage._preview
	# Exercise live replacement, all classes and all saved cosmetic choices.
	for data: Dictionary in GameData.cars():
		preview.car_id = String(data["id"])
		check(preview._car.get_meta("body_class") == int(data["class"]),"Đúng thân xe "+preview.car_id)
		for paint: Dictionary in GameData.paints():
			preview.paint_id = String(paint["id"])
			check(preview._paint_material.albedo_color.is_equal_approx(Color(String(paint["color"]))),"Đổi sơn "+preview.paint_id)
		for decal: Dictionary in GameData.decals():
			preview.decal_id = String(decal["id"])
			check((preview._decals.get_child_count() == 0) == (preview.decal_id == "none"),"Giữ decal "+preview.decal_id)
	var other := CarPreview.new()
	root.add_child(other)
	other.paint_id = "blue"
	preview.paint_id = "red"
	check(other._paint_material.albedo_color.is_equal_approx(Color(String(GameData.paint("blue")["color"]))),"Sơn không lan sang preview khác")
	other.queue_free()
	# Capture each real class in the full Garage with the matching title.
	for family in ["pico","nova","apex","titan","zenith"]:
		main._garage._viewed = "car_%s_tia_chop" % family
		main._garage._sig = ""
		main._garage.refresh()
		await capture("390_%s.png" % family)
	main._garage._viewed = "car_pico_tia_chop"
	for section in 3:
		main._garage.debug_show("2,draft=teal:lightning" if section == 2 else str(section))
		await capture("390_tab%d.png" % section)
	main._garage.debug_show("2")
	await capture("390_look.png")
	for decal in ["double_stripe","lightning","checker"]:
		main._garage.debug_show("2,car=car_pico_tia_chop,draft=orange:"+decal)
		await capture("390_look_%s.png" % decal)
	main.queue_free()
	await settle()
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(900,1200)
		RenderingServer.set_default_clear_color(Color("fff6e9"))
		var sheet := Control.new()
		root.add_child(sheet)
		var families := ["pico","nova","apex","titan","zenith"]
		for i in 15:
			var model := CarPreview.new()
			model.car_id = "car_%s_tia_chop" % families[i/3]
			model.show_floor = false
			model.paint_id = ["white","teal","purple"][i%3]
			model.decal_id = ["double_stripe","lightning","checker"][i%3]
			model.position = Vector2((i%3)*300,(i/3)*240)
			model.size = Vector2(300,205)
			sheet.add_child(model)
			var title := Label.new()
			title.text = String(GameData.car(model.car_id)["name"])
			title.add_theme_font_size_override("font_size",16)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_color_override("font_color",Color("18446a"))
			title.position = model.position+Vector2(0,205)
			title.size = Vector2(300,35)
			sheet.add_child(title)
		await capture("five_bodies.png")
		sheet.queue_free()
		await settle()
	print("Garage car preview: %d lỗi" % failures)
	quit(1 if failures else 0)
