extends SceneTree
## Chụp popup Xe Epic / Bộ sơn Epic ở 320/390/412 để đối chiếu concept (Design/Previews/epic_popup_v7/).
##   XDG_DATA_HOME=/tmp/rmx godot --path . --screen 1 --audio-driver Dummy -s res://tests/epic_popup_capture.gd
const WIDTHS := [390]
const SKUS := ["epic_car_pico", "epic_car_nova", "epic_car_apex", "epic_car_titan", "epic_car_zenith", "epic_paint_aurora", "epic_paint_solar", "epic_paint_midnight", "epic_paint_sakura", "epic_paint_neon"]
const OUT := "res://Design/Previews/epic_popup_v7/"


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for i in 20:
		await process_frame


func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP epic popup capture: no renderer under --headless")
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for sku: String in SKUS:
		for width: int in WIDTHS:
			root.size = Vector2i(width, 844)
			await settle()
			main._show_iap_detail(sku)
			await settle()
			await RenderingServer.frame_post_draw
			var path := "%sruntime_%s_%d.png" % [OUT, sku, width]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			for node_name: String in ["EpicHeader", "EpicDetailStage", "EpicDetailName", "EpicDetailChip", "EpicDetailTiles", "DetailBuy_" + sku, "EpicLater", "EpicDetail"]:
				var node := main.find_child(node_name, true, false) as Control
				if node != null:
					var r := node.get_global_rect()
					print("RECT %d %s x=%.1f y=%.1f w=%.1f h=%.1f" % [width, node_name, r.position.x, r.position.y, r.size.x, r.size.y])
			print("WROTE ", path," later=", main._overlay_box.find_child("EpicLater", true, false) != null, " buy=", main._overlay_box.find_child("DetailBuy_" + sku, true, false) != null)
			pass
			await settle()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%sswitched_prev_%s_%d.png" % [OUT, sku, width]))
			print("SWITCHED buy=", main._overlay_box.find_child("DetailBuy_epic_car_titan", true, false) != null)
			main._close_overlay()
			await settle()
	quit(0)
