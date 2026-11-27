extends SceneTree
## Chụp mục Xe Epic / Bộ sơn Epic trong Shop ở 320/390/412 để đối chiếu concept (Design/Previews/epic_review/).
##   godot --path . --screen 1 --audio-driver Dummy -s res://tests/epic_shop_capture.gd
const WIDTHS := [320, 390, 412]
const OUT := "res://Design/Previews/epic_review/"


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for i in 14:
		await process_frame


func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP epic capture: no renderer under --headless")
		quit(0)
		return
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.business_tier = 4
	state.unlocked_tier = 4
	state.completed_races = 30
	state.owned_cars["car_titan_tia_chop"] = true
	state.car_levels["car_titan_tia_chop"] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	state.active_car_id = "car_titan_tia_chop"
	print("GRANT ", state.grant_iap("epic_paint_aurora", "tok_cap_paint"), " ", state.iap_bought("epic_paint_aurora"))
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	main._select_tab(main.Tab.SHOP)
	main._rebuild_shop()
	await settle()
	var scroll: ScrollContainer = main._shop_box.get_parent()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for width: int in WIDTHS:
		root.size = Vector2i(width, 844)
		await settle()
		for section in ["Section_EpicCars", "Section_EpicPaints"]:
			var heading: Control = main._shop_box.find_child(section, true, false)
			scroll.scroll_vertical = int(heading.global_position.y - scroll.global_position.y + scroll.scroll_vertical) - 8
			await settle()
			await RenderingServer.frame_post_draw
			var path := "%sruntime_%s_%d.png" % [OUT, section.to_lower(), width]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print("WROTE ", path)
	quit(0)
