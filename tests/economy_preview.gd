extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Render actual game UI with a late-game BigNumber wallet; isolated test save.

func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.active = false
	gs.init_new_game()
	gs.business_tier = 5
	gs.unlocked_tier = 5
	for car: Dictionary in GameData.cars():
		if int(car["class"]) == 5:
			gs.active_car_id = car["id"]
			break
	gs.owned_cars[gs.active_car_id] = true
	gs.car_levels[gs.active_car_id] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	for kind in Balance.REVENUE:
		gs.levels[kind] = 12
	gs.coins = BigNumber.parse_decimal("1.25e18")
	gs.gems = 375
	var ui: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	for i in 5:
		await process_frame
	var output := "res://docs/screenshots/economy_v2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for tab in [0, 3, 4]:
		ui._select_tab(tab)
		ui._refresh()
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var err := img.save_png(output + "/tab_%d.png" % tab)
		if err != OK:
			quit(1)
			return
	gs.coins = BigNumber.parse_decimal("1.25e93")
	ui._refresh_light()
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(output + "/suffix_BA.png")
	ui.queue_free()
	await process_frame
	await process_frame
	quit(0 if err == OK else 1)
