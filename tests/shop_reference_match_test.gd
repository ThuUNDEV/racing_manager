extends SceneTree
## Real-main capture fixture. /tests/ isolates the player's save.
const OUT := "res://Design/Previews/"
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in 16:
		await process_frame
func run() -> void:
	var state := root.get_node("GameState")
	if not state.SAVE_PATH.contains("/tests/"):
		quit(1)
		return
	GameData.reload()
	state.init_new_game()
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.business_tier = 4
	state.unlocked_tier = 4
	state.owned_cars["car_titan_tia_chop"] = true
	state.car_levels["car_titan_tia_chop"] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	state.active_car_id = "car_titan_tia_chop"
	state.completed_races = 30
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 946)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	main._select_tab(main.Tab.SHOP)
	main._rebuild_shop()
	await settle()
	var shop = main._shop_content
	var scroll: ScrollContainer = main._shop_box.get_parent()
	var records := {}
	for width: int in [320, 390, 448]:
		root.size = Vector2i(width, 946)
		scroll.scroll_vertical = 0
		await settle()
		var height := ceili(shop.size.y)
		var full := Image.create(width, height, false, Image.FORMAT_RGBA8)
		var top := roundi(scroll.global_position.y)
		var visible_height := floori(scroll.size.y)
		var info := {"width": width, "height": height, "scroll_top": top, "visible_height": visible_height, "shop_x":shop.global_position.x, "shop_width":shop.size.x, "blocks":{}}
		for child: Control in shop.get_children():
			if child.visible:
				info["blocks"][str(child.name)] = [child.position.x + shop.position.x, child.position.y, child.size.x, child.size.y]
		for sku: String in shop._offer_cards:
			var card: Control = shop._offer_cards[sku]
			if not card.is_visible_in_tree():
				continue
			info["blocks"]["Offer_"+sku] = [card.global_position.x, card.global_position.y-shop.global_position.y, card.size.x, card.size.y]
			var buy: Button = shop._iap_buttons[sku]["button"]
			if buy.size.y < 44 or not card.get_global_rect().grow(0.5).encloses(buy.get_global_rect()):
				print("FAIL target ",sku," ",width," ",card.get_global_rect()," ",buy.get_global_rect())
				failures += 1
		var offset := 0
		while true:
			scroll.scroll_vertical = offset
			await settle()
			await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image()
			screenshot.convert(Image.FORMAT_RGBA8)
			var actual := scroll.scroll_vertical
			full.blit_rect(screenshot, Rect2i(0, top, width, mini(visible_height, height-actual)), Vector2i(0, actual))
			if offset == 0:
				screenshot.save_png(OUT + "shop_match_%d_top.png" % width)
			if actual + visible_height >= height or actual < offset:
				break
			offset += visible_height - 20
		full.save_png(OUT + "shop_match_%d_full.png" % width)
		records[str(width)] = info
	var file := FileAccess.open(OUT + "shop_match_geometry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t"))
	print("SHOP_REFERENCE_MATCH_TEST failures=",failures)
	main.queue_free()
	await process_frame
	quit(failures)
