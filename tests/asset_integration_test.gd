extends SceneTree
## Native/headless asset smoke test. Save routing is isolated by GameState's /tests/ path.
var failures := 0
var main: Control
var shots := false

func check(ok: bool, message: String) -> void:
	print("  ", "OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 5:
		await process_frame

func shot(id: String) -> void:
	await settle()
	if shots:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/asset_" + id + ".png")

func run() -> void:
	shots = "--asset-shots" in OS.get_cmdline_user_args()
	GameData.reload()
	var state := root.get_node("GameState")
	state.init_new_game()
	state.active = false
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/racing_ui_hd_expansion/manifest.json"))
	var loaded := 0
	for sprite: Dictionary in manifest["sprites"]:
		var texture := ExpansionArt.texture(sprite["id"])
		if texture != null and texture.get_width() > 0 and texture.get_height() > 0:
			loaded += 1
	check(loaded == 82, "82 texture resources load with nonzero dimensions")
	for car: Dictionary in GameData.cars():
		check(ExpansionArt.texture(ExpansionArt.car_id(car["id"])) != null and ExpansionArt.texture(ExpansionArt.car_id(car["id"], true)) != null, "both views map for " + car["id"])
	state.gems = 500
	for item: Dictionary in GameData.gear_items().slice(0, 3):
		state.gear_owned[item["id"]] = {"level": 0, "shards": 100}
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	await shot("upgrades")
	main._select_tab(1)
	await shot("gear_packs")
	check(main._gear.find_child("Art_standard_gear_pack", true, false) != null, "gear packs use generated art")
	check(main._gear.find_child("Art_gear_balaclava", true, false) != null, "owned gear uses its own item art")
	var bag_scroll: ScrollContainer = main._pages[1]
	bag_scroll.scroll_vertical = 400
	await shot("gear_inventory")
	main._select_tab(2)
	main._select_team_sub(0)
	await shot("drivers")
	check(main._roster.find_child("Art_standard_driver_pack", true, false) != null and main._roster.find_child("Art_elite_driver_pack", true, false) != null, "Pro/All-Star map to distinct generated packs")
	for driver: Dictionary in GameData.drivers():
		check(main._roster.find_child("Art_" + driver["id"], true, false) != null, "roster portrait " + driver["id"])
	(main._pages[2] as ScrollContainer).scroll_vertical = 500
	await shot("driver_roster")
	main._select_team_sub(1)
	(main._pages[2] as ScrollContainer).scroll_vertical = 0
	main._garage.debug_show("0")
	await shot("garage")
	check(main._garage._preview._car.texture == ExpansionArt.texture("car_pico_showroom"), "Garage shows the selected model in three-quarter view")
	main._garage.debug_show("2,draft=red:lightning")
	await shot("cosmetics")
	check(main._garage._preview._car.texture == ExpansionArt.texture("car_pico_topdown") and main._garage._preview._layer.visible, "cosmetic draft uses overhead body and visible decal")
	check(main._garage._preview._paint_material.get_shader_parameter("paint_color").is_equal_approx(Color(GameData.paint("red")["color"])), "saved/draft color drives body material")
	main._garage.debug_show("1")
	(main._pages[2] as ScrollContainer).scroll_vertical = 350
	await shot("parts")
	main._garage.debug_show("0,collection")
	await shot("collection")
	main._select_tab(3)
	await shot("league")
	main._select_tab(4)
	await shot("shop")
	check(main._shop_content.find_child("Art_elite_gear_pack", true, false) != null, "Shop uses generated bundle art")
	for width in [320, 360, 390, 412]:
		root.size = Vector2i(width, 844)
		main._select_tab(1)
		await settle()
		var inventory: ScrollContainer = main._gear.find_child("InventoryScroll", true, false)
		for card: Control in inventory.get_child(0).get_children():
			check(card.get_global_rect().end.x <= inventory.get_global_rect().end.x + 1, "gear card fits width %d" % width)
		main._select_tab(2)
		main._select_team_sub(1)
		main._garage.debug_show("1")
		await settle()
		check(main._garage.size.x <= (main._pages[2] as ScrollContainer).size.x + 1, "Garage parts fit width %d" % width)
	state.active = false
	main.queue_free()
	await settle()
	# Release the art cache before exit so renderer diagnostics stay meaningful.
	ExpansionArt._textures.clear()
	print("ASSET_INTEGRATION_TEST failures=", failures)
	quit(1 if failures else 0)
